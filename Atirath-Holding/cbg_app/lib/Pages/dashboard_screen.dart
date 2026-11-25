import 'dart:async';
import 'dart:convert';
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
import '../utils/app_colors.dart';
import 'task_details_screen.dart';
import 'task_screen.dart';
import '../widgets/reassign_icon.dart';

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
  Map<String, dynamic>? _backendTaskProgressOverview;
  double? _backendOverallCompletion;
  Timer? _autoRefreshTimer;

  static double? _extractPercentage(dynamic val) {
    if (val == null) return null;
    double? numVal;
    if (val is num) {
      numVal = val.toDouble();
    } else if (val is String) {
      final clean = val.replaceAll('%', '').trim();
      numVal = double.tryParse(clean);
    } else if (val is Map) {
      final raw = val['percentage'] ??
          val['pct'] ??
          val['progress'] ??
          val['value'] ??
          val['overallCompletion'] ??
          val['overall_completion'] ??
          val['completionPercentage'] ??
          val['completion_percentage'] ??
          val['progressPercentage'] ??
          val['progress_percentage'] ??
          val['currentCount'] ??
          val['count'];
      return _extractPercentage(raw);
    }
    if (numVal != null && !numVal.isNaN && !numVal.isInfinite) {
      // If backend provided fraction between 0.0 and 1.0 (e.g. 0.75 for 75%), convert to percentage
      if (numVal > 0.0 && numVal <= 1.0) {
        numVal = numVal * 100.0;
      }
      return numVal.clamp(0.0, 100.0);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCachedDashboard();
    _fetchDashboardData();
    _startAutoRefresh();
  }

  String _calculateUserLeadLag(List<dynamic> tasks, String projEndDt) {
    DateTime? maxTargetEnd;
    DateTime? refDate;

    for (final t in tasks) {
      String? endStr;
      String? actStr;
      if (t is Map) {
        endStr = (t['endDt'] ?? t['enddt'] ?? t['endDate'] ?? t['end_dt'])?.toString();
        actStr = (t['actCmpDt'] ?? t['actcmpdt'] ?? t['act_cmp_dt'])?.toString();
        if (actStr == null || actStr.isEmpty) {
          final st = (t['taskSts'] ?? t['tasksts'] ?? t['status'] ?? '').toString().toUpperCase();
          if (st == 'COMPLETED' || st == 'CLOSED' || st == 'DONE') {
            actStr = endStr;
          }
        }
      } else if (t is TaskItem) {
        endStr = t.endDate ?? t.rawEndDt ?? t.date;
        actStr = t.rawData?['actCmpDt']?.toString() ?? t.rawData?['act_cmp_dt']?.toString() ?? (t.isCompleted ? endStr : null);
      }

      if (endStr != null && endStr.isNotEmpty) {
        final d = DateTime.tryParse(endStr);
        if (d != null && (maxTargetEnd == null || d.isAfter(maxTargetEnd))) {
          maxTargetEnd = d;
        }
      }
      if (actStr != null && actStr.isNotEmpty) {
        final d = DateTime.tryParse(actStr);
        if (d != null && (refDate == null || d.isAfter(refDate))) {
          refDate = d;
        }
      }
    }

    if (maxTargetEnd == null && projEndDt.isNotEmpty) {
      maxTargetEnd = DateTime.tryParse(projEndDt);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    refDate ??= today;

    if (maxTargetEnd != null) {
      final targetDate = DateTime(maxTargetEnd.year, maxTargetEnd.month, maxTargetEnd.day);
      final actualDate = DateTime(refDate.year, refDate.month, refDate.day);
      final diffDays = targetDate.difference(actualDate).inDays;

      if (diffDays > 0) {
        return 'Lead ($diffDays Days)';
      } else if (diffDays < 0) {
        return 'Lag (${diffDays.abs()} Days)';
      } else {
        return 'On Time';
      }
    }
    return 'On Time';
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted && !_isLoading) {
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
      int cachedProjects = prefs.getInt('cache_projectsCount') ?? 0;
      if (cachedProjects == 0) {
        final cachedProjectsJson = prefs.getString('cached_json_projects');
        if (cachedProjectsJson != null && cachedProjectsJson.isNotEmpty) {
          try {
            final List<dynamic> list = jsonDecode(cachedProjectsJson);
            if (list.isNotEmpty) {
              cachedProjects = list.length;
            }
          } catch (_) {}
        }
      }
      setState(() {
        _userName = prefs.getString('cache_userName') ?? _userName;
        _myTasksCount = prefs.getInt('cache_myTasksCount') ?? 0;
        _openTasksCount = prefs.getInt('cache_openTasksCount') ?? 0;
        _inProgressTasksCount = prefs.getInt('cache_inProgressTasksCount') ?? 0;
        _overdueTasksCount = prefs.getInt('cache_overdueTasksCount') ?? 0;
        _completedTasksCount = prefs.getInt('cache_completedTasksCount') ?? 0;
        _projectsCount = cachedProjects;
        _backendOverallCompletion = prefs.getDouble('cache_overallCompletion');
      });
    } catch (_) {}
  }

  Future<void> _handleRefresh() async {
    try {
      await ApiService.preloadAllData(forceRefresh: true);
      await _fetchDashboardData(forceRefresh: true);
    } catch (_) {}
  }

  Future<void> _fetchDashboardData({bool forceRefresh = false}) async {
    try {
      // Fetch user dashboard data, tasks list, individual tasks, employee ID, employees list, live projects, companies, plants in parallel
      final results = await Future.wait([
        ApiService.getUserDashboardData(forceRefresh: forceRefresh),
        ApiService.getLiveTasks(forceRefresh: forceRefresh),
        ApiService.getIndividualTasks(forceRefresh: forceRefresh),
        ApiService.getCurrentEmployeeId(),
        ApiService.getEmployees(forceRefresh: forceRefresh),
        ApiService.getLiveProjects(forceRefresh: forceRefresh),
        ApiService.getCompanies(forceRefresh: forceRefresh),
        ApiService.getPlants(forceRefresh: forceRefresh),
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

      String fullName = dashboardData['fullName']?.toString() ?? '';
      if (fullName.isEmpty) {
        final fst = (dashboardData['fstNm'] ?? dashboardData['firstName'] ?? '').toString().trim();
        final lst = (dashboardData['lstNm'] ?? dashboardData['lastName'] ?? '').toString().trim();
        fullName = "$fst $lst".trim();
      }
      final photoUrlVal = dashboardData['photoUrl']?.toString();

      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('userRole') ?? '';
      final lowerRole = userRole.toLowerCase();
      final bool isAdminOrManager = lowerRole.contains('admin') ||
          lowerRole.contains('manager') ||
          lowerRole.contains('pm') ||
          lowerRole.contains('lead');
      final bool filterByEmp = !isAdminOrManager && currentEmpId != null;

      List<TaskItem> filteredLiveTasks = liveTasks;
      List<dynamic> filteredRawIndividualTasks = rawIndividualTasks;

      // Filter tasks by currentEmpId (consistent with task_screen.dart)
      if (filterByEmp && currentEmpId != null) {
        final empStr = currentEmpId.toString();

        filteredLiveTasks = liveTasks.where((t) {
          final raw = t.rawData ?? {};
          final doer = (raw['empId'] ?? raw['empid'] ?? raw['assignedTo'] ?? raw['executorId'])?.toString();
          final reviewer = (raw['reviewerId'] ?? raw['reviewer'] ?? t.reviewer)?.toString();
          final approver = (raw['approverId'] ?? raw['approver'] ?? t.approver)?.toString();
          final assigner = (raw['assignedBy'] ?? raw['assigned_by'] ?? raw['assignerId'] ?? raw['assigner_id'] ?? raw['crBy'] ?? raw['cr_by'])?.toString();
          final noteTxt = (raw['noteTxt'] ?? raw['note_txt'] ?? '').toString();
          final hasTeamMember = noteTxt.split(',').map((e) => e.trim()).contains(empStr) ||
              (raw['teamMembers'] is List && (raw['teamMembers'] as List).any((tm) => tm['empId']?.toString() == empStr || tm['emp_id']?.toString() == empStr));
          return doer == empStr || reviewer == empStr || approver == empStr || assigner == empStr || t.isCurrentUserReviewer || t.isCurrentUserApprover || hasTeamMember;
        }).toList();

        filteredRawIndividualTasks = rawIndividualTasks.where((t) {
          if (t is! Map) return false;
          final doer = (t['empId'] ?? t['empid'] ?? t['assignedTo'] ?? t['executorId'])?.toString();
          final reviewer = (t['reviewerId'] ?? t['reviewer'])?.toString();
          final approver = (t['approverId'] ?? t['approver'])?.toString();
          final assigner = (t['assignedBy'] ?? t['assigned_by'] ?? t['assignerId'] ?? t['assigner_id'] ?? t['crBy'] ?? t['cr_by'])?.toString();
          final noteTxt = (t['noteTxt'] ?? t['note_txt'] ?? '').toString();
          final hasTeamMember = noteTxt.split(',').map((e) => e.trim()).contains(empStr) ||
              (t['teamMembers'] is List && (t['teamMembers'] as List).any((tm) => tm['empId']?.toString() == empStr || tm['emp_id']?.toString() == empStr));
          return doer == empStr || reviewer == empStr || approver == empStr || assigner == empStr || hasTeamMember;
        }).toList();
      }

      // Parse individual tasks safely
      final individualTasks = filteredRawIndividualTasks
          .whereType<Map>()
          .map((json) => TaskItem.fromIndividualTask(Map<String, dynamic>.from(json), currentEmpId?.toString()))
          .toList();

      final combinedTasks = [...filteredLiveTasks, ...individualTasks].where((task) => !task.isDraft).toList();

      // Map Projects from backend dashboard data
      final List<ProjectModel> mappedProjects = [];
      final List<dynamic> myProjectsData = (dashboardData['myProjects'] ??
          dashboardData['my_projects'] ??
          dashboardData['userProjects'] ??
          dashboardData['user_projects'] ??
          dashboardData['assignedProjects'] ??
          dashboardData['assigned_projects'] ??
          dashboardData['projects']) as List<dynamic>? ?? [];

      final List<ProjectModel> baseProjectList = [];
      if (myProjectsData.isNotEmpty) {
        for (final p in myProjectsData) {
          if (p is Map) {
            final map = Map<String, dynamic>.from(p);
            final dbProj = ProjectModel.fromJson(map);

            ProjectModel? matchedFull;
            try {
              matchedFull = liveProjects.firstWhere(
                (proj) => (dbProj.prjId > 0 && proj.prjId == dbProj.prjId) || 
                          (dbProj.prjCd.isNotEmpty && proj.prjCd == dbProj.prjCd) || 
                          (dbProj.name.isNotEmpty && proj.name.trim().toLowerCase() == dbProj.name.trim().toLowerCase()),
              );
            } catch (_) {}

            final merged = ProjectModel(
              prjId: dbProj.prjId > 0 ? dbProj.prjId : (matchedFull?.prjId ?? 0),
              prjCd: dbProj.prjCd.isNotEmpty ? dbProj.prjCd : (matchedFull?.prjCd ?? ''),
              prjNm: dbProj.prjNm.isNotEmpty ? dbProj.prjNm : (matchedFull?.prjNm ?? ''),
              prjDesc: dbProj.prjDesc.isNotEmpty ? dbProj.prjDesc : (matchedFull?.prjDesc ?? ''),
              prjPrty: matchedFull?.prjPrty.isNotEmpty == true ? matchedFull!.prjPrty : (dbProj.prjPrty.isNotEmpty ? dbProj.prjPrty : 'Medium'),
              prjSts: dbProj.prjSts.isNotEmpty ? dbProj.prjSts : (matchedFull?.prjSts ?? 'In Progress'),
              stDt: dbProj.stDt.isNotEmpty ? dbProj.stDt : (matchedFull?.stDt ?? ''),
              endDt: dbProj.endDt.isNotEmpty ? dbProj.endDt : (matchedFull?.endDt ?? ''),
              noOfDays: dbProj.noOfDays > 0 ? dbProj.noOfDays : (matchedFull?.noOfDays ?? 0),
              logo: dbProj.logo ?? matchedFull?.logo,
              pltId: matchedFull?.pltId != 0 ? matchedFull?.pltId : dbProj.pltId,
              coyId: matchedFull?.coyId != 0 ? matchedFull?.coyId : dbProj.coyId,
              name: dbProj.name.isNotEmpty ? dbProj.name : (matchedFull?.name ?? ''),
              details: dbProj.details.isNotEmpty ? dbProj.details : (matchedFull?.details ?? dbProj.name),
              role: dbProj.role.isNotEmpty ? dbProj.role : (matchedFull?.role ?? 'Assignee'),
              assigned: dbProj.rawAssigned ?? matchedFull?.rawAssigned,
              open: dbProj.rawOpen ?? matchedFull?.rawOpen,
              inProgress: dbProj.rawInProgress ?? matchedFull?.rawInProgress,
              progressValue: dbProj.rawProgressValue ?? matchedFull?.rawProgressValue,
              progressText: dbProj.progressText != '0%' ? dbProj.progressText : matchedFull?.progressText,
              barColor: dbProj.barColor,
              companyName: matchedFull?.companyName ?? dbProj.companyName,
              plantName: matchedFull?.plantName ?? dbProj.plantName,
              location: matchedFull?.location ?? dbProj.location,
              leadLagStatusStr: matchedFull?.leadLagStatusStr ?? dbProj.leadLagStatusStr,
            );

            if (!baseProjectList.any((p) => (p.prjId > 0 && p.prjId == merged.prjId) || (p.prjCd.isNotEmpty && p.prjCd == merged.prjCd))) {
              baseProjectList.add(merged);
            }
          }
        }
      }

      // Merge remaining projects from liveProjects:
      // For employees, liveProjects was fetched from /api/project-live/by-employee/$currentEmpId,
      // so all of them are legitimate projects for this employee.
      // For admin/manager, if myProjectsData was empty, include all liveProjects.
      if (filterByEmp) {
        for (final fullProj in liveProjects) {
          if (!baseProjectList.any((p) => (p.prjId > 0 && p.prjId == fullProj.prjId) || (p.prjCd.isNotEmpty && p.prjCd == fullProj.prjCd))) {
            baseProjectList.add(fullProj);
          }
        }
      } else {
        if (baseProjectList.isEmpty) {
          baseProjectList.addAll(liveProjects);
        }
      }

      for (final p in baseProjectList) {
        List<dynamic> milestoneTasksRaw = [];
        try {
          if (p.prjId > 0) {
            final fetchedMilestones = await ApiService.getMilestones(p.prjId);
            final taskFutures = fetchedMilestones.map((m) async {
              final rawMId = m['mId'] ?? m['mid'] ?? m['m_id'] ?? m['id'] ?? m['milestoneId'] ?? m['mlstnId'];
              if (rawMId == null) return <dynamic>[];
              final int mId = (rawMId as num).toInt();
              try {
                return await ApiService.getTasksForMilestone(mId);
              } catch (_) {
                return <dynamic>[];
              }
            }).toList();
            final allMTasks = await Future.wait(taskFutures);
            for (final tList in allMTasks) {
              milestoneTasksRaw.addAll(tList);
            }
          }
        } catch (e) {
          debugPrint('Error fetching milestone tasks for dashboard project ${p.prjId}: $e');
        }

        int totalAssigned = 0;
        int completedCount = 0;
        int openCount = 0;
        int inProgressCount = 0;
        double totalWeightedProgress = 0.0;

        List<dynamic> effectiveTasks = [];
        if (milestoneTasksRaw.isNotEmpty) {
          final List<dynamic> filteredMilestoneTasks = [];
          for (var t in milestoneTasksRaw) {
            if (filterByEmp && currentEmpId != null) {
              final strEmpId = currentEmpId.toString();
              final doerId = (t['empId'] ?? t['empid'])?.toString();
              final reviewer = t['reviewer']?.toString();
              final approver = t['approver']?.toString();
              final noteTxt = (t['noteTxt'] ?? t['note_txt'] ?? '').toString();
              final hasTeamMemberInTeamMembers = (t['teamMembers'] is List) && (t['teamMembers'] as List).any((tm) => tm['empId']?.toString() == strEmpId || tm['emp_id']?.toString() == strEmpId);
              final isTeamMember = noteTxt.split(',').map((e) => e.trim()).contains(strEmpId) || hasTeamMemberInTeamMembers;
              
              if (doerId == strEmpId || reviewer == strEmpId || approver == strEmpId || isTeamMember) {
                filteredMilestoneTasks.add(t);
              }
            } else {
              filteredMilestoneTasks.add(t);
            }
          }

          effectiveTasks = filteredMilestoneTasks;
          totalAssigned = filteredMilestoneTasks.length;
          for (final t in filteredMilestoneTasks) {
            String tStatus = '';
            final rawSts = t['taskSts'] ?? t['task_sts'] ?? t['status'] ?? t['taskStatus'] ?? t['task_status'] ?? t['sts'];
            if (rawSts != null) {
              if (rawSts is Map) {
                tStatus = (rawSts['statusNm'] ?? rawSts['status_nm'] ?? rawSts['name'] ?? rawSts['statusId'] ?? '').toString();
              } else {
                tStatus = rawSts.toString();
              }
            }
            tStatus = tStatus.toUpperCase().trim();

            double taskProg = 0.0;
            switch (tStatus) {
              case '4':
              case 'COMPLETED':
              case 'CLOSED':
              case 'DONE':
              case 'FINISHED':
                taskProg = 1.0;
                completedCount++;
                break;
              case 'SUBMIT_REVIEW':
              case 'UNDER_REVIEW':
              case 'UNDERREVIEW':
              case 'SUBMIT REVIEW':
              case 'UNDER REVIEW':
                taskProg = 0.8;
                inProgressCount++;
                break;
              case 'WIP':
              case 'INPROGRESS':
              case 'IN PROGRESS':
              case 'IN_PROGRESS':
                taskProg = 0.5;
                inProgressCount++;
                break;
              case 'OVERDUE':
                taskProg = 0.5;
                openCount++;
                break;
              case 'REASSIGN':
              case 'REASSIGNED':
                taskProg = 0.4;
                openCount++;
                break;
              case 'REWORK':
                taskProg = 0.3;
                openCount++;
                break;
              default: // OPEN
                taskProg = 0.0;
                openCount++;
                break;
            }
            totalWeightedProgress += taskProg;
          }
        } else {
          final projectTasks = combinedTasks.where((t) => 
            (p.prjId > 0 && t.projectId == p.prjId) || 
            (p.prjCd.isNotEmpty && t.projectCode != null && t.projectCode == p.prjCd) ||
            (p.name.isNotEmpty && t.projectName != null && t.projectName!.trim().toLowerCase() == p.name.trim().toLowerCase())
          ).toList();

          effectiveTasks = projectTasks;
          totalAssigned = projectTasks.length;
          for (final t in projectTasks) {
            final String st = (t.status).toUpperCase().trim();
            double taskProg = 0.0;
            if (t.isCompleted || st == 'COMPLETED' || st == 'CLOSED' || st == 'DONE' || st == 'FINISHED' || st == '4') {
              taskProg = 1.0;
              completedCount++;
            } else if (st == 'SUBMIT_REVIEW' || st == 'UNDER_REVIEW' || st == 'UNDERREVIEW' || st == 'SUBMIT REVIEW' || st == 'UNDER REVIEW' || t.isUnderReview) {
              taskProg = 0.8;
              inProgressCount++;
            } else if (st == 'WIP' || st == 'INPROGRESS' || st == 'IN PROGRESS' || st == 'IN_PROGRESS' || t.isInProgress) {
              taskProg = 0.5;
              inProgressCount++;
            } else if (st == 'OVERDUE' || t.isOverdue) {
              taskProg = 0.5;
              openCount++;
            } else if (st == 'REASSIGN' || st == 'REASSIGNED') {
              taskProg = 0.4;
              openCount++;
            } else if (st == 'REWORK') {
              taskProg = 0.3;
              openCount++;
            } else {
              taskProg = 0.0;
              openCount++;
            }
            totalWeightedProgress += taskProg;
          }
        }

        double progressVal;
        if (totalAssigned > 0) {
          progressVal = totalWeightedProgress / totalAssigned;
        } else if (p.rawProgressValue != null) {
          final double val = p.rawProgressValue!;
          progressVal = val > 1.0 ? val / 100.0 : val;
        } else {
          progressVal = 0.0;
        }

        final double progressPct = progressVal * 100;
        final progressTxt = '${progressPct.toStringAsFixed(1)}%';
            
        Color barColor;
        if (progressVal < 0.5) {
          barColor = const Color(0xffF97316);
        } else if (progressVal < 1.0) {
          barColor = const Color(0xff3B82F6);
        } else {
          barColor = const Color(0xff22C55E);
        }

        String? companyName = p.companyName;
        if (companyName == null || companyName.isEmpty) {
          final coyId = p.coyId;
          if (coyId != null && coyId > 0) {
            final matched = companies.firstWhere(
              (c) => (c['coyId'] ?? c['coy_id']) == coyId,
              orElse: () => null,
            );
            if (matched != null) companyName = matched['coyNm'];
          }
        }

        String? plantName = p.plantName;
        String? location = p.location;
        final pltId = p.pltId;
        if (pltId != null && pltId > 0 && (plantName == null || plantName.isEmpty)) {
          final matched = plants.firstWhere(
            (pl) => (pl['pltId'] ?? pl['plt_id']) == pltId,
            orElse: () => null,
          );
          if (matched != null) {
            plantName = matched['pltNm'] ?? matched['plt_nm'];
            if (location == null || location.isEmpty) {
              final addr = matched['addr']?.toString() ?? '';
              final dist = matched['dist']?.toString() ?? '';
              location = addr.isNotEmpty ? addr : (dist.isNotEmpty ? dist : null);
            }
          }
        }

        final int finalAssigned = totalAssigned > 0 ? totalAssigned : (p.rawAssigned ?? 0);
        final int finalOpen = totalAssigned > 0 ? openCount : (p.rawOpen ?? 0);
        final bool isUserClosed = finalAssigned > 0 && completedCount == finalAssigned;
        final String calculatedStatus = _calculateUserLeadLag(effectiveTasks, p.endDt);
        final String apiStatus = (p.leadLagStatusStr).trim();
        final String userLeadLag = (apiStatus.contains(RegExp(r'\d+')))
            ? apiStatus
            : calculatedStatus;

        mappedProjects.add(ProjectModel(
          prjId: p.prjId,
          prjCd: p.prjCd,
          prjNm: p.prjNm,
          prjDesc: p.prjDesc,
          prjPrty: p.prjPrty,
          prjSts: isUserClosed ? 'CLOSED' : p.prjSts,
          stDt: p.stDt,
          endDt: p.endDt,
          noOfDays: p.noOfDays,
          logo: p.logo,
          pltId: pltId,
          coyId: p.coyId,
          name: p.name,
          details: p.details.isNotEmpty ? p.details : (companyName ?? p.name),
          role: p.role,
          assigned: finalAssigned,
          open: isUserClosed ? 0 : finalOpen,
          inProgress: isUserClosed ? 0 : inProgressCount,
          closed: isUserClosed ? finalAssigned : completedCount,
          progressValue: isUserClosed ? 1.0 : progressVal,
          progressText: isUserClosed ? '100.0%' : progressTxt,
          barColor: isUserClosed ? const Color(0xff22C55E) : barColor,
          companyName: companyName,
          plantName: plantName,
          location: location,
          leadLagStatusStr: userLeadLag,
        ));
      }

      bool isTodoTask(TaskItem task) => !task.isCompleted && !task.isDraft && task.isTodo;
      bool isUpcomingTask(TaskItem task) => !task.isCompleted && !task.isDraft && task.isUpcomingTask;

      // Map To-Do List tasks matching the backend order & IDs
      final List<dynamic> todoListData = (dashboardData['todoList'] ?? dashboardData['todo_list'] ?? dashboardData['todo']) as List<dynamic>? ?? [];
      final List<TaskItem> mappedTodoTasks = [];
      for (final t in todoListData) {
        if (t is Map) {
          final map = Map<String, dynamic>.from(t);
          final String tId = (map['taskId'] ?? map['task_id'] ?? map['empTaskId'] ?? map['emp_task_id'] ?? map['id'] ?? '').toString();
          final String title = (map['taskNm'] ?? map['task_nm'] ?? map['title'] ?? map['name'] ?? '').toString().trim().toLowerCase();

          TaskItem? match;
          for (final item in combinedTasks) {
            if ((tId.isNotEmpty && (item.id == tId || item.id.endsWith(tId))) ||
                (title.isNotEmpty && item.title.trim().toLowerCase() == title)) {
              match = item;
              break;
            }
          }
          if (match != null) {
            if (!mappedTodoTasks.any((m) => m.id == match!.id)) {
              mappedTodoTasks.add(match);
            }
          } else {
            try {
              final parsed = TaskItem.fromIndividualTask(map, currentEmpId?.toString());
              if (!parsed.isDraft && !mappedTodoTasks.any((m) => m.id == parsed.id)) {
                mappedTodoTasks.add(parsed);
              }
            } catch (_) {}
          }
        }
      }

      // Map Upcoming tasks matching the backend order & IDs
      final List<dynamic> upcomingListData = (dashboardData['upcomingTasks'] ?? dashboardData['upcoming_tasks'] ?? dashboardData['upcoming']) as List<dynamic>? ?? [];
      final List<TaskItem> mappedUpcomingTasks = [];
      for (final t in upcomingListData) {
        if (t is Map) {
          final map = Map<String, dynamic>.from(t);
          final String tId = (map['taskId'] ?? map['task_id'] ?? map['empTaskId'] ?? map['emp_task_id'] ?? map['id'] ?? '').toString();
          final String title = (map['taskNm'] ?? map['task_nm'] ?? map['title'] ?? map['name'] ?? '').toString().trim().toLowerCase();

          TaskItem? match;
          for (final item in combinedTasks) {
            if ((tId.isNotEmpty && (item.id == tId || item.id.endsWith(tId))) ||
                (title.isNotEmpty && item.title.trim().toLowerCase() == title)) {
              match = item;
              break;
            }
          }
          if (match != null) {
            if (!mappedUpcomingTasks.any((m) => m.id == match!.id)) {
              mappedUpcomingTasks.add(match);
            }
          } else {
            try {
              final parsed = TaskItem.fromIndividualTask(map, currentEmpId?.toString());
              if (!parsed.isDraft && !mappedUpcomingTasks.any((m) => m.id == parsed.id)) {
                mappedUpcomingTasks.add(parsed);
              }
            } catch (_) {}
          }
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

      final dynamic rawProgressOverview = dashboardData['taskProgressOverview'] ??
          dashboardData['task_progress_overview'] ??
          dashboardData['progressOverview'] ??
          dashboardData['progress_overview'] ??
          dashboardData['taskProgress'] ??
          dashboardData['task_progress'] ??
          dashboardData['taskOverview'] ??
          dashboardData['task_overview'] ??
          dashboardData['taskStatusOverview'] ??
          dashboardData['task_status_overview'];

      int safeIntVal(dynamic val, [int fallback = 0]) {
        if (val == null) return fallback;
        if (val is int) return val;
        if (val is num) return val.toInt();
        if (val is String) {
          return int.tryParse(val) ?? double.tryParse(val)?.toInt() ?? fallback;
        }
        if (val is List) {
          return val.length;
        }
        return fallback;
      }

      int? extractCardCount(dynamic card) {
        if (card == null) return null;
        if (card is int) return card;
        if (card is num) return card.toInt();
        if (card is String) return int.tryParse(card);
        if (card is Map) {
          final countVal = card['currentCount'] ??
              card['current_count'] ??
              card['count'] ??
              card['total'] ??
              card['value'] ??
              card['cnt'] ??
              card['taskCount'] ??
              card['tasksCount'] ??
              card['inProgressCount'] ??
              card['in_progress_count'] ??
              card['wipCount'] ??
              card['wip_count'] ??
              card['projectCount'] ??
              card['projectsCount'] ??
              card['myProjectsCount'] ??
              card['my_projects_count'];
          if (countVal != null) return safeIntVal(countVal);
        }
        return null;
      }

      int? findCountFromCardListByKeywords(dynamic list, List<String> keywords) {
        if (list is! List) return null;
        for (final item in list) {
          if (item is Map) {
            final title = (item['title'] ??
                    item['name'] ??
                    item['label'] ??
                    item['cardTitle'] ??
                    item['card_title'] ??
                    item['kpiTitle'] ??
                    item['key'] ??
                    '')
                .toString()
                .toLowerCase();
            for (final kw in keywords) {
              if (title.contains(kw.toLowerCase())) {
                final cnt = extractCardCount(item);
                if (cnt != null) return cnt;
              }
            }
          }
        }
        return null;
      }

      int? findCountFromCardList(dynamic list) =>
          findCountFromCardListByKeywords(list, ['project']);

      final cardListKeys = [
        'kpiCards',
        'kpi_cards',
        'cards',
        'stats',
        'metrics',
        'summary',
        'kpis',
        'kpiList',
        'taskCards',
        'task_cards',
        'overviewCards',
        'overview_cards',
      ];

      int? searchCardLists(List<String> keywords) {
        for (final lk in cardListKeys) {
          if (dashboardData[lk] is List) {
            final cnt = findCountFromCardListByKeywords(dashboardData[lk], keywords);
            if (cnt != null && cnt >= 0) return cnt;
          }
        }
        return null;
      }

      final Map<String, dynamic>? countsMap = (dashboardData['taskStatusCounts'] ??
          dashboardData['task_status_counts'] ??
          dashboardData['statusCounts'] ??
          dashboardData['status_counts'] ??
          dashboardData['counts'] ??
          (rawProgressOverview is Map
              ? (rawProgressOverview['statusCounts'] ??
                  rawProgressOverview['taskStatusCounts'] ??
                  rawProgressOverview['counts'])
              : null)) as Map<String, dynamic>?;

      int? getFromCountsMap(List<String> keys) {
        if (countsMap == null) return null;
        for (final k in keys) {
          if (countsMap.containsKey(k) && countsMap[k] != null) {
            return safeIntVal(countsMap[k]);
          }
        }
        for (final k in keys) {
          for (final entry in countsMap.entries) {
            if (entry.key.toString().trim().toLowerCase() == k.toLowerCase() && entry.value != null) {
              return safeIntVal(entry.value);
            }
          }
        }
        return null;
      }

      final int myTasksVal = extractCardCount(dashboardData['assignedTasksCard']) ??
          extractCardCount(dashboardData['assigned_tasks_card']) ??
          extractCardCount(dashboardData['myTasksCard']) ??
          extractCardCount(dashboardData['my_tasks_card']) ??
          extractCardCount(dashboardData['totalTasksCard']) ??
          extractCardCount(dashboardData['total_tasks_card']) ??
          searchCardLists(['assigned', 'my task', 'total task']) ??
          safeIntVal(
            dashboardData['assignedTasksCount'] ??
            dashboardData['assigned_tasks_count'] ??
            dashboardData['myTasksCount'] ??
            dashboardData['my_tasks_count'] ??
            dashboardData['totalTasks'] ??
            dashboardData['total_tasks'] ??
            dashboardData['totalTasksCount'] ??
            dashboardData['total_tasks_count'] ??
            dashboardData['assignedCount'] ??
            dashboardData['assigned_count'] ??
            dashboardData['assignedTasks'] ??
            dashboardData['assigned_tasks'] ??
            dashboardData['myTasks'] ??
            dashboardData['my_tasks'] ??
            (rawProgressOverview is Map ? (rawProgressOverview['total'] ?? rawProgressOverview['totalTasks'] ?? rawProgressOverview['totalCount'] ?? rawProgressOverview['assignedTasks']) : null),
            combinedTasks.length,
          );

      final int openCountVal = extractCardCount(dashboardData['openTasksCard']) ??
          extractCardCount(dashboardData['open_tasks_card']) ??
          extractCardCount(dashboardData['openCard']) ??
          extractCardCount(dashboardData['open_card']) ??
          searchCardLists(['open task', 'open', 'pending']) ??
          safeIntVal(
            dashboardData['openTasksCount'] ??
            dashboardData['open_tasks_count'] ??
            dashboardData['openCount'] ??
            dashboardData['open_count'] ??
            dashboardData['openTasks'] ??
            dashboardData['open_tasks'] ??
            (rawProgressOverview is Map ? (rawProgressOverview['open'] ?? rawProgressOverview['openTasks'] ?? rawProgressOverview['openCount'] ?? rawProgressOverview['pending']) : null) ??
            getFromCountsMap(['Open', 'OPEN', 'Pending', 'PENDING', 'open', 'pending', 'DRAFT', 'Draft', 'draft', 'ASSIGNED', 'Assigned', 'assigned', '1']),
            combinedTasks.where((t) => t.isOpen || t.status.toUpperCase() == 'OPEN' || t.status.toUpperCase() == 'PENDING' || t.status.toUpperCase() == 'ASSIGNED' || t.status.toUpperCase() == 'DRAFT').length,
          );

      // ============================================================
      // Robust Backend-driven In Progress Count Resolution
      // ============================================================
      int? resolvedInProgressCount;

      // 1. Direct card objects from dashboardData
      final inProgressCardKeys = [
        'inProgressCard',
        'in_progress_card',
        'inProgressTasksCard',
        'in_progress_tasks_card',
        'wipCard',
        'wip_card',
        'wipTasksCard',
        'wip_tasks_card',
        'workInProgressCard',
        'work_in_progress_card',
        'workInProgressTasksCard',
        'work_in_progress_tasks_card',
      ];
      for (final k in inProgressCardKeys) {
        if (dashboardData.containsKey(k) && dashboardData[k] != null) {
          final cnt = extractCardCount(dashboardData[k]);
          if (cnt != null && cnt >= 0) {
            resolvedInProgressCount = cnt;
            break;
          }
        }
      }

      // 2. Search card list in kpiCards, cards, stats, metrics, summary, etc.
      if (resolvedInProgressCount == null) {
        final inProgressKeywords = [
          'in progress',
          'in-progress',
          'in_progress',
          'work in progress',
          'work_in_progress',
          'wip',
          'inprogress',
        ];
        final cnt = searchCardLists(inProgressKeywords);
        if (cnt != null && cnt >= 0) {
          resolvedInProgressCount = cnt;
        }
      }

      // 3. Progress overview object (taskProgressOverview / progressOverview)
      if (resolvedInProgressCount == null && rawProgressOverview is Map) {
        final poKeys = [
          'inProgress',
          'in_progress',
          'inProgressCount',
          'in_progress_count',
          'inProgressTasks',
          'in_progress_tasks',
          'inProgressTasksCount',
          'in_progress_tasks_count',
          'wip',
          'wipCount',
          'wip_count',
          'wipTasks',
          'wip_tasks',
          'wipTasksCount',
          'wip_tasks_count',
          'workInProgress',
          'work_in_progress',
          'workInProgressCount',
          'work_in_progress_count',
          'inprogress',
          'inprogressCount',
          'inprogress_count',
        ];
        for (final pk in poKeys) {
          if (rawProgressOverview.containsKey(pk) && rawProgressOverview[pk] != null) {
            final cnt = safeIntVal(rawProgressOverview[pk], -1);
            if (cnt >= 0) {
              resolvedInProgressCount = cnt;
              break;
            }
          }
        }
        if (resolvedInProgressCount == null) {
          for (final subKey in ['allTime', 'all_time', 'overall', 'thisWeek', 'this_week', 'thisMonth', 'this_month']) {
            if (rawProgressOverview[subKey] is Map) {
              final subMap = rawProgressOverview[subKey] as Map;
              for (final pk in poKeys) {
                if (subMap.containsKey(pk) && subMap[pk] != null) {
                  final cnt = safeIntVal(subMap[pk], -1);
                  if (cnt >= 0) {
                    resolvedInProgressCount = cnt;
                    break;
                  }
                }
              }
              if (resolvedInProgressCount != null) break;
            }
          }
        }
      }

      // 4. Explicit direct fields from dashboardData
      if (resolvedInProgressCount == null) {
        final directKeys = [
          'inProgressCount',
          'in_progress_count',
          'inProgressTasksCount',
          'in_progress_tasks_count',
          'wipCount',
          'wip_count',
          'wipTasksCount',
          'wip_tasks_count',
          'workInProgressCount',
          'work_in_progress_count',
          'workInProgressTasksCount',
          'work_in_progress_tasks_count',
          'inprogressCount',
          'inprogress_count',
          'inProgressTaskCount',
          'in_progress_task_count',
          'inProgress',
          'in_progress',
          'wip',
          'workInProgress',
          'work_in_progress',
          'inprogress',
        ];
        for (final k in directKeys) {
          if (dashboardData.containsKey(k) && dashboardData[k] != null && dashboardData[k] is! List) {
            final cnt = safeIntVal(dashboardData[k], -1);
            if (cnt >= 0) {
              resolvedInProgressCount = cnt;
              break;
            }
          }
        }
      }

      // 5. Status counts map (taskStatusCounts / statusCounts)
      if (resolvedInProgressCount == null && countsMap != null) {
        final cnt = getFromCountsMap([
          'In Progress',
          'IN PROGRESS',
          'IN_PROGRESS',
          'in_progress',
          'in progress',
          'INPROGRESS',
          'inprogress',
          'WIP',
          'wip',
          'Wip',
          'Work In Progress',
          'WORK IN PROGRESS',
          'WORK_IN_PROGRESS',
          'work_in_progress',
          'work in progress',
          '3',
        ]);
        if (cnt != null && cnt >= 0) {
          resolvedInProgressCount = cnt;
        }
      }

      // 6. Backend task lists in dashboardData (wipTasks, inProgressTasks, etc.)
      if (resolvedInProgressCount == null) {
        final listKeys = [
          'inProgressTasks',
          'in_progress_tasks',
          'wipTasks',
          'wip_tasks',
          'workInProgressTasks',
          'work_in_progress_tasks',
          'inProgressTaskList',
          'wipTaskList',
        ];
        for (final k in listKeys) {
          if (dashboardData[k] is List) {
            resolvedInProgressCount = (dashboardData[k] as List).length;
            break;
          }
        }
      }

      // Fallback: calculate from live backend tasks list
      final int computedTasksInProgressCount = combinedTasks.where((t) {
        if (t.isCompleted || t.isDraft) return false;
        if (t.isInProgress || t.isUnderReview || t.isRework || t.isReassigned) return true;
        final st = t.status.toUpperCase().replaceAll('_', ' ').trim();
        if (st == 'IN PROGRESS' ||
            st == 'WORK IN PROGRESS' ||
            st == 'WIP' ||
            st == 'UNDER REVIEW' ||
            st == 'SUBMIT REVIEW' ||
            st == 'REWORK' ||
            st == 'REASSIGNED' ||
            st == 'REASSIGN' ||
            st == '3') {
          return true;
        }
        return false;
      }).length;

      // 1. Trust backend in-progress count directly (even if 0)
      final int inProgressCountVal = resolvedInProgressCount ??
          (computedTasksInProgressCount > 0
              ? computedTasksInProgressCount
              : 0);

      // ============================================================
      // Robust Backend-driven Overdue Count Resolution
      // ============================================================
      int? resolvedOverdueCount;

      // A. Direct card objects from dashboardData
      final overdueCardKeys = [
        'overdueTasksCard',
        'overdue_tasks_card',
        'overdueCard',
        'overdue_card',
        'delayedTasksCard',
        'delayed_tasks_card',
        'delayedCard',
        'delayed_card',
        'lagTasksCard',
        'lag_tasks_card',
        'lagCard',
        'lag_card',
      ];
      for (final k in overdueCardKeys) {
        if (dashboardData.containsKey(k) && dashboardData[k] != null) {
          final cnt = extractCardCount(dashboardData[k]);
          if (cnt != null && cnt >= 0) {
            resolvedOverdueCount = cnt;
            break;
          }
        }
      }

      // B. Search card list in kpiCards, cards, stats, metrics, summary
      if (resolvedOverdueCount == null) {
        final overdueKeywords = [
          'overdue',
          'over-due',
          'over_due',
          'over due',
          'delayed',
          'delay',
          'lag',
          'late',
        ];
        final cnt = searchCardLists(overdueKeywords);
        if (cnt != null && cnt >= 0) {
          resolvedOverdueCount = cnt;
        }
      }

      // C. Progress overview object (taskProgressOverview / progressOverview)
      if (resolvedOverdueCount == null && rawProgressOverview is Map) {
        final poOverdueKeys = [
          'overdue',
          'overdueCount',
          'overdue_count',
          'overdueTasks',
          'overdue_tasks',
          'overdueTasksCount',
          'overdue_tasks_count',
          'overdueTaskCount',
          'overdue_task_count',
          'delayed',
          'delayedCount',
          'delayed_count',
          'delayedTasks',
          'delayed_tasks',
          'delayedTasksCount',
          'delayed_tasks_count',
          'lag',
          'lagCount',
          'lag_count',
          'lagTasks',
          'lag_tasks',
        ];
        for (final pk in poOverdueKeys) {
          if (rawProgressOverview.containsKey(pk) && rawProgressOverview[pk] != null) {
            final cnt = safeIntVal(rawProgressOverview[pk], -1);
            if (cnt >= 0) {
              resolvedOverdueCount = cnt;
              break;
            }
          }
        }
        if (resolvedOverdueCount == null) {
          for (final subKey in ['allTime', 'all_time', 'overall', 'thisWeek', 'this_week', 'thisMonth', 'this_month']) {
            if (rawProgressOverview[subKey] is Map) {
              final subMap = rawProgressOverview[subKey] as Map;
              for (final pk in poOverdueKeys) {
                if (subMap.containsKey(pk) && subMap[pk] != null) {
                  final cnt = safeIntVal(subMap[pk], -1);
                  if (cnt >= 0) {
                    resolvedOverdueCount = cnt;
                    break;
                  }
                }
              }
              if (resolvedOverdueCount != null) break;
            }
          }
        }
      }

      // D. Explicit direct fields from dashboardData
      if (resolvedOverdueCount == null) {
        final directOverdueKeys = [
          'overdueCount',
          'overdue_count',
          'overdueTasksCount',
          'overdue_tasks_count',
          'overdueTaskCount',
          'overdue_task_count',
          'overdue',
          'overdueTasks',
          'overdue_tasks',
          'delayedCount',
          'delayed_count',
          'delayedTasksCount',
          'delayed_tasks_count',
          'delayed',
          'delayedTasks',
          'delayed_tasks',
          'lagCount',
          'lag_count',
          'lag',
          'lagTasks',
          'lag_tasks',
        ];
        for (final k in directOverdueKeys) {
          if (dashboardData.containsKey(k) && dashboardData[k] != null) {
            final cnt = safeIntVal(dashboardData[k], -1);
            if (cnt >= 0) {
              resolvedOverdueCount = cnt;
              break;
            }
          }
        }
      }

      // E. Status counts map (taskStatusCounts / statusCounts)
      if (resolvedOverdueCount == null && countsMap != null) {
        final cnt = getFromCountsMap([
          'Overdue',
          'OVERDUE',
          'overdue',
          'Over Due',
          'OVER DUE',
          'over due',
          'Delayed',
          'DELAYED',
          'delayed',
          'Lag',
          'LAG',
          'lag',
          'Late',
          'LATE',
          'late',
        ]);
        if (cnt != null && cnt >= 0) {
          resolvedOverdueCount = cnt;
        }
      }

      // Fallback: calculate from live backend tasks list ONLY if backend provided no count
      final int computedTasksOverdueCount = combinedTasks
          .where((t) => t.isOverdue || t.status.toUpperCase() == 'OVERDUE' || t.timeStatus == 'Overdue' || t.computedTimeStatus == 'Overdue')
          .length;

      // 2. Trust backend overdue count directly (even if 0)
      final int overdueCountVal = resolvedOverdueCount ??
          (computedTasksOverdueCount > 0
              ? computedTasksOverdueCount
              : 0);

      final int completedCountVal = extractCardCount(dashboardData['completedTasksCard']) ??
          extractCardCount(dashboardData['completed_tasks_card']) ??
          extractCardCount(dashboardData['closedTasksCard']) ??
          extractCardCount(dashboardData['closed_tasks_card']) ??
          extractCardCount(dashboardData['closedCard']) ??
          extractCardCount(dashboardData['completedCard']) ??
          searchCardLists(['closed', 'completed', 'done', 'finished']) ??
          safeIntVal(
            dashboardData['completedTasksCount'] ??
            dashboardData['completed_tasks_count'] ??
            dashboardData['closedTasksCount'] ??
            dashboardData['closed_tasks_count'] ??
            dashboardData['completedCount'] ??
            dashboardData['completed_count'] ??
            dashboardData['closedCount'] ??
            dashboardData['closed_count'] ??
            dashboardData['completedTasks'] ??
            dashboardData['completed_tasks'] ??
            dashboardData['closedTasks'] ??
            dashboardData['closed_tasks'] ??
            dashboardData['completed'] ??
            dashboardData['closed'] ??
            (rawProgressOverview is Map ? (rawProgressOverview['completed'] ?? rawProgressOverview['closed'] ?? rawProgressOverview['completedTasks'] ?? rawProgressOverview['closedTasks'] ?? rawProgressOverview['completedCount'] ?? rawProgressOverview['closedCount']) : null) ??
            getFromCountsMap(['Closed', 'CLOSED', 'Completed', 'COMPLETED', 'closed', 'completed', 'Done', 'DONE', 'Finished', 'FINISHED', 'finished', '4']),
            combinedTasks.where((t) => t.isCompleted || t.status.toUpperCase() == 'CLOSED' || t.status.toUpperCase() == 'COMPLETED' || t.status.toUpperCase() == 'DONE' || t.status == 'Closed' || t.status == 'Completed').length,
          );

      int? resolvedProjectsCount;

      // 1. Direct card objects from dashboardData
      final projectCardKeys = [
        'myProjectsCard',
        'my_projects_card',
        'myProjectCard',
        'my_project_card',
        'projectsCard',
        'projects_card',
        'projectCard',
        'project_card',
        'activeProjectsCard',
        'active_projects_card',
      ];
      for (final k in projectCardKeys) {
        if (dashboardData.containsKey(k) && dashboardData[k] != null) {
          final cnt = extractCardCount(dashboardData[k]);
          if (cnt != null && cnt > 0) {
            resolvedProjectsCount = cnt;
            break;
          }
        }
      }

      // 2. Search card list in kpiCards, cards, stats, metrics, summary
      if (resolvedProjectsCount == null) {
        final cardListKeys = ['kpiCards', 'kpi_cards', 'cards', 'stats', 'metrics', 'summary', 'kpis'];
        for (final lk in cardListKeys) {
          if (dashboardData[lk] is List) {
            final cnt = findCountFromCardList(dashboardData[lk]);
            if (cnt != null && cnt > 0) {
              resolvedProjectsCount = cnt;
              break;
            }
          }
        }
      }

      // 3. Explicit project count fields from backend
      if (resolvedProjectsCount == null) {
        final countKeys = [
          'myProjectsCount',
          'my_projects_count',
          'myProjectCount',
          'my_project_count',
          'userProjectsCount',
          'user_projects_count',
        ];
        for (final k in countKeys) {
          if (dashboardData.containsKey(k) && dashboardData[k] != null) {
            final cnt = safeIntVal(dashboardData[k], -1);
            if (cnt > 0) {
              resolvedProjectsCount = cnt;
              break;
            }
          }
        }
      }

      // 4. Backend project lists in dashboardData
      if (resolvedProjectsCount == null) {
        final listKeys = [
          'myProjects',
          'my_projects',
          'userProjects',
          'user_projects',
          'assignedProjects',
          'assigned_projects',
        ];
        for (final k in listKeys) {
          if (dashboardData[k] is List && (dashboardData[k] as List).isNotEmpty) {
            resolvedProjectsCount = (dashboardData[k] as List).length;
            break;
          }
        }
      }

      // 5. General project count keys from backend
      if (resolvedProjectsCount == null) {
        final generalKeys = [
          'projectsCount',
          'projects_count',
          'projectCount',
          'project_count',
          'activeProjectsCount',
          'active_projects_count',
        ];
        for (final k in generalKeys) {
          if (dashboardData.containsKey(k) && dashboardData[k] != null) {
            final cnt = safeIntVal(dashboardData[k], -1);
            if (cnt > 0) {
              resolvedProjectsCount = cnt;
              break;
            }
          }
        }
      }

      // 6. Generic 'projects' list in dashboardData
      if (resolvedProjectsCount == null && dashboardData['projects'] is List && (dashboardData['projects'] as List).isNotEmpty) {
        resolvedProjectsCount = (dashboardData['projects'] as List).length;
      }

      // 7. Total projects (for admin/manager)
      if (resolvedProjectsCount == null && isAdminOrManager) {
        final totalKeys = ['totalProjects', 'total_projects', 'totalProjectsCount', 'total_projects_count'];
        for (final k in totalKeys) {
          if (dashboardData.containsKey(k) && dashboardData[k] != null) {
            final cnt = safeIntVal(dashboardData[k], -1);
            if (cnt > 0) {
              resolvedProjectsCount = cnt;
              break;
            }
          }
        }
      }

      // 8. Final Count: Ensure it reflects actual mapped projects and live projects
      int finalProjectsCount = (resolvedProjectsCount != null && resolvedProjectsCount > 0)
          ? resolvedProjectsCount
          : 0;

      if (mappedProjects.isNotEmpty) {
        if (mappedProjects.length > finalProjectsCount) {
          finalProjectsCount = mappedProjects.length;
        }
      } else if (baseProjectList.isNotEmpty) {
        if (baseProjectList.length > finalProjectsCount) {
          finalProjectsCount = baseProjectList.length;
        }
      } else if (liveProjects.isNotEmpty) {
        if (liveProjects.length > finalProjectsCount) {
          finalProjectsCount = liveProjects.length;
        }
      }

      final int projectsCountVal = finalProjectsCount;

      final Map<String, int> tempCounts = {};
      if (countsMap != null) {
        countsMap.forEach((key, val) {
          tempCounts[key.toString()] = safeIntVal(val);
        });
      }

      final double? parsedOverallCompletion = _extractPercentage(
        dashboardData['overallCompletion'] ??
        dashboardData['overall_completion'] ??
        dashboardData['completionPercentage'] ??
        dashboardData['completion_percentage'] ??
        dashboardData['overallProgress'] ??
        dashboardData['overall_progress'] ??
        dashboardData['progressPercentage'] ??
        dashboardData['progress_percentage'] ??
        dashboardData['taskProgressPercentage'] ??
        dashboardData['task_progress_percentage'] ??
        dashboardData['taskProgress'] ??
        dashboardData['task_progress'] ??
        dashboardData['progress'] ??
        dashboardData['progressVal'] ??
        dashboardData['progress_val'] ??
        dashboardData['completion'] ??
        dashboardData['percentage'] ??
        dashboardData['taskProgressCard'] ??
        dashboardData['progressCard'] ??
        dashboardData['completionCard'] ??
        (rawProgressOverview is Map ? (
          rawProgressOverview['overallCompletion'] ??
          rawProgressOverview['overall_completion'] ??
          rawProgressOverview['completionPercentage'] ??
          rawProgressOverview['completion_percentage'] ??
          rawProgressOverview['progressPercentage'] ??
          rawProgressOverview['progress_percentage'] ??
          rawProgressOverview['progress'] ??
          rawProgressOverview['percentage'] ??
          rawProgressOverview['completion'] ??
          rawProgressOverview['value']
        ) : null)
      );

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
          _backendTaskProgressOverview = rawProgressOverview is Map ? Map<String, dynamic>.from(rawProgressOverview) : null;
          _backendOverallCompletion = parsedOverallCompletion;
          _currentEmpId = currentEmpId;
          _employeeMap = tempMap;
          _isLoading = false;
        });
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('cache_userName', _userName);
          if (_userName != 'Welcome!') {
            prefs.setString('userName', _userName);
            prefs.setString('fullName', _userName);
          }
          if (_userPhotoUrl != null && _userPhotoUrl!.isNotEmpty) {
            prefs.setString('profilePhotoUrl', _userPhotoUrl!);
          }
          prefs.setInt('cache_myTasksCount', _myTasksCount);
          prefs.setInt('cache_openTasksCount', _openTasksCount);
          prefs.setInt('cache_inProgressTasksCount', _inProgressTasksCount);
          prefs.setInt('cache_overdueTasksCount', _overdueTasksCount);
          prefs.setInt('cache_completedTasksCount', _completedTasksCount);
          prefs.setInt('cache_projectsCount', _projectsCount);
          if (_backendOverallCompletion != null) {
            prefs.setDouble('cache_overallCompletion', _backendOverallCompletion!);
          }
        }).catchError((_) {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_tasks.isEmpty && _projects.isEmpty && _myTasksCount == 0) {
            _error = e.toString();
          }
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
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: text.withValues(alpha: 0.6), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
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
    String displayInitials = initials;
    if (displayInitials.length > 2) {
      displayInitials = displayInitials.substring(0, 2);
    }
    return Container(
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
      child: displayInitials.isNotEmpty
          ? Text(
              displayInitials,
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: text,
              ),
            )
          : Icon(
              iconData,
              size: 12,
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
        _buildRoleAvatar(
          photoUrl: abPhoto,
          initials: abInitials,
          fallbackIcon: Icons.person_outline,
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
        _buildRoleAvatar(
          photoUrl: executorPhoto,
          initials: executorInitials,
          fallbackIcon: Icons.person_rounded,
          bg: const Color(0xFFEFF6FF),
          text: const Color(0xFF2563EB),
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
        _buildRoleAvatar(
          photoUrl: tmPhoto,
          initials: tmInitials,
          fallbackIcon: Icons.group_outlined,
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
        reviewerPhoto = (task.rawData?['reviewerPhoto'] ?? task.rawData?['reviewer_photo'] ?? task.rawData?['reviewerPhotoUrl'] ?? task.rawData?['reviewer_photo_url'] ?? '').toString();
      }
      String reviewerInitials = reviewerOpt?.initials ?? '';
      if (reviewerInitials.isEmpty && reviewerNm.isNotEmpty) {
        final parts = reviewerNm.trim().split(RegExp(r'\s+'));
        reviewerInitials = parts.length >= 2 ? (parts[0][0] + parts[1][0]).toUpperCase() : parts[0][0].toUpperCase();
      }
      if (reviewerInitials.isEmpty) reviewerInitials = 'RV';
      final String reviewerLabel = reviewerOpt?.name ?? (reviewerNm.isNotEmpty && !RegExp(r'^\d+$').hasMatch(reviewerNm) ? reviewerNm : (RegExp(r'^\d+$').hasMatch(reviewerId) ? 'Unassigned' : (reviewerId.isNotEmpty ? reviewerId : 'Unassigned')));

      avatarWidgets.add(
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

    // 5. Approver (AP)
    final approverId = (task.approver ?? task.rawData?['approver'] ?? task.rawData?['approverId'] ?? task.rawData?['approver_id'] ?? task.rawData?['approverEmpId'] ?? task.rawData?['approver_emp_id'] ?? (task.approvers.isNotEmpty ? task.approvers.first : '')).toString().trim();
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
      final String approverLabel = approverOpt?.name ?? (approverNm.isNotEmpty && !RegExp(r'^\d+$').hasMatch(approverNm) ? approverNm : (RegExp(r'^\d+$').hasMatch(approverId) ? 'Unassigned' : (approverId.isNotEmpty ? approverId : 'Unassigned')));

      avatarWidgets.add(
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

    if (avatarWidgets.isEmpty) {
      String? fallbackPhoto = (task.rawData?['photoUrl'] ?? task.rawData?['photo_url'] ?? task.rawData?['profileImageUrl'] ?? task.rawData?['profile_image_url'] ?? '').toString();
      if (fallbackPhoto.isEmpty) fallbackPhoto = _userPhotoUrl;
      String fallbackInitials = (task.rawData?['initials'] ?? '').toString().trim();
      if (fallbackInitials.isEmpty) fallbackInitials = _userInitials.isNotEmpty ? _userInitials : 'EX';

      avatarWidgets.add(
        _buildRoleAvatar(
          photoUrl: fallbackPhoto,
          initials: fallbackInitials,
          fallbackIcon: Icons.person_rounded,
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

    // Robust parsing using TaskItem.parseDateTime supporting all date formats
    DateTime? endDate = TaskItem.parseDateTime(task.endDate) ??
        TaskItem.parseDateTime(task.rawEndDt) ??
        TaskItem.parseDateTime(task.rawData?['endDt']?.toString()) ??
        TaskItem.parseDateTime(task.rawData?['endDate']?.toString()) ??
        TaskItem.parseDateTime(task.rawData?['dueDt']?.toString());

    DateTime? stDate = TaskItem.parseDateTime(task.startDate) ??
        TaskItem.parseDateTime(task.rawStDt) ??
        TaskItem.parseDateTime(task.rawData?['stDt']?.toString()) ??
        TaskItem.parseDateTime(task.rawData?['startDate']?.toString()) ??
        TaskItem.parseDateTime(task.date.isNotEmpty && task.date != 'No Date' && task.date != 'N/A' ? task.date : null);

    DateTime? crDate = TaskItem.parseDateTime(task.rawData?['crDt']?.toString()) ??
        TaskItem.parseDateTime(task.rawData?['cr_dt']?.toString()) ??
        TaskItem.parseDateTime(task.rawData?['createdDate']?.toString()) ??
        TaskItem.parseDateTime(task.rawData?['createdAt']?.toString());

    final dateToCheck = endDate ?? stDate ?? crDate;
    if (dateToCheck == null) {
      return false;
    }

    final now = DateTime.now();

    if (timeframe == 'This Month') {
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      if (endDate != null && endDate.year == now.year && endDate.month == now.month) return true;
      if (stDate != null && stDate.year == now.year && stDate.month == now.month) return true;
      if (stDate != null && endDate != null && stDate.isBefore(monthEnd) && endDate.isAfter(monthStart)) return true;
      return dateToCheck.year == now.year && dateToCheck.month == now.month;
    }

    if (timeframe == 'This Week') {
      final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday % 7));
      final endOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + 6, 23, 59, 59);

      if (endDate != null && !endDate.isBefore(startOfWeek) && !endDate.isAfter(endOfWeek)) return true;
      if (stDate != null && !stDate.isBefore(startOfWeek) && !stDate.isAfter(endOfWeek)) return true;
      if (stDate != null && endDate != null && stDate.isBefore(endOfWeek) && endDate.isAfter(startOfWeek)) return true;
      return !dateToCheck.isBefore(startOfWeek) && !dateToCheck.isAfter(endOfWeek);
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
              : RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: const Color(0xFF2563EB),
                  backgroundColor: Colors.white,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                              iconColor: AppColors.open,
                              iconBg: AppColors.openBg,
                            ),
                            _buildStatCard(
                              title: 'Open Tasks',
                              count: '$_openTasksCount',
                              icon: Icons.pending_actions_rounded,
                              iconColor: AppColors.closed,
                              iconBg: AppColors.closedBg,
                            ),
                            _buildStatCard(
                              title: 'In Progress',
                              count: '$_inProgressTasksCount',
                              icon: Icons.timelapse_outlined,
                              iconColor: AppColors.inProgress,
                              iconBg: AppColors.inProgressBg,
                            ),
                            _buildStatCard(
                              title: 'Overdue',
                              count: '$_overdueTasksCount',
                              icon: Icons.warning_amber_rounded,
                              iconColor: AppColors.overdue,
                              iconBg: AppColors.overdueBg,
                            ),
                            _buildStatCard(
                              title: 'Closed',
                              count: '$_completedTasksCount',
                              icon: Icons.check_circle_outline_rounded,
                              iconColor: AppColors.teal,
                              iconBg: AppColors.tealBg,
                            ),
                            _buildStatCard(
                              title: 'My Projects',
                              count: '${_projectsCount > 0 ? _projectsCount : (_projects.isNotEmpty ? _projects.length : 0)}',
                              icon: Icons.folder_open_outlined,
                              iconColor: AppColors.purple,
                              iconBg: AppColors.purpleBg,
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
                ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
      ),
    );
  }

  Map<String, dynamic> _resolveOverviewCountsForTimeframe(String timeframe, List<TaskItem> overviewTasks) {
    int safeParseInt(dynamic val, [int fallback = 0]) {
      if (val == null) return fallback;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) {
        return int.tryParse(val) ?? double.tryParse(val)?.toInt() ?? fallback;
      }
      return fallback;
    }

    int completed = 0;
    int inProgress = 0;
    int open = 0;
    int overdue = 0;
    double? overallPct;

    // 1. Check if backend provided timeframe-specific metrics
    Map<String, dynamic>? timeframeBackendData;
    if (_backendTaskProgressOverview != null) {
      if (timeframe == 'This Week') {
        final rawWeek = _backendTaskProgressOverview!['thisWeek'] ??
            _backendTaskProgressOverview!['this_week'] ??
            _backendTaskProgressOverview!['week'] ??
            _backendTaskProgressOverview!['weekly'];
        if (rawWeek is Map) timeframeBackendData = Map<String, dynamic>.from(rawWeek);
      } else if (timeframe == 'This Month') {
        final rawMonth = _backendTaskProgressOverview!['thisMonth'] ??
            _backendTaskProgressOverview!['this_month'] ??
            _backendTaskProgressOverview!['month'] ??
            _backendTaskProgressOverview!['monthly'];
        if (rawMonth is Map) timeframeBackendData = Map<String, dynamic>.from(rawMonth);
      } else {
        final rawAll = _backendTaskProgressOverview!['allTime'] ??
            _backendTaskProgressOverview!['all_time'] ??
            _backendTaskProgressOverview!['all'] ??
            _backendTaskProgressOverview!['overall'];
        if (rawAll is Map) timeframeBackendData = Map<String, dynamic>.from(rawAll);
      }
    }

    if (timeframeBackendData != null) {
      completed = safeParseInt(timeframeBackendData['completed'] ?? timeframeBackendData['closed'] ?? timeframeBackendData['completedTasks'] ?? timeframeBackendData['closedTasks'] ?? timeframeBackendData['completedCount'] ?? timeframeBackendData['closedCount']);
      inProgress = safeParseInt(timeframeBackendData['inProgress'] ?? timeframeBackendData['in_progress'] ?? timeframeBackendData['wip'] ?? timeframeBackendData['inProgressTasks'] ?? timeframeBackendData['inProgressCount']);
      open = safeParseInt(timeframeBackendData['open'] ?? timeframeBackendData['openTasks'] ?? timeframeBackendData['pending'] ?? timeframeBackendData['openCount']);
      overdue = safeParseInt(timeframeBackendData['overdue'] ?? timeframeBackendData['overdueTasks'] ?? timeframeBackendData['overdueCount']);
      overallPct = _extractPercentage(timeframeBackendData['overallCompletion'] ?? timeframeBackendData['overall_completion'] ?? timeframeBackendData['completionPercentage'] ?? timeframeBackendData['progressPercentage'] ?? timeframeBackendData['progress'] ?? timeframeBackendData['percentage']);
    }

    // 2. If 'All Time', prioritize top-level backend metrics & status counts
    if (timeframe == 'All Time') {
      if (_backendTaskProgressOverview != null) {
        if (completed == 0) completed = safeParseInt(_backendTaskProgressOverview!['completed'] ?? _backendTaskProgressOverview!['closed'] ?? _backendTaskProgressOverview!['completedTasks'] ?? _backendTaskProgressOverview!['closedTasks'] ?? _backendTaskProgressOverview!['completedCount'] ?? _backendTaskProgressOverview!['closedCount']);
        if (inProgress == 0) inProgress = safeParseInt(_backendTaskProgressOverview!['inProgress'] ?? _backendTaskProgressOverview!['in_progress'] ?? _backendTaskProgressOverview!['wip'] ?? _backendTaskProgressOverview!['inProgressTasks'] ?? _backendTaskProgressOverview!['inProgressCount']);
        if (open == 0) open = safeParseInt(_backendTaskProgressOverview!['open'] ?? _backendTaskProgressOverview!['openTasks'] ?? _backendTaskProgressOverview!['pending'] ?? _backendTaskProgressOverview!['openCount']);
        if (overdue == 0) overdue = safeParseInt(_backendTaskProgressOverview!['overdue'] ?? _backendTaskProgressOverview!['overdueTasks'] ?? _backendTaskProgressOverview!['overdueCount']);
        overallPct ??= _extractPercentage(_backendTaskProgressOverview!['overallCompletion'] ?? _backendTaskProgressOverview!['overall_completion'] ?? _backendTaskProgressOverview!['completionPercentage'] ?? _backendTaskProgressOverview!['progressPercentage'] ?? _backendTaskProgressOverview!['progress'] ?? _backendTaskProgressOverview!['percentage']);
      }

      // Check _backendStatusCounts if non-zero
      if (_backendStatusCounts != null && _backendStatusCounts!.isNotEmpty) {
        if (completed == 0) {
          completed = _backendStatusCounts!['Closed'] ??
              _backendStatusCounts!['CLOSED'] ??
              _backendStatusCounts!['Completed'] ??
              _backendStatusCounts!['COMPLETED'] ??
              _backendStatusCounts!['closed'] ??
              _backendStatusCounts!['completed'] ??
              _backendStatusCounts!['4'] ?? 0;
        }
        if (inProgress == 0) {
          inProgress = _backendStatusCounts!['In Progress'] ??
              _backendStatusCounts!['IN_PROGRESS'] ??
              _backendStatusCounts!['IN PROGRESS'] ??
              _backendStatusCounts!['WIP'] ??
              _backendStatusCounts!['wip'] ??
              _backendStatusCounts!['Work In Progress'] ??
              _backendStatusCounts!['WORK IN PROGRESS'] ??
              _backendStatusCounts!['WORK_IN_PROGRESS'] ??
              _backendStatusCounts!['work_in_progress'] ??
              _backendStatusCounts!['3'] ??
              _backendStatusCounts!['2'] ?? 0;
        }
        if (open == 0) {
          open = _backendStatusCounts!['Open'] ??
              _backendStatusCounts!['OPEN'] ??
              _backendStatusCounts!['Pending'] ??
              _backendStatusCounts!['PENDING'] ??
              _backendStatusCounts!['open'] ??
              _backendStatusCounts!['1'] ?? 0;
        }
        if (overdue == 0) {
          overdue = _backendStatusCounts!['Overdue'] ??
              _backendStatusCounts!['OVERDUE'] ??
              _backendStatusCounts!['overdue'] ?? 0;
        }
      }

      // Direct usage of top KPI counts from backend dashboard
      if (completed == 0 && inProgress == 0 && open == 0 && overdue == 0) {
        completed = _completedTasksCount;
        inProgress = _inProgressTasksCount;
        open = _openTasksCount;
        overdue = _overdueTasksCount;
      }

      overallPct ??= _backendOverallCompletion;

      // Align total with _myTasksCount so percentages reflect assigned total accurately
      final int rawSum = completed + inProgress + open + overdue;
      final int targetTotal = _myTasksCount > 0 ? _myTasksCount : rawSum;
      if (targetTotal > rawSum) {
        open += (targetTotal - rawSum);
      }
    }

    // 3. If counts are still 0 (or for timeframe filtering without backend object), calculate from tasks
    if (completed == 0 && inProgress == 0 && open == 0 && overdue == 0 && overviewTasks.isNotEmpty) {
      final filteredTasks = (timeframe == 'All Time')
          ? overviewTasks
          : overviewTasks.where((task) => _isTaskInTimeframe(task, timeframe)).toList();

      for (final task in filteredTasks) {
        final st = task.status.toUpperCase().trim();
        final bool isClosed = task.isCompleted ||
            st == 'CLOSED' ||
            st == 'COMPLETED' ||
            st == 'DONE' ||
            st == 'FINISHED' ||
            st == '4' ||
            task.status == 'Closed' ||
            task.status == 'Completed';

        if (isClosed) {
          completed++;
        } else if (task.isInProgress ||
            task.isUnderReview ||
            st == 'IN PROGRESS' ||
            st == 'IN_PROGRESS' ||
            st == 'WIP' ||
            st == 'UNDER REVIEW' ||
            st == 'UNDER_REVIEW' ||
            st == 'REWORK' ||
            st == 'REASSIGNED' ||
            st == 'REASSIGN' ||
            st == 'SUBMIT_REVIEW' ||
            st == '3') {
          inProgress++;
        } else if (task.isOverdue || st == 'OVERDUE' || task.timeStatus == 'Overdue' || task.computedTimeStatus == 'Overdue') {
          overdue++;
        } else {
          open++;
        }
      }
    }

    return {
      'completed': completed,
      'inProgress': inProgress,
      'open': open,
      'overdue': overdue,
      'overallPct': overallPct,
    };
  }

  Widget _buildTaskProgressOverview(List<TaskItem> overviewTasks) {
    final overviewData = _resolveOverviewCountsForTimeframe(_selectedOverviewTimeframe, overviewTasks);
    final int overviewCompleted = overviewData['completed'] as int? ?? 0;
    final int overviewInProgress = overviewData['inProgress'] as int? ?? 0;
    final int overviewOpen = overviewData['open'] as int? ?? 0;
    final int overviewOverdue = overviewData['overdue'] as int? ?? 0;
    final double? backendPct = overviewData['overallPct'] as double?;

    final int overviewTotal = overviewCompleted + overviewInProgress + overviewOpen + overviewOverdue;
    final double completedPct = overviewTotal == 0 ? 0.0 : (overviewCompleted / overviewTotal * 100);
    final double inProgressPct = overviewTotal == 0 ? 0.0 : (overviewInProgress / overviewTotal * 100);
    final double openPct = overviewTotal == 0 ? 0.0 : (overviewOpen / overviewTotal * 100);
    final double overduePct = overviewTotal == 0 ? 0.0 : (overviewOverdue / overviewTotal * 100);

    final double displayOverallPct = (backendPct != null && backendPct > 0.0) ? backendPct : completedPct;

    String formatDecimalPct(double val) {
      if (val.isNaN || val.isInfinite) return '0%';
      if (val % 1 == 0) {
        return '${val.toInt()}%';
      }
      return '${val.toStringAsFixed(1)}%';
    }

    // Construct non-zero sections to prevent fl_chart gaps or crashes
    final List<PieChartSectionData> chartSections = [];
    if (overviewCompleted > 0) {
      chartSections.add(
        PieChartSectionData(
          color: AppColors.closed,
          value: overviewCompleted.toDouble(),
          showTitle: false,
          radius: 14,
        ),
      );
    }
    if (overviewInProgress > 0) {
      chartSections.add(
        PieChartSectionData(
          color: AppColors.inProgress,
          value: overviewInProgress.toDouble(),
          showTitle: false,
          radius: 14,
        ),
      );
    }
    if (overviewOpen > 0) {
      chartSections.add(
        PieChartSectionData(
          color: AppColors.open,
          value: overviewOpen.toDouble(),
          showTitle: false,
          radius: 14,
        ),
      );
    }
    if (overviewOverdue > 0) {
      chartSections.add(
        PieChartSectionData(
          color: AppColors.overdue,
          value: overviewOverdue.toDouble(),
          showTitle: false,
          radius: 14,
        ),
      );
    }
    if (chartSections.isEmpty) {
      chartSections.add(
        PieChartSectionData(
          color: const Color(0xFFE2E8F0),
          value: 1,
          showTitle: false,
          radius: 14,
        ),
      );
    }

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
                          sectionsSpace: chartSections.length > 1 ? 2 : 0,
                          centerSpaceRadius: 36,
                          startDegreeOffset: 270,
                          sections: chartSections,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatDecimalPct(displayOverallPct),
                            style: GoogleFonts.inter(
                              fontSize: 15,
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
                    _buildOverviewLegendItem(const Color(0xFF16A34A), 'Closed', overviewCompleted, formatDecimalPct(completedPct)),
                    const SizedBox(height: 8),
                    _buildOverviewLegendItem(const Color(0xFFF59E0B), 'In Progress', overviewInProgress, formatDecimalPct(inProgressPct)),
                    const SizedBox(height: 8),
                    _buildOverviewLegendItem(const Color(0xFF2563EB), 'Open', overviewOpen, formatDecimalPct(openPct)),
                    const SizedBox(height: 8),
                    _buildOverviewLegendItem(const Color(0xFFEF4444), 'Overdue', overviewOverdue, formatDecimalPct(overduePct)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewLegendItem(Color color, String label, int count, String percentage) {
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
          '$count',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($percentage)',
          style: GoogleFonts.inter(
            fontSize: 10.5,
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
            ..._projects.take(4).map((p) => _buildActiveProjectItem(p)),
        ],
      ),
    );
  }

  Widget _buildProjectImage(String? logoPath, String projectNm, double size) {
    if (logoPath == null || logoPath.isEmpty) {
      return _buildPlaceholderImage(projectNm, size);
    }

    final String fullImageUrl = (logoPath.startsWith('http://') || logoPath.startsWith('https://'))
        ? logoPath
        : '${dotenv.env['BASE_URL'] ?? 'https://bionova-rjii.onrender.com'}/${logoPath.startsWith('/') ? logoPath.substring(1) : logoPath}';

    return Image.network(
      fullImageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: size,
          height: size,
          color: const Color(0xffF8FAFC),
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholderImage(projectNm, size);
      },
    );
  }

  Widget _buildPlaceholderImage(String name, double size) {
    final String char = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    final List<Color> colors = [
      const Color(0xff3B82F6),
      const Color(0xff1D4ED8),
    ];
    if (char.codeUnitAt(0) % 2 == 0) {
      colors[0] = const Color(0xff10B981);
      colors[1] = const Color(0xff047857);
    } else if (char.codeUnitAt(0) % 3 == 0) {
      colors[0] = const Color(0xff8B5CF6);
      colors[1] = const Color(0xff6D28D9);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveProjectItem(ProjectModel project) {
    Color iconColor = project.barColor;

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
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildProjectImage(project.logo, project.prjNm, 42),
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
                          if (!task.isCompleted) ...[
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
                          ],
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!task.isCompleted && task.processIcon != null) ...[
                                  (task.isReassigned || task.processIcon == Icons.undo_rounded)
                                      ? ReassignIcon(size: 11, color: task.processIconColor ?? task.progressStatusColor)
                                      : Icon(task.processIcon, size: 11, color: task.processIconColor ?? task.progressStatusColor),
                                  const SizedBox(width: 3),
                                ],
                                Text(
                                  task.progressStatusText,
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: task.progressStatusColor,
                                  ),
                                ),
                              ],
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
                          ],
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
        'label': 'Assignments',
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