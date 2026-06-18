import 'package:flutter/foundation.dart';
import '../../data/models/login_request.dart';
import '../../domain/usecases/login_usecase.dart';
import '../pages/login_state.dart';

class LoginProvider with ChangeNotifier {
  final LoginUseCase _loginUseCase;

  LoginProvider(this._loginUseCase);

  LoginStatus _status = LoginStatus.initial;
  String? _errorMessage;
  String? _token;
  String? _role;

  LoginStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  String? get role => _role;

  /// Compatibilidad con código que usa [isLoading] directamente.
  bool get isLoading => _status == LoginStatus.loading;

  Future<bool> login(String email, String password) async {
    _status = LoginStatus.loading;
    _errorMessage = null;
    _token = null;
    _role = null;
    notifyListeners();

    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _loginUseCase.execute(request);
      _token = response.accessToken;
      _role = response.role;
      _status = LoginStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = LoginStatus.error;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _status = LoginStatus.initial;
    _errorMessage = null;
    _token = null;
    _role = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
