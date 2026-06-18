import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/theme.dart';
import '../providers/appointment_provider.dart';
import 'appointment_state.dart';
import '../../domain/entities/appointment.dart';
import 'appointment_detail_page.dart';

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
      context.read<AppointmentsProvider>().loadAppointments('dummy_user_id');
    });
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
                            builder: (context) => AppointmentDetailPage(appointment: app),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Función de agendar próxima (Mock)')),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
                onPressed: () => context
                    .read<AppointmentsProvider>()
                    .loadAppointments('dummy_user_id'),
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
      onRefresh: () =>
          context.read<AppointmentsProvider>().loadAppointments('dummy_user_id'),
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
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (appointment.status) {
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
                  _formatDate(appointment.dateTime),
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
                        appointment.reason,
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
                        'Paciente: ${appointment.patientName}',
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
