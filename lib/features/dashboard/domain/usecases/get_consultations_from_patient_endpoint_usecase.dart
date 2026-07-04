import '../../data/models/consultation_response.dart';
import '../repositories/dashboard_repository.dart';

class GetConsultationsFromPatientEndpointUseCase {
  final DashboardRepository repository;

  GetConsultationsFromPatientEndpointUseCase(this.repository);

  Future<List<ConsultationResponse>> call(int patientId, {required int doctorId}) {
    return repository.getConsultationsFromPatientEndpoint(patientId, doctorId: doctorId);
  }
}
