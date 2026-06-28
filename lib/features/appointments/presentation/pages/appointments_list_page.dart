import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/appointment_provider.dart';
import 'appointment_detail_page.dart';
import '../widgets/appointment_card.dart';
import '../../../login/presentation/providers/login_provider.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text(
          'Todas las Citas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(provider),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigator.pushNamed(context, '/appointments/new');
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody(AppointmentsProvider provider) {
    if (provider.viewState == ViewState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (provider.viewState == ViewState.error) {
      return Center(child: Text('Error: ${provider.error}'));
    }
    
    if (provider.appointments.isEmpty) {
      return const Center(
        child: Text(
          'No hay citas programadas.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 16),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.appointments.length,
      itemBuilder: (context, index) {
        final appointment = provider.appointments[index];
        return AppointmentCard(
          appointment: appointment,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentDetailPage(appointment: appointment),
              ),
            );
          },
        );
      },
    );
  }
}
