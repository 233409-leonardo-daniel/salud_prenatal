import 'package:flutter/foundation.dart';
import '../../domain/entities/patient.dart';
import '../../domain/usecases/get_doctor_patients_usecase.dart';
import '../../domain/usecases/unlink_patient_usecase.dart';
import '../pages/patient_state.dart';

class PatientsListProvider with ChangeNotifier {
  final GetDoctorPatientsUseCase _getDoctorPatientsUseCase;
  final UnlinkPatientUseCase _unlinkPatientUseCase;

  PatientsListProvider(this._getDoctorPatientsUseCase, this._unlinkPatientUseCase);

  PatientsListStatus _status = PatientsListStatus.initial;
  String? _error;
  List<PatientEntity> _patients = [];
  bool _isUnlinking = false;

  PatientsListStatus get status => _status;
  String? get error => _error;
  List<PatientEntity> get patients => _patients;
  bool get isUnlinking => _isUnlinking;

  Future<void> loadPatients(String? doctorId) async {
    _status = PatientsListStatus.loading;
    _error = null;
    notifyListeners();

    if (doctorId == null || doctorId.isEmpty) {
      _status = PatientsListStatus.error;
      _error = 'El ID de médico no está disponible para consultar la lista de pacientes.';
      notifyListeners();
      return;
    }

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

  /// Rompe la relación doctor-paciente. Si el backend responde bien se quita
  /// la paciente de la lista en memoria, así "Mis Pacientes" queda al día sin
  /// tener que volver a pedir el listado completo.
  Future<bool> unlinkPatient(String doctorId, int patientId) async {
    _isUnlinking = true;
    _error = null;
    notifyListeners();

    try {
      await _unlinkPatientUseCase.call(doctorId, patientId.toString());
      _patients = _patients.where((p) => p.patientId != patientId).toList();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isUnlinking = false;
      notifyListeners();
    }
  }
}
