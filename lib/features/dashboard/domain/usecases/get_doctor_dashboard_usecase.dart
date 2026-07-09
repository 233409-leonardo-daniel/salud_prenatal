import '../repositories/dashboard_repository.dart';

class GetDoctorDashboardUseCase {
  final DashboardRepository repository;

  GetDoctorDashboardUseCase(this.repository);

  Future<Map<String, dynamic>> call(int doctorId) {
    return repository.getDoctorDashboard(doctorId);
  }
}
