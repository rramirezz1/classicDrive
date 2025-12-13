import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

/// Serviço para gestão de chat e mensagens.
class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;

  /// Obtém as conversas do utilizador atual.
  Future<List<ConversationModel>> getConversations(String userId) async {
    try {
      final response = await _supabase
          .from('conversations')
          .select()
          .or('participant_1_id.eq.$userId,participant_2_id.eq.$userId')
          .order('last_message_at', ascending: false);

      return (response as List)
          .map((e) => ConversationModel.fromMap(e))
          .toList();
    } catch (e) {
      print('Erro ao obter conversas: $e');
      return [];
    }
  }

  /// Obtém ou cria uma conversa entre dois utilizadores.
  Future<ConversationModel?> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
    String? currentUserName,
    String? otherUserName,
    String? vehicleId,
    String? vehicleName,
    String? bookingId,
  }) async {
    try {
      // Verificar se já existe uma conversa
      final existing = await _supabase
          .from('conversations')
          .select()
          .or('and(participant_1_id.eq.$currentUserId,participant_2_id.eq.$otherUserId),and(participant_1_id.eq.$otherUserId,participant_2_id.eq.$currentUserId)')
          .maybeSingle();

      if (existing != null) {
        return ConversationModel.fromMap(existing);
      }

      // Criar nova conversa
      final newConversation = ConversationModel(
        participant1Id: currentUserId,
        participant2Id: otherUserId,
        participant1Name: currentUserName,
        participant2Name: otherUserName,
        vehicleId: vehicleId,
        vehicleName: vehicleName,
        bookingId: bookingId,
        createdAt: DateTime.now(),
      );

      final response = await _supabase
          .from('conversations')
          .insert(newConversation.toMap())
          .select()
          .single();

      return ConversationModel.fromMap(response);
    } catch (e) {
      print('Erro ao criar/obter conversa: $e');
      return null;
    }
  }

  /// Obtém as mensagens de uma conversa.
  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((e) => MessageModel.fromMap(e))
          .toList();
    } catch (e) {
      print('Erro ao obter mensagens: $e');
      return [];
    }
  }

  /// Envia uma mensagem.
  Future<MessageModel?> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    try {
      final message = MessageModel(
        conversationId: conversationId,
        senderId: senderId,
        content: content,
        type: type,
        createdAt: DateTime.now(),
      );

      final response = await _supabase
          .from('messages')
          .insert(message.toMap())
          .select()
          .single();

      // Atualizar última mensagem na conversa
      await _supabase
          .from('conversations')
          .update({
            'last_message': content,
            'last_message_at': DateTime.now().toIso8601String(),
            'last_message_sender_id': senderId,
          })
          .eq('id', conversationId);

      return MessageModel.fromMap(response);
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
      return null;
    }
  }

  /// Subscribe to real-time messages for a conversation.
  Stream<List<MessageModel>> subscribeToMessages(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((data) => data.map((e) => MessageModel.fromMap(e)).toList());
  }

  /// Marca mensagens como lidas.
  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      await _supabase
          .from('messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .isFilter('read_at', null);
    } catch (e) {
      print('Erro ao marcar como lido: $e');
    }
  }

  /// Obtém contagem de mensagens não lidas.
  Future<int> getUnreadCount(String userId) async {
    try {
      final conversations = await getConversations(userId);
      int total = 0;
      
      for (final conv in conversations) {
        final response = await _supabase
            .from('messages')
            .select()
            .eq('conversation_id', conv.conversationId!)
            .neq('sender_id', userId)
            .isFilter('read_at', null);
        
        total += (response as List).length;
      }
      
      return total;
    } catch (e) {
      print('Erro ao contar não lidas: $e');
      return 0;
    }
  }

  /// Cancela subscriptions.
  void dispose() {
    _messagesSubscription?.cancel();
  }
}
