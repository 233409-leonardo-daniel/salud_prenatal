import '../repositories/dashboard_repository.dart';

class GetPatientsByDoctorUseCase {
  final DashboardRepository repository;

  GetPatientsByDoctorUseCase(this.repository);

  Future<List<Map<String, dynamic>>> call(int doctorId) {
    return repository.getPatientsByDoctor(doctorId);
  }
}
