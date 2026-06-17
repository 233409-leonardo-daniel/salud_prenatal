import '../../data/models/register_request.dart';
import '../repositories/register_repository.dart';

class RegisterPatientUseCase {
  final RegisterRepository repository;

  const RegisterPatientUseCase({required this.repository});

  Future<String> execute(PatientRegisterRequest request) {
    return repository.registerPatient(request);
  }
}

class RegisterDoctorUseCase {
  final RegisterRepository repository;

  const RegisterDoctorUseCase({required this.repository});

  Future<String> execute(DoctorRegisterRequest request) {
    return repository.registerDoctor(request);
  }
}
