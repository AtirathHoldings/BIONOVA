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
import '../utils/app_colors.dart';

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
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _autoRefreshTimer;

  String? _userPhotoUrl;
  String _userInitials = 'EM';
  String _userName = '';
  bool _isFetching = false;
  int? _currentEmpId;
  Map<String, EmployeeOption> _employeeMap = {};

  int _todoCount = 0;
  int _upcomingCount = 0;
  int _completedCount = 0;
  int _totalCount = 0;

  Future<void> _fetchTasks() async {
    if (!mounted || _isFetching) return;
    _isFetching = true;
    if (_tasks.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final responses = await Future.wait([
        ApiService.getLiveTasks(forceRefresh: true).catchError((e) {
          debugPrint("Error fetching live tasks: $e");
          return <TaskItem>[];
        }),
        ApiService.getCurrentEmployeeId().catchError((e) => null),
        ApiService.getUserDashboardData(forceRefresh: true).catchError((e) => null),
        ApiService.getEmployees(forceRefresh: true).catchError((e) => <dynamic>[]),
        ApiService.getIndividualTasks(forceRefresh: true).catchError((e) => <dynamic>[]),
      ]);

      List<TaskItem> liveTasks = List<TaskItem>.from(responses[0] as List);
      final currentEmpId = responses[1] as int?;
      final dashboardData = responses[2] as Map<String, dynamic>?;
      final employeesList = responses[3] as List<dynamic>;
      List<dynamic> rawIndividualTasks = List<dynamic>.from(responses[4] as List);

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
      final lowerRole = userRole.toLowerCase();
      final bool isAdminOrManager = lowerRole.contains('admin') || lowerRole.contains('manager') || lowerRole.contains('pm') || lowerRole.contains('lead');

      if (!isAdminOrManager && currentEmpId != null) {
        final empStr = currentEmpId.toString();

        liveTasks = liveTasks.where((t) {
          final raw = t.rawData ?? {};
          final doer = (raw['empId'] ?? raw['empid'] ?? raw['assignedTo'] ?? raw['executorId'])?.toString();
          final reviewer = (raw['reviewerId'] ?? raw['reviewer'] ?? t.reviewer)?.toString();
          final approver = (raw['approverId'] ?? raw['approver'] ?? t.approver)?.toString();
          final assigner = (raw['assignedBy'] ?? raw['assigned_by'] ?? raw['assignerId'] ?? raw['assigner_id'] ?? raw['crBy'] ?? raw['cr_by'])?.toString();
          final noteTxt = (raw['noteTxt'] ?? raw['note_txt'] ?? '').toString();
          final hasTeamMember = noteTxt.split(',').map((e) => e.trim()).contains(empStr) ||
              (raw['teamMembers'] is List && (raw['teamMembers'] as List).any((tm) => tm['empId']?.toString() == empStr || tm['emp_id']?.toString() == empStr));
          final isRevInList = (raw['reviewerIds'] is List && (raw['reviewerIds'] as List).any((id) => id?.toString() == empStr));
          final isAppInList = (raw['approverIds'] is List && (raw['approverIds'] as List).any((id) => id?.toString() == empStr));
          final hasPrcsConfig = (raw['processConfigs'] is List && (raw['processConfigs'] as List).any((pc) => (pc is Map) && (pc['empId']?.toString() == empStr || pc['emp_id']?.toString() == empStr)));
          return doer == empStr || reviewer == empStr || approver == empStr || assigner == empStr || t.isCurrentUserReviewer || t.isCurrentUserApprover || hasTeamMember || isRevInList || isAppInList || hasPrcsConfig;
        }).toList();

        rawIndividualTasks = rawIndividualTasks.where((t) {
          if (t is! Map) return false;
          final doer = (t['empId'] ?? t['empid'] ?? t['assignedTo'] ?? t['executorId'])?.toString();
          final reviewer = (t['reviewerId'] ?? t['reviewer'])?.toString();
          final approver = (t['approverId'] ?? t['approver'])?.toString();
          final assigner = (t['assignedBy'] ?? t['assigned_by'] ?? t['assignerId'] ?? t['assigner_id'] ?? t['crBy'] ?? t['cr_by'])?.toString();
          final noteTxt = (t['noteTxt'] ?? t['note_txt'] ?? '').toString();
          final hasTeamMember = noteTxt.split(',').map((e) => e.trim()).contains(empStr) ||
              (t['teamMembers'] is List && (t['teamMembers'] as List).any((tm) => tm['empId']?.toString() == empStr || tm['emp_id']?.toString() == empStr));
          final isRevInList = (t['reviewerIds'] is List && (t['reviewerIds'] as List).any((id) => id?.toString() == empStr));
          final isAppInList = (t['approverIds'] is List && (t['approverIds'] as List).any((id) => id?.toString() == empStr));
          final hasPrcsConfig = (t['processConfigs'] is List && (t['processConfigs'] as List).any((pc) => (pc is Map) && (pc['empId']?.toString() == empStr || pc['emp_id']?.toString() == empStr)));
          return doer == empStr || reviewer == empStr || approver == empStr || assigner == empStr || hasTeamMember || isRevInList || isAppInList || hasPrcsConfig;
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

      final int todoCount = combinedTasks.where((task) => task.isTodo).length;
      final int upcomingCount = combinedTasks.where((task) => task.isUpcomingTask).length;
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
    } finally {
      _isFetching = false;
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
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
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
      final String code = task.taskCode.toLowerCase();

      return title.contains(query) || code.contains(query);
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

  Widget _buildAvatarCircle({
    required String? photoUrl,
    required String initials,
    required Color bg,
    required Color text,
    required String tooltipMsg,
  }) {
    final resolvedUrl = photoUrl != null && photoUrl.isNotEmpty ? _resolveImageUrl(photoUrl) : '';

    return Tooltip(
      message: tooltipMsg,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(color: text.withValues(alpha: 0.35), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            )
          ],
        ),
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: resolvedUrl.isNotEmpty
              ? Image.network(
                  resolvedUrl,
                  width: 22,
                  height: 22,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildInitialsText(initials, text),
                )
              : _buildInitialsText(initials, text),
        ),
      ),
    );
  }

  Widget _buildInitialsText(String initials, Color text) {
    String displayInitials = initials;
    if (displayInitials.length > 2) {
      displayInitials = displayInitials.substring(0, 2);
    }
    return Center(
      child: Text(
        displayInitials,
        style: GoogleFonts.inter(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: text,
        ),
      ),
    );
  }

  Widget _buildOverflowBadge(int count) {
    return Tooltip(
      message: '+$count more',
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF1F5F9),
          border: Border.all(color: const Color(0xFF94A3B8), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            )
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '+$count',
          style: GoogleFonts.inter(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskAvatarsRow(TaskItem task) {
    final List<Widget> avatarWidgets = [];
    final Set<String> processedEmpIds = {};

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

    // 1. Assigned By (AB)
    final abId = (task.rawData?['assignedBy'] ?? task.rawData?['assigned_by'] ?? task.rawData?['assignerId'] ?? task.rawData?['assigner_id'] ?? task.rawData?['crBy'] ?? task.rawData?['cr_by'] ?? task.rawData?['createdBy'] ?? task.rawData?['created_by'] ?? '').toString().trim();
    final abNm = (task.rawData?['assignedByNm'] ?? task.rawData?['assignerNm'] ?? task.rawData?['assigned_by_nm'] ?? task.rawData?['crByNm'] ?? task.rawData?['createdByNm'] ?? '').toString().trim();
    if (abId.isNotEmpty || abNm.isNotEmpty) {
      EmployeeOption? abOpt = findEmp(abId, abNm);
      String? abPhoto = abOpt?.profileImageUrl;
      if (abPhoto == null || abPhoto.isEmpty) {
        abPhoto = (task.rawData?['assignedByPhoto'] ?? task.rawData?['assigned_by_photo'] ?? '').toString();
      }
      String abInitials = abOpt?.initials ?? '';
      if (abInitials.isEmpty && abNm.isNotEmpty) {
        final parts = abNm.trim().split(RegExp(r'\s+'));
        abInitials = parts.length >= 2 ? (parts[0][0] + parts[1][0]).toUpperCase() : parts[0][0].toUpperCase();
      }
      if (abInitials.isEmpty) abInitials = 'AB';
      final String abLabel = abOpt?.name ?? (abNm.isNotEmpty ? abNm : (RegExp(r'^\d+$').hasMatch(abId) ? 'Unassigned' : (abId.isNotEmpty ? abId : 'Unassigned')));
      if (abId.isNotEmpty) processedEmpIds.add(abId);

      avatarWidgets.add(
        _buildAvatarCircle(
          photoUrl: abPhoto,
          initials: abInitials,
          bg: const Color(0xFFEEF2FF),
          text: const Color(0xFF4F46E5),
          tooltipMsg: 'Assigned By: $abLabel',
        ),
      );
    }

    // 2. Executor (EX)
    final executorId = (task.rawData?['empId'] ?? task.rawData?['empid'] ?? task.rawData?['assignedTo'] ?? task.rawData?['assigned_to'] ?? task.rawData?['executorId'] ?? task.rawData?['executor_id'] ?? '').toString().trim();
    final executorNm = (task.rawData?['empNm'] ?? task.rawData?['executorNm'] ?? task.rawData?['assigneeNm'] ?? task.rawData?['emp_nm'] ?? task.rawData?['assignedToNm'] ?? '').toString().trim();
    if (executorId.isNotEmpty || executorNm.isNotEmpty) {
      EmployeeOption? executorOpt = findEmp(executorId, executorNm);
      String? executorPhoto = executorOpt?.profileImageUrl;
      if (executorPhoto == null || executorPhoto.isEmpty) {
        executorPhoto = (task.rawData?['executorPhoto'] ?? task.rawData?['executor_photo'] ?? task.rawData?['empPhoto'] ?? task.rawData?['emp_photo'] ?? '').toString();
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
      final String executorLabel = executorOpt?.name ?? (executorNm.isNotEmpty ? executorNm : (RegExp(r'^\d+$').hasMatch(executorId) ? (executorId == _currentEmpId?.toString() ? _userName : 'Unassigned') : (executorId == _currentEmpId?.toString() ? _userName : "Executor")));
      if (executorId.isNotEmpty) processedEmpIds.add(executorId);

      avatarWidgets.add(
        _buildAvatarCircle(
          photoUrl: executorPhoto,
          initials: executorInitials,
          bg: const Color(0xFFE0F2FE),
          text: const Color(0xFF0284C7),
          tooltipMsg: 'Executor: $executorLabel',
        ),
      );
    }

    // 3. Team Members (TM)
    final List<Map<String, String>> tmList = [];
    final rawTm = task.rawData?['teamMembers'] ?? task.rawData?['team_members'] ?? task.rawData?['team'] ?? task.rawData?['contributors'];
    if (rawTm is List) {
      for (final tm in rawTm) {
        if (tm is Map) {
          final id = (tm['empId'] ?? tm['emp_id'] ?? tm['id'])?.toString().trim() ?? '';
          final nm = (tm['empNm'] ?? tm['emp_nm'] ?? tm['name'])?.toString().trim() ?? '';
          final photo = (tm['profileImageUrl'] ?? tm['profile_image_url'] ?? tm['photoUrl'] ?? tm['photo_url'])?.toString().trim();
          if (id.isNotEmpty || nm.isNotEmpty) {
            tmList.add({'id': id, 'name': nm, 'photo': photo ?? ''});
          }
        } else if (tm != null && tm.toString().trim().isNotEmpty) {
          tmList.add({'id': tm.toString().trim(), 'name': '', 'photo': ''});
        }
      }
    }
    final noteTxt = (task.rawData?['noteTxt'] ?? task.rawData?['note_txt'] ?? '').toString();
    if (noteTxt.isNotEmpty) {
      final ids = noteTxt.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
      for (final id in ids) {
        if (!tmList.any((t) => t['id'] == id)) {
          tmList.add({'id': id, 'name': '', 'photo': ''});
        }
      }
    }

    final List<Color> tmBgs = [
      const Color(0xFFF3E8FF),
      const Color(0xFFECFDF5),
      const Color(0xFFFEF3C7),
      const Color(0xFFFCE7F3),
    ];
    final List<Color> tmTexts = [
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFDB2777),
    ];
    int tmColorIdx = 0;

    for (final tm in tmList) {
      final id = tm['id'] ?? '';
      final nm = tm['name'] ?? '';
      if (id.isNotEmpty && processedEmpIds.contains(id)) continue;

      EmployeeOption? tmOpt = findEmp(id, nm);
      String? tmPhoto = tmOpt?.profileImageUrl ?? (tm['photo']?.isNotEmpty == true ? tm['photo'] : null);
      String tmInitials = tmOpt?.initials ?? '';
      if (tmInitials.isEmpty && nm.isNotEmpty) {
        final parts = nm.trim().split(RegExp(r'\s+'));
        tmInitials = parts.length >= 2 ? (parts[0][0] + parts[1][0]).toUpperCase() : parts[0][0].toUpperCase();
      }
      if (tmInitials.isEmpty) tmInitials = 'TM';
      final String tmLabel = tmOpt?.name ?? (nm.isNotEmpty ? nm : (RegExp(r'^\d+$').hasMatch(id) ? 'Unassigned' : id));
      if (id.isNotEmpty) processedEmpIds.add(id);

      final bg = tmBgs[tmColorIdx % tmBgs.length];
      final text = tmTexts[tmColorIdx % tmTexts.length];
      tmColorIdx++;

      avatarWidgets.add(
        _buildAvatarCircle(
          photoUrl: tmPhoto,
          initials: tmInitials,
          bg: bg,
          text: text,
          tooltipMsg: 'Team Member: $tmLabel',
        ),
      );
    }

    // 4. Reviewer (RV)
    final reviewerId = (task.reviewer ?? task.rawData?['reviewer'] ?? task.rawData?['reviewerId'] ?? task.rawData?['reviewer_id'] ?? task.rawData?['reviewerEmpId'] ?? task.rawData?['reviewer_emp_id'] ?? (task.reviewers.isNotEmpty ? task.reviewers.first : '')).toString().trim();
    final reviewerNm = (task.rawData?['reviewerNm'] ?? task.rawData?['reviewer_nm'] ?? '').toString().trim();
    if (reviewerId.isNotEmpty || reviewerNm.isNotEmpty) {
      EmployeeOption? reviewerOpt = findEmp(reviewerId, reviewerNm);
      String? reviewerPhoto = reviewerOpt?.profileImageUrl;
      if (reviewerPhoto == null || reviewerPhoto.isEmpty) {
        reviewerPhoto = (task.rawData?['reviewerPhoto'] ?? task.rawData?['reviewer_photo'] ?? '').toString();
      }
      String reviewerInitials = reviewerOpt?.initials ?? '';
      if (reviewerInitials.isEmpty && reviewerNm.isNotEmpty) {
        final parts = reviewerNm.trim().split(RegExp(r'\s+'));
        reviewerInitials = parts.length >= 2 ? (parts[0][0] + parts[1][0]).toUpperCase() : parts[0][0].toUpperCase();
      }
      if (reviewerInitials.isEmpty) reviewerInitials = 'RV';
      final String reviewerLabel = reviewerOpt?.name ?? (reviewerNm.isNotEmpty && !RegExp(r'^\d+$').hasMatch(reviewerNm) ? reviewerNm : (RegExp(r'^\d+$').hasMatch(reviewerId) ? 'Unassigned' : (reviewerId.isNotEmpty ? reviewerId : 'Unassigned')));

      avatarWidgets.add(
        _buildAvatarCircle(
          photoUrl: reviewerPhoto,
          initials: reviewerInitials,
          bg: const Color(0xFFF3E8FF),
          text: const Color(0xFF7C3AED),
          tooltipMsg: 'Reviewer: $reviewerLabel',
        ),
      );
    }

    // 5. Approver (AP)
    final approverId = (task.approver ?? task.rawData?['approver'] ?? task.rawData?['approverId'] ?? task.rawData?['approver_id'] ?? task.rawData?['approverEmpId'] ?? task.rawData?['approver_emp_id'] ?? (task.approvers.isNotEmpty ? task.approvers.first : '')).toString().trim();
    final approverNm = (task.rawData?['approverNm'] ?? task.rawData?['approver_nm'] ?? '').toString().trim();
    if (approverId.isNotEmpty || approverNm.isNotEmpty) {
      EmployeeOption? approverOpt = findEmp(approverId, approverNm);
      String? approverPhoto = approverOpt?.profileImageUrl;
      if (approverPhoto == null || approverPhoto.isEmpty) {
        approverPhoto = (task.rawData?['approverPhoto'] ?? task.rawData?['approver_photo'] ?? '').toString();
      }
      String approverInitials = approverOpt?.initials ?? '';
      if (approverInitials.isEmpty && approverNm.isNotEmpty) {
        final parts = approverNm.trim().split(RegExp(r'\s+'));
        approverInitials = parts.length >= 2 ? (parts[0][0] + parts[1][0]).toUpperCase() : parts[0][0].toUpperCase();
      }
      if (approverInitials.isEmpty) approverInitials = 'AP';
      final String approverLabel = approverOpt?.name ?? (approverNm.isNotEmpty && !RegExp(r'^\d+$').hasMatch(approverNm) ? approverNm : (RegExp(r'^\d+$').hasMatch(approverId) ? 'Unassigned' : (approverId.isNotEmpty ? approverId : 'Unassigned')));

      avatarWidgets.add(
        _buildAvatarCircle(
          photoUrl: approverPhoto,
          initials: approverInitials,
          bg: const Color(0xFFECFDF5),
          text: const Color(0xFF10B981),
          tooltipMsg: 'Approver: $approverLabel',
        ),
      );
    }

    if (avatarWidgets.isEmpty) {
      String? fallbackPhoto = (task.rawData?['photoUrl'] ?? task.rawData?['photo_url'] ?? task.rawData?['profileImageUrl'] ?? task.rawData?['profile_image_url'] ?? '').toString();
      if (fallbackPhoto.isEmpty) fallbackPhoto = _userPhotoUrl;
      String fallbackInitials = (task.rawData?['initials'] ?? '').toString().trim();
      if (fallbackInitials.isEmpty) fallbackInitials = _userInitials.isNotEmpty ? _userInitials : 'EX';

      avatarWidgets.add(
        _buildAvatarCircle(
          photoUrl: fallbackPhoto,
          initials: fallbackInitials,
          bg: const Color(0xFFEFF6FF),
          text: const Color(0xFF2563EB),
          tooltipMsg: 'Executor: ${_userName.isNotEmpty ? _userName : "Executor"}',
        ),
      );
    }

    const int maxVisible = 2;

    final List<Widget> finalRowWidgets = [];

    if (avatarWidgets.length <= maxVisible) {
      for (int i = 0; i < avatarWidgets.length; i++) {
        if (i > 0) finalRowWidgets.add(const SizedBox(width: 3));
        finalRowWidgets.add(avatarWidgets[i]);
      }
    } else {
      for (int i = 0; i < maxVisible; i++) {
        if (i > 0) finalRowWidgets.add(const SizedBox(width: 3));
        finalRowWidgets.add(avatarWidgets[i]);
      }
      final remainingCount = avatarWidgets.length - maxVisible;
      finalRowWidgets.add(const SizedBox(width: 3));
      finalRowWidgets.add(_buildOverflowBadge(remainingCount));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: finalRowWidgets,
      ),
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

                  // Bottom row: Priority badge (for open tasks), Lead/Lag badge (for completed tasks) and Avatars
                  Row(
                    children: [
                      if (!task.isCompleted) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: getPriorityBg(task.priority),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: getPriorityColor(task.priority).withValues(alpha: 0.15), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: getPriorityColor(task.priority),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                task.priority,
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: getPriorityColor(task.priority),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ] else ...[
                        _buildLeadLagBadge(calculateTaskLeadLag(task)),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: _buildTaskAvatarsRow(task),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Right column - aligned right
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                const SizedBox(height: 6),

                // Process & Time Icons Row (EXACT SAME AS WEBSITE!)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!task.isCompleted && task.processIcon != null) ...[
                      Tooltip(
                        message: task.processIconTooltip,
                        child: (task.isReassigned || task.processIcon == Icons.undo_rounded)
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
                const SizedBox(height: 6),

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
            ? Center(
                child: Text(
                  'loading tasks...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              )
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
                                padding: const EdgeInsets.only(top: 40.0, bottom: 40.0),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.assignment_turned_in_outlined,
                                        size: 40,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No tasks found',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
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
    if (task.isCompleted || currentStatus == 'Closed' || currentStatus == 'Completed') {
      final leadLagStr = calculateTaskLeadLag(task);
      final Match? numberMatch = RegExp(r'\d+').firstMatch(leadLagStr);
      final String? daysNum = numberMatch?.group(0);
      final lower = leadLagStr.toLowerCase();

      final bool isClosed = task.progressStatusText == 'CLOSED' ||
          currentStatus.toLowerCase() == 'closed' ||
          task.status.toLowerCase() == 'closed';
      final String statusLabel = isClosed ? 'Closed' : 'Completed';

      Color compColor = const Color(0xFF16A34A);
      String compText = statusLabel;

      if (lower.contains('lead') || lower.contains('ahead')) {
        compColor = const Color(0xFF16A34A);
        compText = daysNum != null ? '$statusLabel ($daysNum days lead)' : '$statusLabel (Lead)';
      } else if (lower.contains('lag') || lower.contains('behind') || lower.contains('delay') || lower.contains('overdue')) {
        compColor = const Color(0xFFDC2626);
        compText = daysNum != null ? '$statusLabel ($daysNum days lag)' : '$statusLabel (Lag)';
      } else if (lower.contains('on time')) {
        compColor = const Color(0xFF2563EB);
        compText = '$statusLabel (On Time)';
      } else {
        final compSts = task.computedTimeStatus;
        if (compSts == 'Lead') {
          compColor = const Color(0xFF16A34A);
          compText = '$statusLabel (Lead)';
        } else if (compSts == 'Lag') {
          compColor = const Color(0xFFDC2626);
          compText = '$statusLabel (Lag)';
        } else {
          compColor = const Color(0xFF2563EB);
          compText = '$statusLabel (On Time)';
        }
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 12, color: compColor),
          const SizedBox(width: 3),
          Text(
            compText,
            style: TextStyle(fontSize: 10, color: compColor, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    final daysLeft = _getDaysLeft(task.date);
    final compSts = task.computedTimeStatus;

    if (daysLeft == null && compSts.isEmpty) {
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
    FontWeight fontWeight = FontWeight.w600;

    if (compSts == 'Overdue' || (daysLeft != null && daysLeft < 0)) {
      final absDays = daysLeft != null ? daysLeft.abs() : 1;
      textColor = const Color(0xFFEF4444);
      icon = Icons.warning_amber_rounded;
      text = 'Overdue ($absDays ${absDays == 1 ? 'day' : 'days'})';
      fontWeight = FontWeight.bold;
    } else if (compSts == 'Due Today' || (daysLeft != null && daysLeft == 0)) {
      textColor = const Color(0xFFF59E0B);
      icon = Icons.hourglass_empty_rounded;
      text = 'Due Today (0 days left)';
      fontWeight = FontWeight.bold;
    } else if (daysLeft != null) {
      if (daysLeft == 1) {
        textColor = const Color(0xFFF59E0B);
        icon = Icons.hourglass_bottom_rounded;
        text = '1 day left';
        fontWeight = FontWeight.bold;
      } else {
        if (compSts == 'Lead') {
          textColor = const Color(0xFF16A34A);
          icon = Icons.schedule;
          text = 'Lead: $daysLeft days left';
        } else if (compSts == 'On Time') {
          textColor = const Color(0xFF2563EB);
          icon = Icons.schedule;
          text = 'On Time: $daysLeft days left';
        } else {
          textColor = (currentStatus == 'Pending' || currentStatus == 'Open') ? task.tagColor : Colors.blueGrey.shade600;
          icon = Icons.schedule;
          text = '$daysLeft days left';
        }
      }
    } else {
      textColor = const Color(0xFF3B82F6);
      icon = Icons.schedule;
      text = compSts.isNotEmpty ? compSts : 'On Time';
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
                      (task.isReassigned || task.processIcon == Icons.undo_rounded)
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
                    _buildLegendBadge('OPEN', AppColors.open, AppColors.openBg, 'Not started'),
                    _buildLegendBadge('IN PROGRESS', AppColors.inProgress, AppColors.inProgressBg, 'In progress'),
                    _buildLegendBadge('CLOSED', AppColors.closed, AppColors.closedBg, 'Closed'),
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

String calculateTaskLeadLag(TaskItem task) {
  String? endStr = task.endDate ?? task.rawEndDt ?? task.date;
  if (endStr.isEmpty || endStr.toLowerCase() == 'no date' || endStr.toLowerCase() == 'n/a') {
    return 'ON TIME';
  }

  DateTime? endDt;
  try {
    endDt = DateTime.parse(endStr);
  } catch (_) {
    endDt = TaskItem.parseDateTime(endStr);
  }
  if (endDt == null) return 'ON TIME';

  final targetDate = DateTime(endDt.year, endDt.month, endDt.day);

  if (!task.isCompleted) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (targetDate.isBefore(today)) {
      return 'OVERDUE';
    } else if (targetDate.isAtSameMomentAs(today)) {
      return 'DUE TODAY';
    } else {
      return 'ON TIME';
    }
  }

  // Task IS completed -> Calculate exact Lead/Lag days!
  final String? apiStatus = task.rawData?['leadLagStatus']?.toString() ?? 
                            task.rawData?['lead_lag_status']?.toString() ?? 
                            task.rawData?['leadLagStatusStr']?.toString() ?? 
                            task.rawData?['scheduleStatus']?.toString();
  if (apiStatus != null && 
      apiStatus.isNotEmpty && 
      apiStatus.toLowerCase() != 'null' && 
      apiStatus.toLowerCase() != 'n/a' && 
      apiStatus.contains(RegExp(r'\d+'))) {
    return _cleanLeadLagLabel(apiStatus);
  }

  String? actStr = task.rawData?['compDt']?.toString() ??
                   task.rawData?['completedDt']?.toString() ??
                   task.rawData?['actCmpDt']?.toString() ??
                   task.rawData?['act_cmp_dt']?.toString() ??
                   task.rawData?['actlEndDt']?.toString() ??
                   task.rawData?['updDt']?.toString();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime refDate = today;

  if (actStr != null && actStr.isNotEmpty) {
    DateTime? actDt;
    try { actDt = DateTime.parse(actStr); } catch (_) { actDt = TaskItem.parseDateTime(actStr); }
    if (actDt != null) {
      refDate = DateTime(actDt.year, actDt.month, actDt.day);
    }
  }

  final diffDays = targetDate.difference(refDate).inDays;

  if (diffDays > 0) {
    return 'LEAD ($diffDays DAYS)';
  } else if (diffDays < 0) {
    return 'LAG (${diffDays.abs()} DAYS)';
  } else {
    return 'ON TIME';
  }
}

String _cleanLeadLagLabel(String statusStr) {
  final s = statusStr.trim();
  if (s.isEmpty || s.toLowerCase() == 'null' || s.toLowerCase() == 'n/a' || s.toLowerCase() == 'none') {
    return 'ON TIME';
  }

  final Match? numberMatch = RegExp(r'\d+').firstMatch(s);
  final String? daysNum = numberMatch?.group(0);
  final String lower = s.toLowerCase();

  if (lower.contains('on time')) {
    return 'ON TIME';
  } else if (lower.contains('due today')) {
    return 'DUE TODAY';
  } else if (lower.contains('overdue')) {
    if (daysNum != null && daysNum.isNotEmpty) {
      return 'OVERDUE ($daysNum DAYS)';
    }
    return 'OVERDUE';
  } else if (lower.contains('lead') || lower.contains('ahead')) {
    if (daysNum != null && daysNum.isNotEmpty) {
      return 'LEAD ($daysNum DAYS)';
    }
    return 'LEAD';
  } else if (lower.contains('lag') || lower.contains('behind') || lower.contains('delay')) {
    if (daysNum != null && daysNum.isNotEmpty) {
      return 'LAG ($daysNum DAYS)';
    }
    return 'LAG';
  } else if (daysNum != null && daysNum.isNotEmpty) {
    return 'LAG ($daysNum DAYS)';
  }

  String cleaned = s.replaceAll(RegExp(r'^schedule:\s*', caseSensitive: false), '').replaceAll('+', '').replaceAll('-', '').trim();
  return cleaned.toUpperCase();
}

Widget _buildLeadLagBadge(String statusStr) {
  final String s = statusStr.trim().toLowerCase();
  
  if (s == 'null' || s == 'n/a' || s.isEmpty || s == 'none') {
    return _buildLeadLagPill('ON TIME', const Color(0xffDBEAFE), const Color(0xff2563EB));
  }

  bool isLead = s.contains('lead') || s == 'ahead';
  bool isLag = s.contains('lag') || s == 'behind' || s == 'delay' || s.contains('overdue');
  bool isDueToday = s.contains('due today');

  final String label = _cleanLeadLagLabel(statusStr);

  if (isLead) {
    return _buildLeadLagPill(label, const Color(0xffDCFCE7), const Color(0xff16A34A));
  } else if (isLag) {
    return _buildLeadLagPill(label, const Color(0xffFEE2E2), const Color(0xffDC2626));
  } else if (isDueToday) {
    return _buildLeadLagPill(label, const Color(0xffFEF3C7), const Color(0xffD97706));
  } else {
    return _buildLeadLagPill(label, const Color(0xffDBEAFE), const Color(0xff2563EB));
  }
}

Widget _buildLeadLagPill(String label, Color bgColor, Color textColor) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 3.5,
    ),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: textColor.withValues(alpha: 0.3),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: textColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
