import '../models/register_request.dart';

abstract class RegisterRemoteDataSource {
  Future<String> registerPatient(PatientRegisterRequest request);
  Future<String> registerDoctor(DoctorRegisterRequest request);
}

class RegisterRemoteDataSourceImpl implements RegisterRemoteDataSource {
  @override
  Future<String> registerPatient(PatientRegisterRequest request) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    if (request.email.contains('@') && request.name.isNotEmpty) {
      return 'mock_patient_token_abc123';
    } else {
      throw Exception('Error al registrar paciente');
    }
  }

  @override
  Future<String> registerDoctor(DoctorRegisterRequest request) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    if (request.email.contains('@') && request.name.isNotEmpty) {
      return 'mock_doctor_token_xyz789';
    } else {
      throw Exception('Error al registrar médico');
    }
  }
}
