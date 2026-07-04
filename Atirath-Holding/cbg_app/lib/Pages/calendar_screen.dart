import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/header.dart';
import 'main_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class CalendarTaskItem {
  final String title;
  final String projectCode;
  final String category;
  final String timeRange;
  final String priority;
  final Color priorityBgColor;
  final Color priorityTextColor;
  final Color themeColor;

  CalendarTaskItem({
    required this.title,
    required this.projectCode,
    required this.category,
    required this.timeRange,
    required this.priority,
    required this.priorityBgColor,
    required this.priorityTextColor,
    required this.themeColor,
  });
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime(2025, 5, 1);
  DateTime _selectedDate = DateTime(2025, 5, 29);
  String _selectedTab = 'Month'; // 'Month', 'Week', 'Day'
  String _selectedFilter = 'All'; // Filter state

  // Draggable Scrollable Controller to expand bottom panel on date clicks
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  // Mock events data matching the screenshot and adding a few extra for interactivity
  final Map<String, List<CalendarTaskItem>> _eventsMap = {
    '2025-05-29': [
      CalendarTaskItem(
        title: 'Daily Progress Report',
        projectCode: 'PRJ-001',
        category: 'Daily Reporting',
        timeRange: '09:00 AM - 10:00 AM',
        priority: 'Medium',
        priorityBgColor: const Color(0xFFE8F5E9),
        priorityTextColor: const Color(0xFF2E7D32),
        themeColor: const Color(0xFF2563EB), // Blue
      ),
      CalendarTaskItem(
        title: 'Material Inspection',
        projectCode: 'PRJ-005',
        category: 'Quality Check',
        timeRange: '02:00 PM - 03:00 PM',
        priority: 'High',
        priorityBgColor: const Color(0xFFFFEBEE),
        priorityTextColor: const Color(0xFFC62828),
        themeColor: const Color(0xFF8B5CF6), // Purple
      ),
      CalendarTaskItem(
        title: 'Site Meeting',
        projectCode: 'PRJ-001',
        category: 'Project Meeting',
        timeRange: '04:00 PM - 05:00 PM',
        priority: 'Medium',
        priorityBgColor: const Color(0xFFFFF3E0),
        priorityTextColor: const Color(0xFFEF6C00),
        themeColor: const Color(0xFF10B981), // Green
      ),
    ],
    '2025-05-01': [
      CalendarTaskItem(
        title: 'Milestone Kickoff',
        projectCode: 'PRJ-001',
        category: 'Kickoff',
        timeRange: '10:00 AM - 11:30 AM',
        priority: 'Medium',
        priorityBgColor: const Color(0xFFE8F5E9),
        priorityTextColor: const Color(0xFF2E7D32),
        themeColor: const Color(0xFF10B981),
      ),
    ],
    '2025-05-05': [
      CalendarTaskItem(
        title: 'Safety Training',
        projectCode: 'PRJ-003',
        category: 'HSE',
        timeRange: '09:00 AM - 11:00 AM',
        priority: 'High',
        priorityBgColor: const Color(0xFFFFEBEE),
        priorityTextColor: const Color(0xFFC62828),
        themeColor: const Color(0xFFEF4444),
      ),
    ],
    '2025-05-07': [
      CalendarTaskItem(
        title: 'Design Team Sync',
        projectCode: 'PRJ-002',
        category: 'Sync',
        timeRange: '03:00 PM - 04:00 PM',
        priority: 'High',
        priorityBgColor: const Color(0xFFFFEBEE),
        priorityTextColor: const Color(0xFFC62828),
        themeColor: const Color(0xFF8B5CF6),
      ),
    ],
    '2025-05-10': [
      CalendarTaskItem(
        title: 'Procurement Alignment',
        projectCode: 'PRJ-003',
        category: 'Logistics',
        timeRange: '10:00 AM - 11:30 AM',
        priority: 'Medium',
        priorityBgColor: const Color(0xFFFFF3E0),
        priorityTextColor: const Color(0xFFEF6C00),
        themeColor: const Color(0xFFF59E0B),
      ),
    ],
    '2025-05-13': [
      CalendarTaskItem(
        title: 'Site Safety Audit',
        projectCode: 'PRJ-001',
        category: 'HSE Audit',
        timeRange: '09:00 AM - 11:00 AM',
        priority: 'Medium',
        priorityBgColor: const Color(0xFFE8F5E9),
        priorityTextColor: const Color(0xFF2E7D32),
        themeColor: const Color(0xFF3B82F6),
      ),
    ],
    '2025-05-20': [
      CalendarTaskItem(
        title: 'Project Status Review',
        projectCode: 'PRJ-004',
        category: 'Review',
        timeRange: '02:00 PM - 03:30 PM',
        priority: 'Medium',
        priorityBgColor: const Color(0xFFFFF3E0),
        priorityTextColor: const Color(0xFFEF6C00),
        themeColor: const Color(0xFF10B981),
      ),
    ],
    '2025-05-22': [
      CalendarTaskItem(
        title: 'Drawing Sign-off',
        projectCode: 'PRJ-004',
        category: 'Design Approval',
        timeRange: '03:00 PM - 04:30 PM',
        priority: 'High',
        priorityBgColor: const Color(0xFFFFEBEE),
        priorityTextColor: const Color(0xFFC62828),
        themeColor: const Color(0xFFEF4444),
      ),
    ],
    '2025-05-26': [
      CalendarTaskItem(
        title: 'Milestone 2 Review',
        projectCode: 'PRJ-005',
        category: 'Milestone Review',
        timeRange: '01:00 PM - 02:00 PM',
        priority: 'High',
        priorityBgColor: const Color(0xFFFFEBEE),
        priorityTextColor: const Color(0xFFC62828),
        themeColor: const Color(0xFF8B5CF6),
      ),
    ],
    '2025-05-28': [
      CalendarTaskItem(
        title: 'Pre-Pour QC Inspection',
        projectCode: 'PRJ-002',
        category: 'Civil QC',
        timeRange: '09:00 AM - 10:30 AM',
        priority: 'Medium',
        priorityBgColor: const Color(0xFFFFF3E0),
        priorityTextColor: const Color(0xFFEF6C00),
        themeColor: const Color(0xFFF59E0B),
      ),
    ],
    '2025-05-31': [
      CalendarTaskItem(
        title: 'Monthly Safety Audit',
        projectCode: 'PRJ-001',
        category: 'Safety Audit',
        timeRange: '10:00 AM - 12:00 PM',
        priority: 'Medium',
        priorityBgColor: const Color(0xFFE8F5E9),
        priorityTextColor: const Color(0xFF2E7D32),
        themeColor: const Color(0xFF10B981),
      ),
    ],
  };

  void _handleNotification() {
    Navigator.pushNamed(context, '/notifications');
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  // Returns 42 days for the calendar grid
  List<DateTime> _generateGridDates(DateTime monthDate) {
    final firstDay = DateTime(monthDate.year, monthDate.month, 1);
    final padDays = firstDay.weekday == 7 ? 0 : firstDay.weekday;
    final gridStart = firstDay.subtract(Duration(days: padDays));
    return List.generate(42, (index) => gridStart.add(Duration(days: index)));
  }

  // Get dots for a specific day
  List<Color> _getDayDotColors(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final tasks = _eventsMap[key];
    if (tasks == null || tasks.isEmpty) return [];
    
    // Return theme colors for up to 3 events per day
    return tasks.map((t) => t.themeColor).toSet().toList();
  }

  // Animates sheet to expanded view when clicking on a date
  void _expandBottomSheet() {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.45,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Show a filter options dialog/bottom-sheet
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                        'Filter Events',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(
                    'Priority Level',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: ['All', 'High', 'Medium'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (val) {
                          setModalState(() {
                            _selectedFilter = filter;
                          });
                          setState(() {});
                        },
                        selectedColor: const Color(0xFF2563EB),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Apply Filters',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper to format Date
  String _formatSelectedDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final gridDates = _generateGridDates(_currentMonth);
    final selectedKey = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    
    // Filter events
    List<CalendarTaskItem> activeTasks = _eventsMap[selectedKey] ?? [];
    if (_selectedFilter != 'All') {
      activeTasks = activeTasks.where((t) => t.priority == _selectedFilter).toList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomHeader(
        title: 'Calendar',
        automaticallyImplyLeading: false,
        onNotificationTap: _handleNotification,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Background Content (Scrollable Calendar View)
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120), // Bottom padding so calendar grid isn't blocked when sheet is collapsed
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Calendar Title and Filter Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Calendar',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'View and manage your schedule, tasks\nand project deadlines.',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: const Color(0xFF64748B),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: _showFilterBottomSheet,
                            icon: const Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFF1E293B)),
                            label: Text(
                              'Filter',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1E293B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Month Navigation Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _previousMonth,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF475569)),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                DateFormat('MMMM yyyy').format(_currentMonth),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF0F172A)),
                            ],
                          ),
                          GestureDetector(
                            onTap: _nextMonth,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // View Selector Tabs (Month, Week, Day)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: ['Month', 'Week', 'Day'].map((tab) {
                            final isSelected = _selectedTab == tab;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTab = tab),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    tab,
                                    style: GoogleFonts.inter(
                                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tab Views
                      if (_selectedTab == 'Month') ...[
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.95,
                          ),
                          itemCount: 49,
                          itemBuilder: (context, index) {
                            if (index < 7) {
                              final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                              return Center(
                                child: Text(
                                  weekdays[index],
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }
                            
                            final date = gridDates[index - 7];
                            final isSelected = date.year == _selectedDate.year &&
                                               date.month == _selectedDate.month &&
                                               date.day == _selectedDate.day;
                            final isCurrentMonth = date.month == _currentMonth.month;
                            final dotColors = _getDayDotColors(date);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = date;
                                  _currentMonth = DateTime(date.year, date.month, 1);
                                });
                                _expandBottomSheet();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${date.day}',
                                      style: GoogleFonts.inter(
                                        color: isSelected
                                            ? Colors.white
                                            : (isCurrentMonth ? const Color(0xFF1E293B) : const Color(0xFF94A3B8)),
                                        fontSize: 13.5,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                    if (dotColors.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: dotColors.map((color) {
                                          return Container(
                                            width: 4.5,
                                            height: 4.5,
                                            margin: const EdgeInsets.symmetric(horizontal: 1),
                                            decoration: BoxDecoration(
                                              color: isSelected ? Colors.white : color,
                                              shape: BoxShape.circle,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ] else if (_selectedTab == 'Week') ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weekly Timeline',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(7, (i) {
                                  final dayDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday - i));
                                  final isSelected = dayDate.day == _selectedDate.day;
                                  return Column(
                                    children: [
                                      Text(
                                        ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() => _selectedDate = dayDate);
                                          _expandBottomSheet();
                                        },
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${dayDate.day}',
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hourly Agenda',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 12),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: 4,
                                separatorBuilder: (context, idx) => const Divider(height: 20),
                                itemBuilder: (context, idx) {
                                  final hours = ['09:00 AM', '11:00 AM', '02:00 PM', '04:00 PM'];
                                  final agendas = [
                                    'Daily Progress Report',
                                    'Free Slot',
                                    'Material Inspection Meeting',
                                    'Site Review Meeting'
                                  ];
                                  return Row(
                                    children: [
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          hours[idx],
                                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: agendas[idx] == 'Free Slot' ? Colors.transparent : const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(6),
                                            border: agendas[idx] == 'Free Slot'
                                                ? Border.all(color: Colors.grey.shade300, style: BorderStyle.solid)
                                                : Border.all(color: const Color(0xFFBFDBFE)),
                                          ),
                                          child: Text(
                                            agendas[idx],
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: agendas[idx] == 'Free Slot' ? Colors.grey : const Color(0xFF1E3A8A),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            // 2. Foreground Content (Draggable Scrollable Bottom Panel for Events & Tasks)
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.15,
              minChildSize: 0.08,
              maxChildSize: 0.75,
              snap: true,
              snapSizes: const [0.08, 0.45, 0.75],
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: 3 + (activeTasks.isEmpty ? 1 : activeTasks.length),
                    itemBuilder: (BuildContext context, int index) {
                      // Item 0: Drag Handle Indicator
                      if (index == 0) {
                        return Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(top: 10, bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }

                      // Item 1: Date Header Row
                      if (index == 1) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, color: Color(0xFF2563EB), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatSelectedDate(_selectedDate),
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  if (MainScreen.navigatorKey.currentState != null) {
                                    MainScreen.navigatorKey.currentState!.changeTab(2); // Go to tasks tab
                                  }
                                },
                                child: Text(
                                  '${activeTasks.length} Events & Tasks',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF2563EB),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Render Tasks or Empty State
                      if (activeTasks.isEmpty) {
                        if (index == 2) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            child: Text(
                              'No events or tasks scheduled for this day.',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          );
                        }
                      } else {
                        if (index >= 2 && index < 2 + activeTasks.length) {
                          final item = activeTasks[index - 2];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      decoration: BoxDecoration(
                                        color: item.themeColor,
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color: item.themeColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    item.title,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: const Color(0xFF1E293B),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${item.projectCode}  •  ${item.category}',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: const Color(0xFF64748B),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.access_time_outlined, size: 13, color: Color(0xFF94A3B8)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  item.timeRange,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color: const Color(0xFF64748B),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: item.priorityBgColor,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.priority,
                                          style: TextStyle(
                                            color: item.priorityTextColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      }

                      // Last Item: View all tasks link
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: () {
                              if (MainScreen.navigatorKey.currentState != null) {
                                MainScreen.navigatorKey.currentState!.changeTab(2); // Go to tasks tab
                              }
                            },
                            icon: Text(
                              'View all tasks',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: const Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            label: const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF2563EB)),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}