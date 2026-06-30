import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../../../patients/presentation/pages/invitation_code_page.dart';
import '../../../patients/presentation/providers/patients_list_provider.dart';
import '../../../patients/presentation/pages/patient_state.dart';
import '../../di/chat_module.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_room_page.dart';
import '../../../../core/network/api_client.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final ChatModule _chatModule;
  Map<int, List<ChatMessage>> _conversations = {};
  bool _loadingLastMessages = false;
  StreamSubscription<ChatMessage>? _listMessageSubscription;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<ApiClient>();
    _chatModule = ChatModule(apiClient);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loginProvider = context.read<LoginProvider>();
      final isDoctor = loginProvider.role?.toLowerCase().contains('doctor') ?? false;
      final dashboardProvider = context.read<DashboardProvider>();
      final patId = loginProvider.patientId ?? loginProvider.userId ?? 2;
      final currentUserId = loginProvider.userId ?? 2;
      
      // Load relevant data depending on role
      if (isDoctor) {
        final doctorId = loginProvider.doctorId?.toString() ?? '1';
        await context.read<PatientsListProvider>().loadPatients(doctorId);
        await _loadLastMessages();

        // Listen for real-time incoming messages to update conversation status
        _listMessageSubscription = _chatModule.remoteDataSource.messageStream.listen((message) {
          final currentUserIdLocal = loginProvider.userId;
          if (currentUserIdLocal == null) return;
          final otherUserId = message.senderId == currentUserIdLocal ? message.receiverId : message.senderId;
          
          if (_conversations.containsKey(otherUserId)) {
            setState(() {
              final exists = _conversations[otherUserId]!.any((msg) => msg.messageId == message.messageId);
              if (!exists) {
                _conversations[otherUserId]!.add(message);
                _conversations[otherUserId]!.sort((a, b) => a.createdAt.compareTo(b.createdAt));
              }
            });
          } else {
            _loadLastMessages();
          }
        });
      }
      
      // Load users list for doctor search / fallback matching
      dashboardProvider.loadPatientDashboard(patId, currentUserId);
    });
  }

  Future<void> _loadLastMessages() async {
    final loginProvider = context.read<LoginProvider>();
    final currentUserId = loginProvider.userId;
    if (currentUserId == null) return;

    final patientsProvider = context.read<PatientsListProvider>();
    final patients = patientsProvider.patients;
    if (patients.isEmpty) return;

    setState(() {
      _loadingLastMessages = true;
    });

    try {
      final Map<int, List<ChatMessage>> loadedConversations = {};
      for (final patient in patients) {
        final history = await _chatModule.repository.getChatHistory(patient.userId, currentUserId);
        loadedConversations[patient.userId] = history;
      }
      if (mounted) {
        setState(() {
          _conversations = loadedConversations;
          _loadingLastMessages = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading last messages: $e');
      if (mounted) {
        setState(() {
          _loadingLastMessages = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _listMessageSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = context.watch<LoginProvider>();
    final isDoctor = loginProvider.role?.toLowerCase().contains('doctor') ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Mensajes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.textDark),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFFF9F9FB),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: AppColors.primary),
            onPressed: () async {
              final dashboardProvider = context.read<DashboardProvider>();
              final patId = loginProvider.patientId ?? loginProvider.userId ?? 2;
              final currentUserId = loginProvider.userId ?? 2;
              
              if (isDoctor) {
                final doctorId = loginProvider.doctorId?.toString() ?? '1';
                await context.read<PatientsListProvider>().loadPatients(doctorId);
                await _loadLastMessages();
              }
              dashboardProvider.loadPatientDashboard(patId, currentUserId);
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: isDoctor ? 'Buscar paciente...' : 'Buscar médico...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppColors.textMuted),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.pink.shade50),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.pink.shade50),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            
            // List view
            Expanded(
              child: isDoctor ? _buildDoctorChatList() : _buildPatientChatList(),
            ),
          ],
        ),
      ),
      floatingActionButton: isDoctor ? FloatingActionButton(
        onPressed: _showContactsDialog,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.contacts, color: Colors.white),
      ) : null,
    );
  }

  // --- DOCTOR VIEW: List of Patients ---
  Widget _buildDoctorChatList() {
    final patientsProvider = context.watch<PatientsListProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final loginProvider = context.watch<LoginProvider>();

    if (patientsProvider.status == PatientsListStatus.loading || _loadingLastMessages) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final patients = patientsProvider.patients;
    if (patients.isEmpty) {
      return _buildEmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'Sin pacientes aún',
        description: 'Tus pacientes aparecerán aquí una vez que se vinculen a tu cuenta.',
      );
    }

    // Filter patients to only show those who have active conversations & match the search query
    final filtered = patients.where((patient) {
      final history = _conversations[patient.userId] ?? [];
      if (history.isEmpty) return false;

      final patientUser = dashboardProvider.users.firstWhere(
        (u) => u.userId == patient.userId,
        orElse: () => UserProfile(name: 'Paciente', lastName: '${patient.patientId}', email: '', role: 'paciente'),
      );
      final fullName = '${patientUser.name} ${patientUser.lastName}'.toLowerCase();
      return fullName.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return _buildEmptyState(
          icon: Icons.search_off_outlined,
          title: 'Sin resultados',
          description: 'No se encontraron pacientes que coincidan con tu búsqueda.',
        );
      } else {
        return _buildEmptyState(
          icon: Icons.chat_bubble_outline,
          title: 'Sin chats activos',
          description: 'Toca el botón de contactos abajo para iniciar una conversación con tus pacientes.',
        );
      }
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final patient = filtered[index];
        final patientUser = dashboardProvider.users.firstWhere(
          (u) => u.userId == patient.userId,
          orElse: () => UserProfile(name: 'Paciente', lastName: '${patient.patientId}', email: '', role: 'paciente'),
        );
        final fullName = '${patientUser.name} ${patientUser.lastName}';
        final initials = '${patientUser.name.isNotEmpty ? patientUser.name[0] : 'P'}${patientUser.lastName.isNotEmpty ? patientUser.lastName[0] : ''}';
        
        final history = _conversations[patient.userId] ?? [];
        String lastMessageContent = 'Sin mensajes';
        String lastMessageTime = '';
        
        if (history.isNotEmpty) {
          final lastMsg = history.last;
          final isSentByMe = lastMsg.senderId == loginProvider.userId;
          final prefix = isSentByMe ? 'Tú: ' : '';
          lastMessageContent = '$prefix${lastMsg.content}';
          
          final time = lastMsg.createdAt;
          final isPm = time.hour >= 12;
          final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
          lastMessageTime = '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ${isPm ? 'PM' : 'AM'}';
        }

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: ListTile(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomPage(
                    otherUserId: patientUser.userId ?? patient.userId,
                    otherUserName: fullName,
                    otherUserRole: 'paciente',
                  ),
                ),
              );
              _loadLastMessages();
            },
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                initials,
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    fullName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                  ),
                ),
                Text(
                  lastMessageTime,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text(
                lastMessageContent,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showContactsDialog() {
    final patientsProvider = context.read<PatientsListProvider>();
    final dashboardProvider = context.read<DashboardProvider>();
    final patients = patientsProvider.patients;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Contactos (Pacientes)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  SizedBox(height: 8),
                  const Divider(),
                  Expanded(
                    child: patients.isEmpty
                        ? Center(
                            child: Text(
                              'No hay pacientes registrados.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: patients.length,
                            itemBuilder: (context, index) {
                              final patient = patients[index];
                              final patientUser = dashboardProvider.users.firstWhere(
                                (u) => u.userId == patient.userId,
                                orElse: () => UserProfile(name: 'Paciente', lastName: '${patient.patientId}', email: '', role: 'paciente'),
                              );
                              final fullName = '${patientUser.name} ${patientUser.lastName}';
                              final initials = '${patientUser.name.isNotEmpty ? patientUser.name[0] : 'P'}${patientUser.lastName.isNotEmpty ? patientUser.lastName[0] : ''}';

                              return Container(
                                margin: EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F9FB),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  leading: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.primaryLight,
                                    child: Text(
                                      initials,
                                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  title: Text(
                                    fullName,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                                  ),
                                  trailing: Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 18),
                                  onTap: () async {
                                    Navigator.pop(context); // Close bottom sheet
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatRoomPage(
                                          otherUserId: patientUser.userId ?? patient.userId,
                                          otherUserName: fullName,
                                          otherUserRole: 'paciente',
                                        ),
                                      ),
                                    );
                                    _loadLastMessages();
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- PATIENT VIEW: List of Doctors ---
  Widget _buildPatientChatList() {
    final dashboardProvider = context.watch<DashboardProvider>();
    final loginProvider = context.read<LoginProvider>();

    final docName = dashboardProvider.dashboardData?['current_doctor'] as String?;
    final docSpecialty = dashboardProvider.dashboardData?['current_doctor_specialty'] as String? ?? 'Ginecología y Obstetricia';
    
    // Check if patient is linked to a doctor
    final hasDoctor = docName != null && docName.isNotEmpty;

    if (!hasDoctor) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 40),
            Container(
              padding: EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F6),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.pink.shade100, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(10),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 40),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Aún no tienes un médico asignado',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Para poder chatear en tiempo real y recibir asesoramiento, debes vincular tu cuenta con tu doctor usando su código.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const InvitationCodePage()),
                      );
                      if (result == true && mounted) {
                        context.read<DashboardProvider>().loadPatientDashboard(
                              loginProvider.patientId ?? 0,
                              loginProvider.userId ?? 0,
                            );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.vpn_key_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Ingresar Código', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Patient has a doctor. Let's find this doctor's user ID in users list.
    // In database, the doctor is user_id 1 (Pedro Gomez).
    // Let's filter the users list to locate doctors.
    final doctors = dashboardProvider.users.where((u) => u.role.toLowerCase().contains('doctor')).toList();

    // If no doctors are found in remote, fallback to Pedro Gomez (id 1)
    if (doctors.isEmpty) {
      doctors.add(UserProfile(
        userId: 1,
        name: docName.replaceAll('Dra. ', '').replaceAll('Dr. ', ''),
        lastName: '',
        email: 'doctor@example.com',
        role: 'doctor',
      ));
    }

    // Filter based on search query
    final filteredDoctors = doctors.where((doc) {
      final fullName = '${doc.name} ${doc.lastName}'.toLowerCase();
      return fullName.contains(_searchQuery);
    }).toList();

    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: filteredDoctors.length,
      itemBuilder: (context, index) {
        final doctor = filteredDoctors[index];
        final fullName = 'Dra. ${doctor.name} ${doctor.lastName}'.trim();
        final initials = '${doctor.name.isNotEmpty ? doctor.name[0] : 'D'}${doctor.lastName.isNotEmpty ? doctor.lastName[0] : ''}';
        
        final isAssigned = docName.contains(doctor.name) || doctor.userId == 1;

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: isAssigned ? Border.all(color: Colors.pink.shade100, width: 1.5) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    initials,
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    fullName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                  ),
                ),
                if (isAssigned)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Mi Doctor',
                      style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text(
                docSpecialty,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: Color(0xFFC7C7CC)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomPage(
                    otherUserId: doctor.userId ?? 1,
                    otherUserName: fullName,
                    otherUserRole: 'doctor',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String description}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.pink.shade100),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
