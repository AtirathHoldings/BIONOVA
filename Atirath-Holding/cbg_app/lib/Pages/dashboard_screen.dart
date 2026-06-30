import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../widgets/header.dart';
import '../models/task_item.dart';
import '../models/project_model.dart';
import 'main_screen.dart';
import 'notification_screen.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<ProjectModel> _projects = [];
  List<TaskItem> _tasks = [];
  List<TaskItem> _todoTasks = [];
  List<TaskItem> _upcomingTasks = [];
  bool _isLoading = true;
  String? _error;
  String _userName = 'Welcome!';
  String _userRole = '';
  int _unreadNotificationCount = 0;

  int _myTasksCount = 0;
  int _dueTodayCount = 0;
  int _overdueTasksCount = 0;
  int _completedTasksCount = 0;
  double _overallCompletionPercentage = 0.0;
  int _wipCount = 0;
  int _underReviewCount = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      // Fetch user dashboard data, tasks list and unread notifications in parallel
      final results = await Future.wait([
        ApiService.getUserDashboardData(),
        ApiService.getLiveTasks(),
        ApiService.getUnreadNotifications(),
      ]);

      final dashboardData = results[0] as Map<String, dynamic>?;
      final liveTasks = results[1] as List<TaskItem>;
      final unreadNotifications = results[2] as List<dynamic>;

      if (dashboardData == null) {
        throw Exception('Failed to load dashboard data');
      }

      final fullName = dashboardData['fullName']?.toString() ?? '';
      final role = dashboardData['role']?.toString() ?? '';

      // Map Projects from backend dashboard data
      final List<ProjectModel> mappedProjects = [];
      final List<dynamic> myProjectsData = dashboardData['myProjects'] as List<dynamic>? ?? [];
      for (final p in myProjectsData) {
        final double progressDouble = (p['progress'] as num?)?.toDouble() ?? 0.0;
        final double progressVal = progressDouble / 100.0;
        final progressTxt = '${progressDouble.round()}%';
        final barColor = progressVal >= 0.7 ? const Color(0xFF16A34A) : const Color(0xFF2563EB);

        mappedProjects.add(ProjectModel(
          prjId: (p['projectId'] as num?)?.toInt() ?? 0,
          prjCd: p['projectCode']?.toString() ?? '',
          prjNm: p['projectName']?.toString() ?? '',
          prjDesc: p['projectName']?.toString() ?? '',
          prjPrty: 'Medium',
          prjSts: p['status']?.toString() ?? '',
          name: p['projectName']?.toString(),
          details: p['clientName']?.toString() ?? p['projectName']?.toString(),
          role: p['role']?.toString() ?? 'Assignee',
          assigned: (p['tasksAssigned'] as num?)?.toInt() ?? 0,
          open: (p['openTasks'] as num?)?.toInt() ?? 0,
          progressValue: progressVal,
          progressText: progressTxt,
          barColor: barColor,
        ));
      }

      // Map To-Do List tasks matching the backend order & IDs
      final List<dynamic> todoListData = dashboardData['todoList'] as List<dynamic>? ?? [];
      final List<TaskItem> mappedTodoTasks = [];
      for (final t in todoListData) {
        final String tId = t['taskId']?.toString() ?? '';
        final match = liveTasks.firstWhere(
          (item) => item.id == tId,
          orElse: () => const TaskItem(id: '', title: '', subtitle: '', date: '', tag: '', tagColor: Colors.transparent, tagBg: Colors.transparent, icon: Icons.error, iconColor: Colors.transparent, iconBg: Colors.transparent, status: '', priority: ''),
        );
        if (match.id.isNotEmpty) {
          mappedTodoTasks.add(match);
        }
      }

      // Map Upcoming tasks matching the backend order & IDs
      final List<dynamic> upcomingListData = dashboardData['upcomingTasks'] as List<dynamic>? ?? [];
      final List<TaskItem> mappedUpcomingTasks = [];
      for (final t in upcomingListData) {
        final String tId = t['taskId']?.toString() ?? '';
        final match = liveTasks.firstWhere(
          (item) => item.id == tId,
          orElse: () => const TaskItem(id: '', title: '', subtitle: '', date: '', tag: '', tagColor: Colors.transparent, tagBg: Colors.transparent, icon: Icons.error, iconColor: Colors.transparent, iconBg: Colors.transparent, status: '', priority: ''),
        );
        if (match.id.isNotEmpty) {
          mappedUpcomingTasks.add(match);
        }
      }

      // Fallback to client-side logic if backend returns empty lists
      if (mappedTodoTasks.isEmpty) {
        mappedTodoTasks.addAll(liveTasks.where((task) => task.hasStarted).take(4));
      }
      if (mappedUpcomingTasks.isEmpty) {
        mappedUpcomingTasks.addAll(liveTasks.where((task) => !task.hasStarted).take(4));
      }

      final int myTasksVal = (dashboardData['myTasksCount'] as num?)?.toInt() ?? 0;
      final int completedCountVal = (dashboardData['completedTasksCount'] as num?)?.toInt() ?? 0;
      final int dueTodayVal = (dashboardData['dueTodayCount'] as num?)?.toInt() ?? 0;
      final int overdueCountVal = (dashboardData['overdueTasksCount'] as num?)?.toInt() ?? 0;
      final double overallPctVal = (dashboardData['overallCompletionPercentage'] as num?)?.toDouble() ?? 0.0;

      final Map<String, dynamic> statusCounts = dashboardData['taskStatusCounts'] as Map<String, dynamic>? ?? {};
      final int wipVal = (statusCounts['In Progress'] as num?)?.toInt() ?? 0;
      final int underReviewVal = (statusCounts['Under Review'] as num?)?.toInt() ?? 0;
      final int pendingVal = (statusCounts['Pending'] as num?)?.toInt() ?? 0;

      if (mounted) {
        setState(() {
          _userName = fullName.isEmpty ? 'Welcome!' : fullName;
          _userRole = role;
          _projects = mappedProjects;
          _tasks = liveTasks;
          _todoTasks = mappedTodoTasks;
          _upcomingTasks = mappedUpcomingTasks;
          _myTasksCount = myTasksVal;
          _completedTasksCount = completedCountVal;
          _dueTodayCount = dueTodayVal;
          _overdueTasksCount = overdueCountVal;
          _overallCompletionPercentage = overallPctVal;
          _wipCount = wipVal;
          _underReviewCount = underReviewVal;
          _pendingCount = pendingVal;
          _unreadNotificationCount = unreadNotifications.length;
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
    }
  }

  void _navigateToTaskDetails(TaskItem task) {
    Navigator.pushNamed(
      context,
      '/task-details',
      arguments: task,
    );
  }

  void _navigateToProjectDetails(ProjectModel project) {
    Navigator.pushNamed(
      context,
      '/project-details',
      arguments: project,
    );
  }

  // ✅ Navigate to tab using MainScreen controller
  void _navigateToTab(int index) {
    MainScreen.navigatorKey.currentState?.changeTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    final todoTasks = _todoTasks;
    final upcomingTasks = _upcomingTasks;
    final String currentDynamicDate = DateFormat('dd MMMM yyyy').format(DateTime.now());

    final total = _myTasksCount;
    final completedCount = _completedTasksCount;
    final inProgressCount = _wipCount;
    final underReviewCount = _underReviewCount;
    final pendingCount = _pendingCount;
    final overdueCount = _overdueTasksCount;

    final completedPct = total == 0 ? 0.0 : (completedCount / total * 100);
    final inProgressPct = total == 0 ? 0.0 : (inProgressCount / total * 100);
    final underReviewPct = total == 0 ? 0.0 : (underReviewCount / total * 100);
    final pendingPct = total == 0 ? 0.0 : (pendingCount / total * 100);
    final overduePct = total == 0 ? 0.0 : (overdueCount / total * 100);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomHeader(
        title: "Home",
        automaticallyImplyLeading: false,
        notificationCount: _unreadNotificationCount,
        onNotificationTap: () async {
          await Navigator.pushNamed(context, '/notifications');
          _fetchDashboardData();
        },
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF071D49),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF051637)),
              child: Row(
                children: [
                  const Icon(Icons.eco, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('CBG', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Project Management System', style: GoogleFonts.inter(color: Colors.white70, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(Icons.dashboard, 'Dashboard', true, 0),
                  _buildDrawerItem(Icons.assignment_outlined, 'My Projects', false, 1),
                  _buildDrawerItem(Icons.task_alt, 'My Tasks', false, 2),
                  _buildDrawerItem(Icons.calendar_month, 'Calendar', false, 3),
                  _buildDrawerItem(Icons.dashboard_customize, 'Task Board', false, 2),
                  _buildDrawerItem(Icons.file_copy, 'Document Upload', false, 1),
                  _buildDrawerItem(Icons.report_problem, 'Issues & Escalation', false, 0),
                ],
              ),
            ),
          ],
        ),
      ),
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
                    padding: const EdgeInsets.symmetric(vertical: 80.0),
                    child: Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 14.0, right: 14.0, top: 16.0, bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, $_userName! 👋',
                        style: GoogleFonts.inter(fontSize: isSmallScreen ? 18 : 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _userRole.isNotEmpty ? '$_userRole  |  Projects Department' : 'Projects Department',
                              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: isSmallScreen ? 11 : 12, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            currentDynamicDate,
                            style: GoogleFonts.inter(color: Colors.grey, fontSize: isSmallScreen ? 11 : 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTodoSectionCard(
                        title: 'To-Do List',
                        trailingText: 'View All',
                        onTrailingTap: () {
                          _navigateToTab(2); // ✅ Tasks tab
                        },
                        child: todoTasks.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(child: Text('No to-do tasks found', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey))),
                              )
                            : Column(
                                children: todoTasks.map((task) {
                                  return _buildImageStyleTodoItem(task, isSmallScreen);
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionCard(
                        title: 'UPCOMING TASKS',
                        trailingText: 'View all',
                        headerIcon: Icons.calendar_month_outlined,
                        onTrailingTap: () {
                          _navigateToTab(2); // ✅ Tasks tab
                        },
                        child: Column(
                          children: [
                            _buildUpcomingTaskRow(null, 'Task Name', 'Project', 'Due Date', 'Priority', isHeader: true),
                            const Divider(color: Color(0xFFE2E8F0)),
                            if (upcomingTasks.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(child: Text('No upcoming tasks found', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey))),
                              )
                            else
                              ...upcomingTasks.map((task) {
                                return _buildUpcomingTaskRow(
                                  task,
                                  task.title,
                                  task.subtitle.split('•').first.trim(),
                                  task.date,
                                  task.priority.isEmpty ? task.tag : task.priority,
                                  pColor: task.tagColor,
                                );
                              }),
                          ],
                        ),
                        footerText: 'View all upcoming tasks →',
                      ),
                      const SizedBox(height: 20),
                      _buildProjectSectionCard(
                        title: 'My Projects',
                        trailingText: 'View All',
                        onTrailingTap: () {
                          _navigateToTab(1); // ✅ Projects tab
                        },
                        child: Column(
                          children: _projects.isEmpty
                              ? [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                                    child: Center(child: Text('No projects found', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey))),
                                  )
                                ]
                              : _projects.take(3).map((p) => _buildImageStyleProjectItem(p)).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionCard(
                        title: 'TASK COMPLETION OVERVIEW',
                        trailingText: 'This Month 🔽',
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            bool useVerticalLayout = constraints.maxWidth < 280;

                            Widget chartWidget = SizedBox(
                              height: 130,
                              width: 130,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 35,
                                  startDegreeOffset: 270,
                                  sections: [
                                    PieChartSectionData(color: const Color(0xFF00A65A), value: completedPct == 0 && inProgressPct == 0 && underReviewPct == 0 && pendingPct == 0 && overduePct == 0 ? 1 : completedPct, showTitle: false, radius: 15),
                                    PieChartSectionData(color: const Color(0xFF0073B7), value: inProgressPct, showTitle: false, radius: 15),
                                    PieChartSectionData(color: const Color(0xFFF39C12), value: underReviewPct, showTitle: false, radius: 15),
                                    PieChartSectionData(color: const Color(0xFF605CA8), value: pendingPct, showTitle: false, radius: 15),
                                    PieChartSectionData(color: const Color(0xFFDD4B39), value: overduePct, showTitle: false, radius: 15),
                                  ],
                                ),
                              ),
                            );

                            Widget legendWidget = Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildChartLegend(const Color(0xFF00A65A), 'Completed', '$completedCount (${completedPct.round()}%)'),
                                _buildChartLegend(const Color(0xFF0073B7), 'In Progress', '$inProgressCount (${inProgressPct.round()}%)'),
                                _buildChartLegend(const Color(0xFFF39C12), 'Under Review', '$underReviewCount (${underReviewPct.round()}%)'),
                                _buildChartLegend(const Color(0xFF605CA8), 'Pending', '$pendingCount (${pendingPct.round()}%)'),
                                _buildChartLegend(const Color(0xFFDD4B39), 'Overdue', '$overdueCount (${overduePct.round()}%)'),
                              ],
                            );

                            return Column(
                              children: [
                                useVerticalLayout
                                  ? Column(children: [chartWidget, const SizedBox(height: 10), legendWidget])
                                  : Row(
                                      children: [
                                        Expanded(flex: 4, child: chartWidget),
                                        const SizedBox(width: 10),
                                        Expanded(flex: 5, child: legendWidget),
                                      ],
                                    ),
                                const SizedBox(height: 15),
                                Center(
                                  child: Text('${completedPct.round()}%\nOverall Completion', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                )
                              ],
                            );
                          }
                        ),
                        footerText: 'View detailed report →',
                      ),
                      const SizedBox(height: 20),
                      const SpacerSection(),
                      SizedBox(
                        height: 95,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildBottomStatCard('${_projects.length}', 'My Projects', 'View projects', Icons.business, const Color(0xFFECFDF5), const Color(0xFF10B981), 1),
                            _buildBottomStatCard('$_myTasksCount', 'My Tasks', 'View tasks', Icons.assignment_turned_in_outlined, const Color(0xFFEFF6FF), const Color(0xFF2563EB), 2),
                            _buildBottomStatCard('$_dueTodayCount', 'Due Today', 'View today\'s tasks', Icons.calendar_today, const Color(0xFFFFF7ED), const Color(0xFFF59E0B), 2),
                            _buildBottomStatCard('$_overdueTasksCount', 'Overdue Tasks', 'View overdue', Icons.error_outline_rounded, const Color(0xFFFEF2F2), const Color(0xFFEF4444), 2),
                            _buildBottomStatCard('$_completedTasksCount', 'Completed Tasks', 'View completed', Icons.check_circle_outline, const Color(0xFFF5F3FF), const Color(0xFF8B5CF6), 2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, bool isSelected, int tabIndex) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.white60),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.blue : Colors.white)),
      onTap: () {
        MainScreen.navigatorKey.currentState?.changeTab(tabIndex);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildTodoSectionCard({required String title, required String trailingText, required VoidCallback onTrailingTap, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.playlist_add_check_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))
                  ),
                ],
              ),
              GestureDetector(
                onTap: onTrailingTap,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      trailingText,
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF2563EB), fontWeight: FontWeight.w600)
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 11, color: Color(0xFF2563EB)),
                  ],
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

  Widget _buildImageStyleTodoItem(TaskItem task, bool isSmallScreen) {
    return GestureDetector(
      onTap: () => _navigateToTaskDetails(task),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      task.title,
                      style: GoogleFonts.inter(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 5),
                        Text(
                          '${task.date}  •  ${task.subtitle}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: task.tagBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task.tag,
                style: GoogleFonts.inter(color: task.tagColor, fontSize: 11, fontWeight: FontWeight.w600)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectSectionCard({required String title, required String trailingText, required Widget child, required VoidCallback onTrailingTap}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.business_center, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))
                  ),
                ],
              ),
              GestureDetector(
                onTap: onTrailingTap,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      trailingText,
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF2563EB), fontWeight: FontWeight.w600)
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 11, color: Color(0xFF2563EB)),
                  ],
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

  Widget _buildImageStyleProjectItem(ProjectModel project) {
    return GestureDetector(
      onTap: () => _navigateToProjectDetails(project),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      project.name,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'In Progress',
                    style: GoogleFonts.inter(color: const Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                project.details,
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w400),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text(
                  'Role: ${project.role}',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tasks', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('${project.assigned}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Open', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('${project.open}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Progress', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            project.progressText,
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: project.barColor)
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: project.progressValue,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(project.barColor),
                                minHeight: 6,
                              ),
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
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String trailingText, required Widget child, String? footerText, IconData? headerIcon, VoidCallback? onTrailingTap}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (headerIcon != null) ...[
                    Icon(headerIcon, size: 16, color: const Color(0xFF64748B)),
                    const SizedBox(width: 6),
                  ],
                  Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                ],
              ),
              GestureDetector(
                onTap: onTrailingTap,
                child: Text(trailingText, style: GoogleFonts.inter(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFE2E8F0)),
          child,
          if (footerText != null) ...[
            const Divider(height: 20, color: Color(0xFFE2E8F0)),
            GestureDetector(
              onTap: onTrailingTap,
              child: Center(
                child: Text(footerText, style: GoogleFonts.inter(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildUpcomingTaskRow(TaskItem? task, String col1, String col2, String col3, String col4, {bool isHeader = false, Color? pColor}) {
    TextStyle style = GoogleFonts.inter(
      fontSize: isHeader ? 11 : 12,
      fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
      color: isHeader ? const Color(0xFF64748B) : const Color(0xFF1E293B),
    );
    
    return GestureDetector(
      onTap: () {
        if (!isHeader && task != null) {
          _navigateToTaskDetails(task);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: Text(
                col1,
                style: style,
                maxLines: 2,
                overflow: TextOverflow.visible,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 3,
              child: Text(
                col2,
                style: isHeader ? style : style.copyWith(color: const Color(0xFF64748B), fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 3,
              child: Text(
                col3,
                style: isHeader ? style : style.copyWith(color: const Color(0xFF475569), fontSize: 11),
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 2,
              child: isHeader
                  ? Text(col4, style: style, textAlign: TextAlign.center)
                  : Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      decoration: BoxDecoration(
                        color: pColor != null ? pColor.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        col4,
                        style: TextStyle(color: pColor ?? Colors.grey, fontSize: 9, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(Color color, String label, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomStatCard(
    String count,
    String label,
    String actionText,
    IconData icon,
    Color iconBgColor,
    Color themeColor,
    int tabIndex
  ) {
    return GestureDetector(
      onTap: () {
        _navigateToTab(tabIndex);
      },
      child: Container(
        width: 190,
        margin: const EdgeInsets.only(right: 12, bottom: 6, top: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: themeColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count,
                    style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), height: 1.1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        actionText,
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF2563EB), fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 10, color: Color(0xFF2563EB)),
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
}

class SpacerSection extends StatelessWidget {
  const SpacerSection({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(height: 0);
}