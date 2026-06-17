import 'package:flutter/material.dart';
import '../pages/appointments_status.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/get_appointments_usecase.dart';

class AppointmentsProvider extends ChangeNotifier {
  final GetAppointmentsUseCase _getAppointmentsUseCase;

  AppointmentsProvider({required GetAppointmentsUseCase getAppointmentsUseCase})
      : _getAppointmentsUseCase = getAppointmentsUseCase;

  AppointmentsListStatus _status = AppointmentsListStatus.loading;
  AppointmentsListStatus get status => _status;

  String? _error;
  String? get error => _error;

  List<Appointment> _appointments = [];
  List<Appointment> get appointments => _appointments;

  Future<void> loadAppointments(String userId) async {
    _status = AppointmentsListStatus.loading;
    _error = null;
    notifyListeners();

    try {
      // The use case can be updated in the future to receive the userId
      _appointments = await _getAppointmentsUseCase.execute();
      _status = AppointmentsListStatus.success;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _status = AppointmentsListStatus.error;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
