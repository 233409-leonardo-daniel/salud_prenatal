import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../data/models/medical_record_response.dart';
import '../providers/dashboard_provider.dart';
import '../../../appointments/presentation/providers/appointment_provider.dart';
import '../../../../core/session/session_manager.dart';
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
    final factoresDeterminantes = (riskPrediction != null && riskPrediction.isOk)
        ? riskPrediction.factoresDeterminantes
        : <Map<String, dynamic>>[];
    final pacientesSimilares = (riskPrediction != null && riskPrediction.isOk)
        ? riskPrediction.pacientesSimilares
        : <Map<String, dynamic>>[];
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
            if (factoresDeterminantes.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildExpansionSection(
                title: 'Factores Determinantes',
                icon: Icons.insights_outlined,
                content: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...factoresDeterminantes.map((f) {
                        final label = f['etiqueta']?.toString() ?? f['variable']?.toString() ?? '';
                        final valorPaciente = f['valor_paciente'];
                        final promedioPerfil = f['promedio_perfil'];
                        final score = f['score'];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.circle, size: 5, color: AppColors.primary),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                                    if (valorPaciente != null || promedioPerfil != null)
                                      Text(
                                        'Paciente: $valorPaciente · Promedio del perfil: $promedioPerfil${score != null ? ' · Score: $score' : ''}',
                                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (explicacionRiesgo != null && explicacionRiesgo.isNotEmpty) ...[
                        const Divider(height: 24),
                        Text(
                          explicacionRiesgo,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.4, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            if (pacientesSimilares.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildExpansionSection(
                title: 'Pacientes Similares',
                icon: Icons.groups_outlined,
                content: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: pacientesSimilares.asMap().entries.map((entry) {
                      final i = entry.key;
                      final p = entry.value;
                      final edad = p['age_years'];
                      final sys = p['systolic'];
                      final dia = p['diastolic'];
                      final bmi = p['bmi_initial'];
                      final perfil = p['perfil']?.toString();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paciente similar ${i + 1}${perfil != null ? ' · $perfil' : ''}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Edad: ${edad ?? 'N/D'} · Presión: ${sys ?? 'N/D'}/${dia ?? 'N/D'} · IMC inicial: ${bmi ?? 'N/D'}',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            if (i < pacientesSimilares.length - 1) const Divider(height: 16),
                          ],
                        ),
                      );
                    }).toList(),
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
                        style: TextStyle(fontSize: 11, color: level.color.withOpacity(0.85), fontWeight: FontWeight.w600),
                      ),
                      Text(
                        level.label,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: level.color),
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
                color: AppColors.isDarkMode ? Colors.purple.shade100 : Colors.purple.shade900,
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
