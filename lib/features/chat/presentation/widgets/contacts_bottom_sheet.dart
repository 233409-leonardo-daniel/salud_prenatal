import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/contacts_provider.dart';
import '../pages/chat_room_page.dart';
import 'pulsing_skeleton.dart';

void showContactsBottomSheet(BuildContext context, {VoidCallback? onReturn}) {
  context.read<ContactsProvider>().loadContacts();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
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
                color: AppColors.textMuted.withOpacity(0.3),
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
              child: Consumer<ContactsProvider>(
                builder: (context, contactsProvider, _) {
                  if (contactsProvider.status == ContactsStatus.initial ||
                      contactsProvider.status == ContactsStatus.loading) {
                    return const _ContactsSkeletonList();
                  }

                  if (contactsProvider.status == ContactsStatus.error) {
                    return Center(
                      child: Text(
                        contactsProvider.errorMessage ?? 'Error al cargar contactos.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    );
                  }

                  final availableContacts = contactsProvider.contacts;
                  if (availableContacts.isEmpty) {
                    return Center(
                      child: Text(
                        'No hay contactos registrados.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: availableContacts.length,
                    itemBuilder: (context, index) {
                      final contactUser = availableContacts[index];
                      final isDoc = contactUser.role.toLowerCase().contains('doctor');
                      final isReceptionist = contactUser.role.toLowerCase() == 'receptionist' ||
                          contactUser.role.toLowerCase() == 'recepcionista';
                      final fullName = isDoc
                          ? 'Dra. ${contactUser.name} ${contactUser.lastName}'.trim()
                          : (isReceptionist
                              ? 'Recepcionista: ${contactUser.name} ${contactUser.lastName}'.trim()
                              : '${contactUser.name} ${contactUser.lastName}'.trim());
                      final initials =
                          '${contactUser.name.isNotEmpty ? contactUser.name[0] : 'U'}${contactUser.lastName.isNotEmpty ? contactUser.lastName[0] : ''}';

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
                            onReturn?.call();
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Skeleton del diálogo de contactos: bloques simples, esa lista no tiene
/// avatar/subtítulo.
class _ContactsSkeletonList extends StatelessWidget {
  const _ContactsSkeletonList();

  @override
  Widget build(BuildContext context) {
    return PulsingSkeleton(
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        margin: EdgeInsets.only(bottom: 12),
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.skeletonBase,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
