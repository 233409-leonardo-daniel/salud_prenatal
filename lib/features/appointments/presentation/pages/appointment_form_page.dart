import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../domain/entities/appointment.dart';
import '../providers/create_appointment_provider.dart';
import 'appointment_state.dart';

class AppointmentFormPage extends StatefulWidget {
  const AppointmentFormPage({super.key});

  @override
  State<AppointmentFormPage> createState() => _AppointmentFormPageState();
}

class _AppointmentFormPageState extends State<AppointmentFormPage> {
  final _reasonController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int? _selectedPatientId;
  bool _isLoadingPatients = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPatientsIfNeeded());
  }

  Future<void> _loadPatientsIfNeeded() async {
    final dashboardProvider = context.read<DashboardProvider>();
    if (dashboardProvider.patients.isNotEmpty) return;

    final doctorId = context.read<LoginProvider>().doctorId;
    if (doctorId == null) return;

    setState(() => _isLoadingPatients = true);
    await dashboardProvider.loadDoctorPatients(doctorId);
    if (!mounted) return;
    setState(() => _isLoadingPatients = false);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final doctorId = context.read<LoginProvider>().doctorId;
    if (doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar al médico de la sesión.')),
      );
      return;
    }
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un paciente.')));
      return;
    }
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
      doctorId: doctorId,
      patientId: _selectedPatientId!,
      doctorName: doctorId.toString(),
      patientName: _selectedPatientId.toString(),
      dateTime: finalDateTime,
      reason: _reasonController.text,
    );

    context.read<CreateAppointmentProvider>().createAppointment(appointment).then((_) {
      if (!mounted) return;
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
    final dashboardProvider = context.watch<DashboardProvider>();
    final patientsList = dashboardProvider.patients;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Nueva Cita', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isLoadingPatients)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (patientsList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No hay pacientes registrados para agendar citas.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              DropdownButtonFormField<int>(
                value: _selectedPatientId,
                decoration: const InputDecoration(labelText: 'Paciente'),
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
                onChanged: (val) => setState(() => _selectedPatientId = val),
              ),
            SizedBox(height: 16),
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
