import '../data/datasources/chat_remote_data_source.dart';
import '../data/repositories/chat_repository_impl.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/usecases/get_conversations_use_case.dart';
import '../domain/usecases/get_chat_contacts_use_case.dart';
import '../../../../core/network/api_client.dart';

class ChatModule {
  late final ChatRemoteDataSource remoteDataSource;
  late final ChatRepository repository;
  late final GetConversationsUseCase getConversationsUseCase;
  late final GetChatContactsUseCase getChatContactsUseCase;

  ChatModule(ApiClient apiClient, {required TokenProvider tokenProvider}) {
    remoteDataSource = ChatRemoteDataSourceImpl(
      apiClient: apiClient,
      tokenProvider: tokenProvider,
    );
    repository = ChatRepositoryImpl(remoteDataSource);
    getConversationsUseCase = GetConversationsUseCase(repository);
    getChatContactsUseCase = GetChatContactsUseCase(repository);
  }
}
