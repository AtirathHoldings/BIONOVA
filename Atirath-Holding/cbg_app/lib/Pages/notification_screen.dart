import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/header.dart';      
import '../widgets/footer.dart';      
import '../services/api_service.dart';
import 'main_screen.dart';

// ============================================
// NOTIFICATION MODEL
// ============================================
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String category; // task, comment, progress, system, document
  final String priority; // critical, high, medium, low, info
  final String icon;
  final Color color;
  final String? taskId;
  final String? projectId;
  final String? userId;
  final String projectTag;
  final DateTime timestamp;
  final bool isRead;
  final bool isArchived;
  final List<QuickAction> quickActions;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.priority,
    required this.icon,
    required this.color,
    this.taskId,
    this.projectId,
    this.userId,
    required this.projectTag,
    required this.timestamp,
    this.isRead = false,
    this.isArchived = false,
    this.quickActions = const [],
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json, {VoidCallback? onMarkRead}) {
    final title = json['title'] ?? '';
    final message = json['message'] ?? '';
    
    // Category mapping based on content keywords
    String category = 'system';
    final lowerTitle = title.toLowerCase();
    final lowerMsg = message.toLowerCase();
    
    if (lowerTitle.contains('overdue') || lowerTitle.contains('escalat') || 
        lowerMsg.contains('overdue') || lowerMsg.contains('escalat')) {
      category = 'critical';
    } else if (lowerTitle.contains('task') || lowerTitle.contains('assign') || 
               lowerMsg.contains('task') || lowerMsg.contains('assign')) {
      category = 'tasks';
    } else if (lowerTitle.contains('comment') || lowerMsg.contains('comment')) {
      category = 'comments';
    } else if (lowerTitle.contains('progress') || lowerTitle.contains('milestone') || 
               lowerMsg.contains('progress') || lowerMsg.contains('milestone')) {
      category = 'progress';
    } else if (lowerTitle.contains('document') || lowerTitle.contains('file') || 
               lowerMsg.contains('document') || lowerMsg.contains('file') || 
               lowerMsg.contains('upload')) {
      category = 'document';
    }

    // Priority mapping based on keywords
    String priority = 'info';
    if (category == 'critical') {
      priority = 'critical';
    } else if (lowerTitle.contains('high') || lowerMsg.contains('high') || 
               lowerTitle.contains('urgent') || lowerMsg.contains('urgent')) {
      priority = 'high';
    } else if (lowerTitle.contains('medium') || lowerMsg.contains('medium') || 
               lowerTitle.contains('normal') || lowerMsg.contains('normal')) {
      priority = 'medium';
    } else if (lowerTitle.contains('low') || lowerMsg.contains('low')) {
      priority = 'low';
    }

    // Icon mapping
    String icon = 'bell';
    if (priority == 'critical') {
      icon = 'exclamation-triangle';
    } else if (category == 'tasks') {
      if (lowerMsg.contains('complet')) {
        icon = 'check-circle';
      } else {
        icon = 'tasks';
      }
    } else if (category == 'comments') {
      icon = 'comment';
    } else if (category == 'progress') {
      if (lowerMsg.contains('milestone')) {
        icon = 'flag-checkered';
      } else {
        icon = 'chart-line';
      }
    } else if (category == 'document') {
      icon = 'file-upload';
    }

    // Color mapping
    Color color = const Color(0xFF0EA5E9); // sky blue for info/system
    if (priority == 'critical') {
      color = const Color(0xFFEF4444); // red
    } else if (priority == 'high') {
      color = const Color(0xFFF59E0B); // orange
    } else if (priority == 'medium') {
      color = category == 'comments' ? const Color(0xFF8B5CF6) : const Color(0xFF2563EB); // purple or blue
    } else if (priority == 'low') {
      color = const Color(0xFF10B981); // green
    }

    // Project tag extraction (e.g. PRJ-001)
    String projectTag = 'General';
    final regExp = RegExp(r'PRJ-\d+');
    final match = regExp.firstMatch('$title $message');
    if (match != null) {
      projectTag = match.group(0)!;
    }

    // Parse timestamp
    DateTime timestamp = DateTime.now();
    if (json['createdAt'] != null) {
      timestamp = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    }

    // Generate quick actions
    final List<QuickAction> quickActions = [];
    if (!(json['isRead'] ?? false) && onMarkRead != null) {
      quickActions.add(
        QuickAction(
          label: 'Mark Read',
          icon: Icons.check,
          color: const Color(0xFF10B981),
          onTap: onMarkRead,
        ),
      );
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: title,
      message: message,
      category: category,
      priority: priority,
      icon: icon,
      color: color,
      projectTag: projectTag,
      timestamp: timestamp,
      isRead: json['isRead'] ?? false,
      isArchived: false,
      quickActions: quickActions,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// ============================================
// QUICK ACTION MODEL
// ============================================
class QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

// ============================================
// MAIN NOTIFICATION SCREEN
// ============================================
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'All';
  bool _isCompactView = false;
  late TabController _tabController;
  int _currentIdx = -1; // 👇 ఫుటర్ ఇండెక్స్ ట్రాక్ చేయడానికి

  // Sample Notifications Data
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isLoading = true;
  String? _error;

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final List<dynamic> rawNotifications = await ApiService.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = rawNotifications.map((json) {
          final idVal = json['id'] as int? ?? 0;
          return NotificationModel.fromJson(
            json,
            onMarkRead: () => _handleMarkRead(idVal),
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleMarkRead(int id) async {
    final success = await ApiService.markNotificationAsRead(id);
    if (success) {
      _fetchNotifications();
      _showSnackBar('✅ Notification marked as read');
    } else {
      _showSnackBar('❌ Failed to mark notification as read');
    }
  }

  // ============================================
  // HANDLER METHODS
  // ============================================

  void _handleViewTask(String taskName) {
    _showSnackBar('📋 Opening task: $taskName');
  }

  void _handleViewProject(String projectName) {
    _showSnackBar('🏗️ Opening project: $projectName');
  }

  void _handleViewDocument(String docName) {
    _showSnackBar('📄 Opening document: $docName');
  }

  void _handleAccept(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          category: _notifications[index].category,
          priority: _notifications[index].priority,
          icon: _notifications[index].icon,
          color: _notifications[index].color,
          taskId: _notifications[index].taskId,
          projectId: _notifications[index].projectId,
          userId: _notifications[index].userId,
          projectTag: _notifications[index].projectTag,
          timestamp: _notifications[index].timestamp,
          isRead: true,
          isArchived: _notifications[index].isArchived,
          quickActions: _notifications[index].quickActions,
        );
      }
    });
    _showSnackBar('✅ Task accepted!');
  }

  void _handleDecline(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    _showSnackBar('❌ Task declined');
  }

  void _handleApprove(String id) {
    _showSnackBar('✅ Task approved!');
  }

  void _handleReply(String id) {
    _showSnackBar('💬 Replying to comment...');
  }

  void _handleResolve(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          category: _notifications[index].category,
          priority: _notifications[index].priority,
          icon: _notifications[index].icon,
          color: _notifications[index].color,
          taskId: _notifications[index].taskId,
          projectId: _notifications[index].projectId,
          userId: _notifications[index].userId,
          projectTag: _notifications[index].projectTag,
          timestamp: _notifications[index].timestamp,
          isRead: true,
          isArchived: _notifications[index].isArchived,
          quickActions: _notifications[index].quickActions,
        );
      }
    });
    _showSnackBar('✅ Escalation resolved!');
  }

  void _handleDismiss(String id) async {
    final idInt = int.tryParse(id);
    if (idInt != null) {
      await ApiService.markNotificationAsRead(idInt);
    }
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    _showSnackBar('🗑️ Notification dismissed');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ============================================
  // GETTERS
  // ============================================

  int get _unreadCount {
    return _notifications.where((n) => !n.isRead).length;
  }

  List<NotificationModel> get _filteredNotifications {
    if (_selectedFilter == 'All') {
      return _notifications;
    } else if (_selectedFilter == 'Unread') {
      return _notifications.where((n) => !n.isRead).toList();
    } else if (_selectedFilter == 'Critical') {
      return _notifications
          .where((n) => n.priority == 'critical' || n.category == 'critical')
          .toList();
    } else if (_selectedFilter == 'Tasks') {
      return _notifications.where((n) => n.category == 'tasks').toList();
    } else if (_selectedFilter == 'Comments') {
      return _notifications.where((n) => n.category == 'comments').toList();
    } else if (_selectedFilter == 'Progress') {
      return _notifications.where((n) => n.category == 'progress').toList();
    }
    return _notifications;
  }

  Map<String, List<NotificationModel>> get _groupedNotifications {
    final grouped = <String, List<NotificationModel>>{};
    final now = DateTime.now();

    for (var notification in _filteredNotifications) {
      String key;
      final diff = now.difference(notification.timestamp);

      if (diff.inDays == 0) {
        key = 'Today';
      } else if (diff.inDays == 1) {
        key = 'Yesterday';
      } else if (diff.inDays <= 7) {
        key = 'Earlier This Week';
      } else if (diff.inDays <= 14) {
        key = 'Last Week';
      } else {
        key = 'Older';
      }

      grouped.putIfAbsent(key, () => []).add(notification);
    }

    return grouped;
  }

  // ============================================
  // ICON HELPERS
  // ============================================

  IconData _getIconForNotification(String iconName) {
    switch (iconName) {
      case 'exclamation-triangle':
        return Icons.warning_amber_rounded;
      case 'check-circle':
        return Icons.check_circle;
      case 'tasks':
        return Icons.task_alt;
      case 'comment':
        return Icons.comment;
      case 'chart-line':
        return Icons.show_chart;
      case 'file-upload':
        return Icons.upload_file;
      case 'exchange-alt':
        return Icons.swap_horiz;
      case 'flag-checkered':
        return Icons.flag;
      case 'clock':
        return Icons.access_time;
      case 'arrow-up':
        return Icons.trending_up;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconBackgroundColor(String priority) {
    switch (priority) {
      case 'critical':
        return const Color(0xFFFEF2F2);
      case 'high':
        return const Color(0xFFFFF7ED);
      case 'medium':
        return const Color(0xFFEFF6FF);
      case 'low':
        return const Color(0xFFECFDF5);
      case 'info':
        return const Color(0xFFF0F9FF);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF59E0B);
      case 'medium':
        return const Color(0xFF2563EB);
      case 'low':
        return const Color(0xFF10B981);
      case 'info':
        return const Color(0xFF0EA5E9);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getPriorityLabel(String priority) {
    return priority.toUpperCase();
  }

  // ============================================
  // BUILD METHOD
  // ============================================

  @override
  Widget build(BuildContext context) {
    final groupedNotifications = _groupedNotifications;
    final keys = groupedNotifications.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // ============================================
      // CUSTOM APP BAR / HEADER SECTION
      // ============================================
      appBar: CustomHeader(
        title: "Notifications", // బ్యాక్ బటన్ ఆటోమేటిక్‌గా వస్తుంది
      ),
      
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterBar(),
          // Notification List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : keys.isEmpty
                        ? _buildEmptyState()
                        : _buildNotificationList(keys, groupedNotifications),
          ),
        ],
      ),

      // ============================================
      // CUSTOM FOOTER / BOTTOM NAV SECTION
      // ============================================
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: true,
        child: CustomFooter(
          currentIndex: _currentIdx,
          onTabSelected: (index) {
            if (MainScreen.navigatorKey.currentState != null) {
              MainScreen.navigatorKey.currentState!.changeTab(index);
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          },
        ),
      ),
    );
  }

  // ============================================
  // FILTER BAR
  // ============================================

  Widget _buildFilterBar() {
    final filters = ['All', 'Unread', 'Critical', 'Tasks', 'Comments', 'Progress'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        if (filter == 'Critical')
                          const Icon(Icons.warning_amber_rounded,
                              size: 12, color: Colors.white),
                        if (filter == 'Unread')
                          const Icon(Icons.circle,
                              size: 10, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          filter,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                        if (filter == 'Unread' && _unreadCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.3)
                                  : const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_unreadCount',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          // View Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isCompactView = !_isCompactView;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isCompactView
                            ? Icons.view_list
                            : Icons.view_agenda,
                        size: 16,
                        color: const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isCompactView ? 'Compact' : 'Normal',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // NOTIFICATION LIST
  // ============================================

  Widget _buildNotificationList(
    List<String> keys,
    Map<String, List<NotificationModel>> grouped,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final notifications = grouped[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Row(
              children: [
                Text(
                  '📅 $key',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${notifications.length}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Notifications
            ...notifications.map((notification) {
              return _buildNotificationCard(notification);
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // ============================================
  // NOTIFICATION CARD
  // ============================================

  Widget _buildNotificationCard(NotificationModel notification) {
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _handleDismiss(notification.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () async {
          if (isUnread) {
            final idInt = int.tryParse(notification.id);
            if (idInt != null) {
              final success = await ApiService.markNotificationAsRead(idInt);
              if (success) {
                _fetchNotifications();
              }
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnread ? const Color(0xFFBFDBFE) : const Color(0xFFF1F5F9),
              width: isUnread ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getIconBackgroundColor(notification.priority),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getIconForNotification(notification.icon),
                  color: notification.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Priority Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(notification.priority)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getPriorityLabel(notification.priority),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _getPriorityColor(notification.priority),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Message
                    if (!_isCompactView) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ],
                    // Meta Info
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        // Project Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            notification.projectTag,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Time
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time,
                                size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(
                              notification.timeAgo,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Quick Actions
                    if (notification.quickActions.isNotEmpty &&
                        !_isCompactView) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: notification.quickActions.map((action) {
                          return GestureDetector(
                            onTap: action.onTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: action.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: action.color.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    action.icon,
                                    size: 12,
                                    color: action.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    action.label,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: action.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              // Unread Dot
              if (isUnread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // EMPTY STATE
  // ============================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off,
              size: 50,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up! 🎉',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}