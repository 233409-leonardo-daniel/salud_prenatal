import 'package:flutter/foundation.dart';
import '../../domain/entities/unlink_request.dart';
import '../../domain/usecases/create_unlink_request_usecase.dart';
import '../../domain/usecases/get_patient_unlink_requests_usecase.dart';
import '../../domain/usecases/cancel_unlink_request_usecase.dart';

/// Estado del lado paciente: saber si ya tiene una solicitud pendiente (para
/// pintar el botón del dashboard como "Solicitud enviada") y poder crearla o
/// cancelarla.
class PatientUnlinkProvider with ChangeNotifier {
  final CreateUnlinkRequestUsecase _createUseCase;
  final GetPatientUnlinkRequestsUsecase _getUseCase;
  final CancelUnlinkRequestUsecase _cancelUseCase;

  PatientUnlinkProvider(this._createUseCase, this._getUseCase, this._cancelUseCase);

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  UnlinkRequestEntity? _pendingRequest;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  UnlinkRequestEntity? get pendingRequest => _pendingRequest;
  bool get hasPending => _pendingRequest != null;

  /// Carga la solicitud pendiente actual (si existe) para reflejar el estado
  /// en el dashboard. Silencioso: un fallo aquí no debe romper el dashboard.
  Future<void> loadPending(int patientId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final requests = await _getUseCase.call(patientId, status: 'pending');
      _pendingRequest = requests.isNotEmpty ? requests.first : null;
      _error = null;
    } catch (e) {
      _pendingRequest = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRequest(int patientId, String? reason) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      _pendingRequest = await _createUseCase.call(patientId, reason);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> cancelRequest(int patientId) async {
    final pending = _pendingRequest;
    if (pending == null) return false;
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _cancelUseCase.call(patientId, pending.unlinkRequestId);
      _pendingRequest = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
