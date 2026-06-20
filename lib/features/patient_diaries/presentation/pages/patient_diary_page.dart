import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../providers/patient_diaries_provider.dart';
import '../../domain/entities/patient_diary.dart';

class PatientDiaryPage extends StatefulWidget {
  const PatientDiaryPage({super.key});

  @override
  State<PatientDiaryPage> createState() => _PatientDiaryPageState();
}

class _PatientDiaryPageState extends State<PatientDiaryPage> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadData();
      _isInitialized = true;
    }
  }

  Future<void> _loadData() async {
    final loginProvider = context.read<LoginProvider>();
    final dashboardProvider = context.read<DashboardProvider>();
    final diariesProvider = context.read<PatientDiariesProvider>();

    if (dashboardProvider.medicalRecord == null) {
      final patId = loginProvider.patientId ?? loginProvider.userId ?? 2;
      await dashboardProvider.loadPatientDashboard(patId, loginProvider.userId ?? 2);
    }

    final medicalRecordId = dashboardProvider.medicalRecord?.medicalRecordId ?? 1;
    diariesProvider.loadDiaries(medicalRecordId);
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final monthList = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final month = monthList[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  Map<String, dynamic> _evaluatePressureRisk(int systolic, int diastolic) {
    if (systolic >= 140 || diastolic >= 90) {
      return {
        'label': 'Riesgo Alto',
        'color': AppColors.riskHighText,
        'bgColor': AppColors.riskHighBg,
        'icon': Icons.warning_amber_rounded,
        'message': 'Presión arterial alta. Reposa y contacta a tu médico.'
      };
    } else if (systolic >= 130 || diastolic >= 85) {
      return {
        'label': 'Riesgo Medio',
        'color': AppColors.riskMediumText,
        'bgColor': AppColors.riskMediumBg,
        'icon': Icons.info_outline,
        'message': 'Presión arterial ligeramente elevada. Mantente en monitoreo.'
      };
    } else {
      return {
        'label': 'Normal',
        'color': AppColors.riskLowText,
        'bgColor': AppColors.riskLowBg,
        'icon': Icons.check_circle_outline,
        'message': 'Tu presión arterial está dentro de los rangos normales.'
      };
    }
  }

  void _showFormDialog(BuildContext context, {PatientDiary? diary}) {
    final dashboardProvider = context.read<DashboardProvider>();
    final diariesProvider = context.read<PatientDiariesProvider>();
    final medicalRecordId = dashboardProvider.medicalRecord?.medicalRecordId ?? 1;

    final formKey = GlobalKey<FormState>();
    final weightController = TextEditingController(
      text: diary != null ? diary.weightKg.toString() : '',
    );
    final systolicController = TextEditingController(
      text: diary != null ? diary.systolic.toString() : '',
    );
    final diastolicController = TextEditingController(
      text: diary != null ? diary.diastolic.toString() : '',
    );
    final symptomsController = TextEditingController(
      text: diary != null ? diary.symptoms : '',
    );
    final notesController = TextEditingController(
      text: diary != null ? diary.notes : '',
    );

    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Row(
                children: [
                  Icon(
                    diary != null ? Icons.edit_note : Icons.add_chart,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    diary != null ? 'Editar Registro' : 'Nueva Medición',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Ingresa tus mediciones del día. Es importante no omitir ningún dato.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: systolicController,
                              keyboardType: TextInputType.number,
                              enabled: !isSubmitting,
                              decoration: const InputDecoration(
                                labelText: 'Sistólica (mmHg)',
                                hintText: 'Ej. 120',
                                prefixIcon: Icon(Icons.favorite, color: AppColors.primary, size: 20),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Requerido';
                                }
                                final valInt = int.tryParse(val.trim());
                                if (valInt == null || valInt <= 0) {
                                  return 'Inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: diastolicController,
                              keyboardType: TextInputType.number,
                              enabled: !isSubmitting,
                              decoration: const InputDecoration(
                                labelText: 'Diastólica (mmHg)',
                                hintText: 'Ej. 80',
                                prefixIcon: Icon(Icons.favorite_border, color: AppColors.primary, size: 20),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Requerido';
                                }
                                final valInt = int.tryParse(val.trim());
                                if (valInt == null || valInt <= 0) {
                                  return 'Inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        enabled: !isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Peso actual (kg)',
                          hintText: 'Ej. 65.4',
                          prefixIcon: Icon(Icons.monitor_weight_outlined, color: AppColors.primary, size: 20),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Por favor ingresa tu peso';
                          }
                          final valDouble = double.tryParse(val.trim());
                          if (valDouble == null || valDouble <= 0) {
                            return 'Ingresa un peso válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: symptomsController,
                        enabled: !isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Síntomas (Opcional)',
                          hintText: 'Ej. Dolor de cabeza, náuseas...',
                          prefixIcon: Icon(Icons.sick_outlined, color: AppColors.primary, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: notesController,
                        enabled: !isSubmitting,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notas / Observaciones',
                          hintText: '¿Cómo te sientes hoy?',
                          prefixIcon: Icon(Icons.edit_note, color: AppColors.primary, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (!formKey.currentState!.validate()) return;

                    setDialogState(() {
                      isSubmitting = true;
                    });

                    final weight = double.parse(weightController.text.trim());
                    final systolic = int.parse(systolicController.text.trim());
                    final diastolic = int.parse(diastolicController.text.trim());
                    final symptoms = symptomsController.text.trim().isEmpty ? 'Ninguno' : symptomsController.text.trim();
                    final notes = notesController.text.trim().isEmpty ? 'Sin notas adicionales' : notesController.text.trim();

                    bool success;
                    if (diary == null) {
                      success = await diariesProvider.createDiary(
                        medicalRecordId: medicalRecordId,
                        weightKg: weight,
                        systolic: systolic,
                        diastolic: diastolic,
                        symptoms: symptoms,
                        notes: notes,
                      );
                    } else {
                      success = await diariesProvider.updateDiary(
                        patientDiaryId: diary.patientDiaryId,
                        weightKg: weight,
                        systolic: systolic,
                        diastolic: diastolic,
                        symptoms: symptoms,
                        notes: notes,
                      );
                    }

                    if (!dialogCtx.mounted) return;

                    if (success) {
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            diary == null
                                ? 'Medición registrada correctamente.'
                                : 'Medición actualizada correctamente.',
                          ),
                          backgroundColor: Colors.green.shade600,
                        ),
                      );
                    } else {
                      setDialogState(() {
                        isSubmitting = false;
                      });
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                        SnackBar(
                          content: Text(
                            diariesProvider.errorMessage ?? 'Ocurrió un error inesperado.',
                          ),
                          backgroundColor: Colors.red.shade600,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(diary == null ? 'Registrar' : 'Guardar', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, int patientDiaryId) {
    final diariesProvider = context.read<PatientDiariesProvider>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Eliminar Registro', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              content: const Text('¿Estás segura de que deseas eliminar esta medición de tu bitácora? Esta acción no se puede deshacer.'),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    setDialogState(() {
                      isSubmitting = true;
                    });
                    final success = await diariesProvider.deleteDiary(patientDiaryId);
                    if (!dialogCtx.mounted) return;

                    if (success) {
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Registro eliminado de tu bitácora.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      setDialogState(() {
                        isSubmitting = false;
                      });
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                        SnackBar(
                          content: Text(diariesProvider.errorMessage ?? 'Error al eliminar el registro.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final diariesProvider = context.watch<PatientDiariesProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text(
          'Mi Bitácora de Salud',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(diariesProvider),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva medición', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBody(PatientDiariesProvider provider) {
    if (provider.isLoading && provider.diaries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.status == PatientDiariesStatus.error && provider.diaries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 54, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage ?? 'Ocurrió un error al cargar la bitácora.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.diaries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_stories_outlined, size: 64, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tu bitácora está vacía',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Llevar un registro diario de tu presión arterial y peso te ayuda a prevenir complicaciones durante tu embarazo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Registrar mi primer medición', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    // Header showing the summary of the last reading
    final latest = provider.diaries.first;
    final riskEval = _evaluatePressureRisk(latest.systolic, latest.diastolic);

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Elegant summary card for the last record
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withRed(220)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ÚLTIMO REGISTRO',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.white70, size: 16),
                            SizedBox(width: 4),
                            Text('Presión Arterial', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${latest.systolic}/${latest.diastolic}',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const Text('mmHg', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.monitor_weight, color: Colors.white70, size: 16),
                            SizedBox(width: 4),
                            Text('Peso Actual', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${latest.weightKg}',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const Text('kg', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(riskEval['icon'] as IconData, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          riskEval['message'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'HISTORIAL DE MEDICIONES',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.diaries.length,
            itemBuilder: (context, index) {
              final item = provider.diaries[index];
              final itemRisk = _evaluatePressureRisk(item.systolic, item.diastolic);

              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade100, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDateTime(item.createdAt),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: itemRisk['bgColor'] as Color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              itemRisk['label'] as String,
                              style: TextStyle(
                                color: itemRisk['color'] as Color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.pink.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.favorite_outline, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Presión', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                    Text(
                                      '${item.systolic}/${item.diastolic}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                                    ),
                                    const Text('mmHg', style: TextStyle(color: AppColors.textMuted, fontSize: 9)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.pink.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.monitor_weight_outlined, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Peso', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                    Text(
                                      '${item.weightKg} kg',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                                    ),
                                    const Text('Kilogramos', style: TextStyle(color: AppColors.textMuted, fontSize: 9)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF2F2F7)),
                      const SizedBox(height: 12),
                      if (item.symptoms.isNotEmpty && item.symptoms != 'Ninguno') ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Síntomas: ',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                            ),
                            Expanded(
                              child: Text(
                                item.symptoms,
                                style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (item.notes.isNotEmpty && item.notes != 'Sin notas adicionales') ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notas: ',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                            ),
                            Expanded(
                              child: Text(
                                item.notes,
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                            onPressed: () => _showFormDialog(context, diary: item),
                            tooltip: 'Editar registro',
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _showDeleteConfirmation(context, item.patientDiaryId),
                            tooltip: 'Eliminar registro',
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
