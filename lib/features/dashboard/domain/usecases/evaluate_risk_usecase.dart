import '../../data/models/medical_record_response.dart';
import '../repositories/dashboard_repository.dart';

class EvaluateRiskUseCase {
  final DashboardRepository repository;

  EvaluateRiskUseCase(this.repository);

  Future<RiskPrediction> call(int medicalRecordId) {
    return repository.evaluateRisk(medicalRecordId);
  }
}
