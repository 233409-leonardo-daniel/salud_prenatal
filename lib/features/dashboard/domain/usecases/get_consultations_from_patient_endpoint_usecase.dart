import '../../data/models/consultation_response.dart';
import '../repositories/dashboard_repository.dart';

class GetConsultationsFromPatientEndpointUsecase {
  final DashboardRepository repository;

  GetConsultationsFromPatientEndpointUsecase(this.repository);

  Future<List<ConsultationResponse>> call(int patientId, {required int doctorId}) {
    return repository.getConsultationsFromPatientEndpoint(patientId, doctorId: doctorId);
  }
}
