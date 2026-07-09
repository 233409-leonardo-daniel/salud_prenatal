import '../../data/models/medical_record_response.dart';
import '../repositories/dashboard_repository.dart';

class GetMedicalRecordByPatientUseCase {
  final DashboardRepository repository;

  GetMedicalRecordByPatientUseCase(this.repository);

  Future<MedicalRecordResponse?> call(int patientId, {required int doctorId}) {
    return repository.getMedicalRecordByPatient(patientId, doctorId: doctorId);
  }
}
