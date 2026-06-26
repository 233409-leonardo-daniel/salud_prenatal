import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../providers/dashboard_provider.dart';

class CreateMedicalRecordPage extends StatefulWidget {
  final int patientId;
  final String patientName;

  const CreateMedicalRecordPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<CreateMedicalRecordPage> createState() => _CreateMedicalRecordPageState();
}

class _CreateMedicalRecordPageState extends State<CreateMedicalRecordPage> {
  // Counters for history
  int _previousPregnancies = 0;
  int _previousDeliveries = 0;
  int _previousMiscarriages = 0;
  int _previousCesareans = 0;

  // Switches/Checkboxes for risk factors
  bool _previousHypertension = false;
  bool _diabetes = false;
  bool _familyHistoryHypertension = false;
  bool _previousPreeclampsia = false;
  bool _chronicKidneyDisease = false;
  bool _chronicHypertension = false;
  bool _multiplePregnancy = false;
  bool _fetalDeath = false;
  bool _fetalGrowthRestriction = false;
  bool _familyHistoryHeartDisease = false;
  bool _activeSmoking = false;

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final loginProvider = context.read<LoginProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nuevo Expediente'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Patient Info Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 24,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'ID Paciente: #SP-${widget.patientId.toString().padLeft(3, '0')}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 1: History Counters (Editable text fields)
            const Text(
              'Historial Obstétrico',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: const Color(0xFFF9F9FB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _buildNumberInputField(
                      label: 'Embarazos previos',
                      value: _previousPregnancies,
                      onChanged: (val) {
                        setState(() {
                          _previousPregnancies = val;
                        });
                      },
                    ),
                    const Divider(color: Color(0xFFF0F0F2)),
                    _buildNumberInputField(
                      label: 'Partos previos',
                      value: _previousDeliveries,
                      onChanged: (val) {
                        setState(() {
                          _previousDeliveries = val;
                        });
                      },
                    ),
                    const Divider(color: Color(0xFFF0F0F2)),
                    _buildNumberInputField(
                      label: 'Abortos previos',
                      value: _previousMiscarriages,
                      onChanged: (val) {
                        setState(() {
                          _previousMiscarriages = val;
                        });
                      },
                    ),
                    const Divider(color: Color(0xFFF0F0F2)),
                    _buildNumberInputField(
                      label: 'Cesáreas previas',
                      value: _previousCesareans,
                      onChanged: (val) {
                        setState(() {
                          _previousCesareans = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Section 2: Clinical Risks / Checkboxes
            const Text(
              'Antecedentes y Factores de Riesgo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildCheckboxRow(
              label: 'Hipertensión Previa',
              subtitle: 'Antecedentes personales de hipertensión antes del embarazo',
              value: _previousHypertension,
              onChanged: (val) => setState(() => _previousHypertension = val ?? false),
            ),
            _buildCheckboxRow(
              label: 'Preeclampsia Previa',
              subtitle: 'Antecedentes de preeclampsia en embarazos anteriores',
              value: _previousPreeclampsia,
              onChanged: (val) => setState(() => _previousPreeclampsia = val ?? false),
            ),
            _buildCheckboxRow(
              label: 'Hipertensión Crónica',
              subtitle: 'Diagnóstico de hipertensión crónica persistente',
              value: _chronicHypertension,
              onChanged: (val) => setState(() => _chronicHypertension = val ?? false),
            ),
            _buildCheckboxRow(
              label: 'Historia Familiar de Hipertensión',
              subtitle: 'Familiares directos con diagnóstico de hipertensión',
              value: _familyHistoryHypertension,
              onChanged: (val) => setState(() => _familyHistoryHypertension = val ?? false),
            ),
            _buildCheckboxRow(
              label: 'Diabetes',
              subtitle: 'Diabetes mellitus preexistente o gestacional',
              value: _diabetes,
              onChanged: (val) => setState(() => _diabetes = val ?? false),
            ),
            _buildCheckboxRow(
              label: 'Enfermedad Renal Crónica',
              subtitle: 'Alteraciones o insuficiencia renal diagnosticada',
              value: _chronicKidneyDisease,
              onChanged: (val) => setState(() => _chronicKidneyDisease = val ?? false),
            ),
            _buildCheckboxRow(
              label: 'Embarazo Múltiple',
              subtitle: 'Gestación actual de más de un feto',
              value: _multiplePregnancy,
              onChanged: (val) => setState(() => _multiplePregnancy = val ?? false),
            ),
            _buildCheckboxRow(
              label: 'Muerte Fetal Previa',
              subtitle: 'Antecedentes de pérdida fetal gestacional tardía',
              value: _fetalDeath,
              onChanged: (val) => setState(() => _fetalDeath = val ?? false),
            ),
            _buildCheckboxRow(
              label: 'Restricción del Crecimiento Fetal (RCIU)',
              subtitle: 'Antecedentes de retraso del crecimiento intrauterino',
              value: _fetalGrowthRestriction,
              onChanged: (val) => setState(() => _fetalGrowthRestriction = val ?? false),
            ),
            _buildCheckboxRow(
              label: 'Historia Familiar de Cardiopatía',
              subtitle: 'Antecedentes familiares de enfermedades cardíacas',
              value: _familyHistoryHeartDisease,
              onChanged: (val) => setState(() => _familyHistoryHeartDisease = val ?? false),
            ),
            _buildCheckboxRow(
              label: 'Tabaquismo Activo',
              subtitle: 'Consumo habitual de tabaco durante el embarazo',
              value: _activeSmoking,
              onChanged: (val) => setState(() => _activeSmoking = val ?? false),
            ),

            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: dashboardProvider.isSavingRecord
                  ? null
                  : () async {
                      final docId = loginProvider.doctorId ?? 1;

                      final Map<String, dynamic> recordPayload = {
                        "previous_hypertension": _previousHypertension,
                        "diabetes": _diabetes,
                        "family_history_hypertension": _familyHistoryHypertension,
                        "previous_pregnancies": _previousPregnancies,
                        "previous_deliveries": _previousDeliveries,
                        "previous_miscarriages": _previousMiscarriages,
                        "previous_cesareans": _previousCesareans,
                        "previous_preeclampsia": _previousPreeclampsia,
                        "chronic_kidney_disease": _chronicKidneyDisease,
                        "chronic_hypertension": _chronicHypertension,
                        "multiple_pregnancy": _multiplePregnancy,
                        "fetal_death": _fetalDeath,
                        "fetal_growth_restriction": _fetalGrowthRestriction,
                        "family_history_heart_disease": _familyHistoryHeartDisease,
                        "active_smoking": _activeSmoking,
                        "patient_id": widget.patientId,
                        "doctor_id": docId,
                      };

                      final success = await context
                          .read<DashboardProvider>()
                          .createMedicalRecord(recordPayload);

                      if (success) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Expediente clínico guardado exitosamente.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context, true);
                        }
                      } else {
                        if (mounted) {
                          final error = context.read<DashboardProvider>().errorMessage ??
                              'Error al crear el expediente.';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: dashboardProvider.isSavingRecord
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Guardar Expediente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInputField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: value.toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              onChanged: (val) {
                final parsed = int.tryParse(val) ?? 0;
                onChanged(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxRow({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: CheckboxListTile(
          activeColor: AppColors.primary,
          title: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          subtitle: subtitle.isNotEmpty
              ? Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                )
              : null,
          value: value,
          onChanged: onChanged,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    );
  }
}
