import 'package:flutter/material.dart';
import '../widgets/header.dart';
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
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    try {
      final results = await Future.wait([
        ApiService.getLiveProjects(),
        ApiService.getLiveTasks(),
        ApiService.getUserDashboardData(),
      ]);

      final liveProjects = results[0] as List<ProjectModel>;
      final liveTasks = results[1] as List<TaskItem>;
      final dashboardData = results[2] as Map<String, dynamic>?;

      final Set<int> assignedProjectIds = {};
      if (dashboardData != null && dashboardData['myProjects'] != null) {
        final myProjectsList = dashboardData['myProjects'] as List<dynamic>;
        for (final p in myProjectsList) {
          final id = (p['projectId'] as num?)?.toInt();
          if (id != null) {
            assignedProjectIds.add(id);
          }
        }
      }

      final filteredLiveProjects = liveProjects.where((p) {
        return assignedProjectIds.contains(p.prjId);
      }).toList();

      // Fallback to all live projects if assigned list is empty
      final projectsToMap = filteredLiveProjects.isEmpty ? liveProjects : filteredLiveProjects;

      final List<ProjectModel> mappedProjects = [];
      for (final p in projectsToMap) {
        final projectTasks = liveTasks.where((t) => t.subtitle.startsWith('${p.prjCd} •')).toList();
        final assigned = projectTasks.length;
        final open = projectTasks.where((t) => t.status != 'Completed').length;
        final completed = assigned - open;
        final progressVal = assigned == 0 ? 0.0 : (completed / assigned);
        final progressTxt = '${(progressVal * 100).round()}%';
        final barColor = progressVal >= 0.7 ? const Color(0xFF16A34A) : const Color(0xFF2563EB);

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
          name: p.prjNm,
          details: p.prjDesc,
          role: 'Assignee',
          assigned: assigned,
          open: open,
          progressValue: progressVal,
          progressText: progressTxt,
          barColor: barColor,
        ));
      }

      setState(() {
        _projects = mappedProjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint(e.toString());
    }
  }

  List<ProjectModel> get _filteredProjects {
    return _projects.where((project) {
      final matchesSearch = project.prjNm
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

      final matchesFilter = _selectedFilter == 'All Projects'
          ? true
          : project.prjSts == _selectedFilter;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFAFBFC),
      appBar: CustomHeader(
        title: 'Projects',
        onNotificationTap: () {
          Navigator.pushNamed(context, '/notifications');
        },
      ),
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
              value: 'Open',
              child: Text('Open'),
            ),
            DropdownMenuItem(
              value: 'In Progress',
              child: Text('In Progress'),
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

  Widget _buildProjectCard(ProjectModel project, Color themeColor) {
    final priorityColor = getPriorityColor(project.prjPrty);
    
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
                    child: Image.asset(
                      'assets/company.png',
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 90,
                          height: 90,
                          color: const Color(0xffF1F5F9),
                          child: const Icon(
                            Icons.business,
                            color: Color(0xff94A3B8),
                            size: 32,
                          ),
                        );
                      },
                    ),
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
                        // Fixed LayoutBuilder section
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final label = project.prjCd ?? '';
                            
                            final textPainter = TextPainter(
                              text: TextSpan(text: label, style: const TextStyle(fontSize: 10)),
                              maxLines: 1,
                              textDirection: TextDirection.ltr,
                            )..layout(maxWidth: constraints.maxWidth);

                            if (textPainter.didExceedMaxLines) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    project.prjDesc ?? '',
                                    style: const TextStyle(fontSize: 10, color: Color(0xff64748B), fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    project.stDt ?? '',
                                    style: const TextStyle(fontSize: 10, color: Color(0xff64748B), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              );
                            } else {
                              return Text(
                                label,
                                style: const TextStyle(fontSize: 10, color: Color(0xff64748B), fontWeight: FontWeight.w500),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildPriorityBadge(project.prjPrty, priorityColor),
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
                              color: priorityColor,
                            ),
                            Text(
                              project.progressText,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: priorityColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildLeadLagBadge(project.progressValue >= 0.5),
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
                  Row(
                    children: [
                      _buildMetricBlock('Tasks Assigned', project.assigned, themeColor),
                      Container(
                        height: 20,
                        width: 1,
                        color: themeColor.withValues(alpha: 0.20),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      _buildMetricBlock('Open Tasks', project.open, themeColor),
                    ],
                  ),
                  _buildStatusPill(project.prjSts, themeColor),
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

  Widget _buildPriorityBadge(String? priority, Color priorityColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: priorityColor.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        priority ?? 'Normal',
        style: TextStyle(
          color: priorityColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusPill(String? status, Color themeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Text(
        status ?? 'Open',
        style: TextStyle(
          color: themeColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildLeadLagBadge(bool isLead) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isLead
            ? const Color(0xffDCFCE7)
            : const Color(0xffFEE2E2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isLead ? 'Lead' : 'Lag',
        style: TextStyle(
          color: isLead
              ? const Color(0xff10B981)
              : const Color(0xffEF4444),
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
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