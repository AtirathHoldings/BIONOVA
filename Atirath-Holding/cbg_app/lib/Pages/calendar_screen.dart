import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/header.dart';
import 'main_screen.dart';
import '../services/api_service.dart';
import '../models/task_item.dart';
import 'task_details_screen.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    if (text.length > 8) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class CalendarTaskItem {
  final String id;
  final String title;
  final String projectCode;
  final String category;
  final String timeRange;
  final String priority;
  final Color priorityBgColor;
  final Color priorityTextColor;
  final Color themeColor;
  final String type;
  final Map<String, dynamic> rawItem;

  CalendarTaskItem({
    required this.id,
    required this.title,
    required this.projectCode,
    required this.category,
    required this.timeRange,
    required this.priority,
    required this.priorityBgColor,
    required this.priorityTextColor,
    required this.themeColor,
    required this.type,
    required this.rawItem,
  });
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  String _selectedTab = 'Month'; // 'Month', 'Week', 'Day'
  String _selectedFilter = 'All'; // Filter state
  bool _isLoading = false;
  String? _error;
  List<TaskItem> _allTasks = [];

  // Draggable Scrollable Controller to expand bottom panel on date clicks
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  final Map<String, List<CalendarTaskItem>> _eventsMap = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDate = now;
    _fetchCalendarData();
  }

  Future<void> _fetchCalendarData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final String refDateStr = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-01';
      
      final results = await Future.wait([
        ApiService.getCalendarFeed(
          viewType: 'month',
          date: refDateStr,
        ),
        ApiService.getLiveTasks(),
        ApiService.getIndividualTasks(),
        ApiService.getCurrentEmployeeId(),
      ]);

      final List<dynamic> feed = results[0] as List<dynamic>;
      final liveTasks = results[1] as List<TaskItem>;
      final rawIndividualTasks = results[2] as List<dynamic>;
      final currentEmpId = results[3] as int?;

      final individualTasks = rawIndividualTasks
          .whereType<Map<String, dynamic>>()
          .map((json) => TaskItem.fromIndividualTask(json, currentEmpId?.toString()))
          .toList();

      final allTasks = [...liveTasks, ...individualTasks];
      final Map<String, List<CalendarTaskItem>> newEventsMap = {};

      for (var item in feed) {
        final String dateRaw = item['date']?.toString() ?? '';
        if (dateRaw.isEmpty) continue;

        String dateKey = dateRaw;
        if (dateRaw.contains('T')) {
          dateKey = dateRaw.split('T')[0];
        }

        final String type = item['type']?.toString() ?? 'TASK';
        final String title = item['title']?.toString() ?? '';
        final String code = item['code']?.toString() ?? '';
        final String desc = item['description']?.toString() ?? '';
        final String time = item['time']?.toString() ?? 'All Day';
        final String status = item['status']?.toString() ?? 'OPEN';

        final String eventId = item['id']?.toString() ?? item['taskId']?.toString() ?? item['empTaskId']?.toString() ?? '';

        String priority = 'Medium';
        Color priorityBg = const Color(0xFFFFF3E0);
        Color priorityText = const Color(0xFFEF6C00);
        Color themeColor = const Color(0xFF10B981);

        if (type == 'HOLIDAY') {
          priority = 'Low';
          priorityBg = const Color(0xFFEFF6FF);
          priorityText = const Color(0xFF1E40AF);
          themeColor = const Color(0xFF3B82F6);
        } else if (type == 'MILESTONE') {
          priority = 'High';
          priorityBg = const Color(0xFFF3E5F5);
          priorityText = const Color(0xFF6A1B9A);
          themeColor = const Color(0xFF8B5CF6);
        } else {
          if (status == 'HIGH' || status == 'COMPLETED') {
            priority = 'High';
            priorityBg = const Color(0xFFFFEBEE);
            priorityText = const Color(0xFFC62828);
            themeColor = const Color(0xFFEF4444);
          } else if (status == 'WIP' || status == 'UNDER_REVIEW') {
            priority = 'Medium';
            priorityBg = const Color(0xFFFFF3E0);
            priorityText = const Color(0xFFEF6C00);
            themeColor = const Color(0xFFF59E0B);
          } else {
            priority = 'Low';
            priorityBg = const Color(0xFFE8F5E9);
            priorityText = const Color(0xFF2E7D32);
            themeColor = const Color(0xFF10B981);
          }
        }

        final eventItem = CalendarTaskItem(
          id: eventId,
          title: title,
          projectCode: code.isNotEmpty ? code : (type == 'HOLIDAY' ? 'HOLIDAY' : 'N/A'),
          category: type,
          timeRange: time.isNotEmpty ? time : 'All Day',
          priority: priority,
          priorityBgColor: priorityBg,
          priorityTextColor: priorityText,
          themeColor: themeColor,
          type: type,
          rawItem: item,
        );

        if (!newEventsMap.containsKey(dateKey)) {
          newEventsMap[dateKey] = [];
        }
        newEventsMap[dateKey]!.add(eventItem);
      }

      if (mounted) {
        setState(() {
          _eventsMap.clear();
          _eventsMap.addAll(newEventsMap);
          _allTasks = allTasks;
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

  void _handleNotification() {
    Navigator.pushNamed(context, '/notifications');
  }

  void _navigateToTaskDetails(CalendarTaskItem calendarItem) async {
    if (calendarItem.type != 'TASK' && calendarItem.category != 'TASK') {
      return;
    }

    TaskItem? matchedTask;
    final String cId = calendarItem.id;
    if (cId.isNotEmpty) {
      for (final t in _allTasks) {
        if (t.id == cId || t.drftTaskId == cId) {
          matchedTask = t;
          break;
        }
      }
    }

    if (matchedTask == null) {
      final String cleanTitle = calendarItem.title.trim().toLowerCase();
      for (final t in _allTasks) {
        if (t.title.trim().toLowerCase() == cleanTitle) {
          matchedTask = t;
          break;
        }
      }
    }

    if (matchedTask != null) {
      if (matchedTask.isIndividualTask) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailsScreen(task: matchedTask!, isIndividualTask: true),
          ),
        );
      } else {
        await Navigator.pushNamed(
          context,
          '/task-details',
          arguments: matchedTask,
        );
      }
      _fetchCalendarData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task details not found for "${calendarItem.title}"'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _previousMonth() {
    setState(() {
      if (_selectedTab == 'Week') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
        _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      } else if (_selectedTab == 'Day') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
        _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      } else {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
        final int targetDay = _selectedDate.day.clamp(1, DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day);
        _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, targetDay);
      }
    });
    _fetchCalendarData();
  }

  void _nextMonth() {
    setState(() {
      if (_selectedTab == 'Week') {
        _selectedDate = _selectedDate.add(const Duration(days: 7));
        _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      } else if (_selectedTab == 'Day') {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
        _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      } else {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
        final int targetDay = _selectedDate.day.clamp(1, DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day);
        _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, targetDay);
      }
    });
    _fetchCalendarData();
  }

  Future<void> _selectYearMonth(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final dateController = TextEditingController(
          text: DateFormat('dd/MM/yyyy').format(_selectedDate),
        );

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Go to Date',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Enter Date (DD/MM/YYYY)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: dateController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  DateInputFormatter(),
                ],
                decoration: InputDecoration(
                  hintText: 'DD/MM/YYYY',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF2563EB)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit_calendar_outlined, color: Color(0xFF2563EB)),
                    tooltip: 'Pick Date Visual',
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialEntryMode: DatePickerEntryMode.calendarOnly,
                      );
                      if (picked != null) {
                        dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                      }
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    final text = dateController.text.trim();
                    try {
                      final parts = text.split('/');
                      if (parts.length == 3) {
                        final day = int.parse(parts[0]);
                        final month = int.parse(parts[1]);
                        final year = int.parse(parts[2]);
                        final picked = DateTime(year, month, day);
                        setState(() {
                          _selectedDate = picked;
                          _currentMonth = DateTime(picked.year, picked.month, 1);
                        });
                        _fetchCalendarData();
                        Navigator.pop(context);
                        return;
                      }
                    } catch (_) {}
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid date in DD/MM/YYYY format'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Apply Date',
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
  }

  String get _navigationHeaderTitle {
    if (_selectedTab == 'Week') {
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      if (startOfWeek.month == endOfWeek.month) {
        return '${DateFormat('d').format(startOfWeek)} - ${DateFormat('d MMMM yyyy').format(endOfWeek)}';
      } else {
        return '${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM yyyy').format(endOfWeek)}';
      }
    } else if (_selectedTab == 'Day') {
      return DateFormat('d MMMM yyyy').format(_selectedDate);
    }
    return DateFormat('MMMM yyyy').format(_currentMonth);
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

  Widget _buildTaskItem(CalendarTaskItem item) {
    final bool isTask = item.type == 'TASK' || item.category == 'TASK';
    TaskItem? matchedTask;
    if (isTask) {
      final String cId = item.id;
      if (cId.isNotEmpty) {
        for (final t in _allTasks) {
          if (t.id == cId || t.drftTaskId == cId) {
            matchedTask = t;
            break;
          }
        }
      }
      if (matchedTask == null) {
        final String cleanTitle = item.title.trim().toLowerCase();
        for (final t in _allTasks) {
          if (t.title.trim().toLowerCase() == cleanTitle) {
            matchedTask = t;
            break;
          }
        }
      }
    }

    String subtitleText = '${item.projectCode}  •  ${item.category}';
    if (isTask) {
      if (matchedTask != null) {
        if (matchedTask.isIndividualTask) {
          subtitleText = 'Assignment';
        } else if (matchedTask.subtitle.isNotEmpty) {
          subtitleText = matchedTask.subtitle;
        }
      } else {
        subtitleText = 'Assignment';
      }
    }

    final bool showTimeRange = item.timeRange.toLowerCase().trim() != 'all day';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: InkWell(
        onTap: isTask ? () => _navigateToTaskDetails(item) : null,
        borderRadius: BorderRadius.circular(12),
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
                          subtitleText,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        if (showTimeRange) ...[
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
      ),
    );
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'View and manage your schedule, tasks and project deadlines.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: const Color(0xFF64748B),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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
                              GestureDetector(
                                onTap: () => _selectYearMonth(context),
                                child: Row(
                                  children: [
                                    Text(
                                      _navigationHeaderTitle,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF0F172A)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  final now = DateTime.now();
                                  setState(() {
                                    _selectedDate = now;
                                    _currentMonth = DateTime(now.year, now.month, 1);
                                  });
                                  _fetchCalendarData();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    'Today',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ),
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
                      const SizedBox(height: 8),
                      if (_isLoading)
                        const LinearProgressIndicator(minHeight: 2, color: Color(0xFF2563EB), backgroundColor: Color(0xFFF1F5F9))
                      else
                        const SizedBox(height: 2),
                      const SizedBox(height: 8),

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
                            final now = DateTime.now();
                            final isToday = date.year == now.year &&
                                            date.month == now.month &&
                                            date.day == now.day;
                            final isCurrentMonth = date.month == _currentMonth.month;
                            final dotColors = _getDayDotColors(date);

                            BoxDecoration cellDecoration;
                            Color textColor;

                            if (isSelected && isToday) {
                              // TODAY IS SELECTED -> SOLID ORANGE CIRCLE WITH WHITE TEXT
                              cellDecoration = const BoxDecoration(
                                color: Color(0xFFEA580C),
                                shape: BoxShape.circle,
                              );
                              textColor = Colors.white;
                            } else if (isSelected && !isToday) {
                              // OTHER DATE IS SELECTED -> SOLID BLUE CIRCLE WITH WHITE TEXT
                              cellDecoration = const BoxDecoration(
                                color: Color(0xFF2563EB),
                                shape: BoxShape.circle,
                              );
                              textColor = Colors.white;
                            } else if (!isSelected && isToday) {
                              // TODAY IS NOT SELECTED -> ORANGE BORDER RING & SOFT AMBER TINT
                              cellDecoration = BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFEA580C), width: 1.8),
                              );
                              textColor = const Color(0xFFEA580C);
                            } else {
                              // NORMAL UNSELECTED DATE
                              cellDecoration = const BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle,
                              );
                              textColor = isCurrentMonth ? const Color(0xFF1E293B) : const Color(0xFF94A3B8);
                            }

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = date;
                                  _currentMonth = DateTime(date.year, date.month, 1);
                                });
                                _expandBottomSheet();
                              },
                              child: Container(
                                decoration: cellDecoration,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${date.day}',
                                      style: GoogleFonts.inter(
                                        color: textColor,
                                        fontSize: 13.5,
                                        fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.w500,
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
                                  final dayDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1)).add(Duration(days: i));
                                  final isSelected = dayDate.day == _selectedDate.day && dayDate.month == _selectedDate.month && dayDate.year == _selectedDate.year;
                                  final now = DateTime.now();
                                  final isToday = dayDate.day == now.day && dayDate.month == now.month && dayDate.year == now.year;
                                  final dotColors = _getDayDotColors(dayDate);
                                  return Column(
                                    children: [
                                      Text(
                                        ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                                        style: TextStyle(color: isToday ? const Color(0xFFD97706) : Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedDate = dayDate;
                                            if (dayDate.month != _currentMonth.month || dayDate.year != _currentMonth.year) {
                                              _currentMonth = DateTime(dayDate.year, dayDate.month, 1);
                                              _fetchCalendarData();
                                            }
                                          });
                                          _expandBottomSheet();
                                        },
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: (isSelected && isToday)
                                                    ? const Color(0xFFEA580C)
                                                    : ((isSelected && !isToday)
                                                        ? const Color(0xFF2563EB)
                                                        : (isToday ? const Color(0xFFFFF7ED) : Colors.transparent)),
                                                shape: BoxShape.circle,
                                                border: (!isSelected && isToday)
                                                    ? Border.all(color: const Color(0xFFEA580C), width: 1.8)
                                                    : null,
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${dayDate.day}',
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : (isToday ? const Color(0xFFEA580C) : const Color(0xFF1E293B)),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
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
                                                      color: color,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ] else ...[
                                              const SizedBox(height: 7.5),
                                            ],
                                          ],
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
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 12.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('d MMMM yyyy').format(_selectedDate),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFDBEAFE)),
                                ),
                                child: Text(
                                  '${activeTasks.length} ${activeTasks.length == 1 ? 'Task' : 'Tasks'}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (activeTasks.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            child: Text(
                              'No events or tasks scheduled for this day.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activeTasks.length,
                            itemBuilder: (context, index) {
                              return _buildTaskItem(activeTasks[index]);
                            },
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            // 2. Foreground Content (Draggable Scrollable Bottom Panel for Events & Tasks)
            if (_selectedTab != 'Day')
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              const SizedBox(height: 4),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
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
                          return _buildTaskItem(item);
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