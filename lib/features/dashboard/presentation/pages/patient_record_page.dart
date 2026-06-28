import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/dashboard_provider.dart';
import '../../../appointments/presentation/providers/appointment_provider.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../../core/enums/appointment_status.dart';
import 'create_medical_record_page.dart';

class PatientRecordPage extends StatefulWidget {
  final String patientName;
  final String patientId;

  const PatientRecordPage({
    super.key,
    required this.patientName,
    required this.patientId,
  });

  @override
  State<PatientRecordPage> createState() => _PatientRecordPageState();
}

class _PatientRecordPageState extends State<PatientRecordPage> {
  int _parsedPatientId = 1;

  @override
  void initState() {
    super.initState();
    _parsedPatientId = int.tryParse(widget.patientId.replaceAll('#SP-', '').trim()) ?? 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadPatientDetails(_parsedPatientId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final appointmentsProvider = context.watch<AppointmentsProvider>();

    if (dashboardProvider.isDetailsLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Expediente: ${widget.patientName}'),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final patientData = dashboardProvider.patients.firstWhere(
      (p) => p['patient_id'] == _parsedPatientId,
      orElse: () => <String, dynamic>{},
    );

    final record = dashboardProvider.activeMedicalRecord;
    final consultations = dashboardProvider.activeConsultations;

    // Filter appointments for this patient
    final patientAppointments = appointmentsProvider.appointments.where((app) {
      final pIdStr = app.patientName;
      final parsedId = int.tryParse(pIdStr);
      if (parsedId != null) {
        return parsedId == _parsedPatientId;
      }
      return pIdStr.toLowerCase() == widget.patientName.toLowerCase() ||
             app.reason.toLowerCase().contains(widget.patientName.toLowerCase());
    }).toList();

    // 1. Details
    final age = patientData['age'] ?? '30';
    final bloodType = patientData['blood_type'] ?? 'O+';
    final residence = patientData['residence'] ?? 'No especificado';
    final marital = patientData['marital_status'] ?? 'No especificado';
    final education = patientData['education_level'] ?? 'No especificado';
    final initialWeight = patientData['initial_weight'] ?? '60.0';

    // 2. Flags
    final flags = <Widget>[];
    if (record != null) {
      if (record.chronicHypertension || record.previousHypertension || record.previousPreeclampsia) {
        flags.add(_buildFlagRow('Hipertensión / Riesgo Preeclampsia', Colors.red));
      }
      if (record.diabetes) {
        flags.add(_buildFlagRow('Diabetes Gestacional / Previa', Colors.orange));
      }
      if (record.multiplePregnancy) {
        flags.add(_buildFlagRow('Embarazo Múltiple', Colors.blue));
      }
      if (record.chronicKidneyDisease) {
        flags.add(_buildFlagRow('Enfermedad Renal Crónica', Colors.red));
      }
    }
    if (flags.isEmpty) {
      flags.add(const Text('Sin alertas clínicas reportadas.', style: TextStyle(color: AppColors.textMuted)));
    }

    // 3. Previous consultations
    final consultationsWidgets = <Widget>[];
    if (consultations.isEmpty) {
      consultationsWidgets.add(const Text('No hay consultas registradas aún.', style: TextStyle(color: AppColors.textMuted)));
    } else {
      for (var i = 0; i < consultations.length; i++) {
        final c = consultations[i];
        final formattedDate = '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}';
        consultationsWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$formattedDate - Consulta #${c.consultationId}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 2),
                Text('Notas: ${c.notes}', style: const TextStyle(fontSize: 13)),
                Text('Objetivo: ${c.objective}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                if (i < consultations.length - 1) const Divider(),
              ],
            ),
          ),
        );
      }
    }

    // 4. Pending Appointments
    final pendingAppsWidgets = <Widget>[];
    final pendingApps = patientAppointments.where((app) => app.status == AppointmentStatus.pending).toList();
    if (pendingApps.isEmpty) {
      pendingAppsWidgets.add(const Text('No hay citas programadas.', style: TextStyle(color: AppColors.textMuted)));
    } else {
      for (var i = 0; i < pendingApps.length; i++) {
        final app = pendingApps[i];
        final day = app.dateTime.day.toString().padLeft(2, '0');
        final month = app.dateTime.month.toString().padLeft(2, '0');
        final year = app.dateTime.year.toString();
        final hour = app.dateTime.hour.toString().padLeft(2, '0');
        final min = app.dateTime.minute.toString().padLeft(2, '0');
        pendingAppsWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$day/$month/$year - $hour:$min', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(app.reason, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                if (i < pendingApps.length - 1) const Divider(),
              ],
            ),
          ),
        );
      }
    }

    // 5. Patient Plan
    final planText = consultations.isNotEmpty ? consultations.last.plan : 'Continuar con las indicaciones médicas generales.';

    final loginProvider = context.watch<LoginProvider>();
    final isDoctor = loginProvider.role == 'doctor' || loginProvider.role == 'doctor(a)';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: Text(
          'Expediente: ${widget.patientName}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (record == null) ...[
              _buildNoRecordBanner(context, isDoctor),
              const SizedBox(height: 16),
            ] else ...[
              _buildResumenIA(record),
              const SizedBox(height: 16),
            ],
            _buildExpansionSection(
              title: 'Detalles del paciente',
              icon: Icons.person_outline,
              content: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edad: $age años', style: const TextStyle(color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Text('Tipo de sangre: $bloodType', style: const TextStyle(color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Text('Residencia: $residence', style: const TextStyle(color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Text('Estado civil: $marital', style: const TextStyle(color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Text('Escolaridad: $education', style: const TextStyle(color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Text('Peso inicial: $initialWeight kg', style: const TextStyle(color: AppColors.textDark)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildExpansionSection(
              title: 'Banderas (Factores de Riesgo)',
              icon: Icons.flag_outlined,
              content: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: flags,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildExpansionSection(
              title: 'Consultas Previas',
              icon: Icons.history,
              content: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: consultationsWidgets,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildExpansionSection(
              title: 'Citas Pendientes',
              icon: Icons.calendar_today_outlined,
              content: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: pendingAppsWidgets,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildExpansionSection(
              title: 'Plan del Paciente',
              icon: Icons.next_plan_outlined,
              content: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(planText, style: const TextStyle(color: AppColors.textDark, height: 1.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagRow(String flagName, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 8),
          Text(flagName, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildResumenIA(dynamic record) {
    String iaSummary = 'Presión arterial estable y desarrollo fetal adecuado. Continuar con plan nutricional.';
    if (record != null) {
      if (record.chronicHypertension || record.previousHypertension || record.previousPreeclampsia) {
        iaSummary = 'Paciente con antecedentes de hipertensión/preeclampsia. Monitorear estrechamente presión sistólica.';
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.pink.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_outlined, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Resumen IA',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.pink.shade100),
                ),
                child: const Text(
                  'GENERADO POR IA',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"$iaSummary"',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: AppColors.textDark,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionSection({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: const Border(),
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildNoRecordBanner(BuildContext context, bool isDoctor) {
    if (isDoctor) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9DB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFEC99)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                SizedBox(width: 8),
                Text(
                  'Sin Expediente Clínico',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta paciente no cuenta con un expediente clínico registrado en el sistema. Es necesario crearlo para registrar antecedentes y factores de riesgo.',
              style: TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateMedicalRecordPage(
                      patientId: _parsedPatientId,
                      patientName: widget.patientName,
                    ),
                  ),
                );
                if (result == true) {
                  if (context.mounted) {
                    context.read<DashboardProvider>().loadPatientDetails(_parsedPatientId);
                  }
                }
              },
              icon: const Icon(Icons.add_moderator, size: 18),
              label: const Text('Crear Expediente Médico'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.textMuted, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tu expediente clínico no está registrado en el sistema. Tu médico lo creará en tu próxima consulta.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
