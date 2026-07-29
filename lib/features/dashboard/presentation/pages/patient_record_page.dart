import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../data/models/medical_record_response.dart';
import '../../../patient_diaries/domain/entities/aggregated_symptom.dart';
import '../../../patient_diaries/domain/entities/patient_diary.dart';
import '../../../patient_diaries/presentation/providers/patient_diaries_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../appointments/presentation/providers/appointment_provider.dart';
import '../../../../core/session/session_manager.dart';
import '../../../appointments/domain/entities/appointment.dart';
import 'create_medical_record_page.dart';
import 'new_consultation_dialog.dart';
import 'edit_general_plan_dialog.dart';
import 'consultation_detail_sheet.dart';
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
      final session = context.read<SessionManager>();
      context.read<DashboardProvider>().loadPatientDetails(_parsedPatientId, doctorId: session.doctorId);
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

    // 1. Details — la edad viene del expediente (GET /medical-records/patient/{id})
    // o, si aún no hay expediente, del listado de pacientes del doctor. Lo
    // clínico (tipo de sangre, residencia, etc.) solo existe si ya hay
    // expediente: si no, se muestra honestamente como "No especificado" en
    // vez de un valor inventado.
    final age = record?.age ?? patientData['age'];
    final bloodType = record?.bloodType ?? 'No especificado';
    final residence = record?.residence ?? 'No especificado';
    final marital = record?.maritalStatus ?? 'No especificado';
    final education = record?.educationLevel ?? 'No especificado';
    final initialWeight = record?.initialWeight;
    final heightCm = record?.heightCm;
    final initialSystolic = record?.initialSystolic;
    final initialDiastolic = record?.initialDiastolic;

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

    // 2b. Detalle de la última predicción de riesgo (para los desplegables
    // opcionales de factores determinantes / pacientes similares / caso
    // límitrofe — solo se muestran si hay datos).
    final riskPrediction = record?.riskPrediction;
    final explicacionRiesgo = (riskPrediction != null && riskPrediction.isOk) ? riskPrediction.explicacion : null;
    final esCasoLimitrofe = riskPrediction != null && riskPrediction.isOk && riskPrediction.casoLimitrofe;

    // 3. Previous consultations
    final consultationsWidgets = <Widget>[];
    if (consultations.isEmpty) {
      consultationsWidgets.add(Text('No hay consultas registradas aún.', style: TextStyle(color: AppColors.textMuted)));
    } else {
      for (var i = 0; i < consultations.length; i++) {
        final c = consultations[i];
        final formattedDate = '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}';
        consultationsWidgets.add(
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => showConsultationDetailSheet(context, c),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$formattedDate - Consulta #${c.consultationId}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Motivo: ${c.reportedFacts.trim().isEmpty ? 'Sin información' : c.reportedFacts}',
                    style: TextStyle(fontSize: 13),
                  ),
                  if (c.objective.trim().isNotEmpty)
                    Text('Objetivo: ${c.objective}', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  if (c.notes.trim().isNotEmpty)
                    Text('Notas: ${c.notes}', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  if (i < consultations.length - 1) const Divider(),
                ],
              ),
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

    final session = context.watch<SessionManager>();
    final isDoctor = session.role?.toLowerCase() == 'doctor' || session.role?.toLowerCase() == 'doctor(a)';

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
              if (record.symptomAlert.isNotEmpty) ...[
                _buildSymptomAlertBanner(record.symptomAlert, record.medicalRecordId),
                SizedBox(height: 16),
              ],
              _buildResumenIA(context, record, isDoctor),
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
                    Text('Edad: ${age != null ? '$age años' : 'No especificado'}', style: TextStyle(color: AppColors.textDark)),
                    SizedBox(height: 8),
                    Text('Tipo de sangre: $bloodType', style: TextStyle(color: AppColors.textDark)),
                    SizedBox(height: 8),
                    Text('Residencia: $residence', style: TextStyle(color: AppColors.textDark)),
                    SizedBox(height: 8),
                    Text('Estado civil: $marital', style: TextStyle(color: AppColors.textDark)),
                    SizedBox(height: 8),
                    Text('Escolaridad: $education', style: TextStyle(color: AppColors.textDark)),
                    SizedBox(height: 8),
                    Text(
                      'Talla / Peso inicial: ${heightCm != null ? '$heightCm cm' : 'No especificado'} / ${initialWeight != null ? '$initialWeight kg' : 'No especificado'}',
                      style: TextStyle(color: AppColors.textDark),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Presión inicial: ${initialSystolic != null && initialDiastolic != null ? '$initialSystolic/$initialDiastolic mmHg' : 'No especificado'}',
                      style: TextStyle(color: AppColors.textDark),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            _buildExpansionSection(
              title: 'Datos del Expediente Médico',
              icon: Icons.medical_information_outlined,
              content: Padding(
                padding: EdgeInsets.all(16.0),
                child: record == null
                    ? Text(
                        'Aún no se cuenta con expediente médico registrado para esta paciente.',
                        style: TextStyle(color: AppColors.textMuted),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRecordValueRow('Embarazos previos', record.previousPregnancies.toString()),
                          _buildRecordValueRow('Partos previos', record.previousDeliveries.toString()),
                          _buildRecordValueRow('Abortos previos', record.previousMiscarriages.toString()),
                          _buildRecordValueRow('Cesáreas previas', record.previousCesareans.toString()),
                          const Divider(height: 20),
                          _buildRecordBoolRow('Hipertensión previa', record.previousHypertension),
                          _buildRecordBoolRow('Diabetes', record.diabetes),
                          _buildRecordBoolRow('Historial familiar de hipertensión', record.familyHistoryHypertension),
                          _buildRecordBoolRow('Preeclampsia previa', record.previousPreeclampsia),
                          _buildRecordBoolRow('Enfermedad renal crónica', record.chronicKidneyDisease),
                          _buildRecordBoolRow('Hipertensión crónica', record.chronicHypertension),
                          _buildRecordBoolRow('Embarazo múltiple', record.multiplePregnancy),
                          _buildRecordBoolRow('Muerte fetal', record.fetalDeath),
                          _buildRecordBoolRow('Restricción de crecimiento fetal', record.fetalGrowthRestriction),
                          _buildRecordBoolRow('Historial familiar de cardiopatía', record.familyHistoryHeartDisease),
                          _buildRecordBoolRow('Tabaquismo activo', record.activeSmoking),
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
            // Los siguientes 3 desplegables solo aparecen si la última
            // evaluación de riesgo trae ese dato — si no, no se muestran
            // (nada de acordeones vacíos).
            // Factores Determinantes: solo se muestra la explicación en texto
            // del perfil asignado (sin el desglose de variables ni pacientes
            // similares).
            if (explicacionRiesgo != null && explicacionRiesgo.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildExpansionSection(
                title: 'Factores Determinantes',
                icon: Icons.insights_outlined,
                content: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    explicacionRiesgo,
                    style: TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.4),
                  ),
                ),
              ),
            ],
            if (esCasoLimitrofe) ...[
              SizedBox(height: 12),
              _buildExpansionSection(
                title: 'Caso Límitrofe',
                icon: Icons.warning_amber_rounded,
                content: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Esta paciente quedó en un punto límite entre dos perfiles clínicos (ver "Afinidad a perfiles" en la predicción de riesgo). Se recomienda revisar el caso con criterio clínico adicional antes de decidir el seguimiento.',
                    style: TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.4),
                  ),
                ),
              ),
            ],
            SizedBox(height: 12),
            _buildExpansionSection(
              title: 'Consultas Previas',
              icon: Icons.history,
              content: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isDoctor && record != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _openNewConsultationDialog(context, record.medicalRecordId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Nueva consulta',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                    ],
                    ...consultationsWidgets,
                  ],
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
            if (record != null) ...[
              SizedBox(height: 12),
              _buildExpansionSection(
                title: 'Plan General del Expediente',
                icon: Icons.assignment_outlined,
                titleAction: isDoctor
                    ? IconButton(
                        icon: Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                        tooltip: 'Editar plan general',
                        onPressed: () => _openEditGeneralPlanDialog(context, record.medicalRecordId, record.generalPlan),
                      )
                    : null,
                content: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    (record.generalPlan?.trim().isNotEmpty ?? false)
                        ? record.generalPlan!
                        : 'Aún no se ha definido un plan general para esta paciente.',
                    style: TextStyle(color: AppColors.textDark, height: 1.4),
                  ),
                ),
              ),
            ],
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

  Widget _buildRecordValueRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: AppColors.textDark)),
          ),
          Text(value, style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecordBoolRow(String label, bool value) {
    final color = value ? Colors.red : Colors.green;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.remove_circle_outline,
            color: color,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(label, style: TextStyle(color: AppColors.textDark)),
          ),
          Text(
            value ? 'Sí' : 'No',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenIA(BuildContext context, MedicalRecordResponse record, bool isDoctor) {
    final riskPrediction = record.riskPrediction;

    // Nunca se ha evaluado: estado vacío + botón (solo doctor puede disparar).
    if (riskPrediction == null) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: AppColors.textMuted, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aún no se ha evaluado el riesgo de esta paciente.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
            if (isDoctor) ...[
              SizedBox(height: 12),
              _buildEvaluateRiskButton(context, record.medicalRecordId),
            ],
          ],
        ),
      );
    }

    // Servicio de ML no disponible en el momento de la última evaluación.
    if (riskPrediction.isMlUnavailable) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_off_outlined, color: Colors.orange, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Servicio de predicción no disponible, intenta más tarde.',
                    style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            if (isDoctor) ...[
              SizedBox(height: 12),
              _buildEvaluateRiskButton(context, record.medicalRecordId, label: 'Reintentar evaluación'),
            ],
          ],
        ),
      );
    }

    // Faltan datos críticos para poder evaluar.
    if (riskPrediction.isInsufficientData) {
      final missing = riskPrediction.missingFields ?? [];
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Faltan datos para evaluar el riesgo',
                    style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            if (missing.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Campos faltantes: ${missing.join(', ')}',
                style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
              ),
            ],
            SizedBox(height: 4),
            Text(
              'Completa el expediente o registra la presión arterial de la paciente.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            if (isDoctor) ...[
              SizedBox(height: 12),
              _buildEvaluateRiskButton(context, record.medicalRecordId, label: 'Reintentar evaluación'),
            ],
          ],
        ),
      );
    }

    // status == 'ok': hay predicción.
    // Factores determinantes, pacientes similares y caso límitrofe se
    // muestran en sus propios desplegables (ver build()), no aquí.
    final clusterName = riskPrediction.diagnosis ?? 'Riesgo indeterminado';
    final interpretation = riskPrediction.interpretation;
    final afinidad = riskPrediction.afinidad;
    final level = _resolveRiskLevel(clusterName);

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
          // Cuadro de nivel de riesgo
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: level.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: level.color, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(level.icon, color: level.color, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nivel de riesgo',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        level.label,
                        // Texto neutro segun el tema (negro en claro / blanco en
                        // oscuro); el color de riesgo queda solo en el icono y el
                        // borde para no saturar de rojo.
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
              'Diagnóstico: $clusterName',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                // Neutro segun el tema; el matiz morado se conserva solo en el
                // fondo y el borde del recuadro.
                color: AppColors.textDark,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          if (interpretation != null && interpretation.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              interpretation,
              style: TextStyle(color: AppColors.textDark, fontSize: 12.5, height: 1.4),
            ),
          ],
          if (afinidad.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              'Afinidad a perfiles clínicos',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
            ),
            SizedBox(height: 6),
            ...(afinidad.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(e.key, style: TextStyle(fontSize: 12, color: AppColors.textDark)),
                    ),
                    Expanded(
                      flex: 5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (e.value / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.purple.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('${e.value.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: 8),
          if (riskPrediction.predictedAt != null)
            Text(
              'Evaluado el ${_formatDateTime(riskPrediction.predictedAt!)}',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          if (riskPrediction.stale) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.update, color: Colors.orange, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Hay datos nuevos desde la última evaluación. Re-evalúa para actualizar.',
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (riskPrediction.recomendaciones != null) ...[
            SizedBox(height: 8),
            _buildSomanzSection(riskPrediction.recomendaciones!),
          ],
          if (isDoctor) ...[
            SizedBox(height: 12),
            _buildEvaluateRiskButton(
              context,
              record.medicalRecordId,
              label: riskPrediction.stale ? 'Re-evaluar riesgo' : 'Evaluar riesgo de nuevo',
            ),
          ],
        ],
      ),
    );
  }

  /// Aviso accionable para el doctor: síntomas registrados por la paciente
  /// desde la última consulta (symptom_alert dentro de GET
  /// /medical-records/patient/{id}). Si el expediente no tiene ninguna
  /// consulta todavía, el backend manda TODO el historial aquí.
  Widget _buildSymptomAlertBanner(List<AggregatedSymptom> alerts, int medicalRecordId) {
    final hasAlarm = alerts.any((a) => a.alarm);
    final accent = hasAlarm ? AppColors.riskHighText : AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // Al tocar la tarjeta se abre la bitácora de la paciente (mediciones).
        onTap: () => _showBitacoraSheet(medicalRecordId),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasAlarm ? AppColors.riskHighBg : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasAlarm ? AppColors.riskHighText.withOpacity(0.35) : AppColors.primary.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active_outlined, color: accent, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Síntomas registrados desde tu última consulta',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: accent),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: accent, size: 20),
                ],
              ),
              SizedBox(height: 10),
              ...alerts.map(
                (a) => Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• ${a.label} (${a.occurrences} registro${a.occurrences == 1 ? '' : 's'})'
                    '${a.zones.isNotEmpty ? ' — ${a.zones.join(', ')}' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textDark,
                      fontWeight: a.alarm ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.menu_book_outlined, color: accent, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Ver bitácora de mediciones',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: accent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Abre una hoja inferior con la bitácora de la paciente (mediciones de
  /// presión y peso registradas). Se muestra la hoja de inmediato y se cargan
  /// las mediciones con un estado de carga interno (convención UI del proyecto).
  void _showBitacoraSheet(int medicalRecordId) {
    final diariesProvider = context.read<PatientDiariesProvider>();
    diariesProvider.loadDiaries(medicalRecordId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.menu_book_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Bitácora de mediciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Consumer<PatientDiariesProvider>(
                builder: (context, provider, _) {
                  if (provider.status == PatientDiariesStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.status == PatientDiariesStatus.error) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          provider.errorMessage ?? 'No se pudieron cargar las mediciones.',
                          style: TextStyle(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final diaries = provider.diaries;
                  if (diaries.isEmpty) {
                    return Center(
                      child: Text('La paciente aún no tiene mediciones registradas.',
                          style: TextStyle(color: AppColors.textMuted)),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: diaries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildBitacoraTile(diaries[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBitacoraTile(PatientDiary d) {
    final highBp = d.systolic >= 140 || d.diastolic >= 90;
    final date = '${d.createdAt.day.toString().padLeft(2, '0')}/'
        '${d.createdAt.month.toString().padLeft(2, '0')}/${d.createdAt.year}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.06) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.favorite, size: 16, color: highBp ? AppColors.riskHighText : AppColors.primary),
              const SizedBox(width: 6),
              Text('Presión: ', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              Text('${d.systolic}/${d.diastolic} mmHg',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: highBp ? AppColors.riskHighText : AppColors.textDark,
                  )),
              const SizedBox(width: 16),
              Icon(Icons.monitor_weight, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Peso: ', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              Text('${d.weightKg} kg',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ],
          ),
          if (d.symptoms.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Síntomas: ${d.symptoms}', style: TextStyle(fontSize: 12.5, color: AppColors.textDark)),
          ],
          if (d.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Notas: ${d.notes}', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }

  /// Bloque de recomendaciones clínicas SOMANZ dentro de la predicción de
  /// riesgo — solo se llama cuando `riskPrediction.recomendaciones` no es
  /// null (perfil "Alto Riesgo Hipertensivo / Preeclampsia"). El `descargo`
  /// se muestra siempre de forma prominente: no es una prescripción, la
  /// decisión final es del médico tratante.
  Widget _buildSomanzSection(Map<String, dynamic> rec) {
    final fuente = rec['fuente']?.toString() ?? '';
    final descargo = rec['descargo']?.toString() ?? '';
    final items = (rec['items'] as List? ?? []).whereType<Map>().toList();
    final noRecomendados = (rec['no_recomendados'] as List? ?? []).whereType<Map>().toList();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recomendaciones clínicas (SOMANZ)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          if (descargo.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.riskHighBg, borderRadius: BorderRadius.circular(10)),
              child: Text(
                descargo,
                // Antes usaba riskHighText (rojo), que en modo oscuro quedaba
                // ilegible. Ahora es texto neutro del tema (negro/blanco) sobre
                // el fondo tenue de aviso.
                style: TextStyle(fontSize: 11, color: AppColors.textDark, fontWeight: FontWeight.w600, height: 1.4),
              ),
            ),
          SizedBox(height: 12),
          ...items.map((raw) {
            final item = Map<String, dynamic>.from(raw);
            final aplicable = item['aplicable_ahora'] == true;
            return Opacity(
              opacity: aplicable ? 1.0 : 0.55,
              child: Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['intervencion']?.toString() ?? '',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textDark),
                          ),
                        ),
                        if (item['grade'] != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(100)),
                            child: Text(
                              'GRADE ${item['grade']}',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 3),
                    Text(
                      item['recomendacion']?.toString() ?? '',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
                    ),
                    if (!aplicable && item['nota'] != null) ...[
                      SizedBox(height: 3),
                      Text(
                        item['nota'].toString(),
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          if (noRecomendados.isNotEmpty) ...[
            Divider(height: 20),
            Text(
              'No recomendados por evidencia insuficiente',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
            ),
            SizedBox(height: 6),
            ...noRecomendados.map((raw) {
              final item = Map<String, dynamic>.from(raw);
              return Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${item['intervencion'] ?? ''} (GRADE ${item['grade'] ?? ''})',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              );
            }),
          ],
          if (fuente.isNotEmpty) ...[
            SizedBox(height: 10),
            Text(
              'Fuente: $fuente',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openNewConsultationDialog(BuildContext context, int medicalRecordId) async {
    await showNewConsultationDialog(
      context,
      medicalRecordId: medicalRecordId,
      patientName: widget.patientName,
    );
  }

  Future<void> _openEditGeneralPlanDialog(BuildContext context, int medicalRecordId, String? currentPlan) async {
    await showEditGeneralPlanDialog(
      context,
      medicalRecordId: medicalRecordId,
      currentPlan: currentPlan,
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEvaluateRiskButton(BuildContext context, int medicalRecordId, {String label = 'Evaluar riesgo'}) {
    final dashboardProvider = context.watch<DashboardProvider>();
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: dashboardProvider.isEvaluatingRisk
            ? null
            : () async {
                final success = await context.read<DashboardProvider>().evaluateRisk(medicalRecordId);
                if (mounted && !success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.read<DashboardProvider>().errorMessage ?? 'Error al evaluar riesgo'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
        icon: dashboardProvider.isEvaluatingRisk
            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
            : Icon(Icons.analytics_outlined, size: 18, color: AppColors.primary),
        label: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  /// Determina el nivel de riesgo (Bajo / Medio / Alto) a partir del texto del
  /// diagnóstico devuelto por el modelo de predicción, para mostrarlo en un
  /// cuadro con color distintivo.
  _RiskLevel _resolveRiskLevel(String diagnosis) {
    final text = diagnosis.toLowerCase();
    final hasAlto = text.contains('alto');
    final hasMedio = text.contains('medio');
    final hasBajo = text.contains('bajo');

    if (hasAlto) {
      return _RiskLevel('Riesgo Alto', Colors.red, Icons.warning_amber_rounded);
    }
    if (hasMedio && hasBajo) {
      return _RiskLevel('Riesgo Bajo-Medio', Colors.orange, Icons.info_outline);
    }
    if (hasMedio) {
      return _RiskLevel('Riesgo Medio', Colors.orange, Icons.info_outline);
    }
    if (hasBajo) {
      return _RiskLevel('Riesgo Bajo', Colors.green, Icons.check_circle_outline);
    }
    return _RiskLevel('Riesgo indeterminado', Colors.purple, Icons.analytics_outlined);
  }

  Widget _buildExpansionSection({
    required String title,
    required IconData icon,
    required Widget content,
    Widget? titleAction,
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ),
            if (titleAction != null) titleAction,
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFF0F0F0))),
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
                  final docId = context.read<SessionManager>().doctorId;
                  context.read<DashboardProvider>().loadPatientDetails(_parsedPatientId, doctorId: docId);
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

class _RiskLevel {
  final String label;
  final Color color;
  final IconData icon;

  const _RiskLevel(this.label, this.color, this.icon);
}
