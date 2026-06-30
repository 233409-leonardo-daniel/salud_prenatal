import 'package:flutter/foundation.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_doctors_use_case.dart';
import '../../domain/usecases/get_patients_use_case.dart';

enum UserViewState { initial, loading, success, error }

class UserProvider with ChangeNotifier {
  final GetDoctorsUseCase _getDoctorsUseCase;
  final GetPatientsUseCase _getPatientsUseCase;

  UserProvider(this._getDoctorsUseCase, this._getPatientsUseCase);

  UserViewState _viewState = UserViewState.initial;
  String? _error;
  List<UserEntity> _users = [];

  UserViewState get viewState => _viewState;
  String? get error => _error;
  List<UserEntity> get users => _users;

  Future<void> loadDoctors() async {
    _viewState = UserViewState.loading;
    _error = null;
    notifyListeners();

    try {
      _users = await _getDoctorsUseCase.call();
      _viewState = UserViewState.success;
    } catch (e) {
      _viewState = UserViewState.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadPatients() async {
    _viewState = UserViewState.loading;
    _error = null;
    notifyListeners();

    try {
      _users = await _getPatientsUseCase.call();
      _viewState = UserViewState.success;
    } catch (e) {
      _viewState = UserViewState.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }
}
