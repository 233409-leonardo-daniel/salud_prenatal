import '../../data/models/register_request.dart';

abstract class RegisterRepository {
  Future<String> registerPatient(PatientRegisterRequest request);
  Future<String> registerDoctor(DoctorRegisterRequest request);
}
