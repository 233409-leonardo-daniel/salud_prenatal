import 'package:flutter/material.dart';
import '../../data/datasources/appointment_remote_data_source.dart';
import '../../data/models/appointment_model.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import '../../domain/usecases/get_appointments_usecase.dart';

class AppointmentProvider extends ChangeNotifier {
  final GetAppointmentsUseCase _getAppointmentsUseCase;

  AppointmentProvider({GetAppointmentsUseCase? getAppointmentsUseCase})
      : _getAppointmentsUseCase = getAppointmentsUseCase ??
            GetAppointmentsUseCase(
              repository: AppointmentRepositoryImpl(
                remoteDataSource: AppointmentRemoteDataSourceImpl(),
              ),
            );

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<AppointmentModel> _appointments = [];
  List<AppointmentModel> get appointments => _appointments;

  Future<void> fetchAppointments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _appointments = await _getAppointmentsUseCase.execute();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
