import 'package:flutter/foundation.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/get_appointments_usecase.dart';

enum AppointmentsListStatus { initial, loading, success, error }

class AppointmentsProvider with ChangeNotifier {
  final GetAppointmentsByUserIdUsecase _getAppointmentsByUserIdUsecase;

  AppointmentsProvider(this._getAppointmentsByUserIdUsecase);

  AppointmentsListStatus _status = AppointmentsListStatus.initial;
  String? _error;
  List<Appointment> _appointments = [];

  AppointmentsListStatus get status => _status;
  String? get error => _error;
  List<Appointment> get appointments => _appointments;

  Future<void> loadAppointments(String userId) async {
    _status = AppointmentsListStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _appointments = await _getAppointmentsByUserIdUsecase.call(userId);
      _status = AppointmentsListStatus.success;
    } catch (e) {
      _status = AppointmentsListStatus.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _status = AppointmentsListStatus.initial;
    _error = null;
    _appointments = [];
    notifyListeners();
  }
}
