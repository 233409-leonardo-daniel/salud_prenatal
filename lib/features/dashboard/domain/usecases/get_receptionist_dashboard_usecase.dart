import '../repositories/dashboard_repository.dart';

class GetReceptionistDashboardUseCase {
  final DashboardRepository repository;

  GetReceptionistDashboardUseCase(this.repository);

  Future<Map<String, dynamic>> call(int receptionistId) {
    return repository.getReceptionistDashboard(receptionistId);
  }
}
