import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../widgets/header.dart';
import '../models/task_item.dart';
import '../models/project_model.dart';
import 'main_screen.dart';
import 'notification_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

    final todoTasks = globalTasks.take(4).toList();
    final upcomingTasks = globalTasks.where((task) => task.date != 'Today').toList();
    final String currentDynamicDate = DateFormat('dd MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomHeader(
        title: "Home",
        automaticallyImplyLeading: false,
        onNotificationTap: () {
          Navigator.pushNamed(context, '/notifications');
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 14.0, right: 14.0, top: 16.0, bottom: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, Ravi Kumar! 👋',
              style: GoogleFonts.inter(fontSize: isSmallScreen ? 18 : 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Site Engineer  |  Projects Department',
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
              child: Column(
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
                children: [
                  _buildImageStyleProjectItem(ProjectModel(name: '50 TPD CBG Plant Construction', details: 'Atirath Bio Energy Pvt. Ltd. | Nalgonda Plant', role: 'Site Engineer', assigned: 8, open: 3, progressValue: 0.65, progressText: '65%', barColor: const Color(0xFF16A34A))),
                  _buildImageStyleProjectItem(ProjectModel(name: 'Bio Fertilizer Unit', details: 'Atirath Bio Energy Pvt. Ltd. | Nalgonda Plant', role: 'QA Engineer', assigned: 4, open: 2, progressValue: 0.40, progressText: '40%', barColor: const Color(0xFF16A34A))),
                  _buildImageStyleProjectItem(ProjectModel(name: 'CBG Expansion Phase-II', details: 'Atirath Bio Energy Pvt. Ltd. | Nalgonda Plant', role: 'Reviewer', assigned: 5, open: 1, progressValue: 0.25, progressText: '25%', barColor: const Color(0xFF2563EB))),
                ],
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
                          PieChartSectionData(color: const Color(0xFF00A65A), value: 64, showTitle: false, radius: 15),
                          PieChartSectionData(color: const Color(0xFF0073B7), value: 24, showTitle: false, radius: 15),
                          PieChartSectionData(color: const Color(0xFFF39C12), value: 8, showTitle: false, radius: 15),
                          PieChartSectionData(color: const Color(0xFF605CA8), value: 4, showTitle: false, radius: 15),
                          PieChartSectionData(color: const Color(0xFFDD4B39), value: 4, showTitle: false, radius: 15),
                        ],
                      ),
                    ),
                  );

                  Widget legendWidget = Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildChartLegend(const Color(0xFF00A65A), 'Completed', '32 (64%)'),
                      _buildChartLegend(const Color(0xFF0073B7), 'In Progress', '12 (24%)'),
                      _buildChartLegend(const Color(0xFFF39C12), 'Under Review', '4 (8%)'),
                      _buildChartLegend(const Color(0xFF605CA8), 'Pending', '2 (4%)'),
                      _buildChartLegend(const Color(0xFFDD4B39), 'Overdue', '2 (4%)'),
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
                        child: Text('64%\nOverall Completion', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
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
                  _buildBottomStatCard('3', 'My Projects', 'View projects', Icons.business, const Color(0xFFECFDF5), const Color(0xFF10B981), 1), // ✅ Projects tab
                  _buildBottomStatCard('14', 'My Tasks', 'View tasks', Icons.assignment_turned_in_outlined, const Color(0xFFEFF6FF), const Color(0xFF2563EB), 2), // ✅ Tasks tab
                  _buildBottomStatCard('2', 'Due Today', 'View today\'s tasks', Icons.calendar_today, const Color(0xFFFFF7ED), const Color(0xFFF59E0B), 2), // ✅ Tasks tab
                  _buildBottomStatCard('1', 'Overdue Tasks', 'View overdue', Icons.error_outline_rounded, const Color(0xFFFEF2F2), const Color(0xFFEF4444), 2), // ✅ Tasks tab
                  _buildBottomStatCard('32', 'Completed Tasks', 'View completed', Icons.check_circle_outline, const Color(0xFFF5F3FF), const Color(0xFF8B5CF6), 2), // ✅ Tasks tab
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