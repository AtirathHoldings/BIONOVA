import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_item.dart';
import '../models/project_model.dart';
import '../models/employee_option.dart';
import 'main_screen.dart';
import '../services/api_service.dart';
import 'task_details_screen.dart';
import 'task_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  List<ProjectModel> _projects = [];
  List<TaskItem> _tasks = [];
  List<TaskItem> _todoTasks = [];
  List<TaskItem> _upcomingTasks = [];
  bool _isLoading = false;
  String? _error;
  String _userName = 'Welcome!';
  String? _userPhotoUrl;
  String _selectedOverviewTimeframe = 'All Time';
  int? _currentEmpId;
  Map<String, EmployeeOption> _employeeMap = {};

  int _myTasksCount = 0;
  int _openTasksCount = 0;
  int _inProgressTasksCount = 0;
  int _overdueTasksCount = 0;
  int _completedTasksCount = 0;
  int _projectsCount = 0;
  Map<String, int>? _backendStatusCounts;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCachedDashboard();
    _fetchDashboardData();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _fetchDashboardData();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _fetchDashboardData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCachedDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _userName = prefs.getString('cache_userName') ?? _userName;
        _myTasksCount = prefs.getInt('cache_myTasksCount') ?? 0;
        _openTasksCount = prefs.getInt('cache_openTasksCount') ?? 0;
        _inProgressTasksCount = prefs.getInt('cache_inProgressTasksCount') ?? 0;
        _overdueTasksCount = prefs.getInt('cache_overdueTasksCount') ?? 0;
        _completedTasksCount = prefs.getInt('cache_completedTasksCount') ?? 0;
        _projectsCount = prefs.getInt('cache_projectsCount') ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _fetchDashboardData() async {
    try {
      // Fetch user dashboard data, tasks list, individual tasks, employee ID, employees list, live projects, companies, plants in parallel
      final results = await Future.wait([
        ApiService.getUserDashboardData(),
        ApiService.getLiveTasks(),
        ApiService.getIndividualTasks(),
        ApiService.getCurrentEmployeeId(),
        ApiService.getEmployees(),
        ApiService.getLiveProjects(),
        ApiService.getCompanies(),
        ApiService.getPlants(),
      ]);

      final dashboardData = results[0] as Map<String, dynamic>?;
      final liveTasks = results[1] as List<TaskItem>;
      List<dynamic> rawIndividualTasks = results[2] as List<dynamic>;
      final currentEmpId = results[3] as int?;
      final employeesList = results[4] as List<dynamic>;
      final liveProjects = results[5] as List<ProjectModel>;
      final companies = results[6] as List<dynamic>;
      final plants = results[7] as List<dynamic>;

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

      if (dashboardData == null) {
        throw Exception('Failed to load dashboard data');
      }

      final fullName = dashboardData['fullName']?.toString() ?? '';
      final photoUrlVal = dashboardData['photoUrl']?.toString();

      // Filter individual tasks by currentEmpId (same logic as task_screen.dart)
      if (currentEmpId != null) {
        final empStr = currentEmpId.toString();
        rawIndividualTasks = rawIndividualTasks.where((t) {
          if (t is! Map) return false;
          final doer = t['empId']?.toString() ?? t['empid']?.toString();
          final assigner = t['assignedBy']?.toString() ?? t['assigned_by']?.toString();
          final reviewer = t['reviewer']?.toString();
          final approver = t['approver']?.toString();
          return doer == empStr || assigner == empStr || reviewer == empStr || approver == empStr;
        }).toList();
      }

      // Parse individual tasks safely
      final individualTasks = rawIndividualTasks
          .whereType<Map>()
          .map((json) => TaskItem.fromIndividualTask(Map<String, dynamic>.from(json), currentEmpId?.toString()))
          .toList();

      final combinedTasks = [...liveTasks, ...individualTasks];

      // Map Projects from backend dashboard data
      final List<ProjectModel> mappedProjects = [];
      final List<dynamic> myProjectsData = dashboardData['myProjects'] as List<dynamic>? ?? [];
      for (final p in myProjectsData) {
        final int prjId = (p['projectId'] as num?)?.toInt() ?? 0;
        final String prjCd = p['projectCode']?.toString() ?? '';
        final String prjNm = p['projectName']?.toString() ?? '';

        final projectTasks = combinedTasks.where((t) => 
          t.projectId == prjId || 
          (t.projectCode != null && t.projectCode == prjCd) ||
          (t.projectName != null && t.projectName == prjNm)
        ).toList();

        final int totalAssigned = projectTasks.length;
        final int completed = projectTasks.where((t) => t.isCompleted).length;

        // Use backend progress if available, otherwise fallback to task counts
        final num? progressNum = p['progress'] ?? p['projectProgress'] ?? p['progressValue'] ?? p['progress_value'];
        double progressVal;
        if (progressNum != null) {
          final double rawVal = progressNum.toDouble();
          progressVal = rawVal > 1.0 ? rawVal / 100.0 : rawVal;
        } else {
          progressVal = totalAssigned > 0 ? (completed / totalAssigned) : 0.0;
        }
        final progressTxt = '${(progressVal * 100).round()}%';
        
        Color barColor;
        if (progressVal < 0.5) {
          barColor = const Color(0xffF97316);
        } else if (progressVal < 1.0) {
          barColor = const Color(0xff3B82F6);
        } else {
          barColor = const Color(0xff22C55E);
        }

        final int assignedCount = (p['tasksAssigned'] ?? p['assigned'] ?? totalAssigned) as int;
        final int openCount = (p['openTasks'] ?? p['open'] ?? projectTasks.where((t) => !t.isCompleted).length) as int;

        // Find full-detail matched project
        ProjectModel? matchedFull;
        try {
          matchedFull = liveProjects.firstWhere((proj) => proj.prjId == prjId);
        } catch (_) {}

        // Resolve Company Name
        String? companyName = matchedFull?.companyName;
        if (companyName == null || companyName.isEmpty) {
          final coyId = matchedFull?.coyId ?? (p['coyId'] as num?)?.toInt();
          if (coyId != null && coyId > 0) {
            final matched = companies.firstWhere(
              (c) => (c['coyId'] ?? c['coy_id']) == coyId,
              orElse: () => null,
            );
            if (matched != null) companyName = matched['coyNm'];
          }
        }

        // Resolve Plant Name and Location
        String? plantName = matchedFull?.plantName;
        String? location = matchedFull?.location;
        final pltId = matchedFull?.pltId ?? (p['pltId'] as num?)?.toInt();
        if (pltId != null && pltId > 0) {
          final matched = plants.firstWhere(
            (pl) => (pl['pltId'] ?? pl['plt_id']) == pltId,
            orElse: () => null,
          );
          if (matched != null) {
            plantName ??= matched['pltNm'] ?? matched['plt_nm'];
            if (location == null || location.isEmpty) {
              final addr = matched['addr']?.toString() ?? '';
              final dist = matched['dist']?.toString() ?? '';
              location = addr.isNotEmpty ? addr : (dist.isNotEmpty ? dist : null);
            }
          }
        }

        mappedProjects.add(ProjectModel(
          prjId: prjId,
          prjCd: prjCd.isNotEmpty ? prjCd : (matchedFull?.prjCd ?? ''),
          prjNm: prjNm.isNotEmpty ? prjNm : (matchedFull?.prjNm ?? ''),
          prjDesc: matchedFull?.prjDesc ?? p['projectName']?.toString() ?? '',
          prjPrty: matchedFull?.prjPrty.isNotEmpty == true ? matchedFull!.prjPrty : 'Medium',
          prjSts: p['status']?.toString() ?? matchedFull?.prjSts ?? '',
          stDt: matchedFull?.stDt ?? '',
          endDt: matchedFull?.endDt ?? '',
          noOfDays: matchedFull?.noOfDays ?? 0,
          logo: matchedFull?.logo,
          pltId: pltId,
          coyId: matchedFull?.coyId ?? (p['coyId'] as num?)?.toInt(),
          name: prjNm.isNotEmpty ? prjNm : (matchedFull?.name ?? ''),
          details: matchedFull?.details ?? p['clientName']?.toString() ?? prjNm,
          role: p['role']?.toString() ?? matchedFull?.role ?? 'Assignee',
          assigned: assignedCount,
          open: openCount,
          progressValue: progressVal,
          progressText: progressTxt,
          barColor: barColor,
          companyName: companyName,
          plantName: plantName,
          location: location,
          leadLagStatusStr: matchedFull?.leadLagStatusStr,
        ));
      }

      // Merge any additional live projects from backend DB to display full project data
      for (final liveProj in liveProjects) {
        if (!mappedProjects.any((mp) => mp.prjId == liveProj.prjId || (mp.prjCd.isNotEmpty && mp.prjCd == liveProj.prjCd))) {
          final projectTasks = combinedTasks.where((t) =>
            t.projectId == liveProj.prjId ||
            (t.projectCode != null && t.projectCode == liveProj.prjCd) ||
            (t.projectName != null && t.projectName == liveProj.name)
          ).toList();

          final int totalAssigned = projectTasks.length;
          final int completed = projectTasks.where((t) => t.isCompleted).length;
          final double progressVal = totalAssigned > 0 ? (completed / totalAssigned) : 0.0;
          final String progressTxt = '${(progressVal * 100).round()}%';

          Color barColor;
          if (progressVal < 0.5) {
            barColor = const Color(0xffF97316);
          } else if (progressVal < 1.0) {
            barColor = const Color(0xff3B82F6);
          } else {
            barColor = const Color(0xff22C55E);
          }

          mappedProjects.add(ProjectModel(
            prjId: liveProj.prjId,
            prjCd: liveProj.prjCd,
            prjNm: liveProj.prjNm,
            prjDesc: liveProj.prjDesc,
            prjPrty: liveProj.prjPrty,
            prjSts: liveProj.prjSts,
            stDt: liveProj.stDt,
            endDt: liveProj.endDt,
            noOfDays: liveProj.noOfDays,
            logo: liveProj.logo,
            pltId: liveProj.pltId,
            coyId: liveProj.coyId,
            name: liveProj.name,
            details: liveProj.details,
            role: liveProj.role,
            assigned: totalAssigned,
            open: totalAssigned - completed,
            progressValue: progressVal,
            progressText: progressTxt,
            barColor: barColor,
            companyName: liveProj.companyName,
            plantName: liveProj.plantName,
            location: liveProj.location,
            leadLagStatusStr: liveProj.leadLagStatusStr,
          ));
        }
      }

      bool isTodoTask(TaskItem task) => task.isTodo;
      bool isUpcomingTask(TaskItem task) => task.isUpcomingTask;

      // Map To-Do List tasks matching the backend order & IDs
      final List<dynamic> todoListData = dashboardData['todoList'] as List<dynamic>? ?? [];
      final List<TaskItem> mappedTodoTasks = [];
      for (final t in todoListData) {
        final String tId = t['taskId']?.toString() ?? '';
        final match = combinedTasks.firstWhere(
          (item) => item.id == tId,
          orElse: () => const TaskItem(id: '', title: '', subtitle: '', date: '', tag: '', tagColor: Colors.transparent, tagBg: Colors.transparent, icon: Icons.error, iconColor: Colors.transparent, iconBg: Colors.transparent, status: '', priority: ''),
        );
        if (match.id.isNotEmpty && isTodoTask(match)) {
          mappedTodoTasks.add(match);
        }
      }

      // Map Upcoming tasks matching the backend order & IDs
      final List<dynamic> upcomingListData = dashboardData['upcomingTasks'] as List<dynamic>? ?? [];
      final List<TaskItem> mappedUpcomingTasks = [];
      for (final t in upcomingListData) {
        final String tId = t['taskId']?.toString() ?? '';
        final match = combinedTasks.firstWhere(
          (item) => item.id == tId,
          orElse: () => const TaskItem(id: '', title: '', subtitle: '', date: '', tag: '', tagColor: Colors.transparent, tagBg: Colors.transparent, icon: Icons.error, iconColor: Colors.transparent, iconBg: Colors.transparent, status: '', priority: ''),
        );
        if (match.id.isNotEmpty && isUpcomingTask(match)) {
          mappedUpcomingTasks.add(match);
        }
      }

      // Fallback/fill-up to client-side logic if lists are empty or have fewer than 4 items
      if (mappedTodoTasks.length < 4) {
        final existingIds = mappedTodoTasks.map((t) => t.id).toSet();
        final additional = combinedTasks.where((task) => 
          isTodoTask(task) && 
          !existingIds.contains(task.id)
        ).take(4 - mappedTodoTasks.length);
        mappedTodoTasks.addAll(additional);
      }

      if (mappedUpcomingTasks.length < 4) {
        final existingIds = mappedUpcomingTasks.map((t) => t.id).toSet();
        final additional = combinedTasks.where((task) => 
          isUpcomingTask(task) && 
          !existingIds.contains(task.id)
        ).take(4 - mappedUpcomingTasks.length);
        mappedUpcomingTasks.addAll(additional);
      }

      int safeIntVal(dynamic val, [int fallback = 0]) {
        if (val == null) return fallback;
        if (val is int) return val;
        if (val is num) return val.toInt();
        if (val is String) {
          return int.tryParse(val) ?? double.tryParse(val)?.toInt() ?? fallback;
        }
        return fallback;
      }

      final Map<String, dynamic>? countsMap = dashboardData['taskStatusCounts'] as Map<String, dynamic>?;

      int? getFromCountsMap(List<String> keys) {
        if (countsMap == null) return null;
        for (final k in keys) {
          if (countsMap.containsKey(k) && countsMap[k] != null) {
            return safeIntVal(countsMap[k]);
          }
        }
        return null;
      }

      final int myTasksVal = safeIntVal(
        dashboardData['assignedTasksCard']?['currentCount'] ??
        dashboardData['myTasksCard']?['currentCount'] ??
        dashboardData['myTasksCount'] ??
        dashboardData['assignedTasksCount'] ??
        dashboardData['totalTasks'] ??
        dashboardData['myTasks'],
        combinedTasks.length,
      );

      final int openCountVal = safeIntVal(
        dashboardData['openTasksCard']?['currentCount'] ??
        dashboardData['openTasksCount'] ??
        dashboardData['openCount'] ??
        dashboardData['openTasks'] ??
        getFromCountsMap(['Open', 'Pending', 'open', 'pending']),
        combinedTasks.where((t) => t.isOpen || t.status == 'Open' || t.status == 'Pending').length,
      );

      final int inProgressCountVal = safeIntVal(
        dashboardData['inProgressCard']?['currentCount'] ??
        dashboardData['inProgressTasksCard']?['currentCount'] ??
        dashboardData['inProgressCount'] ??
        dashboardData['inProgressTasks'] ??
        dashboardData['inProgress'] ??
        getFromCountsMap(['In Progress', 'WIP', 'in_progress', 'wip']),
        combinedTasks.where((t) => t.isInProgress || t.isUnderReview || t.status == 'In Progress' || t.status == 'Rework' || t.status == 'Reassigned').length,
      );

      final int overdueCountVal = safeIntVal(
        dashboardData['overdueTasksCard']?['currentCount'] ??
        dashboardData['overdueTasksCount'] ??
        dashboardData['overdueCount'] ??
        dashboardData['overdueTasks'] ??
        getFromCountsMap(['Overdue', 'overdue']),
        combinedTasks.where((t) => t.isOverdue).length,
      );

      final int completedCountVal = safeIntVal(
        dashboardData['completedTasksCard']?['currentCount'] ??
        dashboardData['completedTasksCount'] ??
        dashboardData['closedTasksCard']?['currentCount'] ??
        dashboardData['closedTasksCount'] ??
        dashboardData['completedCount'] ??
        dashboardData['closedCount'] ??
        getFromCountsMap(['Closed', 'Completed', 'closed', 'completed']),
        combinedTasks.where((t) => t.isCompleted || t.status == 'Closed' || t.status == 'Completed').length,
      );

      final int projectsCountVal = safeIntVal(
        dashboardData['myProjectsCard']?['currentCount'] ??
        dashboardData['myProjectsCount'] ??
        dashboardData['projectsCount'] ??
        dashboardData['totalProjects'] ??
        (dashboardData['myProjects'] is List ? (dashboardData['myProjects'] as List).length : null),
        mappedProjects.length,
      );

      final Map<String, dynamic>? countsJson = dashboardData['taskStatusCounts'] as Map<String, dynamic>?;
      final Map<String, int> tempCounts = {};
      if (countsJson != null) {
        countsJson.forEach((key, val) {
          tempCounts[key] = (val as num?)?.toInt() ?? 0;
        });
      }

      if (mounted) {
        setState(() {
          _userName = fullName.isEmpty ? 'Welcome!' : fullName;
          _userPhotoUrl = photoUrlVal;
          _projects = mappedProjects;
          _tasks = combinedTasks;
          _todoTasks = mappedTodoTasks;
          _upcomingTasks = mappedUpcomingTasks;
          _myTasksCount = myTasksVal;
          _openTasksCount = openCountVal;
          _inProgressTasksCount = inProgressCountVal;
          _overdueTasksCount = overdueCountVal;
          _completedTasksCount = completedCountVal;
          _projectsCount = projectsCountVal;
          _backendStatusCounts = tempCounts;
          _currentEmpId = currentEmpId;
          _employeeMap = tempMap;
          _isLoading = false;
        });
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('cache_userName', _userName);
          prefs.setInt('cache_myTasksCount', _myTasksCount);
          prefs.setInt('cache_openTasksCount', _openTasksCount);
          prefs.setInt('cache_inProgressTasksCount', _inProgressTasksCount);
          prefs.setInt('cache_overdueTasksCount', _overdueTasksCount);
          prefs.setInt('cache_completedTasksCount', _completedTasksCount);
          prefs.setInt('cache_projectsCount', _projectsCount);
        }).catchError((_) {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
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
    _fetchDashboardData();
  }

  String get _userInitials {
    if (_userName.isEmpty || _userName == 'Welcome!') return 'EM';
    final parts = _userName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String get _userFirstName {
    if (_userName.isEmpty || _userName == 'Welcome!') return '';
    return _userName.trim().split(RegExp(r'\s+')).first;
  }

  void _navigateToProjectDetails(ProjectModel project) {
    Navigator.pushNamed(
      context,
      '/project-details',
      arguments: project,
    );
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

  void _navigateToTab(int index) {
    MainScreen.navigatorKey.currentState?.changeTab(index);
  }

  void _openGanttView() async {
    List<ProjectModel> projectsList = _projects;
    if (projectsList.isEmpty) {
      try {
        projectsList = await ApiService.getLiveProjects();
      } catch (e) {
        debugPrint('Error fetching projects for Gantt view: $e');
      }
    }

    if (!mounted) return;

    if (projectsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active projects available for Gantt View.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (projectsList.length == 1) {
      Navigator.pushNamed(
        context,
        '/project-details',
        arguments: {
          'project': projectsList.first,
          'initialTab': 2, // Gantt Chart tab
        },
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Project for Gantt View',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: projectsList.length,
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemBuilder: (c, i) {
                    final prj = projectsList[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.bar_chart_rounded, color: Color(0xFFF59E0B), size: 20),
                      ),
                      title: Text(
                        prj.name,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${prj.prjCd} • ${prj.companyName}',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(
                          context,
                          '/project-details',
                          arguments: {
                            'project': prj,
                            'initialTab': 2, // Gantt Chart tab
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 16) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  bool _isTaskInTimeframe(TaskItem task, String timeframe) {
    if (timeframe == 'All Time') return true;

    // Try parsing start date and end date
    DateTime? stDate;
    DateTime? endDate;

    if (task.startDate != null && task.startDate!.isNotEmpty) {
      stDate = DateTime.tryParse(task.startDate!);
    }
    if (task.endDate != null && task.endDate!.isNotEmpty) {
      endDate = DateTime.tryParse(task.endDate!);
    }

    // Fallback: try parsing rawStDt / rawEndDt
    if (stDate == null && task.rawStDt != null && task.rawStDt!.isNotEmpty) {
      stDate = DateTime.tryParse(task.rawStDt!);
    }
    if (endDate == null && task.rawEndDt != null && task.rawEndDt!.isNotEmpty) {
      endDate = DateTime.tryParse(task.rawEndDt!);
    }

    // Fallback: try parsing task.date
    if (stDate == null && task.date.isNotEmpty && task.date != 'No Date' && task.date != 'N/A') {
      stDate = DateTime.tryParse(task.date);
    }

    final dateToCheck = endDate ?? stDate;
    if (dateToCheck == null) {
      return false;
    }

    final now = DateTime.now();
    
    if (timeframe == 'This Month') {
      return dateToCheck.year == now.year && dateToCheck.month == now.month;
    }

    if (timeframe == 'This Week') {
      final sunday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday % 7));
      final nextSunday = sunday.add(const Duration(days: 7));
      return dateToCheck.isAfter(sunday.subtract(const Duration(seconds: 1))) && dateToCheck.isBefore(nextSunday);
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    final todoTasks = _todoTasks;
    final upcomingTasks = _upcomingTasks;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 80.0),
                child: CircularProgressIndicator(),
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          color: Colors.redAccent,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Connection Failed',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!.replaceAll('Exception: ', '').trim(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _fetchDashboardData();
                          },
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                          label: Text(
                            'Retry Loading',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 14.0, right: 14.0, top: 16.0, bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting & Date Card in a Single Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.waving_hand_rounded,
                                  size: 16,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    (_userName.isNotEmpty && _userName != 'Welcome!')
                                        ? '${_getGreeting()}, $_userName'
                                        : _getGreeting(),
                                    style: GoogleFonts.inter(
                                      fontSize: isSmallScreen ? 14 : 17,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Here's what's happening with your work today.",
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_outlined, size: 12, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 1) KPI cards
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.35,
                        children: [
                          _buildStatCard(
                            title: 'Assigned Tasks',
                            count: '$_myTasksCount',
                            icon: Icons.playlist_add_check_rounded,
                            iconColor: const Color(0xFF2563EB),
                            iconBg: const Color(0xFFEFF6FF),
                          ),
                          _buildStatCard(
                            title: 'Open Tasks',
                            count: '$_openTasksCount',
                            icon: Icons.pending_actions_rounded,
                            iconColor: const Color(0xFF16A34A),
                            iconBg: const Color(0xFFECFDF5),
                          ),
                          _buildStatCard(
                            title: 'In Progress',
                            count: '$_inProgressTasksCount',
                            icon: Icons.timelapse_outlined,
                            iconColor: const Color(0xFFEA580C),
                            iconBg: const Color(0xFFFFF7ED),
                          ),
                          _buildStatCard(
                            title: 'Overdue',
                            count: '$_overdueTasksCount',
                            icon: Icons.warning_amber_rounded,
                            iconColor: const Color(0xFFEF4444),
                            iconBg: const Color(0xFFFEF2F2),
                          ),
                          _buildStatCard(
                            title: 'Closed',
                            count: '$_completedTasksCount',
                            icon: Icons.check_circle_outline_rounded,
                            iconColor: const Color(0xFF0D9488),
                            iconBg: const Color(0xFFF0FDFA),
                          ),
                          _buildStatCard(
                            title: 'My Projects',
                            count: '$_projectsCount',
                            icon: Icons.folder_open_outlined,
                            iconColor: const Color(0xFF7C3AED),
                            iconBg: const Color(0xFFF5F3FF),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // 2) To-Do List
                      _buildTodoSectionCard(
                        title: 'My To-Do List',
                        onTrailingTap: () {
                          TasksScreen.activeTabNotifier.value = 'To-Do List';
                          _navigateToTab(2);
                        },
                        child: todoTasks.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(child: Text('No to-do tasks found', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey))),
                              )
                            : Column(
                                children: todoTasks.take(4).map<Widget>((task) {
                                  return _buildTodoItemRedesigned(task, isSmallScreen);
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 20),
                      // 3) Upcoming Tasks
                      _buildTodoSectionCard(
                        title: 'Upcoming Tasks',
                        onTrailingTap: () {
                          TasksScreen.activeTabNotifier.value = 'Upcoming Tasks';
                          _navigateToTab(2);
                        },
                        child: upcomingTasks.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(child: Text('No upcoming tasks found', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey))),
                              )
                            : Column(
                                children: upcomingTasks.take(4).map<Widget>((task) {
                                  return _buildUpcomingTaskItemRedesigned(task);
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 20),
                      // 4) My Active Projects
                      _buildActiveProjectsSection(),
                      const SizedBox(height: 20),
                      // 5) Task Progress
                      _buildTaskProgressOverview(_tasks),
                      const SizedBox(height: 20),
                      // 6) Quick Actions
                      _buildQuickActionsGrid(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  count,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskProgressOverview(List<TaskItem> overviewTasks) {
    final filteredTasks = overviewTasks.where((task) => _isTaskInTimeframe(task, _selectedOverviewTimeframe)).toList();

    int overviewCompleted = 0;
    int overviewInProgress = 0;
    int overviewOpen = 0;
    int overviewOverdue = 0;
    int overviewTotal = 0;

    if (_selectedOverviewTimeframe == 'All Time' && _backendStatusCounts != null) {
      overviewCompleted = (_backendStatusCounts!['Closed'] ?? _backendStatusCounts!['Completed'] ?? 0);
      overviewInProgress = (_backendStatusCounts!['In Progress'] ?? 0) + (_backendStatusCounts!['Under Review'] ?? 0);
      overviewOpen = _backendStatusCounts!['Pending'] ?? 0;
      overviewOverdue = _backendStatusCounts!['Overdue'] ?? 0;
      overviewTotal = overviewCompleted + overviewInProgress + overviewOpen + overviewOverdue;
    } else {
      for (final task in filteredTasks) {
        if (task.isOverdue) {
          overviewOverdue++;
        } else if (task.isCompleted) {
          overviewCompleted++;
        } else if (task.isInProgress || task.isUnderReview) {
          overviewInProgress++;
        } else {
          overviewOpen++;
        }
      }
      overviewTotal = filteredTasks.length;
    }
    final double completedPct = overviewTotal == 0 ? 0.0 : (overviewCompleted / overviewTotal * 100);
    final double inProgressPct = overviewTotal == 0 ? 0.0 : (overviewInProgress / overviewTotal * 100);
    final double openPct = overviewTotal == 0 ? 0.0 : (overviewOpen / overviewTotal * 100);
    final double overduePct = overviewTotal == 0 ? 0.0 : (overviewOverdue / overviewTotal * 100);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Task Progress Overview',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (String val) {
                  setState(() {
                    _selectedOverviewTimeframe = val;
                  });
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'This Week',
                    child: Text('This Week', style: GoogleFonts.inter(fontSize: 12)),
                  ),
                  PopupMenuItem<String>(
                    value: 'This Month',
                    child: Text('This Month', style: GoogleFonts.inter(fontSize: 12)),
                  ),
                  PopupMenuItem<String>(
                    value: 'All Time',
                    child: Text('All Time', style: GoogleFonts.inter(fontSize: 12)),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedOverviewTimeframe,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF475569)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 36,
                          startDegreeOffset: 270,
                          sections: [
                            PieChartSectionData(
                              color: const Color(0xFF16A34A),
                              value: completedPct,
                              showTitle: false,
                              radius: 14,
                            ),
                            PieChartSectionData(
                              color: const Color(0xFFEA580C),
                              value: inProgressPct,
                              showTitle: false,
                              radius: 14,
                            ),
                            PieChartSectionData(
                              color: const Color(0xFF2563EB),
                              value: openPct,
                              showTitle: false,
                              radius: 14,
                            ),
                            PieChartSectionData(
                              color: const Color(0xFFEF4444),
                              value: overduePct,
                              showTitle: false,
                              radius: 14,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${completedPct.round()}%',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Overall\nCompletion',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewLegendItem(const Color(0xFF16A34A), 'Closed', '${completedPct.round()}%'),
                    const SizedBox(height: 8),
                    _buildOverviewLegendItem(const Color(0xFFEA580C), 'In Progress', '${inProgressPct.round()}%'),
                    const SizedBox(height: 8),
                    _buildOverviewLegendItem(const Color(0xFF2563EB), 'Open', '${openPct.round()}%'),
                    const SizedBox(height: 8),
                    _buildOverviewLegendItem(const Color(0xFFEF4444), 'Overdue', '${overduePct.round()}%'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewLegendItem(Color color, String label, String percentage) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        Text(
          percentage,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveProjectsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Active Projects',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: () => _navigateToTab(1),
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_projects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'No active projects found',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
              ),
            )
          else
            ..._projects.map((p) => _buildActiveProjectItem(p)),
        ],
      ),
    );
  }

  Widget _buildActiveProjectItem(ProjectModel project) {
    IconData iconData = Icons.business_outlined;
    Color iconColor = project.barColor;
    Color iconBg = project.barColor.withValues(alpha: 0.12);

    String statusText = project.prjSts.isNotEmpty ? project.prjSts : project.leadLagStatusStr;
    final upperSts = statusText.toUpperCase();
    Color statusColor = const Color(0xFF16A34A);

    if (upperSts.contains('RISK') || upperSts.contains('LAG') || upperSts.contains('OVERDUE')) {
      statusText = 'At Risk';
      statusColor = const Color(0xFFEF4444);
    } else if (upperSts.contains('COMPLETED') || upperSts.contains('CLOSED') || upperSts.contains('DONE')) {
      statusText = 'Completed';
      statusColor = const Color(0xFF2563EB);
    } else if (upperSts.contains('LIVE') || upperSts.contains('PROGRESS') || upperSts.contains('WIP')) {
      statusText = 'In Progress';
      statusColor = const Color(0xFF16A34A);
    } else {
      statusText = statusText.split(RegExp(r'\s+|_')).map((w) => w.isNotEmpty ? (w[0].toUpperCase() + w.substring(1).toLowerCase()) : '').join(' ').trim();
      if (statusText.isEmpty) statusText = 'In Progress';
    }

    final String subText = project.prjCd.isNotEmpty ? '${project.prjCd} • $statusText' : statusText;

    return GestureDetector(
      onTap: () => _navigateToProjectDetails(project),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subText,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: project.progressValue,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        project.progressText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoSectionCard({
    required String title,
    required VoidCallback onTrailingTap,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: onTrailingTap,
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildAvatarStack(String taskId, [int count = 2]) {
    final initials = ['SA', 'JD', 'HR', 'MK'];
    final bgColors = [
      const Color(0xFFEFF6FF),
      const Color(0xFFECFDF5),
      const Color(0xFFFFF7ED),
      const Color(0xFFF5F3FF),
    ];
    final textColors = [
      const Color(0xFF2563EB),
      const Color(0xFF059669),
      const Color(0xFFEA580C),
      const Color(0xFF7C3AED),
    ];

    final int hash = taskId.hashCode;

    return SizedBox(
      width: 55,
      height: 20,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColors[hash % bgColors.length],
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                initials[hash % initials.length][0],
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: textColors[hash % textColors.length],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColors[(hash + 1) % bgColors.length],
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                initials[(hash + 1) % initials.length][0],
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: textColors[(hash + 1) % textColors.length],
                ),
              ),
            ),
          ),
          if (count > 0)
            Positioned(
              left: 24,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF1F5F9),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$count',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTodoItemRedesigned(TaskItem task, bool isSmallScreen) {
    final Color leftBarColor = task.progressStatusColor;

    String prjName = task.projectName ?? task.subtitle.split('•').first.trim();
    if (prjName.isEmpty || prjName == 'Role: Executor' || prjName == 'Role: Reviewer' || prjName == 'Role: Approver' || prjName.startsWith('Role:')) {
      prjName = task.taskCode;
    }

    return GestureDetector(
      onTap: () => _navigateToTaskDetails(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: leftBarColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: task.progressStatusBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: task.progressStatusColor.withValues(alpha: 0.15), width: 1),
                            ),
                            child: Text(
                              task.progressStatusText,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: task.progressStatusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prjName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            task.date,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: getPriorityColor(task.priority),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          _buildTaskAvatarsRow(task),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTaskItemRedesigned(TaskItem task) {
    final Color leftBarColor = task.progressStatusColor;

    String prjName = task.projectName ?? task.subtitle.split('•').first.trim();
    if (prjName.isEmpty || prjName == 'Role: Executor' || prjName == 'Role: Reviewer' || prjName == 'Role: Approver' || prjName.startsWith('Role:')) {
      prjName = task.taskCode;
    }

    return GestureDetector(
      onTap: () => _navigateToTaskDetails(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: leftBarColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: task.progressStatusBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: task.progressStatusColor.withValues(alpha: 0.15), width: 1),
                            ),
                            child: Text(
                              task.progressStatusText,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: task.progressStatusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prjName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            task.date,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: getPriorityColor(task.priority),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          _buildTaskAvatarsRow(task),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      {
        'label': 'My Tasks',
        'icon': Icons.assignment_turned_in_outlined,
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
        'action': () => _navigateToTab(2),
      },
      {
        'label': 'My Projects',
        'icon': Icons.folder_open_outlined,
        'color': const Color(0xFF16A34A),
        'bg': const Color(0xFFECFDF5),
        'action': () => _navigateToTab(1),
      },
      {
        'label': 'Calendar',
        'icon': Icons.calendar_month_outlined,
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF5F3FF),
        'action': () => _navigateToTab(3),
      },
      {
        'label': 'Gantt View',
        'icon': Icons.bar_chart_rounded,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFF7ED),
        'action': () => _openGanttView(),
      },
      {
        'label': 'Assign Task',
        'icon': Icons.person_add_alt_1_outlined,
        'color': const Color(0xFF0D9488),
        'bg': const Color(0xFFF0FDFA),
        'action': () {
          Navigator.pushNamed(context, '/individual-tasks-list');
        },
      },
      {
        'label': 'More',
        'icon': Icons.more_horiz_rounded,
        'color': const Color(0xFF475569),
        'bg': const Color(0xFFF1F5F9),
        'action': () => _navigateToTab(4),
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: actions.length,
            itemBuilder: (context, idx) {
              final act = actions[idx];
              return InkWell(
                onTap: act['action'] as VoidCallback,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: act['bg'] as Color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(act['icon'] as IconData, color: act['color'] as Color, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        act['label'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}