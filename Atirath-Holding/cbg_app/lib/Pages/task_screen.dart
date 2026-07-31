import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_item.dart';
import '../models/employee_option.dart';
import '../services/api_service.dart';
import 'task_details_screen.dart';
import '../widgets/reassign_icon.dart';

class TasksScreen extends StatefulWidget {
  static final ValueNotifier<String> activeTabNotifier = ValueNotifier<String>('To-Do List');

  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with WidgetsBindingObserver {
  String _selectedTab = 'To-Do List';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  List<TaskItem> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _autoRefreshTimer;

  String? _userPhotoUrl;
  String _userInitials = 'EM';
  String _userName = '';
  int? _currentEmpId;
  Map<String, EmployeeOption> _employeeMap = {};

  int _todoCount = 0;
  int _upcomingCount = 0;
  int _completedCount = 0;
  int _totalCount = 0;

  Future<void> _fetchTasks() async {
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
    });
    try {
      final responses = await Future.wait([
        ApiService.getLiveTasks(forceRefresh: true),
        ApiService.getCurrentEmployeeId(),
        ApiService.getUserDashboardData(forceRefresh: true),
        ApiService.getEmployees(forceRefresh: true),
      ]);

      List<TaskItem> liveTasks = responses[0] as List<TaskItem>;
      final currentEmpId = responses[1] as int?;
      final dashboardData = responses[2] as Map<String, dynamic>?;
      final employeesList = responses[3] as List<dynamic>;

      final Map<String, EmployeeOption> tempMap = {};
      for (final emp in employeesList) {
        if (emp is Map) {
          final map = Map<String, dynamic>.from(emp);
          final opt = EmployeeOption.fromJson(map);
          if (opt.id != null) {
            tempMap[opt.id!] = opt;
            tempMap[opt.id!.trim()] = opt;
          }
          final String empId = (map['empId'] ?? map['empid'] ?? map['id'] ?? '').toString().trim();
          if (empId.isNotEmpty) {
            tempMap[empId] = opt;
          }
          final String fst = (map['fstNm'] ?? map['firstName'] ?? map['fst_nm'] ?? '').toString().trim();
          final String lst = (map['lstNm'] ?? map['lastName'] ?? map['lst_nm'] ?? '').toString().trim();
          final String fullNm = "$fst $lst".trim();
          if (fullNm.isNotEmpty) {
            tempMap[_normalizeName(fullNm)] = opt;
          }
          final String empNm = (map['empNm'] ?? map['employeeName'] ?? map['name'] ?? '').toString().trim();
          if (empNm.isNotEmpty) {
            tempMap[_normalizeName(empNm)] = opt;
          }
        }
      }

      String fullName = '';
      if (dashboardData != null) {
        _userPhotoUrl = dashboardData['photoUrl']?.toString();
        fullName = dashboardData['fullName']?.toString() ?? '';
        if (fullName.isNotEmpty) {
          final parts = fullName.trim().split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            _userInitials = (parts[0][0] + parts[1][0]).toUpperCase();
          } else {
            _userInitials = parts[0][0].toUpperCase();
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('userRole') ?? '';
      final bool isAdmin = userRole.toLowerCase() == 'admin';

      List<dynamic> rawIndividualTasks = await ApiService.getIndividualTasks(forceRefresh: true);
      
      if (!isAdmin && currentEmpId != null) {
        final empStr = currentEmpId.toString();

        liveTasks = liveTasks.where((t) {
          final raw = t.rawData ?? {};
          final doer = (raw['empId'] ?? raw['empid'] ?? raw['assignedTo'] ?? raw['executorId'])?.toString();
          final reviewer = (raw['reviewerId'] ?? raw['reviewer'] ?? t.reviewer)?.toString();
          final approver = (raw['approverId'] ?? raw['approver'] ?? t.approver)?.toString();
          return doer == empStr || reviewer == empStr || approver == empStr || t.isCurrentUserReviewer || t.isCurrentUserApprover;
        }).toList();

        rawIndividualTasks = rawIndividualTasks.where((t) {
          if (t is! Map) return false;
          final doer = (t['empId'] ?? t['empid'] ?? t['assignedTo'] ?? t['executorId'])?.toString();
          final reviewer = (t['reviewerId'] ?? t['reviewer'])?.toString();
          final approver = (t['approverId'] ?? t['approver'])?.toString();
          return doer == empStr || reviewer == empStr || approver == empStr;
        }).toList();
      }

      final individualTasks = rawIndividualTasks
          .whereType<Map>()
          .map((json) => TaskItem.fromIndividualTask(Map<String, dynamic>.from(json), currentEmpId?.toString()))
          .toList();

      // Deduplicate tasks strictly by unique database primary ID with source prefix
      final Map<String, TaskItem> uniqueTaskMap = {};
      for (final task in [...liveTasks, ...individualTasks]) {
        final prefix = task.isIndividualTask ? 'IND_' : 'LIVE_';
        final idKey = '$prefix${task.id}';

        if (!uniqueTaskMap.containsKey(idKey)) {
          uniqueTaskMap[idKey] = task;
        }
      }

      final combinedTasks = uniqueTaskMap.values.where((task) => !task.isDraft).toList();

      // Sort by date (descending, newest first)
      combinedTasks.sort((a, b) {
        final dateA = a.rawEndDt ?? a.rawStDt ?? a.startDate ?? a.date;
        final dateB = b.rawEndDt ?? b.rawStDt ?? b.startDate ?? b.date;
        final dtA = TaskItem.parseDateTime(dateA);
        final dtB = TaskItem.parseDateTime(dateB);
        if (dtA != null && dtB != null) {
          return dtB.compareTo(dtA);
        }
        return 0;
      });

      bool isTaskActive(TaskItem task) {
        return !task.isCompleted;
      }

      final int todoCount = combinedTasks.where((task) => isTaskActive(task) && !_isTaskUpcoming(task)).length;
      final int upcomingCount = combinedTasks.where((task) => isTaskActive(task) && _isTaskUpcoming(task)).length;
      final int completedCount = combinedTasks.where((task) => task.isCompleted).length;
      final int totalCount = combinedTasks.length;

      if (mounted) {
        setState(() {
          _tasks = combinedTasks;
          _currentEmpId = currentEmpId;
          _userName = fullName;
          _employeeMap = tempMap;
          _todoCount = todoCount;
          _upcomingCount = upcomingCount;
          _completedCount = completedCount;
          _totalCount = totalCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onTabNotifierChanged() {
    if (mounted && _selectedTab != TasksScreen.activeTabNotifier.value) {
      setState(() {
        _selectedTab = TasksScreen.activeTabNotifier.value;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedTab = TasksScreen.activeTabNotifier.value;
    TasksScreen.activeTabNotifier.addListener(_onTabNotifierChanged);
    _fetchTasks();
    _startAutoRefresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        setState(() {
          if (args == 'Pending') {
            _selectedTab = 'To-Do List';
          } else {
            _selectedTab = args;
          }
        });
      }
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) {
        _fetchTasks();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _fetchTasks();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    TasksScreen.activeTabNotifier.removeListener(_onTabNotifierChanged);
    _searchController.dispose();
    super.dispose();
  }

  bool _isTaskUpcoming(TaskItem task) {
    return task.isUpcomingTask;
  }

  List<TaskItem> _getFilteredTasks() {
    final query = _searchQuery.trim().toLowerCase();
    return _tasks.where((task) {
      bool matchesTab = true;
      if (_selectedTab == 'To-Do List') {
        matchesTab = task.isTodo;
      } else if (_selectedTab == 'Upcoming Tasks') {
        matchesTab = task.isUpcomingTask;
      } else if (_selectedTab == 'Closed' || _selectedTab == 'Completed') {
        matchesTab = task.isCompleted;
      } else if (_selectedTab == 'All Tasks') {
        matchesTab = true;
      }

      if (!matchesTab) return false;

      if (query.isEmpty) return true;

      final String title = task.title.toLowerCase();
      final String subtitle = task.subtitle.toLowerCase();
      final String code = task.taskCode.toLowerCase();
      final String prjName = (task.projectName ?? '').toLowerCase();
      final String prjCode = (task.projectCode ?? '').toLowerCase();
      final String milestone = (task.milestoneName ?? '').toLowerCase();
      final String status = task.status.toLowerCase();
      final String priority = task.priority.toLowerCase();
      final String tag = task.tag.toLowerCase();
      final String desc = (task.description ?? '').toLowerCase();
      final String dateStr = task.date.toLowerCase();
      final String stDate = (task.startDate ?? '').toLowerCase();
      final String endDate = (task.endDate ?? '').toLowerCase();
      final String rawDataStr = (task.rawData != null ? task.rawData.toString() : '').toLowerCase();

      return title.contains(query) ||
          subtitle.contains(query) ||
          code.contains(query) ||
          prjName.contains(query) ||
          prjCode.contains(query) ||
          milestone.contains(query) ||
          status.contains(query) ||
          priority.contains(query) ||
          tag.contains(query) ||
          desc.contains(query) ||
          dateStr.contains(query) ||
          stDate.contains(query) ||
          endDate.contains(query) ||
          rawDataStr.contains(query);
    }).toList();
  }


  void _navigateToTaskDetails(TaskItem task) async {
    if (task.isIndividualTask) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskDetailsScreen(task: task, isIndividualTask: true),
        ),
      );
    } else {
      await Navigator.pushNamed(
        context,
        '/task-details',
        arguments: task,
      );
    }
    _fetchTasks();
  }

  String _normalizeName(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
  }

  String _resolveImageUrl(String path) {
    if (path.trim().isEmpty) return '';
    final str = path.trim();
    if (str.startsWith('http://') || str.startsWith('https://') || str.startsWith('data:image')) {
      return str;
    }
    final baseUrl = dotenv.env['BASE_URL'] ?? 'https://bionova-rjii.onrender.com';
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = str.startsWith('/') ? str : '/$str';
    return '$cleanBase$cleanPath';
  }

  Widget _buildRoleAvatar({
    required String? photoUrl,
    required String initials,
    required IconData fallbackIcon,
    required Color bg,
    required Color text,
    required String tooltipMsg,
  }) {
    final resolvedUrl = photoUrl != null && photoUrl.isNotEmpty ? _resolveImageUrl(photoUrl) : '';
    
    Widget avatarWidget;
    if (resolvedUrl.isNotEmpty) {
      avatarWidget = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: text.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            resolvedUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildIconAvatar(fallbackIcon, initials, bg, text);
            },
          ),
        ),
      );
    } else {
      avatarWidget = _buildIconAvatar(fallbackIcon, initials, bg, text);
    }

    return Tooltip(
      message: tooltipMsg,
      child: avatarWidget,
    );
  }

  Widget _buildIconAvatar(IconData iconData, String initials, Color bg, Color text) {
    final bool hasNameInitials = initials.isNotEmpty && initials != 'EX' && initials != 'RV' && initials != 'AP';
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: text.withValues(alpha: 0.35), width: 1.5),
      ),
      alignment: Alignment.center,
      child: hasNameInitials
          ? Text(
              initials,
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            )
          : Icon(
              iconData,
              size: 13,
              color: text,
            ),
    );
  }

  Widget _buildEmployeeAvatar(String? photoUrl, String initials, [Color? bg, Color? text]) {
    return _buildRoleAvatar(
      photoUrl: photoUrl,
      initials: initials,
      fallbackIcon: Icons.person_rounded,
      bg: bg ?? const Color(0xFFEFF6FF),
      text: text ?? const Color(0xFF2563EB),
      tooltipMsg: initials,
    );
  }

  Widget _buildFallbackIconOrInitials(String initials, [Color? bg, Color? text]) {
    return _buildIconAvatar(Icons.person_rounded, initials, bg ?? const Color(0xFFEFF6FF), text ?? const Color(0xFF2563EB));
  }

  Widget _buildTaskAvatarsRow(TaskItem task) {
    final List<Widget> avatars = [];

    EmployeeOption? findEmp(String idStr, String nameStr) {
      final cleanId = idStr.trim();
      final cleanNm = _normalizeName(nameStr);
      if (cleanId.isEmpty && cleanNm.isEmpty) return null;
      for (final emp in _employeeMap.values) {
        final empIdStr = emp.id?.toString().trim() ?? '';
        final empNmStr = _normalizeName(emp.name);
        if (cleanId.isNotEmpty && empIdStr == cleanId) return emp;
        if (cleanNm.isNotEmpty && empNmStr == cleanNm) return emp;
      }
      return null;
    }

    // 1. Executor (Doer / Assignee)
    final executorId = (task.rawData?['empId'] ?? task.rawData?['empid'] ?? task.rawData?['assignedTo'] ?? '').toString().trim();
    final executorNm = (task.rawData?['empNm'] ?? task.rawData?['executorNm'] ?? task.rawData?['assigneeNm'] ?? task.rawData?['emp_nm'] ?? '').toString().trim();
    EmployeeOption? executorOpt = findEmp(executorId, executorNm);

    String? executorPhoto = executorOpt?.profileImageUrl;
    if (executorPhoto == null || executorPhoto.isEmpty) {
      executorPhoto = (task.rawData?['executorPhoto'] ?? task.rawData?['executor_photo'] ?? task.rawData?['empPhoto'] ?? task.rawData?['emp_photo'] ?? task.rawData?['photoUrl'] ?? task.rawData?['photo_url'] ?? '').toString();
    }
    String executorInitials = executorOpt?.initials ?? '';
    if (executorInitials.isEmpty && executorNm.isNotEmpty) {
      final parts = executorNm.trim().split(RegExp(r'\s+'));
      executorInitials = parts.length >= 2 ? (parts[0][0] + parts[1][0]).toUpperCase() : parts[0][0].toUpperCase();
    }
    if (executorInitials.isEmpty) executorInitials = 'EX';

    if (executorOpt == null && (executorId.isEmpty || executorId == _currentEmpId?.toString())) {
      executorPhoto = _userPhotoUrl;
      executorInitials = _userInitials;
    }
    final String executorLabel = executorOpt?.name ?? (executorNm.isNotEmpty ? executorNm : (executorId == _currentEmpId?.toString() ? _userName : "Executor"));

    avatars.add(
      _buildRoleAvatar(
        photoUrl: executorPhoto,
        initials: executorInitials,
        fallbackIcon: Icons.person_rounded,
        bg: const Color(0xFFEFF6FF),
        text: const Color(0xFF2563EB),
        tooltipMsg: 'Executor: $executorLabel',
      ),
    );

    // 2. Reviewer
    final reviewerId = (task.reviewer ?? task.rawData?['reviewer'] ?? '').toString().trim();
    final reviewerNm = (task.rawData?['reviewerNm'] ?? task.rawData?['reviewer_nm'] ?? '').toString().trim();
    if (reviewerId.isNotEmpty || reviewerNm.isNotEmpty) {
      EmployeeOption? reviewerOpt = findEmp(reviewerId, reviewerNm);
      String? reviewerPhoto = reviewerOpt?.profileImageUrl;
      if (reviewerPhoto == null || reviewerPhoto.isEmpty) {
        reviewerPhoto = (task.rawData?['reviewerPhoto'] ?? task.rawData?['reviewer_photo'] ?? task.rawData?['reviewerPhotoUrl'] ?? task.rawData?['reviewer_photo_url'] ?? '').toString();
      }
      String reviewerInitials = reviewerOpt?.initials ?? '';
      if (reviewerInitials.isEmpty && reviewerNm.isNotEmpty) {
        final parts = reviewerNm.trim().split(RegExp(r'\s+'));
        reviewerInitials = parts.length >= 2 ? (parts[0][0] + parts[1][0]).toUpperCase() : parts[0][0].toUpperCase();
      }
      if (reviewerInitials.isEmpty) reviewerInitials = 'RV';
      final String reviewerLabel = reviewerOpt?.name ?? (reviewerNm.isNotEmpty ? reviewerNm : reviewerId);

      avatars.add(const SizedBox(width: 5));
      avatars.add(
        _buildRoleAvatar(
          photoUrl: reviewerPhoto,
          initials: reviewerInitials,
          fallbackIcon: Icons.rate_review_rounded,
          bg: const Color(0xFFF3E8FF),
          text: const Color(0xFF7C3AED),
          tooltipMsg: 'Reviewer: $reviewerLabel',
        ),
      );
    }

    // 3. Approver
    final approverId = (task.approver ?? task.rawData?['approver'] ?? '').toString().trim();
    final approverNm = (task.rawData?['approverNm'] ?? task.rawData?['approver_nm'] ?? '').toString().trim();
    if (approverId.isNotEmpty || approverNm.isNotEmpty) {
      EmployeeOption? approverOpt = findEmp(approverId, approverNm);
      String? approverPhoto = approverOpt?.profileImageUrl;
      if (approverPhoto == null || approverPhoto.isEmpty) {
        approverPhoto = (task.rawData?['approverPhoto'] ?? task.rawData?['approver_photo'] ?? task.rawData?['approverPhotoUrl'] ?? task.rawData?['approver_photo_url'] ?? '').toString();
      }
      String approverInitials = approverOpt?.initials ?? '';
      if (approverInitials.isEmpty && approverNm.isNotEmpty) {
        final parts = approverNm.trim().split(RegExp(r'\s+'));
        approverInitials = parts.length >= 2 ? (parts[0][0] + parts[1][0]).toUpperCase() : parts[0][0].toUpperCase();
      }
      if (approverInitials.isEmpty) approverInitials = 'AP';
      final String approverLabel = approverOpt?.name ?? (approverNm.isNotEmpty ? approverNm : approverId);

      avatars.add(const SizedBox(width: 5));
      avatars.add(
        _buildRoleAvatar(
          photoUrl: approverPhoto,
          initials: approverInitials,
          fallbackIcon: Icons.verified_user_rounded,
          bg: const Color(0xFFECFDF5),
          text: const Color(0xFF10B981),
          tooltipMsg: 'Approver: $approverLabel',
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: avatars,
    );
  }

  Widget _buildTaskCard(TaskItem task) {
    String prjName = '';
    if (task.projectName != null && task.projectName!.isNotEmpty && task.projectName != 'Unknown Project') {
      prjName = task.projectName!;
    } else if (task.projectCode != null && task.projectCode!.isNotEmpty) {
      prjName = task.projectCode!;
    } else {
      final cleanSub = task.subtitle.replaceAll('â€¢', '•').trim();
      final parts = cleanSub.split('•');
      prjName = parts.first.trim();
    }

    if (prjName.isEmpty || prjName == 'Role: Executor' || prjName == 'Role: Reviewer' || prjName == 'Role: Approver' || prjName.startsWith('Role:')) {
      prjName = task.taskCode;
    }

    return GestureDetector(
      onTap: () => _navigateToTaskDetails(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  Text(
                    prjName,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  if ((task.status == 'Closed' || task.status == 'Completed') && task.completionDate != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        Text(
                          'Closed: ${task.completionDate}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Due Date
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          (task.startDate != null && task.startDate!.isNotEmpty && task.startDate != 'No Date' && task.startDate != task.date)
                              ? '${task.startDate} - ${task.date}'
                              : 'Due Date: ${task.date}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bottom row: Priority badge (hidden for completed) and Avatars
                  Row(
                    children: [
                      if (!task.isCompleted) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: getPriorityBg(task.priority),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: getPriorityColor(task.priority).withValues(alpha: 0.15), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: getPriorityColor(task.priority),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                task.priority,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: getPriorityColor(task.priority),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      _buildTaskAvatarsRow(task),
                    ],
                  ),
                ],
              ),
            ),

            // Right column - aligned right
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Progress Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: task.progressStatusBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: task.progressStatusColor.withValues(alpha: 0.15), width: 1),
                  ),
                  child: Text(
                    task.progressStatusText,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: task.progressStatusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Process & Time Icons Row (EXACT SAME AS WEBSITE!)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!task.isCompleted && task.processIcon != null) ...[
                      Tooltip(
                        message: task.status,
                        child: task.isReassigned
                            ? ReassignIcon(size: 18, color: task.processIconColor ?? const Color(0xFF4F46E5))
                            : Icon(task.processIcon, color: task.processIconColor, size: 18),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (task.computedTimeStatus.isNotEmpty)
                      Tooltip(
                        message: task.computedTimeStatus,
                        child: Icon(task.timeIcon, color: task.timeIconColor, size: 18),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Chevron right arrow icon
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoItemRedesigned(TaskItem task, bool isSmallScreen) {
    return _buildTaskCard(task);
  }

  Widget _buildUpcomingTaskItemRedesigned(TaskItem task) {
    return _buildTaskCard(task);
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredTasks();

    final criticalTasks = filteredTasks.where((t) => t.tag == 'Critical').toList();
    final highTasks = filteredTasks.where((t) => t.tag == 'High').toList();
    final normalTasks = filteredTasks.where((t) => t.tag != 'Critical' && t.tag != 'High').toList();

    final sortedTasks = [...criticalTasks, ...highTasks, ...normalTasks];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      body: RefreshIndicator(
        onRefresh: _fetchTasks,
        color: Colors.deepPurple,
        child: _isLoading && _tasks.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
            : _errorMessage != null && _tasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 60, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load tasks',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _fetchTasks,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                            child: const Text('Retry', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          
                          // Search Bar
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() => _searchQuery = value),
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search tasks...',
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty 
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18), 
                                        onPressed: () => setState(() { 
                                          _searchController.clear(); 
                                          _searchQuery = ''; 
                                        })
                                      ) 
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/individual-task').then((_) => _fetchTasks());
                              },
                              icon: const Icon(Icons.add, size: 16, color: Colors.deepPurple),
                              label: const Text(
                                'Assignment',
                                style: TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                backgroundColor: Colors.deepPurple.withValues(alpha: 0.08),
                                side: BorderSide(color: Colors.deepPurple.withValues(alpha: 0.2), width: 1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Summary Cards
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: SummaryCard(
                                    title: '$_todoCount', 
                                    subtitle: 'To-Do', 
                                    desc: 'Active Tasks', 
                                    icon: Icons.assignment_outlined, 
                                    iconColor: Colors.orange, 
                                    bgColor: const Color(0xFFFEF3C7), 
                                    isSelected: _selectedTab == 'To-Do List', 
                                    onTap: () => setState(() => _selectedTab = 'To-Do List')
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: SummaryCard(
                                    title: '$_upcomingCount', 
                                    subtitle: 'Upcoming', 
                                    desc: 'Scheduled', 
                                    icon: Icons.calendar_month_outlined, 
                                    iconColor: Colors.blue, 
                                    bgColor: const Color(0xFFE0F2FE), 
                                    isSelected: _selectedTab == 'Upcoming Tasks', 
                                    onTap: () => setState(() => _selectedTab = 'Upcoming Tasks')
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: SummaryCard(
                                    title: '$_completedCount', 
                                    subtitle: 'Closed', 
                                    desc: 'Done', 
                                    icon: Icons.task_alt, 
                                    iconColor: const Color(0xFF16A34A), 
                                    bgColor: const Color(0xFFDCFCE7), 
                                    isSelected: _selectedTab == 'Closed' || _selectedTab == 'Completed', 
                                    onTap: () => setState(() => _selectedTab = 'Closed')
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: SummaryCard(
                                    title: '$_totalCount', 
                                    subtitle: 'All Tasks', 
                                    desc: 'Total Work', 
                                    icon: Icons.layers_outlined, 
                                    iconColor: Colors.deepPurple, 
                                    bgColor: const Color(0xFFF3E8FF), 
                                    isSelected: _selectedTab == 'All Tasks', 
                                    onTap: () => setState(() => _selectedTab = 'All Tasks')
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Task List Card Section
                          if (sortedTasks.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 30.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.assignment_turned_in_outlined, size: 40, color: Colors.grey.shade400),
                                    const SizedBox(height: 10),
                                    Text('No tasks found!', style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500))
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sortedTasks.length,
                              itemBuilder: (context, index) {
                                final task = sortedTasks[index];
                                if (_selectedTab == 'Upcoming Tasks') {
                                  return _buildUpcomingTaskItemRedesigned(task);
                                } else {
                                  final bool isSmallScreen = MediaQuery.of(context).size.width < 360;
                                  return _buildTodoItemRedesigned(task, isSmallScreen);
                                }
                              },
                            ),
                          
                          const SizedBox(height: 80), 
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

// ============================================================
// ✅ POLISHED TASK TILE ROW - Complete version
// ============================================================
class TaskTileRow extends StatelessWidget {
  final TaskItem task; 
  final String status;
  final VoidCallback onInfoTap;
  final VoidCallback onTap;
  
  const TaskTileRow({
    super.key, 
    required this.task, 
    required this.status,
    required this.onInfoTap,
    required this.onTap,
  });

  // ✅ Supports both ISO date (yyyy-MM-dd) and formatted dates (1 Jul 2026)
  int? _getDaysLeft(String dateStr) {
    final value = dateStr.trim();
    if (value.isEmpty || value.toLowerCase() == 'n/a' || value.toLowerCase() == 'no date') {
      return null;
    }

    if (value.toLowerCase() == 'today') {
      return 0;
    }

    try {
      // 1) Handle yyyy-MM-dd directly (ex: 2026-07-09)
      final isoDate = DateTime.tryParse(value);
      if (isoDate != null) {
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final target = DateTime(isoDate.year, isoDate.month, isoDate.day);
        return target.difference(todayStart).inDays;
      }

      // 2) Handle "1 Jul 2026" / "Jul 1 2026"
      final normalized = value.replaceAll(',', '').toLowerCase();
      final parts = normalized.split(RegExp(r'\s+'));

      if (parts.length == 3) {
        int? day;
        int? month;
        int? year;

        const months = {
          'jan': 1, 'january': 1,
          'feb': 2, 'february': 2,
          'mar': 3, 'march': 3,
          'apr': 4, 'april': 4,
          'may': 5,
          'jun': 6, 'june': 6,
          'jul': 7, 'july': 7,
          'aug': 8, 'august': 8,
          'sep': 9, 'september': 9,
          'oct': 10, 'october': 10,
          'nov': 11, 'november': 11,
          'dec': 12, 'december': 12,
        };

        final firstNum = int.tryParse(parts[0]);
        if (firstNum != null) {
          day = firstNum;
          month = months[parts[1]];
          year = int.tryParse(parts[2]);
        } else {
          month = months[parts[0]];
          day = int.tryParse(parts[1]);
          year = int.tryParse(parts[2]);
        }

        if (day != null && month != null && year != null) {
          final target = DateTime(year, month, day);
          final today = DateTime.now();
          final todayStart = DateTime(today.year, today.month, today.day);
          return target.difference(todayStart).inDays;
        }
      }
    } catch (_) {}

    return null;
  }

  Widget _buildDaysLeftWidget(TaskItem task, String currentStatus) {
    if (currentStatus == 'Closed' || currentStatus == 'Completed') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 12, color: Colors.green.shade700),
          const SizedBox(width: 3),
          Text(
            'Closed',
            style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    final daysLeft = _getDaysLeft(task.date);
    if (daysLeft == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(
            'Due: ${task.date}',
            style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
      );
    }

    Color textColor = Colors.blueGrey.shade600;
    IconData icon = Icons.schedule;
    String text = '';
    FontWeight fontWeight = FontWeight.w500;

    if (task.timeStatus != null && task.timeStatus!.isNotEmpty) {
      final ts = task.timeStatus!;
      text = ts;
      fontWeight = FontWeight.bold;
      if (ts == 'Lead') {
        textColor = const Color(0xFF22C55E);
        icon = Icons.thumb_up_alt_outlined;
      } else if (ts == 'On Time') {
        textColor = const Color(0xFF3B82F6);
        icon = Icons.check_circle_outline;
      } else if (ts == 'Due Today') {
        textColor = const Color(0xFFF59E0B);
        icon = Icons.hourglass_empty_rounded;
      } else if (ts == 'Overdue') {
        textColor = const Color(0xFFEF4444);
        icon = Icons.warning_amber_rounded;
        if (daysLeft < 0) text = '${daysLeft.abs()} days overdue';
      } else if (ts == 'Lag') {
        textColor = const Color(0xFFDC2626);
        icon = Icons.error_outline;
      }
    } else {
      if (daysLeft < 0) {
        textColor = Colors.red.shade700;
        icon = Icons.warning_amber_rounded;
        text = '${daysLeft.abs()} days overdue';
        fontWeight = FontWeight.bold;
      } else if (daysLeft == 0) {
        textColor = Colors.orange.shade800;
        icon = Icons.hourglass_empty_rounded;
        text = '0 days left (Today)';
        fontWeight = FontWeight.bold;
      } else if (daysLeft == 1) {
        textColor = Colors.orange.shade700;
        icon = Icons.hourglass_bottom_rounded;
        text = '1 day left';
        fontWeight = FontWeight.bold;
      } else {
        textColor = (currentStatus == 'Pending' || currentStatus == 'Open') ? task.tagColor : Colors.blueGrey.shade600;
        icon = Icons.schedule;
        text = '$daysLeft days left';
        fontWeight = (currentStatus == 'Pending' || currentStatus == 'Open') ? FontWeight.bold : FontWeight.w500;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: textColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 10, color: textColor, fontWeight: fontWeight),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Get description for individual tasks
    final String descriptionText = (task.description != null && task.description!.trim().isNotEmpty)
        ? task.description!.trim()
        : 'No description';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), 
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            // 1. Left side - Task icon with status note
            GestureDetector(
              onTap: onInfoTap,
              child: Container(
                padding: const EdgeInsets.all(10), 
                decoration: BoxDecoration(
                  color: task.iconBg.withValues(alpha: 0.8), // Using iconBg directly with slight transparency
                  borderRadius: BorderRadius.circular(10)
                ), 
                child: Icon(
                  task.icon, 
                  color: task.iconColor, 
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            
            // 2. Middle section - Task details with conditional subtitle/description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Task Title
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 14, 
                      color: Color(0xFF1E293B), 
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // ✅ CONDITIONAL: Individual task → description, Normal task → subtitle
                  if (task.isIndividualTask)
                    Text(
                      descriptionText,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      task.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 6),
                  
                  // Days left widget
                  _buildDaysLeftWidget(task, status),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 3. Right side - Status, arrow, tag (vertical centered)
            Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Progress Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: task.progressStatusBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.progressStatusText,
                    style: TextStyle(
                      fontSize: 9, 
                      fontWeight: FontWeight.w700, 
                      color: task.progressStatusColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                
                // Process and Time Icons Row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hide process icon for completed tasks
                    if (!task.isCompleted && task.processIcon != null) ...[
                      task.isReassigned
                          ? ReassignIcon(size: 16, color: task.processIconColor ?? const Color(0xFF4F46E5))
                          : Icon(task.processIcon, color: task.processIconColor, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Icon(task.timeIcon, color: task.timeIconColor, size: 16),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: Colors.grey[400], size: 16),
                  ],
                ),
                const SizedBox(height: 6),
                
                // Tag badge (priority) — hidden for completed tasks
                if (!task.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), 
                    decoration: BoxDecoration(
                      color: task.tagBg, 
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: task.tagColor.withValues(alpha: 0.2), width: 0.5),
                    ), 
                    child: Text(
                      task.tag, 
                      style: TextStyle(
                        color: task.tagColor, 
                        fontSize: 8.5, 
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title; 
  final String subtitle; 
  final String desc; 
  final IconData icon; 
  final Color iconColor; 
  final Color bgColor; 
  final bool isSelected; 
  final VoidCallback onTap;
  
  const SummaryCard({
    super.key, 
    required this.title, 
    required this.subtitle, 
    required this.desc, 
    required this.icon, 
    required this.iconColor, 
    required this.bgColor, 
    required this.isSelected, 
    required this.onTap
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, 
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), 
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10), 
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(
            color: isSelected ? iconColor : Colors.grey.shade200, 
            width: isSelected ? 1.5 : 1
          ), 
          boxShadow: isSelected ? [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.1), 
              blurRadius: 8, 
              offset: const Offset(0, 4)
            )
          ] : []
        ), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            Container(
              padding: const EdgeInsets.all(4), 
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), 
              child: Icon(icon, color: iconColor, size: 14)
            ), 
            const SizedBox(height: 10), 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))), 
                const SizedBox(height: 1), 
                Text(subtitle, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis), 
                Text(desc, style: TextStyle(fontSize: 8, color: Colors.grey[500], fontWeight: FontWeight.w500))
              ],
            )
          ],
        ),
      ),
    );
  }
}

