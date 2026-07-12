import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/conversations_provider.dart';
import '../widgets/contacts_bottom_sheet.dart';
import '../../../../core/session/session_manager.dart';
import 'chat_detail_page.dart';

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
    final session = context.read<SessionManager>();
    final currentUserId = session.userId;
    if (currentUserId == null) return;

    await context.read<ConversationsProvider>().loadConversations(currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConversationsProvider>();
    final currentUserId = context.watch<SessionManager>().userId;

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
      // GET /chat/contacts resuelve por rol en el backend (pacientes+
      // doctores para una recepcionista).
      floatingActionButton: FloatingActionButton(
        onPressed: () => showContactsBottomSheet(context, onReturn: _loadInbox),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.contacts, color: Colors.white),
      ),
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
