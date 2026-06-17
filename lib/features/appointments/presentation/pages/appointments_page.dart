import 'package:flutter/material.dart';
import '../../../../theme/theme.dart';
import '../providers/appointment_provider.dart';
import '../../data/models/appointment_model.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  late final AppointmentProvider _appointmentProvider;

  @override
  void initState() {
    super.initState();
    _appointmentProvider = AppointmentProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appointmentProvider.fetchAppointments();
    });
  }

  @override
  void dispose() {
    _appointmentProvider.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F8),
      appBar: AppBar(
        title: const Text('Citas Médicas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _appointmentProvider,
        builder: (context, _) {
          if (_appointmentProvider.isLoading && _appointmentProvider.appointments.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (_appointmentProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      _appointmentProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _appointmentProvider.fetchAppointments(),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          final appointments = _appointmentProvider.appointments;

          if (appointments.isEmpty) {
            return const Center(
              child: Text('No hay citas programadas'),
            );
          }

          return RefreshIndicator(
            onRefresh: _appointmentProvider.fetchAppointments,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return _buildAppointmentCard(appointment, theme);
              },
            ),
          );
        },
      ),
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

  Widget _buildAppointmentCard(AppointmentModel appointment, ThemeData theme) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (appointment.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'COMPLETADA';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'CANCELADA';
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'PENDIENTE';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatDate(appointment.dateTime),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFE5E5EA)),
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFF0E6EA),
                  radius: 24,
                  child: Icon(Icons.medical_services, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Paciente: ${appointment.patientName}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.reason,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
