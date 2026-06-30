import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/appointment.dart';
import '../providers/create_appointment_provider.dart';
import 'appointment_state.dart';

// Este formulario simplificado asume que un médico (doctorId: 1) y paciente (patientId: 2)
// son elegidos o pasados al formulario, y se centra en seleccionar la fecha y hora.
class AppointmentFormPage extends StatefulWidget {
  const AppointmentFormPage({super.key});

  @override
  State<AppointmentFormPage> createState() => _AppointmentFormPageState();
}

class _AppointmentFormPageState extends State<AppointmentFormPage> {
  final _reasonController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedDate == null || _selectedTime == null || _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor complete todos los campos')));
      return;
    }

    final finalDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final appointment = Appointment(
      id: 0,
      doctorId: 1, // Ejemplo estático (requeriría un dropdown con UserSearch en una app completa)
      patientId: 2, // Ejemplo estático
      doctorName: '1', // Fake para backend si todavía usa names como ids
      patientName: '2', // Fake
      dateTime: finalDateTime,
      reason: _reasonController.text,
    );

    context.read<CreateAppointmentProvider>().createAppointment(appointment).then((_) {
      final error = context.read<CreateAppointmentProvider>().error;
      if (error == null) {
        Navigator.pop(context, true); // Devuelve true para recargar la lista anterior
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreateAppointmentProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: Text('Nueva Cita', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Motivo de la Cita'),
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text(_selectedDate == null ? 'Seleccionar Fecha' : '${_selectedDate!.toLocal()}'.split(' ')[0]),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            ListTile(
              title: Text(_selectedTime == null ? 'Seleccionar Hora' : _selectedTime!.format(context)),
              trailing: Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() => _selectedTime = time);
                }
              },
            ),
            SizedBox(height: 32),
            if (provider.status == CreateAppointmentStatus.loading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text('Guardar Cita', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}
