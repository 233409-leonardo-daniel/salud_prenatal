import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/conversations_provider.dart';
import '../../../login/presentation/providers/login_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = context.read<LoginProvider>().userId ?? 0;
      if (currentUserId > 0) {
        context.read<ConversationsProvider>().loadConversations(currentUserId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConversationsProvider>();
    final currentUserId = context.watch<LoginProvider>().userId ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: Text('Mensajes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _buildBody(provider, currentUserId),
    );
  }

  Widget _buildBody(ConversationsProvider provider, int currentUserId) {
    if (provider.viewState == ConversationsViewState.loading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (provider.viewState == ConversationsViewState.error) {
      return Center(child: Text('Error: ${provider.error}'));
    }
    
    if (provider.conversations.isEmpty) {
      return Center(
        child: Text('No tienes conversaciones activas.', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
      );
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
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFF0F6),
              child: Icon(Icons.person, color: AppColors.primary),
            ),
            title: Text(otherName, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
            subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
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
