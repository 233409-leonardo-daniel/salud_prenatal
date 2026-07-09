import '../../data/models/register_request.dart';

abstract class RegisterRepository {
  Future<Map<String, dynamic>> registerPatient(PatientRegisterRequest request);
  Future<String> registerDoctor(DoctorRegisterRequest request);
  Future<String> registerReceptionist(ReceptionistRegisterRequest request, int doctorId);
}
