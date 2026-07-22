import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/unlink_request.dart';
import '../providers/doctor_unlink_provider.dart';

/// Abre la bandeja de solicitudes de desvinculación del doctor. Se muestra de
/// inmediato y carga las solicitudes con un estado de carga interno (convención
/// UI del proyecto: no bloquear la apertura con un await previo).
void showDoctorUnlinkRequestsSheet(BuildContext context, int doctorId) {
  context.read<DoctorUnlinkProvider>().loadPending(doctorId);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _DoctorUnlinkRequestsSheet(doctorId: doctorId),
  );
}

class _DoctorUnlinkRequestsSheet extends StatelessWidget {
  final int doctorId;
  const _DoctorUnlinkRequestsSheet({required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.link_off, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Solicitudes de desvinculación',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Consumer<DoctorUnlinkProvider>(
              builder: (context, provider, _) {
                if (provider.status == DoctorUnlinkStatus.loading) {
                  return Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (provider.status == DoctorUnlinkStatus.error) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        provider.error ?? 'No se pudieron cargar las solicitudes.',
                        style: TextStyle(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final pending = provider.pending;
                if (pending.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, size: 40, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'No tienes solicitudes de desvinculación pendientes.',
                            style: TextStyle(color: AppColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: pending.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _RequestTile(doctorId: doctorId, request: pending[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final int doctorId;
  final UnlinkRequestEntity request;
  const _RequestTile({required this.doctorId, required this.request});

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _resolve(BuildContext context, String status) async {
    final provider = context.read<DoctorUnlinkProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final name = request.patientFullName ?? 'La paciente';

    if (status == 'approved') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Aprobar desvinculación'),
          content: Text(
            '¿Aprobar la desvinculación de $name? Dejará de estar en tu lista de '
            'pacientes y se cancelarán sus citas futuras contigo.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('Aprobar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final ok = await provider.resolve(doctorId, request.unlinkRequestId, status);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? (status == 'approved'
                ? '$name fue desvinculada.'
                : 'Solicitud rechazada.')
            : provider.error ?? 'Error al procesar la solicitud'),
        backgroundColor: ok ? null : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isResolving = context.select<DoctorUnlinkProvider, bool>(
      (p) => p.resolvingId == request.unlinkRequestId,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.06) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  (request.patientFullName?.isNotEmpty ?? false)
                      ? request.patientFullName![0].toUpperCase()
                      : 'P',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.patientFullName ?? 'Paciente #${request.patientId}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    if (request.createdAt != null)
                      Text(
                        'Solicitado el ${_formatDate(request.createdAt)}',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if ((request.reason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Motivo: ${request.reason}', style: TextStyle(fontSize: 13, color: AppColors.textDark)),
          ],
          const SizedBox(height: 14),
          if (isResolving)
            Center(child: CircularProgressIndicator(color: AppColors.primary))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _resolve(context, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: Text('Rechazar', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _resolve(context, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Aprobar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
