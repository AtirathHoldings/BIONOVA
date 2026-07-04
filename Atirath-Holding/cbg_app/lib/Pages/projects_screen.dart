import 'package:flutter/material.dart';
import '../widgets/header.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  static const Color themeColor = Color(0xff10B981);
  
  String _selectedFilter = 'All Projects';
  String _searchQuery = '';

  final List<ProjectModel> _projects = [
    ProjectModel(
      projectName: '50 TPD CBG Plant Construction',
      companyName: 'Atirath Bio Energy Pvt. Ltd.',
      location: 'Nalgonda Plant',
      taskAssigned: 8,
      openTasks: 3,
      progress: 65,
      status: 'In Progress',
      priority: 'Atmost Critical',
    ),
    ProjectModel(
      projectName: 'Bio Fertilizer Unit',
      companyName: 'Atirath Bio Energy Pvt. Ltd.',
      location: 'Nalgonda Plant',
      taskAssigned: 4,
      openTasks: 2,
      progress: 40,
      status: 'Open',
      priority: 'Critical',
    ),
    ProjectModel(
      projectName: 'CBG Expansion Phase-II',
      companyName: 'Atirath Bio Energy Pvt. Ltd.',
      location: 'Nalgonda Plant',
      taskAssigned: 5,
      openTasks: 1,
      progress: 25,
      status: 'Open',
      priority: 'High',
    ),
    ProjectModel(
      projectName: 'Gas Pipeline Installation',
      companyName: 'Atirath Bio Energy Pvt. Ltd.',
      location: 'Nalgonda Plant',
      taskAssigned: 12,
      openTasks: 5,
      progress: 55,
      status: 'In Progress',
      priority: 'Medium',
    ),
    ProjectModel(
      projectName: 'Water Treatment Plant',
      companyName: 'Atirath Bio Energy Pvt. Ltd.',
      location: 'Nalgonda Plant',
      taskAssigned: 10,
      openTasks: 0,
      progress: 100,
      status: 'Closed',
      priority: 'Normal',
    ),
    ProjectModel(
      projectName: 'Solar Power Integration',
      companyName: 'Atirath Bio Energy Pvt. Ltd.',
      location: 'Nalgonda Plant',
      taskAssigned: 3,
      openTasks: 1,
      progress: 15,
      status: 'Open',
      priority: 'Low',
    ),
  ];

  List<ProjectModel> get _filteredProjects {
    return _projects.where((project) {
      final matchesSearch = project.projectName
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

      final matchesFilter = _selectedFilter == 'All Projects'
          ? true
          : project.status == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Color getPriorityColor(String priority) {
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
      body: Column(
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
    final priorityColor = getPriorityColor(project.priority);
    
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/project-details');
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
                          project.projectName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: Color(0xff0F172A),
                            height: 1.2,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final label = '${project.companyName}   |   ${project.location}';
                            
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
                                    project.companyName,
                                    style: const TextStyle(fontSize: 10, color: Color(0xff64748B), fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    project.location,
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
                        _buildPriorityBadge(project.priority, priorityColor),
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
                              value: project.progress / 100,
                              strokeWidth: 3,
                              backgroundColor: const Color(0xffF1F5F9),
                              color: priorityColor,
                            ),
                            Text(
                              '${project.progress}%',
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
                      _buildLeadLagBadge(project.progress >= 50),
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
                      _buildMetricBlock('Tasks Assigned', project.taskAssigned, themeColor),
                      Container(
                        height: 20,
                        width: 1,
                        color: themeColor.withValues(alpha: 0.20),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      _buildMetricBlock('Open Tasks', project.openTasks, themeColor),
                    ],
                  ),
                  _buildStatusPill(project.status, themeColor),
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

  Widget _buildPriorityBadge(String priority, Color priorityColor) {
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
        priority,
        style: TextStyle(
          color: priorityColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status, Color themeColor) {
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
        status,
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

class ProjectModel {
  final String projectName;
  final String companyName;
  final String location;
  final int taskAssigned;
  final int openTasks;
  final int progress;
  final String status;
  final String priority;

  ProjectModel({
    required this.projectName,
    required this.companyName,
    required this.location,
    required this.taskAssigned,
    required this.openTasks,
    required this.progress,
    required this.status,
    required this.priority,
  });
}