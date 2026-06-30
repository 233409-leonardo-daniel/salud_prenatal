import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../data/models/medical_record_response.dart';
import '../providers/dashboard_provider.dart';
import '../../../appointments/presentation/providers/appointment_provider.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../../core/enums/appointment_status.dart';
import 'create_medical_record_page.dart';
import 'dashboard_state.dart';

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
      final loginProvider = context.read<LoginProvider>();
      final docId = loginProvider.doctorId ?? 1;
      context.read<DashboardProvider>().loadPatientDetails(_parsedPatientId, doctorId: docId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final appointmentsProvider = context.watch<AppointmentsProvider>();

    switch (dashboardProvider.detailsStatus) {
      case DashboardDetailsStatus.initial:
      case DashboardDetailsStatus.loading:
        return Scaffold(
          appBar: AppBar(
            title: Text('Expediente: ${widget.patientName}'),
            backgroundColor: AppColors.primary,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      case DashboardDetailsStatus.error:
        return Scaffold(
          appBar: AppBar(
            title: Text('Expediente: ${widget.patientName}'),
            backgroundColor: AppColors.primary,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Center(child: Text(dashboardProvider.errorMessage ?? 'Error al cargar expediente')),
        );
      case DashboardDetailsStatus.success:
        break;
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
      flags.add(Text('Sin alertas clínicas reportadas.', style: TextStyle(color: AppColors.textMuted)));
    }

    // 3. Previous consultations
    final consultationsWidgets = <Widget>[];
    if (consultations.isEmpty) {
      consultationsWidgets.add(Text('No hay consultas registradas aún.', style: TextStyle(color: AppColors.textMuted)));
    } else {
      for (var i = 0; i < consultations.length; i++) {
        final c = consultations[i];
        final formattedDate = '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}';
        consultationsWidgets.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$formattedDate - Consulta #${c.consultationId}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                SizedBox(height: 2),
                Text('Notas: ${c.notes}', style: TextStyle(fontSize: 13)),
                Text('Objetivo: ${c.objective}', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
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
      pendingAppsWidgets.add(Text('No hay citas programadas.', style: TextStyle(color: AppColors.textMuted)));
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
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$day/$month/$year - $hour:$min', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(app.reason, style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Expediente: ${widget.patientName}',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (record == null) ...[
              _buildNoRecordBanner(context, isDoctor),
              SizedBox(height: 16),
            ] else ...[
              _buildResumenIA(record),
              SizedBox(height: 16),
            ],
            _buildExpansionSection(
              title: 'Detalles del paciente',
              icon: Icons.person_outline,
              content: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edad: $age años', style: TextStyle(color: AppColors.textDark)),
                    SizedBox(height: 8),
                    Text('Tipo de sangre: $bloodType', style: TextStyle(color: AppColors.textDark)),
                    SizedBox(height: 8),
                    Text('Residencia: $residence', style: TextStyle(color: AppColors.textDark)),
                    SizedBox(height: 8),
                    Text('Estado civil: $marital', style: TextStyle(color: AppColors.textDark)),
                    SizedBox(height: 8),
                    Text('Escolaridad: $education', style: TextStyle(color: AppColors.textDark)),
                    SizedBox(height: 8),
                    Text('Peso inicial: $initialWeight kg', style: TextStyle(color: AppColors.textDark)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            _buildExpansionSection(
              title: 'Banderas (Factores de Riesgo)',
              icon: Icons.flag_outlined,
              content: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: flags,
                ),
              ),
            ),
            SizedBox(height: 12),
            _buildExpansionSection(
              title: 'Consultas Previas',
              icon: Icons.history,
              content: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: consultationsWidgets,
                ),
              ),
            ),
            SizedBox(height: 12),
            _buildExpansionSection(
              title: 'Citas Pendientes',
              icon: Icons.calendar_today_outlined,
              content: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: pendingAppsWidgets,
                ),
              ),
            ),
            SizedBox(height: 12),
            _buildExpansionSection(
              title: 'Plan del Paciente',
              icon: Icons.next_plan_outlined,
              content: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(planText, style: TextStyle(color: AppColors.textDark, height: 1.4)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagRow(String flagName, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          SizedBox(width: 8),
          Text(flagName, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildResumenIA(MedicalRecordResponse record) {
    final riskPrediction = record.riskPrediction;
    final hasRiskPrediction = riskPrediction != null &&
        riskPrediction.diagnosis != null &&
        riskPrediction.diagnosis!.isNotEmpty;

    if (!hasRiskPrediction) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.purple, size: 24),
              SizedBox(width: 8),
              Text(
                'Predicción de Riesgo',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 15),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (riskPrediction.riskCluster != null)
            Text(
              'Clúster: ${riskPrediction.riskCluster}',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 13),
            ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.isDarkMode ? const Color(0xFF2C2C2E) : Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Text(
              'Diagnóstico: ${riskPrediction.diagnosis}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.isDarkMode ? Colors.purple.shade100 : Colors.purple.shade900,
                fontSize: 13,
                height: 1.4,
              ),
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
        color: AppColors.cardBackground,
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
        shape: Border(),
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: ElevatedButton.icon(
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
            label: const Text('Crear Expediente Médico', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.textMuted, size: 24),
            const SizedBox(width: 12),
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
