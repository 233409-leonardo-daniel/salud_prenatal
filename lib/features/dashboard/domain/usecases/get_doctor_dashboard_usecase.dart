import '../repositories/dashboard_repository.dart';

class GetDoctorDashboardUsecase {
  final DashboardRepository _repository;

  GetDoctorDashboardUsecase(this._repository);

  Future<Map<String, dynamic>> call(int doctorId) async {
    return await _repository.getDoctorDashboard(doctorId);
  }
}
