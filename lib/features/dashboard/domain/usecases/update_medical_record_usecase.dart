import '../../data/models/medical_record_response.dart';
import '../repositories/dashboard_repository.dart';

class UpdateMedicalRecordUsecase {
  final DashboardRepository repository;

  UpdateMedicalRecordUsecase(this.repository);

  Future<MedicalRecordResponse> call(int medicalRecordId, Map<String, dynamic> data) {
    return repository.updateMedicalRecord(medicalRecordId, data);
  }
}
