import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/patient_detail_provider.dart';
import 'patient_state.dart';
import '../../domain/entities/patient.dart';
import '../../../appointments/presentation/providers/appointment_provider.dart';
import '../../../chat/presentation/pages/chat_room_page.dart';
import '../../../../core/enums/appointment_status.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../../core/session/session_manager.dart';
class PatientDetailPage extends StatefulWidget {
  final String patientName;
  final String patientId;
  final String userId;
  final PatientEntity patientEntity;

  const PatientDetailPage({
    super.key,
    required this.patientName,
    required this.patientId,
    required this.userId,
    required this.patientEntity,
  });

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  bool _previousHypertension = false;
  bool _diabetes = false;
  bool _familyHistoryHypertension = false;
  int _previousPregnancies = 0;
  int _previousDeliveries = 0;
  int _previousMiscarriages = 0;
  int _previousCesareans = 0;
  bool _previousPreeclampsia = false;
  bool _chronicKidneyDisease = false;
  bool _chronicHypertension = false;
  bool _multiplePregnancy = false;
  bool _fetalDeath = false;
  bool _fetalGrowthRestriction = false;
  bool _familyHistoryHeartDisease = false;
  bool _activeSmoking = false;

  bool _isSubmittingMedicalRecord = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = context.read<SessionManager>();
      context.read<PatientDetailProvider>().loadPatientDetails(
        widget.userId,
        patientId: widget.patientEntity.patientId,
        doctorId: session.doctorId,
      );
      context.read<AppointmentsProvider>().loadAppointments(widget.patientId, isDoctor: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final patientDetailProvider = context.watch<PatientDetailProvider>();
    final appointmentsProvider = context.watch<AppointmentsProvider>();
    final session = context.read<SessionManager>();
    final isDoctor = session.role?.toLowerCase() == 'doctor' || session.role?.toLowerCase() == 'doctor(a)';

    switch (patientDetailProvider.status) {
      case PatientDetailStatus.initial:
      case PatientDetailStatus.loading:
        return Scaffold(
          appBar: AppBar(
            title: Text('Expediente: ${widget.patientName}'),
            backgroundColor: AppColors.primary,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      case PatientDetailStatus.error:
        return Scaffold(
          appBar: AppBar(
            title: Text('Expediente: ${widget.patientName}'),
            backgroundColor: AppColors.primary,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text(patientDetailProvider.error ?? 'Error', style: TextStyle(color: Colors.red)),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<PatientDetailProvider>().loadPatientDetails(widget.userId);
                  },
                  child: Text('Reintentar'),
                )
              ],
            ),
          ),
        );
      case PatientDetailStatus.success:
        break;
    }

    final userProfile = patientDetailProvider.currentPatientProfile;
    final patientData = widget.patientEntity;

    // Filter appointments for this patient
    final allAppointments = appointmentsProvider.appointments;
    
    // Consultas previas: el backend no tiene un estado "completada", así que
    // se consideran pasadas las citas no canceladas cuya fecha ya ocurrió.
    final now = DateTime.now();
    final pastAppointments = allAppointments
        .where((app) => app.status != AppointmentStatus.cancelled && app.dateTime.isBefore(now))
        .toList();
    
    // Citas pendientes (Pending)
    final pendingAppointments = allAppointments.where((app) => app.status == AppointmentStatus.pending).toList();

    // 1. Details
    final age = (patientData.age ?? '—').toString(); // From patient entity
    final medicalRecordData = patientDetailProvider.rawRecordResponse?['medical_record'] as Map<String, dynamic>?;
    final bloodType = medicalRecordData?['blood_type']?.toString() ?? 'No especificado';
    final residence = medicalRecordData?['residence']?.toString() ?? 'No especificado';
    final email = userProfile?.email ?? 'No especificado';
    final role = userProfile?.role ?? 'paciente';

    // 2. Previous consultations (past, non-cancelled appointments)
    final consultationsWidgets = <Widget>[];
    if (pastAppointments.isEmpty) {
      consultationsWidgets.add(Text('No hay consultas registradas aún.', style: TextStyle(color: AppColors.textMuted)));
    } else {
      for (var i = 0; i < pastAppointments.length; i++) {
        final c = pastAppointments[i];
        final day = c.dateTime.day.toString().padLeft(2, '0');
        final month = c.dateTime.month.toString().padLeft(2, '0');
        final year = c.dateTime.year.toString();
        consultationsWidgets.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$day/$month/$year - Consulta',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                SizedBox(height: 2),
                Text('Motivo: ${c.reason}', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                if (i < pastAppointments.length - 1) const Divider(),
              ],
            ),
          ),
        );
      }
    }

    // 3. Pending Appointments
    final pendingAppsWidgets = <Widget>[];
    if (pendingAppointments.isEmpty) {
      pendingAppsWidgets.add(Text('No hay citas programadas.', style: TextStyle(color: AppColors.textMuted)));
    } else {
      for (var i = 0; i < pendingAppointments.length; i++) {
        final app = pendingAppointments[i];
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
                if (i < pendingAppointments.length - 1) const Divider(),
              ],
            ),
          ),
        );
      }
    }

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
            if (patientDetailProvider.rawRecordResponse?['risk_prediction'] != null) ...[
              _buildResumenIA(patientDetailProvider.rawRecordResponse!['risk_prediction']),
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
                    Text('Nombre: ${userProfile?.name} ${userProfile?.lastName}', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Edad: $age', style: TextStyle(color: AppColors.textDark)),
                    SizedBox(height: 8),
                    Text('Email: $email', style: TextStyle(color: AppColors.textDark)),
                    SizedBox(height: 8),
                    Text('Rol: $role', style: TextStyle(color: AppColors.textDark)),
                    SizedBox(height: 8),
                    Text('Tipo de sangre: $bloodType', style: TextStyle(color: AppColors.textDark)),
                    SizedBox(height: 8),
                    Text('Residencia: $residence', style: TextStyle(color: AppColors.textDark)),
                  ],
                ),
              ),
            ),
            if (isDoctor && !patientDetailProvider.hasMedicalRecord) ...[
              SizedBox(height: 12),
              _buildExpansionSection(
                title: 'Crear Expediente Médico',
                icon: Icons.add_card,
                content: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: Text('Hipertensión Previa', style: TextStyle(fontSize: 14)),
                        value: _previousHypertension,
                        onChanged: (val) => setState(() => _previousHypertension = val ?? false),
                      ),
                      CheckboxListTile(
                        title: Text('Diabetes', style: TextStyle(fontSize: 14)),
                        value: _diabetes,
                        onChanged: (val) => setState(() => _diabetes = val ?? false),
                      ),
                      CheckboxListTile(
                        title: Text('Historial Familiar Hipertensión', style: TextStyle(fontSize: 14)),
                        value: _familyHistoryHypertension,
                        onChanged: (val) => setState(() => _familyHistoryHypertension = val ?? false),
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Embarazos Previos'),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => _previousPregnancies = int.tryParse(val) ?? 0,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Partos Previos'),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => _previousDeliveries = int.tryParse(val) ?? 0,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Abortos Previos'),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => _previousMiscarriages = int.tryParse(val) ?? 0,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Cesáreas Previas'),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => _previousCesareans = int.tryParse(val) ?? 0,
                      ),
                      CheckboxListTile(
                        title: Text('Preeclampsia Previa', style: TextStyle(fontSize: 14)),
                        value: _previousPreeclampsia,
                        onChanged: (val) => setState(() => _previousPreeclampsia = val ?? false),
                      ),
                      CheckboxListTile(
                        title: Text('Enfermedad Renal Crónica', style: TextStyle(fontSize: 14)),
                        value: _chronicKidneyDisease,
                        onChanged: (val) => setState(() => _chronicKidneyDisease = val ?? false),
                      ),
                      CheckboxListTile(
                        title: Text('Hipertensión Crónica', style: TextStyle(fontSize: 14)),
                        value: _chronicHypertension,
                        onChanged: (val) => setState(() => _chronicHypertension = val ?? false),
                      ),
                      CheckboxListTile(
                        title: Text('Embarazo Múltiple', style: TextStyle(fontSize: 14)),
                        value: _multiplePregnancy,
                        onChanged: (val) => setState(() => _multiplePregnancy = val ?? false),
                      ),
                      CheckboxListTile(
                        title: Text('Muerte Fetal', style: TextStyle(fontSize: 14)),
                        value: _fetalDeath,
                        onChanged: (val) => setState(() => _fetalDeath = val ?? false),
                      ),
                      CheckboxListTile(
                        title: Text('Restricción de Crecimiento Fetal', style: TextStyle(fontSize: 14)),
                        value: _fetalGrowthRestriction,
                        onChanged: (val) => setState(() => _fetalGrowthRestriction = val ?? false),
                      ),
                      CheckboxListTile(
                        title: Text('Historial Familiar de Cardiopatía', style: TextStyle(fontSize: 14)),
                        value: _familyHistoryHeartDisease,
                        onChanged: (val) => setState(() => _familyHistoryHeartDisease = val ?? false),
                      ),
                      CheckboxListTile(
                        title: Text('Tabaquismo Activo', style: TextStyle(fontSize: 14)),
                        value: _activeSmoking,
                        onChanged: (val) => setState(() => _activeSmoking = val ?? false),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmittingMedicalRecord
                              ? null
                              : () async {
                                  final doctorId = session.doctorId;
                                  if (doctorId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('No se pudo identificar al médico de la sesión.')),
                                    );
                                    return;
                                  }
                                  setState(() => _isSubmittingMedicalRecord = true);
                                  final recordData = {
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
                                    "patient_id": widget.patientEntity.patientId,
                                    "doctor_id": doctorId,
                                  };

                                  // Se delega la creación del expediente a DashboardProvider
                                  // (provider -> datasource ya encapsulado), en vez de golpear
                                  // ApiClient directo desde el widget.
                                  final success = await context
                                      .read<DashboardProvider>()
                                      .createMedicalRecord(recordData);

                                  if (mounted) {
                                    if (success) {
                                      context.read<PatientDetailProvider>().setMedicalRecordCreated();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Expediente creado con éxito')),
                                      );
                                    } else {
                                      final error = context.read<DashboardProvider>().errorMessage ??
                                          'Error al crear expediente';
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(error)),
                                      );
                                    }
                                    setState(() => _isSubmittingMedicalRecord = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSubmittingMedicalRecord
                              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('Guardar Expediente'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: 12),
            _buildExpansionSection(
              title: 'Banderas (Factores de Riesgo)',
              icon: Icons.flag_outlined,
              content: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (() {
                    final record = patientDetailProvider.rawRecordResponse?['medical_record'];
                    if (record == null) {
                      return [
                        Text(
                          'Aún no se cuenta con expediente médico registrado para esta paciente.',
                          style: TextStyle(color: AppColors.textMuted),
                        )
                      ];
                    }
                    final flags = <Widget>[];
                    if (record['chronic_hypertension'] == true || record['previous_hypertension'] == true || record['previous_preeclampsia'] == true) {
                      flags.add(_buildFlagRow('Hipertensión / Riesgo Preeclampsia', Colors.red));
                    }
                    if (record['diabetes'] == true) {
                      flags.add(_buildFlagRow('Diabetes Gestacional / Previa', Colors.orange));
                    }
                    if (record['multiple_pregnancy'] == true) {
                      flags.add(_buildFlagRow('Embarazo Múltiple', Colors.blue));
                    }
                    if (record['chronic_kidney_disease'] == true) {
                      flags.add(_buildFlagRow('Enfermedad Renal Crónica', Colors.red));
                    }
                    if (record['active_smoking'] == true) {
                      flags.add(_buildFlagRow('Tabaquismo Activo', Colors.orange));
                    }
                    if (flags.isEmpty) {
                      flags.add(Text('Sin alertas clínicas reportadas.', style: TextStyle(color: AppColors.textMuted)));
                    }
                    return flags;
                  })(),
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
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.construction_outlined, color: AppColors.primary, size: 32),
                      SizedBox(height: 8),
                      Text('Sección en construcción', style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatRoomPage(
                otherUserId: int.tryParse(widget.userId) ?? widget.patientEntity.userId,
                otherUserName: widget.patientName,
                otherUserRole: 'paciente',
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: Icon(Icons.chat_bubble_outline),
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
            color: Colors.black.withAlpha(5),
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
        initiallyExpanded: true,
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

  Widget _buildResumenIA(Map<String, dynamic> riskPrediction) {
    final diagnosis = riskPrediction['diagnosis']?.toString();
    final hasRiskPrediction = diagnosis != null && diagnosis.isNotEmpty;

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
          if (riskPrediction['risk_cluster'] != null)
            Text(
              'Clúster: ${riskPrediction['risk_cluster']}',
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
              'Diagnóstico: $diagnosis',
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
}
