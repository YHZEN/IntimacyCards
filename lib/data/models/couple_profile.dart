/// 情侣信息 · PRD §10.3 + §5.2
///
/// 全 App 唯一一行，初始化后所有功能复用。
class CoupleProfile {
  final String myName;
  final String partnerName;
  final String myAvatar; // PresetAvatar.id
  final String partnerAvatar;
  final DateTime anniversary;
  final int intimacyLevel;
  final int intimacyExp;
  final String safeWord;
  final CurrentUser currentUser;
  final List<String> excludedComfortTags;

  const CoupleProfile({
    required this.myName,
    required this.partnerName,
    required this.myAvatar,
    required this.partnerAvatar,
    required this.anniversary,
    this.intimacyLevel = 1,
    this.intimacyExp = 0,
    this.safeWord = '暂停',
    this.currentUser = CurrentUser.self,
    this.excludedComfortTags = const [],
  });

  int get daysTogether =>
      DateTime.now().difference(anniversary).inDays.abs() + 1;

  String get activeName => currentUser == CurrentUser.self ? myName : partnerName;
  String get activeAvatar =>
      currentUser == CurrentUser.self ? myAvatar : partnerAvatar;
  String get inactiveName =>
      currentUser == CurrentUser.self ? partnerName : myName;
  String get inactiveAvatar =>
      currentUser == CurrentUser.self ? partnerAvatar : myAvatar;

  CoupleProfile copyWith({
    String? myName,
    String? partnerName,
    String? myAvatar,
    String? partnerAvatar,
    DateTime? anniversary,
    int? intimacyLevel,
    int? intimacyExp,
    String? safeWord,
    CurrentUser? currentUser,
    List<String>? excludedComfortTags,
  }) {
    return CoupleProfile(
      myName: myName ?? this.myName,
      partnerName: partnerName ?? this.partnerName,
      myAvatar: myAvatar ?? this.myAvatar,
      partnerAvatar: partnerAvatar ?? this.partnerAvatar,
      anniversary: anniversary ?? this.anniversary,
      intimacyLevel: intimacyLevel ?? this.intimacyLevel,
      intimacyExp: intimacyExp ?? this.intimacyExp,
      safeWord: safeWord ?? this.safeWord,
      currentUser: currentUser ?? this.currentUser,
      excludedComfortTags: excludedComfortTags ?? this.excludedComfortTags,
    );
  }

  Map<String, Object?> toDbRow() => {
        'id': 1,
        'my_name': myName,
        'partner_name': partnerName,
        'my_avatar': myAvatar,
        'partner_avatar': partnerAvatar,
        'anniversary': anniversary.toIso8601String(),
        'intimacy_level': intimacyLevel,
        'intimacy_exp': intimacyExp,
        'safe_word': safeWord,
        'current_user': currentUser.name,
        'excluded_comfort_tags': excludedComfortTags.join(','),
      };

  factory CoupleProfile.fromDbRow(Map<String, Object?> row) {
    final excluded = (row['excluded_comfort_tags'] as String? ?? '').isEmpty
        ? <String>[]
        : (row['excluded_comfort_tags'] as String).split(',');
    return CoupleProfile(
      myName: row['my_name'] as String,
      partnerName: row['partner_name'] as String,
      myAvatar: row['my_avatar'] as String,
      partnerAvatar: row['partner_avatar'] as String,
      anniversary: DateTime.parse(row['anniversary'] as String),
      intimacyLevel: row['intimacy_level'] as int? ?? 1,
      intimacyExp: row['intimacy_exp'] as int? ?? 0,
      safeWord: row['safe_word'] as String? ?? '暂停',
      currentUser: CurrentUser.values.firstWhere(
        (e) => e.name == (row['current_user'] as String? ?? 'self'),
        orElse: () => CurrentUser.self,
      ),
      excludedComfortTags: excluded,
    );
  }
}

enum CurrentUser { self, partner }
