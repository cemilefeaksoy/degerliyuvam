import 'user.dart';

class MessageItem {
  MessageItem({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.content,
    required this.imageUrl,
    required this.isRead,
    required this.isDeleted,
    required this.isEdited,
    required this.createdAt,
  });

  final int id;
  final int fromUserId;
  final int toUserId;
  final String content;
  final String imageUrl;
  final bool isRead;
  final bool isDeleted;
  final bool isEdited;
  final DateTime createdAt;

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      id: _asInt(json['id'] ?? json['Id']),
      fromUserId: _asInt(json['fromUserId'] ?? json['FromUserId']),
      toUserId: _asInt(json['toUserId'] ?? json['ToUserId']),
      content: _asString(json['content'] ?? json['Content']),
      imageUrl: _asString(json['imageUrl'] ?? json['ImageUrl']),
      isRead: _asBool(json['isRead'] ?? json['IsRead']),
      isDeleted: _asBool(json['isDeleted'] ?? json['IsDeleted']),
      isEdited: _asBool(json['isEdited'] ?? json['IsEdited']),
      createdAt: DateTime.tryParse(
              _asString(json['createdAt'] ?? json['CreatedAt'])) ??
          DateTime.now(),
    );
  }
}

class ConversationItem {
  ConversationItem({
    required this.partnerUserId,
    required this.partnerName,
    required this.partnerRole,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.lastFromMe,
  });

  final int partnerUserId;
  final String partnerName;
  final String partnerRole;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool lastFromMe;

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    return ConversationItem(
      partnerUserId: _asInt(json['partnerUserId'] ?? json['PartnerUserId']),
      partnerName: _asString(json['partnerName'] ?? json['PartnerName']),
      partnerRole: _roleLabel(json['partnerRole'] ?? json['PartnerRole']),
      lastMessage: _asString(json['lastMessage'] ?? json['LastMessage']),
      lastMessageAt: DateTime.tryParse(
              _asString(json['lastMessageAt'] ?? json['LastMessageAt'])) ??
          DateTime.now(),
      unreadCount: _asInt(json['unreadCount'] ?? json['UnreadCount']),
      lastFromMe: _asBool(json['lastFromMe'] ?? json['LastFromMe']),
    );
  }
}

class ConversationDetail {
  ConversationDetail(
      {required this.otherUser,
      required this.messages,
      required this.unreadCount});

  final User otherUser;
  final List<MessageItem> messages;
  final int unreadCount;

  factory ConversationDetail.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] ?? json['Messages'] ?? const [];
    return ConversationDetail(
      otherUser: User.fromJson(Map<String, dynamic>.from(
          json['otherUser'] ?? json['OtherUser'] ?? const {})),
      messages: rawMessages is List
          ? rawMessages
              .map((e) =>
                  MessageItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
      unreadCount: _asInt(json['unreadCount'] ?? json['UnreadCount']),
    );
  }
}

int _asInt(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
String _asString(dynamic value) => value == null ? '' : '$value';
bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = '$value'.toLowerCase();
  return normalized == 'true' || normalized == '1';
}

String _roleLabel(dynamic value) {
  if (value is num) {
    return value == 1 ? 'Admin' : 'Müşteri';
  }
  final raw = '$value';
  if (raw == '0') return 'Müşteri';
  if (raw == '1') return 'Admin';
  return raw;
}
