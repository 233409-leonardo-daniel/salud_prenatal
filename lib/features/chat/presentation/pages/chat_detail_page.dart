import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/chat_provider.dart';
import '../../../login/presentation/providers/login_provider.dart';
import 'chat_state.dart';

class ChatDetailPage extends StatefulWidget {
  final int otherUserId;
  final String otherUserName;

  const ChatDetailPage({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = context.read<LoginProvider>().userId;
      if (currentUserId != null) {
        context.read<ChatProvider>().initChat(currentUserId, widget.otherUserId);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final currentUserId = context.watch<LoginProvider>().userId;

    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatProvider.messages.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName, style: TextStyle(fontSize: 16, color: Colors.white)),
            Text(
              chatProvider.isConnected ? 'En línea' : 'Desconectado',
              style: TextStyle(
                fontSize: 12,
                color: chatProvider.isConnected ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: switch (chatProvider.status) {
              ChatStatus.initial || ChatStatus.loading =>
                Center(child: CircularProgressIndicator()),
              ChatStatus.error =>
                Center(child: Text(chatProvider.errorMessage ?? 'Error al cargar mensajes')),
              ChatStatus.success => ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chatProvider.messages[index];
                    final isMe = msg.senderId == currentUserId;
                    return _buildMessageBubble(msg.content, isMe);
                  },
                ),
            },
          ),
          _buildMessageInput(chatProvider),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : (AppColors.isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: isMe ? Colors.white : AppColors.textDark),
        ),
      ),
    );
  }

  Widget _buildMessageInput(ChatProvider provider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: AppColors.cardBackground,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F7),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onSubmitted: (_) {
                if (_messageController.text.isNotEmpty) {
                  provider.sendMessage(_messageController.text);
                  _messageController.clear();
                }
              },
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: () {
                if (_messageController.text.isNotEmpty) {
                  provider.sendMessage(_messageController.text);
                  _messageController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
