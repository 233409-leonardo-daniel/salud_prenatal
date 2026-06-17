import 'package:flutter/foundation.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/update_appointment_usecase.dart';

enum UpdateAppointmentStatus { initial, loading, success, error }

class UpdateAppointmentProvider with ChangeNotifier {
  final UpdateAppointmentUsecase _updateAppointmentUsecase;

  UpdateAppointmentProvider(this._updateAppointmentUsecase);

  UpdateAppointmentStatus _status = UpdateAppointmentStatus.initial;
  String? _error;

  UpdateAppointmentStatus get status => _status;
  String? get error => _error;

  Future<void> updateAppointment(Appointment appointment) async {
    _status = UpdateAppointmentStatus.loading;
    _error = null;
    notifyListeners();

    try {
      await _updateAppointmentUsecase.call(appointment);
      _status = UpdateAppointmentStatus.success;
    } catch (e) {
      _status = UpdateAppointmentStatus.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _status = UpdateAppointmentStatus.initial;
    _error = null;
    notifyListeners();
  }
}
