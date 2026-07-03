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
    });
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
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: provider.appointments.length,
      itemBuilder: (context, index) {
        final appointment = provider.appointments[index];
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

  void _showCreateAppointmentDialog(BuildContext context) {
    final dashboardProvider = context.read<DashboardProvider>();
    final loginProvider = context.read<LoginProvider>();
    
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cita agendada exitosamente.'), backgroundColor: Colors.green),
                      );
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
