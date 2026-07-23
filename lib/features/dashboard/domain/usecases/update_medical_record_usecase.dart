import '../../data/models/medical_record_response.dart';
import '../repositories/dashboard_repository.dart';

class UpdateMedicalRecordUseCase {
  final DashboardRepository repository;

  UpdateMedicalRecordUseCase(this.repository);

  Future<MedicalRecordResponse> call(int medicalRecordId, Map<String, dynamic> data) {
    return repository.updateMedicalRecord(medicalRecordId, data);
  }
}
