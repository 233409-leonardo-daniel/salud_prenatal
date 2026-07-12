import 'package:flutter/foundation.dart';

import '../../../login/domain/entities/user_profile.dart';
import '../../../login/domain/usecases/update_profile_usecase.dart';
import '../../../../core/session/session_manager.dart';

/// Provider de la operación de actualización de perfil.
///
/// Migrado fuera de `LoginProvider` para (a) no contaminar el login-flow ni el
/// [SessionManager] con el estado de guardado, y (b) eliminar por completo el
/// `_userPassword` en texto plano que se retenía en RAM: el perfil se envía
/// SIEMPRE con `password: null`, por lo que `UserProfile.toJson` omite la clave
/// y un update de perfil nunca toca la credencial.
class ProfileProvider with ChangeNotifier {
  final UpdateProfileUseCase _updateProfileUseCase;
  final SessionManager _session;

  ProfileProvider({
    required UpdateProfileUseCase updateProfileUseCase,
    required SessionManager session,
  })  : _updateProfileUseCase = updateProfileUseCase,
        _session = session;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> updateProfile({
    required String name,
    required String lastName,
    required String phone,
    String? email,
    String? imageUrl,
    String? specialty,
    String? professionalLicense,
    String? office,
  }) async {
    final userId = _session.userId;
    if (userId == null) {
      _errorMessage = 'Usuario no autenticado';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final current = _session.userProfile;
      final updatedProfile = UserProfile(
        userId: userId,
        name: name,
        lastName: lastName,
        email: email ?? current?.email ?? '',
        role: current?.role ?? 'paciente',
        phone: phone,
        imageUrl: imageUrl ?? current?.imageUrl ?? '',
        isActive: current?.isActive ?? true,
        createdAt: current?.createdAt ?? '',
        updatedAt: current?.updatedAt ?? '',
        password: null, // nunca se retiene ni reenvía la credencial
        specialty: specialty ?? current?.specialty,
        professionalLicense: professionalLicense ?? current?.professionalLicense,
        office: office ?? current?.office,
      );

      final updated = await _updateProfileUseCase.execute(userId, updatedProfile);
      _session.setUserProfile(updated);
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
}
