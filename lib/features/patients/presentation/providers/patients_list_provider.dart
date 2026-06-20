import 'package:flutter/foundation.dart';
import '../../domain/entities/patient.dart';
import '../../domain/usecases/get_doctor_patients_usecase.dart';
import '../pages/patient_state.dart';

class PatientsListProvider with ChangeNotifier {
  final GetDoctorPatientsUseCase _getDoctorPatientsUseCase;

  PatientsListProvider(this._getDoctorPatientsUseCase);

  PatientsListStatus _status = PatientsListStatus.initial;
  String? _error;
  List<PatientEntity> _patients = [];

  PatientsListStatus get status => _status;
  String? get error => _error;
  List<PatientEntity> get patients => _patients;

  Future<void> loadPatients(String doctorId) async {
    _status = PatientsListStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final results = await _getDoctorPatientsUseCase.call(doctorId);
      _patients = results;
      _status = PatientsListStatus.success;
    } catch (e) {
      _status = PatientsListStatus.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }
}
