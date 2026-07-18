import 'package:flutter/foundation.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl(this._remoteDataSource);

  @override
  Stream<ChatMessage> get messageStream => _remoteDataSource.messageStream;

  @override
  Stream<bool> get connectionStatusStream => _remoteDataSource.connectionStatusStream;

  @override
  Future<List<Conversation>> getConversations(int currentUserId) async {
    try {
      final inboxItems = await _remoteDataSource.getInbox();
      return inboxItems.map((item) {
        return Conversation(
          conversationId: item.otherUserId,
          participant1Id: currentUserId,
          participant2Id: item.otherUserId,
          participant1Name: '',
          participant2Name: '${item.otherUserName} ${item.otherUserLastname}'.trim(),
          lastMessage: item.lastMessage,
          unreadCount: item.unreadCount,
          updatedAt: item.lastMessage?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          otherUserRole: item.otherUserRole,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error en getConversations: $e');
      throw Exception('Error al obtener la bandeja de chat: $e');
    }
  }

  @override
  Future<List<UserProfile>> getContacts() async {
    try {
      return await _remoteDataSource.getContacts();
    } catch (e) {
      debugPrint('Error en getContacts: $e');
      throw Exception('Error al obtener contactos de chat: $e');
    }
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
  bool sendMessage(int receiverId, String content) {
    try {
      return _remoteDataSource.sendMessage(receiverId, content);
    } catch (e) {
      debugPrint('Error en sendMessage: $e');
      return false;
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
