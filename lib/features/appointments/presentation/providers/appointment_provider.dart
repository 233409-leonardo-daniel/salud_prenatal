import 'package:flutter/foundation.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/get_appointments_usecase.dart';
import '../../domain/usecases/get_appointments_use_case.dart';
import '../../domain/usecases/update_appointment_status_use_case.dart';
import '../../../../core/enums/appointment_status.dart';
import '../pages/appointment_state.dart';

class AppointmentsProvider with ChangeNotifier {
  final GetAppointmentsByUserIdUsecase _getAppointmentsByUserIdUsecase;
  final GetAppointmentsUseCase _getAppointmentsUseCase;
  final UpdateAppointmentStatusUseCase _updateAppointmentStatusUseCase;

  AppointmentsProvider(
    this._getAppointmentsByUserIdUsecase,
    this._getAppointmentsUseCase,
    this._updateAppointmentStatusUseCase,
  );

  AppointmentsListStatus _status = AppointmentsListStatus.initial;
  AppointmentActionStatus _viewState = AppointmentActionStatus.initial;
  String? _error;
  List<Appointment> _appointments = [];

  AppointmentsListStatus get status => _status;
  AppointmentActionStatus get viewState => _viewState;
  String? get error => _error;
  List<Appointment> get appointments => _appointments;

  Future<void> loadAppointments(String userId, {bool isDoctor = false}) async {
    _status = AppointmentsListStatus.loading;
    _error = null;
    _appointments = [];
    notifyListeners();

    try {
      _appointments = await _getAppointmentsByUserIdUsecase.call(userId, isDoctor: isDoctor);
      _status = AppointmentsListStatus.success;
    } catch (e) {
      _status = AppointmentsListStatus.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadAllAppointments({int? doctorId, int? patientId, String? status, String? date}) async {
    _viewState = AppointmentActionStatus.loading;
    _error = null;
    _appointments = [];
    notifyListeners();

    try {
      _appointments = await _getAppointmentsUseCase.call(
        doctorId: doctorId,
        patientId: patientId,
        status: status,
        date: date,
      );
      _viewState = AppointmentActionStatus.success;
    } catch (e) {
      _viewState = AppointmentActionStatus.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateAppointmentStatus(int id, AppointmentStatus status) async {
    _viewState = AppointmentActionStatus.loading;
    _error = null;
    notifyListeners();

    try {
      await _updateAppointmentStatusUseCase.call(id, status);
      // Reload list locally by updating the item if we want, or re-fetch.
      final index = _appointments.indexWhere((a) => a.id == id);
      if (index != -1) {
        final old = _appointments[index];
        _appointments[index] = Appointment(
          id: old.id,
          doctorId: old.doctorId,
          patientId: old.patientId,
          doctorName: old.doctorName,
          patientName: old.patientName,
          dateTime: old.dateTime,
          status: status,
          reason: old.reason,
        );
      }
      _viewState = AppointmentActionStatus.success;
    } catch (e) {
      _viewState = AppointmentActionStatus.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _status = AppointmentsListStatus.initial;
    _viewState = AppointmentActionStatus.initial;
    _error = null;
    _appointments = [];
    notifyListeners();
  }
}
