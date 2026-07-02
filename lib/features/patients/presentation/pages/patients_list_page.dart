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
  int _currentPage = 1;
  static const int _pageSize = 5;

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
        return Center(child: CircularProgressIndicator(color: AppColors.primary));
      case PatientsListStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(patientsProvider.error ?? 'Error', style: TextStyle(color: Colors.red)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final doctorId = context.read<LoginProvider>().doctorId?.toString() ?? '1';
                  context.read<PatientsListProvider>().loadPatients(doctorId);
                },
                child: Text('Reintentar'),
              )
            ],
          ),
        );
      case PatientsListStatus.success:
        break;
    }

    final totalPatientsStr = patientsProvider.patients.length.toString();

    // Map and sort patients by risk
    // Risk definition: High (0), Medium (1), Low (2)
    int getRiskLevel(int pId) {
      if (pId % 3 == 0) return 0; // Alto
      if (pId % 3 == 1) return 1; // Medio
      return 2; // Bajo
    }

    final sortedPatients = List<PatientEntity>.from(patientsProvider.patients);
    sortedPatients.sort((a, b) => getRiskLevel(a.patientId).compareTo(getRiskLevel(b.patientId)));

    // Build the view-model list and apply search/risk filters BEFORE paginating,
    // so pagination always reflects the actually visible set of patients.
    final searchQuery = _searchController.text.trim().toLowerCase();
    final filteredPatients = <Map<String, dynamic>>[];

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
      final patientCode = '#SP-$pId';
      final initials = '${patientUser.name.isNotEmpty ? patientUser.name[0] : 'P'}${patientUser.lastName.isNotEmpty ? patientUser.lastName[0] : ''}';

      String risk = 'Bajo Riesgo';
      Color riskBg = AppColors.riskLowBg;
      Color riskText = AppColors.riskLowText;
      Color imgBg = AppColors.riskLowBg;

      if (getRiskLevel(pId) == 0) {
        risk = 'Alto Riesgo';
        riskBg = AppColors.riskHighBg;
        riskText = AppColors.riskHighText;
        imgBg = AppColors.riskHighBg;
      } else if (getRiskLevel(pId) == 1) {
        risk = 'Medio Riesgo';
        riskBg = AppColors.riskMediumBg;
        riskText = AppColors.riskMediumText;
        imgBg = AppColors.riskMediumBg;
      }

      if (searchQuery.isNotEmpty &&
          !patientName.toLowerCase().contains(searchQuery) &&
          !patientCode.toLowerCase().contains(searchQuery)) {
        continue;
      }

      if (_activeFilter != 'Todas') {
        if (_activeFilter == 'Riesgo Alto' && risk != 'Alto Riesgo') continue;
        if (_activeFilter == 'Riesgo Medio' && risk != 'Medio Riesgo') continue;
        if (_activeFilter == 'Riesgo Bajo' && risk != 'Bajo Riesgo') continue;
      }

      filteredPatients.add({
        'name': patientName,
        'id': patientCode,
        'userId': userId,
        'patientEntity': patient,
        'risk': risk,
        'riskBg': riskBg,
        'riskText': riskText,
        'gestationAge': '${patient.currentGestationalWeeks ?? 28} sem',
        'initials': initials,
        'imgBg': imgBg,
      });
    }

    // Pagination: 5 patients per page.
    final totalFiltered = filteredPatients.length;
    final totalPages = totalFiltered == 0 ? 1 : (totalFiltered / _pageSize).ceil();
    var effectivePage = _currentPage;
    if (effectivePage > totalPages) effectivePage = totalPages;
    if (effectivePage < 1) effectivePage = 1;
    _currentPage = effectivePage;

    final startIndex = (effectivePage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize) > totalFiltered ? totalFiltered : (startIndex + _pageSize);
    final pageItems = totalFiltered == 0
        ? <Map<String, dynamic>>[]
        : filteredPatients.sublist(startIndex, endIndex);

    final patientCards = <Widget>[];
    for (final item in pageItems) {
      patientCards.add(
        _buildPatientListCard(
          name: item['name'] as String,
          id: item['id'] as String,
          userId: item['userId'] as int,
          patientEntity: item['patientEntity'] as PatientEntity,
          risk: item['risk'] as String,
          riskColorBg: item['riskBg'] as Color,
          riskColorText: item['riskText'] as Color,
          gestationAge: item['gestationAge'] as String,
          status: 'Estable',
          statusIcon: Icons.check_circle_outline,
          statusIconColor: Colors.teal,
          avatarInitials: item['initials'] as String,
          imageBackground: item['imgBg'] as Color,
        ),
      );
      patientCards.add(SizedBox(height: 12));
    }

    if (patientCards.isEmpty) {
      patientCards.add(
        Padding(
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
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mis Pacientes',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Gestión activa de cuidados prenatales.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  totalPatientsStr,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Search patient bar
          TextField(
            style: TextStyle(color: AppColors.textDark),
            controller: _searchController,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.cardBackground,
              hintText: 'Buscar paciente por nombre o ID...',
              hintStyle: TextStyle(color: AppColors.textMuted),
              prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.transparent : Colors.pink.shade50),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.transparent : Colors.pink.shade50),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              setState(() {
                _currentPage = 1;
              });
            },
          ),
          SizedBox(height: 16),

          // Scrollable Filter Tags
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todas'),
                SizedBox(width: 8),
                _buildFilterChip('Riesgo Alto'),
                SizedBox(width: 8),
                _buildFilterChip('Riesgo Medio'),
                SizedBox(width: 8),
                _buildFilterChip('Riesgo Bajo'),
              ],
            ),
          ),
          SizedBox(height: 16),

          ...patientCards,
          SizedBox(height: 24),

          // Pagination indicators (5 pacientes por página)
          if (totalFiltered > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: effectivePage > 1
                        ? AppColors.textMuted
                        : (AppColors.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
                  ),
                  onPressed: effectivePage > 1
                      ? () => setState(() => _currentPage = effectivePage - 1)
                      : null,
                ),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var page = 1; page <= totalPages; page++)
                          _buildPageDot(page, page == effectivePage),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: effectivePage < totalPages
                        ? AppColors.textMuted
                        : (AppColors.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
                  ),
                  onPressed: effectivePage < totalPages
                      ? () => setState(() => _currentPage = effectivePage + 1)
                      : null,
                ),
              ],
            ),
          SizedBox(height: 40),
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
          _currentPage = 1;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (AppColors.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFEFEFF4)),
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
    // El filtrado por búsqueda y riesgo ya se aplica antes de paginar en build().
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: imageBackground,
                radius: 24,
                child: Text(
                  avatarInitials,
                  style: TextStyle(color: riskColorText, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: riskColorBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            risk,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: riskColorText, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ID: $id',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Edad Gestacional', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      SizedBox(height: 2),
                      Text(gestationAge, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estado Actual', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusIconColor),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              status,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
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
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text('Ver Detalle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                      color: AppColors.isDarkMode ? Colors.transparent : Colors.grey.shade300,
                      width: 1,
                    ),
                    backgroundColor: AppColors.isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                    disabledForegroundColor: AppColors.isDarkMode ? AppColors.textMuted : Colors.grey,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.trending_up, size: 16, color: AppColors.isDarkMode ? AppColors.textMuted : Colors.grey),
                      SizedBox(width: 6),
                      Text(
                        'Progreso',
                        style: TextStyle(
                          color: AppColors.isDarkMode ? AppColors.textMuted : Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() => _currentPage = pageNum);
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
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
      ),
    );
  }
}
