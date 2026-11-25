import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/reassign_icon.dart';

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
  List<dynamic> _assignedByMe = [];
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

      final empList = await ApiService.getEmployees(forceRefresh: true);
      final List<EmployeeOption> parsedList = [];
      final Map<String, EmployeeOption> tempMap = {};

      for (final raw in empList) {
        final opt = EmployeeOption.fromJson(raw);
        if (opt.id != null && opt.id!.isNotEmpty && !tempMap.containsKey(opt.id)) {
          tempMap[opt.id!] = opt;
          parsedList.add(opt);
        }
      }

      parsedList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _employees = parsedList;

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
              (t['assignedBy'] ?? t['assigned_by'] ?? t['createdBy'] ?? t['created_by'] ?? t['supervisorId'] ?? t['assignerId'])?.toString() == _currentEmpId.toString();

          final isAssignedToMe =
              (t['assignedTo'] ?? t['assigned_to'] ?? t['empId'] ?? t['emp_id'] ?? t['doerId'] ?? t['doer_id'] ?? t['executorId'] ?? t['executor_id'] ?? t['assigneeId'])?.toString() ==
                  _currentEmpId.toString();

          final noteTxt = (t['noteTxt'] ?? t['note_txt'] ?? '').toString();
          final hasTeamMemberInTeamMembers = (t['teamMembers'] is List) && (t['teamMembers'] as List).any((tm) => tm['empId']?.toString() == _currentEmpId.toString() || tm['emp_id']?.toString() == _currentEmpId.toString());
          final isTeamMember = noteTxt
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .contains(_currentEmpId.toString()) || hasTeamMemberInTeamMembers;

          final isReviewer = (t['reviewer']?.toString() == _currentEmpId.toString()) ||
              (t['reviewers'] is List && (t['reviewers'] as List).any((r) => r.toString() == _currentEmpId.toString())) ||
              (t['reviewer']?.toString().split(',').map((e) => e.trim()).contains(_currentEmpId.toString()) ?? false) ||
              reviewerTaskIds.contains(taskId);
          final isApprover = (t['approver']?.toString() == _currentEmpId.toString()) ||
              (t['approvers'] is List && (t['approvers'] as List).any((a) => a.toString() == _currentEmpId.toString())) ||
              (t['approver']?.toString().split(',').map((e) => e.trim()).contains(_currentEmpId.toString()) ?? false) ||
              approverTaskIds.contains(taskId);

          // TAB 0: My Assignments
          if (isAssignedToMe || isTeamMember || isReviewer || isApprover) {
            myAssignments.add(t);
          }

          // TAB 1: Assigned by Me
          if (isAssignedByMe) {
            assignedByMeOnly.add(t);
          }
        }

        if (mounted) {
          setState(() {
            _myAssignments = myAssignments;   // Tab 0 -> My Assignments
            _assignedByMe = assignedByMeOnly; // Tab 1 -> Assigned by Me
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

  DateTime? _parseValidDate(String text) {
    final clean = text.trim();
    if (clean.length != 10) return null;
    final parts = clean.split('/');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    final currentYear = DateTime.now().year;
    if (year < currentYear || year > 2030) return null;

    try {
      final date = DateTime(year, month, day);
      if (date.day != day || date.month != month || date.year != year) {
        return null;
      }
      return date;
    } catch (_) {
      return null;
    }
  }

  void _showEmployeePickerDialog(
    BuildContext context,
    List<EmployeeOption> employees,
    EmployeeOption? selectedEmp,
    ValueChanged<EmployeeOption?> onSelected,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        String query = '';
        final searchController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = query.trim().isEmpty
                ? employees
                : employees.where((emp) {
                    final name = emp.name.toLowerCase();
                    final desig = emp.designation.toLowerCase();
                    final plt = emp.plantName?.toLowerCase() ?? '';
                    final coy = emp.companyName?.toLowerCase() ?? '';
                    final q = query.toLowerCase().trim();
                    return name.contains(q) || desig.contains(q) || plt.contains(q) || coy.contains(q);
                  }).toList();

            final screenHeight = MediaQuery.of(dialogContext).size.height;
            final dialogContentHeight = (screenHeight * 0.55).clamp(260.0, 460.0);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Row(
                children: [
                  const Icon(Icons.people_outline, color: Color(0xFF2563EB)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Select Employee',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: dialogContentHeight,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      onChanged: (val) => setDialogState(() => query = val),
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search employee...',
                        hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB), size: 20),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.cancel, color: Color(0xFF94A3B8), size: 18),
                                onPressed: () {
                                  searchController.clear();
                                  setDialogState(() => query = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (selectedEmp != null && query.isEmpty) ...[
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.clear_all, color: Colors.red, size: 20),
                        title: Text('Clear Selection (All Employees)', style: GoogleFonts.inter(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w600)),
                        onTap: () {
                          onSelected(null);
                          Navigator.pop(dialogContext);
                        },
                      ),
                      const Divider(height: 1),
                    ],
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_search_outlined, size: 40, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text('No employees found', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              itemBuilder: (context, index) {
                                final emp = filtered[index];
                                final isSelected = selectedEmp?.id == emp.id;
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isSelected ? const Color(0xFF2563EB) : const Color(0xFFEFF6FF),
                                    backgroundImage: emp.profileImageUrl != null && emp.profileImageUrl!.isNotEmpty
                                        ? NetworkImage(emp.profileImageUrl!)
                                        : null,
                                    child: emp.profileImageUrl == null || emp.profileImageUrl!.isEmpty
                                        ? Text(
                                            emp.initials,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.white : const Color(0xFF2563EB),
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    emp.name,
                                    style: GoogleFonts.inter(fontSize: 13.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: const Color(0xFF1E293B)),
                                  ),
                                  subtitle: emp.designation.isNotEmpty
                                      ? Text(
                                          emp.plantName != null && emp.plantName!.isNotEmpty
                                              ? '${emp.designation} • ${emp.plantName}'
                                              : emp.designation,
                                          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                                        )
                                      : null,
                                  trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 20) : null,
                                  onTap: () {
                                    onSelected(emp);
                                    Navigator.pop(dialogContext);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterBottomSheet() {
    final fromDateController = TextEditingController(
      text: _filterFromDate != null ? DateFormat('dd/MM/yyyy').format(_filterFromDate!) : '',
    );
    final toDateController = TextEditingController(
      text: _filterToDate != null ? DateFormat('dd/MM/yyyy').format(_filterToDate!) : '',
    );
    String? fromDateError;
    String? toDateError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void parseFromText(String text) {
              if (text.isEmpty) {
                setModalState(() {
                  _filterFromDate = null;
                  fromDateError = null;
                });
                return;
              }
              if (text.length == 10) {
                final picked = _parseValidDate(text);
                if (picked == null) {
                  setModalState(() {
                    fromDateError = 'Invalid Date';
                  });
                  return;
                }
                final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                if (picked.isBefore(today)) {
                  setModalState(() {
                    fromDateError = 'From Date cannot be in the past';
                  });
                  return;
                }
                setModalState(() {
                  fromDateError = null;
                  _filterFromDate = picked;
                  if (_filterToDate != null && _filterToDate!.isBefore(picked)) {
                    _filterToDate = picked;
                    toDateController.text = DateFormat('dd/MM/yyyy').format(picked);
                  }
                });
              } else {
                setModalState(() {
                  fromDateError = 'Invalid Date';
                });
              }
            }

            void parseToText(String text) {
              if (text.isEmpty) {
                setModalState(() {
                  _filterToDate = null;
                  toDateError = null;
                });
                return;
              }
              if (text.length == 10) {
                final picked = _parseValidDate(text);
                if (picked == null) {
                  setModalState(() {
                    toDateError = 'Invalid Date';
                  });
                  return;
                }
                final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                final minDate = _filterFromDate ?? today;
                if (picked.isBefore(today) || picked.isBefore(minDate)) {
                  setModalState(() {
                    toDateError = 'To Date cannot be before From Date';
                  });
                  return;
                }
                setModalState(() {
                  toDateError = null;
                  _filterToDate = picked;
                });
              } else {
                setModalState(() {
                  toDateError = 'Invalid Date';
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
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

                      // From Date Field (Full Width)
                      Text(
                        'From Date (DD/MM/YYYY)',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: fromDateController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          DateInputFormatter(),
                        ],
                        onChanged: parseFromText,
                        style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                        decoration: InputDecoration(
                          hintText: 'DD/MM/YYYY',
                          errorText: fromDateError,
                          hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF2563EB)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit_calendar_outlined, size: 20, color: Color(0xFF2563EB)),
                            tooltip: 'Pick Date Visual',
                            onPressed: () async {
                              final DateTime today = DateTime(
                                DateTime.now().year,
                                DateTime.now().month,
                                DateTime.now().day,
                              );
                              final DateTime firstDate = _filterFromDate ?? today;
                              final DateTime initialDate = _filterFromDate ?? today;
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
                                firstDate: firstDate.isBefore(today) ? firstDate : today,
                                lastDate: DateTime(2030),
                                initialEntryMode: DatePickerEntryMode.calendarOnly,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF2563EB),
                                        onPrimary: Colors.white,
                                        onSurface: Color(0xFF1E293B),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                final formatted = DateFormat('dd/MM/yyyy').format(picked);
                                fromDateController.text = formatted;
                                setModalState(() {
                                  fromDateError = null;
                                  _filterFromDate = picked;
                                  if (_filterToDate != null && _filterToDate!.isBefore(picked)) {
                                    _filterToDate = picked;
                                    toDateController.text = formatted;
                                  }
                                });
                              }
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _filterFromDate != null ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // To Date Field (Full Width)
                      Text(
                        'To Date (DD/MM/YYYY)',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: toDateController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          DateInputFormatter(),
                        ],
                        onChanged: parseToText,
                        style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                        decoration: InputDecoration(
                          hintText: 'DD/MM/YYYY',
                          errorText: toDateError,
                          hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF2563EB)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit_calendar_outlined, size: 20, color: Color(0xFF2563EB)),
                            tooltip: 'Pick Date Visual',
                            onPressed: () async {
                              final DateTime today = DateTime(
                                DateTime.now().year,
                                DateTime.now().month,
                                DateTime.now().day,
                              );
                              final DateTime minDate = _filterFromDate ?? today;
                              final DateTime firstDate = minDate.isBefore(today) ? today : minDate;
                              final initialTo = (_filterToDate != null && !_filterToDate!.isBefore(firstDate))
                                  ? _filterToDate!
                                  : firstDate;
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: initialTo.isBefore(firstDate) ? firstDate : initialTo,
                                firstDate: firstDate,
                                lastDate: DateTime(2030),
                                initialEntryMode: DatePickerEntryMode.calendarOnly,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF2563EB),
                                        onPrimary: Colors.white,
                                        onSurface: Color(0xFF1E293B),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                final formatted = DateFormat('dd/MM/yyyy').format(picked);
                                toDateController.text = formatted;
                                setModalState(() {
                                  toDateError = null;
                                  _filterToDate = picked;
                                });
                              }
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _filterToDate != null ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          ),
                        ),
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
                          return GestureDetector(
                            onTap: () {
                              _showEmployeePickerDialog(
                                context,
                                _employees,
                                selectedEmp,
                                (emp) {
                                  setModalState(() {
                                    _filterEmployeeId = emp?.id != null ? int.tryParse(emp!.id!) : null;
                                  });
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedEmp != null ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                                  width: selectedEmp != null ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selectedEmp != null ? Icons.person : Icons.search,
                                    color: selectedEmp != null ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      selectedEmp != null ? selectedEmp.name : 'Select Employee',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: selectedEmp != null ? FontWeight.w600 : FontWeight.w400,
                                        color: selectedEmp != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (selectedEmp != null)
                                    GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          _filterEmployeeId = null;
                                        });
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(2.0),
                                        child: Icon(Icons.clear, size: 18, color: Color(0xFF64748B)),
                                      ),
                                    )
                                  else
                                    const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF94A3B8)),
                                ],
                              ),
                            ),
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
                                  fromDateController.clear();
                                  toDateController.clear();
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
                                parseFromText(fromDateController.text.trim());
                                parseToText(toDateController.text.trim());
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
                ),
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
  int? _extractNumericTaskId(Map<String, dynamic> taskMap) {
    final rawId = taskMap['empTaskId'] ??
        taskMap['emp_task_id'] ??
        taskMap['taskId'] ??
        taskMap['task_id'] ??
        taskMap['id'];
    if (rawId != null) {
      final digits = rawId.toString().replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(digits);
    }
    return null;
  }

  void _confirmDeleteTask(Map<String, dynamic> taskMap) {
    final numId = _extractNumericTaskId(taskMap);
    final String title = (taskMap['taskNm'] ?? taskMap['title'] ?? 'this task').toString();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$title"? This action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              if (numId != null && numId > 0) {
                final success = await ApiService.deleteIndividualTask(numId);
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Task deleted successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Failed to delete task. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openTaskActionModal(Map<String, dynamic> taskMap) {
    final parsedTask = TaskItem.fromIndividualTask(taskMap, _currentEmpId?.toString());
    final bool isClosed = parsedTask.isCompleted ||
        parsedTask.status == 'Closed' ||
        parsedTask.status == 'Completed' ||
        parsedTask.status == 'Done';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          parsedTask.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: parsedTask.progressStatusBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          parsedTask.progressStatusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: parsedTask.progressStatusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // 1) View Task Details option (ALWAYS AVAILABLE)
                ListTile(
                  leading: const Icon(Icons.visibility_outlined, color: Color(0xFF2563EB)),
                  title: const Text('View Task Details', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Open full task details and activity'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openTask(taskMap, false);
                  },
                ),

                // 2) Edit Task & Delete Task options (ONLY FOR OPEN / IN PROGRESS / NON-CLOSED TASKS)
                if (!isClosed) ...[
                  ListTile(
                    leading: const Icon(Icons.edit_outlined, color: Color(0xFF16A34A)),
                    title: const Text('Edit Task', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Modify task title, description, assignee or due date'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final numId = _extractNumericTaskId(taskMap);
                      final fullTaskData = (numId != null && numId > 0)
                          ? (await ApiService.getIndividualTaskById(numId) ?? taskMap)
                          : taskMap;

                      if (!mounted) return;
                      final editResult = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IndividualTaskScreen(
                            task: fullTaskData,
                            isEditMode: true,
                          ),
                        ),
                      );
                      if (editResult == true) {
                        _loadData();
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text('Delete Task', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Permanently remove this task'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmDeleteTask(taskMap);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

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
      isMyAssignment: isMyAssignment,
      onInfoTap: () => _showStatusNote(context, parsedTask),
      onTap: () {
        if (isMyAssignment) {
          _openTask(taskMap, isMyAssignment);
        } else {
          _openTaskActionModal(taskMap);
        }
      },
      onOptionsTap: !isMyAssignment ? () => _openTaskActionModal(taskMap) : null,
    );
  }

  Widget _buildTaskTileRow({
    required TaskItem task,
    required String status,
    required bool isMyAssignment,
    required VoidCallback onInfoTap,
    required VoidCallback onTap,
    VoidCallback? onOptionsTap,
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
                    // Hide process icon for completed tasks
                    if (!task.isCompleted && task.processIcon != null) ...[
                      Tooltip(
                        message: task.processIconTooltip,
                        child: (task.isReassigned || task.processIcon == Icons.undo_rounded)
                            ? ReassignIcon(size: 18, color: task.processIconColor ?? const Color(0xFF4F46E5))
                            : Icon(task.processIcon, color: task.processIconColor, size: 18),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (task.computedTimeStatus.isNotEmpty)
                      Tooltip(
                        message: task.computedTimeStatus,
                        child: Icon(task.timeIcon, color: task.timeIconColor, size: 18),
                      ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
                    if (!isMyAssignment && onOptionsTap != null) ...[
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: onOptionsTap,
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.more_vert, color: Color(0xFF64748B), size: 20),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                
                // Priority Tag badge for open tasks OR Lead/Lag badge for completed tasks
                if (!task.isCompleted)
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
                  )
                else
                  _buildLeadLagBadge(_calculateTaskLeadLag(task)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _calculateTaskLeadLag(TaskItem task) {
    String? endStr = task.endDate ?? task.rawEndDt ?? task.date;
    if (endStr.isEmpty || endStr.toLowerCase() == 'no date' || endStr.toLowerCase() == 'n/a') {
      return 'ON TIME';
    }

    DateTime? endDt;
    try {
      endDt = DateTime.parse(endStr);
    } catch (_) {
      endDt = TaskItem.parseDateTime(endStr);
    }
    if (endDt == null) return 'ON TIME';

    final targetDate = DateTime(endDt.year, endDt.month, endDt.day);

    if (!task.isCompleted) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (targetDate.isBefore(today)) {
        return 'OVERDUE';
      } else if (targetDate.isAtSameMomentAs(today)) {
        return 'DUE TODAY';
      } else {
        return 'ON TIME';
      }
    }

    // Task IS completed -> Calculate exact Lead/Lag days!
    final String? apiStatus = task.rawData?['leadLagStatus']?.toString() ?? 
                              task.rawData?['lead_lag_status']?.toString() ?? 
                              task.rawData?['leadLagStatusStr']?.toString() ?? 
                              task.rawData?['scheduleStatus']?.toString();
    if (apiStatus != null && 
        apiStatus.isNotEmpty && 
        apiStatus.toLowerCase() != 'null' && 
        apiStatus.toLowerCase() != 'n/a' && 
        apiStatus.contains(RegExp(r'\d+'))) {
      return _cleanLeadLagLabel(apiStatus);
    }

    String? actStr = TaskItem.getRawCompletionDate(task.rawData);
    if (actStr.isEmpty) {
      actStr = task.rawData?['compDt']?.toString() ??
               task.rawData?['completedDt']?.toString() ??
               task.rawData?['actCmpDt']?.toString() ??
               task.rawData?['act_cmp_dt']?.toString() ??
               task.rawData?['actlEndDt']?.toString() ??
               task.rawData?['updDt']?.toString();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime refDate = today;

    if (actStr != null && actStr.isNotEmpty) {
      DateTime? actDt;
      try { actDt = DateTime.parse(actStr); } catch (_) { actDt = TaskItem.parseDateTime(actStr); }
      if (actDt != null) {
        refDate = DateTime(actDt.year, actDt.month, actDt.day);
      }
    }

    final diffDays = targetDate.difference(refDate).inDays;

    if (diffDays > 0) {
      return 'LEAD ($diffDays DAYS)';
    } else if (diffDays < 0) {
      return 'LAG (${diffDays.abs()} DAYS)';
    } else {
      return 'ON TIME';
    }
  }

  String _cleanLeadLagLabel(String statusStr) {
    final s = statusStr.trim();
    if (s.isEmpty || s.toLowerCase() == 'null' || s.toLowerCase() == 'n/a' || s.toLowerCase() == 'none') {
      return 'ON TIME';
    }

    final Match? numberMatch = RegExp(r'\d+').firstMatch(s);
    final String? daysNum = numberMatch?.group(0);
    final String lower = s.toLowerCase();

    if (lower.contains('on time')) {
      return 'ON TIME';
    } else if (lower.contains('due today')) {
      return 'DUE TODAY';
    } else if (lower.contains('overdue')) {
      if (daysNum != null && daysNum.isNotEmpty) {
        return 'OVERDUE ($daysNum DAYS)';
      }
      return 'OVERDUE';
    } else if (lower.contains('lead') || lower.contains('ahead')) {
      if (daysNum != null && daysNum.isNotEmpty) {
        return 'LEAD ($daysNum DAYS)';
      }
      return 'LEAD';
    } else if (lower.contains('lag') || lower.contains('behind') || lower.contains('delay')) {
      if (daysNum != null && daysNum.isNotEmpty) {
        return 'LAG ($daysNum DAYS)';
      }
      return 'LAG';
    } else if (daysNum != null && daysNum.isNotEmpty) {
      return 'LAG ($daysNum DAYS)';
    }

    return s.toUpperCase();
  }

  Widget _buildLeadLagBadge(String statusStr) {
    final String s = statusStr.trim().toLowerCase();
    
    if (s == 'null' || s == 'n/a' || s.isEmpty || s == 'none') {
      return _buildLeadLagPill('ON TIME', const Color(0xffDBEAFE), const Color(0xff2563EB));
    }

    bool isLead = s.contains('lead') || s == 'ahead';
    bool isLag = s.contains('lag') || s == 'behind' || s == 'delay' || s.contains('overdue');
    bool isDueToday = s.contains('due today');

    final String label = _cleanLeadLagLabel(statusStr);

    if (isLead) {
      return _buildLeadLagPill(label, const Color(0xffDCFCE7), const Color(0xff16A34A));
    } else if (isLag) {
      return _buildLeadLagPill(label, const Color(0xffFEE2E2), const Color(0xffDC2626));
    } else if (isDueToday) {
      return _buildLeadLagPill(label, const Color(0xffFEF3C7), const Color(0xffD97706));
    } else {
      return _buildLeadLagPill(label, const Color(0xffDBEAFE), const Color(0xff2563EB));
    }
  }

  Widget _buildLeadLagPill(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3.5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
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
        String? targetEmpId;
        if (isMyAssignment) {
          // Tab 0: My Assignments -> filter by who assigned it (Assigned By)
          targetEmpId = (task['assignedBy'] ?? task['assigned_by'] ?? task['createdBy'] ?? task['created_by'] ?? task['empIdBy'])?.toString();
        } else {
          // Tab 1: Assigned by Me -> filter by who it is assigned to (Assigned To)
          targetEmpId = (task['assignedTo'] ?? task['assigned_to'] ?? task['empId'] ?? task['emp_id'] ?? task['doerId'])?.toString();
        }
        if (targetEmpId != _filterEmployeeId.toString()) {
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
                    ? "No tasks assigned to you" 
                    : "You haven't assigned any tasks yet",
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
        title: 'Assignments',
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
                child: _isLoading && _myAssignments.isEmpty && _assignedByMe.isEmpty
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
                            child: _buildList(_myAssignments, isMyAssignment: true),
                          ),
                          RefreshIndicator(
                            onRefresh: _loadData,
                            color: const Color(0xFF2563EB),
                            child: _buildList(_assignedByMe, isMyAssignment: false),
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