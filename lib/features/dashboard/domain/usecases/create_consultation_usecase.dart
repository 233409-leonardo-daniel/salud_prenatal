import '../../data/models/consultation_response.dart';
import '../repositories/dashboard_repository.dart';

class CreateConsultationUsecase {
  final DashboardRepository repository;

  CreateConsultationUsecase(this.repository);

  Future<ConsultationResponse> call({
    required int medicalRecordId,
    String? notes,
    String? objective,
    String? plan,
    required String reportedFacts,
  }) {
    return repository.createConsultation(
      medicalRecordId: medicalRecordId,
      notes: notes,
      objective: objective,
      plan: plan,
      reportedFacts: reportedFacts,
    );
  }
}
