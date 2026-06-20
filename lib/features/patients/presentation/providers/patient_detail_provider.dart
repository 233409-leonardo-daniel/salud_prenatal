import 'package:flutter/foundation.dart';
import '../../domain/usecases/get_patient_details_usecase.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../pages/patient_state.dart';

class PatientDetailProvider with ChangeNotifier {
  final GetPatientDetailsUseCase _getPatientDetailsUseCase;

  PatientDetailProvider(this._getPatientDetailsUseCase);

  PatientDetailStatus _status = PatientDetailStatus.initial;
  String? _error;
  UserProfile? _currentPatientProfile;

  PatientDetailStatus get status => _status;
  String? get error => _error;
  UserProfile? get currentPatientProfile => _currentPatientProfile;

  Future<void> loadPatientDetails(String userId) async {
    _status = PatientDetailStatus.loading;
    _error = null;
    _currentPatientProfile = null;
    notifyListeners();

    try {
      _currentPatientProfile = await _getPatientDetailsUseCase.call(userId);
      _status = PatientDetailStatus.success;
    } catch (e) {
      _status = PatientDetailStatus.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }
}
