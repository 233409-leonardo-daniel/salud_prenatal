import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/user_provider.dart';

import '../../../login/presentation/providers/login_provider.dart';
import '../../../chat/presentation/pages/chat_detail_page.dart';

class UserSearchPage extends StatefulWidget {
  final bool initialIsDoctor;

  const UserSearchPage({super.key, this.initialIsDoctor = true});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  late bool _isDoctor;

  @override
  void initState() {
    super.initState();
    _isDoctor = widget.initialIsDoctor;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final loginProvider = context.read<LoginProvider>();
    final isReceptionist = loginProvider.role == 'receptionist' || loginProvider.role == 'recepcionista';
    final docId = isReceptionist ? loginProvider.doctorId : null;

    if (_isDoctor) {
      context.read<UserProvider>().loadDoctors(singleDoctorId: docId);
    } else {
      context.read<UserProvider>().loadPatients(doctorId: docId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: Text('Directorio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTab('Doctores', _isDoctor, () {
                  setState(() => _isDoctor = true);
                  _loadData();
                }),
                _buildTab('Pacientes', !_isDoctor, () {
                  setState(() => _isDoctor = false);
                  _loadData();
                }),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(UserProvider provider) {
    switch (provider.viewState) {
      case UserViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case UserViewState.error:
        return Center(child: Text('Error: ${provider.error}'));
      case UserViewState.initial:
      case UserViewState.success:
        if (provider.users.isEmpty) {
          return Center(
            child: Text('No se encontraron usuarios.', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
          );
        }
        break;
    }
    
    var displayUsers = provider.users;
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: displayUsers.length,
      itemBuilder: (context, index) {
        final user = displayUsers[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFFF0F6),
              backgroundImage: user.profilePicture != null ? NetworkImage(user.profilePicture!) : null,
              child: user.profilePicture == null ? Icon(Icons.person, color: AppColors.primary) : null,
            ),
            title: Text(user.fullName, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
            subtitle: Text(user.email),
            trailing: IconButton(
              icon: Icon(Icons.chat, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailPage(
                      otherUserId: user.id,
                      otherUserName: user.fullName,
                    ),
                  ),
                );
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailPage(
                    otherUserId: user.id,
                    otherUserName: user.fullName,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
