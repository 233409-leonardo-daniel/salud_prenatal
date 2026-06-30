import 'package:flutter/foundation.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_doctors_use_case.dart';
import '../../domain/usecases/get_patients_use_case.dart';

import '../../domain/usecases/get_user_by_id_use_case.dart';

enum UserViewState { initial, loading, success, error }

class UserProvider with ChangeNotifier {
  final GetDoctorsUseCase _getDoctorsUseCase;
  final GetPatientsUseCase _getPatientsUseCase;
  final GetUserByIdUseCase _getUserByIdUseCase;

  UserProvider(
      this._getDoctorsUseCase, this._getPatientsUseCase, this._getUserByIdUseCase);

  UserViewState _viewState = UserViewState.initial;
  String? _error;
  List<UserEntity> _users = [];

  UserViewState get viewState => _viewState;
  String? get error => _error;
  List<UserEntity> get users => _users;

  Future<void> loadDoctors({int? singleDoctorId}) async {
    _viewState = UserViewState.loading;
    _error = null;
    notifyListeners();

    try {
      if (singleDoctorId != null) {
        final user = await _getUserByIdUseCase.call(singleDoctorId);
        _users = [user];
      } else {
        _users = await _getDoctorsUseCase.call();
      }
      _viewState = UserViewState.success;
    } catch (e) {
      _viewState = UserViewState.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadPatients({int? doctorId}) async {
    _viewState = UserViewState.loading;
    _error = null;
    notifyListeners();

    try {
      _users = await _getPatientsUseCase.call(doctorId: doctorId);
      _viewState = UserViewState.success;
    } catch (e) {
      _viewState = UserViewState.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }
}
