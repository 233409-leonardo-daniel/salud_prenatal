import '../../data/models/medical_record_response.dart';
import '../repositories/dashboard_repository.dart';

class CreateMedicalRecordUseCase {
  final DashboardRepository repository;

  CreateMedicalRecordUseCase(this.repository);

  Future<MedicalRecordResponse> call(Map<String, dynamic> recordData) {
    return repository.createMedicalRecord(recordData);
  }
}
