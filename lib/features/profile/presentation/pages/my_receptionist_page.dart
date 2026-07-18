import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/session/session_manager.dart';
import '../../../register/presentation/providers/register_provider.dart';
import '../providers/receptionist_provider.dart';

/// Vista "Mi Recepcionista" para el doctor: muestra los detalles de su
/// recepcionista y, en la parte superior, un botón para registrar una nueva
/// (si no tiene) o para eliminarla (si ya existe).
class MyReceptionistPage extends StatefulWidget {
  const MyReceptionistPage({super.key});

  @override
  State<MyReceptionistPage> createState() => _MyReceptionistPageState();
}

class _MyReceptionistPageState extends State<MyReceptionistPage> {
  static const _accent = Color(0xFF6A5ACD);
  static const _danger = Color(0xFFD32F2F);
  int? _doctorId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    _doctorId = context.read<SessionManager>().doctorId;
    final provider = context.read<ReceptionistProvider>();
    final id = _doctorId;
    if (id == null) {
      return;
    }
    provider.load(id);
  }

  Future<void> _openRegisterSheet() async {
    final id = _doctorId;
    if (id == null) return;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _CreateReceptionistSheet(doctorId: id),
      ),
    );
    if (created == true && mounted) {
      context.read<ReceptionistProvider>().load(id);
    }
  }

  Future<void> _onDelete() async {
    final provider = context.read<ReceptionistProvider>();
    final name = provider.receptionist?.fullName ?? 'la recepcionista';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar recepcionista'),
        content: Text(
          '¿Seguro que deseas eliminar a $name? Se borrará su cuenta y perderá '
          'el acceso a la aplicación. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final ok = await provider.delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Recepcionista eliminada correctamente.'
            : (provider.error ?? 'No se pudo eliminar la recepcionista.')),
        backgroundColor: ok ? _accent : _danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceptionistProvider>();
    final hasRecep = provider.hasReceptionist;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Recepcionista', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _accent,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        actions: [
          if (provider.status == ReceptionistStatus.success)
            if (hasRecep)
              IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: _onDelete,
              )
            else
              IconButton(
                tooltip: 'Registrar',
                icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                onPressed: _openRegisterSheet,
              ),
        ],
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(ReceptionistProvider provider) {
    switch (provider.status) {
      case ReceptionistStatus.initial:
      case ReceptionistStatus.loading:
        return const Center(child: CircularProgressIndicator(color: _accent));
      case ReceptionistStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: _danger, size: 48),
                const SizedBox(height: 12),
                Text(provider.error ?? 'Error al cargar', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _load,
                  style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      case ReceptionistStatus.success:
        return provider.hasReceptionist
            ? _buildDetails(provider.receptionist!)
            : _buildEmpty();
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 44, backgroundColor: _accent.withOpacity(0.12), child: const Icon(Icons.badge_outlined, size: 44, color: _accent)),
            const SizedBox(height: 20),
            Text('Aún no tienes recepcionista', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(
              'Registra a tu recepcionista para que te ayude a gestionar citas y pacientes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openRegisterSheet,
              icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
              label: const Text('Registrar recepcionista', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(Receptionist r) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: _accent.withOpacity(0.12),
                child: Text(
                  (r.name.isNotEmpty ? r.name[0] : 'R').toUpperCase(),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _accent),
                ),
              ),
              const SizedBox(height: 12),
              Text(r.fullName.isNotEmpty ? r.fullName : 'Recepcionista',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: _accent.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: const Text('Recepcionista', style: TextStyle(color: _accent, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.06) : Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _row(Icons.person_outline, 'Nombre completo', r.fullName.isNotEmpty ? r.fullName : 'No especificado'),
              const Divider(height: 1),
              _row(Icons.email_outlined, 'Correo electrónico', r.email.isNotEmpty ? r.email : 'No especificado'),
              const Divider(height: 1),
              _row(Icons.badge_outlined, 'Rol', 'Recepcionista'),
            ],
          ),
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: _onDelete,
          icon: Icon(Icons.delete_outline, color: _danger),
          label: Text('Eliminar recepcionista', style: TextStyle(color: _danger, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: _danger),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundColor: _accent.withOpacity(0.12), child: Icon(icon, size: 20, color: _accent)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hoja inferior para registrar una recepcionista (reutiliza
/// RegisterProvider.registerReceptionist). Devuelve `true` al crear con éxito.
class _CreateReceptionistSheet extends StatefulWidget {
  final int doctorId;
  const _CreateReceptionistSheet({required this.doctorId});

  @override
  State<_CreateReceptionistSheet> createState() => _CreateReceptionistSheetState();
}

class _CreateReceptionistSheetState extends State<_CreateReceptionistSheet> {
  static const _accent = Color(0xFF6A5ACD);
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _name.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _accent),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    final registerProvider = context.watch<RegisterProvider>();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _accent.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.person_add_alt_1_outlined, color: _accent),
                  ),
                  const SizedBox(width: 12),
                  Text('Crear Recepcionista', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(controller: _name, decoration: _dec('Nombre', Icons.person_outline),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el nombre' : null),
              const SizedBox(height: 14),
              TextFormField(controller: _lastName, decoration: _dec('Apellido', Icons.person_outline),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el apellido' : null),
              const SizedBox(height: 14),
              TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: _dec('Correo electrónico', Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa el correo';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return 'Correo no válido';
                    return null;
                  }),
              const SizedBox(height: 14),
              TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: _dec('Teléfono (opcional)', Icons.phone_outlined)),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: !_showPassword,
                decoration: _dec('Contraseña', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
                validator: (v) => v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: registerProvider.isLoading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        final ok = await registerProvider.registerReceptionist(
                          name: _name.text.trim(),
                          lastName: _lastName.text.trim(),
                          email: _email.text.trim(),
                          phone: _phone.text.trim(),
                          password: _password.text.trim(),
                          doctorId: widget.doctorId,
                        );
                        if (!mounted) return;
                        if (ok) {
                          Navigator.pop(context, true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(registerProvider.errorMessage ?? 'Error al crear recepcionista.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: registerProvider.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Crear cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
