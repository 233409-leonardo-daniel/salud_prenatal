import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/patient_detail_provider.dart';
import 'patient_state.dart';
import '../../domain/entities/patient.dart';
import '../../../appointments/presentation/providers/appointment_provider.dart';
import '../../../appointments/domain/entities/appointment.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientDetailProvider>().loadPatientDetails(widget.userId);
      context.read<AppointmentsProvider>().loadAppointments(widget.patientId, isDoctor: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final patientDetailProvider = context.watch<PatientDetailProvider>();
    final appointmentsProvider = context.watch<AppointmentsProvider>();

    if (patientDetailProvider.status == PatientDetailStatus.loading || patientDetailProvider.status == PatientDetailStatus.initial) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Expediente: ${widget.patientName}'),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (patientDetailProvider.status == PatientDetailStatus.error) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Expediente: ${widget.patientName}'),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(patientDetailProvider.error ?? 'Error', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<PatientDetailProvider>().loadPatientDetails(widget.userId);
                },
                child: const Text('Reintentar'),
              )
            ],
          ),
        ),
      );
    }

    final userProfile = patientDetailProvider.currentPatientProfile;
    final patientData = widget.patientEntity;

    // Filter appointments for this patient
    final allAppointments = appointmentsProvider.appointments;
    
    // Consultas previas (Completed)
    final pastAppointments = allAppointments.where((app) => app.status == AppointmentStatus.completed).toList();
    
    // Citas pendientes (Pending)
    final pendingAppointments = allAppointments.where((app) => app.status == AppointmentStatus.pending).toList();

    // 1. Details
    final age = patientData.age.toString(); // From patient entity
    final bloodType = patientData.bloodType;
    final residence = 'No especificado'; // or from patientData if it was added
    final email = userProfile?.email ?? 'No especificado';
    final role = userProfile?.role ?? 'paciente';

    // 2. Previous consultations (completed appointments)
    final consultationsWidgets = <Widget>[];
    if (pastAppointments.isEmpty) {
      consultationsWidgets.add(const Text('No hay consultas registradas aún.', style: TextStyle(color: AppColors.textMuted)));
    } else {
      for (var i = 0; i < pastAppointments.length; i++) {
        final c = pastAppointments[i];
        final day = c.dateTime.day.toString().padLeft(2, '0');
        final month = c.dateTime.month.toString().padLeft(2, '0');
        final year = c.dateTime.year.toString();
        consultationsWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$day/$month/$year - Consulta Completada',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 2),
                Text('Motivo: ${c.reason}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
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
      pendingAppsWidgets.add(const Text('No hay citas programadas.', style: TextStyle(color: AppColors.textMuted)));
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
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$day/$month/$year - $hour:$min', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(app.reason, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                if (i < pendingAppointments.length - 1) const Divider(),
              ],
            ),
          ),
        );
      }
    }

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
            _buildExpansionSection(
              title: 'Detalles del paciente',
              icon: Icons.person_outline,
              content: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nombre: ${userProfile?.name} ${userProfile?.lastName}', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Edad: $age', style: const TextStyle(color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Text('Email: $email', style: const TextStyle(color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Text('Rol: $role', style: const TextStyle(color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Text('Tipo de sangre: $bloodType', style: const TextStyle(color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Text('Residencia: $residence', style: const TextStyle(color: AppColors.textDark)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildExpansionSection(
              title: 'Banderas (Factores de Riesgo)',
              icon: Icons.flag_outlined,
              content: const Padding(
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
              content: const Padding(
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
            const SizedBox(height: 40),
          ],
        ),
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
}
