import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/header.dart';      
import '../widgets/footer.dart';      
import '../services/api_service.dart';
import '../models/task_item.dart';
import 'main_screen.dart';

// ============================================
// NOTIFICATION MODEL
// ============================================
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String category;
  final String priority;
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

  factory NotificationModel.fromJson(Map<String, dynamic> json, {VoidCallback? onMarkRead, Map<String, String>? taskNamesMap}) {
    String title = json['title'] ?? '';
    String message = json['message'] ?? '';
    
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

    Color color = const Color(0xFF0EA5E9); 
    if (priority == 'critical') {
      color = const Color(0xFFEF4444); 
    } else if (priority == 'high') {
      color = const Color(0xFFF59E0B); 
    } else if (priority == 'medium') {
      color = category == 'comments' ? const Color(0xFF8B5CF6) : const Color(0xFF2563EB); 
    } else if (priority == 'low') {
      color = const Color(0xFF10B981); 
    }

    String? tId =
        json['taskId']?.toString() ??
        json['entityId']?.toString();

    // Fallback: extract TSK code from title/message if no explicit ID
    if (tId == null) {
      final tskExtractRegex = RegExp(r'TSK-?(\d+)');
      final match = tskExtractRegex.firstMatch('$title $message');
      if (match != null) {
        tId = match.group(1);
      }
    }

    // ── Stage 1: Resolve task name ──────────────────────────────────────────
    String? taskName;

    // From taskNamesMap (fetched via entityId → getLiveTask)
    if (tId != null && taskNamesMap != null && taskNamesMap.containsKey(tId)) {
      taskName = taskNamesMap[tId];
    }

    // Fallback: extract task name already embedded in the message
    // Pattern: The task 'Name' (TSK...) or task 'Name'
    if (taskName == null || taskName.isEmpty) {
      final nameInMsg = RegExp(r"task '([^']+)'").firstMatch(message)?.group(1);
      if (nameInMsg != null && nameInMsg.isNotEmpty) {
        taskName = nameInMsg;
      }
    }

    // ── Stage 2: Apply replacements ─────────────────────────────────────────
    debugPrint('[NOTIF-DEBUG] raw title="${json['title']}" raw message="${json['message']}" entityId=${json['entityId']} tId=$tId taskName=$taskName');

    if (taskName != null && taskName.isNotEmpty) {
      if (tId != null) category = 'tasks';

      final tskRegex = RegExp(r'TSK[-\s]?\d+');

      // Title: handle known patterns cleanly
      if (title.contains('Overdue Reminder')) {
        title = '🚨 Overdue Reminder: $taskName';
      } else if (title.contains('Task Update') || title.contains('task update')) {
        title = '📋 Task Update: $taskName';
      } else if (title.contains('Task Assigned') || title.contains('assigned')) {
        title = '📌 Task Assigned: $taskName';
      } else {
        title = title.replaceAll(tskRegex, taskName);
      }

      // Message: replace all TSK codes with task name
      message = message.replaceAll(tskRegex, taskName);
      // Clean up "(taskName)" that appears after already-replaced name
      message = message.replaceAll(RegExp("'$taskName'\\s*\\($taskName\\)"), "'$taskName'");
    }

    debugPrint('[NOTIF-DEBUG] final title="$title" final message="$message"');



    String projectTag = 'General';
    final regExp = RegExp(r'PRJ-\d+');
    final match = regExp.firstMatch('$title $message');
    if (match != null) {
      projectTag = match.group(0)!;
    } else if (category == 'tasks') {
      projectTag = 'Task';
    }

    DateTime timestamp = DateTime.now();
    if (json['createdAt'] != null) {
      timestamp = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    }

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
      taskId: tId,
      projectId: json['projectId']?.toString(),
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
  bool _isGridView = false;
  late TabController _tabController;
  final int _currentIdx = -1; // future index track cheyyadaniki

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

  bool _isLoading = false;
  String? _error;

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() {
      _error = null;
    });
    try {
      // Step 1: Fetch raw notifications
      final List<dynamic> rawNotifications = await ApiService.getNotifications();

      // Step 2: Collect unique task entityIds from ALL notifications that have entityId
      final tskCodeRegex = RegExp(r'TSK-?(\d+)');
      final taskEntityIds = <String>{};
      for (final n in rawNotifications) {
        // Debug: print raw notification keys
        debugPrint('[NOTIF] keys=${n.keys.toList()} entityId=${n['entityId']} entityTyp=${n['entityTyp']} entityType=${n['entityType']}');

        // Prefer explicit entityId (regardless of entityTyp, to avoid missing tasks)
        final eid = n['entityId']?.toString();
        if (eid != null && eid.isNotEmpty && eid != 'null') {
          taskEntityIds.add(eid);
        } else {
          // Fallback: extract TSK code from title/message
          final combined = '${n['title'] ?? ''} ${n['message'] ?? ''}';
          final m = tskCodeRegex.firstMatch(combined);
          if (m != null) taskEntityIds.add(m.group(1)!);
        }
      }
      debugPrint('[NOTIF] Collected taskEntityIds: $taskEntityIds');


      // Step 3: Fetch task names in parallel for each unique entityId
      final Map<String, String> taskNamesMap = {};
      if (taskEntityIds.isNotEmpty) {
        final futures = taskEntityIds.map((eid) async {
          final taskIdInt = int.tryParse(eid);
          if (taskIdInt == null) return;
          try {
            // Try project-live task first
            final liveTask = await ApiService.getLiveTask(taskIdInt);
            if (liveTask != null) {
              final name = liveTask['taskNm']?.toString() ?? liveTask['taskName']?.toString() ?? '';
              if (name.isNotEmpty) {
                taskNamesMap[eid] = name;
                return;
              }
            }
          } catch (_) {}
          try {
            // Fallback: individual task (assignments endpoint)
            final indTask = await ApiService.getIndividualTaskById(taskIdInt);
            if (indTask != null) {
              final name = indTask['taskNm']?.toString() ?? indTask['taskName']?.toString() ?? '';
              if (name.isNotEmpty) {
                taskNamesMap[eid] = name;
              }
            }
          } catch (_) {}
        });
        await Future.wait(futures);
      }

      if (!mounted) return;
      setState(() {
        _notifications = rawNotifications.map((json) {
          return NotificationModel.fromJson(json, taskNamesMap: taskNamesMap);
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



  Future<void> _markAllAsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) {
      _showSnackBar('No unread notifications');
      return;
    }
    
    setState(() { _isLoading = true; });
    for (var n in unread) {
      final idInt = int.tryParse(n.id);
      if (idInt != null) {
        await ApiService.markNotificationAsRead(idInt);
      }
    }
    _showSnackBar('âœ“ All notifications marked as read');
    _fetchNotifications();
  }


  // ============================================
  // HANDLER METHODS
  // ============================================



  void _handleDismiss(String id) async {
    final idInt = int.tryParse(id);
    if (idInt != null) {
      await ApiService.markNotificationAsRead(idInt);
    }
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    _showSnackBar('ðŸ—‘ï¸ Notification dismissed');
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

  Map<String, List<NotificationModel>> get _groupedNotifications {
    final grouped = <String, List<NotificationModel>>{};
    final now = DateTime.now();

    for (var notification in _notifications) {
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
        title: "Notifications", // à°¬à±à°¯à°¾à°•à± à°¬à°Ÿà°¨à± à°†à°Ÿà±‹à°®à±‡à°Ÿà°¿à°•à±â€Œà°—à°¾ à°µà°¸à±à°¤à±à°‚à°¦à°¿
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _markAllAsRead,
            icon: const Icon(Icons.done_all, size: 18),
            label: Text(
              'Mark All Read',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _isGridView ? Icons.view_list : Icons.grid_view_outlined,
                    size: 16,
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isGridView ? 'List' : 'Grid',
                    style: GoogleFonts.inter(
                      fontSize: 12,
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
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  key,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Notifications
            if (_isGridView)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: notifications.map((notification) {
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - 44) / 2, // 32 for screen padding, 12 for spacing
                    child: _buildNotificationCard(notification, isGrid: true),
                  );
                }).toList(),
              )
            else
              ...notifications.map((notification) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildNotificationCard(notification, isGrid: false),
                );
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

  Widget _buildNotificationCard(NotificationModel notification, {bool isGrid = false}) {
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
              await ApiService.markNotificationAsRead(idInt);
              _fetchNotifications();
            }
          }

          if (notification.taskId != null) {
            try {
              if (mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Center(child: CircularProgressIndicator());
                  },
                );
              }

              final prefs = await SharedPreferences.getInstance();
              final currentEmpId = prefs.getString('empId');

              // Fetch all tasks identical to task_screen.dart
              final responses = await Future.wait([
                ApiService.getLiveTasks(),
                ApiService.getIndividualTasks(),
              ]);

              final liveTasks = responses[0] as List<TaskItem>;
              final rawIndividualTasks = responses[1];

              final individualTasks = rawIndividualTasks
                  .whereType<Map<String, dynamic>>()
                  .map((json) => TaskItem.fromIndividualTask(json, currentEmpId))
                  .toList();

              final combinedTasks = [...liveTasks, ...individualTasks];

              if (mounted) {
                Navigator.pop(context); // Dismiss loading dialog
              }

              TaskItem? foundTask;
              for (final t in combinedTasks) {
                if (t.id == notification.taskId ||
                    t.rawData?['taskId']?.toString() == notification.taskId ||
                    t.rawData?['empTaskId']?.toString() == notification.taskId) {
                  foundTask = t;
                  break;
                }
              }

              if (foundTask != null && mounted) {
                Navigator.pushNamed(
                  context, 
                  '/task-details', 
                  arguments: foundTask
                );
                return;
              } else if (mounted) {
                _showSnackBar('Task details not found locally.');
              }
            } catch (e) {
              if (mounted) {
                Navigator.pop(context); // Dismiss loading dialog if error
                _showSnackBar('Error loading task details: $e');
              }
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnread ? const Color(0xFFBFDBFE) : const Color(0xFFF1F5F9),
              width: isUnread ? 1.5 : 1,
            ),
          ),
          child: isGrid
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _getIconBackgroundColor(notification.priority),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getIconForNotification(notification.icon),
                            color: notification.color,
                            size: 18,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      notification.title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF475569),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification.timeAgo,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(notification.priority).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getPriorityLabel(notification.priority),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _getPriorityColor(notification.priority),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
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
                                  color: _getPriorityColor(notification.priority).withValues(alpha: 0.1),
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
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF475569),
                              height: 1.4,
                            ),
                          ),
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
                                  const Icon(Icons.access_time, size: 12, color: Color(0xFF94A3B8)),
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
                          if (notification.quickActions.isNotEmpty) ...[
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
                                      color: action.color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: action.color.withValues(alpha: 0.2),
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
            'You\'re all caught up! ðŸŽ‰',
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
