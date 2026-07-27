import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../services/api_service.dart';
import '../models/employee_option.dart';
import '../models/task_item.dart';
import 'individual_task_screen.dart';
import 'task_details_screen.dart';
import 'main_screen.dart';
// ============================================================
// INDIVIDUAL TASK LIST SCREEN
// ============================================================

class IndividualTaskListScreen extends StatefulWidget {
  const IndividualTaskListScreen({super.key});

  @override
  State<IndividualTaskListScreen> createState() => _IndividualTaskListScreenState();
}

class _IndividualTaskListScreenState extends State<IndividualTaskListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _unreadNotificationCount = 0;
  bool _isLoading = false;
  int? _currentEmpId;
  String _searchQuery = '';
  DateTime? _filterFromDate;
  DateTime? _filterToDate;
  int? _filterEmployeeId;

  List<dynamic> _myAssignments = [];
  List<dynamic> _assignedToMe = [];
  List<EmployeeOption> _employees = [];
  Map<String, EmployeeOption> _employeeMap = {};
  String? _userPhotoUrl;
  String _userInitials = 'EM';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _loadData();
    _fetchNotificationCount();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        setState(() {
          _tabController.index = args;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final notifications = await ApiService.getUnreadNotifications();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = notifications.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final empId = await ApiService.getCurrentEmployeeId();
      _currentEmpId = empId;

      final empList = await ApiService.getEmployees();
      _employees = empList
          .map<EmployeeOption>((emp) => EmployeeOption.fromJson(emp))
          .toList();

      final Map<String, EmployeeOption> tempMap = {};
      for (final emp in empList) {
        final opt = EmployeeOption.fromJson(emp);
        if (opt.id != null) {
          tempMap[opt.id!] = opt;
        }
      }

      String? userPhotoUrl;
      String userInitials = 'EM';
      String userName = '';

      if (empId != null) {
        final currentEmpOpt = tempMap[empId.toString()];
        if (currentEmpOpt != null) {
          userName = currentEmpOpt.name;
          userPhotoUrl = currentEmpOpt.profileImageUrl;
          userInitials = currentEmpOpt.initials;
        }
      }

      if (empId != null) {
        // 1) Fetch task sources
        final assignedByMe = await ApiService.getIndividualTasksAssignedBy(empId);
        final assignedToMe = await ApiService.getIndividualTasksAssignedTo(empId);
        final allIndivTasks = await ApiService.getIndividualTasks();

        // 2) Fetch process-config rows where current employee is reviewer/approver
        final processConfigs =
            await ApiService.getIndividualTaskProcessConfigsForEmployee(empId);

        final reviewerTaskIds = <String>{};
        final approverTaskIds = <String>{};

        for (final row in processConfigs) {
          final taskId = (row['empTaskId'] ?? row['taskId'])?.toString();
          if (taskId == null || taskId.isEmpty) continue;

          final stepType = (row['stepType'] ?? '').toString().toUpperCase();
          final stepLabel = (row['stepLabel'] ?? '').toString().toUpperCase();

          final isReviewer =
              stepType == 'REVIEWER' || stepLabel == 'REVIEWER';

          final isApprover =
              stepType == 'CHECKER' ||
              stepType == 'APPROVER' ||
              stepLabel == 'APPROVER';

          if (isReviewer) {
            reviewerTaskIds.add(taskId);
          }
          if (isApprover) {
            approverTaskIds.add(taskId);
          }
        }

        // 3) Merge all tasks into unique map
        final combined = [...allIndivTasks, ...assignedToMe, ...assignedByMe];
        final uniqueTasks = <String, Map<String, dynamic>>{};

        for (final raw in combined) {
          final t = Map<String, dynamic>.from(raw as Map);
          final id = (t['id'] ?? t['empTaskId'])?.toString();
          if (id != null && id.isNotEmpty) {
            uniqueTasks[id] = t;
          }
        }

        // 4) Build tabs
        final myAssignments = <Map<String, dynamic>>[];
        final assignedByMeOnly = <Map<String, dynamic>>[];

        for (final t in uniqueTasks.values) {
          final taskId = (t['id'] ?? t['empTaskId'])?.toString() ?? '';

          final isAssignedByMe =
              (t['assignedBy'] ?? t['assigned_by'])?.toString() == _currentEmpId.toString();

          final isAssignedToMe =
              (t['assignedTo'] ?? t['empId'])?.toString() ==
                  _currentEmpId.toString();

          final noteTxt = (t['noteTxt'] ?? t['note_txt'] ?? '').toString();
          final isTeamMember = noteTxt
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .contains(_currentEmpId.toString());

          final isReviewer = (t['reviewer']?.toString() == _currentEmpId.toString()) || reviewerTaskIds.contains(taskId);
          final isApprover = (t['approver']?.toString() == _currentEmpId.toString()) || approverTaskIds.contains(taskId);

          // TAB 1: My Assignments
          if (isAssignedToMe || isTeamMember || isReviewer || isApprover) {
            myAssignments.add(t);
          }

          // TAB 2: Assigned by Me
          if (isAssignedByMe) {
            assignedByMeOnly.add(t);
          }
        }

        if (mounted) {
          setState(() {
            _assignedToMe = myAssignments;   // Tab 1 -> My Assignments
            _myAssignments = assignedByMeOnly; // Tab 2 -> Assigned by Me
            _employeeMap = tempMap;
            _userPhotoUrl = userPhotoUrl;
            _userInitials = userInitials;
            _userName = userName;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading individual tasks: ');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final fromDateStr = _filterFromDate != null 
                ? DateFormat('dd-MMM-yyyy').format(_filterFromDate!) 
                : 'Select From Date';
            final toDateStr = _filterToDate != null 
                ? DateFormat('dd-MMM-yyyy').format(_filterToDate!) 
                : 'Select To Date';

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Tasks',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Due Date Range',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _filterFromDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setModalState(() {
                                _filterFromDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  fromDateStr,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: _filterFromDate != null 
                                        ? const Color(0xFF1E293B) 
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                                const Icon(Icons.calendar_today, size: 14, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _filterToDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setModalState(() {
                                _filterToDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  toDateStr,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: _filterToDate != null 
                                        ? const Color(0xFF1E293B) 
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                                const Icon(Icons.calendar_today, size: 14, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(
                    _tabController.index == 0 ? 'Assigned By Employee' : 'Assigned To Employee',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Builder(
                    builder: (context) {
                      EmployeeOption? selectedEmp;
                      if (_filterEmployeeId != null) {
                        for (final emp in _employees) {
                          if (emp.id?.toString() == _filterEmployeeId.toString()) {
                            selectedEmp = emp;
                            break;
                          }
                        }
                      }
                      return SearchableDropdown<EmployeeOption>(
                        items: _employees,
                        selectedItem: selectedEmp,
                        onChanged: (val) {
                          setModalState(() {
                            _filterEmployeeId = val != null ? int.tryParse(val.id ?? '') : null;
                          });
                        },
                        label: '',
                        hint: 'Select Employee',
                        isRequired: false,
                        itemLabel: (item) => item.name,
                        itemSubtitle: (item) => item.designation,
                      );
                    }
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _filterFromDate = null;
                              _filterToDate = null;
                              _filterEmployeeId = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Reset All',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Apply Filters',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBreadcrumbs() {
    return TextButton.icon(
      onPressed: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, '/main');
        }
      },
      icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF1E293B)),
      label: Text(
        'Back',
        style: GoogleFonts.inter(
          color: const Color(0xFF1E293B),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  void _showStatusNote(BuildContext context, TaskItem task) {
    String noteMessage = '';
    final currentStatus = task.status;
    if (task.tag == 'Critical' || task.priority == 'At Most Critical') {
      noteMessage = 'It will go to almost critical';
    } else if (task.tag == 'High') {
      noteMessage = 'This task has high priority and needs immediate action.';
    } else if (task.isCompleted) {
      noteMessage = 'This task is successfully completed.';
    } else if (task.timeIconColor == const Color(0xFFEF4444)) {
      noteMessage = 'This task is Overdue.';
    } else {
      noteMessage = 'Task is currently ${currentStatus.toLowerCase()}.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(task.icon, color: task.iconColor, size: 22),
            const SizedBox(width: 8),
            Text('${task.tag} Note', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(noteMessage, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple))),
        ],
      ),
    );
  }

  // ============================================================
  // EXACT SECOND IMAGE STYLE TASK CARD WITH VIEW BUTTON
  // ============================================================
  Future<void> _openTask(Map<String, dynamic> task, bool isMyAssignment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailsScreen(
          task: TaskItem.fromIndividualTask(task, _currentEmpId?.toString()),
          isIndividualTask: true,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Widget _buildTaskCard(dynamic taskItem, {required bool isMyAssignment}) {
    final taskMap = taskItem as Map<String, dynamic>;
    final parsedTask = TaskItem.fromIndividualTask(taskMap, _currentEmpId?.toString());
    
    return _buildTaskTileRow(
      task: parsedTask,
      status: parsedTask.status,
      onInfoTap: () => _showStatusNote(context, parsedTask),
      onTap: () => _openTask(taskMap, isMyAssignment),
    );
  }

  Widget _buildTaskTileRow({
    required TaskItem task,
    required String status,
    required VoidCallback onInfoTap,
    required VoidCallback onTap,
  }) {
    final String descriptionText = (task.description != null && task.description!.trim().isNotEmpty)
        ? task.description!.trim()
        : 'No description';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0), 
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            // Middle section - Task details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 15.5, 
                      color: Color(0xFF1E293B), 
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 6),
                  
                  Text(
                    descriptionText,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Days left widget
                  _buildDaysLeftWidget(task, status),
                ],
              ),
            ),
            
            const SizedBox(width: 14),
            
            // Right side - Status, arrow, tag
            Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Progress Status badge
                GestureDetector(
                  onTap: onInfoTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: task.progressStatusBg,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      task.progressStatusText,
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.w700, 
                        color: task.progressStatusColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Process and Time Icons Row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (task.processIcon != null) ...[
                      Icon(task.processIcon, color: task.processIconColor, size: 18),
                      const SizedBox(width: 6),
                    ],
                    Icon(task.timeIcon, color: task.timeIconColor, size: 18),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Priority Tag badge with dot
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                  decoration: BoxDecoration(
                    color: task.tagBg, 
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: task.tagColor.withValues(alpha: 0.2), width: 0.5),
                  ), 
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: task.tagColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        task.tag, 
                        style: TextStyle(
                          color: task.tagColor, 
                          fontSize: 9.5, 
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
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
    );
  }

  int? _getDaysLeft(String dateStr) {
    final value = dateStr.trim();
    if (value.isEmpty || value.toLowerCase() == 'n/a' || value.toLowerCase() == 'no date') {
      return null;
    }

    if (value.toLowerCase() == 'today') {
      return 0;
    }

    try {
      final isoDate = DateTime.tryParse(value);
      if (isoDate != null) {
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final target = DateTime(isoDate.year, isoDate.month, isoDate.day);
        return target.difference(todayStart).inDays;
      }

      final normalized = value.replaceAll(',', '').toLowerCase();
      final parts = normalized.split(RegExp(r'\s+'));

      if (parts.length == 3) {
        int? day;
        int? month;
        int? year;

        const months = {
          'jan': 1, 'january': 1,
          'feb': 2, 'february': 2,
          'mar': 3, 'march': 3,
          'apr': 4, 'april': 4,
          'may': 5,
          'jun': 6, 'june': 6,
          'jul': 7, 'july': 7,
          'aug': 8, 'august': 8,
          'sep': 9, 'september': 9,
          'oct': 10, 'october': 10,
          'nov': 11, 'november': 11,
          'dec': 12, 'december': 12,
        };

        final firstNum = int.tryParse(parts[0]);
        if (firstNum != null) {
          day = firstNum;
          month = months[parts[1]];
          year = int.tryParse(parts[2]);
        } else {
          month = months[parts[0]];
          day = int.tryParse(parts[1]);
          year = int.tryParse(parts[2]);
        }

        if (day != null && month != null && year != null) {
          final target = DateTime(year, month, day);
          final today = DateTime.now();
          final todayStart = DateTime(today.year, today.month, today.day);
          return target.difference(todayStart).inDays;
        }
      }
    } catch (_) {}

    return null;
  }

  Widget _buildDaysLeftWidget(TaskItem task, String currentStatus) {
    if (currentStatus == 'Completed') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 12, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            'Completed',
            style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    final daysLeft = _getDaysLeft(task.date);
    if (daysLeft == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(
            'Due: ${task.date}',
            style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
      );
    }

    Color textColor = Colors.blueGrey.shade600;
    IconData icon = Icons.schedule;
    String text = '';
    FontWeight fontWeight = FontWeight.w500;

    if (task.timeStatus != null && task.timeStatus!.isNotEmpty) {
      final ts = task.timeStatus!;
      text = ts;
      fontWeight = FontWeight.bold;
      if (ts == 'Lead') {
        textColor = const Color(0xFF22C55E);
        icon = Icons.thumb_up_alt_outlined;
      } else if (ts == 'On Time') {
        textColor = const Color(0xFF3B82F6);
        icon = Icons.check_circle_outline;
      } else if (ts == 'Due Today') {
        textColor = const Color(0xFFF59E0B);
        icon = Icons.hourglass_empty_rounded;
      } else if (ts == 'Overdue') {
        textColor = const Color(0xFFEF4444);
        icon = Icons.warning_amber_rounded;
        if (daysLeft < 0) text = '${daysLeft.abs()} days overdue';
      } else if (ts == 'Lag') {
        textColor = const Color(0xFFDC2626);
        icon = Icons.error_outline;
      }
    } else {
      if (daysLeft < 0) {
        textColor = Colors.red.shade700;
        icon = Icons.warning_amber_rounded;
        text = '${daysLeft.abs()} days overdue';
        fontWeight = FontWeight.bold;
      } else if (daysLeft == 0) {
        textColor = Colors.orange.shade800;
        icon = Icons.hourglass_empty_rounded;
        text = '0 days left (Today)';
        fontWeight = FontWeight.bold;
      } else if (daysLeft == 1) {
        textColor = Colors.orange.shade700;
        icon = Icons.hourglass_bottom_rounded;
        text = '1 day left';
        fontWeight = FontWeight.bold;
      } else {
        textColor = (currentStatus == 'Pending' || currentStatus == 'Open') ? task.tagColor : Colors.blueGrey.shade600;
        icon = Icons.schedule;
        text = '$daysLeft days left';
        fontWeight = (currentStatus == 'Pending' || currentStatus == 'Open') ? FontWeight.bold : FontWeight.w500;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: textColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 10, color: textColor, fontWeight: fontWeight),
        ),
      ],
    );
  }

  Widget _buildList(List<dynamic> tasks, {required bool isMyAssignment}) {
    final filtered = tasks.where((taskItem) {
      final task = taskItem as Map<String, dynamic>;
      final name = (task['taskNm'] ?? '').toString().toLowerCase();
      final code = (task['taskCd'] ?? '').toString().toLowerCase();
      final desc = (task['taskDesc'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      final matchesSearch = name.contains(query) || code.contains(query) || desc.contains(query);
      if (!matchesSearch) return false;

      if (_filterFromDate != null || _filterToDate != null) {
        final dueDtStr = (task['endDt'] ?? task['stDt'] ?? task['dueDt']) as String?;
        if (dueDtStr == null || dueDtStr.isEmpty) {
          return false;
        }
        try {
          final dueDt = DateTime.tryParse(dueDtStr);
          if (dueDt == null) return false;
          final checkDate = DateTime(dueDt.year, dueDt.month, dueDt.day);
          if (_filterFromDate != null) {
            final fromDate = DateTime(_filterFromDate!.year, _filterFromDate!.month, _filterFromDate!.day);
            if (checkDate.isBefore(fromDate)) return false;
          }
          if (_filterToDate != null) {
            final toDate = DateTime(_filterToDate!.year, _filterToDate!.month, _filterToDate!.day);
            if (checkDate.isAfter(toDate)) return false;
          }
        } catch (_) {
          return false;
        }
      }

      if (_filterEmployeeId != null) {
        final checkEmpId = isMyAssignment ? task['assignedTo'] : task['assignedBy'];
        if (checkEmpId?.toString() != _filterEmployeeId.toString()) {
          return false;
        }
      }

      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.assignment_late_outlined,
                size: 56,
                color: Color(0xFFCBD5E1),
              ),
              const SizedBox(height: 16),
              Text(
                isMyAssignment 
                    ? "You haven't assigned any tasks yet" 
                    : "No tasks assigned to you",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF1F5F9), 
            indent: 12,
            endIndent: 12,
          ),
          itemBuilder: (context, index) {
            return _buildTaskCard(filtered[index], isMyAssignment: isMyAssignment);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showFAB = _tabController.index == 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomHeader(
        title: 'Assign Tasks',
        automaticallyImplyLeading: false,
        notificationCount: _unreadNotificationCount,
        onNotificationTap: () async {
          await Navigator.pushNamed(context, '/notifications');
          _fetchNotificationCount();
        },
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildBreadcrumbs(),
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: (_filterFromDate != null || _filterToDate != null || _filterEmployeeId != null)
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                      size: 20,
                    ),
                    onPressed: _showFilterBottomSheet,
                  ),
                ),
              ],
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _tabController.index = 0;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _tabController.index == 0
                              ? const Color(0xFF2563EB)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'My Assignments',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _tabController.index == 0
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _tabController.index = 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _tabController.index == 1
                              ? const Color(0xFF2563EB)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Assigned by Me',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _tabController.index == 1
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _isLoading && _myAssignments.isEmpty && _assignedToMe.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2563EB),
                        ),
                      )
                    : IndexedStack(
                        index: _tabController.index,
                        children: [
                          RefreshIndicator(
                            onRefresh: _loadData,
                            color: const Color(0xFF2563EB),
                            child: _buildList(_assignedToMe, isMyAssignment: false),
                          ),
                          RefreshIndicator(
                            onRefresh: _loadData,
                            color: const Color(0xFF2563EB),
                            child: _buildList(_myAssignments, isMyAssignment: true),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: showFAB
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/individual-task').then((value) {
                  if (value == true) {
                    _loadData();
                  }
                });
              },
              backgroundColor: const Color(0xFF2563EB),
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            )
          : null,
      bottomNavigationBar: CustomFooter(
        currentIndex: 2,
        onTabSelected: (index) {
          if (MainScreen.navigatorKey.currentState != null) {
            MainScreen.navigatorKey.currentState!.changeTab(index);
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
      ),
    );
  }
}