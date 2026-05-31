class Message {
  final String id;
  final String familyId;
  final String senderType;
  final String? senderParentId;
  final String? senderChildId;
  final String? receiverChildId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.familyId,
    required this.senderType,
    this.senderParentId,
    this.senderChildId,
    this.receiverChildId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  bool get isFromParent => senderType == 'parent';

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      familyId: json['family_id'],
      senderType: json['sender_type'],
      senderParentId: json['sender_parent_id'],
      senderChildId: json['sender_child_id'],
      receiverChildId: json['receiver_child_id'],
      content: json['content'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'family_id': familyId,
    'sender_type': senderType,
    'sender_parent_id': senderParentId,
    'sender_child_id': senderChildId,
    'receiver_child_id': receiverChildId,
    'content': content,
  };
}
