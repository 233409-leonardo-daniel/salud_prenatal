import 'package:flutter/foundation.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/create_appointment_usecase.dart';
import '../pages/appointment_state.dart';

class CreateAppointmentProvider with ChangeNotifier {
  final CreateAppointmentUsecase _createAppointmentUsecase;

  CreateAppointmentProvider(this._createAppointmentUsecase);

  CreateAppointmentStatus _status = CreateAppointmentStatus.initial;
  String? _error;

  CreateAppointmentStatus get status => _status;
  String? get error => _error;

  Future<void> createAppointment(Appointment appointment) async {
    _status = CreateAppointmentStatus.loading;
    _error = null;
    notifyListeners();

    try {
      await _createAppointmentUsecase.call(appointment);
      _status = CreateAppointmentStatus.success;
    } catch (e) {
      _status = CreateAppointmentStatus.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _status = CreateAppointmentStatus.initial;
    _error = null;
    notifyListeners();
  }
}
