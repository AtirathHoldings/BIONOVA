import 'package:flutter/material.dart';
import '../widgets/header.dart';
import 'settings_screen.dart';
import 'main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {

  final List<Map<String, dynamic>> menuItems = [
    {'title': 'My Projects', 'icon': Icons.folder_shared_outlined, 'color': Colors.blueAccent, 'target': 'projects'},
    {'title': 'My Tasks', 'icon': Icons.check_box_outlined, 'color': Colors.deepPurpleAccent, 'target': 'tasks'},
    {'title': 'Calendar', 'icon': Icons.calendar_today_outlined, 'color': const Color(0xFFF59E0B), 'target': 'calendar'},
    {'title': 'Settings', 'icon': Icons.settings_outlined, 'color': Colors.grey.shade700, 'target': 'settings'},
    {'title': 'Logout', 'icon': Icons.logout_outlined, 'color': Colors.red, 'target': 'logout'},
  ];

  void _handleNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications clicked')),
    );
  }

  void _navigateToScreen(String target) {
    switch (target) {
      case 'dashboard':
        if (MainScreen.navigatorKey.currentState != null) {
          MainScreen.navigatorKey.currentState!.changeTab(0);
        }
        break;
      case 'projects':
        if (MainScreen.navigatorKey.currentState != null) {
          MainScreen.navigatorKey.currentState!.changeTab(1);
        }
        break;
      case 'tasks':
        if (MainScreen.navigatorKey.currentState != null) {
          MainScreen.navigatorKey.currentState!.changeTab(2);
        }
        break;
      case 'calendar':
        if (MainScreen.navigatorKey.currentState != null) {
          MainScreen.navigatorKey.currentState!.changeTab(3);
        }
        break;
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userRole');
    await prefs.remove('userEmail');
    await prefs.remove('currentEmpId');

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/signin', 
        (route) => false
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: CustomHeader(
        title: 'Menu',
        automaticallyImplyLeading: false,
        onNotificationTap: _handleNotification,
      ),
      body: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: menuItems.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
        itemBuilder: (context, index) {
          final item = menuItems[index];
          final isLogout = item['target'] == 'logout';
          
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (item['color'] as Color).withValues(alpha: 0.1),
                shape: BoxShape.circle
              ),
              child: Icon(
                item['icon'] as IconData, 
                color: isLogout ? Colors.red : item['color'] as Color, 
                size: 18
              ),
            ),
            title: Text(
              item['title'] as String,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: isLogout ? Colors.red : const Color(0xFF1E293B),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right, 
              size: 16, 
              color: isLogout ? Colors.red : Colors.grey
            ),
            onTap: () {
              _navigateToScreen(item['target'] as String);
            },
          );
        },
      ),
    );
  }
}