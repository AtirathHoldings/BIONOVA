import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import 'main_screen.dart';
import '../services/api_service.dart';
import 'login_activity_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _unreadNotificationCount = 0;
  bool _isLoading = false;
  Map<String, dynamic> _preferences = {
    'dateFormat': 'DD-MMM-YYYY',
    'timeZone': 'Asia/Kolkata',
    'theme': 'Light',
  };
  List<dynamic> _loginActivity = [];
  Map<String, dynamic> _supportAndAbout = {};

  @override
  void initState() {
    super.initState();
    _fetchNotificationCount();
    _loadSettings();
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final unreadNotifications = await ApiService.getUnreadNotifications();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadNotifications.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notification count: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ApiService.getSettings();
      if (settings != null && mounted) {
        setState(() {
          if (settings['preferences'] != null) {
            _preferences = Map<String, dynamic>.from(settings['preferences']);
          }
          if (settings['loginActivity'] != null) {
            _loginActivity = List<dynamic>.from(settings['loginActivity']);
          }
          if (settings['supportAndAbout'] != null) {
            _supportAndAbout = Map<String, dynamic>.from(settings['supportAndAbout']);
          }
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePreference(String key, String value) async {
    final updatedPreferences = Map<String, dynamic>.from(_preferences);
    updatedPreferences[key] = value;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Updating preference...'),
        duration: Duration(milliseconds: 500),
      ),
    );

    final success = await ApiService.updateSettings(updatedPreferences);
    if (mounted) {
      if (success) {
        setState(() {
          _preferences = updatedPreferences;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Preferences updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to update preferences.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }



  void _changeDateFormat() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Select Date Format', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            ...['DD-MMM-YYYY', 'YYYY-MM-DD', 'DD/MM/YYYY'].map((format) {
              return ListTile(
                title: Text(format, style: const TextStyle(fontSize: 14)),
                trailing: _preferences['dateFormat'] == format ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  Navigator.pop(context);
                  _savePreference('dateFormat', format);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _changeTimeZone() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Select Time Zone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            ...['Asia/Kolkata', 'UTC', 'America/New_York', 'Europe/London'].map((tz) {
              return ListTile(
                title: Text(tz, style: const TextStyle(fontSize: 14)),
                trailing: _preferences['timeZone'] == tz ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  Navigator.pop(context);
                  _savePreference('timeZone', tz);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '';
    try {
      if (dateTime is String) {
        final parsed = DateTime.parse(dateTime);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final day = parsed.day.toString().padLeft(2, '0');
        final month = months[parsed.month - 1];
        final year = parsed.year;
        final hourNum = parsed.hour > 12 ? parsed.hour - 12 : (parsed.hour == 0 ? 12 : parsed.hour);
        final hour = hourNum.toString().padLeft(2, '0');
        final minute = parsed.minute.toString().padLeft(2, '0');
        final period = parsed.hour >= 12 ? 'PM' : 'AM';
        return '$day-$month-$year $hour:$minute $period';
      }
      return dateTime.toString();
    } catch (_) {
      return dateTime.toString();
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return const Color(0xFF2563EB); // BLUE (OPEN)
    final s = status.toUpperCase();
    if (s.contains('CLOSED') || s.contains('COMPLETED')) return const Color(0xFF16A34A); // GREEN
    if (s.contains('PROGRESS') || s.contains('REVIEW') || s.contains('REWORK')) return const Color(0xFFF59E0B); // AMBER
    if (s.contains('HOLD')) return const Color(0xFF7C3AED); // PURPLE
    return const Color(0xFF2563EB); // BLUE (OPEN)
  }

  void _handleNotification() async {
    await Navigator.pushNamed(context, '/notifications');
    _fetchNotificationCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomHeader(
        title: 'Settings',
        automaticallyImplyLeading: false,
        notificationCount: _unreadNotificationCount,
        onNotificationTap: _handleNotification,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 32.0),
                      child: Text(
                        'Manage your preferences and application settings.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildSectionCard(
                      icon: Icons.settings_outlined,
                      iconColor: Colors.indigo,
                      title: 'Application Preferences',
                      subtitle: 'Customize your application preferences.',
                      children: [
                        _buildValueTile(
                          'Date Format',
                          _preferences['dateFormat'] ?? 'DD-MMM-YYYY',
                          onTap: _changeDateFormat,
                        ),
                        _buildValueTile(
                          'Time Zone',
                          _preferences['timeZone'] ?? 'Asia/Kolkata',
                          isLast: true,
                          onTap: _changeTimeZone,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      icon: Icons.important_devices_rounded,
                      iconColor: Colors.blueGrey,
                      title: 'Login Activity',
                      subtitle: 'Review your recent login activity and devices.',
                      children: [
                        if (_loginActivity.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: Text(
                                'No login activity found.',
                                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                              ),
                            ),
                          )
                        else
                          ..._loginActivity.take(3).map((activity) {
                            return _buildActivityTile(
                              activity['deviceInfo'] ?? 'Unknown Device',
                              _formatDateTime(activity['loginDt']),
                              activity['status'] ?? 'Logged Out',
                              _getStatusColor(activity['status']),
                            );
                          }),
                        if (_loginActivity.length > 3)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginActivityScreen(loginActivity: _loginActivity),
                                    ),
                                  );
                                },
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('View full login activity', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward, size: 14, color: Colors.blue),
                                  ],
                                ),
                              ),
                            ),
                          )
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      icon: Icons.help_outline_rounded,
                      iconColor: Colors.teal,
                      title: 'Support & About',
                      subtitle: 'Get help and view system information.',
                      children: [
                        _buildNavigationTile(Icons.help_outline, 'Help Center'),
                        _buildNavigationTile(Icons.headset_mic_outlined, 'Contact Administrator'),
                        _buildNavigationTile(Icons.description_outlined, 'User Guide'),
                        _buildValueTile(
                          'Application Version',
                          _supportAndAbout['appVersion'] ?? 'Version 1.0.0',
                          trailingIcon: false,
                          isLast: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: CustomFooter(
        currentIndex: 4,
        onTabSelected: (index) {
          if (MainScreen.navigatorKey.currentState != null) {
            MainScreen.navigatorKey.currentState!.changeTab(index);
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
      ),
    );
  }

  // ... (keep all your helper methods)
  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          maintainState: true,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          title: Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          children: [
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ...children,
          ],
        ),
      ),
    );
  }


  Widget _buildValueTile(String title, String value, {bool trailingIcon = true, bool isLast = false, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: TextStyle(fontSize: 12.5, color: trailingIcon ? const Color(0xFF1E293B) : const Color(0xFF64748B), fontWeight: FontWeight.w500)),
              if (trailingIcon) ...[
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
              ]
            ],
          ),
          onTap: onTap,
        ),
        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
      ],
    );
  }

  Widget _buildNavigationTile(IconData icon, String title) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, size: 18, color: const Color(0xFF64748B)),
          horizontalTitleGap: -4,
          title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
          trailing: const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
          onTap: () {},
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
      ],
    );
  }

  Widget _buildActivityTile(String device, String dateTime, String status, Color statusColor) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            device.contains('Chrome') ? Icons.laptop_mac_rounded : Icons.phone_android_rounded,
            color: const Color(0xFF64748B),
            size: 20,
          ),
          title: Text(device, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          subtitle: Text(dateTime, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
      ],
    );
  }
}