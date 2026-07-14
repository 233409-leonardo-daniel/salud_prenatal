import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/enums/appointment_status.dart';
import '../../domain/entities/appointment.dart';
import '../../../../core/session/session_manager.dart';
import '../providers/appointment_provider.dart';
import '../providers/delete_appointment_provider.dart';
import '../providers/update_appointment_provider.dart';
import '../widgets/appointment_status_chip.dart';
import 'appointment_state.dart';

class AppointmentDetailPage extends StatelessWidget {
  final Appointment appointment;

  const AppointmentDetailPage({super.key, required this.appointment});

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
    final loginProvider = context.watch<SessionManager>();
    final isDoctor = loginProvider.role == 'doctor' || loginProvider.role == 'doctor(a)';
    final isReceptionist = loginProvider.role == 'receptionist' || loginProvider.role == 'recepcionista' || loginProvider.role == 'recepcionist';
    
    // Obtenemos la cita del provider si existe (para reflejar cambios locales de estado)
    final provider = context.watch<AppointmentsProvider>();
    final currentAppointment = provider.appointments.firstWhere(
      (a) => a.id == appointment.id,
      orElse: () => appointment,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Detalles de la Cita',
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
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.calendar_month, color: AppColors.primary, size: 40),
                  ),
                  SizedBox(height: 16),
                  Text(
                    currentAppointment.reason,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _formatDate(currentAppointment.dateTime),
                    style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                  ),
                  SizedBox(height: 16),
                  AppointmentStatusChip(status: currentAppointment.status),
                ],
              ),
            ),
            SizedBox(height: 16),
            if (isDoctor || isReceptionist) ...[
              _buildInfoCard('Paciente', currentAppointment.patientName, Icons.person_outline),
              SizedBox(height: 12),
            ],
            _buildInfoCard('Médico', currentAppointment.doctorName, Icons.medical_services_outlined),
            
            SizedBox(height: 32),
            
            if (isReceptionist || isDoctor) ..._buildActionButtons(context, currentAppointment, provider),

            if (!isReceptionist && !isDoctor)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text('Volver al Calendario', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              SizedBox(height: 4),
              Text(value, style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context, Appointment appointment, AppointmentsProvider provider) {
    if (provider.viewState == AppointmentActionStatus.loading) {
      return [Center(child: CircularProgressIndicator())];
    }
    
    List<Widget> buttons = [];
    
    void updateStatus(AppointmentStatus newStatus) async {
      await provider.updateAppointmentStatus(appointment.id, newStatus);
      if (!context.mounted) return;
      if (provider.viewState == AppointmentActionStatus.success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo actualizar el estado. Intenta de nuevo.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    void cancelAppointment() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Cancelar cita'),
          content: Text('¿Deseas marcar esta cita como cancelada? El registro se conserva, solo cambia su estado.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('No')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Sí, cancelar', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );
      if (confirm != true || !context.mounted) return;
      updateStatus(AppointmentStatus.cancelled);
    }

    void rescheduleAppointment() async {
      DateTime newDateTime = appointment.dateTime;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (dialogCtx, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: Text('Reagendar Cita', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Nueva fecha y hora:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final baseDate = newDateTime.isBefore(DateTime.now()) ? DateTime.now() : newDateTime;
                        final date = await showDatePicker(
                          context: dialogCtx,
                          initialDate: baseDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: dialogCtx,
                            initialTime: TimeOfDay.fromDateTime(newDateTime),
                          );
                          if (time != null) {
                            setDialogState(() {
                              newDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            });
                          }
                        }
                      },
                      icon: Icon(Icons.calendar_today, color: AppColors.primary),
                      label: Text(
                        '${newDateTime.day}/${newDateTime.month}/${newDateTime.year} - ${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: AppColors.textDark),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx, false),
                    child: Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogCtx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Guardar', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed != true || !context.mounted) return;

      final updated = Appointment(
        id: appointment.id,
        doctorId: appointment.doctorId,
        patientId: appointment.patientId,
        doctorName: appointment.doctorName,
        patientName: appointment.patientName,
        dateTime: newDateTime,
        status: appointment.status,
        reason: appointment.reason,
      );

      final updateProvider = context.read<UpdateAppointmentProvider>();
      await updateProvider.updateAppointment(updated);
      if (!context.mounted) return;
      if (updateProvider.status == UpdateAppointmentStatus.success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo reagendar la cita: ${updateProvider.error ?? "Error desconocido"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    void deleteAndGoBack() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Eliminar cita'),
          content: Text('¿Estás segura de que deseas eliminar esta cita? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('No')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Sí, eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirm != true || !context.mounted) return;
      final deleteProvider = context.read<DeleteAppointmentProvider>();
      await deleteProvider.deleteAppointment(appointment.id.toString());
      if (!context.mounted) return;
      if (deleteProvider.status == DeleteAppointmentStatus.success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar la cita'), backgroundColor: Colors.red),
        );
      }
    }
    
    if (appointment.status == AppointmentStatus.pending) {
      buttons.add(_actionButton('Confirmar Asistencia', Colors.blue, () => updateStatus(AppointmentStatus.confirmed)));
      buttons.add(SizedBox(height: 8));
      buttons.add(_actionButton('Reagendar Cita', AppColors.primary, rescheduleAppointment));
      buttons.add(SizedBox(height: 8));
      buttons.add(_actionButton('Cancelar Cita', Colors.orange, cancelAppointment));
      buttons.add(SizedBox(height: 8));
      buttons.add(_actionButton('Eliminar Cita', Colors.red, deleteAndGoBack));
    } else if (appointment.status == AppointmentStatus.confirmed) {
      buttons.add(_actionButton('Reagendar Cita', AppColors.primary, rescheduleAppointment));
      buttons.add(SizedBox(height: 8));
      buttons.add(_actionButton('Cancelar Cita', Colors.orange, cancelAppointment));
      buttons.add(SizedBox(height: 8));
      buttons.add(_actionButton('Eliminar Cita', Colors.red, deleteAndGoBack));
    } else {
      buttons.add(_actionButton('Eliminar Cita', Colors.red, deleteAndGoBack));
    }
    
    return buttons;
  }
  
  Widget _actionButton(String label, Color color, VoidCallback onPressed) {
    return _LiftButton(label: label, color: color, onPressed: onPressed);
  }
}

/// Botón blanco con sombra rosa suave alrededor y efecto de "levantamiento"
/// (se eleva y la sombra crece) al pasar el cursor por encima. El color
/// pasado (`color`) solo se usa para el texto, para conservar el
/// significado semántico (azul=confirmar, naranja=cancelar, rojo=eliminar).
class _LiftButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _LiftButton({required this.label, required this.color, required this.onPressed});

  @override
  State<_LiftButton> createState() => _LiftButtonState();
}

class _LiftButtonState extends State<_LiftButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovering ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(_hovering ? 0.35 : 0.18),
              blurRadius: _hovering ? 20 : 10,
              spreadRadius: _hovering ? 1 : 0,
              offset: Offset(0, _hovering ? 8 : 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: widget.onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  widget.label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
