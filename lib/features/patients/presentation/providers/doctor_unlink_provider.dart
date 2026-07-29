import 'package:flutter/foundation.dart';
import '../../domain/entities/unlink_request.dart';
import '../../domain/usecases/get_doctor_unlink_requests_usecase.dart';
import '../../domain/usecases/resolve_unlink_request_usecase.dart';

enum DoctorUnlinkStatus { initial, loading, success, error }

/// Estado del lado doctor: la bandeja de solicitudes pendientes que se abre
/// desde la campana, y la resolución (aprobar/rechazar) de cada una.
class DoctorUnlinkProvider with ChangeNotifier {
  final GetDoctorUnlinkRequestsUsecase _getUseCase;
  final ResolveUnlinkRequestUsecase _resolveUseCase;

  DoctorUnlinkProvider(this._getUseCase, this._resolveUseCase);

  DoctorUnlinkStatus _status = DoctorUnlinkStatus.initial;
  String? _error;
  List<UnlinkRequestEntity> _pending = [];
  int? _resolvingId;

  DoctorUnlinkStatus get status => _status;
  String? get error => _error;
  List<UnlinkRequestEntity> get pending => _pending;
  int get pendingCount => _pending.length;
  int? get resolvingId => _resolvingId;

  Future<void> loadPending(int doctorId) async {
    _status = DoctorUnlinkStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _pending = await _getUseCase.call(doctorId, status: 'pending');
      _status = DoctorUnlinkStatus.success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = DoctorUnlinkStatus.error;
    } finally {
      notifyListeners();
    }
  }

  /// Actualiza solo el contador (para el badge de la campana) sin tocar el
  /// estado de una lista posiblemente abierta. Silencioso ante fallos.
  Future<void> refreshCount(int doctorId) async {
    try {
      _pending = await _getUseCase.call(doctorId, status: 'pending');
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> resolve(int doctorId, int requestId, String status) async {
    _resolvingId = requestId;
    _error = null;
    notifyListeners();
    try {
      await _resolveUseCase.call(doctorId, requestId, status);
      _pending = _pending.where((r) => r.unlinkRequestId != requestId).toList();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _resolvingId = null;
      notifyListeners();
    }
  }
}
