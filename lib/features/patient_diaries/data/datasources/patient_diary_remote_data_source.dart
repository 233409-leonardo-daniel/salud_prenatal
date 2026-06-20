import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../models/patient_diary_model.dart';
import '../../domain/entities/patient_diary.dart';

abstract class PatientDiaryRemoteDataSource {
  Future<List<PatientDiaryModel>> getDiariesByMedicalRecord(int medicalRecordId);
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

  PatientDiaryRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // Local fallback storage for mock offline mode
  static final List<PatientDiaryModel> _offlineDiaries = [
    PatientDiaryModel(
      patientDiaryId: 101,
      medicalRecordId: 1,
      weightKg: 68.5,
      systolic: 118,
      diastolic: 75,
      symptoms: "Ninguno",
      notes: "Presión normal, peso estable",
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    PatientDiaryModel(
      patientDiaryId: 102,
      medicalRecordId: 1,
      weightKg: 69.0,
      systolic: 120,
      diastolic: 80,
      symptoms: "Dolor de cabeza leve",
      notes: "Dolor de cabeza por la tarde, se quitó al descansar",
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<PatientDiaryModel>> getDiariesByMedicalRecord(int medicalRecordId) async {
    try {
      final response = await _apiClient.get('/patient-diaries/medical-record/$medicalRecordId');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => PatientDiaryModel.fromJson(item)).toList();
      }
      throw Exception('Error al obtener bitácoras (Status: ${response.statusCode})');
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('ClientException')) {
        await Future.delayed(const Duration(milliseconds: 500));
        return _offlineDiaries.where((d) => d.medicalRecordId == medicalRecordId).toList();
      }
      rethrow;
    }
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

    try {
      final response = await _apiClient.post('/patient-diaries/', payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return PatientDiaryModel.fromJson(data);
      }
      throw Exception('Error al crear bitácora (Status: ${response.statusCode})');
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('ClientException')) {
        await Future.delayed(const Duration(milliseconds: 500));
        final newDiary = PatientDiaryModel(
          patientDiaryId: _offlineDiaries.length + 103,
          medicalRecordId: diary.medicalRecordId,
          weightKg: diary.weightKg,
          systolic: diary.systolic,
          diastolic: diary.diastolic,
          symptoms: diary.symptoms,
          notes: diary.notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _offlineDiaries.add(newDiary);
        return newDiary;
      }
      rethrow;
    }
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

    try {
      final response = await _apiClient.put('/patient-diaries/$patientDiaryId', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PatientDiaryModel.fromJson(data);
      }
      throw Exception('Error al actualizar bitácora (Status: ${response.statusCode})');
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('ClientException')) {
        await Future.delayed(const Duration(milliseconds: 500));
        final index = _offlineDiaries.indexWhere((d) => d.patientDiaryId == patientDiaryId);
        if (index != -1) {
          final current = _offlineDiaries[index];
          final updated = PatientDiaryModel(
            patientDiaryId: current.patientDiaryId,
            medicalRecordId: current.medicalRecordId,
            weightKg: weightKg,
            systolic: systolic,
            diastolic: diastolic,
            symptoms: symptoms,
            notes: notes,
            createdAt: current.createdAt,
            updatedAt: DateTime.now(),
          );
          _offlineDiaries[index] = updated;
          return updated;
        }
        throw Exception('Bitácora no encontrada localmente');
      }
      rethrow;
    }
  }

  @override
  Future<void> deletePatientDiary(int patientDiaryId) async {
    try {
      final response = await _apiClient.delete('/patient-diaries/$patientDiaryId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar bitácora (Status: ${response.statusCode})');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('ClientException')) {
        await Future.delayed(const Duration(milliseconds: 500));
        _offlineDiaries.removeWhere((d) => d.patientDiaryId == patientDiaryId);
        return;
      }
      rethrow;
    }
  }
}
