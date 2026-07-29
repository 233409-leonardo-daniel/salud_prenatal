import '../../data/models/register_request.dart';
import '../repositories/register_repository.dart';

class RegisterPatientUsecase {
  final RegisterRepository repository;

  const RegisterPatientUsecase({required this.repository});

  Future<Map<String, dynamic>> execute(PatientRegisterRequest request) {
    return repository.registerPatient(request);
  }
}

class RegisterDoctorUsecase {
  final RegisterRepository repository;

  const RegisterDoctorUsecase({required this.repository});

  Future<String> execute(DoctorRegisterRequest request) {
    return repository.registerDoctor(request);
  }
}

class RegisterReceptionistUsecase {
  final RegisterRepository repository;

  const RegisterReceptionistUsecase({required this.repository});

  Future<String> execute(ReceptionistRegisterRequest request, int doctorId) {
    return repository.registerReceptionist(request, doctorId);
  }
}
