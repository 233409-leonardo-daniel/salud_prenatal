import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors_ext.dart';
import '../../../appointments/presentation/pages/appointments_page.dart';
import '../../../../core/session/session_manager.dart';
import '../providers/dashboard_provider.dart';
import 'dashboard_state.dart';
import '../../data/models/medical_record_response.dart';
import '../../../appointments/presentation/providers/appointment_provider.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../../../appointments/presentation/pages/appointment_detail_page.dart';
import '../../../patients/presentation/pages/patients_list_page.dart';
import '../../../patients/presentation/pages/invitation_code_page.dart';
import 'patient_record_page.dart';
import '../../../../core/widgets/latest_diary_record_card.dart';
import '../../../patient_diaries/presentation/providers/patient_diaries_provider.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../chat/presentation/pages/chat_list_page.dart';
import '../../../chat/presentation/pages/chat_room_page.dart';
import '../../../forums/presentation/pages/forums_hub_page.dart';
import '../../../appointments/presentation/pages/appointment_form_page.dart';
import '../../../../core/enums/appointment_status.dart';
import '../../../appointments/domain/entities/appointment.dart';
import 'new_consultation_dialog.dart';

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
      final session = context.read<SessionManager>();
      final args = ModalRoute.of(context)?.settings.arguments;
      // El rol puede llegar como String (uso histórico) o dentro de un Map
      // (p. ej. la navegación desde una notificación de chat, que además pide
      // abrir la pestaña de Mensajes con `openChat`).
      String? explicitRole;
      bool openChat = false;
      if (args is String) {
        explicitRole = args;
      } else if (args is Map) {
        final r = args['role'];
        if (r is String) explicitRole = r;
        openChat = args['openChat'] == true;
      }

      if (explicitRole != null) {
        _userRole = explicitRole;
      } else {
        final providerRole = session.role;
        if (providerRole != null) {
          final raw = providerRole.toLowerCase();
          if (raw == 'doctor' || raw == 'doctor(a)') {
            _userRole = 'doctor';
          } else if (raw == 'recepcionista' || raw == 'receptionist') {
            _userRole = 'receptionist';
          } else {
            _userRole = 'patient';
          }
        }
      }

      // La pestaña de Mensajes vive en un índice distinto según el rol
      // (paciente 3, doctor 4, recepcionista 2). Si nos pidieron abrirla,
      // seleccionamos el índice correcto para el rol ya resuelto.
      if (openChat) {
        _currentTab = _chatTabIndex();
      }

      _isInitialized = true;
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    final session = context.read<SessionManager>();
    final dashboardProvider = context.read<DashboardProvider>();
    final appointmentsProvider = context.read<AppointmentsProvider>();
    final diariesProvider = context.read<PatientDiariesProvider>();

    if (_userRole == 'doctor') {
      final docId = session.doctorId;
      if (docId == null) {
        // Antes se hacía `return` en seco y la pantalla quedaba cargando para
        // siempre; ahora se muestra un error accionable.
        dashboardProvider.setSessionError(
          'Tu sesión no trae el identificador de doctor. Cierra sesión y vuelve a iniciar.',
        );
        return;
      }
      await dashboardProvider.loadDoctorDashboard(docId);
      if (!mounted) return;
      appointmentsProvider.loadAppointments(docId.toString(), isDoctor: true);
      // Se dispara sin await: la sección de Alertas Prioritarias se actualiza
      // sola (vía notifyListeners) en cuanto terminen las peticiones en paralelo.
      dashboardProvider.loadCriticalPatients(docId);
    } else if (_userRole == 'receptionist') {
      final recepId = session.receptionistId;
      if (recepId == null) return; // Sesión sin receptionistId: nada que cargar.
      await dashboardProvider.loadReceptionistDashboard(recepId);
    } else {
      final userId = session.userId;
      if (userId == null) {
        // Antes se hacía `return` en seco y la pantalla quedaba cargando para
        // siempre; ahora se muestra un error accionable.
        dashboardProvider.setSessionError(
          'Tu sesión no cargó correctamente (falta el identificador de usuario). '
          'Cierra sesión y vuelve a iniciar.',
        );
        return;
      }
      final patId = session.patientId ?? userId;
      await dashboardProvider.loadPatientDashboard(patId, userId, doctorId: session.doctorId);
      if (!mounted) return;
      appointmentsProvider.loadAppointments(patId.toString(), isDoctor: false);

      final medicalRecordId = dashboardProvider.medicalRecord?.medicalRecordId;
      if (medicalRecordId != null) {
        diariesProvider.loadDiaries(medicalRecordId);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Índice de la pestaña "Mensajes" en el footer según el rol. Debe seguir
  /// coincidiendo con el orden de los ítems en `_buildBottomNavBar` y con los
  /// `case` de `_buildBody`.
  int _chatTabIndex() {
    switch (_userRole) {
      case 'doctor':
        return 4;
      case 'receptionist':
        return 2;
      default: // patient
        return 3;
    }
  }

  // --- WIDGET BUILDERS ---

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );

    if (_userRole == 'doctor' || _userRole == 'receptionist') {
      // El footer de doctor/recepcionista (_buildBottomNavBar) es reactivo al
      // tema (AppColors.cardBackground). Igualamos aquí la barra de navegación
      // del sistema (Android, debajo del footer) a ese mismo color/tema
      // para que no haya un salto de color justo debajo del footer.
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          systemNavigationBarColor: AppColors.cardBackground,
          systemNavigationBarIconBrightness: AppColors.isDarkMode ? Brightness.light : Brightness.dark,
        ),
        child: scaffold,
      );
    }

    return scaffold;
  }

  /// Header de la pestaña de inicio, compartido por doctor y recepcionista:
  /// avatar con inicial + saludo + nombre sobre el color primario.
  PreferredSizeWidget _buildGreetingAppBar({
    required String greeting,
    required String name,
    required String initial,
  }) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.primary,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
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
                greeting,
                style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.normal),
              ),
              Text(
                name,
                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_outlined, size: 20, color: Colors.white),
          ),
          onPressed: () {},
        ),
        SizedBox(width: 12),
      ],
    );
  }

  /// True cuando el cuerpo de la pestaña actual es una página con su PROPIO
  /// Scaffold+AppBar (Citas, Foros, Mensajes, Directorio). En esos casos el
  /// scaffold externo NO debe poner un AppBar (devuelve null) para que el
  /// AppBar de la página hija se extienda hasta la barra de notificaciones,
  /// en vez de quedar debajo de una franja del status bar. Perfil (sin
  /// Scaffold propio) y los dashboards conservan el espaciado del AppBar.
  bool _bodyHasOwnAppBar() {
    if (_userRole == 'receptionist') {
      return _currentTab == 1 || _currentTab == 2 || _currentTab == 3;
    }
    if (_userRole == 'doctor') {
      return _currentTab == 2 || _currentTab == 3 || _currentTab == 4;
    }
    // paciente
    return _currentTab == 1 || _currentTab == 2 || _currentTab == 3;
  }

  PreferredSizeWidget? _buildAppBar() {
    final session = context.watch<SessionManager>();
    final String doctorName = session.name.isNotEmpty
        ? 'Dr(a). ${session.name}'
        : 'Médico';
    final String doctorInitial = session.name.isNotEmpty
        ? session.name[0].toUpperCase()
        : (session.email.isNotEmpty ? session.email[0].toUpperCase() : 'D');

    if (_userRole == 'receptionist') {
      if (_currentTab == 0) {
        final String receptionistName = session.name.isNotEmpty
            ? session.name
            : 'Recepcionista';
        final String receptionistInitial = session.name.isNotEmpty
            ? session.name[0].toUpperCase()
            : (session.email.isNotEmpty ? session.email[0].toUpperCase() : 'R');
        return _buildGreetingAppBar(
          greeting: 'Hola,',
          name: receptionistName,
          initial: receptionistInitial,
        );
      }
<<<<<<< HEAD
      // El resto de pestañas (Citas, Mensajes, Directorio, Perfil) traen su
      // propio AppBar, igual que en doctor/paciente. Para las que tienen
      // Scaffold propio, no ponemos AppBar externo (null) para que su header
      // llegue hasta el status bar; Perfil conserva el AppBar vacío como
      // espaciador.
      return _bodyHasOwnAppBar()
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: 0,
              elevation: 0,
            );
=======
      // El resto de pestañas (Citas, Mensajes, Perfil) traen su
      // propio AppBar, igual que en doctor/paciente.
      return AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        elevation: 0,
      );
