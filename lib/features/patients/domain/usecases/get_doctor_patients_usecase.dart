import '../repositories/patients_repository.dart';
import '../entities/patient.dart';

class GetDoctorPatientsUsecase {
  final PatientsRepository repository;

  GetDoctorPatientsUsecase(this.repository);

  Future<List<PatientEntity>> call(String doctorId) async {
    return await repository.getPatientsByDoctor(doctorId);
  }
}
