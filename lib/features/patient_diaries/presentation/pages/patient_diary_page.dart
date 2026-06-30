import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../providers/patient_diaries_provider.dart';
import '../../domain/entities/patient_diary.dart';
import '../../../../core/widgets/latest_diary_record_card.dart';

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
      await dashboardProvider.loadPatientDashboard(patId, loginProvider.userId ?? 2, doctorId: loginProvider.doctorId ?? 1);
    }

    final medicalRecordId = loginProvider.medicalRecordId ?? dashboardProvider.medicalRecord?.medicalRecordId;
    if (medicalRecordId != null && medicalRecordId > 0) {
      diariesProvider.loadDiaries(medicalRecordId);
    }
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
    final loginProvider = context.read<LoginProvider>();
    final medicalRecordId = loginProvider.medicalRecordId ?? dashboardProvider.medicalRecord?.medicalRecordId ?? 0;

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
              backgroundColor: AppColors.cardBackground,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Row(
                children: [
                  Icon(
                    diary != null ? Icons.edit_note : Icons.add_chart,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Text(
                    diary != null ? 'Editar Registro' : 'Nueva Medición',
                    style: TextStyle(
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
                      Text(
                        'Ingresa tus mediciones del día. Es importante no omitir ningún dato.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      SizedBox(height: 20),
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
                          SizedBox(width: 12),
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
                      SizedBox(height: 16),
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
                      SizedBox(height: 16),
                      TextFormField(
                        controller: symptomsController,
                        enabled: !isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Síntomas (Opcional)',
                          hintText: 'Ej. Dolor de cabeza, náuseas...',
                          prefixIcon: Icon(Icons.sick_outlined, color: AppColors.primary, size: 20),
                        ),
                      ),
                      SizedBox(height: 16),
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
                  child: Text('Cancelar', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (!formKey.currentState!.validate()) return;

                    if (medicalRecordId <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error: No se ha cargado tu expediente médico. Intenta recargar la página.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

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
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(diary == null ? 'Registrar' : 'Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              backgroundColor: AppColors.cardBackground,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Eliminar Registro', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              content: Text('¿Estás segura de que deseas eliminar esta medición de tu bitácora? Esta acción no se puede deshacer.'),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
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
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final loginProvider = context.watch<LoginProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final medicalRecordId = loginProvider.medicalRecordId ?? dashboardProvider.medicalRecord?.medicalRecordId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Mi Bitácora de Salud',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _buildBody(diariesProvider, loginProvider, medicalRecordId),
      floatingActionButton: (medicalRecordId != null && medicalRecordId > 0)
          ? FloatingActionButton.extended(
              onPressed: () => _showFormDialog(context),
              backgroundColor: AppColors.primary,
              icon: Icon(Icons.add, color: Colors.white),
              label: Text('Nueva medición', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildBody(PatientDiariesProvider provider, LoginProvider loginProvider, int? medicalRecordId) {
    if (medicalRecordId == null || medicalRecordId <= 0) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.folder_off_outlined, size: 64, color: Colors.red.shade400),
              ),
              SizedBox(height: 24),
              Text(
                'Tu médico no te ha creado un expediente aún',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              if (loginProvider.doctorId == null) ...[
                SizedBox(height: 12),
                Text(
                  'Aún no estás vinculado a un médico.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                ),
              ],
            ],
          ),
        ),
      );
    }

    switch (provider.status) {
      case PatientDiariesStatus.initial:
      case PatientDiariesStatus.loading:
        if (provider.diaries.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        break;
      case PatientDiariesStatus.error:
        if (provider.diaries.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 54, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    provider.errorMessage ?? 'Ocurrió un error al cargar la bitácora.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        break;
      case PatientDiariesStatus.success:
        break;
    }

    if (provider.diaries.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_stories_outlined, size: 64, color: AppColors.primary),
              ),
              SizedBox(height: 24),
              Text(
                'Tu bitácora está vacía',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              SizedBox(height: 8),
              Text(
                'Llevar un registro diario de tu presión arterial y peso te ayuda a prevenir complicaciones durante tu embarazo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(context),
                icon: Icon(Icons.add, color: Colors.white),
                label: Text('Registrar mi primer medición', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    // Header showing the summary of the last reading
    final latest = provider.diaries.first;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          LatestDiaryRecordCard(
            systolic: latest.systolic,
            diastolic: latest.diastolic,
            weightKg: latest.weightKg,
          ),
          SizedBox(height: 24),
          Text(
            'HISTORIAL DE MEDICIONES',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
          ),
          SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.diaries.length,
            itemBuilder: (context, index) {
              final item = provider.diaries[index];
              final itemRisk = _evaluatePressureRisk(item.systolic, item.diastolic);

              return Card(
                margin: EdgeInsets.only(bottom: 16.0),
                elevation: 0,
                color: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade100, width: 1),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDateTime(item.createdAt),
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          if (itemRisk['label'] != 'Normal')
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.pink.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.favorite_outline, color: AppColors.primary, size: 20),
                                ),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Presión', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                    Text(
                                      '${item.systolic}/${item.diastolic}',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                                    ),
                                    Text('mmHg', style: TextStyle(color: AppColors.textMuted, fontSize: 9)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.pink.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.monitor_weight_outlined, color: AppColors.primary, size: 20),
                                ),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Peso', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                    Text(
                                      '${item.weightKg} kg',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                                    ),
                                    Text('Kilogramos', style: TextStyle(color: AppColors.textMuted, fontSize: 9)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF2F2F7)),
                      SizedBox(height: 12),
                      if (item.symptoms.isNotEmpty &&
                          item.symptoms.toLowerCase() != 'ninguno' &&
                          item.symptoms.toLowerCase() != 'normal') ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Síntomas: ',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                            ),
                            Expanded(
                              child: Text(
                                item.symptoms,
                                style: TextStyle(fontSize: 12, color: AppColors.textDark),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                      ],
                      if (item.notes.isNotEmpty &&
                          item.notes.toLowerCase() != 'sin notas adicionales' &&
                          item.notes.toLowerCase() != 'normal') ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notas: ',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                            ),
                            Expanded(
                              child: Text(
                                item.notes,
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                            onPressed: () => _showFormDialog(context, diary: item),
                            tooltip: 'Editar registro',
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
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
          SizedBox(height: 60),
        ],
      ),
    );
  }
}
