import '../repositories/patients_repository.dart';
import '../entities/patient.dart';

class GetDoctorPatientsUseCase {
  final PatientsRepository repository;

  GetDoctorPatientsUseCase(this.repository);

  Future<List<PatientEntity>> call(String doctorId) async {
    return await repository.getPatientsByDoctor(doctorId);
  }
}
