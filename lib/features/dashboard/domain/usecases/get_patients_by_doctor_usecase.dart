import '../repositories/dashboard_repository.dart';

class GetPatientsByDoctorUsecase {
  final DashboardRepository repository;

  GetPatientsByDoctorUsecase(this.repository);

  Future<List<Map<String, dynamic>>> call(int doctorId) {
    return repository.getPatientsByDoctor(doctorId);
  }
}
