import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../../../patients/presentation/pages/invitation_code_page.dart';
import '../../../patients/presentation/providers/patients_list_provider.dart';
import '../../domain/entities/conversation_entity.dart';
import '../providers/conversations_provider.dart';
import 'chat_room_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final ConversationsProvider _conversationsProvider;
  List<Conversation> _inboxConversations = [];
  bool _loadingLastMessages = false;

  @override
  void initState() {
    super.initState();
    _conversationsProvider = context.read<ConversationsProvider>();
    _conversationsProvider.addListener(_onConversationsChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loginProvider = context.read<LoginProvider>();
      final isDoctor = loginProvider.role?.toLowerCase().contains('doctor') ?? false;
      final isReceptionist = loginProvider.role == 'receptionist' || loginProvider.role == 'recepcionista';
      final isDoctorOrReceptionist = isDoctor || isReceptionist;
      final dashboardProvider = context.read<DashboardProvider>();
      final patId = loginProvider.patientId ?? loginProvider.userId ?? 2;
      final currentUserId = loginProvider.userId ?? 2;

      // 1. Cargar pacientes si es doctor o recepcionista
      if (isDoctorOrReceptionist) {
        final doctorId = loginProvider.doctorId?.toString() ?? '1';
        await context.read<PatientsListProvider>().loadPatients(doctorId);
      }

      // 2. Cargar historial de conversaciones desde la bandeja de entrada (Inbox)
      await _loadLastMessages();

      // 3. Suscribirse a mensajes en tiempo real para actualizar la bandeja de entrada
      _conversationsProvider.startWatchingInbox();

      // Cargar panel y usuarios para autocompletar o búsquedas
      dashboardProvider.loadPatientDashboard(patId, currentUserId, doctorId: loginProvider.doctorId ?? 1);
    });
  }

  void _onConversationsChanged() {
    if (!mounted) return;
    setState(() {
      _inboxConversations = List<Conversation>.from(_conversationsProvider.conversations);
      _loadingLastMessages = _conversationsProvider.viewState == ConversationsViewState.loading;
    });
  }

  Future<void> _loadLastMessages() async {
    final loginProvider = context.read<LoginProvider>();
    final currentUserId = loginProvider.userId;
    if (currentUserId == null) return;

    // loadConversations ya notifica loading/success/error; _onConversationsChanged
    // se encarga de reflejarlo en el estado local de este widget.
    await _conversationsProvider.loadConversations(currentUserId);
  }

  @override
  void dispose() {
    _conversationsProvider.removeListener(_onConversationsChanged);
    _conversationsProvider.stopWatchingInbox();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = context.watch<LoginProvider>();
    final isDoctor = loginProvider.role?.toLowerCase().contains('doctor') ?? false;
    final isReceptionist = loginProvider.role == 'receptionist' || loginProvider.role == 'recepcionista';
    final isDoctorOrReceptionist = isDoctor || isReceptionist;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Mensajes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.textDark),
        ),
        elevation: 0,
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: AppColors.primary),
            onPressed: () async {
              final dashboardProvider = context.read<DashboardProvider>();
              final patId = loginProvider.patientId ?? loginProvider.userId ?? 2;
              final currentUserId = loginProvider.userId ?? 2;
              
              if (isDoctorOrReceptionist) {
                final doctorId = loginProvider.doctorId?.toString() ?? '1';
                await context.read<PatientsListProvider>().loadPatients(doctorId);
              }
              await _loadLastMessages();
              dashboardProvider.loadPatientDashboard(patId, currentUserId, doctorId: loginProvider.doctorId ?? 1);
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
                  fillColor: AppColors.cardBackground,
                  hintText: isDoctorOrReceptionist ? 'Buscar contacto...' : 'Buscar médico o recepcionista...',
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
                    borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.transparent : Colors.pink.shade50),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.transparent : Colors.pink.shade50),
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
              child: isDoctorOrReceptionist ? _buildDoctorChatList() : _buildPatientChatList(),
            ),
          ],
        ),
      ),
      floatingActionButton: isDoctorOrReceptionist ? FloatingActionButton(
        onPressed: _showContactsDialog,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.contacts, color: Colors.white),
      ) : null,
    );
  }

  // --- DOCTOR & RECEPTIONIST VIEW: Active Conversations ---
  Widget _buildDoctorChatList() {
    final loginProvider = context.watch<LoginProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();

    if (_loadingLastMessages && _inboxConversations.isEmpty) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_inboxConversations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'Sin conversaciones',
        description: 'Inicia un chat con un paciente o doctor usando el botón de contactos abajo.',
      );
    }

    final filtered = _inboxConversations.where((conv) {
      return conv.participant2Name.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return _buildEmptyState(
          icon: Icons.search_off_outlined,
          title: 'Sin resultados',
          description: 'No se encontraron contactos que coincidan con tu búsqueda.',
        );
      } else {
        return _buildEmptyState(
          icon: Icons.chat_bubble_outline,
          title: 'Sin chats activos',
          description: 'Toca el botón de contactos abajo para iniciar una conversación.',
        );
      }
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final conv = filtered[index];
        final otherUserId = conv.participant2Id;
        
        // Obtener rol del usuario
        final contactUser = dashboardProvider.users.firstWhere(
          (u) => u.userId == otherUserId,
          orElse: () => UserProfile(name: '', lastName: '', email: '', role: 'paciente'),
        );
        
        final isDoc = contactUser.role.toLowerCase().contains('doctor') || conv.participant2Name.contains('Dra.');
        final fullName = isDoc 
            ? 'Dra. ${conv.participant2Name.replaceAll('Dra. ', '').replaceAll('Dr. ', '')}'.trim()
            : conv.participant2Name;
            
        final initials = fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'U';
        
        String lastMessageContent = 'Sin mensajes';
        String lastMessageTime = '';
        
        final lastMsg = conv.lastMessage;
        final unreadCount = (lastMsg != null && lastMsg.senderId == loginProvider.userId) ? 0 : conv.unreadCount;
        if (lastMsg != null) {
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
            color: AppColors.cardBackground,
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
              setState(() {
                final idx = _inboxConversations.indexWhere((c) => c.participant2Id == otherUserId);
                if (idx != -1) {
                  final old = _inboxConversations[idx];
                  _inboxConversations[idx] = Conversation(
                    conversationId: old.conversationId,
                    participant1Id: old.participant1Id,
                    participant2Id: old.participant2Id,
                    participant1Name: old.participant1Name,
                    participant2Name: old.participant2Name,
                    lastMessage: old.lastMessage,
                    unreadCount: 0,
                    updatedAt: old.updatedAt,
                  );
                }
              });
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomPage(
                    otherUserId: otherUserId,
                    otherUserName: fullName,
                    otherUserRole: contactUser.role.isNotEmpty ? contactUser.role : 'paciente',
                  ),
                ),
              );
              _loadLastMessages();
            },
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    initials,
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
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
    final loginProvider = context.read<LoginProvider>();
    final isReceptionist = loginProvider.role == 'receptionist' || loginProvider.role == 'recepcionista';
    
    // Construir la lista de contactos disponibles
    final List<UserProfile> availableContacts = [];
    
    // Todos los pacientes
    for (final patient in patientsProvider.patients) {
      final patientUser = dashboardProvider.users.firstWhere(
        (u) => u.userId == patient.userId,
        orElse: () => UserProfile(userId: patient.userId, name: 'Paciente', lastName: '${patient.patientId}', email: '', role: 'paciente'),
      );
      availableContacts.add(patientUser);
    }
    
    // Si es recepcionista, también agregar a todos los médicos
    if (isReceptionist) {
      final doctors = dashboardProvider.users.where((u) => u.role.toLowerCase().contains('doctor')).toList();
      availableContacts.addAll(doctors);
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
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
                    'Contactos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  SizedBox(height: 8),
                  const Divider(),
                  Expanded(
                    child: availableContacts.isEmpty
                        ? Center(
                            child: Text(
                              'No hay contactos registrados.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: availableContacts.length,
                            itemBuilder: (context, index) {
                              final contactUser = availableContacts[index];
                              final isDoc = contactUser.role.toLowerCase().contains('doctor');
                              final fullName = isDoc 
                                  ? 'Dra. ${contactUser.name} ${contactUser.lastName}'.trim()
                                  : '${contactUser.name} ${contactUser.lastName}'.trim();
                              final initials = '${contactUser.name.isNotEmpty ? contactUser.name[0] : 'U'}${contactUser.lastName.isNotEmpty ? contactUser.lastName[0] : ''}';

                              return Container(
                                margin: EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9FB),
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
                                          otherUserId: contactUser.userId!,
                                          otherUserName: fullName,
                                          otherUserRole: contactUser.role,
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

  // --- PATIENT VIEW: List of Doctors & Receptionists ---
  Widget _buildPatientChatList() {
    final dashboardProvider = context.watch<DashboardProvider>();
    final loginProvider = context.read<LoginProvider>();
    final currentUserId = loginProvider.userId;

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
                color: AppColors.isDarkMode ? const Color(0xFF351A25) : const Color(0xFFFFF0F6),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.isDarkMode ? const Color(0xFF5C2E42) : Colors.pink.shade100, width: 1.5),
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
                              doctorId: loginProvider.doctorId ?? 1,
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

    if (_loadingLastMessages && _inboxConversations.isEmpty) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    // 1. Obtener la lista de conversaciones del inbox
    final List<Conversation> conversations = _inboxConversations;

    // 2. Asegurarse de que el médico asignado siempre aparezca, incluso si no hay mensajes en el inbox
    final doctors = dashboardProvider.users.where((u) => u.role.toLowerCase().contains('doctor')).toList();
    final assignedDoc = doctors.isNotEmpty ? doctors.first : null;
    final assignedDocUserId = assignedDoc?.userId ?? 1;
    final assignedDocName = hasDoctor ? docName : 'Dra. Gómez';

    final List<Conversation> displayConversations = List.from(conversations);

    // Si el médico asignado no está en el inbox, lo agregamos como una conversación vacía
    final hasDocInInbox = displayConversations.any((c) => c.participant2Id == assignedDocUserId);
    if (!hasDocInInbox) {
      displayConversations.add(Conversation(
        conversationId: assignedDocUserId,
        participant1Id: currentUserId ?? 0,
        participant2Id: assignedDocUserId,
        participant1Name: '',
        participant2Name: assignedDocName.replaceAll('Dra. ', '').replaceAll('Dr. ', ''),
        unreadCount: 0,
        updatedAt: DateTime.now().subtract(const Duration(days: 365)), // Al final
      ));
    }

    // 3. Filtrar según la búsqueda
    final filteredContacts = displayConversations.where((conv) {
      return conv.participant2Name.toLowerCase().contains(_searchQuery);
    }).toList();

    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: filteredContacts.length,
      itemBuilder: (context, index) {
        final conv = filteredContacts[index];
        final otherUserId = conv.participant2Id;
        
        final contactUser = dashboardProvider.users.firstWhere(
          (u) => u.userId == otherUserId,
          orElse: () => UserProfile(name: '', lastName: '', email: '', role: 'paciente'),
        );
        
        final isDoctorRole = contactUser.role.toLowerCase().contains('doctor') || conv.participant2Name.contains('Dra.');
        final isReceptionistRole = contactUser.role.toLowerCase() == 'receptionist' || contactUser.role.toLowerCase() == 'recepcionista';
        
        final String displayName = isDoctorRole 
            ? 'Dra. ${conv.participant2Name.replaceAll('Dra. ', '').replaceAll('Dr. ', '')}'.trim()
            : (isReceptionistRole ? 'Recepcionista: ${conv.participant2Name}' : conv.participant2Name);
            
        final initials = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U';
        final isAssigned = isDoctorRole && (otherUserId == assignedDocUserId);

        // Obtener último mensaje
        String subtitleText = isDoctorRole ? docSpecialty : 'Personal Administrativo';
        final lastMsg = conv.lastMessage;
        final unreadCount = (lastMsg != null && lastMsg.senderId == currentUserId) ? 0 : conv.unreadCount;
        if (lastMsg != null) {
          final isSentByMe = lastMsg.senderId == currentUserId;
          final prefix = isSentByMe ? 'Tú: ' : '';
          subtitleText = '$prefix${lastMsg.content}';
        }

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
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
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
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
                subtitleText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: Color(0xFFC7C7CC)),
            onTap: () async {
              setState(() {
                final idx = _inboxConversations.indexWhere((c) => c.participant2Id == otherUserId);
                if (idx != -1) {
                  final old = _inboxConversations[idx];
                  _inboxConversations[idx] = Conversation(
                    conversationId: old.conversationId,
                    participant1Id: old.participant1Id,
                    participant2Id: old.participant2Id,
                    participant1Name: old.participant1Name,
                    participant2Name: old.participant2Name,
                    lastMessage: old.lastMessage,
                    unreadCount: 0,
                    updatedAt: old.updatedAt,
                  );
                }
              });
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomPage(
                    otherUserId: otherUserId,
                    otherUserName: displayName,
                    otherUserRole: contactUser.role.isNotEmpty ? contactUser.role : 'doctor',
                  ),
                ),
              );
              _loadLastMessages();
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
