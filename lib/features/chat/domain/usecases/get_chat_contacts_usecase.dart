import '../../../profile/domain/entities/user_profile.dart';
import '../repositories/chat_repository.dart';

class GetChatContactsUsecase {
  final ChatRepository repository;

  GetChatContactsUsecase(this.repository);

  Future<List<UserProfile>> call() => repository.getContacts();
}
