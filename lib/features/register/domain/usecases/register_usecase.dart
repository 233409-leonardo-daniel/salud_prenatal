import '../../data/models/register_request.dart';
import '../repositories/register_repository.dart';

class RegisterPatientUseCase {
  final RegisterRepository repository;

  const RegisterPatientUseCase({required this.repository});

  Future<Map<String, dynamic>> execute(PatientRegisterRequest request) {
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

class RegisterReceptionistUseCase {
  final RegisterRepository repository;

  const RegisterReceptionistUseCase({required this.repository});

  Future<String> execute(ReceptionistRegisterRequest request, int doctorId) {
    return repository.registerReceptionist(request, doctorId);
  }
}