>>>>>>> 35be42c62b0f90083a9191aa7a61d85a48b22b5d
    }

    if (_userRole == 'doctor') {
      if (_currentTab == 0) {
        // Doctor main dashboard header
        return _buildGreetingAppBar(
          greeting: 'Buenos días,',
          name: doctorName,
          initial: doctorInitial,
        );
      } else if (_currentTab == 1) {
        // "Mis Pacientes" header
        return AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.primary,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Text(
                  doctorInitial,
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              SizedBox(width: 10),
              const Text(
                'Salud Prenatal',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InvitationCodePage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
              onPressed: () {},
            ),
            SizedBox(width: 8),
          ],
        );
      }
    } else {
      // Patient dashboard header (renders directly in screen body to match styling)
    }
    // Pestañas con página de Scaffold propio (Citas, Foros, Mensajes): sin
    // AppBar externo para que su header se extienda hasta el status bar. El
    // resto (Perfil, dashboard del paciente) mantiene el AppBar espaciador.
    return _bodyHasOwnAppBar()
        ? null
        : AppBar(
            automaticallyImplyLeading: false,
            toolbarHeight: 0,
            elevation: 0,
          );
  }

  Widget _buildBody() {
    if (_userRole == 'receptionist') {
      switch (_currentTab) {
        case 0:
          return _buildReceptionistDashboard();
        case 1:
          return const AppointmentsPage();
        case 2:
          return const ChatListPage();
        case 3:
          return const ProfilePage();
        default:
          return _buildPlaceholderView('Módulo de recepción.');
      }
    }

    if (_userRole == 'doctor') {
      switch (_currentTab) {
        case 0:
          return _buildDoctorDashboard();
        case 1:
          return const PatientsListPage();
        case 2:
          return const AppointmentsPage();
        case 3:
          return const ForumsHubPage();
        case 4:
          return const ChatListPage();
        case 5:
          return const ProfilePage();
        default:
          return _buildPlaceholderView('Módulo de comunicación y perfil médico.');
      }
    } else {
      switch (_currentTab) {
        case 0:
          return _buildPatientDashboard();
        case 1:
          return const AppointmentsPage();
        case 2:
          return const ForumsHubPage();
        case 3:
          return const ChatListPage();
        case 4:
          return const ProfilePage();
        default:
          return _buildPlaceholderView('Módulo de salud prenatal.');
      }
    }
  }

  Widget _buildPlaceholderView(String description) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_outlined, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'En Construcción',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // --- RECEPTIONIST VIEWS ---

  /// Pestaña de inicio de la recepcionista. Vive dentro de [DashboardPage] y
  /// reutiliza los mismos componentes que el doctor (`_buildDoctorStatCard`,
  /// footer y header compartidos) en vez de una página aparte.
  Widget _buildReceptionistDashboard() {
    final dashboardProvider = context.watch<DashboardProvider>();
    switch (dashboardProvider.status) {
      case DashboardStatus.initial:
      case DashboardStatus.loading:
        return const _DashboardSkeleton();
      case DashboardStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(dashboardProvider.errorMessage ?? 'Error al cargar el dashboard'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboardData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      case DashboardStatus.success:
        break;
    }

    final totalCitas = dashboardProvider.receptionistUpcomingAppointments.length;
    final pending = dashboardProvider.receptionistPendingAppointments.length;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppColors.primary,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _buildDoctorStatCard('Citas Programadas', totalCitas.toString(), Icons.calendar_today_outlined, Colors.teal),
              SizedBox(width: 12),
              _buildDoctorStatCard('Citas Pendientes', pending.toString(), Icons.pending_actions_outlined, Colors.orange),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Acciones Rápidas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          _buildReceptionistActionCard('Nueva Cita', Icons.add_circle, Colors.green, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AppointmentFormPage()),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
      ),
    );
  }

  Widget _buildReceptionistActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
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

  // --- DOCTOR VIEWS ---

  Widget _buildDoctorDashboard() {
    final dashboardProvider = context.watch<DashboardProvider>();
    switch (dashboardProvider.status) {
      case DashboardStatus.initial:
      case DashboardStatus.loading:
        return const _DashboardSkeleton();
      case DashboardStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(dashboardProvider.errorMessage ?? 'Error al cargar el dashboard'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboardData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      case DashboardStatus.success:
        break;
    }
    final docDb = dashboardProvider.doctorDashboardData;
    final List<dynamic> receptionists = (docDb?['receptionists'] as List?) ?? const [];
    final citasHoyStr = docDb?['today_appointments_count']?.toString() ?? '0';
    final List<dynamic> todayAppointmentsRaw = docDb?['today_appointments'] ?? [];

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppColors.primary,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildReceptionistInfoCard(receptionists),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDoctorStatCard('Citas Hoy', citasHoyStr, Icons.calendar_today_outlined, Colors.teal),
            ],
          ),
          const SizedBox(height: 24),

          // Próximas Citas Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Próximas Citas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
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
          SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: todayAppointmentsRaw.isEmpty
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        'No hay citas programadas para hoy.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(todayAppointmentsRaw.length, (index) {
                      final app = todayAppointmentsRaw[index];
                      final String patientName = app['patient_name'] ?? 'Paciente';
                      final String reason = app['reason'] ?? 'Consulta general';
                      final String status = app['status'] ?? 'pending';
                      final String timeRaw = app['appointment_time'] ?? '';
                      final int? appointmentId = app['appointment_id'] as int?;
                      final int? patientId = app['patient_id'] as int?;

                      DateTime parsedDateTime = DateTime.now();
                      String timeStr = 'Hora no esp.';
                      if (timeRaw.isNotEmpty) {
                        try {
                          final dt = DateTime.parse(timeRaw).toLocal();
                          parsedDateTime = dt;
                          final isPm = dt.hour >= 12;
                          final hour = dt.hour == 0
                              ? 12
                              : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
                          timeStr = '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${isPm ? 'PM' : 'AM'}';
                        } catch (_) {}
                      }

                      return Column(
                        children: [
                          _buildDoctorAppointmentItem(
                            timeStr,
                            patientName,
                            reason,
                            reason.toLowerCase().contains('urgente') || status == 'cancelled',
                            onTap: (appointmentId == null || patientId == null)
                                ? null
                                : () => _openDoctorAppointmentDetail(
                                      appointmentId: appointmentId,
                                      patientId: patientId,
                                      patientName: patientName,
                                      reason: reason,
                                      status: status,
                                      dateTime: parsedDateTime,
                                    ),
                          ),
                          if (index != todayAppointmentsRaw.length - 1)
                            Divider(height: 1, color: AppColors.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
                        ],
                      );
                    }),
                  ),
          ),
          const SizedBox(height: 20),
          _buildNewConsultationCard(),
          const SizedBox(height: 20),
        ],
      ),
      ),
    );
  }

  Widget _buildNewConsultationCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: Icon(Icons.note_add_outlined, color: AppColors.primary),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registrar consulta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                SizedBox(height: 2),
                Text(
                  'Elige una paciente y añade una nueva consulta',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: _openPatientPickerForConsultation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Nueva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Modal que carga a los pacientes del doctor (mismo patrón que el
  /// selector de "Nueva Cita") para elegir a quién registrarle una consulta
  /// desde el dashboard, sin tener que entrar primero a su expediente.
  Future<void> _openPatientPickerForConsultation() async {
    final session = context.read<SessionManager>();
    final doctorId = session.doctorId;
    if (doctorId == null) return;

    final dashboardProvider = context.read<DashboardProvider>();
    if (dashboardProvider.patients.isEmpty) {
      await dashboardProvider.loadDoctorPatients(doctorId);
    }
    if (!mounted) return;

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Consumer<DashboardProvider>(
          builder: (context, provider, _) {
            final patients = provider.patients;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecciona una paciente',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),
                    if (patients.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text('No hay pacientes registradas.', style: TextStyle(color: AppColors.textMuted)),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: patients.length,
                          itemBuilder: (itemContext, index) {
                            final patient = patients[index];
                            final pId = patient['patient_id'] as int;
                            final user = provider.users.firstWhere(
                              (u) => u.userId == patient['user_id'],
                              orElse: () => UserProfile(name: 'Paciente', lastName: '$pId', email: '', role: 'paciente'),
                            );
                            final fullName = '${user.name} ${user.lastName}'.trim();
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  fullName.isNotEmpty ? fullName[0].toUpperCase() : 'P',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(fullName, style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
                              subtitle: Text('#SP-$pId', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              onTap: () => Navigator.pop(sheetContext, {'patientId': pId, 'name': fullName}),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected == null || !mounted) return;

    final patientId = selected['patientId'] as int;
    final patientName = selected['name'] as String;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    await dashboardProvider.loadPatientDetails(patientId, doctorId: doctorId);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final record = dashboardProvider.activeMedicalRecord;
    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta paciente aún no tiene expediente médico. Créalo primero desde su detalle.')),
      );
      return;
    }
    if (!mounted) return;
    await showNewConsultationDialog(context, medicalRecordId: record.medicalRecordId, patientName: patientName);
  }

  /// Tarjeta con los datos de la recepcionista asignada al doctor (nombre y
  /// correo), en lugar de un simple conteo. Muestra la primera; si hay más de
  /// una, lo indica con "(+N más)". Si no hay ninguna, invita a crear una.
  Widget _buildReceptionistInfoCard(List<dynamic> receptionists) {
    final bool has = receptionists.isNotEmpty;
    final Map<String, dynamic>? r =
        has ? Map<String, dynamic>.from(receptionists.first as Map) : null;
    final String name = r == null
        ? ''
        : '${r['name'] ?? ''} ${r['last_name'] ?? ''}'.trim();
    final String email = r?['email']?.toString() ?? '';
    final String initials = name.isNotEmpty ? name[0].toUpperCase() : 'R';
    final String extra =
        receptionists.length > 1 ? ' (+${receptionists.length - 1} más)' : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primaryLight,
            child: has
                ? Text(
                    initials,
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                  )
                : Icon(Icons.support_agent_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.support_agent_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Mi Recepcionista$extra',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  has ? name : 'Aún no tienes recepcionista asignada',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (has && email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          email,
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
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
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(String name, String alert, String initials, {VoidCallback? onDetailPressed}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: AppColors.isDarkMode ? const Color(0xFF3A1F1F) : const Color(0xFFFFEBEA),
            radius: 20,
            child: Text(
              initials,
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                ),
                SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 14),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        alert,
                        style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: onDetailPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Detalle',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Antes el chevron de "Próximas Citas" (dashboard del doctor) no hacía
  /// nada (`onPressed: () {}`), a diferencia de la recepcionista, que sí
  /// puede entrar al detalle desde su lista. El dashboard del doctor solo
  /// trae datos crudos (Map) de `today_appointments`, así que reconstruimos
  /// aquí un `Appointment` con esos campos para navegar al mismo
  /// `AppointmentDetailPage` que usa la recepcionista.
  void _openDoctorAppointmentDetail({
    required int appointmentId,
    required int patientId,
    required String patientName,
    required String reason,
    required String status,
    required DateTime dateTime,
  }) async {
    final session = context.read<SessionManager>();
    final doctorId = session.doctorId;
    if (doctorId == null) return;
    final doctorFullName = '${session.name} ${session.lastName}'.trim();

    final appointment = Appointment(
      id: appointmentId,
      doctorId: doctorId,
      patientId: patientId,
      doctorName: doctorFullName,
      patientName: patientName,
      dateTime: dateTime,
      status: AppointmentStatusExtension.fromString(status),
      reason: reason,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AppointmentDetailPage(appointment: appointment)),
    );
    if (mounted) {
      _loadDashboardData();
    }
  }

  Widget _buildDoctorAppointmentItem(String time, String name, String subtitle, bool isUrgent, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        color: AppColors.cardBackground,
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time.split(' ')[0],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  Text(
                    time.split(' ')[1],
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 30,
              color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.pink.shade50,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                  ),
                  SizedBox(height: 2),
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
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  // --- OLD METHODS REMOVED ---

  // --- PATIENT VIEWS ---

  Widget _buildPatientDashboard() {
    final dashboardProvider = context.watch<DashboardProvider>();
    switch (dashboardProvider.status) {
      case DashboardStatus.initial:
      case DashboardStatus.loading:
        return const _DashboardSkeleton();
      case DashboardStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(dashboardProvider.errorMessage ?? 'Error al cargar el dashboard'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboardData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      case DashboardStatus.success:
        break;
    }
    final session = context.watch<SessionManager>();
    final appointmentsProvider = context.watch<AppointmentsProvider>();
    final diariesProvider = context.watch<PatientDiariesProvider>();

    final String displayName = session.fullName.isNotEmpty
        ? session.fullName
        : 'Paciente';

    final rawWeeks = dashboardProvider.currentPatientData?['current_gestational_weeks'];
    final String weeksText = rawWeeks != null ? 'Semana $rawWeeks de embarazo' : 'Embarazo en curso';

    final medicalRecord = dashboardProvider.medicalRecord;
    String patientRisk = 'Bajo';

    if (medicalRecord != null) {
      final riskPrediction = medicalRecord.riskPrediction;
      String? clusterName;
      if (riskPrediction != null && riskPrediction.isOk) {
        clusterName = riskPrediction.diagnosis;
      }
      if (clusterName != null && clusterName.isNotEmpty) {
        final diagnosis = clusterName.toLowerCase();
        if (diagnosis.contains('alto') || diagnosis.contains('crítico') || diagnosis.contains('critico')) {
          patientRisk = 'Alto';
        } else if (diagnosis.contains('medio') || diagnosis.contains('moderado')) {
          patientRisk = 'Medio';
        } else {
          patientRisk = 'Bajo';
        }
      } else {
        if (medicalRecord.previousPreeclampsia || 
            medicalRecord.chronicHypertension || 
            medicalRecord.previousHypertension) {
          patientRisk = 'Alto';
        } else if (medicalRecord.diabetes || 
                   medicalRecord.familyHistoryHypertension) {
          patientRisk = 'Medio';
        }
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

    if (dashboardProvider.dashboardData?['current_doctor'] != null) {
      docNameStr = dashboardProvider.dashboardData!['current_doctor'];
      docSpecialtyStr = dashboardProvider.dashboardData?['current_doctor_specialty'] ?? docSpecialtyStr;
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

    // Find current week's start (Monday) and end (Sunday)
    final now = DateTime.now();
    final currentDay = now.weekday; // 1 = Monday, 7 = Sunday
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: currentDay - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    
    // Array of booleans to track if a measurement was made each day (index 0 = Monday, 6 = Sunday)
    final weekMeasurements = List.filled(7, false);
    
    for (var diary in diariesProvider.diaries) {
      if (diary.createdAt.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && 
          diary.createdAt.isBefore(endOfWeek.add(const Duration(seconds: 1)))) {
        final dayIndex = diary.createdAt.weekday - 1;
        weekMeasurements[dayIndex] = true;
      }
    }
    
    final trackingCirclesList = <Widget>[];
    for (var i = 0; i < 7; i++) {
      final isActive = weekMeasurements[i];
      final isFuture = i > (currentDay - 1);
      
      trackingCirclesList.add(
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppColors.primary
                      : (isFuture
                          ? (AppColors.isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade200)
                          : AppColors.primaryLight),
                ),
                child: isActive
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : (isFuture ? null : const Icon(Icons.close, color: Color(0xFFFF85C0), size: 18)),
              ),
              const SizedBox(height: 8),
              Text(
                daysOfWeek[i],
                style: TextStyle(
                  color: (i == currentDay - 1) ? AppColors.primary : AppColors.textMuted,
                  fontWeight: (i == currentDay - 1) ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppColors.primary,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(20.0),
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
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '👋',
                        style: TextStyle(fontSize: 22),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                   Text(
                    weeksText,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          SizedBox(height: 28),

          // Banner de vinculación si no tiene doctor
          if (dashboardProvider.dashboardData?['current_doctor'] == null)
            Container(
              margin: EdgeInsets.only(bottom: 24),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.isDarkMode ? const Color(0xFF5C2E42) : Colors.pink.shade100, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.medical_services_outlined, color: AppColors.primary),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aún no tienes un médico',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 15),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Vincúlate usando el código de invitación.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const InvitationCodePage()),
                      );
                      if (result == true && mounted) {
                        final session = context.read<SessionManager>();
                        final patientId = session.patientId;
                        final userId = session.userId;
                        if (patientId != null && userId != null) {
                          context.read<DashboardProvider>().loadPatientDashboard(patientId, userId);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('Vincular', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // MI ESTADO DE HOY Section
          Text(
            'MI ESTADO DE HOY',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
          ),
          SizedBox(height: 12),

          Builder(
            builder: (context) {
              final medicalRecordId = session.medicalRecordId ?? dashboardProvider.medicalRecord?.medicalRecordId;
              
              if (medicalRecordId == null || medicalRecordId <= 0) {
                return Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.folder_off_outlined, color: Colors.red.shade400, size: 32),
                      SizedBox(height: 12),
                      Text(
                        'Tu médico no te ha creado un expediente aún',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
                      ),
                      if (session.doctorId == null) ...[
                        SizedBox(height: 4),
                        Text(
                          'Aún no estás vinculado a un médico.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (diariesProvider.isLoading)
                    Center(child: CircularProgressIndicator(color: AppColors.primary))
                  else if (diariesProvider.diaries.isNotEmpty)
                    LatestDiaryRecordCard(
                      systolic: diariesProvider.diaries.first.systolic,
                      diastolic: diariesProvider.diaries.first.diastolic,
                      weightKg: diariesProvider.diaries.first.weightKg,
                    )
                  else
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                      ),
                      child: Text(
                        'Aún no tienes registros en tu bitácora.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/patient-diaries');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: Icon(Icons.add_circle_outline, color: Colors.white),
                    label: Text(
                      'Registrar medición',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 28),

          // MI PRÓXIMA CITA Section
          Text(
            'MI PRÓXIMA CITA',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
          ),
          SizedBox(height: 12),

          // Magenta Card
          Container(
            padding: EdgeInsets.all(20),
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
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeStr,
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            reasonStr,
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Text(
                        docNameStr.isNotEmpty
                            ? docNameStr.replaceAll(RegExp(r'^(Dr\.|Dra\.)\s*', caseSensitive: false), '')[0].toUpperCase()
                            : 'D',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            docNameStr,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
                SizedBox(height: 20),
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
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Ver detalles', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // El backend no da el user_id del doctor asignado
                          // directamente; se empareja su nombre contra la lista de
                          // usuarios ya cargada. Si no hay coincidencia, no se
                          // navega con un ID inventado.
                          UserProfile? matchedDoc;
                          final normalized = docNameStr.trim().toLowerCase();
                          final doctors = dashboardProvider.users.where((u) => u.role.toLowerCase().contains('doctor'));
                          for (final doc in doctors) {
                            final fullName = '${doc.name} ${doc.lastName}'.trim().toLowerCase();
                            if (fullName.isNotEmpty && fullName == normalized) {
                              matchedDoc = doc;
                              break;
                            }
                          }
                          if (matchedDoc == null) {
                            for (final doc in doctors) {
                              if (doc.name.isNotEmpty && normalized.contains(doc.name.toLowerCase())) {
                                matchedDoc = doc;
                                break;
                              }
                            }
                          }
                          final docUserId = matchedDoc?.userId;
                          if (docUserId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No se pudo identificar a tu médico.')),
                            );
                            return;
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
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
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
          SizedBox(height: 28),

          // SEGUIMIENTO SEMANAL Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SEGUIMIENTO SEMANAL',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: Text(
                  'Presión Sistólica',
                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Weekly chart card mockup
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: trackingCirclesList,
                ),
                SizedBox(height: 16),
                Text(
                  patientRisk == 'Alto'
                      ? 'Atención: Tu presión muestra variaciones. Reporta cualquier malestar de inmediato.'
                      : 'Tu presión se mantiene estable dentro de los rangos normales.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
      ),
    );
  }

  Widget _buildBar(double heightPercentage, bool isActive) {
    return Container(
      width: 8,
      height: heightPercentage,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : (AppColors.isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade200),
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
    // Leer del tema (no de `AppColors`) hace que este widget dependa del tema y
    // se reconstruya solo cuando el SO cambia claro/oscuro. `primary` es
    // constante entre variantes, por eso se deja como `AppColors.primary`.
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExt>()!;
    if (_userRole == 'receptionist') {
      // Mismo componente y estilo que el footer del doctor; solo cambian los
      // ítems (sin Pacientes ni Foros).
      return BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: colors.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        backgroundColor: theme.colorScheme.surface,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Inicio',
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
    }
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
        unselectedItemColor: colors.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        backgroundColor: theme.colorScheme.surface,
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
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: 'Foros',
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
      // Bottom nav bar for Patient role (has a central circular button that
      // opens the "Bitácora" / patient diary)
      return BottomAppBar(
        color: theme.colorScheme.surface,
        elevation: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPatientTabItem(0, Icons.home_outlined, Icons.home, 'Inicio'),
            _buildPatientTabItem(1, Icons.calendar_today_outlined, Icons.calendar_today, 'Citas'),
            _buildPatientTabItem(2, Icons.forum_outlined, Icons.forum, 'Foros'),
            // Bitácora: se muestra como un ítem más del nav (mismo estilo que el
            // resto) en lugar de un botón circular flotante. Abre otra ruta, así
            // que no participa del estado seleccionado (`_currentTab`).
            _buildPatientNavAction(
              Icons.menu_book_outlined,
              'Bitácora',
              () => Navigator.pushNamed(context, '/patient-diaries'),
            ),
            _buildPatientTabItem(3, Icons.message_outlined, Icons.message, 'Mensajes'),
            _buildPatientTabItem(4, Icons.person_outline, Icons.person, 'Perfil'),
          ],
        ),
      );
    }
  }

  Widget _buildPatientTabItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _currentTab == index;
    final colors = Theme.of(context).extension<AppColorsExt>()!;
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
            color: isSelected ? AppColors.primary : colors.textMuted,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : colors.textMuted,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Ítem del nav de paciente que dispara una acción (ej. abrir la Bitácora en
  /// otra ruta) en vez de cambiar de pestaña. Usa exactamente el mismo layout
  /// e estilo "no seleccionado" que `_buildPatientTabItem` para que se vea igual
  /// que el resto de los botones.
  Widget _buildPatientNavAction(IconData outlineIcon, String label, VoidCallback onTap) {
    final colors = Theme.of(context).extension<AppColorsExt>()!;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(outlineIcon, color: colors.textMuted, size: 24),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskPredictionBanner(RiskPrediction prediction) {
    final clusterName = prediction.diagnosis ?? 'Riesgo indeterminado';
    final lower = clusterName.toLowerCase();
    final isHigh = lower.contains('alto') || lower.contains('crítico') || lower.contains('critico');
    final isMedium = lower.contains('medio') || lower.contains('moderado');

    final Color bgColor = isHigh
        ? AppColors.riskHighBg
        : (isMedium ? AppColors.riskMediumBg : AppColors.riskLowBg);
    final Color textColor = isHigh
        ? AppColors.riskHighText
        : (isMedium ? AppColors.riskMediumText : AppColors.riskLowText);
    final Color iconColor = isHigh
        ? Colors.red
        : (isMedium ? Colors.orange : Colors.teal);
    final IconData icon = isHigh
        ? Icons.warning_amber_rounded
        : (isMedium ? Icons.info_outline : Icons.check_circle_outline);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Predicción de Riesgo IA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 6),
                    if (prediction.riskCluster != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'C${prediction.riskCluster}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  clusterName,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton de carga de los dashboards (doctor/recepcionista/paciente): imita
/// el layout general (dos tarjetas superiores, un título y varias filas) con
/// un pulso suave, en vez de un spinner. Se muestra tanto en la carga inicial
/// como al hacer pull-to-refresh.
class _DashboardSkeleton extends StatefulWidget {
  const _DashboardSkeleton();

  @override
  State<_DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<_DashboardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _block({double? width, double height = 16, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.skeletonBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _card(double height) {
    return Expanded(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.skeletonBase,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_controller),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _card(88),
                const SizedBox(width: 12),
                _card(88),
              ],
            ),
            const SizedBox(height: 24),
            _block(width: 160, height: 18),
            const SizedBox(height: 16),
            for (var i = 0; i < 3; i++) ...[
              Container(
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.skeletonBase,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
