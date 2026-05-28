import 'dart:convert';
import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../../data/models/card_rarity.dart';
import '../../data/models/intimacy_card.dart';

/// 批量导入自制卡 JSON 解析结果
class CustomCardImportResult {
  final int imported;
  final List<({IntimacyCard card, List<int> poolLevels})> items;
  final List<String> errors;

  const CustomCardImportResult({
    required this.imported,
    required this.items,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isEmpty => items.isEmpty;
}

/// 自制卡 JSON 批量导入解析器
///
/// 支持格式：
/// ```json
/// {
///   "version": "1.0",
///   "cards": [
///     {
///       "title": "专属的晚安吻",
///       "description": "睡前给对方一个额头吻",
///       "rarity": "R",
///       "executor": "loser",
///       "poolLevels": [1, 2]
///     }
///   ]
/// }
/// ```
///
/// 也支持直接传入数组 `[{...}, {...}]`。
class CustomCardImporter {
  CustomCardImporter._();

  /// 界面展示的格式说明（与解析逻辑保持一致）
  static const formatIntro = '粘贴 JSON 对象或数组，批量写入自制卡池。'
      '导入的卡都会进入「定制的爱」，可通过 poolLevels 额外混入 Lv.1–4。';

  static const rootFormats = [
    ('对象', '{ "version": "1.0", "cards": [ {...}, {...} ] }'),
    ('数组', '[ {...}, {...} ]'),
  ];

  static const fieldRules = [
    ImportFieldRule('title', required: true, desc: '卡名', example: '"专属的晚安吻"'),
    ImportFieldRule('description', required: true, desc: '任务描述', example: '"睡前给对方一个额头吻"'),
    ImportFieldRule('rarity', desc: '稀有度', example: '"R" / "SR" / "SSR"，默认 R'),
    ImportFieldRule('executor', desc: '执行者', example: '"loser" / "winner" / "both"，默认 loser'),
    ImportFieldRule('poolLevels', desc: '混入等级', example: '[1, 2] 可多选；[] 或不写 = 仅「定制的爱」'),
    ImportFieldRule('level', desc: '单等级（简写）', example: '2  等同 poolLevels: [2]'),
    ImportFieldRule('id', desc: '卡片 ID', example: '可选，不写则自动生成'),
    ImportFieldRule('type', desc: '类型', example: '"action"，默认 action'),
    ImportFieldRule('tags', desc: '标签', example: '["custom"]'),
    ImportFieldRule('duration', desc: '时长（秒）', example: '60'),
    ImportFieldRule('enabled', desc: '是否启用', example: 'true，默认 true'),
  ];

  static const exampleJson = '''
{
  "version": "1.0",
  "cards": [
    {
      "title": "专属的晚安吻",
      "description": "睡前给对方一个额头吻，并说晚安",
      "rarity": "R",
      "executor": "loser",
      "poolLevels": [1, 2]
    },
    {
      "title": "只属于我们的暗号",
      "description": "用只有你们懂的暗号说一次我爱你",
      "rarity": "SR",
      "executor": "both",
      "poolLevels": []
    }
  ]
}''';

  static CustomCardImportResult parse(String raw) {
    final errors = <String>[];
    final items = <({IntimacyCard card, List<int> poolLevels})>[];

    dynamic decoded;
    try {
      decoded = json.decode(raw.trim());
    } catch (e) {
      return CustomCardImportResult(
        imported: 0,
        items: const [],
        errors: ['JSON 格式无效：$e'],
      );
    }

    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final cards = decoded['cards'];
      if (cards is! List) {
        return CustomCardImportResult(
          imported: 0,
          items: const [],
          errors: ['根对象需包含 "cards" 数组，或直接传入数组'],
        );
      }
      list = cards;
    } else {
      return CustomCardImportResult(
        imported: 0,
        items: const [],
        errors: ['根节点必须是对象或数组'],
      );
    }

    if (list.isEmpty) {
      return CustomCardImportResult(
        imported: 0,
        items: const [],
        errors: ['cards 数组为空'],
      );
    }

    final usedIds = <String>{};
    for (var i = 0; i < list.length; i++) {
      final idx = i + 1;
      final entry = list[i];
      if (entry is! Map) {
        errors.add('第 $idx 条：不是对象');
        continue;
      }
      final map = Map<String, dynamic>.from(entry);

      final title = (map['title'] as String?)?.trim() ?? '';
      final description = (map['description'] as String?)?.trim() ?? '';
      if (title.isEmpty) {
        errors.add('第 $idx 条：缺少 title');
        continue;
      }
      if (description.isEmpty) {
        errors.add('第 $idx 条：缺少 description');
        continue;
      }

      final rarityCode = ((map['rarity'] as String?) ?? 'R').toUpperCase();
      if (!const {'R', 'SR', 'SSR'}.contains(rarityCode)) {
        errors.add('第 $idx 条：rarity 仅支持 R / SR / SSR');
        continue;
      }
      final rarity = CardRarity.parse(rarityCode);

      final executor = CardExecutor.parse(
        (map['executor'] as String?) ?? 'loser',
      );

      final poolLevels = _parsePoolLevels(map, errors, idx);
      if (poolLevels == null) continue;

      var rawId = (map['id'] as String?)?.trim();
      String cardId;
      if (rawId == null || rawId.isEmpty) {
        cardId = _genId();
      } else if (rawId.startsWith('L') && RegExp(r'^L\d').hasMatch(rawId)) {
        cardId = '${_genId()}_from_$idx';
        errors.add('第 $idx 条：id 与官方卡冲突，已自动生成新 id');
      } else {
        cardId = rawId;
      }
      while (usedIds.contains(cardId)) {
        cardId = _genId();
      }
      usedIds.add(cardId);

      final primaryLevel = poolLevels.isNotEmpty
          ? poolLevels.first
          : AppConstants.customOnlyLevel;

      final tagsRaw = map['tags'];
      final tags = tagsRaw is List
          ? tagsRaw.cast<String>()
          : <String>['custom', 'imported'];

      final card = IntimacyCard(
        id: cardId,
        title: title,
        description: description,
        level: primaryLevel,
        rarity: rarity,
        type: (map['type'] as String?) ?? 'action',
        tags: tags,
        executor: executor,
        durationSeconds: map['duration'] as int?,
        comfortTags: map['comfortTags'] is List
            ? (map['comfortTags'] as List).cast<String>()
            : const [],
        isCustom: true,
        enabled: map['enabled'] as bool? ?? true,
        poolLevels: poolLevels,
      );

      items.add((card: card, poolLevels: poolLevels));
    }

    return CustomCardImportResult(
      imported: items.length,
      items: items,
      errors: errors,
    );
  }

  static List<int>? _parsePoolLevels(
    Map<String, dynamic> map,
    List<String> errors,
    int idx,
  ) {
    if (map['poolLevels'] != null) {
      final raw = map['poolLevels'];
      if (raw is! List) {
        errors.add('第 $idx 条：poolLevels 必须是数组');
        return null;
      }
      final levels = <int>[];
      for (final v in raw) {
        if (v is! int || v < 1 || v > 4) {
          errors.add('第 $idx 条：poolLevels 仅支持 1–4 的整数');
          return null;
        }
        levels.add(v);
      }
      return levels.toSet().toList()..sort();
    }

    if (map['level'] != null) {
      final lv = map['level'];
      if (lv is! int || lv < 1 || lv > 4) {
        errors.add('第 $idx 条：level 需为 1–4 的整数');
        return null;
      }
      return [lv];
    }

    return [];
  }

  static String _genId() {
    return 'custom_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
  }
}

class ImportFieldRule {
  final String name;
  final bool required;
  final String desc;
  final String example;

  const ImportFieldRule(
    this.name, {
    this.required = false,
    required this.desc,
    required this.example,
  });
}
