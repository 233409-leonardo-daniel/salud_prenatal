import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/patients_list_provider.dart';
import 'patient_state.dart';
import '../../domain/entities/patient.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../../core/session/session_manager.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../../../dashboard/presentation/pages/patient_progress_page.dart';
import '../../../dashboard/presentation/pages/patient_record_page.dart';
import '../../../dashboard/presentation/pages/new_consultation_dialog.dart';

class PatientsListPage extends StatefulWidget {
  const PatientsListPage({super.key});

  @override
  State<PatientsListPage> createState() => _PatientsListPageState();
}

class _PatientsListPageState extends State<PatientsListPage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  static const int _pageSize = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = context.read<SessionManager>();
      final doctorId = session.doctorId?.toString();
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
                  final doctorId = context.read<SessionManager>().doctorId?.toString();
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

    // Build the view-model list and apply the search filter BEFORE paginating,
    // so pagination always reflects the actually visible set of patients.
    final searchQuery = _searchController.text.trim().toLowerCase();
    final filteredPatients = <Map<String, dynamic>>[];

    for (final patient in patientsProvider.patients) {
      final pId = patient.patientId;
      final userId = patient.userId;

      // GET /doctors/{id}/patients ya trae full_name resuelto; si no viene
      // (p. ej. viniera de /patients/search) se cae al listado de usuarios.
      String patientName;
      if (patient.fullName != null && patient.fullName!.trim().isNotEmpty) {
        patientName = patient.fullName!.trim();
      } else {
        final patientUser = dashboardProvider.users.firstWhere(
          (u) => u.userId == userId,
          orElse: () => UserProfile(
            name: 'Paciente',
            lastName: '$pId',
            email: '',
            role: 'paciente',
          ),
        );
        patientName = '${patientUser.name} ${patientUser.lastName}'.trim();
      }

      final patientCode = '#SP-$pId';
      final nameParts = patientName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      final initials = nameParts.isNotEmpty
          ? '${nameParts.first[0]}${nameParts.length > 1 ? nameParts.last[0] : ''}'
          : 'P';

      if (searchQuery.isNotEmpty &&
          !patientName.toLowerCase().contains(searchQuery) &&
          !patientCode.toLowerCase().contains(searchQuery)) {
        continue;
      }

      filteredPatients.add({
        'name': patientName,
        'id': patientCode,
        'userId': userId,
        'patientEntity': patient,
        'gestationAge': patient.currentGestationalWeeks != null
            ? '${patient.currentGestationalWeeks} sem'
            : 'No reg.',
        'initials': initials.toUpperCase(),
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
          gestationAge: item['gestationAge'] as String,
          avatarInitials: item['initials'] as String,
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

  /// Resuelve el expediente médico de la paciente (necesario para conocer
  /// su medical_record_id, que el card de "Mis Pacientes" no trae) y, si
  /// existe, abre el diálogo de nueva consulta. Si aún no tiene expediente,
  /// avisa al doctor en vez de intentar crear la consulta con un id inválido.
  Future<void> _handleNewConsultation(PatientEntity patient, String patientName) async {
    final doctorId = context.read<SessionManager>().doctorId;
    if (doctorId == null) return;

    final dashboardProvider = context.read<DashboardProvider>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    await dashboardProvider.loadPatientDetails(patient.patientId, doctorId: doctorId);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final record = dashboardProvider.activeMedicalRecord;
    if (record == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Esta paciente aún no tiene expediente médico. Créalo primero desde "Ver Detalle".')),
      );
      return;
    }
    if (!mounted) return;
    await showNewConsultationDialog(context, medicalRecordId: record.medicalRecordId, patientName: patientName);
  }

  Widget _buildPatientListCard({
    required String name,
    required String id,
    required int userId,
    required PatientEntity patientEntity,
    required String gestationAge,
    required String avatarInitials,
  }) {
    // El filtrado por búsqueda ya se aplica antes de paginar en build().
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
                backgroundColor: AppColors.primaryLight,
                radius: 24,
                child: Text(
                  avatarInitials,
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ID: $id',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _handleNewConsultation(patientEntity, name),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Nueva consulta',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edad Gestacional', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                SizedBox(height: 2),
                Text(gestationAge, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientProgressPage(
                          patientName: name,
                          patientId: id,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: AppColors.primary, width: 1.4),
                    backgroundColor: AppColors.primaryLight,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.trending_up, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Progreso',
                        style: TextStyle(
                          color: AppColors.primary,
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
