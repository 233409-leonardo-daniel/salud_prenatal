import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/theme.dart';
import '../providers/appointment_provider.dart';
import 'appointment_state.dart';
import '../../domain/entities/appointment.dart';
import 'appointment_detail_page.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../providers/create_appointment_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../login/domain/entities/user_profile.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointmentsData();
    });
  }

  void _loadAppointmentsData() {
    final loginProvider = context.read<LoginProvider>();
    final isDoctor = loginProvider.role == 'doctor' || loginProvider.role == 'doctor(a)';
    final idStr = isDoctor 
        ? (loginProvider.doctorId?.toString() ?? '1')
        : (loginProvider.patientId?.toString() ?? loginProvider.userId?.toString() ?? '2');
    
    context.read<AppointmentsProvider>().loadAppointments(idStr, isDoctor: isDoctor);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year, $hour:$minute';
  }

  List<Appointment> _getAppointmentsForDay(DateTime day, List<Appointment> allAppointments) {
    return allAppointments.where((app) {
      return isSameDay(app.dateTime, day);
    }).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay, List<Appointment> allAppointments) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      final dayAppointments = _getAppointmentsForDay(selectedDay, allAppointments);
      if (dayAppointments.isNotEmpty) {
        _showDayAppointments(context, selectedDay, dayAppointments);
      }
    } else {
      final dayAppointments = _getAppointmentsForDay(selectedDay, allAppointments);
      if (dayAppointments.isNotEmpty) {
        _showDayAppointments(context, selectedDay, dayAppointments);
      }
    }
  }

  void _showDayAppointments(BuildContext context, DateTime day, List<Appointment> appointments) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Citas para el ${_formatDate(day).split(',')[0]}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final app = appointments[index];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context); // Close bottom sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentDetailPage(
                              appointment: _resolveAppointmentNames(app, context),
                            ),
                          ),
                        );
                      },
                      child: _buildAppointmentCard(app, theme, isCompact: true),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AppointmentsProvider>();
    final loginProvider = context.watch<LoginProvider>();
    final isDoctor = loginProvider.role == 'doctor' || loginProvider.role == 'doctor(a)';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F8),
      appBar: AppBar(
        title: const Text(
          'Agenda de Citas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(provider, theme),
      floatingActionButton: isDoctor
          ? FloatingActionButton(
              onPressed: () => _showCreateAppointmentDialog(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Appointment _resolveAppointmentNames(Appointment app, BuildContext context) {
    try {
      final dashboardProvider = context.read<DashboardProvider>();
      
      String resolvedPatient = app.patientName;
      final pId = int.tryParse(app.patientName);
      if (pId != null) {
        final match = dashboardProvider.patients.firstWhere(
          (p) => p['patient_id'] == pId,
          orElse: () => <String, dynamic>{},
        );
        if (match.isNotEmpty) {
          final user = dashboardProvider.users.firstWhere(
            (u) => u.userId == match['user_id'],
            orElse: () => UserProfile(name: 'Paciente', lastName: '$pId', email: '', role: 'paciente'),
          );
          resolvedPatient = '${user.name} ${user.lastName}'.trim();
        }
      }

      String resolvedDoctor = app.doctorName;
      final dId = int.tryParse(app.doctorName);
      if (dId != null) {
        resolvedDoctor = 'Dra. Lucía Mendoza';
      }

      return Appointment(
        id: app.id,
        doctorName: resolvedDoctor,
        patientName: resolvedPatient,
        dateTime: app.dateTime,
        status: app.status,
        reason: app.reason,
      );
    } catch (_) {
      return app;
    }
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
              title: const Text('Agendar Cita', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Paciente:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedPatientId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    const SizedBox(height: 16),
                    const Text('Fecha y Hora:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
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
                      icon: const Icon(Icons.calendar_today, color: AppColors.primary),
                      label: Text(
                        '${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} - ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: AppColors.textDark),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Motivo de la Cita:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
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
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                        const SnackBar(content: Text('Por favor, ingresa el motivo de la cita.')),
                      );
                      return;
                    }

                    setDialogState(() {
                      isSaving = true;
                    });

                    final newApp = Appointment(
                      id: '',
                      doctorName: (loginProvider.doctorId ?? 1).toString(),
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
                      _loadAppointmentsData(); // Reload
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
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Agendar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBody(AppointmentsProvider provider, ThemeData theme) {
    if (provider.status == AppointmentsListStatus.loading ||
        provider.status == AppointmentsListStatus.initial) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    } else if (provider.status == AppointmentsListStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                provider.error ?? 'Error desconocido',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAppointmentsData,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: const Text('Reintentar',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final allAppointments = provider.appointments;

    return RefreshIndicator(
      onRefresh: () async => _loadAppointmentsData(),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mes',
              },
              eventLoader: (day) {
                return _getAppointmentsForDay(day, allAppointments);
              },
              onDaySelected: (selectedDay, focusedDay) {
                _onDaySelected(selectedDay, focusedDay, allAppointments);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.pinkAccent.shade100,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
              ),
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Citas Próximas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          if (allAppointments.isEmpty)
            const Text('No hay citas programadas')
          else
            ...allAppointments.take(3).map((app) => _buildAppointmentCard(app, theme, isCompact: false)),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment, ThemeData theme, {bool isCompact = false}) {
    final app = _resolveAppointmentNames(appointment, context);
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (app.status) {
      case AppointmentStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'COMPLETADA';
        break;
      case AppointmentStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'CANCELADA';
        break;
      case AppointmentStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'PENDIENTE';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: isCompact ? 1 : 2,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: isCompact ? 16 : 20),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isCompact ? 10 : 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatDate(app.dateTime),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: isCompact ? 11 : 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFF0E6EA),
                  radius: isCompact ? 16 : 24,
                  child: Icon(Icons.medical_services, color: AppColors.primary, size: isCompact ? 16 : 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.reason,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontSize: isCompact ? 14 : 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Paciente: ${app.patientName}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: isCompact ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompact) const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
