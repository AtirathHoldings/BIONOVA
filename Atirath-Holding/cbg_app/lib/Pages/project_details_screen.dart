import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import 'main_screen.dart';

// --- DATA MODELS ---
class MilestoneModel {
  final String id;
  final String title;
  final String desc;
  final String startDate;
  final String targetDate;
  final int progress;
  final int assigned;
  final int open;
  final String status;
  final Color color;

  MilestoneModel({
    required this.id,
    required this.title,
    required this.desc,
    required this.startDate,
    required this.targetDate,
    required this.progress,
    required this.assigned,
    required this.open,
    required this.status,
    required this.color,
  });
}

class TaskModel {
  final String code;
  final String name;
  final String assignedTo;
  final String priority;
  final String dueDate;
  final String status;
  final double progress;
  final Color priorityColor;
  final Color statusColor;

  TaskModel({
    required this.code,
    required this.name,
    required this.assignedTo,
    required this.priority,
    required this.dueDate,
    required this.status,
    required this.progress,
    required this.priorityColor,
    required this.statusColor,
  });
}

class GanttItemModel {
  final String id;
  final String milestoneName;
  final String taskName;
  final String progress;
  final int startDay;
  final int durationDays;

  GanttItemModel({
    required this.id,
    required this.milestoneName,
    required this.taskName,
    required this.progress,
    required this.startDay,
    required this.durationDays,
  });
}

