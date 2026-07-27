import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  
  String _selectedFilter = 'All Projects';
  String _searchQuery = '';

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

      final List<ProjectModel> liveProjects;
      if (myProjectsData.isNotEmpty) {
        liveProjects = myProjectsData.map((json) {
          final dbProj = ProjectModel.fromJson(Map<String, dynamic>.from(json));
          final matchedFull = fullDetailProjects.firstWhere(
            (p) => p.prjId == dbProj.prjId,
            orElse: () => dbProj,
          );
          
          return ProjectModel(
            prjId: dbProj.prjId,
            prjCd: dbProj.prjCd.isNotEmpty ? dbProj.prjCd : matchedFull.prjCd,
            prjNm: dbProj.prjNm.isNotEmpty ? dbProj.prjNm : matchedFull.prjNm,
            prjDesc: dbProj.prjDesc.isNotEmpty ? dbProj.prjDesc : matchedFull.prjDesc,
            prjPrty: matchedFull.prjPrty.isNotEmpty ? matchedFull.prjPrty : dbProj.prjPrty,
            prjSts: dbProj.prjSts.isNotEmpty ? dbProj.prjSts : matchedFull.prjSts,
            stDt: matchedFull.stDt.isNotEmpty ? matchedFull.stDt : dbProj.stDt,
            endDt: matchedFull.endDt.isNotEmpty ? matchedFull.endDt : dbProj.endDt,
            noOfDays: matchedFull.noOfDays > 0 ? matchedFull.noOfDays : dbProj.noOfDays,
            logo: matchedFull.logo ?? dbProj.logo,
            addlRem: matchedFull.addlRem ?? dbProj.addlRem,
            leadLagStatus: matchedFull.leadLagStatus ?? dbProj.leadLagStatus,
            pltId: matchedFull.pltId != 0 ? matchedFull.pltId : dbProj.pltId,
            coyId: matchedFull.coyId != 0 ? matchedFull.coyId : dbProj.coyId,
            name: dbProj.name.isNotEmpty ? dbProj.name : matchedFull.name,
            details: dbProj.details.isNotEmpty ? dbProj.details : matchedFull.details,
            role: dbProj.role.isNotEmpty ? dbProj.role : matchedFull.role,
            assigned: dbProj.rawAssigned ?? matchedFull.rawAssigned,
            open: dbProj.rawOpen ?? matchedFull.rawOpen,
            inProgress: dbProj.rawInProgress ?? matchedFull.rawInProgress,
            progressValue: dbProj.rawProgressValue, // Do NOT fall back to matchedFull.rawProgressValue which has wrong static values!
            progressText: dbProj.progressText != '0%' ? dbProj.progressText : (dbProj.rawProgressValue != null ? dbProj.progressText : null),
            barColor: dbProj.progressText != '0%' ? dbProj.barColor : (dbProj.rawProgressValue != null ? dbProj.barColor : null),
            companyName: matchedFull.companyName ?? dbProj.companyName,
            plantName: matchedFull.plantName ?? dbProj.plantName,
            location: matchedFull.location ?? dbProj.location,
            leadLagStatusStr: matchedFull.leadLagStatusStr != 'Lag' ? matchedFull.leadLagStatusStr : dbProj.leadLagStatusStr,
          );
        }).toList();
      } else {
        liveProjects = fullDetailProjects;
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

      final leadLagFutures = liveProjects.map((p) => ApiService.getProjectLeadLagStatus(p.prjId)).toList();
      final leadLagResults = await Future.wait(leadLagFutures);
      final Map<int, String> leadLagMap = {};
      for (int i = 0; i < liveProjects.length; i++) {
        leadLagMap[liveProjects[i].prjId] = leadLagResults[i];
      }

      final List<ProjectModel> mappedProjects = [];
      for (final p in liveProjects) {
        final projectTasks = combinedTasks.where((t) => 
          t.projectId == p.prjId || 
          (t.projectCode != null && t.projectCode == p.prjCd) ||
          (t.projectName != null && t.projectName == p.prjNm)
        ).toList();

        final int totalAssigned = projectTasks.length;
        final int completed = projectTasks.where((t) => t.isCompleted).length;
        final int inProgress = projectTasks.where((t) => t.isInProgress || t.isUnderReview).length;
        final int open = totalAssigned - completed;

        // Use backend progress if available, otherwise fallback to task counts
        final double progressVal = p.rawProgressValue ?? (totalAssigned > 0 ? (completed / totalAssigned) : 0.0);
        final String progressTxt = p.rawProgressValue != null 
            ? p.progressText 
            : '${(progressVal * 100).round()}%';
            
        Color barColor;
        if (progressVal < 0.5) {
          barColor = const Color(0xffF97316);
        } else if (progressVal < 1.0) {
          barColor = const Color(0xff3B82F6);
        } else {
          barColor = const Color(0xff22C55E);
        }

        final int assigned = p.rawAssigned ?? totalAssigned;
        final int openCount = p.rawOpen ?? open;

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

        mappedProjects.add(ProjectModel(
          prjId: p.prjId,
          prjCd: p.prjCd,
          prjNm: p.prjNm,
          prjDesc: p.prjDesc,
          prjPrty: p.prjPrty,
          prjSts: p.prjSts,
          stDt: p.stDt,
          endDt: p.endDt,
          noOfDays: p.noOfDays,
          logo: p.logo,
          addlRem: p.addlRem,
          leadLagStatus: p.leadLagStatus,
          pltId: p.pltId,
          coyId: p.coyId,
          name: p.name,
          details: p.details,
          role: p.role,
          assigned: assigned,
          open: openCount,
          inProgress: inProgress,
          progressValue: progressVal,
          progressText: progressTxt,
          barColor: barColor,
          companyName: companyName,
          plantName: plantName,
          location: location,
          leadLagStatusStr: leadLagMap[p.prjId] ?? p.leadLagStatusStr,
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
                        itemCount: _filteredProjects.length,
                        itemBuilder: (context, index) {
                          return _buildProjectCard(
                            _filteredProjects[index],
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
                        const SizedBox(height: 8),
                        // Priority badge REMOVED from here
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
                  if (isCompleted)
                    _buildLeadLagBadge(project.leadLagStatusStr)
                  else
                    _buildPriorityPill(project.prjPrty, getPriorityColor(project.prjPrty)),
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

  Widget _buildLeadLagBadge(String statusStr) {
    final String s = statusStr.trim().toLowerCase();
    bool isLead = s == 'lead';
    bool isLag = s == 'lag';
    bool isOnTime = s == 'on time' || s == 'ontime' || s == 'on-time';

    String displayText = isLead
        ? 'Lead'
        : isLag
            ? 'Lag'
            : isOnTime
                ? 'On Time'
                : (statusStr.isEmpty ? 'Lag' : statusStr);

    Color bgColor = const Color(0xffF1F5F9);
    Color textColor = const Color(0xff475569);

    if (isLead) {
      bgColor = const Color(0xffDCFCE7);
      textColor = const Color(0xff16A34A);
    } else if (isLag) {
      bgColor = const Color(0xffFEE2E2);
      textColor = const Color(0xffDC2626);
    } else if (isOnTime) {
      bgColor = const Color(0xffDBEAFE);
      textColor = const Color(0xff2563EB);
    }

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
            displayText.toUpperCase(),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xffE2E8F0), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing 1 to ${_filteredProjects.length} of ${_filteredProjects.length} projects',
            style: const TextStyle(fontSize: 11, color: Color(0xff64748B), fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              _buildPageButton(Icons.chevron_left, false),
              const SizedBox(width: 4),
              _buildPageButton(null, true, labelText: '1'),
              const SizedBox(width: 4),
              _buildPageButton(Icons.chevron_right, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(IconData? icon, bool isActive, {String? labelText}) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive ? const Color(0xff2563EB) : const Color(0xffE2E8F0),
          width: isActive ? 1.2 : 1,
        ),
      ),
      child: Center(
        child: labelText != null
            ? Text(
                labelText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive ? const Color(0xff2563EB) : const Color(0xff475569),
                ),
              )
            : Icon(icon, size: 14, color: const Color(0xff94A3B8)),
      ),
    );
  }
}