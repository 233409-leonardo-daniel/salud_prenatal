import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/dashboard_provider.dart';

/// Abre el diálogo para editar el plan general del expediente
/// (PUT /medical-records/{id}, partial update con solo `general_plan`).
/// Distinto del plan puntual de cada consulta. Devuelve `true` si se guardó
/// con éxito.
Future<bool?> showEditGeneralPlanDialog(
  BuildContext context, {
  required int medicalRecordId,
  required String? currentPlan,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => EditGeneralPlanDialog(
      medicalRecordId: medicalRecordId,
      currentPlan: currentPlan,
    ),
  );
}

class EditGeneralPlanDialog extends StatefulWidget {
  final int medicalRecordId;
  final String? currentPlan;

  const EditGeneralPlanDialog({
    super.key,
    required this.medicalRecordId,
    required this.currentPlan,
  });

  @override
  State<EditGeneralPlanDialog> createState() => _EditGeneralPlanDialogState();
}

class _EditGeneralPlanDialogState extends State<EditGeneralPlanDialog> {
  late final _planController = TextEditingController(text: widget.currentPlan ?? '');

  @override
  void dispose() {
    _planController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final provider = context.read<DashboardProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final text = _planController.text.trim();
    final success = await provider.updateGeneralPlan(
      widget.medicalRecordId,
      text.isEmpty ? null : text,
    );

    if (!mounted) return;
    if (success) {
      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Plan general actualizado correctamente.')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'No se pudo actualizar el plan general.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<DashboardProvider>().isUpdatingGeneralPlan;

    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Plan general del expediente',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
      ),
      content: SingleChildScrollView(
        child: TextFormField(
          controller: _planController,
          maxLines: 6,
          minLines: 4,
          style: TextStyle(color: AppColors.textDark),
          decoration: const InputDecoration(
            labelText: 'Plan general',
            hintText: 'Ej. Control mensual, monitorear presión, suplemento de hierro...',
            alignLabelWithHint: true,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context, false),
          child: Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
