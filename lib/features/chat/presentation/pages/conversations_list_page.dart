import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../patients/presentation/providers/patients_list_provider.dart';
import '../providers/conversations_provider.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../../domain/entities/chat_contact.dart';
import 'chat_detail_page.dart';

/// Bandeja de mensajes de la recepcionista. El backend no expone un
/// endpoint de "inbox", así que primero se resuelven los contactos reales
/// (pacientes y médicos del consultorio) y luego se pide el historial de
/// cada uno para armar la lista de conversaciones.
class ConversationsListPage extends StatefulWidget {
  const ConversationsListPage({super.key});

  @override
  State<ConversationsListPage> createState() => _ConversationsListPageState();
}

class _ConversationsListPageState extends State<ConversationsListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInbox());
  }

  Future<void> _loadInbox() async {
    final loginProvider = context.read<LoginProvider>();
    final currentUserId = loginProvider.userId;
    final doctorId = loginProvider.doctorId;
    if (currentUserId == null) return;

    final dashboardProvider = context.read<DashboardProvider>();
    final patientsProvider = context.read<PatientsListProvider>();

    if (doctorId != null) {
      await patientsProvider.loadPatients(doctorId.toString());
      if (!mounted) return;
      // loadDoctorDashboard puebla dashboardProvider.users, necesario para
      // resolver los nombres reales de los contactos.
      await dashboardProvider.loadDoctorDashboard(doctorId);
      if (!mounted) return;
    }

    final contacts = <ChatContact>[];
    for (final patient in patientsProvider.patients) {
      final user = dashboardProvider.users.firstWhere(
        (u) => u.userId == patient.userId,
        orElse: () => UserProfile(userId: patient.userId, name: 'Paciente', lastName: '${patient.patientId}', email: '', role: 'paciente'),
      );
      contacts.add(ChatContact(userId: patient.userId, name: '${user.name} ${user.lastName}'.trim(), role: user.role));
    }
    for (final u in dashboardProvider.users) {
      if (u.role.toLowerCase().contains('doctor') && u.userId != null && u.userId != currentUserId) {
        contacts.add(ChatContact(userId: u.userId!, name: '${u.name} ${u.lastName}'.trim(), role: u.role));
      }
    }

    if (!mounted) return;
    await context.read<ConversationsProvider>().loadConversations(currentUserId, contacts);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConversationsProvider>();
    final currentUserId = context.watch<LoginProvider>().userId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mensajes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: _loadInbox,
          ),
        ],
      ),
      body: _buildBody(provider, currentUserId),
    );
  }

  Widget _buildBody(ConversationsProvider provider, int? currentUserId) {
    switch (provider.viewState) {
      case ConversationsViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ConversationsViewState.error:
        return Center(child: Text('Error: ${provider.error}'));
      case ConversationsViewState.initial:
      case ConversationsViewState.success:
        if (provider.conversations.isEmpty) {
          return Center(
            child: Text('No tienes conversaciones activas.', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
          );
        }
        break;
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: provider.conversations.length,
      itemBuilder: (context, index) {
        final conv = provider.conversations[index];
        final isParticipant1 = conv.participant1Id == currentUserId;
        final otherName = isParticipant1 ? conv.participant2Name : conv.participant1Name;
        final otherId = isParticipant1 ? conv.participant2Id : conv.participant1Id;
        final lastMsg = conv.lastMessage?.content ?? 'Sin mensajes aún';

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person, color: AppColors.primary),
            ),
            title: Text(otherName, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
            subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textMuted)),
            trailing: conv.unreadCount > 0
                ? Container(
                    padding: EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('${conv.unreadCount}', style: TextStyle(color: Colors.white, fontSize: 12)),
                  )
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailPage(otherUserId: otherId, otherUserName: otherName),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
