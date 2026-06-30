import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../patient_diaries/presentation/providers/patient_diaries_provider.dart';
import '../providers/chat_provider.dart';
import '../../domain/entities/chat_message.dart';
import '../../di/chat_module.dart';

import '../../../../core/network/api_client.dart';

class ChatRoomPage extends StatefulWidget {
  final int otherUserId;
  final String otherUserName;
  final String otherUserRole; // 'doctor' or 'paciente'

  const ChatRoomPage({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<ApiClient>();
    final chatModule = ChatModule(apiClient);
    _chatProvider = ChatProvider(chatModule.repository);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loginProvider = context.read<LoginProvider>();
      final currentUserId = loginProvider.userId ?? 2;
      
      _chatProvider.initChat(currentUserId, widget.otherUserId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatProvider.closeChat();
    _chatProvider.dispose();
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

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _chatProvider.sendMessage(text);
    _messageController.clear();
    
    // Auto-scroll after a short delay to let frame render
    Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
  }

  // --- QUICK ACTION: Send latest measurement ---
  void _sendLatestMeasurement() {
    final diariesProvider = context.read<PatientDiariesProvider>();
    if (diariesProvider.diaries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes mediciones registradas en tu bitácora.')),
      );
      return;
    }
    
    final latest = diariesProvider.diaries.first;
    final message = "Presión: ${latest.systolic}/${latest.diastolic} mmHg • Peso: ${latest.weightKg} kg (Última medición)";
    
    _chatProvider.sendMessage(message);
    Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
  }

  // --- QUICK ACTION: Show medical tips template ---
  void _showDoctorTipsMenu() {
    final templates = [
      "Recuerda medir tu presión arterial dos veces al día y registrarla.",
      "Si presentas dolor de cabeza severo, zumbido de oídos o luces brillantes en la vista, acude a urgencias inmediatamente.",
      "Es importante mantener una buena hidratación. Bebe al menos 2 litros de agua diarios.",
      "Evita alimentos altos en sodio y alimentos procesados para controlar el edema.",
      "El reposo en posición lateral izquierda ayuda a mejorar el flujo sanguíneo placentario.",
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enviar Recomendación Rápida',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              ...templates.map((tpl) => Card(
                margin: EdgeInsets.only(bottom: 8),
                elevation: 0,
                color: AppColors.background,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pop(context);
                    _messageController.text = tpl;
                  },
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      tpl,
                      style: TextStyle(fontSize: 13, color: AppColors.textDark),
                    ),
                  ),
                ),
              )),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatProvider>.value(
      value: _chatProvider,
      child: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          final loginProvider = context.read<LoginProvider>();
          final currentUserId = loginProvider.userId ?? 2;
          final isDoctor = loginProvider.role?.toLowerCase().contains('doctor') ?? false;

          // Auto-scroll when messages update
          if (provider.messages.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: _buildAppBar(provider),
            body: Column(
              children: [
                // Network/Connection Alert Banner
                if (!provider.isConnected)
                  Container(
                    width: double.infinity,
                    color: Colors.orange.shade100,
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Sin conexión. Reconectando...',
                          style: TextStyle(color: Color(0xFFE65100), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                // Chat Messages List
                Expanded(
                  child: provider.isLoading
                      ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : provider.messages.isEmpty
                          ? _buildWelcomeMessage()
                          : _buildMessageList(provider.messages, currentUserId),
                ),

                // Bottom Input Control
                _buildInputBar(isDoctor),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- APP BAR BUILDER ---
  PreferredSizeWidget _buildAppBar(ChatProvider provider) {
    final initials = widget.otherUserName.length >= 2 
        ? widget.otherUserName.substring(0, 2).toUpperCase() 
        : widget.otherUserName.substring(0, 1).toUpperCase();
        
    return AppBar(
      titleSpacing: 0,
      backgroundColor: AppColors.cardBackground,
      elevation: 2,
      shadowColor: Colors.black.withAlpha(20),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.textDark),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              initials,
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: provider.isConnected ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      provider.isConnected ? 'En línea' : 'Desconectado',
                      style: TextStyle(
                        fontSize: 11,
                        color: provider.isConnected ? Colors.green.shade700 : AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline, color: AppColors.textMuted),
          onPressed: () {},
        ),
        SizedBox(width: 8),
      ],
    );
  }

  // --- WELCOME/EMPTY MESSAGE VIEW ---
  Widget _buildWelcomeMessage() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(13),
                    blurRadius: 16,
                  )
                ],
              ),
              child: Icon(
                widget.otherUserRole == 'doctor' ? Icons.medical_services_outlined : Icons.person_outline,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Conversación con ${widget.otherUserName}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
            ),
            SizedBox(height: 6),
            Text(
              'Este chat es privado y está diseñado para dar seguimiento y resolver dudas. Envía un mensaje para comenzar la conversación.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // --- MESSAGE LIST BUILDER WITH DATE HEADERS ---
  Widget _buildMessageList(List<ChatMessage> messages, int currentUserId) {
    final listItems = <Widget>[];
    DateTime? lastDate;

    for (final message in messages) {
      final messageDate = message.createdAt.toLocal();
      if (lastDate == null || 
          lastDate.year != messageDate.year || 
          lastDate.month != messageDate.month || 
          lastDate.day != messageDate.day) {
        listItems.add(_buildDateHeader(messageDate));
        lastDate = messageDate;
      }
      listItems.add(_buildMessageBubble(message, message.senderId == currentUserId));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: listItems.length,
      itemBuilder: (context, index) => listItems[index],
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final today = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    String label = '${date.day} de ${_getMonthName(date.month)}';
    
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      label = 'Hoy';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      label = 'Ayer';
    }

    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 16),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return months[month - 1];
  }

  // --- MESSAGE BUBBLE BUILDER ---
  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    final timeStr = '${message.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${message.createdAt.toLocal().minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.cardBackground,
          gradient: isMe 
              ? LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withRed(220)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textDark,
                fontSize: 14.5,
                height: 1.3,
              ),
            ),
            SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : AppColors.textMuted,
                    fontSize: 9.5,
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    color: Colors.white70,
                    size: 11,
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- INPUT CONTROL BAR BUILDER ---
  Widget _buildInputBar(bool isDoctor) {
    return Container(
      padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        children: [
          // Quick Action Shortcut Button
          GestureDetector(
            onTap: isDoctor ? _showDoctorTipsMenu : _sendLatestMeasurement,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.pink.shade50),
              ),
              child: Icon(
                isDoctor ? Icons.lightbulb_outline : Icons.assignment_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 10),
          
          // Text Input Field
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF5F5F7),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 10),
          
          // Send Button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
