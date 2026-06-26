import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../appointments/presentation/pages/appointments_page.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../appointments/presentation/providers/appointment_provider.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/presentation/pages/appointment_detail_page.dart';
import '../../../patients/presentation/pages/patients_list_page.dart';
import '../../../patients/presentation/pages/invitation_code_page.dart';
import '../../../../core/widgets/latest_diary_record_card.dart';
import '../../../patient_diaries/presentation/providers/patient_diaries_provider.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../chat/presentation/pages/chat_list_page.dart';
import '../../../chat/presentation/pages/chat_room_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _userRole = 'patient'; // Default role
  int _currentTab = 0; // Selected bottom navigation tab
  bool _isInitialized = false;

  // Search and filter query for the doctor's patient list page
  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _userRole = args;
      }
      _isInitialized = true;
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    final loginProvider = context.read<LoginProvider>();
    final dashboardProvider = context.read<DashboardProvider>();
    final appointmentsProvider = context.read<AppointmentsProvider>();
    final diariesProvider = context.read<PatientDiariesProvider>();

    if (_userRole == 'doctor') {
      final docId = loginProvider.doctorId ?? 1;
      await dashboardProvider.loadDoctorDashboard(docId);
      if (!mounted) return;
      appointmentsProvider.loadAppointments(docId.toString(), isDoctor: true);
    } else {
      final patId = loginProvider.patientId ?? loginProvider.userId ?? 2;
      await dashboardProvider.loadPatientDashboard(patId, loginProvider.userId ?? 2);
      if (!mounted) return;
      appointmentsProvider.loadAppointments(patId.toString(), isDoctor: false);
      
      final medicalRecordId = dashboardProvider.medicalRecord?.medicalRecordId ?? 1;
      diariesProvider.loadDiaries(medicalRecordId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- WIDGET BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final loginProvider = context.watch<LoginProvider>();
    final String doctorName = loginProvider.name.isNotEmpty 
        ? 'Dra. ${loginProvider.name}' 
        : 'Dra. Mendoza';

    if (_userRole == 'doctor') {
      if (_currentTab == 0) {
        // Doctor main dashboard header
        return AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=100'),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Buenos días,',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.normal),
                  ),
                  Text(
                    doctorName,
                    style: TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EFF4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_none_outlined, size: 20, color: AppColors.textDark),
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 12),
          ],
        );
      } else if (_currentTab == 1) {
        // "Mis Pacientes" header
        return AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=100'),
              ),
              const SizedBox(width: 10),
              Text(
                'Salud Prenatal',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InvitationCodePage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined, color: AppColors.textDark),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        );
      }
    } else {
      // Patient dashboard header (renders directly in screen body to match styling)
    }
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 0,
      elevation: 0,
    );
  }

  Widget _buildBody() {
    if (_userRole == 'doctor') {
      switch (_currentTab) {
        case 0:
          return _buildDoctorDashboard();
        case 1:
          return const PatientsListPage();
        case 2:
          return const AppointmentsPage();
        case 4:
          return const ProfilePage();
        case 3:
          return const ChatListPage();
        default:
          return _buildPlaceholderView('Módulo de comunicación y perfil médico.');
      }
    } else {
      switch (_currentTab) {
        case 0:
          return _buildPatientDashboard();
        case 1:
          return const AppointmentsPage();
        case 3:
          return const ProfilePage();
        case 2:
          return const ChatListPage();
        default:
          return _buildPlaceholderView('Módulo de salud prenatal.');
      }
    }
  }

  Widget _buildPlaceholderView(String description) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction_outlined, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'En Construcción',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // --- DOCTOR VIEWS ---

  Widget _buildDoctorDashboard() {
    final dashboardProvider = context.watch<DashboardProvider>();
    if (dashboardProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    final appointmentsProvider = context.watch<AppointmentsProvider>();
    final today = DateTime.now();

    final totalPatientsStr = dashboardProvider.patients.length.toString();

    final todayAppointments = appointmentsProvider.appointments.where((app) =>
        app.dateTime.year == today.year &&
        app.dateTime.month == today.month &&
        app.dateTime.day == today.day
    ).toList();
    todayAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final citasHoyStr = todayAppointments.length.toString();

    final priorityAlerts = <Widget>[];
    for (final patient in dashboardProvider.patients) {
      final pId = patient['patient_id'] ?? 0;
      if (pId % 3 == 0) {
        final patientUser = dashboardProvider.users.firstWhere(
          (u) => u.userId == patient['user_id'],
          orElse: () => UserProfile(name: 'Paciente', lastName: '$pId', email: '', role: 'paciente'),
        );
        final initials = '${patientUser.name.isNotEmpty ? patientUser.name[0] : 'P'}${patientUser.lastName.isNotEmpty ? patientUser.lastName[0] : ''}';
        final fullName = '${patientUser.name} ${patientUser.lastName}'.trim();
        priorityAlerts.add(
          _buildAlertCard(fullName, 'Riesgo de Preeclampsia (Alto)', initials),
        );
        priorityAlerts.add(const SizedBox(height: 12));
      }
    }
    if (priorityAlerts.isEmpty) {
      priorityAlerts.add(
        const Card(
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No hay alertas de riesgo alto el día de hoy.', style: TextStyle(color: AppColors.textMuted)),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _buildDoctorStatCard('Total Pacientes', totalPatientsStr, Icons.people_outline, Colors.pink),
              const SizedBox(width: 12),
              _buildDoctorStatCard('Citas Hoy', citasHoyStr, Icons.calendar_today_outlined, Colors.teal),
            ],
          ),
          const SizedBox(height: 12),

          // Alertas Prioritarias Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Alertas Prioritarias',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Ver todas',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...priorityAlerts,
          const SizedBox(height: 12),

          // Próximas Citas Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Próximas Citas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: AppColors.textDark),
                    SizedBox(width: 4),
                    Text(
                      'Hoy',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (todayAppointments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'No hay citas programadas para hoy.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...todayAppointments.map((app) {
              final isPm = app.dateTime.hour >= 12;
              final hour = app.dateTime.hour == 0 
                  ? 12 
                  : (app.dateTime.hour > 12 ? app.dateTime.hour - 12 : app.dateTime.hour);
              final timeStr = '${hour.toString().padLeft(2, '0')}:${app.dateTime.minute.toString().padLeft(2, '0')} ${isPm ? 'PM' : 'AM'}';
              return Column(
                children: [
                  _buildDoctorAppointmentItem(
                    timeStr,
                    app.patientName,
                    app.reason,
                    app.reason.toLowerCase().contains('urgente') || app.status == AppointmentStatus.cancelled,
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E5EA)),
                ],
              );
            }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDoctorStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              count,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(String name, String alert, String initials) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          // Red curve container border decoration
          Container(
            width: 4,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: const Color(0xFFFFEBEA),
            radius: 20,
            child: Text(
              initials,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      alert,
                      style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Detalle',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorAppointmentItem(String time, String name, String subtitle, bool isUrgent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time.split(' ')[0],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                Text(
                  time.split(' ')[1],
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.pink.shade50,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12, 
                    color: isUrgent ? Colors.red.shade700 : AppColors.textMuted,
                    fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Color(0xFFC7C7CC)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // --- OLD METHODS REMOVED ---

  // --- PATIENT VIEWS ---

  Widget _buildPatientDashboard() {
    final dashboardProvider = context.watch<DashboardProvider>();
    if (dashboardProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    final loginProvider = context.watch<LoginProvider>();
    final appointmentsProvider = context.watch<AppointmentsProvider>();
    final diariesProvider = context.watch<PatientDiariesProvider>();

    final String displayName = loginProvider.fullName.isNotEmpty
        ? loginProvider.fullName
        : 'Ana García';

    final currentWeeks = dashboardProvider.currentPatientData?['current_gestational_weeks'] ?? 28;

    final medicalRecord = dashboardProvider.medicalRecord;
    String patientRisk = 'Bajo';

    if (medicalRecord != null) {
      if (medicalRecord.previousPreeclampsia || 
          medicalRecord.chronicHypertension || 
          medicalRecord.previousHypertension) {
        patientRisk = 'Alto';
      } else if (medicalRecord.diabetes || 
                 medicalRecord.familyHistoryHypertension) {
        patientRisk = 'Medio';
      }
    }

    final upcomingAppointments = appointmentsProvider.appointments.where((app) => 
        app.status == AppointmentStatus.pending && 
        app.dateTime.isAfter(DateTime.now().subtract(const Duration(hours: 2)))
    ).toList();
    upcomingAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final nextApp = upcomingAppointments.isNotEmpty ? upcomingAppointments.first : null;

    final monthsList = ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'];
    final monthStr = nextApp != null ? monthsList[nextApp.dateTime.month - 1] : 'S/C';
    final dayStr = nextApp != null ? nextApp.dateTime.day.toString() : '--';
    
    final isPm = nextApp != null && nextApp.dateTime.hour >= 12;
    final hour = nextApp != null 
        ? (nextApp.dateTime.hour == 0 ? 12 : (nextApp.dateTime.hour > 12 ? nextApp.dateTime.hour - 12 : nextApp.dateTime.hour))
        : 12;
    final timeStr = nextApp != null 
        ? '${hour.toString().padLeft(2, '0')}:${nextApp.dateTime.minute.toString().padLeft(2, '0')} ${isPm ? 'PM' : 'AM'}' 
        : '--';
    
    final reasonStr = nextApp != null ? nextApp.reason : 'No hay citas programadas';
    
    String docNameStr = 'Sin médico';
    String docSpecialtyStr = 'Especialidad no especificada';
    String? docImageStr;

    if (dashboardProvider.dashboardData?['current_doctor'] != null) {
      docNameStr = dashboardProvider.dashboardData!['current_doctor'];
      docSpecialtyStr = dashboardProvider.dashboardData?['current_doctor_specialty'] ?? docSpecialtyStr;
      docImageStr = dashboardProvider.dashboardData?['current_doctor_image'];
    } else if (nextApp != null) {
      docNameStr = nextApp.doctorName;
    }

    final systolicPressures = <double>[];
    final consultationDays = <String>[];
    final daysOfWeek = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    for (var i = 0; i < dashboardProvider.consultations.length; i++) {
      final consultation = dashboardProvider.consultations[i];
      final pressureRegex = RegExp(r'(\d{2,3})/\d{2,3}');
      final match = pressureRegex.firstMatch(consultation.objective);
      if (match != null) {
        final systolic = double.tryParse(match.group(1)!) ?? 120.0;
        systolicPressures.add(systolic);
        
        final dayIndex = consultation.createdAt.weekday - 1;
        consultationDays.add(daysOfWeek[dayIndex]);
      }
    }

    if (systolicPressures.isEmpty) {
      systolicPressures.addAll([115.0, 120.0, 118.0, 122.0, 120.0, 117.0, 119.0]);
      consultationDays.addAll(daysOfWeek);
    }

    final barsList = <Widget>[];
    for (var i = 0; i < systolicPressures.length; i++) {
      final val = systolicPressures[i];
      final heightVal = ((val - 90) * 1.33 + 20).clamp(15.0, 100.0);
      final isActive = i == systolicPressures.length - 1;
      barsList.add(_buildBar(heightVal, isActive));
    }

    final dayLabelsList = <Widget>[];
    for (var i = 0; i < consultationDays.length; i++) {
      final day = consultationDays[i];
      final isActive = i == consultationDays.length - 1;
      dayLabelsList.add(_buildDayLabel(day, isActive));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Hola, $displayName',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '👋',
                        style: TextStyle(fontSize: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Semana $currentWeeks de embarazo',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ],
              ),
              const CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=100'),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Banner de vinculación si no tiene doctor
          if (dashboardProvider.dashboardData?['current_doctor'] == null)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.pink.shade100, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.medical_services_outlined, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aún no tienes un médico',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Vincúlate usando el código de invitación.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const InvitationCodePage()),
                      );
                      if (result == true && mounted) {
                        final loginProvider = context.read<LoginProvider>();
                        context.read<DashboardProvider>().loadPatientDashboard(loginProvider.patientId ?? 0, loginProvider.userId ?? 0);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Vincular', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // MI ESTADO DE HOY Section
          const Text(
            'MI ESTADO DE HOY',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),

          if (diariesProvider.isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (diariesProvider.diaries.isNotEmpty)
            LatestDiaryRecordCard(
              systolic: diariesProvider.diaries.first.systolic,
              diastolic: diariesProvider.diaries.first.diastolic,
              weightKg: diariesProvider.diaries.first.weightKg,
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Text(
                'Aún no tienes registros en tu bitácora.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/patient-diaries');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            label: const Text(
              'Registrar medición',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
            ),
          ),
          const SizedBox(height: 28),

          // MI PRÓXIMA CITA Section
          const Text(
            'MI PRÓXIMA CITA',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),

          // Magenta Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withRed(220)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(51),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            monthStr,
                            style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            dayStr,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeStr,
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            reasonStr,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: docImageStr != null 
                        ? NetworkImage(docImageStr)
                        : const NetworkImage('https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=100'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            docNameStr,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            docSpecialtyStr,
                            style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (nextApp != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AppointmentDetailPage(appointment: nextApp),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(51),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Ver detalles', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          int docUserId = 1; // Default mock doctor ID
                          if (dashboardProvider.users.isNotEmpty) {
                            final matchedDoc = dashboardProvider.users.firstWhere(
                              (u) => u.role.toLowerCase().contains('doctor') && 
                                     docNameStr.toLowerCase().contains(u.name.toLowerCase()),
                              orElse: () => dashboardProvider.users.firstWhere(
                                (u) => u.role.toLowerCase().contains('doctor'),
                                orElse: () => UserProfile(userId: 1, name: 'Pedro', lastName: 'Gomez', email: '', role: 'doctor'),
                              ),
                            );
                            docUserId = matchedDoc.userId ?? 1;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatRoomPage(
                                otherUserId: docUserId,
                                otherUserName: docNameStr,
                                otherUserRole: 'doctor',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 14),
                            SizedBox(width: 4),
                            Text('Enviar mensaje', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // SEGUIMIENTO SEMANAL Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SEGUIMIENTO SEMANAL',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text(
                  'Presión Sistólica',
                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weekly chart card mockup
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: barsList,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: dayLabelsList,
                ),
                const SizedBox(height: 16),
                Text(
                  patientRisk == 'Alto'
                      ? 'Atención: Tu presión muestra variaciones. Reporta cualquier malestar de inmediato.'
                      : 'Tu presión se mantiene estable dentro de los rangos normales.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // COMUNIDAD Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'COMUNIDAD',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Ver más',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Doctor Tip card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.pink.shade50),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dra. Sofia - Consejos',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '"Es normal sentir más cansancio en la semana $currentWeeks. Recuerda hidratarte bien y..."',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Community Question card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.amber,
                          child: Text('M', style: TextStyle(color: Colors.white, fontSize: 8)),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'María R.',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const Text('Hace 2h', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '¿Alguna recomendación para dormir mejor en este trimestre? 🤰✨',
                  style: TextStyle(fontSize: 13, color: AppColors.textDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBar(double heightPercentage, bool isActive) {
    return Container(
      width: 8,
      height: heightPercentage,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildDayLabel(String label, bool isActive) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isActive ? AppColors.primary : AppColors.textMuted,
      ),
    );
  }

  // --- BOTTOM NAV BAR BUILDER ---

  Widget _buildBottomNavBar() {
    if (_userRole == 'doctor') {
      // Bottom nav bar for Doctor role
      return BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Pacientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Citas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            activeIcon: Icon(Icons.message),
            label: 'Mensajes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      );
    } else {
      // Bottom nav bar for Patient role (which has a central circular "+" button)
      return BottomAppBar(
        color: Colors.white,
        elevation: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPatientTabItem(0, Icons.home_outlined, Icons.home, 'Inicio'),
            _buildPatientTabItem(1, Icons.calendar_today_outlined, Icons.calendar_today, 'Citas'),
            // Central floating circular add button
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/patient-diaries');
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
            _buildPatientTabItem(2, Icons.message_outlined, Icons.message, 'Mensajes'),
            _buildPatientTabItem(3, Icons.person_outline, Icons.person, 'Perfil'),
          ],
        ),
      );
    }
  }

  Widget _buildPatientTabItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? filledIcon : outlineIcon,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
