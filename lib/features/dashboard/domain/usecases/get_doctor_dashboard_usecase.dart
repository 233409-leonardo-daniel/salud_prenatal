import '../repositories/dashboard_repository.dart';

class GetDoctorDashboardUseCase {
  final DashboardRepository _repository;

  GetDoctorDashboardUseCase(this._repository);

  Future<Map<String, dynamic>> call(int doctorId) async {
    return await _repository.getDoctorDashboard(doctorId);
  }
}
