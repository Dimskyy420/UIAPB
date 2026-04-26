class ChatRoomModel {
  final String id;
  final String requestId;
  final String requestTitle;
  final String requesterId; // userId yang minta bantuan
  final String helperId;   // userId helper
  final String lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCount; // {'uid1': 2, 'uid2': 0}

  ChatRoomModel({
    required this.id,
    required this.requestId,
    required this.requestTitle,
    required this.requesterId,
    required this.helperId,
    this.lastMessage = '',
    this.lastMessageAt,
    this.unreadCount = const {},
  });

  factory ChatRoomModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatRoomModel(
      id: id,
      requestId: map['requestId'] ?? '',
      requestTitle: map['requestTitle'] ?? '',
      requesterId: map['requesterId'] ?? '',
      helperId: map['helperId'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageAt: map['lastMessageAt']?.toDate(),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'requestTitle': requestTitle,
      'requesterId': requesterId,
      'helperId': helperId,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt,
      'unreadCount': unreadCount,
    };
  }
}

class ChatMessageModel {
  final String? id;
  final String senderUid;
  final String text;
  final DateTime? createdAt;
  final bool isRead;

  ChatMessageModel({
    this.id,
    required this.senderUid,
    required this.text,
    this.createdAt,
    this.isRead = false,
  });

  factory ChatMessageModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessageModel(
      id: id,
      senderUid: map['senderUid'] ?? '',
      text: map['text'] ?? '',
      createdAt: map['createdAt']?.toDate(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderUid': senderUid,
      'text': text,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }
}