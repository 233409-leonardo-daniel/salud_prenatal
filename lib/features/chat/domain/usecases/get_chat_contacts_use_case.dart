import '../../../login/domain/entities/user_profile.dart';
import '../repositories/chat_repository.dart';

class GetChatContactsUseCase {
  final ChatRepository repository;

  GetChatContactsUseCase(this.repository);

  Future<List<UserProfile>> call() => repository.getContacts();
}
