import 'package:flutter/material.dart';
import '../../data/datasources/login_remote_data_source.dart';
import '../../data/models/login_request.dart';
import '../../data/repositories/login_repository_impl.dart';
import '../../domain/usecases/login_usecase.dart';

class LoginProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;

  LoginProvider({LoginUseCase? loginUseCase})
      : _loginUseCase = loginUseCase ??
            LoginUseCase(
              repository: LoginRepositoryImpl(
                remoteDataSource: LoginRemoteDataSourceImpl(),
              ),
            );

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _token;
  String? get token => _token;

  String? _role;
  String? get role => _role;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _token = null;
    _role = null;
    notifyListeners();

    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _loginUseCase.execute(request);
      _token = response.accessToken;
      _role = response.role;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