// --- MAIN SCREEN WIDGET ---
class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({super.key});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 1;

  // Scroll controller
  final ScrollController _horizontalScrollController = ScrollController();

  // Gantt Chart Matrix Constraints
  static const double rowHeight = 50.0;
  static const double barHeight = 28.0;
  static const double ganttHeaderHeight = 50.0;
  double _baseDayWidth = 28.0;
  double _scaleFactor = 1.0;
  double _zoomPercent = 70.0;

  // Selected task ID for highlighting
  String? _selectedTaskId;

  // Milestone dropdown
  String _selectedMilestone = "All Milestones";
  final List<String> _milestoneNames = ["All Milestones", "Project Initiation", "Civil Construction"];

  final List<MilestoneModel> _milestones = [
    MilestoneModel(id: "1", title: "PCC Work Completion", desc: "PCC work for foundation and structures", startDate: "10-Apr-2025", targetDate: "02-Jun-2025", progress: 100, assigned: 2, open: 0, status: "Completed", color: const Color(0xff10B981)),
    MilestoneModel(id: "2", title: "Reinforcement Fixing", desc: "Rebar fixing for all major structures", startDate: "03-Jun-2025", targetDate: "05-Jun-2025", progress: 60, assigned: 3, open: 2, status: "In Progress", color: const Color(0xff2563EB)),
    MilestoneModel(id: "3", title: "Equipment Foundation", desc: "Foundation work for equipment and skids", startDate: "05-Jun-2025", targetDate: "20-Jun-2025", progress: 20, assigned: 2, open: 2, status: "In Progress", color: const Color(0xff7C3AED)),
    MilestoneModel(id: "4", title: "Grouting Work", desc: "Grouting for equipment foundation", startDate: "21-Jun-2025", targetDate: "10-Jun-2025", progress: 0, assigned: 1, open: 1, status: "Not Started", color: const Color(0xff94A3B8)),
    MilestoneModel(id: "5", title: "Pipe Line Installation", desc: "Installation of process piping", startDate: "11-Jun-2025", targetDate: "25-Jul-2025", progress: 0, assigned: 4, open: 4, status: "Not Started", color: const Color(0xff94A3B8)),
  ];

  final List<TaskModel> _tasks = [
    TaskModel(code: "PRJ-001-T02", name: "Column Reinforcement - C1 to C10", assignedTo: "Ravi Kumar (You)", priority: "High", dueDate: "04-Jun-2025", status: "In Progress", progress: 0.6, priorityColor: const Color(0xffEF4444), statusColor: const Color(0xff2563EB)),
    TaskModel(code: "PRJ-001-T03", name: "Beam Reinforcement - B1 to B8", assignedTo: "Ravi Kumar (You)", priority: "Medium", dueDate: "05-Jun-2025", status: "Pending", progress: 0.0, priorityColor: const Color(0xffF59E0B), statusColor: const Color(0xffF59E0B)),
    TaskModel(code: "PRJ-001-T04", name: "Slab Reinforcement - S1", assignedTo: "Ravi Kumar (You)", priority: "Medium", dueDate: "05-Jun-2025", status: "Pending", progress: 0.0, priorityColor: const Color(0xffF59E0B), statusColor: const Color(0xffF59E0B)),
  ];

  final List<GanttItemModel> _ganttData = [
    GanttItemModel(
      id: "g1",
      milestoneName: "Milestone 1",
      taskName: "Task A - Site Preparation",
      progress: "100%",
      startDay: 1,
      durationDays: 6,
    ),
    GanttItemModel(
      id: "g2",
      milestoneName: "Milestone 2",
      taskName: "Task B - Excavation",
      progress: "100%",
      startDay: 5,
      durationDays: 6,
    ),
    GanttItemModel(
      id: "g3",
      milestoneName: "Milestone 3",
      taskName: "Task C - PCC Work",
      progress: "87%",
      startDay: 9,
      durationDays: 7,
    ),
    GanttItemModel(
      id: "g4",
      milestoneName: "Milestone 4",
      taskName: "Task D - Reinforcement",
      progress: "60%",
      startDay: 13,
      durationDays: 8,
    ),
    GanttItemModel(
      id: "g5",
      milestoneName: "Milestone 5",
      taskName: "Task E - Shuttering",
      progress: "20%",
      startDay: 18,
      durationDays: 5,
    ),
    GanttItemModel(
      id: "g6",
      milestoneName: "Milestone 6",
      taskName: "Task F - Concrete Pouring",
      progress: "10%",
      startDay: 22,
      durationDays: 4,
    ),
    GanttItemModel(
      id: "g7",
      milestoneName: "Milestone 7",
      taskName: "Task G - Curing",
      progress: "0%",
      startDay: 25,
      durationDays: 6,
    ),
  ];

  List<GanttItemModel> get _currentTasks {
    if (_selectedMilestone == "All Milestones") {
      return _ganttData;
    } else if (_selectedMilestone == "Project Initiation") {
      return _ganttData.where((item) => 
        item.milestoneName.contains("Milestone 1") ||
        item.milestoneName.contains("Milestone 2")
      ).toList();
    } else {
      return _ganttData.where((item) => 
        !item.milestoneName.contains("Milestone 1") &&
        !item.milestoneName.contains("Milestone 2")
      ).toList();
    }
  }

  Color get _currentColor {
    if (_selectedMilestone == "Project Initiation") {
      return const Color(0xff10B981);
    } else if (_selectedMilestone == "Civil Construction") {
      return const Color(0xff2563EB);
    } else {
      return const Color(0xff2563EB);
    }
  }

  void _updateZoom(double newDayWidth) {
    setState(() {
      _baseDayWidth = newDayWidth.clamp(14.0, 80.0);
      _zoomPercent = ((_baseDayWidth / 40) * 100).roundToDouble();
    });
  }

  // Priority color mapping method
  Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return const Color(0xFF2563EB); // Blue
      case 'normal':
        return const Color(0xFF10B981); // Green
      case 'medium':
        return const Color(0xFFFACC15); // Yellow
      case 'high':
        return const Color(0xFF7C3AED); // Purple
      case 'critical':
        return const Color(0xFFEF4444); // Red
      case 'atmost critical':
        return const Color(0xFF722F37); // Wine
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFAFBFC),
      appBar: CustomHeader(
        title: 'Project Details',
        automaticallyImplyLeading: false,
        onNotificationTap: () {},
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xffE2E8F0)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xff1E293B)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                    label: const Text('Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563EB),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
            ),
            _buildProjectBannerCard(),
            _buildTabBar(),
            Padding(
              padding: _tabController.index == 2
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _tabController.index == 0
                  ? _buildOverviewTabContent()
                  : _tabController.index == 1
                      ? _buildMilestonesTabContent()
                      : _tabController.index == 2
                          ? _buildGanttChartTabContent()
                          : _buildEmptyStateTabContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomFooter(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Use MainScreen's navigation key to change tab
          if (MainScreen.navigatorKey.currentState != null) {
            MainScreen.navigatorKey.currentState!.changeTab(index);
          }
        },
      ),
    );
  }

  Widget _buildGanttChartTabContent() {
    double currentDayWidth = _baseDayWidth * _scaleFactor;
    if (currentDayWidth < 14) currentDayWidth = 14;
    if (currentDayWidth > 80) currentDayWidth = 80;

    final List<GanttItemModel> tasks = _currentTasks;
    final Color milestoneColor = _currentColor;

    // Calculate max day from tasks
    final int maxDay = tasks.isEmpty
        ? 30
        : tasks
            .map((e) => e.startDay + e.durationDays - 1)
            .reduce((a, b) => a > b ? a : b);

    // Generate visible days based on max day
    final List<int> visibleDays = List.generate(maxDay, (index) => index + 1);
    
    final double totalGanttTimelineWidth = visibleDays.length * currentDayWidth;

    // Calculate exact heights
    final double stackHeight = (tasks.length * rowHeight) + 70;
    final double totalChartHeight = ganttHeaderHeight + stackHeight + 20;

    return GestureDetector(
      onScaleUpdate: (ScaleUpdateDetails details) {
        setState(() {
          _scaleFactor = details.scale;
        });
      },
      onScaleEnd: (ScaleEndDetails details) {
        double newWidth = _baseDayWidth * _scaleFactor;
        _updateZoom(newWidth);
        _scaleFactor = 1.0;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Controls Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xffE2E8F0)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedMilestone,
                      underline: const SizedBox(),
                      isExpanded: true,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E293B),
                      ),
                      items: _milestoneNames.map((String value) {
                        Color color;
                        if (value == "All Milestones") {
                          color = const Color(0xff64748B);
                        } else if (value == "Project Initiation") {
                          color = const Color(0xff10B981);
                        } else {
                          color = const Color(0xff2563EB);
                        }
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(value),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedMilestone = value!;
                          _selectedTaskId = null;
                        });
                      },
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                IconButton(
                  icon: const Icon(Icons.remove, size: 18, color: Color(0xff2563EB)),
                  onPressed: () => _updateZoom(_baseDayWidth - 3),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 18,
                ),
                Text(
                  '${_zoomPercent.round()}%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xff1E293B)),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18, color: Color(0xff2563EB)),
                  onPressed: () => _updateZoom(_baseDayWidth + 3),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 18,
                ),
                IconButton(
                  icon: const Icon(Icons.center_focus_strong, size: 16, color: Color(0xff64748B)),
                  onPressed: () => _updateZoom(28.0),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 16,
                ),
              ],
            ),
          ),

          // Gantt Chart
          Container(
            height: totalChartHeight,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xffE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: totalGanttTimelineWidth,
                  height: totalChartHeight,
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        height: ganttHeaderHeight,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xffF8FAFC),
                          border: Border(bottom: BorderSide(color: Color(0xffE2E8F0))),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('May, 2025', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xff1E293B))),
                            const SizedBox(height: 2),
                            Row(
                              children: visibleDays.map((day) {
                                return SizedBox(
                                  width: currentDayWidth,
                                  child: Center(
                                    child: Text(
                                      '$day',
                                      style: GoogleFonts.inter(
                                        fontSize: currentDayWidth < 18 ? 7 : 9,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xff64748B),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            )
                          ],
                        ),
                      ),

                      // Timeline Grid with Bars
                      SizedBox(
                        height: stackHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Grid lines
                            Column(
                              children: List.generate(tasks.length + 1, (index) {
                                return Container(
                                  height: rowHeight,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: index == tasks.length ? Colors.transparent : const Color(0xffF1F5F9),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: visibleDays.map((_) {
                                      return Container(
                                        width: currentDayWidth,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: const Color(0xffF1F5F9),
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              }),
                            ),

                            // Task Bars
                            ...tasks.asMap().entries.map((entry) {
                              final index = entry.key;
                              final task = entry.value;
                              final startPos = (task.startDay - 1) * currentDayWidth;
                              final barWidth = (task.durationDays * currentDayWidth - 4).clamp(20.0, double.infinity);
                              final isSelected = _selectedTaskId == task.id;

                              Color taskColor;
                              if (task.milestoneName.contains("Milestone 1") || 
                                  task.milestoneName.contains("Milestone 2")) {
                                taskColor = const Color(0xff10B981);
                              } else {
                                taskColor = const Color(0xff2563EB);
                              }

                              return Positioned(
                                top: index * rowHeight + (rowHeight - barHeight) / 2,
                                left: startPos + 2,
                                child: SizedBox(
                                  width: barWidth,
                                  height: barHeight + 25,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Main Bar
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedTaskId = isSelected ? null : task.id;
                                            });
                                          },
                                          child: Container(
                                            width: barWidth,
                                            height: barHeight,
                                            decoration: BoxDecoration(
                                              color: isSelected 
                                                  ? taskColor 
                                                  : taskColor.withValues(alpha: 0.8),
                                              borderRadius: BorderRadius.circular(4),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: taskColor.withValues(alpha: 0.3),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 2),
                                                      )
                                                    ]
                                                  : [],
                                              border: isSelected
                                                  ? Border.all(color: Colors.white, width: 2)
                                                  : null,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              task.milestoneName,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: barWidth < 60 ? 8 : 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // Progress
                                      Positioned(
                                        top: 2,
                                        right: 4,
                                        child: Text(
                                          task.progress,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      
                                      // Task Name
                                      if (isSelected)
                                        Positioned(
                                          top: barHeight + 2,
                                          left: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(3),
                                              border: Border.all(color: const Color(0xffE2E8F0)),
                                            ),
                                            child: Text(
                                              task.taskName,
                                              style: const TextStyle(
                                                fontSize: 8,
                                                color: Color(0xff475569),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildGanttLegend('Project Initiation', const Color(0xff10B981)),
                const SizedBox(width: 16),
                _buildGanttLegend('Civil Construction', const Color(0xff2563EB)),
                const SizedBox(width: 16),
                _buildGanttLegend('Selected', const Color(0xff0F172A)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildGanttLegend(String label, Color dotColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xff475569), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xffE2E8F0), width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: const Color(0xff2563EB),
        labelColor: const Color(0xff2563EB),
        unselectedLabelColor: const Color(0xff64748B),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Milestones'),
          Tab(text: 'Gantt Chart'),
          Tab(text: 'My Tasks'),
          Tab(text: 'Documents'),
        ],
      ),
    );
  }

  Widget _buildOverviewTabContent() {
    return Column(
      children: [
        _buildTaskSummaryCard(),
        const SizedBox(height: 12),
        _buildProjectProgressCard(),
        const SizedBox(height: 12),
        _buildProjectInformationCard(),
        const SizedBox(height: 12),
        _buildUpcomingMilestonesCard(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMilestonesTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xffE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.layers_outlined, size: 18, color: Color(0xff2563EB)),
                  SizedBox(width: 8),
                  Text('PROJECT MILESTONES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xff1E293B))),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Color(0xffF1F5F9), thickness: 1),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _milestones.length,
                separatorBuilder: (context, index) => const Divider(color: Color(0xffF8FAFC), height: 20),
                itemBuilder: (context, index) {
                  final milestone = _milestones[index];
                  bool isCompleted = milestone.status == "Completed";
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted ? const Color(0xffE8F8EC) : milestone.color.withValues(alpha: 0.1),
                          border: Border.all(color: milestone.color, width: 1),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, size: 12, color: Color(0xff10B981))
                              : Text(milestone.id, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: milestone.color)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(milestone.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xff0F172A))),
                            const SizedBox(height: 2),
                            Text(milestone.desc, style: const TextStyle(fontSize: 10, color: Color(0xff64748B))),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text('Start: ${milestone.startDate}', style: const TextStyle(fontSize: 9.5, color: Color(0xff475569))),
                                const SizedBox(width: 12),
                                Text('Target: ${milestone.targetDate}', style: const TextStyle(fontSize: 9.5, color: Color(0xff475569))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text('Assigned: ${milestone.assigned}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xff1E293B))),
                                const SizedBox(width: 12),
                                Text('Open: ${milestone.open}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xff1E293B))),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: milestone.progress / 100,
                                  strokeWidth: 2.5,
                                  backgroundColor: const Color(0xffF1F5F9),
                                  color: milestone.color,
                                ),
                                Text('${milestone.progress}%', style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: isCompleted ? const Color(0xffE8F8EC) : milestone.status == "In Progress" ? const Color(0xffEFF6FF) : const Color(0xffF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(milestone.status, style: TextStyle(color: milestone.color, fontSize: 8.5, fontWeight: FontWeight.w700)),
                          )
                        ],
                      )
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildTasksAssignedSection(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTasksAssignedSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.assignment_outlined, size: 18, color: Color(0xff2563EB)),
                  SizedBox(width: 8),
                  Text('TASKS ASSIGNED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xff1E293B))),
                ],
              ),
              InkWell(
                onTap: () {},
                child: Row(
                  children: const [
                    Text('View all', style: TextStyle(fontSize: 11, color: Color(0xff2563EB), fontWeight: FontWeight.w600)),
                    Icon(Icons.arrow_forward, size: 12, color: Color(0xff2563EB)),
                  ],
                ),
              )
            ],
          ),
          const Text('Milestone: Reinforcement Fixing', style: TextStyle(fontSize: 9.5, color: Color(0xff64748B))),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xffF1F5F9), thickness: 1),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tasks.length,
            separatorBuilder: (context, index) => const Divider(color: Color(0xffF8FAFC), height: 16),
            itemBuilder: (context, index) {
              final task = _tasks[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(task.code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xff2563EB))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: task.priorityColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(task.priority, style: TextStyle(color: task.priorityColor, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(task.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xff0F172A))),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('To: ${task.assignedTo}', style: const TextStyle(fontSize: 10.5, color: Color(0xff475569))),
                      Text('Due: ${task.dueDate}', style: const TextStyle(fontSize: 10.5, color: Color(0xff64748B))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: task.status == "In Progress" ? const Color(0xffEFF6FF) : const Color(0xffFFF7ED),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(task.status, style: TextStyle(color: task.statusColor, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: task.progress,
                            minHeight: 5,
                            backgroundColor: const Color(0xffF1F5F9),
                            color: const Color(0xff2563EB),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${(task.progress * 100).toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  )
                ],
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildEmptyStateTabContent() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text('Content Loading...', style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _buildProjectBannerCard() {
    // Project priority (hardcoded for now, can be passed from constructor)
    const String projectPriority = 'Atmost Critical';
    final Color priorityColor = getPriorityColor(projectPriority);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    const Text(
                      '50 TPD CBG Plant Construction',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Atirath Bio Energy Pvt. Ltd.\nNalgonda Plant',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xff64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Status - Plain text, no color
              const Text(
                'In Progress',
                style: TextStyle(
                  color: Color(0xff475569),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xffEDF2F7), thickness: 1, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTopMetaItem(
                'Start Date',
                '10-Apr-2025',
                Icons.calendar_today_outlined,
                iconColor: Colors.green,
              ),
              _buildTopMetaItem(
                'Target Date',
                '30-Sep-2025',
                Icons.event_outlined,
                iconColor: Colors.orange,
              ),
              _buildTopMetaItem(
                'Priority',
                projectPriority,
                Icons.flag_outlined,
                iconColor: priorityColor,
                textColor: priorityColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopMetaItem(
    String label,
    String value,
    IconData icon, {
    Color iconColor = Colors.blue,
    Color textColor = const Color(0xff1E293B),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xff64748B))),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTaskSummaryCard() {
    return _buildSectionCard(
      title: 'TASK SUMMARY',
      icon: Icons.assignment_outlined,
      iconColor: Colors.blue,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        children: [
          _buildTaskBlock('Tasks Assigned', '8', Icons.assignment_turned_in_outlined, Colors.green),
          _buildTaskBlock('In Progress', '5', Icons.play_circle_outline, Colors.blue),
          _buildTaskBlock('Open Tasks', '3', Icons.query_builder, Colors.orange),
          _buildTaskBlock('Completed', '0', Icons.check_circle_outline, Colors.red),
        ],
      ),
    );
  }

  Widget _buildTaskBlock(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xff0F172A))),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8.5, color: Color(0xff64748B), fontWeight: FontWeight.w500), maxLines: 1),
      ],
    );
  }

  Widget _buildProjectProgressCard() {
    return _buildSectionCard(
      title: 'PROJECT PROGRESS',
      icon: Icons.pie_chart_outline,
      iconColor: Colors.blue,
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 74,
                  height: 74,
                  child: CircularProgressIndicator(value: 0.65, strokeWidth: 8, backgroundColor: Colors.orange, color: Colors.green),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('65%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xff0F172A))),
                    Text('Completed', style: TextStyle(fontSize: 8, color: Color(0xff64748B))),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                _buildProgressLegend('Completed', '65%', Colors.green),
                _buildProgressLegend('In Progress', '20%', Colors.blue),
                _buildProgressLegend('Yet to Start', '15%', Colors.orange),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProgressLegend(String status, String percent, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(status, style: const TextStyle(fontSize: 11, color: Color(0xff475569))),
            ],
          ),
          Text(percent, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xff1E293B))),
        ],
      ),
    );
  }

  Widget _buildProjectInformationCard() {
    return _buildSectionCard(
      title: 'PROJECT INFORMATION',
      icon: Icons.info_outline,
      iconColor: Colors.blue,
      child: Column(
        children: [
          _buildRowDetail('Project Code', 'PRJ-001'),
          _buildRowDetail('Project Type', 'Construction'),
          _buildRowDetail('Location', 'Nalgonda, Telangana'),
          _buildRowDetail('Client', 'Atirath Bio Energy Pvt. Ltd.'),
          const SizedBox(height: 10),
          const Align(alignment: Alignment.centerLeft, child: Text('Description', style: TextStyle(fontSize: 11, color: Color(0xff64748B)))),
          const SizedBox(height: 4),
          const Text('50 TPD Compressed Biogas (CBG) Plant Construction Project.', style: TextStyle(fontSize: 11.5, color: Color(0xff1E293B), height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildUpcomingMilestonesCard() {
    return _buildSectionCard(
      title: 'UPCOMING MILESTONES',
      icon: Icons.flag_outlined,
      iconColor: Colors.blue,
      actionWidget: InkWell(
        onTap: () {},
        child: const Text('View all', style: TextStyle(fontSize: 11, color: Color(0xff2563EB), fontWeight: FontWeight.w600)),
      ),
      child: Column(
        children: [
          _buildMilestoneRow('PCC Work Completion', '02-Jun-2025'),
          _buildMilestoneRow('Reinforcement Fixing', '05-Jun-2025'),
          _buildMilestoneRow('Equipment Foundation', '20-Jun-2025'),
          _buildMilestoneRow('Installation & Erection', '15-Jul-2025', isLast: true),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow(String title, String date, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xffF1F5F9), width: 1))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 11.5, color: Color(0xff1E293B), fontWeight: FontWeight.w500))),
          Text(date, style: const TextStyle(fontSize: 11, color: Color(0xff64748B))),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Color iconColor, required Widget child, Widget? actionWidget}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xffE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: iconColor),
                  const SizedBox(width: 6),
                  Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xff1E293B), letterSpacing: 0.3)),
                ],
              ),
              if (actionWidget != null) actionWidget,
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Color(0xffF1F5F9), thickness: 1, height: 1)),
          child,
        ],
      ),
    );
  }

  Widget _buildRowDetail(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xff64748B)))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, color: const Color(0xff1E293B)))),
        ],
      ),
    );
  }  
}