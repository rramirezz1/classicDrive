/// Modelos para o sistema de chat.

/// Representa uma mensagem individual.
class MessageModel {
  final String? messageId;
  final String conversationId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final DateTime? readAt;

  MessageModel({
    this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    required this.createdAt,
    this.readAt,
  });

  bool get isRead => readAt != null;

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['id'],
      conversationId: map['conversation_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (map['message_type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      readAt: map['read_at'] != null
          ? DateTime.parse(map['read_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'message_type': type.name,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? messageId,
    String? conversationId,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

enum MessageType { text, image, system }

/// Representa uma conversa entre dois utilizadores.
class ConversationModel {
  final String? conversationId;
  final String participant1Id;
  final String participant2Id;
  final String? participant1Name;
  final String? participant2Name;
  final String? vehicleId;
  final String? vehicleName;
  final String? bookingId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final int unreadCount;
  final DateTime createdAt;

  ConversationModel({
    this.conversationId,
    required this.participant1Id,
    required this.participant2Id,
    this.participant1Name,
    this.participant2Name,
    this.vehicleId,
    this.vehicleName,
    this.bookingId,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.unreadCount = 0,
    required this.createdAt,
  });

  /// Obtém o ID do outro participante.
  String getOtherParticipantId(String currentUserId) {
    if (participant1Id == currentUserId) {
      return participant2Id;
    }
    return participant1Id;
  }

  /// Obtém o ID do outro participante.
  String getOtherParticipantId(String currentUserId) {
    if (participant1Id == currentUserId) {
      return participant2Id;
    }
    return participant1Id;
  }

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      conversationId: map['id'],
      participant1Id: map['participant_1_id'] ?? '',
      participant2Id: map['participant_2_id'] ?? '',
      participant1Name: map['participant_1_name'],
      participant2Name: map['participant_2_name'],
      vehicleId: map['vehicle_id'],
      vehicleName: map['vehicle_name'],
      bookingId: map['booking_id'],
      lastMessage: map['last_message'],
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'])
          : null,
      lastMessageSenderId: map['last_message_sender_id'],
      unreadCount: map['unread_count'] ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participant_1_id': participant1Id,
      'participant_2_id': participant2Id,
      'participant_1_name': participant1Name,
      'participant_2_name': participant2Name,
      'vehicle_id': vehicleId,
      'vehicle_name': vehicleName,
      'booking_id': bookingId,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message_sender_id': lastMessageSenderId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
