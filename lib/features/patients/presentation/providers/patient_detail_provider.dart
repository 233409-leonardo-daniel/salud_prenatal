import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../domain/usecases/get_patient_details_usecase.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../pages/patient_state.dart';
import '../../../../core/network/api_client.dart';

class PatientDetailProvider with ChangeNotifier {
  final GetPatientDetailsUseCase _getPatientDetailsUseCase;

  PatientDetailProvider(this._getPatientDetailsUseCase);

  PatientDetailStatus _status = PatientDetailStatus.initial;
  String? _error;
  UserProfile? _currentPatientProfile;
  bool _hasMedicalRecord = false;
  Map<String, dynamic>? _rawRecordResponse;

  PatientDetailStatus get status => _status;
  String? get error => _error;
  UserProfile? get currentPatientProfile => _currentPatientProfile;
  bool get hasMedicalRecord => _hasMedicalRecord;
  Map<String, dynamic>? get rawRecordResponse => _rawRecordResponse;

  Future<void> loadPatientDetails(String userId, {int? patientId, int? doctorId}) async {
    _status = PatientDetailStatus.loading;
    _error = null;
    _currentPatientProfile = null;
    _hasMedicalRecord = false; // assume no record until API confirms
    _rawRecordResponse = null;
    notifyListeners();

    try {
      _currentPatientProfile = await _getPatientDetailsUseCase.call(userId);

      if (patientId != null) {
        try {
          final endpoint = doctorId != null
              ? '/medical-records/patient/$patientId?doctor_id=$doctorId'
              : '/medical-records/patient/$patientId';
          final response = await ApiClient().get(endpoint);
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            _rawRecordResponse = data;
            _hasMedicalRecord = data['medical_record'] != null;
          } else {
            _rawRecordResponse = null;
            _hasMedicalRecord = false;
          }
        } catch (e) {
          _rawRecordResponse = null;
          _hasMedicalRecord = false;
        }
      }

      _status = PatientDetailStatus.success;
    } catch (e) {
      _status = PatientDetailStatus.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void setMedicalRecordCreated() {
    _hasMedicalRecord = true;
    notifyListeners();
  }
}
