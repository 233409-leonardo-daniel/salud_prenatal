import '../repositories/dashboard_repository.dart';

class GetPatientDashboardUseCase {
  final DashboardRepository repository;

  GetPatientDashboardUseCase(this.repository);

  Future<Map<String, dynamic>> call(int patientId) {
    return repository.getPatientDashboard(patientId);
  }
}
