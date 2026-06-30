import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/enums/appointment_status.dart';
import '../../domain/entities/appointment.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/delete_appointment_provider.dart';
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
    final loginProvider = context.watch<LoginProvider>();
    final isDoctor = loginProvider.role == 'doctor' || loginProvider.role == 'doctor(a)';
    final isReceptionist = loginProvider.role == 'receptionist' || loginProvider.role == 'recepcionista' || loginProvider.role == 'recepcionist';
    
    // Obtenemos la cita del provider si existe (para reflejar cambios locales de estado)
    final provider = context.watch<AppointmentsProvider>();
    final currentAppointment = provider.appointments.firstWhere(
      (a) => a.id == appointment.id,
      orElse: () => appointment,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
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
                color: Colors.white,
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
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFFFFF0F6),
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
            
            if (isReceptionist) ..._buildActionButtons(context, currentAppointment, provider),

            if (!isReceptionist)
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
        color: Colors.white,
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
    if (provider.viewState == ViewState.loading) {
      return [Center(child: CircularProgressIndicator())];
    }
    
    List<Widget> buttons = [];
    
    void updateStatus(AppointmentStatus newStatus) async {
      await provider.updateAppointmentStatus(appointment.id, newStatus);
      if (!context.mounted) return;
      if (provider.viewState == ViewState.success) {
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
      buttons.add(_actionButton('Eliminar Cita', Colors.red, deleteAndGoBack));
    } else if (appointment.status == AppointmentStatus.confirmed) {
      buttons.add(_actionButton('Marcar En Curso', Colors.indigo, () => updateStatus(AppointmentStatus.in_progress)));
      buttons.add(SizedBox(height: 8));
      buttons.add(_actionButton('Eliminar Cita', Colors.red, deleteAndGoBack));
    } else if (appointment.status == AppointmentStatus.in_progress) {
      buttons.add(_actionButton('Marcar Completada', Colors.green, () => updateStatus(AppointmentStatus.completed)));
      buttons.add(SizedBox(height: 8));
      buttons.add(_actionButton('Eliminar Cita', Colors.red, deleteAndGoBack));
    } else {
      buttons.add(_actionButton('Eliminar Cita', Colors.red, deleteAndGoBack));
    }
    
    return buttons;
  }
  
  Widget _actionButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}
