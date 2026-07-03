import '../../../login/domain/entities/user_profile.dart';
import '../../data/models/medical_record_response.dart';
import '../../data/models/consultation_response.dart';

/// Interfaz de dominio para las operaciones del dashboard (médico y
/// paciente). Antes DashboardProvider dependía directamente de
/// DashboardRemoteDataSource (capa data); esta interfaz es el punto de
/// inversión de dependencia que le faltaba a la feature.
///
/// Nota: por ahora se mantienen los mismos tipos de retorno que ya usaba el
/// datasource (incluyendo `Map<String, dynamic>` para pacientes y para el
/// dashboard del paciente). Tipar esos datos como entidades propias es una
/// mejora adicional recomendada, pero separada de este cambio.
abstract class DashboardRepository {
  Future<List<UserProfile>> getAllUsers();
  Future<List<Map<String, dynamic>>> getPatientsByDoctor(int doctorId);
  Future<MedicalRecordResponse?> getMedicalRecordByPatient(int patientId, {required int doctorId});
  Future<List<ConsultationResponse>> getConsultationsByMedicalRecord(int medicalRecordId);
  Future<List<ConsultationResponse>> getConsultationsFromPatientEndpoint(int patientId, {required int doctorId});
  Future<Map<String, dynamic>> getPatientDashboard(int patientId);
  Future<MedicalRecordResponse> createMedicalRecord(Map<String, dynamic> recordData);
}
