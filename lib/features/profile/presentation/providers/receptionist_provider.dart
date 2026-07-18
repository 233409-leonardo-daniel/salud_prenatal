import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';

/// Datos de la recepcionista tal como los devuelve
/// GET /doctors/{doctor_id}/receptionists (ReceptionistResponse).
/// Nota: la lista NO incluye `receptionist_id` ni `phone` (solo el endpoint de
/// detalle los trae); por eso aquí se muestran nombre, correo y rol.
class Receptionist {
  final int userId;
  final String name;
  final String lastName;
  final String email;
  final String role;

  Receptionist({
    required this.userId,
    required this.name,
    required this.lastName,
    required this.email,
    required this.role,
  });

  factory Receptionist.fromJson(Map<String, dynamic> j) => Receptionist(
        userId: j['user_id'] ?? j['userId'] ?? 0,
        name: j['name'] ?? '',
        lastName: j['last_name'] ?? j['lastName'] ?? '',
        email: j['email'] ?? '',
        role: j['role'] ?? 'recepcionista',
      );

  String get fullName => '$name $lastName'.trim();
}

enum ReceptionistStatus { initial, loading, success, error }

class ReceptionistProvider with ChangeNotifier {
  final ApiClient _apiClient;
  ReceptionistProvider(this._apiClient);

  ReceptionistStatus _status = ReceptionistStatus.initial;
  String? _error;
  Receptionist? _receptionist;

  ReceptionistStatus get status => _status;
  String? get error => _error;
  Receptionist? get receptionist => _receptionist;
  bool get hasReceptionist => _receptionist != null;

  /// Carga la recepcionista del doctor. La API devuelve una lista; se toma la
  /// primera (el modelo de negocio es 1 recepcionista por doctor).
  Future<void> load(int doctorId) async {
    _status = ReceptionistStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final res = await _apiClient.get('/doctors/$doctorId/receptionists');
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List list = decoded is List ? decoded : const [];
        _receptionist = list.isNotEmpty
            ? Receptionist.fromJson(Map<String, dynamic>.from(list.first))
            : null;
        _status = ReceptionistStatus.success;
      } else {
        _error = 'No se pudo cargar la recepcionista (código ${res.statusCode}).';
        _status = ReceptionistStatus.error;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _status = ReceptionistStatus.error;
    }
    notifyListeners();
  }

  bool _deleting = false;
  bool get isDeleting => _deleting;

  /// Elimina a la recepcionista usando el endpoint de borrado de usuarios
  /// (DELETE /users/{user_id}, responde 204). La lista de recepcionistas sí
  /// expone `user_id`, así que no se necesita el `receptionist_id`.
  Future<bool> delete() async {
    final r = _receptionist;
    if (r == null || r.userId == 0) {
      _error = 'No se pudo identificar a la recepcionista.';
      notifyListeners();
      return false;
    }
    _deleting = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _apiClient.delete('/users/${r.userId}');
      if (res.statusCode == 204 || res.statusCode == 200) {
        _receptionist = null;
        _deleting = false;
        notifyListeners();
        return true;
      }
      _error = 'No se pudo eliminar (código ${res.statusCode}).';
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    _deleting = false;
    notifyListeners();
    return false;
  }
}
