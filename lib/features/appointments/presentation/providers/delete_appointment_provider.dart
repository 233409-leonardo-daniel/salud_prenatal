import 'package:flutter/foundation.dart';
import '../../domain/usecases/delete_appointment_usecase.dart';
import '../pages/appointment_state.dart';

class DeleteAppointmentProvider with ChangeNotifier {
  final DeleteAppointmentUsecase _deleteAppointmentUsecase;

  DeleteAppointmentProvider(this._deleteAppointmentUsecase);

  DeleteAppointmentStatus _status = DeleteAppointmentStatus.initial;
  String? _error;

  DeleteAppointmentStatus get status => _status;
  String? get error => _error;

  Future<void> deleteAppointment(String id) async {
    _status = DeleteAppointmentStatus.loading;
    _error = null;
    notifyListeners();

    try {
      await _deleteAppointmentUsecase.call(int.parse(id));
      _status = DeleteAppointmentStatus.success;
    } catch (e) {
      _status = DeleteAppointmentStatus.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _status = DeleteAppointmentStatus.initial;
    _error = null;
    notifyListeners();
  }
}
