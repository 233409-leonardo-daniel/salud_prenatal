import 'package:flutter/foundation.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../../domain/usecases/get_chat_contacts_use_case.dart';

enum ContactsStatus { initial, loading, success, error }

/// Lista de "con quién se puede empezar a chatear" para el diálogo de
/// "nuevo contacto" del chat, resuelta enteramente por el backend vía
/// GET /chat/contacts (filtra por rol del JWT: pacientes/doctores/
/// recepcionistas según corresponda) — el cliente no arma nada ni necesita
/// pasar doctorId/rol.
///
/// El status arranca en [ContactsStatus.initial] y pasa a `loading` de forma
/// síncrona (antes de cualquier `await`), así la UI que lo observa siempre
/// tiene un estado explícito desde el primer frame — no depende del timing
/// de un `Future` guardado aparte, que es lo que causaba la pantalla en
/// negro al abrir el diálogo directamente.
class ContactsProvider with ChangeNotifier {
  final GetChatContactsUseCase _getChatContactsUseCase;

  ContactsProvider(this._getChatContactsUseCase);

  ContactsStatus _status = ContactsStatus.initial;
  List<UserProfile> _contacts = [];
  String? _errorMessage;

  ContactsStatus get status => _status;
  List<UserProfile> get contacts => _contacts;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ContactsStatus.loading;

  Future<void> loadContacts() async {
    _status = ContactsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _contacts = await _getChatContactsUseCase.call();
      _status = ContactsStatus.success;
    } catch (e) {
      _status = ContactsStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }
}
