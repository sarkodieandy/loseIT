class CommunityPost {
  const CommunityPost({
    required this.alias,
    required this.streakDays,
    required this.message,
    required this.minutesAgo,
  });

  final String alias;
  final int streakDays;
  final String message;
  final int minutesAgo;
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
    required this.members,
    required this.weeklyChangePercent,
  });

  final String id;
  final String name;
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
