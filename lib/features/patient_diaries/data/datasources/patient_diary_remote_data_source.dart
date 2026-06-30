import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../models/patient_diary_model.dart';
import '../../domain/entities/patient_diary.dart';

abstract class PatientDiaryRemoteDataSource {
  Future<List<PatientDiaryModel>> getDiariesByMedicalRecord(int medicalRecordId);
  Future<List<PatientDiaryModel>> getDiariesByPatientId(int patientId);
  Future<PatientDiaryModel> createPatientDiary(PatientDiary diary);
  Future<PatientDiaryModel> updatePatientDiary(
    int patientDiaryId,
    double weightKg,
    int systolic,
    int diastolic,
    String symptoms,
    String notes,
  );
  Future<void> deletePatientDiary(int patientDiaryId);
}

class PatientDiaryRemoteDataSourceImpl implements PatientDiaryRemoteDataSource {
  final ApiClient _apiClient;

  PatientDiaryRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<PatientDiaryModel>> getDiariesByMedicalRecord(int medicalRecordId) async {
    final response = await _apiClient.get('/patient-diaries/medical-record/$medicalRecordId');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => PatientDiaryModel.fromJson(item)).toList();
    }
    throw Exception('Error al obtener bitácoras (Status: ${response.statusCode})');
  }

  @override
  Future<List<PatientDiaryModel>> getDiariesByPatientId(int patientId) async {
    final response = await _apiClient.get('/patient-diaries/patient/$patientId');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => PatientDiaryModel.fromJson(item)).toList();
    }
    throw Exception('Error al obtener bitácoras (Status: ${response.statusCode})');
  }

  @override
  Future<PatientDiaryModel> createPatientDiary(PatientDiary diary) async {
    final payload = {
      'medical_record_id': diary.medicalRecordId,
      'weight_kg': diary.weightKg,
      'systolic': diary.systolic,
      'diastolic': diary.diastolic,
      'symptoms': diary.symptoms,
      'notes': diary.notes,
    };

    print('[PatientDiary] POST /patient-diaries/ payload: $payload');

    final response = await _apiClient.post('/patient-diaries/', payload);
    print('[PatientDiary] Response status: ${response.statusCode}, body: ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return PatientDiaryModel.fromJson(data);
    }
    throw Exception('Error al crear bitácora (Status: ${response.statusCode}) - ${response.body}');
  }

  @override
  Future<PatientDiaryModel> updatePatientDiary(
    int patientDiaryId,
    double weightKg,
    int systolic,
    int diastolic,
    String symptoms,
    String notes,
  ) async {
    final payload = {
      'weight_kg': weightKg,
      'systolic': systolic,
      'diastolic': diastolic,
      'symptoms': symptoms,
      'notes': notes,
    };

    final response = await _apiClient.put('/patient-diaries/$patientDiaryId', payload);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PatientDiaryModel.fromJson(data);
    }
    throw Exception('Error al actualizar bitácora (Status: ${response.statusCode})');
  }

  @override
  Future<void> deletePatientDiary(int patientDiaryId) async {
    final response = await _apiClient.delete('/patient-diaries/$patientDiaryId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar bitácora (Status: ${response.statusCode})');
    }
  }
}
