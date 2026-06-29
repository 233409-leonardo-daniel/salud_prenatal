import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/patients_list_provider.dart';
import 'patient_state.dart';
import '../../domain/entities/patient.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../../../dashboard/presentation/pages/patient_progress_page.dart';
import '../../../dashboard/presentation/pages/patient_record_page.dart';

class PatientsListPage extends StatefulWidget {
  const PatientsListPage({super.key});

  @override
  State<PatientsListPage> createState() => _PatientsListPageState();
}

class _PatientsListPageState extends State<PatientsListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'Todas';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loginProvider = context.read<LoginProvider>();
      final doctorId = loginProvider.doctorId?.toString() ?? '1';
      context.read<PatientsListProvider>().loadPatients(doctorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final patientsProvider = context.watch<PatientsListProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();

    switch (patientsProvider.status) {
      case PatientsListStatus.initial:
      case PatientsListStatus.loading:
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      case PatientsListStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(patientsProvider.error ?? 'Error', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final doctorId = context.read<LoginProvider>().doctorId?.toString() ?? '1';
                  context.read<PatientsListProvider>().loadPatients(doctorId);
                },
                child: const Text('Reintentar'),
              )
            ],
          ),
        );
      case PatientsListStatus.success:
        break;
    }

    final totalPatientsStr = patientsProvider.patients.length.toString();
    final patientCards = <Widget>[];

    // Map and sort patients by risk
    // Risk definition: High (0), Medium (1), Low (2)
    int getRiskLevel(int pId) {
      if (pId % 3 == 0) return 0; // Alto
      if (pId % 3 == 1) return 1; // Medio
      return 2; // Bajo
    }

    final sortedPatients = List<PatientEntity>.from(patientsProvider.patients);
    sortedPatients.sort((a, b) => getRiskLevel(a.patientId).compareTo(getRiskLevel(b.patientId)));

    for (final patient in sortedPatients) {
      final pId = patient.patientId;
      final userId = patient.userId;
      
      final patientUser = dashboardProvider.users.firstWhere(
        (u) => u.userId == userId,
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

      if (getRiskLevel(pId) == 0) {
        risk = 'Alto Riesgo';
        riskBg = AppColors.riskHighBg;
        riskText = AppColors.riskHighText;
        imgBg = const Color(0xFFFFF0F6);
      } else if (getRiskLevel(pId) == 1) {
        risk = 'Medio Riesgo';
        riskBg = AppColors.riskMediumBg;
        riskText = AppColors.riskMediumText;
        imgBg = const Color(0xFFFFF4E5);
      }

      final card = _buildPatientListCard(
        name: patientName,
        id: '#SP-$pId',
        userId: userId,
        patientEntity: patient,
        risk: risk,
        riskColorBg: riskBg,
        riskColorText: riskText,
        gestationAge: '${patient.currentGestationalWeeks ?? 28} sem',
        status: 'Estable',
        statusIcon: Icons.check_circle_outline,
        statusIconColor: Colors.teal,
        avatarInitials: initials,
        imageBackground: imgBg,
      );

      if (card is! SizedBox) {
        patientCards.add(card);
        patientCards.add(const SizedBox(height: 12));
      }
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
              setState(() {});
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
    required int userId,
    required PatientEntity patientEntity,
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
                  child: const Text('Ver Detalle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
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
}
