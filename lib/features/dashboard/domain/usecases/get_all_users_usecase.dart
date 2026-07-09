import '../../../login/domain/entities/user_profile.dart';
import '../repositories/dashboard_repository.dart';

class GetAllUsersUseCase {
  final DashboardRepository repository;

  GetAllUsersUseCase(this.repository);

  Future<List<UserProfile>> call() {
    return repository.getAllUsers();
  }
}
