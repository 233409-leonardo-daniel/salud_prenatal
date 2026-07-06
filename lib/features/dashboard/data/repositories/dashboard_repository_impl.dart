import '../../../login/domain/entities/user_profile.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_data_source.dart';
import '../models/medical_record_response.dart';
import '../models/consultation_response.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  const DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<UserProfile>> getAllUsers() {
    return remoteDataSource.getAllUsers();
  }

  @override
  Future<List<Map<String, dynamic>>> getPatientsByDoctor(int doctorId) {
    return remoteDataSource.getPatientsByDoctor(doctorId);
  }

  @override
  Future<MedicalRecordResponse?> getMedicalRecordByPatient(int patientId, {required int doctorId}) {
    return remoteDataSource.getMedicalRecordByPatient(patientId, doctorId: doctorId);
  }

  @override
  Future<List<ConsultationResponse>> getConsultationsByMedicalRecord(int medicalRecordId) {
    return remoteDataSource.getConsultationsByMedicalRecord(medicalRecordId);
  }

  @override
  Future<List<ConsultationResponse>> getConsultationsFromPatientEndpoint(int patientId, {required int doctorId}) {
    return remoteDataSource.getConsultationsFromPatientEndpoint(patientId, doctorId: doctorId);
  }

  @override
  Future<Map<String, dynamic>> getPatientDashboard(int patientId) {
    return remoteDataSource.getPatientDashboard(patientId);
  }

  @override
  Future<MedicalRecordResponse> createMedicalRecord(Map<String, dynamic> recordData) {
    return remoteDataSource.createMedicalRecord(recordData);
  }

  @override
  Future<RiskPrediction> evaluateRisk(int medicalRecordId) {
    return remoteDataSource.evaluateRisk(medicalRecordId);
  }
}