class TaskLegendWidget extends StatelessWidget {
  const TaskLegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PROGRESS (STATUS)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    _buildLegendBadge('OPEN', const Color(0xFF2563EB), const Color(0xFFEFF6FF), 'Not started'),
                    _buildLegendBadge('IN PROGRESS', const Color(0xFFF59E0B), const Color(0xFFFFF7ED), 'In progress'),
                    _buildLegendBadge('CLOSED', const Color(0xFF16A34A), const Color(0xFFF0FDF4), 'Closed'),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PROCESS (Icons)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    _buildLegendIcon(Icons.remove_red_eye_outlined, const Color(0xFF8B5CF6), 'Under Review'),
                    _buildLegendIcon(Icons.sync, const Color(0xFFF97316), 'Rework'),
                    _buildLegendWidget(const ReassignIcon(size: 14, color: Color(0xFF4F46E5)), 'Reassign'),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TIME (Icons)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLegendTime(const Color(0xFF22C55E), Icons.thumb_up_alt_outlined, 'Lead', '(Closed before due date)'),
                              _buildLegendTime(const Color(0xFF3B82F6), Icons.check_circle_outline, 'On Time', '(Closed on due date)'),
                              _buildLegendTime(const Color(0xFFF59E0B), Icons.hourglass_empty_rounded, 'Due Today', '(Due date is today)'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLegendTime(const Color(0xFFEF4444), Icons.warning_amber_rounded, 'Overdue', '(Past due and not closed)'),
                              _buildLegendTime(const Color(0xFFDC2626), Icons.error_outline, 'Lag', '(Closed after due date)'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBadge(String label, Color color, Color bg, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
            child: Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(desc, style: TextStyle(fontSize: 9, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis, maxLines: 2)),
        ],
      ),
    );
  }

  Widget _buildLegendIcon(IconData icon, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildLegendWidget(Widget iconWidget, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          iconWidget,
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF4F46E5))),
        ],
      ),
    );
  }

  Widget _buildLegendTime(Color color, IconData icon, String label, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: '$label ',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                children: [
                  TextSpan(
                    text: desc,
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.normal, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
