import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../appointments/presentation/pages/appointments_page.dart';
import '../../../login/presentation/providers/login_provider.dart';
import 'patient_record_page.dart';
import 'patient_progress_page.dart';
import '../providers/dashboard_provider.dart';
import '../../../appointments/presentation/providers/appointment_provider.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/presentation/pages/appointment_detail_page.dart';

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
  String _activeFilter = 'Todas';

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

  void _loadDashboardData() {
    final loginProvider = context.read<LoginProvider>();
    final dashboardProvider = context.read<DashboardProvider>();
    if (_userRole == 'doctor') {
      final docId = loginProvider.doctorId ?? 1;
      dashboardProvider.loadDoctorDashboard(docId);
      context.read<AppointmentsProvider>().loadAppointments(docId.toString(), isDoctor: true);
    } else {
      final patId = loginProvider.patientId ?? loginProvider.userId ?? 2;
      dashboardProvider.loadPatientDashboard(patId, loginProvider.userId ?? 2);
      context.read<AppointmentsProvider>().loadAppointments(patId.toString(), isDoctor: false);
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
              onPressed: () {},
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
    final dashboardProvider = context.watch<DashboardProvider>();
    if (dashboardProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_userRole == 'doctor') {
      switch (_currentTab) {
        case 0:
          return _buildDoctorDashboard();
        case 1:
          return _buildDoctorPatientsList();
        case 2:
          return const AppointmentsPage();
        default:
          return _buildPlaceholderView('Módulo de comunicación y perfil médico.');
      }
    } else {
      switch (_currentTab) {
        case 0:
          return _buildPatientDashboard();
        case 1:
          return const AppointmentsPage();
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
              color: Colors.black.withOpacity(0.02),
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
            color: Colors.black.withOpacity(0.01),
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

  // --- DOCTOR PATIENTS LIST VIEW ("Mis Pacientes") ---

  Widget _buildDoctorPatientsList() {
    final dashboardProvider = context.watch<DashboardProvider>();
    final totalPatientsStr = dashboardProvider.patients.length.toString();

    final patientCards = <Widget>[];
    for (final patient in dashboardProvider.patients) {
      final pId = patient['patient_id'] ?? 0;
      final patientUser = dashboardProvider.users.firstWhere(
        (u) => u.userId == patient['user_id'],
        orElse: () => UserProfile(
          name: 'Paciente',
          lastName: '$pId',
          email: '',
          role: 'paciente',
        ),
      );

      final patientName = '${patientUser.name} ${patientUser.lastName}'.trim();
      final initials = '${patientUser.name.isNotEmpty ? patientUser.name[0] : 'P'}${patientUser.lastName.isNotEmpty ? patientUser.lastName[0] : ''}';

      String risk = 'Bajo Riesgo';
      Color riskBg = AppColors.riskLowBg;
      Color riskText = AppColors.riskLowText;
      Color imgBg = const Color(0xFFE0F2F1);

      if (pId % 3 == 0) {
        risk = 'Alto Riesgo';
        riskBg = AppColors.riskHighBg;
        riskText = AppColors.riskHighText;
        imgBg = const Color(0xFFFFF0F6);
      } else if (pId % 3 == 1) {
        risk = 'Medio Riesgo';
        riskBg = AppColors.riskMediumBg;
        riskText = AppColors.riskMediumText;
        imgBg = const Color(0xFFFFF4E5);
      }

      patientCards.add(
        _buildPatientListCard(
          name: patientName,
          id: '#SP-$pId',
          risk: risk,
          riskColorBg: riskBg,
          riskColorText: riskText,
          gestationAge: '${patient['current_gestational_weeks'] ?? 28} sem',
          status: 'Estable',
          statusIcon: Icons.check_circle_outline,
          statusIconColor: Colors.teal,
          avatarInitials: initials,
          imageBackground: imgBg,
        ),
      );
      patientCards.add(const SizedBox(height: 12));
    }

    if (patientCards.isEmpty) {
      patientCards.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'No se encontraron pacientes.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Mis Pacientes',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'Gestión activa de cuidados prenatales.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  totalPatientsStr,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search patient bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Buscar paciente por nombre o ID...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.pink.shade50),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.pink.shade50),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              setState(() {}); // Redraw list on search query
            },
          ),
          const SizedBox(height: 16),

          // Scrollable Filter Tags
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todas'),
                const SizedBox(width: 8),
                _buildFilterChip('Riesgo Alto'),
                const SizedBox(width: 8),
                _buildFilterChip('Riesgo Medio'),
                const SizedBox(width: 8),
                _buildFilterChip('Riesgo Bajo'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ...patientCards,
          const SizedBox(height: 24),

          // Pagination indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.textMuted),
                onPressed: () {},
              ),
              _buildPageDot(1, true),
              _buildPageDot(2, false),
              _buildPageDot(3, false),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFEFEFF4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPatientListCard({
    required String name,
    required String id,
    required String risk,
    required Color riskColorBg,
    required Color riskColorText,
    required String gestationAge,
    required String status,
    required IconData statusIcon,
    required Color statusIconColor,
    required String avatarInitials,
    required Color imageBackground,
  }) {
    // Basic search filtering
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      if (!name.toLowerCase().contains(query) && !id.toLowerCase().contains(query)) {
        return const SizedBox.shrink();
      }
    }

    // Risk filtering
    if (_activeFilter != 'Todas') {
      if (_activeFilter == 'Riesgo Alto' && risk != 'Alto Riesgo') return const SizedBox.shrink();
      if (_activeFilter == 'Riesgo Medio' && risk != 'Medio Riesgo') return const SizedBox.shrink();
      if (_activeFilter == 'Riesgo Bajo' && risk != 'Bajo Riesgo') return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: imageBackground,
                radius: 24,
                child: Text(
                  avatarInitials,
                  style: TextStyle(color: riskColorText, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: $id',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColorBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  risk,
                  style: TextStyle(color: riskColorText, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Details row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Edad Gestacional', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text(gestationAge, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estado Actual', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusIconColor),
                          const SizedBox(width: 4),
                          Text(status, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: statusIconColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientRecordPage(
                          patientName: name,
                          patientId: id,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Ver Detalle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientProgressPage(
                          patientName: name,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: Colors.pinkAccent, width: 1),
                    backgroundColor: const Color(0xFFFFF0F6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.trending_up, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('Progreso', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageDot(int pageNum, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          pageNum.toString(),
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- PATIENT VIEWS ---

  Widget _buildPatientDashboard() {
    final loginProvider = context.watch<LoginProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final appointmentsProvider = context.watch<AppointmentsProvider>();

    final String displayName = loginProvider.fullName.isNotEmpty
        ? loginProvider.fullName
        : 'Ana García';

    final currentWeeks = dashboardProvider.currentPatientData?['current_gestational_weeks'] ?? 28;

    final medicalRecord = dashboardProvider.medicalRecord;
    String patientRisk = 'Bajo';
    Color patientRiskColor = Colors.teal.shade700;
    Color patientRiskBg = Colors.teal.shade400;
    Color patientRiskBgLight = Colors.teal.shade50;
    IconData patientRiskIcon = Icons.check;
    double progressValue = 0.95;

    if (medicalRecord != null) {
      if (medicalRecord.previousPreeclampsia || 
          medicalRecord.chronicHypertension || 
          medicalRecord.previousHypertension) {
        patientRisk = 'Alto';
        patientRiskColor = Colors.red.shade700;
        patientRiskBg = Colors.red.shade400;
        patientRiskBgLight = Colors.red.shade50;
        patientRiskIcon = Icons.warning_amber_rounded;
        progressValue = 0.35;
      } else if (medicalRecord.diabetes || 
                 medicalRecord.familyHistoryHypertension) {
        patientRisk = 'Medio';
        patientRiskColor = Colors.orange.shade700;
        patientRiskBg = Colors.orange.shade400;
        patientRiskBgLight = Colors.orange.shade50;
        patientRiskIcon = Icons.info_outline;
        progressValue = 0.65;
      }
    }

    String pressure = '120/80';
    String weight = '60.0';

    if (dashboardProvider.consultations.isNotEmpty) {
      final lastConsultation = dashboardProvider.consultations.last;
      final objectiveText = lastConsultation.objective;
      
      final pressureRegex = RegExp(r'(\d{2,3}/\d{2,3})');
      final pressureMatch = pressureRegex.firstMatch(objectiveText);
      if (pressureMatch != null) {
        pressure = pressureMatch.group(0)!;
      }

      final weightRegex = RegExp(r'Peso\s*(\d{2,3}(?:\.\d)?)');
      final weightMatch = weightRegex.firstMatch(objectiveText);
      if (weightMatch != null) {
        weight = weightMatch.group(1)!;
      } else {
        final doubleRegex = RegExp(r'(\d{2,3}\.\d)\s*kg');
        final doubleMatch = doubleRegex.firstMatch(objectiveText);
        if (doubleMatch != null) {
          weight = doubleMatch.group(1)!;
        }
      }
    } else {
      weight = (dashboardProvider.currentPatientData?['initial_weight'] ?? 60.0).toString();
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
    final docNameStr = nextApp != null ? nextApp.doctorName : 'Dra. Lucía Mendoza';

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

          // MI ESTADO DE HOY Section
          const Text(
            'MI ESTADO DE HOY',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),

          // Riesgo estimado card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riesgo estimado',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patientRisk,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: patientRiskColor),
                    ),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: progressValue,
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(patientRiskBg),
                        backgroundColor: patientRiskBgLight,
                      ),
                    ),
                    Icon(patientRiskIcon, color: patientRiskColor, size: 24),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.favorite_outline, color: AppColors.primary, size: 20),
                          Icon(Icons.show_chart, color: patientRisk == 'Bajo' ? Colors.green : Colors.orange, size: 16),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Presión', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text(pressure, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const Text('MMHG', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
                          const Icon(Icons.horizontal_rule, color: AppColors.textMuted, size: 16),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Peso actual', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text(weight, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const Text('KILOGRAMOS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () {},
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
                  color: AppColors.primary.withOpacity(0.2),
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            monthStr,
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold),
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
                    const CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=100'),
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
                            'Ginecología y Obstetricia',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
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
                          backgroundColor: Colors.white.withOpacity(0.2),
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
                        onPressed: () {},
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
                  color: Colors.black.withOpacity(0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                Container(
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Añadir nueva medición o registro')),
                );
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
