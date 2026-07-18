import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/pages/dashboard_state.dart';
import '../../../../core/session/session_manager.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../../../patients/presentation/pages/invitation_code_page.dart';
import '../../domain/entities/conversation_entity.dart';
import '../providers/conversations_provider.dart';
import '../widgets/contacts_bottom_sheet.dart';
import '../widgets/pulsing_skeleton.dart';
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

  @override
  void initState() {
    super.initState();
    _conversationsProvider = context.read<ConversationsProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshInbox();
      _conversationsProvider.startWatchingInbox();
    });
  }

  /// Carga la bandeja real desde GET /chat/inbox. Para doctor/recepcionista
  /// eso es todo lo que hace falta: el rol/nombre de cada contacto ya viene
  /// en la respuesta del inbox (ver [Conversation.otherUserRole]), y
  /// patients/users solo se cargan bajo demanda al abrir el diálogo de
  /// "nuevo contacto" (ver [_showContactsDialog]). Para el paciente sí
  /// necesitamos, además, el nombre de su doctor asignado (current_doctor),
  /// que el inbox no expone si todavía no hay mensajes con él.
  Future<void> _refreshInbox() async {
    final session = context.read<SessionManager>();
    final currentUserId = session.userId;
    if (currentUserId == null) return; // Sesión no disponible: nada que cargar.

    final isDoctor = session.role?.toLowerCase().contains('doctor') ?? false;
    final isReceptionist = session.role == 'receptionist' || session.role == 'recepcionista';
    final isDoctorOrReceptionist = isDoctor || isReceptionist;

    if (!isDoctorOrReceptionist) {
      final dashboardProvider = context.read<DashboardProvider>();
      final patId = session.patientId ?? currentUserId;
      await dashboardProvider.loadPatientBasicInfo(patId);
      if (!mounted) return;
    }

    await _conversationsProvider.loadConversations(currentUserId);
  }

  Future<void> _loadLastMessages() => _refreshInbox();

  /// Empareja el nombre del doctor asignado (`current_doctor`, la única
  /// referencia que da el dashboard del paciente) contra la lista de
  /// usuarios ya cargada, para obtener su user_id real. El backend no
  /// expone ese ID directamente, así que este es el único mecanismo
  /// disponible; si no hay coincidencia, se devuelve null (nunca se inventa
  /// un ID).
  UserProfile? _matchAssignedDoctor(DashboardProvider dashboardProvider) {
    final docName = dashboardProvider.dashboardData?['current_doctor'] as String?;
    if (docName == null || docName.isEmpty) return null;

    final normalized = docName.trim().toLowerCase();
    final doctors = dashboardProvider.users.where((u) => u.role.toLowerCase().contains('doctor'));

    for (final doc in doctors) {
      final fullName = '${doc.name} ${doc.lastName}'.trim().toLowerCase();
      if (fullName.isNotEmpty && fullName == normalized) return doc;
    }
    for (final doc in doctors) {
      if (doc.name.isNotEmpty && normalized.contains(doc.name.toLowerCase())) return doc;
    }
    return null;
  }

  @override
  void dispose() {
    _conversationsProvider.stopWatchingInbox();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    final isDoctor = session.role?.toLowerCase().contains('doctor') ?? false;
    final isReceptionist = session.role == 'receptionist' || session.role == 'recepcionista';
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
            onPressed: _refreshInbox,
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
      // GET /chat/contacts resuelve por rol en el backend (pacientes+
      // recepcionistas para un doctor, pacientes+doctores para una
      // recepcionista, doctor asignado+recepcionistas para un paciente) —
      // el botón se muestra siempre, sin importar el rol.
      floatingActionButton: FloatingActionButton(
        onPressed: () => showContactsBottomSheet(context, onReturn: _loadLastMessages),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.contacts, color: Colors.white),
      ),
    );
  }

  // --- DOCTOR & RECEPTIONIST VIEW: Active Conversations ---
  Widget _buildDoctorChatList() {
    final session = context.watch<SessionManager>();
    final conversationsProvider = context.watch<ConversationsProvider>();
    final conversations = conversationsProvider.conversations;

    switch (conversationsProvider.viewState) {
      case ConversationsViewState.initial:
        return const _ChatListSkeleton();
      case ConversationsViewState.loading:
        if (conversations.isEmpty) return const _ChatListSkeleton();
        break;
      case ConversationsViewState.error:
        if (conversations.isEmpty) {
          return _buildEmptyState(
            icon: Icons.error_outline,
            title: 'No se pudo cargar',
            description: conversationsProvider.error ?? 'Ocurrió un error al cargar tus chats.',
          );
        }
        break;
      case ConversationsViewState.success:
        break;
    }

    if (conversations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'Sin conversaciones',
        description: 'Inicia un chat con un paciente o doctor usando el botón de contactos abajo.',
      );
    }

    final filtered = conversations.where((conv) {
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

        final isDoc = conv.otherUserRole.toLowerCase().contains('doctor') || conv.participant2Name.contains('Dra.');
        final fullName = isDoc 
            ? 'Dra. ${conv.participant2Name.replaceAll('Dra. ', '').replaceAll('Dr. ', '')}'.trim()
            : conv.participant2Name;
            
        final initials = fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'U';
        
        String lastMessageContent = 'Sin mensajes';
        String lastMessageTime = '';
        
        final lastMsg = conv.lastMessage;
        final unreadCount = (lastMsg != null && lastMsg.senderId == session.userId) ? 0 : conv.unreadCount;
        if (lastMsg != null) {
          final isSentByMe = lastMsg.senderId == session.userId;
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
              _conversationsProvider.markConversationAsRead(otherUserId);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomPage(
                    otherUserId: otherUserId,
                    otherUserName: fullName,
                    otherUserRole: conv.otherUserRole.isNotEmpty ? conv.otherUserRole : 'paciente',
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


  // --- PATIENT VIEW: List of Doctors & Receptionists ---
  Widget _buildPatientChatList() {
    final dashboardProvider = context.watch<DashboardProvider>();
    final session = context.read<SessionManager>();
    final conversationsProvider = context.watch<ConversationsProvider>();
    final currentUserId = session.userId;

    final docName = dashboardProvider.dashboardData?['current_doctor'] as String?;
    final docSpecialty = dashboardProvider.dashboardData?['current_doctor_specialty'] as String? ?? 'Ginecología y Obstetricia';

    // Check if patient is linked to a doctor
    final hasDoctor = docName != null && docName.isNotEmpty;

    // Mientras el dashboard básico (que trae `current_doctor`) sigue cargando y
    // aún no tenemos datos, mostramos el skeleton en vez del cartel de "no
    // tienes médico": si no, al entrar desde una notificación de un doctor que
    // SÍ existe, parpadea ese cartel erróneo antes de resolver.
    if (!hasDoctor &&
        dashboardProvider.dashboardData == null &&
        dashboardProvider.status == DashboardStatus.loading) {
      return const _ChatListSkeleton();
    }

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
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
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
                      final patientId = session.patientId;
                      final userId = session.userId;
                      if (result == true && mounted && patientId != null && userId != null) {
                        context.read<DashboardProvider>().loadPatientDashboard(
                              patientId,
                              userId,
                              doctorId: session.doctorId,
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

    switch (conversationsProvider.viewState) {
      case ConversationsViewState.initial:
        return const _ChatListSkeleton();
      case ConversationsViewState.loading:
        if (conversationsProvider.conversations.isEmpty) return const _ChatListSkeleton();
        break;
      case ConversationsViewState.error:
        if (conversationsProvider.conversations.isEmpty) {
          return _buildEmptyState(
            icon: Icons.error_outline,
            title: 'No se pudo cargar',
            description: conversationsProvider.error ?? 'Ocurrió un error al cargar tus chats.',
          );
        }
        break;
      case ConversationsViewState.success:
        break;
    }

    // 1. Obtener la lista de conversaciones del inbox
    final List<Conversation> conversations = conversationsProvider.conversations;

    // 2. Asegurarse de que el médico asignado siempre aparezca, incluso si no hay mensajes en el inbox.
    // El backend no da el user_id del doctor asignado directamente, así que se
    // resuelve emparejando su nombre (current_doctor) contra la lista de
    // usuarios ya cargada; si no hay coincidencia, no se inventa un ID.
    final assignedDocUserId = _matchAssignedDoctor(dashboardProvider)?.userId;
    final assignedDocName = docName ?? '';

    final List<Conversation> displayConversations = List.from(conversations);

    // Si el médico asignado no está en el inbox, lo agregamos como una conversación vacía
    if (assignedDocUserId != null && currentUserId != null) {
      final hasDocInInbox = displayConversations.any((c) => c.participant2Id == assignedDocUserId);
      if (!hasDocInInbox) {
        displayConversations.add(Conversation(
          conversationId: assignedDocUserId,
          participant1Id: currentUserId,
          participant2Id: assignedDocUserId,
          participant1Name: '',
          participant2Name: assignedDocName.replaceAll('Dra. ', '').replaceAll('Dr. ', ''),
          unreadCount: 0,
          updatedAt: DateTime.now().subtract(const Duration(days: 365)), // Al final
          otherUserRole: 'doctor',
        ));
      }
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

        final isDoctorRole = conv.otherUserRole.toLowerCase().contains('doctor') || conv.participant2Name.contains('Dra.');
        final isReceptionistRole = conv.otherUserRole.toLowerCase() == 'receptionist' || conv.otherUserRole.toLowerCase() == 'recepcionista';
        
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
            border: isAssigned ? Border.all(color: AppColors.isDarkMode ? const Color(0xFF5C2E42) : Colors.pink.shade100, width: 1.5) : null,
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
                      color: AppColors.primaryLight,
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
            trailing: Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () async {
              _conversationsProvider.markConversationAsRead(otherUserId);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomPage(
                    otherUserId: otherUserId,
                    otherUserName: displayName,
                    otherUserRole: conv.otherUserRole.isNotEmpty ? conv.otherUserRole : 'doctor',
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
            Icon(icon, size: 64, color: AppColors.primary.withOpacity(0.3)),
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

/// Skeleton de la bandeja de chats: imita la forma real de una fila (avatar
/// circular + dos líneas de texto), para que el primer frame ya se parezca
/// al contenido final en vez de un bloque genérico.
class _ChatListSkeleton extends StatelessWidget {
  const _ChatListSkeleton();

  @override
  Widget build(BuildContext context) {
    return PulsingSkeleton(
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 26, backgroundColor: AppColors.skeletonBase),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(color: AppColors.skeletonBase, borderRadius: BorderRadius.circular(6)),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 180,
                    decoration: BoxDecoration(color: AppColors.skeletonBase, borderRadius: BorderRadius.circular(6)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
