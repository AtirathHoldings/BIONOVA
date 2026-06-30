import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import 'main_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _taskAssignment = true;
  bool _taskDueDate = true;
  bool _projectUpdates = true;
  bool _issueAlerts = true;
  bool _emailNotifications = false;

  void _handleNotification() {
    Navigator.pushNamed(context, '/notifications');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomHeader(
        title: 'Settings',
        automaticallyImplyLeading: false,
        onNotificationTap: _handleNotification,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                icon: Icons.notifications_none_rounded,
                iconColor: Colors.blue.shade600,
                title: 'Notification Preferences',
                subtitle: 'Choose how you want to receive notifications.',
                children: [
                  _buildSwitchTile('Task Assignment Alerts', 'Notify when you are assigned a new task.', _taskAssignment, (val) => setState(() => _taskAssignment = val)),
                  _buildSwitchTile('Task Due Date Reminders', 'Receive reminders for upcoming due dates.', _taskDueDate, (val) => setState(() => _taskDueDate = val)),
                  _buildSwitchTile('Project Updates', 'Notify about project updates and changes.', _projectUpdates, (val) => setState(() => _projectUpdates = val)),
                  _buildSwitchTile('Issue & Escalation Alerts', 'Receive notifications for issues and escalations.', _issueAlerts, (val) => setState(() => _issueAlerts = val)),
                  _buildSwitchTile('Email Notifications', 'Receive important updates via email.', _emailNotifications, (val) => setState(() => _emailNotifications = val), isLast: true),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                icon: Icons.settings_outlined,
                iconColor: Colors.indigo,
                title: 'Application Preferences',
                subtitle: 'Customize your application preferences.',
                children: [
                  _buildValueTile('Language', 'English'),
                  _buildValueTile('Date Format', 'DD-MMM-YYYY'),
                  _buildValueTile('Time Zone', '(GMT+05:30) Asia/Kolkata', isLast: true),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                icon: Icons.important_devices_rounded,
                iconColor: Colors.blueGrey,
                title: 'Login Activity',
                subtitle: 'Review your recent login activity and devices.',
                children: [
                  _buildActivityTile('Chrome - Windows', '29-May-2025 09:00 AM', 'Active', Colors.green),
                  _buildActivityTile('Android App', '28-May-2025 06:30 PM', 'Logged Out', Colors.grey),
                  _buildActivityTile('Chrome - Windows', '27-May-2025 08:15 AM', 'Logged Out', Colors.grey),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: TextButton(
                        onPressed: () {},
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
                  _buildValueTile('Application Version', 'Version 1.0.0', trailingIcon: false, isLast: true),
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

  Widget _buildSwitchTile(String title, String sub, bool value, ValueChanged<bool> onChanged, {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          trailing: Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: Colors.blue.shade600,
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
      ],
    );
  }

  Widget _buildValueTile(String title, String value, {bool trailingIcon = true, bool isLast = false}) {
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