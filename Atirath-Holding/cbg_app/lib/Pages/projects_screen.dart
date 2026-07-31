import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';
import '../models/task_item.dart';
import '../services/api_service.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  static const Color themeColor = Color(0xff10B981);

  String _calculateUserLeadLag(List<dynamic> tasks, String projEndDt) {
    if (tasks.isEmpty) return 'On Time';
    DateTime? maxTargetEnd;
    DateTime? maxActualEnd;

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
        if (d != null && (maxActualEnd == null || d.isAfter(maxActualEnd))) {
          maxActualEnd = d;
        }
      }
    }

    if (maxTargetEnd == null && projEndDt.isNotEmpty) {
      maxTargetEnd = DateTime.tryParse(projEndDt);
    }

    if (maxTargetEnd != null && maxActualEnd != null) {
      final targetDate = DateTime(maxTargetEnd.year, maxTargetEnd.month, maxTargetEnd.day);
      final actualDate = DateTime(maxActualEnd.year, maxActualEnd.month, maxActualEnd.day);
      final diffDays = targetDate.difference(actualDate).inDays;

      if (diffDays > 0) {
        return 'Lead (-$diffDays Days)';
      } else if (diffDays < 0) {
        return 'Lag (+${diffDays.abs()} Days)';
      } else {
        return 'On Time';
      }
    }
    return 'On Time';
  }
  
  String _selectedFilter = 'All Projects';
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _itemsPerPage = 3;

  List<ProjectModel> _projects = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    try {
      // ── Step 1: Get current employee ID ─────────────────────────
      final currentEmpId = await ApiService.getCurrentEmployeeId();

      // ── Step 2: Parallel fetch ───────────────────────────────────────────
      final fetchResults = await Future.wait([
        ApiService.getUserDashboardData(),             // [0] dashboard data
        ApiService.getCompanies(),                    // [1] companies
        ApiService.getPlants(),                       // [2] plants
        ApiService.getLiveTasks(),                    // [3] live tasks
        ApiService.getIndividualTasks(),              // [4] individual tasks
        ApiService.getLiveProjects(),                 // [5] live projects (full details) for merging
      ]);

      final dashboardData = fetchResults[0] as Map<String, dynamic>?;
      final List<dynamic> myProjectsData = dashboardData?['myProjects'] as List<dynamic>? ?? [];
      final List<ProjectModel> fullDetailProjects = fetchResults[5] as List<ProjectModel>;

      final List<ProjectModel> liveProjects = [];

      // 1. Process projects from dashboard data (myProjects)
      for (final json in myProjectsData) {
        if (json is Map) {
          final dbProj = ProjectModel.fromJson(Map<String, dynamic>.from(json));
          ProjectModel? matchedFull;
          try {
            matchedFull = fullDetailProjects.firstWhere(
              (p) => (dbProj.prjId > 0 && p.prjId == dbProj.prjId) ||
                    (dbProj.prjCd.isNotEmpty && p.prjCd == dbProj.prjCd) ||
                    (dbProj.name.isNotEmpty && p.name.trim().toLowerCase() == dbProj.name.trim().toLowerCase()),
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
            addlRem: dbProj.addlRem ?? matchedFull?.addlRem,
            leadLagStatus: matchedFull?.leadLagStatus ?? dbProj.leadLagStatus,
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

          if (!liveProjects.any((p) => (p.prjId > 0 && p.prjId == merged.prjId) || (p.prjCd.isNotEmpty && p.prjCd == merged.prjCd))) {
            liveProjects.add(merged);
          }
        }
      }

      // 2. Add remaining projects from fullDetailProjects that weren't in myProjects
      for (final fullProj in fullDetailProjects) {
        if (!liveProjects.any((p) => (p.prjId > 0 && p.prjId == fullProj.prjId) || (p.prjCd.isNotEmpty && p.prjCd == fullProj.prjCd))) {
          liveProjects.add(fullProj);
        }
      }

      final companies     = fetchResults[1] as List<dynamic>;
      final plants        = fetchResults[2] as List<dynamic>;
      final liveTasks     = fetchResults[3] as List<TaskItem>;
      List<dynamic> rawIndividualTasks = fetchResults[4] as List<dynamic>;

      // Filter individual tasks by currentEmpId (same logic as dashboard_screen.dart)
      if (currentEmpId != null) {
        final empStr = currentEmpId.toString();
        rawIndividualTasks = rawIndividualTasks.where((t) {
          if (t is! Map) return false;
          final doer = t['empId']?.toString() ?? t['empid']?.toString();
          final reviewer = t['reviewer']?.toString();
          final approver = t['approver']?.toString();
          return doer == empStr || reviewer == empStr || approver == empStr;
        }).toList();
      }

      // Parse individual tasks safely
      final individualTasks = rawIndividualTasks
          .whereType<Map>()
          .map((json) => TaskItem.fromIndividualTask(Map<String, dynamic>.from(json), currentEmpId?.toString()))
          .toList();

      final combinedTasks = [...liveTasks, ...individualTasks].where((task) => !task.isDraft).toList();

      final leadLagFutures = liveProjects.map((p) => ApiService.getProjectLeadLagStatus(p.prjId)).toList();
      final leadLagResults = await Future.wait(leadLagFutures);
      final Map<int, String> leadLagMap = {};
      for (int i = 0; i < liveProjects.length; i++) {
        leadLagMap[liveProjects[i].prjId] = leadLagResults[i];
      }

      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('userRole') ?? '';
      final bool filterByEmp = currentEmpId != null &&
          userRole.isNotEmpty &&
          userRole.toLowerCase() != 'admin' &&
          userRole.toLowerCase() != 'manager';

      final List<ProjectModel> mappedProjects = [];
      for (final p in liveProjects) {
        List<dynamic> milestoneTasksRaw = [];
        try {
          if (p.prjId > 0) {
            final fetchedMilestones = await ApiService.getMilestones(p.prjId);
            final taskFutures = fetchedMilestones.map((m) async {
              final rawMId = m['mId'] ?? m['mid'];
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
          debugPrint('Error fetching milestone tasks for project ${p.prjId}: $e');
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
              final isTeamMember = noteTxt.split(',').map((e) => e.trim()).contains(strEmpId);
              
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
            final String tStatus = (t['taskSts']?.toString() ?? 'OPEN').toUpperCase().trim();
            double taskProg = 0.0;
            switch (tStatus) {
              case 'COMPLETED':
              case 'CLOSED':
              case 'DONE':
                taskProg = 1.0;
                completedCount++;
                break;
              case 'SUBMIT_REVIEW':
              case 'UNDER_REVIEW':
              case 'UNDERREVIEW':
                taskProg = 0.8;
                openCount++;
                inProgressCount++;
                break;
              case 'WIP':
              case 'INPROGRESS':
              case 'IN PROGRESS':
                taskProg = 0.5;
                openCount++;
                inProgressCount++;
                break;
              case 'OVERDUE':
                taskProg = 0.5;
                openCount++;
                inProgressCount++;
                break;
              case 'REASSIGN':
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
          // Fallback to combinedTasks if project milestone tasks list is empty
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
            if (t.isCompleted || st == 'COMPLETED' || st == 'CLOSED' || st == 'DONE') {
              taskProg = 1.0;
              completedCount++;
            } else if (st == 'SUBMIT_REVIEW' || st == 'UNDER_REVIEW' || st == 'UNDERREVIEW' || t.isUnderReview) {
              taskProg = 0.8;
              openCount++;
              inProgressCount++;
            } else if (st == 'WIP' || st == 'INPROGRESS' || st == 'IN PROGRESS' || t.isInProgress) {
              taskProg = 0.5;
              openCount++;
              inProgressCount++;
            } else if (st == 'OVERDUE' || t.isOverdue) {
              taskProg = 0.5;
              openCount++;
              inProgressCount++;
            } else if (st == 'REASSIGN') {
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

        final String progressTxt = '${(progressVal * 100).round()}%';
            
        Color barColor;
        if (progressVal < 0.5) {
          barColor = const Color(0xffF97316);
        } else if (progressVal < 1.0) {
          barColor = const Color(0xff3B82F6);
        } else {
          barColor = const Color(0xff22C55E);
        }

        final int finalAssigned = totalAssigned > 0 ? totalAssigned : (p.rawAssigned ?? 0);
        final int finalOpen = totalAssigned > 0 ? openCount : (p.rawOpen ?? 0);

        // Company / plant details
        String? companyName = p.companyName;
        if (companyName == null || companyName.isEmpty) {
          if (p.coyId != null && p.coyId! > 0) {
            final matched = companies.firstWhere(
              (c) => (c['coyId'] ?? c['coy_id']) == p.coyId,
              orElse: () => null,
            );
            if (matched != null) companyName = matched['coyNm'];
          }
        }

        String? plantName = p.plantName;
        String? location  = p.location;
        if ((plantName == null || plantName.isEmpty) ||
            (location == null || location.isEmpty)) {
          if (p.pltId != null && p.pltId! > 0) {
            final matched = plants.firstWhere(
              (pl) => (pl['pltId'] ?? pl['plt_id']) == p.pltId,
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
        }

        final bool isUserClosed = totalAssigned > 0 && completedCount == totalAssigned;
        final String userLeadLag = isUserClosed
            ? _calculateUserLeadLag(effectiveTasks, p.endDt)
            : (leadLagMap[p.prjId] ?? p.leadLagStatusStr);

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
          addlRem: p.addlRem,
          leadLagStatus: p.leadLagStatus,
          pltId: p.pltId,
          coyId: p.coyId,
          name: p.name,
          details: p.details.isNotEmpty ? p.details : (companyName ?? p.name),
          role: p.role,
          assigned: finalAssigned,
          open: isUserClosed ? 0 : finalOpen,
          inProgress: isUserClosed ? 0 : inProgressCount,
          progressValue: isUserClosed ? 1.0 : progressVal,
          progressText: isUserClosed ? '100%' : progressTxt,
          barColor: isUserClosed ? const Color(0xff22C55E) : barColor,
          companyName: companyName,
          plantName: plantName,
          location: location,
          leadLagStatusStr: userLeadLag,
        ));
      }

      if (mounted) {
        setState(() {
          _projects = mappedProjects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      debugPrint('[Projects] ERROR: $e');
    }
  }


  List<ProjectModel> get _filteredProjects {
    return _projects.where((project) {
      final matchesSearch = project.prjNm
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

      bool matchesFilter = false;
      final status = project.prjSts.trim().toUpperCase();

      if (_selectedFilter == 'All Projects') {
        matchesFilter = true;
      } else if (_selectedFilter == 'Live') {
        matchesFilter = status == 'LIVE' || 
                        status == 'OPEN' || 
                        status == 'ACTIVE' || 
                        status == 'IN PROGRESS' || 
                        status == 'WIP' || 
                        status == 'IN_PROGRESS' || 
                        status.isEmpty;
      } else if (_selectedFilter == 'On Hold') {
        matchesFilter = status == 'ON HOLD' || 
                        status == 'ON_HOLD' || 
                        status == 'HOLD';
      } else if (_selectedFilter == 'Closed') {
        matchesFilter = status == 'CLOSED' || 
                        status == 'COMPLETED' || 
                        status == 'DONE';
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get _totalPages {
    final count = _filteredProjects.length;
    if (count == 0) return 1;
    return (count / _itemsPerPage).ceil();
  }

  List<ProjectModel> get _paginatedProjects {
    final filtered = _filteredProjects;
    if (filtered.isEmpty) return [];
    int page = _currentPage;
    if (page > _totalPages) page = _totalPages;
    if (page < 1) page = 1;
    final startIndex = (page - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < filtered.length)
        ? startIndex + _itemsPerPage
        : filtered.length;
    return filtered.sublist(startIndex, endIndex);
  }

  Color getPriorityColor(String? priority) {
    if (priority == null) return const Color(0xFF10B981);
    
    switch (priority.toLowerCase()) {
      case 'low':
        return const Color(0xFF2563EB);
      case 'normal':
        return const Color(0xFF10B981);
      case 'medium':
        return const Color(0xFFFACC15);
      case 'high':
        return const Color(0xFF7C3AED);
      case 'critical':
        return const Color(0xFFEF4444);
      case 'atmost critical':
        return const Color(0xFF722F37);
      default:
        return const Color(0xFF10B981);
    }
  }

  String _formatDbDate(String rawDate) {
    if (rawDate.isEmpty) return 'No Date';
    try {
      final parsed = DateTime.parse(rawDate);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}";
    } catch (_) {
      return rawDate;
    }
  }

  bool _isValidString(String? str) {
    if (str == null) return false;
    final s = str.trim();
    if (s.isEmpty) return false;
    final lower = s.toLowerCase();
    return lower != 'null' && lower != 'n/a';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFAFBFC),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Text(_error!),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          Expanded(child: _buildSearchField()),
                          const SizedBox(width: 10),
                          _buildProjectDropdown(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _paginatedProjects.length,
                        itemBuilder: (context, index) {
                          return _buildProjectCard(
                            _paginatedProjects[index],
                            themeColor,
                          );
                        },
                      ),
                    ),
                    _buildPagination(),
                  ],
                ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.search, size: 16, color: Color(0xff94A3B8)),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 1;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search projects...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xff94A3B8)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xff1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xff475569)),
          style: const TextStyle(fontSize: 13, color: Color(0xff1E293B), fontWeight: FontWeight.w500),
          items: const [
            DropdownMenuItem(
              value: 'All Projects',
              child: Text('All Projects'),
            ),
            DropdownMenuItem(
              value: 'Live',
              child: Text('Live'),
            ),
            DropdownMenuItem(
              value: 'On Hold',
              child: Text('On Hold'),
            ),
            DropdownMenuItem(
              value: 'Closed',
              child: Text('Closed'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedFilter = value!;
              _currentPage = 1;
            });
          },
        ),
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
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
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

  Widget _buildProjectCard(ProjectModel project, Color themeColor) {
    final String status = project.prjSts.trim().toUpperCase();
    final bool isCompleted = status == 'CLOSED' || status == 'COMPLETED' || status == 'DONE' || project.progressValue >= 1.0;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/project-details', arguments: project);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: themeColor.withValues(alpha: 0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildProjectImage(project.logo, project.prjNm, 90),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.prjNm,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: Color(0xff0F172A),
                            height: 1.2,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        if (_isValidString(project.companyName))
                          Text(
                            project.companyName!,
                            style: const TextStyle(fontSize: 11, color: Color(0xff64748B), fontWeight: FontWeight.w600),
                          ),
                        if (_isValidString(project.plantName))
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              project.plantName!,
                              style: const TextStyle(fontSize: 10, color: Color(0xff64748B), fontWeight: FontWeight.w500),
                            ),
                          ),
                        if (_isValidString(project.location))
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 12, color: Color(0xff64748B)),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    project.location!,
                                    style: const TextStyle(fontSize: 10, color: Color(0xff64748B), fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (project.stDt.isNotEmpty || project.endDt.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 11, color: Color(0xff64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  '${_formatDbDate(project.stDt)} - ${_formatDbDate(project.endDt)}',
                                  style: const TextStyle(fontSize: 10, color: Color(0xff64748B), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),
                        if (isCompleted)
                          _buildLeadLagBadge(project.leadLagStatusStr)
                        else
                          _buildPriorityPill(project.prjPrty, getPriorityColor(project.prjPrty)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: project.progressValue,
                              strokeWidth: 3,
                              backgroundColor: const Color(0xffF1F5F9),
                              color: project.barColor,
                            ),
                            Text(
                              project.progressText,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: project.barColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                border: Border(
                  top: BorderSide(
                    color: themeColor.withValues(alpha: 0.20),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Tasks Assigned and Open Tasks
                  Row(
                    children: [
                      _buildMetricBlock('Task Assigned', project.assigned, themeColor),
                      Container(
                        height: 20,
                        width: 1,
                        color: themeColor.withValues(alpha: 0.20),
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      _buildMetricBlock('Open Tasks', project.open, themeColor),
                      Container(
                        height: 20,
                        width: 1,
                        color: themeColor.withValues(alpha: 0.20),
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      _buildMetricBlock('Closed', project.closed, themeColor),
                    ],
                  ),
                  _buildStatusBadge(project.prjSts),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBlock(String title, int count, Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 9.5,
            color: themeColor.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xff1E293B),
          ),
        ),
      ],
    );
  }

  // Priority pill shown in footer
  Widget _buildPriorityPill(String? priority, Color priorityColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: priorityColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            priority?.toUpperCase() ?? 'NORMAL',
            style: TextStyle(
              color: priorityColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String statusStr) {
    final String s = statusStr.trim().toUpperCase();
    Color bg;
    Color text;
    String label;

    if (s == 'CLOSED' || s == 'COMPLETED') {
      bg = const Color(0xffF1F5F9);
      text = const Color(0xff64748B);
      label = 'CLOSED';
    } else if (s == 'LIVE') {
      bg = const Color(0xffDCFCE7);
      text = const Color(0xff16A34A);
      label = 'LIVE';
    } else if (s == 'HOLD' || s == 'ON HOLD') {
      bg = const Color(0xffFEF3C7);
      text = const Color(0xffD97706);
      label = 'ON HOLD';
    } else {
      bg = const Color(0xffDBEAFE);
      text = const Color(0xff2563EB);
      label = s.isNotEmpty ? s : 'IN PROGRESS';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildLeadLagBadge(String statusStr) {
    final String s = statusStr.trim().toLowerCase();
    
    if (s == 'null' || s == 'n/a' || s.isEmpty || s == 'none' || s.contains('on time')) {
      return _buildLeadLagPill('Schedule: On Time', const Color(0xffDBEAFE), const Color(0xff2563EB));
    }

    bool isLead = s.contains('lead') || s == 'ahead';
    bool isLag = s.contains('lag') || s == 'behind' || s == 'delay';

    if (isLead) {
      final label = statusStr.toLowerCase().startsWith('schedule:') ? statusStr : 'Schedule: $statusStr';
      return _buildLeadLagPill(label, const Color(0xffDCFCE7), const Color(0xff16A34A));
    } else if (isLag) {
      final label = statusStr.toLowerCase().startsWith('schedule:') ? statusStr : 'Schedule: $statusStr';
      return _buildLeadLagPill(label, const Color(0xffFEE2E2), const Color(0xffDC2626));
    } else {
      return _buildLeadLagPill('Schedule: On Time', const Color(0xffDBEAFE), const Color(0xff2563EB));
    }
  }

  Widget _buildLeadLagPill(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final totalCount = _filteredProjects.length;
    final totalPages = _totalPages;
    
    int page = _currentPage;
    if (page > totalPages) page = totalPages;
    if (page < 1) page = 1;

    final startItem = totalCount == 0 ? 0 : ((page - 1) * _itemsPerPage + 1);
    final endItem = totalCount == 0 ? 0 : ((page - 1) * _itemsPerPage + _paginatedProjects.length);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xffE2E8F0), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Showing $startItem to $endItem of $totalCount projects',
              style: const TextStyle(fontSize: 11, color: Color(0xff64748B), fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Previous Button (<)
                GestureDetector(
                  onTap: page > 1
                      ? () => setState(() => _currentPage = page - 1)
                      : null,
                  child: _buildPageButton(
                    Icons.chevron_left,
                    false,
                    isDisabled: page <= 1,
                  ),
                ),
                const SizedBox(width: 4),

                // Page Number Buttons (1, 2, 3...)
                ...List.generate(totalPages, (i) {
                  final pageNum = i + 1;
                  final isActive = pageNum == page;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _currentPage = pageNum),
                      child: _buildPageButton(
                        null,
                        isActive,
                        labelText: '$pageNum',
                      ),
                    ),
                  );
                }),

                // Next Button (>)
                GestureDetector(
                  onTap: page < totalPages
                      ? () => setState(() => _currentPage = page + 1)
                      : null,
                  child: _buildPageButton(
                    Icons.chevron_right,
                    false,
                    isDisabled: page >= totalPages,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(IconData? icon, bool isActive, {String? labelText, bool isDisabled = false}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xffEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? const Color(0xff2563EB) : const Color(0xffE2E8F0),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: labelText != null
            ? Text(
                labelText,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isActive ? const Color(0xff2563EB) : const Color(0xff475569),
                ),
              )
            : Icon(
                icon,
                size: 16,
                color: isDisabled ? const Color(0xffCBD5E1) : const Color(0xff475569),
              ),
      ),
    );
  }
}