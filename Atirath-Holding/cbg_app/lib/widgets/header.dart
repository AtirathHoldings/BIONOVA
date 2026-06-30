import 'package:flutter/material.dart';
import 'dart:io';

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
            'assets/BioNova.png',
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
        if (onNotificationTap != null)
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none,
                  color: Color(0xFF64748B),
                ),
                onPressed: onNotificationTap,
              ),
              // Badge - Show only if count > 0
              if (notificationCount != null && notificationCount! > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        notificationCount! > 9 ? '9+' : '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        
        // Profile Icon with Image Support
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/profile');
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6C4EFF),
              backgroundImage: profileImagePath != null && profileImagePath!.isNotEmpty
                  ? FileImage(File(profileImagePath!)) as ImageProvider
                  : null,
              child: profileImagePath == null || profileImagePath!.isEmpty
                  ? const Icon(Icons.person, size: 18, color: Colors.white)
                  : null,
            ),
          ),
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