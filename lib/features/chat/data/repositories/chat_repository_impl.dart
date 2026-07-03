import 'package:flutter/foundation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../mappers/conversation_mapper.dart';

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
      final dtos = await _remoteDataSource.getConversations(currentUserId);
      return dtos.map((dto) => ConversationMapper.dtoToEntity(dto)).toList();
    } catch (e) {
      debugPrint('Error en getConversations: $e');
      throw Exception('Error al obtener conversaciones: $e');
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
