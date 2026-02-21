enum CommunityPostKind {
  advice,
  checkIn,
  win,
  relapse,
}

extension CommunityPostKindX on CommunityPostKind {
  String get id {
    return switch (this) {
      CommunityPostKind.advice => 'advice',
      CommunityPostKind.checkIn => 'check_in',
      CommunityPostKind.win => 'win',
      CommunityPostKind.relapse => 'relapse',
    };
  }

  String get label {
    return switch (this) {
      CommunityPostKind.advice => 'Advice',
      CommunityPostKind.checkIn => 'Check-in',
      CommunityPostKind.win => 'Win',
      CommunityPostKind.relapse => 'Relapse',
    };
  }

  static CommunityPostKind fromId(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    return switch (normalized) {
      'check_in' || 'checkin' || 'check-in' => CommunityPostKind.checkIn,
      'win' || 'wins' => CommunityPostKind.win,
      'relapse' || 'relapses' => CommunityPostKind.relapse,
      _ => CommunityPostKind.advice,
    };
  }
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.kind,
    required this.alias,
    required this.streakDays,
    this.topic,
    this.label,
    required this.message,
    required this.minutesAgo,
    this.supportCount = 0,
    this.commentCount = 0,
  });

  final int id;
  final CommunityPostKind kind;
  final String alias;
  final int streakDays;
  final String? topic;
  final String? label;
  final String message;
  final int minutesAgo;
  final int supportCount;
  final int commentCount;
}

class CommunityPostReply {
  const CommunityPostReply({
    required this.id,
    required this.postId,
    required this.alias,
    required this.streakDays,
    required this.message,
    required this.minutesAgo,
    this.supportCount = 0,
  });

  final int id;
  final int postId;
  final String alias;
  final int streakDays;
  final String message;
  final int minutesAgo;
  final int supportCount;
}

class CommunityMember {
  const CommunityMember({required this.alias, required this.streakDays});

  final String alias;
  final int streakDays;
}

class CommunityGroup {
  const CommunityGroup({
    required this.id,
    required this.name,
    required this.code,
    required this.members,
    required this.weeklyChangePercent,
  });

  final String id;
  final String name;
  final String code;
  final List<CommunityMember> members;
  final int weeklyChangePercent;
}

class ChatMessage {
  const ChatMessage({
    required this.fromAlias,
    required this.text,
    required this.isMe,
    this.replyToAlias,
    this.replyToText,
  });

  final String fromAlias;
  final String text;
  final bool isMe;
  final String? replyToAlias;
  final String? replyToText;
}
