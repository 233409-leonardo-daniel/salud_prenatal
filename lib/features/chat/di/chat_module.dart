import '../data/datasources/chat_remote_data_source.dart';
import '../data/repositories/chat_repository_impl.dart';
import '../domain/repositories/chat_repository.dart';

class ChatModule {
  late final ChatRemoteDataSource remoteDataSource;
  late final ChatRepository repository;

  ChatModule() {
    remoteDataSource = ChatRemoteDataSourceImpl();
    repository = ChatRepositoryImpl(remoteDataSource: remoteDataSource);
  }
}
