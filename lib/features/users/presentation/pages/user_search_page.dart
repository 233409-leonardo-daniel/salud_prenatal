import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/user_provider.dart';

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
    if (_isDoctor) {
      context.read<UserProvider>().loadDoctors();
    } else {
      context.read<UserProvider>().loadPatients();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('Directorio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
    if (provider.viewState == UserViewState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (provider.viewState == UserViewState.error) {
      return Center(child: Text('Error: ${provider.error}'));
    }
    
    if (provider.users.isEmpty) {
      return const Center(
        child: Text('No se encontraron usuarios.', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.users.length,
      itemBuilder: (context, index) {
        final user = provider.users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFFF0F6),
              backgroundImage: user.profilePicture != null ? NetworkImage(user.profilePicture!) : null,
              child: user.profilePicture == null ? const Icon(Icons.person, color: AppColors.primary) : null,
            ),
            title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
            subtitle: Text(user.email),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
            onTap: () {
              // Return selected user or open their profile
              Navigator.pop(context, user);
            },
          ),
        );
      },
    );
  }
}
