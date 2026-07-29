import '../data/datasources/chat_remote_data_source.dart';
import '../data/repositories/chat_repository_impl.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/usecases/get_conversations_usecase.dart';
import '../domain/usecases/get_chat_contacts_usecase.dart';
import '../../../../core/network/api_client.dart';

class ChatModule {
  late final ChatRemoteDataSource remoteDataSource;
  late final ChatRepository repository;
  late final GetConversationsUsecase getConversationsUseCase;
  late final GetChatContactsUsecase getChatContactsUseCase;

  ChatModule(ApiClient apiClient, {required TokenProvider tokenProvider}) {
    remoteDataSource = ChatRemoteDataSourceImpl(
      apiClient: apiClient,
      tokenProvider: tokenProvider,
    );
    repository = ChatRepositoryImpl(remoteDataSource);
    getConversationsUseCase = GetConversationsUsecase(repository);
    getChatContactsUseCase = GetChatContactsUsecase(repository);
  }
}
