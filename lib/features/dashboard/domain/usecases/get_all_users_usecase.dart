import '../../../profile/domain/entities/user_profile.dart';
import '../repositories/dashboard_repository.dart';

class GetAllUsersUsecase {
  final DashboardRepository repository;

  GetAllUsersUsecase(this.repository);

  Future<List<UserProfile>> call() {
    return repository.getAllUsers();
  }
}
