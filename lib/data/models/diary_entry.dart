import 'card_rarity.dart';

/// 完成日记 · PRD §5.7
class DiaryEntry {
  final int? id;
  final String cardId;
  final String mood; // emoji: 😊 😍 🥵 😂 🥺 ...
  final String content;
  final String? photoPath;
  final DateTime createdAt;
  final String executorName; // 当时的执行者昵称（"小鹿"/"团子"）

  const DiaryEntry({
    this.id,
    required this.cardId,
    required this.mood,
    required this.content,
    this.photoPath,
    required this.createdAt,
    required this.executorName,
  });

  Map<String, Object?> toDbRow() => {
        if (id != null) 'id': id,
        'card_id': cardId,
        'mood': mood,
        'content': content,
        'photo_path': photoPath,
        'created_at': createdAt.toIso8601String(),
        'executor_name': executorName,
      };

  factory DiaryEntry.fromDbRow(Map<String, Object?> row) {
    return DiaryEntry(
      id: row['id'] as int?,
      cardId: row['card_id'] as String,
      mood: row['mood'] as String? ?? '',
      content: row['content'] as String? ?? '',
      photoPath: row['photo_path'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      executorName: row['executor_name'] as String? ?? '',
    );
  }
}

/// 日记列表展示用的"富视图"：日记本体 + 关联卡片的标题/稀有度/等级。
///
/// 通过 SQL JOIN 在仓储层一次性查出，避免列表里 N+1 异步取卡。
/// 若卡片已被删除（自定义卡）则 cardTitle 为 `null`。
class DiaryEntryView {
  final DiaryEntry entry;
  final String? cardTitle;
  final CardRarity? cardRarity;
  final int? cardLevel;

  const DiaryEntryView({
    required this.entry,
    this.cardTitle,
    this.cardRarity,
    this.cardLevel,
  });
}
