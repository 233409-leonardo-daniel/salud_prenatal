import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/dashboard_provider.dart';

/// Abre el diálogo de "Nueva consulta" (POST /consultations/) para el
/// expediente [medicalRecordId] indicado. Devuelve `true` si la consulta se
/// creó con éxito (el llamador puede usarlo para refrescar su propia UI si
/// no observa directamente a [DashboardProvider]).
Future<bool?> showNewConsultationDialog(
  BuildContext context, {
  required int medicalRecordId,
  required String patientName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => NewConsultationDialog(
      medicalRecordId: medicalRecordId,
      patientName: patientName,
    ),
  );
}

class NewConsultationDialog extends StatefulWidget {
  final int medicalRecordId;
  final String patientName;

  const NewConsultationDialog({
    super.key,
    required this.medicalRecordId,
    required this.patientName,
  });

  @override
  State<NewConsultationDialog> createState() => _NewConsultationDialogState();
}

class _NewConsultationDialogState extends State<NewConsultationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reportedFactsController = TextEditingController();
  final _notesController = TextEditingController();
  final _objectiveController = TextEditingController();
  final _planController = TextEditingController();

  @override
  void dispose() {
    _reportedFactsController.dispose();
    _notesController.dispose();
    _objectiveController.dispose();
    _planController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<DashboardProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await provider.createConsultation(
      medicalRecordId: widget.medicalRecordId,
      reportedFacts: _reportedFactsController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      objective: _objectiveController.text.trim().isEmpty ? null : _objectiveController.text.trim(),
      plan: _planController.text.trim().isEmpty ? null : _planController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Consulta registrada correctamente.')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'No se pudo registrar la consulta.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<DashboardProvider>().isCreatingConsultation;

    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Nueva consulta — ${widget.patientName}',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _reportedFactsController,
                maxLines: 2,
                style: TextStyle(color: AppColors.textDark),
                decoration: const InputDecoration(
                  labelText: 'Motivo reportado por la paciente *',
                  hintText: 'Ej. Dolor de cabeza intenso desde hace 2 días',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _objectiveController,
                maxLines: 2,
                style: TextStyle(color: AppColors.textDark),
                decoration: const InputDecoration(
                  labelText: 'Objetivo de la consulta',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _planController,
                maxLines: 2,
                style: TextStyle(color: AppColors.textDark),
                decoration: const InputDecoration(
                  labelText: 'Plan / indicaciones',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: TextStyle(color: AppColors.textDark),
                decoration: const InputDecoration(
                  labelText: 'Notas adicionales',
                ),
              ),
            ],
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
