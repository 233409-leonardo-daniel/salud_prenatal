import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../appointments/presentation/providers/appointment_provider.dart';
import '../../../appointments/presentation/pages/appointments_list_page.dart';
import '../../../appointments/presentation/pages/appointment_form_page.dart';
import '../../../chat/presentation/pages/conversations_list_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../users/presentation/pages/user_search_page.dart';

class ReceptionistDashboardPage extends StatefulWidget {
  const ReceptionistDashboardPage({super.key});

  @override
  State<ReceptionistDashboardPage> createState() => _ReceptionistDashboardPageState();
}

class _ReceptionistDashboardPageState extends State<ReceptionistDashboardPage> {
  int _currentTab = 0;

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _currentTab == 0 ? _buildAppBar() : null, // Ocultar si está en otros tabs para que usen su propio AppBar
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final loginProvider = context.watch<LoginProvider>();
    final String receptionistName = loginProvider.name.isNotEmpty 
        ? loginProvider.name 
        : 'Recepcionista';
    final String initial = receptionistName.isNotEmpty ? receptionistName[0].toUpperCase() : 'R';

    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              initial,
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola,',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.normal),
              ),
              Text(
                receptionistName,
                style: TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF0EFF4),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_outlined, size: 20, color: AppColors.textDark),
          ),
          onPressed: () {},
        ),
        SizedBox(width: 12),
      ],
      backgroundColor: Colors.white,
      elevation: 0,
    );
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const AppointmentsListPage();
      case 2:
        return const ConversationsListPage();
      case 3:
        return const UserSearchPage();
      case 4:
        return const ProfilePage();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    final appointmentsProvider = context.watch<AppointmentsProvider>();
    final totalCitas = appointmentsProvider.appointments.length;
    final pending = appointmentsProvider.appointments.where((a) => a.status.toString().contains('pending')).length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Resumen del Día',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Citas Programadas', totalCitas.toString(), Icons.calendar_today, Colors.blue),
              SizedBox(width: 12),
              _buildStatCard('Citas Pendientes', pending.toString(), Icons.pending_actions, Colors.orange),
            ],
          ),
          SizedBox(height: 24),
          Text(
            'Acciones Rápidas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard('Nueva Cita', Icons.add_circle, Colors.green, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AppointmentFormPage()));
                }),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionCard('Directorio', Icons.people, AppColors.primary, () {
                  setState(() => _currentTab = 3); // Navegar al directorio
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            SizedBox(height: 4),
            Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 12),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentTab,
      onTap: (index) => setState(() => _currentTab = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      backgroundColor: Colors.white,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Citas'),
        BottomNavigationBarItem(icon: Icon(Icons.message_outlined), activeIcon: Icon(Icons.message), label: 'Mensajes'),
        BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Directorio'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}
