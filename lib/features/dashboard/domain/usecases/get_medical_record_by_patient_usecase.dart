import '../../data/models/medical_record_response.dart';
import '../repositories/dashboard_repository.dart';

class GetMedicalRecordByPatientUsecase {
  final DashboardRepository repository;

  GetMedicalRecordByPatientUsecase(this.repository);

  Future<MedicalRecordResponse?> call(int patientId, {required int doctorId}) {
    return repository.getMedicalRecordByPatient(patientId, doctorId: doctorId);
  }
}
