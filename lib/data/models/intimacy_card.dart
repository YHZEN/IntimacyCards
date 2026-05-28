import 'card_rarity.dart';

/// 任务卡 · PRD §6.1
class IntimacyCard {
  final String id;
  final String title;
  final String description;
  final int level; // 1..4
  final CardRarity rarity;
  final String type; // action / truth / combo / wish / roleplay / photo
  final List<String> tags;
  final CardExecutor executor;
  final int? durationSeconds;
  final List<String> comfortTags;
  final bool isCustom;
  final bool enabled;
  /// 自制卡混入的等级池（1–4）；Lv.5「定制的爱」始终包含全部自制卡
  final List<int> poolLevels;

  const IntimacyCard({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.rarity,
    required this.type,
    required this.tags,
    required this.executor,
    this.durationSeconds,
    this.comfortTags = const [],
    this.isCustom = false,
    this.enabled = true,
    this.poolLevels = const [],
  });

  IntimacyCard copyWith({
    String? id,
    String? title,
    String? description,
    int? level,
    CardRarity? rarity,
    String? type,
    List<String>? tags,
    CardExecutor? executor,
    int? durationSeconds,
    List<String>? comfortTags,
    bool? isCustom,
    bool? enabled,
    List<int>? poolLevels,
  }) {
    return IntimacyCard(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      level: level ?? this.level,
      rarity: rarity ?? this.rarity,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      executor: executor ?? this.executor,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      comfortTags: comfortTags ?? this.comfortTags,
      isCustom: isCustom ?? this.isCustom,
      enabled: enabled ?? this.enabled,
      poolLevels: poolLevels ?? this.poolLevels,
    );
  }

  factory IntimacyCard.fromJson(Map<String, dynamic> json) {
    return IntimacyCard(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      level: json['level'] as int,
      rarity: CardRarity.parse(json['rarity'] as String),
      type: json['type'] as String,
      tags: (json['tags'] as List? ?? []).cast<String>(),
      executor: CardExecutor.parse(json['executor'] as String? ?? 'loser'),
      durationSeconds: json['duration'] as int?,
      comfortTags: (json['comfortTags'] as List? ?? []).cast<String>(),
      isCustom: json['isCustom'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'level': level,
        'rarity': rarity.code,
        'type': type,
        'tags': tags,
        'executor': executor.name,
        'duration': durationSeconds,
        'comfortTags': comfortTags,
        'isCustom': isCustom,
        'enabled': enabled,
      };

  Map<String, Object?> toDbRow() => {
        'id': id,
        'title': title,
        'description': description,
        'level': level,
        'rarity': rarity.code,
        'type': type,
        'tags': tags.join(','),
        'executor': executor.name,
        'duration': durationSeconds,
        'comfort_tags': comfortTags.join(','),
        'is_custom': isCustom ? 1 : 0,
        'enabled': enabled ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      };

  factory IntimacyCard.fromDbRow(Map<String, Object?> row) {
    String csvOf(Object? v) => (v as String?) ?? '';
    final tags = csvOf(row['tags']).isEmpty ? <String>[] : csvOf(row['tags']).split(',');
    final comfort = csvOf(row['comfort_tags']).isEmpty
        ? <String>[]
        : csvOf(row['comfort_tags']).split(',');

    return IntimacyCard(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String,
      level: row['level'] as int,
      rarity: CardRarity.parse(row['rarity'] as String),
      type: row['type'] as String,
      tags: tags,
      executor: CardExecutor.parse(row['executor'] as String? ?? 'loser'),
      durationSeconds: row['duration'] as int?,
      comfortTags: comfort,
      isCustom: (row['is_custom'] as int? ?? 0) == 1,
      enabled: (row['enabled'] as int? ?? 1) == 1,
    );
  }
}

/// 功能卡 · PRD §6.4
class FunctionCard {
  final String id;
  final String title;
  final String description;
  final CardRarity rarity;
  final String effect;

  const FunctionCard({
    required this.id,
    required this.title,
    required this.description,
    required this.rarity,
    required this.effect,
  });

  factory FunctionCard.fromJson(Map<String, dynamic> json) {
    return FunctionCard(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      rarity: CardRarity.parse(json['rarity'] as String),
      effect: json['effect'] as String,
    );
  }
}
