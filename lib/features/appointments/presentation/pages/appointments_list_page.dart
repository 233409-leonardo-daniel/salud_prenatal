import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/appointment_provider.dart';
import 'appointment_detail_page.dart';
import '../widgets/appointment_card.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../providers/create_appointment_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../domain/entities/appointment.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../../../../core/enums/appointment_status.dart';
import 'appointment_state.dart';
class AppointmentsListPage extends StatefulWidget {
  const AppointmentsListPage({super.key});

  @override
  State<AppointmentsListPage> createState() => _AppointmentsListPageState();
}

class _AppointmentsListPageState extends State<AppointmentsListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loginProvider = context.read<LoginProvider>();
      final doctorId = loginProvider.doctorId;
      context.read<AppointmentsProvider>().loadAllAppointments(doctorId: doctorId);
      _loadPatientsIfNeeded();
    });
  }

  // Carga la lista real de pacientes (y usuarios) del doctor si aún no está
  // en memoria. La necesitamos tanto para el botón de "Agendar Cita" como
  // para resolver los nombres reales de paciente/médico en cada tarjeta.
  Future<void> _loadPatientsIfNeeded() async {
    final dashboardProvider = context.read<DashboardProvider>();
    if (dashboardProvider.patients.isNotEmpty) return;
    final doctorId = context.read<LoginProvider>().doctorId;
    if (doctorId == null) return;
    await dashboardProvider.loadDoctorPatients(doctorId);
  }

  // Resuelve los nombres reales a partir de los IDs de la cita (patientId /
  // doctorId). El backend nunca llena patientName/doctorName (AppointmentResponse
  // solo trae IDs), así que no podemos mostrarlos directamente.
  Appointment _resolveAppointmentNames(Appointment app, DashboardProvider dashboardProvider, LoginProvider loginProvider) {
    String resolvedPatient = app.patientName;
    final patientMatch = dashboardProvider.patients.firstWhere(
      (p) => p['patient_id'] == app.patientId,
      orElse: () => <String, dynamic>{},
    );
    if (patientMatch.isNotEmpty) {
      final user = dashboardProvider.users.firstWhere(
        (u) => u.userId == patientMatch['user_id'],
        orElse: () => UserProfile(name: '', lastName: '', email: '', role: 'paciente'),
      );
      final fullName = '${user.name} ${user.lastName}'.trim();
      if (fullName.isNotEmpty) resolvedPatient = fullName;
    }

    // No hay endpoint que resuelva doctor_id -> nombre. Solo lo mostramos
    // cuando quien ve la cita es ese mismo doctor (su propio perfil).
    String resolvedDoctor = app.doctorName;
    if (loginProvider.role == 'doctor' && loginProvider.doctorId == app.doctorId) {
      final fullName = '${loginProvider.name} ${loginProvider.lastName}'.trim();
      resolvedDoctor = fullName.isNotEmpty ? fullName : '';
    } else {
      resolvedDoctor = '';
    }

    return Appointment(
      id: app.id,
      doctorId: app.doctorId,
      patientId: app.patientId,
      doctorName: resolvedDoctor,
      patientName: resolvedPatient,
      dateTime: app.dateTime,
      status: app.status,
      reason: app.reason,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentsProvider>();
    final loginProvider = context.watch<LoginProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Todas las Citas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _buildBody(provider),
      floatingActionButton: loginProvider.role == 'receptionist' || loginProvider.role == 'recepcionista' || loginProvider.role == 'recepcionist'
          ? FloatingActionButton(
              onPressed: () => _showCreateAppointmentDialog(context),
              backgroundColor: AppColors.primary,
              child: Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBody(AppointmentsProvider provider) {
    if (provider.viewState == AppointmentActionStatus.loading || provider.status == AppointmentsListStatus.loading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (provider.appointments.isEmpty) {
      return Center(
        child: Text(
          'No hay citas programadas.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 16),
        ),
      );
    }
    
    final dashboardProvider = context.watch<DashboardProvider>();
    final loginProvider = context.watch<LoginProvider>();

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: provider.appointments.length,
      itemBuilder: (context, index) {
        final appointment = _resolveAppointmentNames(provider.appointments[index], dashboardProvider, loginProvider);
        return AppointmentCard(
          appointment: appointment,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentDetailPage(appointment: appointment),
              ),
            );
            if (context.mounted) {
              final loginProvider = context.read<LoginProvider>();
              final docId = loginProvider.doctorId;
              context.read<AppointmentsProvider>().loadAllAppointments(doctorId: docId);
            }
          },
        );
      },
    );
  }

  Future<void> _showCreateAppointmentDialog(BuildContext context) async {
    final dashboardProvider = context.read<DashboardProvider>();
    final loginProvider = context.read<LoginProvider>();

    // Si aún no se cargaron los pacientes del doctor (p. ej. porque no se
    // visitó antes el dashboard), los cargamos antes de asumir que no hay
    // pacientes registrados.
    if (dashboardProvider.patients.isEmpty && loginProvider.doctorId != null) {
      await dashboardProvider.loadDoctorPatients(loginProvider.doctorId!);
      if (!context.mounted) return;
    }

    final patientsList = dashboardProvider.patients;
    if (patientsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay pacientes registrados para agendar citas.')),
      );
      return;
    }

    int? selectedPatientId = patientsList[0]['patient_id'] as int?;
    DateTime selectedDateTime = DateTime.now().add(const Duration(days: 1));
    final reasonController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Agendar Cita', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Paciente:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedPatientId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: patientsList.map((patient) {
                        final pId = patient['patient_id'] as int;
                        final user = dashboardProvider.users.firstWhere(
                          (u) => u.userId == patient['user_id'],
                          orElse: () => UserProfile(name: 'Paciente', lastName: '$pId', email: '', role: 'paciente'),
                        );
                        return DropdownMenuItem<int>(
                          value: pId,
                          child: Text('${user.name} ${user.lastName}'.trim()),
                        );
                      }).toList(),
                      onChanged: isSaving ? null : (val) {
                        setDialogState(() {
                          selectedPatientId = val;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    Text('Fecha y Hora:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: isSaving ? null : () async {
                        final date = await showDatePicker(
                          context: dialogCtx,
                          initialDate: selectedDateTime,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: dialogCtx,
                            initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                          );
                          if (time != null) {
                            setDialogState(() {
                              selectedDateTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                      icon: Icon(Icons.calendar_today, color: AppColors.primary),
                      label: Text(
                        '${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} - ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: AppColors.textDark),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text('Motivo de la Cita:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      enabled: !isSaving,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Ej. Control de tercer trimestre...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                        const SnackBar(content: Text('Por favor, ingresa el motivo de la cita.')),
                      );
                      return;
                    }
                    if (selectedPatientId == null) {
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                        const SnackBar(content: Text('Por favor, selecciona un paciente.')),
                      );
                      return;
                    }
                    final doctorId = loginProvider.doctorId;
                    if (doctorId == null) {
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                        const SnackBar(content: Text('No se pudo identificar al médico de la sesión.')),
                      );
                      return;
                    }

                    setDialogState(() {
                      isSaving = true;
                    });

                    final newApp = Appointment(
                      id: 0,
                      doctorId: doctorId,
                      patientId: selectedPatientId!,
                      doctorName: doctorId.toString(),
                      patientName: selectedPatientId.toString(),
                      dateTime: selectedDateTime,
                      status: AppointmentStatus.pending,
                      reason: reasonController.text.trim(),
                    );

                    final createProvider = dialogCtx.read<CreateAppointmentProvider>();
                    await createProvider.createAppointment(newApp);

                    if (!dialogCtx.mounted) return;

                    if (createProvider.status == CreateAppointmentStatus.success) {
                      Navigator.pop(dialogCtx); // Close dialog
                      // Reload appointments
                      final docId = loginProvider.doctorId;
                      context.read<AppointmentsProvider>().loadAllAppointments(doctorId: docId);
                    } else {
                      setDialogState(() {
                        isSaving = false;
                      });
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                        SnackBar(
                          content: Text('Error al crear la cita: ${createProvider.error ?? "Error desconocido"}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Agendar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
