import '../../data/models/consultation_response.dart';
import '../repositories/dashboard_repository.dart';

class GetConsultationsByMedicalRecordUseCase {
  final DashboardRepository repository;

  GetConsultationsByMedicalRecordUseCase(this.repository);

  Future<List<ConsultationResponse>> call(int medicalRecordId) {
    return repository.getConsultationsByMedicalRecord(medicalRecordId);
  }
}
