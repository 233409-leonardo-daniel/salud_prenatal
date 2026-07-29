import '../repositories/dashboard_repository.dart';

class GetPatientDashboardUsecase {
  final DashboardRepository repository;

  GetPatientDashboardUsecase(this.repository);

  Future<Map<String, dynamic>> call(int patientId) {
    return repository.getPatientDashboard(patientId);
  }
}
