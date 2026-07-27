import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../services/api_service.dart';
import 'main_screen.dart';

class LoginActivityScreen extends StatefulWidget {
  final List<dynamic> loginActivity;

  const LoginActivityScreen({super.key, required this.loginActivity});

  @override
  State<LoginActivityScreen> createState() => _LoginActivityScreenState();
}

class _LoginActivityScreenState extends State<LoginActivityScreen> {
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotificationCount();
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final unread = await ApiService.getUnreadNotifications();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = unread.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notification count: $e');
    }
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
    if (status == null) return const Color(0xFF2563EB);
    final s = status.toUpperCase();
    if (s.contains('COMPLETED') || s.contains('SUCCESS') || s.contains('ACTIVE')) return const Color(0xFF16A34A);
    if (s.contains('PROGRESS') || s.contains('REVIEW') || s.contains('REWORK')) return const Color(0xFFF59E0B);
    if (s.contains('HOLD') || s.contains('LOGGED OUT') || s.contains('LOGOUT')) return const Color(0xFF7C3AED);
    return const Color(0xFF2563EB);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomHeader(
        title: 'Login Activity',
        automaticallyImplyLeading: false,
        notificationCount: _unreadNotificationCount,
        onNotificationTap: () async {
          await Navigator.pushNamed(context, '/notifications');
          _fetchNotificationCount(); // refresh count after returning
        },
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Back button row (same style as Task Details) ─────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
              child: TextButton.icon(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/main');
                  }
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: Color(0xFF1E293B),
                ),
                label: const Text(
                  'Back',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // ── Main content ─────────────────────────────────────────
            Expanded(
              child: widget.loginActivity.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_outlined,
                        size: 48,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No login activity found.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your login history will appear here.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header summary bar ───────────────────────────────────
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security_outlined, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Login Sessions',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${widget.loginActivity.length} session${widget.loginActivity.length != 1 ? 's' : ''} recorded',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.loginActivity.length}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Activity list ────────────────────────────────────────
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: widget.loginActivity.length,
                      itemBuilder: (context, index) {
                        final activity = widget.loginActivity[index];
                        final String device = activity['deviceInfo'] ?? 'Unknown Device';
                        final String dateTime = _formatDateTime(activity['loginDt']);
                        final String status = activity['status'] ?? 'Logged Out';
                        final Color statusColor = _getStatusColor(status);
                        final bool isLatest = index == 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isLatest
                                  ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                                  : const Color(0xFFF1F5F9),
                              width: isLatest ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isLatest
                                        ? const Color(0xFFEEF2FF)
                                        : const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    device.contains('Chrome') || device.contains('Mac') || device.contains('Windows')
                                        ? Icons.laptop_mac_rounded
                                        : Icons.phone_android_rounded,
                                    color: isLatest
                                        ? const Color(0xFF6366F1)
                                        : const Color(0xFF64748B),
                                    size: 20,
                                  ),
                                ),
                                if (isLatest)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF22C55E),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    device,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isLatest)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Latest',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF6366F1),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_outlined, size: 11, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateTime,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                status,
                                style: GoogleFonts.inter(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),   // closes Expanded
          ],
        ), // closes Column
      ),   // closes SafeArea
      bottomNavigationBar: CustomFooter(
        currentIndex: 4, // Menu tab
        onTabSelected: (index) {
          if (MainScreen.navigatorKey.currentState != null) {
            MainScreen.navigatorKey.currentState!.changeTab(index);
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
      ),
    );
  }
}
