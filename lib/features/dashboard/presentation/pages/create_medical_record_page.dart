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
  // Perfil clínico base (ahora vive en el expediente, no en el registro)
  final _residenceController = TextEditingController();
  String _selectedBloodType = 'O+';
  final _heightController = TextEditingController();
  final _initialWeightController = TextEditingController();
  final _initialSystolicController = TextEditingController();
  final _initialDiastolicController = TextEditingController();
  final _weeksController = TextEditingController();
  final _lmpController = TextEditingController();
  final _educationController = TextEditingController();
  final _maritalStatusController = TextEditingController();

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
  void dispose() {
    _residenceController.dispose();
    _heightController.dispose();
    _initialWeightController.dispose();
    _initialSystolicController.dispose();
    _initialDiastolicController.dispose();
    _weeksController.dispose();
    _lmpController.dispose();
    _educationController.dispose();
    _maritalStatusController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final loginProvider = context.read<LoginProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Nuevo Expediente'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Patient Info Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 24,
                    child: Text(
                      widget.patientName.isNotEmpty ? widget.patientName[0].toUpperCase() : 'P',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patientName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'ID Paciente: #SP-${widget.patientId.toString().padLeft(3, '0')}',
                          style: TextStyle(
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
            SizedBox(height: 24),

            // Section 0: Perfil clínico base
            Text(
              'Perfil Clínico',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _residenceController,
              decoration: const InputDecoration(
                labelText: 'Residencia',
                prefixIcon: Icon(Icons.home_outlined),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedBloodType,
              decoration: const InputDecoration(
                labelText: 'Tipo de Sangre',
                prefixIcon: Icon(Icons.bloodtype_outlined),
              ),
              items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedBloodType = val);
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Altura (cm)',
                      prefixIcon: Icon(Icons.height_outlined),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _initialWeightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Peso inicial (kg)',
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _initialSystolicController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Presión sistólica inicial',
                      prefixIcon: Icon(Icons.favorite_border),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _initialDiastolicController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Presión diastólica inicial',
                      prefixIcon: Icon(Icons.favorite_border),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _weeksController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Semanas de Embarazo al Registro',
                prefixIcon: Icon(Icons.trending_up_outlined),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _lmpController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Fecha Última Regla (FUM)',
                prefixIcon: Icon(Icons.date_range_outlined),
              ),
              onTap: () => _selectDate(context, _lmpController),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _educationController,
              decoration: const InputDecoration(
                labelText: 'Escolaridad',
                prefixIcon: Icon(Icons.school_outlined),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _maritalStatusController,
              decoration: const InputDecoration(
                labelText: 'Estado Civil',
                prefixIcon: Icon(Icons.people_outline),
              ),
            ),
            SizedBox(height: 28),

            // Section 1: History Counters (Editable text fields)
            Text(
              'Historial Obstétrico',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 12),
            Card(
              elevation: 0,
              color: const Color(0xFFF9F9FB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            SizedBox(height: 28),

            // Section 2: Clinical Risks / Checkboxes
            Text(
              'Antecedentes y Factores de Riesgo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 12),
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

            SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: dashboardProvider.isSavingRecord
                  ? null
                  : () async {
                      final docId = loginProvider.doctorId;
                      if (docId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No se pudo identificar al médico de la sesión. Vuelve a iniciar sesión.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final Map<String, dynamic> recordPayload = {
                        "residence": _residenceController.text.trim().isEmpty ? null : _residenceController.text.trim(),
                        "blood_type": _selectedBloodType,
                        "height_cm": int.tryParse(_heightController.text.trim()),
                        "initial_weight": double.tryParse(_initialWeightController.text.trim()),
                        "initial_systolic": int.tryParse(_initialSystolicController.text.trim()),
                        "initial_diastolic": int.tryParse(_initialDiastolicController.text.trim()),
                        "weeks_at_registration": int.tryParse(_weeksController.text.trim()),
                        "last_menstrual_period": _lmpController.text.trim().isEmpty ? null : _lmpController.text.trim(),
                        "education_level": _educationController.text.trim().isEmpty ? null : _educationController.text.trim(),
                        "marital_status": _maritalStatusController.text.trim().isEmpty ? null : _maritalStatusController.text.trim(),
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
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: dashboardProvider.isSavingRecord
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Guardar Expediente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            SizedBox(height: 20),
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
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: value.toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
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
      padding: EdgeInsets.symmetric(vertical: 6.0),
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          subtitle: subtitle.isNotEmpty
              ? Text(
                  subtitle,
                  style: TextStyle(
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
