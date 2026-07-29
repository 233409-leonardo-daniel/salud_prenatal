import '../repositories/dashboard_repository.dart';

class GetReceptionistDashboardUsecase {
  final DashboardRepository repository;

  GetReceptionistDashboardUsecase(this.repository);

  Future<Map<String, dynamic>> call(int receptionistId) {
    return repository.getReceptionistDashboard(receptionistId);
  }
}
