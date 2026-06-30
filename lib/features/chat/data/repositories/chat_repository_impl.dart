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
    final dtos = await _remoteDataSource.getConversations(currentUserId);
    return dtos.map((dto) => ConversationMapper.dtoToEntity(dto)).toList();
  }

  @override
  Future<List<ChatMessage>> getChatHistory(int otherUserId, int currentUserId) {
    return _remoteDataSource.getChatHistory(otherUserId, currentUserId);
  }

  @override
  Future<void> connect(int currentUserId) {
    return _remoteDataSource.connect(currentUserId);
  }

  @override
  void sendMessage(int receiverId, String content) {
    _remoteDataSource.sendMessage(receiverId, content);
  }

  @override
  void disconnect() {
    _remoteDataSource.disconnect();
  }
}
