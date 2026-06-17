import 'package:flutter/material.dart';
import '../../../../theme/theme.dart';

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
                    'Dra. Mendoza',
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
    if (_userRole == 'doctor') {
      switch (_currentTab) {
        case 0:
          return _buildDoctorDashboard();
        case 1:
          return _buildDoctorPatientsList();
        default:
          return _buildPlaceholderView('Módulo de comunicación y perfil médico.');
      }
    } else {
      switch (_currentTab) {
        case 0:
          return _buildPatientDashboard();
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 4 Stats Grid Cards
          Row(
            children: [
              _buildDoctorStatCard('Total Pacientes', '24', Icons.people_outline, Colors.pink),
              const SizedBox(width: 12),
              _buildDoctorStatCard('Citas Hoy', '5', Icons.calendar_today_outlined, Colors.teal),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDoctorStatCard('Seguimiento', '8', Icons.trending_up, Colors.indigo),
              const SizedBox(width: 12),
              // Alertas card has a red warning border in mockup
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.shade400, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
                      const SizedBox(height: 12),
                      const Text(
                        'Alertas Riesgo',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '2',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

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

          // Alertas cards with left red line decoration
          _buildAlertCard('Mariana Villanueva', 'Riesgo de Preeclampsia', 'MV'),
          const SizedBox(height: 12),
          _buildAlertCard('Lucía Rojas', 'Taquicardia Fetal', 'LR'),
          const SizedBox(height: 24),

          // Resumen IA Card (Pink background card)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F6), // Soft pink background
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.pink.shade50),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology_outlined, color: AppColors.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Resumen IA',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.pink.shade100),
                      ),
                      child: const Text(
                        'GENERADO POR IA',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '"La tendencia de presión arterial en las últimas 48h para las pacientes de alto riesgo muestra una leve mejoría. Se recomienda priorizar la revisión de laboratorio de Mariana Villanueva agendada para las 10:30 AM."',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textDark,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

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

          // Doctor Appointments List
          _buildDoctorAppointmentItem('09 AM', 'Elena Gómez', 'Control Prenatal - Sem 24', false),
          const Divider(height: 1, color: Color(0xFFE5E5EA)),
          _buildDoctorAppointmentItem('10 AM', 'Mariana Villanueva', 'Urgente: Revisión Labs', true),
          const Divider(height: 1, color: Color(0xFFE5E5EA)),
          _buildDoctorAppointmentItem('11 AM', 'Sofia Méndez', 'Ecografía Doppler', false),
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
                child: const Text(
                  '24',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
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

          // Patients list matching wireframe
          _buildPatientListCard(
            name: 'Mariana Villanueva',
            id: '#SP-20485',
            risk: 'Alto Riesgo',
            riskColorBg: AppColors.riskHighBg,
            riskColorText: AppColors.riskHighText,
            gestationAge: '32 sem + 4 días',
            status: 'Estable',
            statusIcon: Icons.check_circle_outline,
            statusIconColor: Colors.teal,
            avatarInitials: 'MV',
            imageBackground: const Color(0xFFFFF0F6),
          ),
          const SizedBox(height: 12),
          _buildPatientListCard(
            name: 'Lucía Castillo',
            id: '#SP-19322',
            risk: 'Medio Riesgo',
            riskColorBg: AppColors.riskMediumBg,
            riskColorText: AppColors.riskMediumText,
            gestationAge: '28 sem + 2 días',
            status: 'Pendiente',
            statusIcon: Icons.access_time_outlined,
            statusIconColor: Colors.orange,
            avatarInitials: 'LC',
            imageBackground: const Color(0xFFFFF4E5),
          ),
          const SizedBox(height: 12),
          _buildPatientListCard(
            name: 'Elena López',
            id: '#SP-21004',
            risk: 'Bajo Riesgo',
            riskColorBg: AppColors.riskLowBg,
            riskColorText: AppColors.riskLowText,
            gestationAge: '14 sem',
            status: 'Estable',
            statusIcon: Icons.check_circle_outline,
            statusIconColor: Colors.teal,
            avatarInitials: 'EL',
            imageBackground: const Color(0xFFE0F2F1),
          ),
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
                  onPressed: () {},
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
                  onPressed: () {},
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header inside body
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Hola, Ana García',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '👋',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Semana 28 de embarazo',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
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

          // Riesgo estimado card with circle success indicator
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
                      'Bajo',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                    ),
                  ],
                ),
                // Circular success indicator
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: 0.85,
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade400),
                        backgroundColor: Colors.teal.shade50,
                      ),
                    ),
                    Icon(Icons.check, color: Colors.teal.shade700, size: 24),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stats row (Pressure & Weight)
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
                          Icon(Icons.favorite_outline, color: AppColors.primary, size: 20),
                          const Icon(Icons.show_chart, color: Colors.green, size: 16),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Presión', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      const Text('120/80', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
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
                          Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
                          const Icon(Icons.horizontal_rule, color: AppColors.textMuted, size: 16),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Peso actual', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      const Text('68.4', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const Text('KILOGRAMOS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Registrar medicion button
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

          // Magenta Card for Next Appointment
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
                    // Date Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'JUN',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            '18',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '10:00 AM',
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Control prenatal',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Doctor info
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
                          const Text(
                            'Dra. Lucía Mendoza',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
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
                // Simulating a chart background space
                Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    // Simple chart graphics spacer
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar(15, false),
                      _buildBar(35, false),
                      _buildBar(25, false),
                      _buildBar(45, false),
                      _buildBar(75, true), // Active day (Friday in red/pink)
                      _buildBar(30, false),
                      _buildBar(20, false),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDayLabel('L', false),
                    _buildDayLabel('M', false),
                    _buildDayLabel('M', false),
                    _buildDayLabel('J', false),
                    _buildDayLabel('V', true),
                    _buildDayLabel('S', false),
                    _buildDayLabel('D', false),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Tu presión se mantiene estable dentro de los rangos normales.',
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
                        '"Es normal sentir más cansancio en la semana 28. Recuerda hidratarte bien y..."',
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
