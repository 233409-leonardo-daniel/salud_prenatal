import 'package:flutter/foundation.dart';
import '../../domain/entities/chat_contact.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl(this._remoteDataSource);

  @override
  Stream<ChatMessage> get messageStream => _remoteDataSource.messageStream;

  @override
  Stream<bool> get connectionStatusStream => _remoteDataSource.connectionStatusStream;

  @override
  Future<List<Conversation>> getConversations(int currentUserId, List<ChatContact> contacts) async {
    // El backend no expone un endpoint de "inbox": se reconstruye la lista de
    // conversaciones pidiendo, en paralelo, el historial real de cada contacto
    // conocido (GET /chat/history/{other_user_id}) y quedándose con el último
    // mensaje y el conteo de no leídos de cada uno.
    final results = await Future.wait(contacts.map((contact) async {
      try {
        final history = await _remoteDataSource.getChatHistory(contact.userId, currentUserId);
        if (history.isEmpty) return null;

        final sorted = List<ChatMessageModel>.from(history)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        final last = sorted.last;
        final unreadCount = sorted
            .where((m) => m.receiverId == currentUserId && !m.isRead)
            .length;

        return Conversation(
          conversationId: contact.userId,
          participant1Id: currentUserId,
          participant2Id: contact.userId,
          participant1Name: '',
          participant2Name: contact.name,
          lastMessage: last,
          unreadCount: unreadCount,
          updatedAt: last.createdAt,
        );
      } catch (e) {
        debugPrint('Error al obtener historial con ${contact.userId}: $e');
        return null;
      }
    }));

    return results.whereType<Conversation>().toList();
  }

  @override
  Future<List<ChatMessage>> getChatHistory(int otherUserId, int currentUserId) async {
    try {
      return await _remoteDataSource.getChatHistory(otherUserId, currentUserId);
    } catch (e) {
      debugPrint('Error en getChatHistory: $e');
      throw Exception('Error al obtener el historial de chat: $e');
    }
  }

  @override
  Future<void> connect(int currentUserId) async {
    try {
      await _remoteDataSource.connect(currentUserId);
    } catch (e) {
      debugPrint('Error en connect: $e');
      throw Exception('Error al conectar al chat: $e');
    }
  }

  @override
  void sendMessage(int receiverId, String content) {
    try {
      _remoteDataSource.sendMessage(receiverId, content);
    } catch (e) {
      debugPrint('Error en sendMessage: $e');
    }
  }

  @override
  void disconnect() {
    try {
      _remoteDataSource.disconnect();
    } catch (e) {
      debugPrint('Error en disconnect: $e');
    }
  }
}
