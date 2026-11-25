import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onNotificationTap;
  final bool automaticallyImplyLeading;
  final String? profileImagePath;
  final int? notificationCount; // Added notification count

  const CustomHeader({
    super.key,
    required this.title,
    this.onNotificationTap,
    this.automaticallyImplyLeading = false,
    this.profileImagePath,
    this.notificationCount, // Optional notification count
  });

  Widget _buildBellBadge(int count) {
    if (count <= 0) return const SizedBox.shrink();
    final bool isPlus = count > 9;
    return Positioned(
      top: -3,
      right: -3,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isPlus ? 4 : 2, vertical: 1.5),
        constraints: const BoxConstraints(
          minWidth: 16,
          minHeight: 16,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Center(
          child: Text(
            isPlus ? '9+' : '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBellButton(BuildContext context, int count) {
    return GestureDetector(
      onTap: onNotificationTap ?? () {
        Navigator.pushNamed(context, '/notifications');
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF475569),
              size: 20,
            ),
          ),
          _buildBellBadge(count),
        ],
      ),
    );
  }

  String _getInitials(String? nameStr) {
    if (nameStr == null || nameStr.trim().isEmpty) return 'U';
    final nameParts = nameStr.trim().split(RegExp(r'[\s._]+')).where((p) => p.isNotEmpty).toList();
    if (nameParts.isEmpty) return 'U';
    if (nameParts.length >= 2) {
      return (nameParts[0][0] + nameParts[nameParts.length - 1][0]).toUpperCase();
    }
    return nameParts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Row(
        children: [
          // Logo
          Image.asset(
            'assets/BioNova.webp',
            height: 32,
            width: 32,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C4EFF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text(
                    'CBG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          // Screen Title
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        // Notification Icon with Badge
        if (notificationCount != null && notificationCount! > 0)
          _buildBellButton(context, notificationCount!)
        else
          FutureBuilder<List<dynamic>>(
            future: ApiService.getUnreadNotifications(),
            builder: (context, snapshot) {
              final unread = (snapshot.hasData && snapshot.data != null) ? snapshot.data!.length : 0;
              return _buildBellButton(context, unread);
            },
          ),
        const SizedBox(width: 8),
        
        // Profile Icon with Image and Letter Initials Support (matching Web Header)
        FutureBuilder<Map<String, String?>>(
          future: SharedPreferences.getInstance().then((prefs) {
            final photo = prefs.getString('profilePhotoUrl');
            String? name = prefs.getString('userName') ??
                           prefs.getString('fullName') ??
                           prefs.getString('cache_userName') ??
                           prefs.getString('employeeName');
            if (name == null || name.trim().isEmpty || name == 'Welcome!' || name == 'Reviewer') {
              final email = prefs.getString('userEmail') ?? prefs.getString('savedEmail');
              if (email != null && email.isNotEmpty) {
                final namePart = email.split('@').first;
                name = namePart
                    .split(RegExp(r'[._]'))
                    .where((w) => w.isNotEmpty)
                    .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
                    .join(' ');
              }
            }
            return {
              'photo': photo,
              'name': name,
            };
          }),
          builder: (context, snapshot) {
            final path = snapshot.data?['photo'] ?? profileImagePath;
            final name = snapshot.data?['name'];
            final initials = _getInitials(name);
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: path != null && path.isNotEmpty
                        ? Image(
                            image: (path.startsWith('http')
                                ? NetworkImage(path)
                                : path.startsWith('data:image')
                                    ? MemoryImage(base64Decode(path.split(',').last))
                                    : FileImage(File(path))) as ImageProvider,
                            fit: BoxFit.cover,
                            width: 34,
                            height: 34,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: const Color(0xFFF1F5F9),
          height: 1,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}