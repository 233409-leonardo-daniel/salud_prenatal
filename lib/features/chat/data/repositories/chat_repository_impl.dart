import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl({required ChatRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Stream<ChatMessage> get messageStream => _remoteDataSource.messageStream;

  @override
  Stream<bool> get connectionStatusStream => _remoteDataSource.connectionStatusStream;

  @override
  Future<List<ChatMessage>> getChatHistory(int otherUserId, int currentUserId) async {
    return await _remoteDataSource.getChatHistory(otherUserId, currentUserId);
  }

  @override
  Future<void> connect(int currentUserId) async {
    await _remoteDataSource.connect(currentUserId);
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
