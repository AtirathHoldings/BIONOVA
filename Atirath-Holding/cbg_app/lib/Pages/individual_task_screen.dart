import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import 'main_screen.dart';
import '../services/api_service.dart';
import '../models/employee_option.dart';
import '../widgets/searchable_dropdown.dart';

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
// INDIVIDUAL TASK SCREEN (Create / Preview / Edit)
// ============================================================

class IndividualTaskScreen extends StatefulWidget {
  final Map<String, dynamic>? task;
  final bool isPreview;
  final bool isEditMode;

  const IndividualTaskScreen({
    super.key,
    this.task,
    this.isPreview = false,
    this.isEditMode = false,
  });

  @override
  State<IndividualTaskScreen> createState() => _IndividualTaskScreenState();
}

class _IndividualTaskScreenState extends State<IndividualTaskScreen> {
  final int _currentIndex = 2;
  int _unreadNotificationCount = 0;
  bool _isLoading = false;

  // Form State
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _assignToKey = GlobalKey();
  final GlobalKey _durationKey = GlobalKey();
  final GlobalKey _descKey = GlobalKey();
  final GlobalKey _reviewerKey = GlobalKey();
  final GlobalKey _approverKey = GlobalKey();

  final TextEditingController _taskCodeController = TextEditingController(
    text: '',
  );
  final TextEditingController _titleController = TextEditingController(
    text: '',
  );
  final TextEditingController _descController = TextEditingController(text: '');
  final TextEditingController _taskRemarksController = TextEditingController(
    text: '',
  );
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();

  String _priority = 'Medium';
  String _status = 'Open';
  DateTime _startDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  DateTime? _dueDate;

  bool _isProcessWorkflowExpanded = false;

  // Checklist State
  final List<Map<String, dynamic>> _checklistItems = [];

  // Assignment & Workflow State
  EmployeeOption? _assignedEmployee;
  bool _enableWorkflow = false;
  List<EmployeeOption> _reviewers = [];
  List<EmployeeOption> _approvers = [];

  final List<Map<String, dynamic>> _attachments = [];
  final ImagePicker _picker = ImagePicker();

  int? _editingChecklistIndex;
  late TextEditingController _checklistEditController;
  late FocusNode _checklistFocusNode;

  // Employees loaded from DB
  List<EmployeeOption> _employees = [];

  // --- Task Code Formatting & Auto Generation (Identical to Web) ---
  static String formatTaskCode(String cd) {
    if (cd.trim().isEmpty) return '';
    final match = RegExp(r'^INDTSK-?(\d+)$', caseSensitive: false).firstMatch(cd.trim());
    if (match != null) {
      final num = int.tryParse(match.group(1) ?? '') ?? 0;
      return 'INDTSK-${num.toString().padLeft(3, '0')}';
    }
    return cd.trim().toUpperCase();
  }

  static String generateNextTaskCode(List<dynamic> allTasks) {
    if (allTasks.isEmpty) return "INDTSK-001";
    int maxNum = 0;
    for (final t in allTasks) {
      if (t is Map) {
        final cd = (t['taskCd'] ?? t['task_cd'] ?? t['code'] ?? '').toString();
        final match = RegExp(r'INDTSK-?(\d+)', caseSensitive: false).firstMatch(cd);
        if (match != null) {
          final num = int.tryParse(match.group(1) ?? '') ?? 0;
          if (num > maxNum) {
            maxNum = num;
          }
        }
      }
    }
    final nextNum = maxNum + 1;
    return 'INDTSK-${nextNum.toString().padLeft(3, '0')}';
  }

  Future<void> _initTaskCode() async {
    if (widget.isEditMode && widget.task != null && (widget.task!['taskCd'] != null && widget.task!['taskCd'].toString().trim().isNotEmpty)) {
      return;
    }

    try {
      final nextCode = await ApiService.getNextTaskCode();
      if (nextCode != null && nextCode.trim().isNotEmpty) {
        if (mounted) {
          setState(() {
            _taskCodeController.text = formatTaskCode(nextCode.trim());
          });
        }
        return;
      }
    } catch (e) {
      debugPrint("Error fetching next-code endpoint: $e");
    }

    // Fallback: calculate next code from cached / fetched individual tasks
    try {
      final tasks = await ApiService.getIndividualTasks();
      final calculated = generateNextTaskCode(tasks);
      if (mounted) {
        setState(() {
          _taskCodeController.text = calculated;
        });
      }
    } catch (e) {
      if (mounted && _taskCodeController.text.trim().isEmpty) {
        setState(() {
          _taskCodeController.text = "INDTSK-001";
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _startDateController.text = DateFormat('dd/MM/yyyy').format(_startDate);
    _dueDateController.text = _dueDate != null ? DateFormat('dd/MM/yyyy').format(_dueDate!) : '';

    _fetchNotificationCount();
    _fetchEmployees();
    _checklistEditController = TextEditingController();
    _checklistFocusNode = FocusNode();
    _taskCodeController.addListener(() => setState(() {}));
    _titleController.addListener(() => setState(() {}));
    _descController.addListener(() => setState(() {}));
    _taskRemarksController.addListener(() => setState(() {}));
    _durationController.addListener(_calculateEndDate);

    // Pre-fill if task is provided
    _prefillTaskData();

    // Auto-generate task code for new task
    if (widget.task == null || !widget.isEditMode || _taskCodeController.text.trim().isEmpty) {
      _initTaskCode();
    }
  }

  @override
  void dispose() {
    _taskCodeController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _taskRemarksController.dispose();
    _durationController.dispose();
    _startDateController.dispose();
    _dueDateController.dispose();
    _checklistEditController.dispose();
    _checklistFocusNode.dispose();
    super.dispose();
  }

  void _prefillTaskData() {
    if (widget.task == null) return;

    final task = widget.task!;

    _taskCodeController.text = formatTaskCode((task['taskCd'] ?? '').toString());
    _titleController.text = (task['taskNm'] ?? '').toString();
    _descController.text = (task['taskDesc'] ?? '').toString();
    _taskRemarksController.text = (task['taskRemarks'] ?? task['remarks'] ?? '')
        .toString();

    // Priority
    final dbPriority = (task['priority'] ?? 'MEDIUM').toString().toUpperCase();
    if (dbPriority == 'HIGH' || dbPriority == 'CRITICAL') {
      _priority = 'High';
    } else if (dbPriority == 'LOW') {
      _priority = 'Low';
    } else if (dbPriority == 'NORMAL') {
      _priority = 'Normal';
    } else {
      _priority = 'Medium';
    }

    // Status
    final dbStatus = (task['taskSts'] ?? 'ASSIGNED').toString().toUpperCase();
    if (dbStatus == 'IN_PROGRESS' || dbStatus == 'WIP') {
      _status = 'In Progress';
    } else if (dbStatus == 'COMPLETED' || dbStatus == 'CLOSED') {
      _status = 'Closed';
    } else {
      _status = 'Open';
    }

    // Dates
    final stDt = task['stDt']?.toString();
    if (stDt != null && stDt.isNotEmpty) {
      final parsed = DateTime.tryParse(stDt);
      if (parsed != null) {
        _startDate = DateTime(parsed.year, parsed.month, parsed.day);
        _startDateController.text = DateFormat('dd/MM/yyyy').format(_startDate);
      }
    } else {
      _startDateController.text = DateFormat('dd/MM/yyyy').format(_startDate);
    }

    final endDt = task['endDt']?.toString() ?? task['dueDt']?.toString();
    if (endDt != null && endDt.isNotEmpty) {
      final parsed = DateTime.tryParse(endDt);
      if (parsed != null) {
        _dueDate = DateTime(parsed.year, parsed.month, parsed.day);
        _dueDateController.text = DateFormat('dd/MM/yyyy').format(_dueDate!);
      }
    }

    final rawDur = task['noOfDays'] ??
        task['plnDys'] ??
        task['duration'] ??
        task['totalProjectDays'];
    if (rawDur != null && rawDur.toString().trim().isNotEmpty) {
      final parsedDur = int.tryParse(rawDur.toString());
      if (parsedDur != null) {
        _durationController.text = (parsedDur > 0 ? parsedDur : 1).toString();
      }
    }
    if (_durationController.text.isEmpty && _dueDate != null) {
      _calculateDurationFromDates();
    }

    final assignedTo = task['assignedTo'] ?? task['empId'];
    if (assignedTo != null) {
      _assignedEmployee = EmployeeOption(
        id: assignedTo.toString(),
        name: (task['empNm'] ?? task['assignedToNm'] ?? 'Unknown').toString(),
        designation: '',
      );
    }

    _reviewers.clear();
    final reviewerRaw = task['reviewers'] ?? task['reviewer'];
    if (reviewerRaw != null) {
      if (reviewerRaw is List) {
        for (var r in reviewerRaw) {
          if (r != null && r.toString().isNotEmpty) {
            _reviewers.add(EmployeeOption(
              id: r.toString(),
              name: (task['reviewerNm'] ?? 'Unknown').toString(),
              designation: '',
            ));
          }
        }
      } else if (reviewerRaw.toString().isNotEmpty) {
        for (var id in reviewerRaw.toString().split(',')) {
          if (id.trim().isNotEmpty) {
            _reviewers.add(EmployeeOption(
              id: id.trim(),
              name: (task['reviewerNm'] ?? 'Unknown').toString(),
              designation: '',
            ));
          }
        }
      }
    }

    _approvers.clear();
    final approverRaw = task['approvers'] ?? task['approver'];
    if (approverRaw != null) {
      if (approverRaw is List) {
        for (var a in approverRaw) {
          if (a != null && a.toString().isNotEmpty) {
            _approvers.add(EmployeeOption(
              id: a.toString(),
              name: (task['approverNm'] ?? 'Unknown').toString(),
              designation: '',
            ));
          }
        }
      } else if (approverRaw.toString().isNotEmpty) {
        for (var id in approverRaw.toString().split(',')) {
          if (id.trim().isNotEmpty) {
            _approvers.add(EmployeeOption(
              id: id.trim(),
              name: (task['approverNm'] ?? 'Unknown').toString(),
              designation: '',
            ));
          }
        }
      }
    }

    // Workflow
    final prcsFlg = task['prcsFlg'];
    if (prcsFlg != null) {
      _enableWorkflow =
          prcsFlg == true || prcsFlg.toString().toLowerCase() == 'true';
    }

    // Checklist items are now fetched strictly via API

    // Attachments loading
    final String? taskIdStr =
        task['empTaskId']?.toString() ?? task['id']?.toString();
    if (taskIdStr != null) {
      final taskIdInt = int.tryParse(taskIdStr);
      if (taskIdInt != null) {
        ApiService.fetchAttachmentsForTask(taskId: taskIdInt).then((
          dbAttachments,
        ) {
          if (mounted) {
            setState(() {
              _attachments.clear();
              for (final att in dbAttachments) {
                final String fileName = att['fileNm'] ?? 'Attachment';
                final String ext = fileName.split('.').last.toLowerCase();

                IconData fileIcon = Icons.insert_drive_file;
                Color iconColor = Colors.blue;
                Color bgColor = const Color(0xFFEFF6FF);

                if (ext == 'pdf') {
                  fileIcon = Icons.picture_as_pdf;
                  iconColor = Colors.red;
                  bgColor = const Color(0xFFFFF5F5);
                } else if (ext == 'xls' || ext == 'xlsx' || ext == 'csv') {
                  fileIcon = Icons.table_chart;
                  iconColor = Colors.green;
                  bgColor = const Color(0xFFF0FDF4);
                } else if (ext == 'doc' || ext == 'docx') {
                  fileIcon = Icons.description;
                  iconColor = Colors.blue;
                  bgColor = const Color(0xFFEFF6FF);
                } else if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
                  fileIcon = Icons.image;
                  iconColor = Colors.orange;
                  bgColor = const Color(0xFFFFF7ED);
                }

                _attachments.add({
                  'fileId': att['fileId'],
                  'fileName': fileName,
                  'filePath': att['atPath'] ?? '',
                  'size': 'Uploaded',
                  'icon': fileIcon,
                  'iconColor': iconColor,
                  'bgColor': bgColor,
                  'isAlreadyUploaded': true,
                });
              }
            });
          }
        });
      }
    }
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

  Future<void> _fetchEmployees() async {
    try {
      final list = await ApiService.getEmployees();
      final currentEmpId = await ApiService.getCurrentEmployeeId();
      if (mounted) {
        setState(() {
          _employees = list
              .map<EmployeeOption>((emp) => EmployeeOption.fromJson(emp))
              .toList();

          if (currentEmpId != null) {
            final idx = _employees.indexWhere(
              (e) => e.id?.toString() == currentEmpId.toString(),
            );
            if (idx != -1) {
              final selfEmp = _employees.removeAt(idx);
              final updatedSelfEmp = EmployeeOption(
                id: selfEmp.id,
                name: '${selfEmp.name} (Self)',
                designation: selfEmp.designation,
                companyName: selfEmp.companyName,
                plantName: selfEmp.plantName,
                profileImageUrl: selfEmp.profileImageUrl,
                coyId: selfEmp.coyId,
                pltId: selfEmp.pltId,
              );
              _employees.insert(0, updatedSelfEmp);
            } else {
              ApiService.getEmployeeName(currentEmpId).then((name) {
                if (name != null && mounted) {
                  setState(() {
                    _employees.insert(
                      0,
                      EmployeeOption(
                        id: currentEmpId.toString(),
                        name: '$name (Self)',
                        designation: '',
                      ),
                    );
                  });
                }
              });
            }
          }

          // Try to map assigned employee, reviewer, and approver to real instances after employees load
          if (widget.task != null) {
            if (_assignedEmployee != null) {
              final empId = _assignedEmployee!.id;
              for (final emp in _employees) {
                if (emp.id?.toString() == empId) {
                  _assignedEmployee = emp;
                  break;
                }
              }
              _fetchHolidaysForEmployee();
            } else if (_dueDate != null) {
              _calculateDurationFromDates();
            }

            for (int i = 0; i < _reviewers.length; i++) {
              final revId = _reviewers[i].id;
              for (final emp in _employees) {
                if (emp.id?.toString() == revId) {
                  _reviewers[i] = emp;
                  break;
                }
              }
            }

            for (int i = 0; i < _approvers.length; i++) {
              final appId = _approvers[i].id;
              for (final emp in _employees) {
                if (emp.id?.toString() == appId) {
                  _approvers[i] = emp;
                  break;
                }
              }
            }

            // Fetch process configs to update reviewer and approver if needed (fallback)
            if (widget.isEditMode || widget.isPreview) {
              _fetchProcessConfigs();
              _fetchChecklistItems();
            }
          }
        });
        if (_employees.isEmpty && mounted) {
          Future.delayed(const Duration(seconds: 3), () async {
            if (_employees.isEmpty && mounted) {
              final retryList = await ApiService.getEmployees();
              if (retryList.isNotEmpty && mounted) {
                setState(() {
                  _employees = retryList
                      .map<EmployeeOption>(
                        (emp) => EmployeeOption.fromJson(emp),
                      )
                      .toList();
                });
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching employees: $e');
    }
  }

  Future<void> _fetchChecklistItems() async {
    if (widget.task == null) return;

    final taskIdRaw =
        widget.task!['empTaskId'] ??
        widget.task!['emp_task_id'] ??
        widget.task!['taskId'] ??
        widget.task!['id'];

    final taskId = int.tryParse(taskIdRaw?.toString() ?? '');
    if (taskId == null || taskId == 0) return;

    try {
      final items = await ApiService.getIndividualChecklistItems(taskId);
      debugPrint('=== CHECKLIST ITEMS FOR TASK $taskId ===');
      debugPrint(items.toString());

      if (!mounted) return;

      setState(() {
        _checklistItems.clear();

        for (final raw in items) {
          final item = Map<String, dynamic>.from(raw);

          // STRICT checklist mapping only
          final title =
              (item['title'] ??
                      item['checkPnt'] ??
                      item['checkPoint'] ??
                      item['chkNm'] ??
                      item['chkDesc'] ??
                      item['checklistItem'])
                  ?.toString()
                  .trim() ??
              '';

          // checklist-specific key lekapothe skip cheyyi
          if (title.isEmpty) {
            debugPrint('Skipped non-checklist row: $item');
            continue;
          }

          final seqValue =
              item['seq'] ??
              item['ordrId'] ??
              item['orderId'] ??
              (_checklistItems.length + 1);

          _checklistItems.add({
            'chkId': item['chkId'] ?? item['id'],
            'title': title,
            'seq': seqValue.toString(),
            'isCompleted':
                item['isDone'] == true || item['isCompleted'] == true,
          });
        }
      });

      debugPrint('FINAL CHECKLIST => $_checklistItems');
    } catch (e) {
      debugPrint('Error fetching checklist items: $e');
    }
  }

  Future<bool> _saveChecklistItems(int taskId) async {
    try {
      // 1) fetch existing checklists
      final existing = await ApiService.getIndividualChecklistItems(taskId);

      // 2) delete old checklists
      for (final item in existing) {
        final chkId = int.tryParse((item['chkId'] ?? '').toString());
        if (chkId != null) {
          await ApiService.deleteChecklistItem(chkId);
        }
      }

      // 3) build latest checklist
      final cleanedItems = _checklistItems
          .map(
            (e) => {
              "chkNm": (e['title'] ?? '').toString().trim(),
              "chkDesc": "",
            },
          )
          .where((e) => (e["chkNm"] as String).isNotEmpty)
          .toList();

      debugPrint(
        'Checklist payload for individual task $taskId => $cleanedItems',
      );

      // empty checklist ante old items clear chesam kabatti success
      if (cleanedItems.isEmpty) return true;

      // 4) bulk create
      return await ApiService.createIndividualChecklistItems(
        empTaskId: taskId,
        items: cleanedItems,
      );
    } catch (e) {
      debugPrint('Error saving individual checklist items: $e');
      return false;
    }
  }

  void _calculateDurationFromDates() {
    if (_dueDate == null) return;

    final startDateOnly = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final dueDateOnly = DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day);

    if (dueDateOnly.isBefore(startDateOnly)) {
      _dueDate = _startDate;
      _dueDateController.text = DateFormat('dd/MM/yyyy').format(_startDate);
      _durationController.removeListener(_calculateEndDate);
      _durationController.text = '1';
      _durationController.addListener(_calculateEndDate);
      return;
    }

    final diff = dueDateOnly.difference(startDateOnly).inDays;
    final duration = (diff + 1).clamp(1, 9999);

    _durationController.removeListener(_calculateEndDate);
    _durationController.text = duration.toString();
    _durationController.addListener(_calculateEndDate);
  }

  Future<void> _fetchHolidaysForEmployee() async {
    if (_assignedEmployee == null) return;

    if (mounted) {
      if (_durationController.text.isNotEmpty) {
        _calculateEndDate();
      } else if (_dueDate != null) {
        _calculateDurationFromDates();
      }
    }
  }

  Future<void> _fetchProcessConfigs() async {
    if (widget.task == null) return;

    final taskIdRaw =
        widget.task!['empTaskId'] ??
        widget.task!['emp_task_id'] ??
        widget.task!['taskId'] ??
        widget.task!['id'];

    final taskId = int.tryParse(taskIdRaw?.toString() ?? '');
    if (taskId == null || taskId == 0) return;

    try {
      final configs = await ApiService.getLiveProcessConfigs(taskId);
      debugPrint('=== PROCESS CONFIGS FOR TASK $taskId ===');
      debugPrint(configs.toString());

      if (!mounted) return;

      final List<EmployeeOption> fetchedReviewers = [];
      final List<EmployeeOption> fetchedApprovers = [];

      EmployeeOption? findEmployeeById(String? id) {
        if (id == null || id.trim().isEmpty) return null;
        final normalized = id.trim();

        try {
          return _employees.firstWhere(
            (e) => e.id?.toString().trim() == normalized,
          );
        } catch (_) {
          return EmployeeOption(
            id: normalized,
            name: 'Unknown',
            designation: 'Unknown',
          );
        }
      }

      for (final raw in configs) {
        final config = Map<String, dynamic>.from(raw);

        // current task rows matrame use cheyyi
        final rowTaskId = int.tryParse(
          (config['empTaskId'] ?? config['taskId'] ?? '').toString(),
        );
        if (rowTaskId != null && rowTaskId != taskId) continue;

        final stepType = (config['stepType'] ?? '')
            .toString()
            .trim()
            .toUpperCase();
        final stepLabel = (config['stepLabel'] ?? '')
            .toString()
            .trim()
            .toUpperCase();

        // IMPORTANT: selected employee id always empId
        final empId = config['empId']?.toString();
        if (empId == null || empId.isEmpty) continue;

        final matchedEmployee = findEmployeeById(empId);
        if (matchedEmployee == null) continue;

        if (stepType == 'REVIEWER' || stepLabel == 'REVIEWER') {
          if (!fetchedReviewers.any((e) => e.id == matchedEmployee.id)) {
            fetchedReviewers.add(matchedEmployee);
          }
        } else if (stepType == 'CHECKER' ||
            stepType == 'APPROVER' ||
            stepLabel == 'APPROVER') {
          if (!fetchedApprovers.any((e) => e.id == matchedEmployee.id)) {
            fetchedApprovers.add(matchedEmployee);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _enableWorkflow = configs.isNotEmpty;
        if (fetchedReviewers.isNotEmpty) _reviewers = fetchedReviewers;
        if (fetchedApprovers.isNotEmpty) _approvers = fetchedApprovers;
      });

      debugPrint('FINAL REVIEWERS => ${_reviewers.map((e) => e.name).join(', ')}');
      debugPrint('FINAL APPROVERS => ${_approvers.map((e) => e.name).join(', ')}');
    } catch (e) {
      debugPrint('Error fetching process configs: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final DateTime firstDate = isStart
        ? today
        : (_startDate.isBefore(today) ? today : _startDate);

    final DateTime initialDate = isStart
        ? (_startDate.isBefore(today) ? today : _startDate)
        : (_dueDate != null && !_dueDate!.isBefore(firstDate) ? _dueDate! : firstDate);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
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
      setState(() {
        if (isStart) {
          _startDate = DateTime(picked.year, picked.month, picked.day);
          _startDateController.text = DateFormat('dd/MM/yyyy').format(_startDate);
          if (_durationController.text.isNotEmpty) {
            _calculateEndDate();
          } else if (_dueDate != null) {
            if (_dueDate!.isBefore(_startDate)) {
              _dueDate = _startDate;
              _dueDateController.text = DateFormat('dd/MM/yyyy').format(_startDate);
            }
            _calculateDurationFromDates();
          }
        } else {
          _dueDate = DateTime(picked.year, picked.month, picked.day);
          _dueDateController.text = DateFormat('dd/MM/yyyy').format(_dueDate!);
          _calculateDurationFromDates();
        }
      });
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

  void _parseStartDateFromText(String text) {
    final picked = _parseValidDate(text);
    if (picked != null) {
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      if (picked.isBefore(today)) return;

      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        if (_durationController.text.isNotEmpty) {
          _calculateEndDate();
        } else if (_dueDate != null) {
          if (_dueDate!.isBefore(_startDate)) {
            _dueDate = _startDate;
            _dueDateController.text = DateFormat('dd/MM/yyyy').format(_startDate);
          }
          _calculateDurationFromDates();
        }
      });
    }
  }

  void _parseDueDateFromText(String text) {
    final picked = _parseValidDate(text);
    if (picked != null) {
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final startDateOnly = DateTime(_startDate.year, _startDate.month, _startDate.day);
      if (picked.isBefore(today) || picked.isBefore(startDateOnly)) return;

      setState(() {
        _dueDate = DateTime(picked.year, picked.month, picked.day);
        _calculateDurationFromDates();
      });
    } else if (text.isEmpty) {
      setState(() {
        _dueDate = null;
        _durationController.removeListener(_calculateEndDate);
        _durationController.text = '';
        _durationController.addListener(_calculateEndDate);
      });
    }
  }

  void _calculateEndDate() {
    final text = _durationController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _dueDate = null;
        _dueDateController.clear();
      });
      return;
    }
    int? duration = int.tryParse(text);
    if (duration == null || duration <= 0) {
      duration = 1;
    }

    final cleanStart = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final calculated = cleanStart.add(Duration(days: duration - 1));

    setState(() {
      _dueDate = calculated;
      _dueDateController.text = DateFormat('dd/MM/yyyy').format(calculated);
    });
  }

  void _commitChecklistItem(int idx) {
    final text = _checklistEditController.text.trim();
    _checklistFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    setState(() {
      if (text.isNotEmpty) {
        if (idx < _checklistItems.length) {
          _checklistItems[idx]['title'] = text;
        }
      } else {
        if (idx < _checklistItems.length) {
          _checklistItems.removeAt(idx);
          for (int i = 0; i < _checklistItems.length; i++) {
            _checklistItems[i]['seq'] = '${i + 1}';
          }
        }
      }
      _editingChecklistIndex = null;
    });
  }

  void _addChecklistItem() {
    bool hasEmpty = _checklistItems.any(
      (item) => item['title'].toString().trim().isEmpty,
    );
    if (hasEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'please enter here',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _checklistItems.add({
        'title': '',
        'seq': '${_checklistItems.length + 1}',
      });
      _editingChecklistIndex = _checklistItems.length - 1;
      _checklistEditController.clear();
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _checklistFocusNode.requestFocus();
    });
  }

  void _removeChecklistItem(int index) {
    _checklistFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    setState(() {
      if (index < _checklistItems.length) {
        _checklistItems.removeAt(index);
        for (int i = 0; i < _checklistItems.length; i++) {
          _checklistItems[i]['seq'] = '${i + 1}';
        }
      }
      if (_editingChecklistIndex == index) {
        _editingChecklistIndex = null;
      } else if (_editingChecklistIndex != null && _editingChecklistIndex! > index) {
        _editingChecklistIndex = _editingChecklistIndex! - 1;
      }
    });
  }

  void _confirmDeleteChecklistItem(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Confirm Delete',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Text(
            'Are you sure you want to delete this checklist item?',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF475569),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _removeChecklistItem(index);
              },
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitIndividualTask() async {
    // 1) Auto-commit any currently editing checklist item so it doesn't get lost
    if (_editingChecklistIndex != null && _editingChecklistIndex! < _checklistItems.length) {
      final text = _checklistEditController.text.trim();
      if (text.isNotEmpty) {
        _checklistItems[_editingChecklistIndex!]['title'] = text;
      } else {
        _checklistItems.removeAt(_editingChecklistIndex!);
        for (int i = 0; i < _checklistItems.length; i++) {
          _checklistItems[i]['seq'] = '${i + 1}';
        }
      }
      _editingChecklistIndex = null;
    }
    _checklistFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    // 2) Ensure duration is valid before form validation
    if (_durationController.text.trim().isEmpty ||
        (int.tryParse(_durationController.text.trim()) ?? 0) <= 0) {
      if (_dueDate != null) {
        _calculateDurationFromDates();
      }
      if (_durationController.text.trim().isEmpty ||
          (int.tryParse(_durationController.text.trim()) ?? 0) <= 0) {
        _durationController.removeListener(_calculateEndDate);
        _durationController.text = '1';
        _durationController.addListener(_calculateEndDate);
        _calculateEndDate();
      }
    }

    final bool isFormValid = _formKey.currentState!.validate();
    bool hasMissingFields = false;

    if (_titleController.text.trim().isEmpty) {
      Scrollable.ensureVisible(
        _titleKey.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      hasMissingFields = true;
    } else if (_assignedEmployee == null) {
      Scrollable.ensureVisible(
        _assignToKey.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select an employee to assign.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      hasMissingFields = true;
    } else if (_durationController.text.trim().isEmpty ||
        (int.tryParse(_durationController.text.trim()) ?? 0) <= 0) {
      Scrollable.ensureVisible(
        _durationKey.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      hasMissingFields = true;
    } else if (_descController.text.trim().isEmpty) {
      Scrollable.ensureVisible(
        _descKey.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      hasMissingFields = true;
    } else if (_enableWorkflow && _reviewers.isEmpty) {
      Scrollable.ensureVisible(
        _reviewerKey.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one reviewer.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      hasMissingFields = true;
    } else if (_enableWorkflow && _approvers.isEmpty) {
      Scrollable.ensureVisible(
        _approverKey.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one approver.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      hasMissingFields = true;
    }

    if (!isFormValid || hasMissingFields) return;

    final currentEmpId = await ApiService.getCurrentEmployeeId();
    if (!mounted) return;
    if (currentEmpId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to retrieve current user info. Please sign in again.',
          ),
        ),
      );
      return;
    }

    int mappedPriority = 3; // DEFAULT TO MEDIUM
    if (_priority == 'Low') {
      mappedPriority = 1;
    } else if (_priority == 'Normal') {
      mappedPriority = 2;
    } else if (_priority == 'Medium') {
      mappedPriority = 3;
    } else if (_priority == 'High') {
      mappedPriority = 4;
    }

    String mappedStatus = 'OPEN';
    if (widget.isEditMode &&
        widget.task != null &&
        widget.task!['taskSts'] != null) {
      mappedStatus = widget.task!['taskSts'].toString();
    } else {
      if (_status == 'In Progress') {
        mappedStatus = 'WIP';
      } else if (_status == 'Closed' || _status == 'Completed') {
        mappedStatus = 'CLOSED';
      } else if (_status == 'Under Review') {
        mappedStatus = 'SUBMIT_REVIEW';
      } else if (_status == 'Rework') {
        mappedStatus = 'REWORK';
      } else if (_status == 'Reassigned') {
        mappedStatus = 'REASSIGN';
      } else if (_status == 'Open') {
        mappedStatus = 'OPEN';
      }
    }

    final String startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final String? dueDateStr = _dueDate != null
        ? DateFormat('yyyy-MM-dd').format(_dueDate!)
        : null;

    final String enteredCode = _taskCodeController.text.trim();
    final String formattedCode = formatTaskCode(enteredCode.isNotEmpty ? enteredCode : 'INDTSK-001');

    final Map<String, dynamic> taskPayload = {
      "taskCd": formattedCode,
      "taskNm": _titleController.text.trim(),
      "taskDesc": _descController.text.trim(),
      "taskRemarks": _taskRemarksController.text.trim(),
      "empId": int.tryParse(_assignedEmployee?.id ?? '') ?? 0,
      "assignedBy": currentEmpId,
      "taskAsgnTo": "INTERNAL",
      "stDt": startDateStr,
      "endDt": dueDateStr,
      "priority": mappedPriority,
      "taskSts": mappedStatus,
      "sts": true,
      "remarks": _taskRemarksController.text.trim(),
      "chkFlg": _checklistItems.isNotEmpty,
      "attaFlg": _attachments.isNotEmpty,
      "prcsFlg": _enableWorkflow,
      "prcsYesActn": _enableWorkflow ? "YES" : "NO",
      "noOfDays": (int.tryParse(_durationController.text.trim()) ?? 1).clamp(1, 9999),
      "duration": (int.tryParse(_durationController.text.trim()) ?? 1).clamp(1, 9999),
      "totalProjectDays": (int.tryParse(_durationController.text.trim()) ?? 1).clamp(1, 9999),
    };

    try {
      setState(() => _isLoading = true);

      int? createdTaskId;
      bool success = false;

      if (widget.isEditMode && widget.task != null) {
        final taskIdRaw =
            widget.task!['empTaskId'] ??
            widget.task!['emp_task_id'] ??
            widget.task!['taskId'] ??
            widget.task!['id'];
        final taskIdInt = int.tryParse(taskIdRaw.toString()) ?? 0;

        success = await ApiService.updateIndividualTask(taskIdInt, taskPayload);
        if (success) createdTaskId = taskIdInt;
      } else {
        createdTaskId = await ApiService.createIndividualTask(taskPayload);
        success = createdTaskId != null;
      }

      if (!mounted) return;

      if (!success || createdTaskId == null || createdTaskId == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditMode ? 'Task update failed' : 'Task creation failed',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_enableWorkflow) {
        final reviewerIds = _reviewers.map((r) => int.tryParse(r.id ?? '') ?? 0).where((id) => id > 0).toList();
        final approverIds = _approvers.map((a) => int.tryParse(a.id ?? '') ?? 0).where((id) => id > 0).toList();

        final processSuccess = await ApiService.saveLiveProcessConfigs(
          createdTaskId,
          reviewerIds,
          approverIds,
        );
        if (!processSuccess) debugPrint('Failed to save process config');
      } else {
        await ApiService.deleteIndividualTaskProcessConfigs(createdTaskId);
      }

      ApiService.clearCache();

      if (!mounted) return;

      bool checklistSaved = true;
      if (_checklistItems.isNotEmpty) {
        checklistSaved = await _saveChecklistItems(createdTaskId);
        debugPrint(
          'Checklist save result for task $createdTaskId => $checklistSaved',
        );
      }

      if (!mounted) return;

      if (!checklistSaved && _checklistItems.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Checklist save failed')));
      }

      // Upload any new attachments
      for (final att in _attachments) {
        if (att['isAlreadyUploaded'] != true && att['filePath'] != null) {
          final uploadResult = await ApiService.uploadAttachment(
            taskId: createdTaskId,
            fileNm: att['fileName'],
            atPath: att['filePath'],
            atType: 'ATTACHMENT',
          );
          if (uploadResult != null) {
            att['isAlreadyUploaded'] = true;
            att['fileId'] = uploadResult['fileId'];
          }
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditMode
                ? 'Task updated successfully!'
                : 'Task created successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- UI Helpers ---

  Widget _buildBreadcrumbs() {
    return TextButton.icon(
      onPressed: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, '/main');
        }
      },
      icon: const Icon(
        Icons.arrow_back_ios_new,
        size: 16,
        color: Color(0xFF1E293B),
      ),
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

  Widget _buildSectionTitle(
    String title, {
    bool isRequired = false,
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          if (isRequired)
            Text(
              ' *',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: enabled ? Colors.white : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _buildEmployeeDropdown({
    required String label,
    required EmployeeOption? selected,
    required ValueChanged<EmployeeOption?> onChanged,
    bool isRequired = true,
    List<EmployeeOption> excluded = const [],
    bool enabled = true,
  }) {
    final items = _employees;

    final filteredItems = excluded.isEmpty
        ? items
        : items.where((item) {
            return !excluded.any((ex) =>
                ex == item ||
                (ex.id != null && item.id != null && ex.id!.isNotEmpty && item.id!.isNotEmpty && ex.id == item.id) ||
                ex.name.trim().toLowerCase() == item.name.trim().toLowerCase());
          }).toList();

    return SearchableDropdown<EmployeeOption>(
      items: filteredItems,
      selectedItem: selected,
      onChanged: enabled ? onChanged : (val) {},
      label: label,
      hint: 'Select $label',
      isRequired: isRequired,
      enabled: enabled,
      itemLabel: (item) => item.name,
      itemSubtitle: (item) => item.designation,
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    // Determine if in preview mode
    final isPreview = widget.isPreview;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      appBar: CustomHeader(
        title: isPreview
            ? 'Task Preview'
            : (widget.isEditMode ? 'Edit Task' : 'New Assignment'),
        automaticallyImplyLeading: false,
        notificationCount: _unreadNotificationCount,
        onNotificationTap: () async {
          await Navigator.pushNamed(context, '/notifications');
          _fetchNotificationCount();
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBreadcrumbs(),
                  const SizedBox(height: 16),
                  _buildTaskDetailsCard(isPreview: isPreview),
                  _buildChecklistCard(isPreview: isPreview),
                  _buildProcessWorkflowCard(isPreview: isPreview),
                  _buildAttachmentsCard(isPreview: isPreview),
                  _buildActionButtons(isPreview: isPreview),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomFooter(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          if (MainScreen.navigatorKey.currentState != null) {
            MainScreen.navigatorKey.currentState!.changeTab(index);
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
      ),
    );
  }

  Widget _buildTaskDetailsCard({required bool isPreview}) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Task Details'),
          const SizedBox(height: 16),

          _buildLabel('Task Code', isRequired: true),
          TextFormField(
            controller: _taskCodeController,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            textCapitalization: TextCapitalization.characters,
            maxLength: 10,
            decoration: _inputDecoration(
              enabled: !isPreview,
              hint: 'e.g. INDTSK-001',
              suffixIcon: (!isPreview && !widget.isEditMode)
                  ? IconButton(
                      icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF2563EB)),
                      tooltip: 'Auto Generate Code',
                      onPressed: _initTaskCode,
                    )
                  : null,
            ),
            enabled: !isPreview,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Please enter Task Code'
                : null,
          ),
          const SizedBox(height: 16),

          _buildLabel('Task Title', isRequired: true),
          Container(
            key: _titleKey,
            child: TextFormField(
              controller: _titleController,
              style: const TextStyle(fontSize: 13),
              decoration: _inputDecoration(enabled: !isPreview),
              enabled: !isPreview,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please enter Task Title'
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          _buildLabel('Priority', isRequired: true),
          DropdownButtonFormField<String>(
            initialValue: _priority,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Colors.grey,
            ),
            decoration: _inputDecoration(enabled: !isPreview),
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            items: ['High', 'Medium', 'Normal', 'Low'].map((p) {
              return DropdownMenuItem(value: p, child: Text(p));
            }).toList(),
            onChanged: isPreview
                ? null
                : (val) => setState(() => _priority = val!),
            validator: (value) => value == null || value.isEmpty
                ? 'Please select Priority'
                : null,
          ),
          const SizedBox(height: 16),

          Container(
            key: _assignToKey,
            child: _buildEmployeeDropdown(
              label: 'Assigned To',
              selected: _assignedEmployee,
              onChanged: (val) async {
                if (isPreview) return;
                setState(() {
                  _assignedEmployee = val;
                  if (val != null) {
                    _reviewers.removeWhere((r) => r.id == val.id || r.name.trim().toLowerCase() == val.name.trim().toLowerCase());
                    _approvers.removeWhere((a) => a.id == val.id || a.name.trim().toLowerCase() == val.name.trim().toLowerCase());
                  }
                });
                if (val != null) {
                  await _fetchHolidaysForEmployee();
                }
              },
              enabled: !isPreview,
            ),
          ),
          const SizedBox(height: 16),

          _buildLabel('Duration (Days)', isRequired: true),
          Container(
            key: _durationKey,
            child: TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              readOnly: isPreview,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              decoration: _inputDecoration(
                hint: 'Enter days',
                enabled: !isPreview,
              ),
              enabled: !isPreview,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter Duration';
                }
                final dur = int.tryParse(value.trim()) ?? 0;
                if (dur <= 0) {
                  return 'Duration must be greater than 0';
                }
                if (dur > 365) {
                  return 'Duration cannot exceed 365 days';
                }
                return null;
              },
              onChanged: (val) {
                _calculateEndDate();
              },
            ),
          ),
          const SizedBox(height: 16),

          _buildLabel('Start Date (DD/MM/YYYY)', isRequired: true),
          TextFormField(
            controller: _startDateController,
            keyboardType: TextInputType.number,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            enabled: !isPreview,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              DateInputFormatter(),
            ],
            onChanged: _parseStartDateFromText,
            style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
            decoration: _inputDecoration(
              hint: 'DD/MM/YYYY',
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.edit_calendar_outlined,
                  size: 20,
                  color: Color(0xFF2563EB),
                ),
                tooltip: 'Pick Date Visual',
                onPressed: isPreview ? null : () => _selectDate(context, true),
              ),
              enabled: !isPreview,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter Start Date';
              final date = _parseValidDate(value);
              if (date == null) return 'Invalid Date';
              final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
              if (date.isBefore(today)) return 'Start Date cannot be in the past';
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildLabel('Due Date (DD/MM/YYYY)', isRequired: true),
          TextFormField(
            controller: _dueDateController,
            keyboardType: TextInputType.number,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            enabled: !isPreview,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              DateInputFormatter(),
            ],
            onChanged: _parseDueDateFromText,
            style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
            decoration: _inputDecoration(
              hint: 'DD/MM/YYYY',
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.edit_calendar_outlined,
                  size: 20,
                  color: Color(0xFF2563EB),
                ),
                tooltip: 'Pick Date Visual',
                onPressed: isPreview ? null : () => _selectDate(context, false),
              ),
              enabled: !isPreview,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter Due Date';
              final date = _parseValidDate(value);
              if (date == null) return 'Invalid Date';
              final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
              if (date.isBefore(today)) return 'Due Date cannot be in the past';
              final startDateOnly = DateTime(_startDate.year, _startDate.month, _startDate.day);
              if (date.isBefore(startDateOnly)) return 'Due Date cannot be before Start Date';
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildLabel('Description', isRequired: true),
          Container(
            key: _descKey,
            child: TextFormField(
              controller: _descController,
              maxLines: 4,
              style: const TextStyle(fontSize: 13),
              decoration: _inputDecoration(enabled: !isPreview),
              enabled: !isPreview,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please enter Description'
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          _buildLabel('Task Remarks', isRequired: false),
          TextFormField(
            controller: _taskRemarksController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: _inputDecoration(enabled: !isPreview),
            enabled: !isPreview,
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard({required bool isPreview}) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'Checklist Items',
            isRequired: true,
            trailing: isPreview
                ? null
                : TextButton.icon(
                    onPressed: _addChecklistItem,
                    icon: const Icon(
                      Icons.add,
                      size: 14,
                      color: Color(0xFF2563EB),
                    ),
                    label: Text(
                      'Add',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          'Seq.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Checklist Item',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                      if (!isPreview)
                        SizedBox(
                          width: 70,
                          child: Text(
                            'Actions',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ..._checklistItems.asMap().entries.map((entry) {
                  int idx = entry.key;
                  Map<String, dynamic> item = entry.value;
                  bool isEditing = _editingChecklistIndex == idx && !isPreview;
                  return Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        Expanded(
                          child: isEditing
                              ? TextFormField(
                                  controller: _checklistEditController,
                                  focusNode: _checklistFocusNode,
                                  style: const TextStyle(fontSize: 12),
                                  autofocus: true,
                                  onFieldSubmitted: (value) {
                                    _commitChecklistItem(idx);
                                  },
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Enter',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 4,
                                    ),
                                    border: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                    focusedBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0xFF2563EB),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  item['title'].isEmpty
                                      ? 'New Item ${idx + 1}'
                                      : item['title'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                        ),
                        if (!isPreview)
                          SizedBox(
                            width: 70,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                isEditing
                                    ? GestureDetector(
                                        onTap: () => _commitChecklistItem(idx),
                                        child: const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                      )
                                    : GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _editingChecklistIndex = idx;
                                            _checklistEditController.text =
                                                item['title'];
                                          });
                                          Future.delayed(
                                            const Duration(milliseconds: 50),
                                            () {
                                              if (mounted) {
                                                _checklistFocusNode.requestFocus();
                                              }
                                            },
                                          );
                                        },
                                        child: const Icon(
                                          Icons.edit_outlined,
                                          size: 16,
                                          color: Color(0xFF3B82F6),
                                        ),
                                      ),
                                GestureDetector(
                                  onTap: () {
                                    _checklistFocusNode.unfocus();
                                    FocusScope.of(context).unfocus();
                                    if (isEditing) {
                                      setState(() {
                                        _editingChecklistIndex = null;
                                        if (idx < _checklistItems.length &&
                                            _checklistItems[idx]['title']
                                                .isEmpty) {
                                          _checklistItems.removeAt(idx);
                                          for (
                                            int i = 0;
                                            i < _checklistItems.length;
                                            i++
                                          ) {
                                            _checklistItems[i]['seq'] =
                                                '${i + 1}';
                                          }
                                        }
                                      });
                                    } else {
                                      _confirmDeleteChecklistItem(idx);
                                    }
                                  },
                                  child: Icon(
                                    isEditing
                                        ? Icons.close
                                        : Icons.delete_outline,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                if (_checklistItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No checklist found',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewDetailRow(
    String label,
    String value, {
    bool isPriority = false,
    bool isStatus = false,
  }) {
    Widget valueWidget;
    if (isPriority) {
      valueWidget = Text(
        value,
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
      );
    } else if (isStatus) {
      valueWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF2563EB),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      valueWidget = Text(
        value,
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  void _showPreviewDialog() {
    final dueDateStr = _dueDate == null
        ? '-'
        : DateFormat('dd-MMM-yyyy').format(_dueDate!);
    final assignedName = _assignedEmployee?.name ?? 'Not assigned';
    final reviewerNames = _reviewers.isNotEmpty
        ? _reviewers.map((r) => r.name).join(', ')
        : 'Not assigned';
    final approverNames = _approvers.isNotEmpty
        ? _approvers.map((a) => a.name).join(', ')
        : 'Not assigned';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.visibility_outlined,
                color: Color(0xFF2563EB),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Task Preview',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreviewDetailRow('Task Code', _taskCodeController.text),
                  _buildPreviewDetailRow('Task Title', _titleController.text),
                  _buildPreviewDetailRow(
                    'Priority',
                    _priority,
                    isPriority: true,
                  ),
                  _buildPreviewDetailRow(
                    'Start Date',
                    DateFormat('dd-MMM-yyyy').format(_startDate),
                  ),
                  _buildPreviewDetailRow('Due Date', dueDateStr),
                  _buildPreviewDetailRow('Assigned To', assignedName),
                  const Divider(height: 24, color: Color(0xFFE2E8F0)),
                  _buildPreviewDetailRow(
                    'Workflow',
                    _enableWorkflow
                        ? 'Enabled\nReviewer(s): $reviewerNames\nApprover(s): $approverNames'
                        : 'Disabled',
                  ),
                  const Divider(height: 24, color: Color(0xFFE2E8F0)),
                  _buildPreviewDetailRow(
                    'Checklist',
                    _checklistItems.isEmpty
                        ? 'No checklist found'
                        : _checklistItems
                              .map((item) => '• ${item['title']}')
                              .join('\n'),
                  ),
                  const Divider(height: 24, color: Color(0xFFE2E8F0)),
                  _buildPreviewDetailRow(
                    'Attachments',
                    _attachments.isEmpty
                        ? 'No attachments added'
                        : _attachments
                              .map(
                                (item) =>
                                    '📎 ${item['fileName']} (${item['size']})',
                              )
                              .join('\n'),
                  ),
                  const Divider(height: 24, color: Color(0xFFE2E8F0)),
                  _buildPreviewDetailRow('Description', _descController.text),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.edit_outlined,
                size: 16,
                color: Color(0xFF2563EB),
              ),
              label: Text(
                'Edit',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProcessWorkflowCard({required bool isPreview}) {
    return _buildCard(
      child: Column(
        children: [
          InkWell(
            onTap: isPreview
                ? null
                : () {
                    setState(() {
                      _isProcessWorkflowExpanded = !_isProcessWorkflowExpanded;
                    });
                  },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Process / Workflow",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                if (!isPreview)
                  AnimatedRotation(
                    turns: _isProcessWorkflowExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
              ],
            ),
          ),
          if (_isProcessWorkflowExpanded || isPreview) ...[
            const SizedBox(height: 20),
            _buildWorkflowContent(isPreview: isPreview),
          ],
        ],
      ),
    );
  }

  Widget _buildMultiEmployeeSelector({
    required String label,
    required String singleLabel,
    required List<EmployeeOption> selectedItems,
    required ValueChanged<List<EmployeeOption>> onChanged,
    bool isRequired = true,
    List<EmployeeOption> excluded = const [],
    bool enabled = true,
    required GlobalKey key,
  }) {
    final availableEmployees = _employees.where((item) {
      if (selectedItems.any((sel) => sel.id == item.id || (sel.id != null && item.id != null && sel.id!.isNotEmpty && sel.id == item.id) || sel.name.trim().toLowerCase() == item.name.trim().toLowerCase())) {
        return false;
      }
      if (excluded.any((ex) => ex.id == item.id || (ex.id != null && item.id != null && ex.id!.isNotEmpty && item.id == ex.id) || ex.name.trim().toLowerCase() == item.name.trim().toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    final nextNumber = selectedItems.length + 1;
    final hintText = 'Select $singleLabel $nextNumber';

    return Container(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label, isRequired: isRequired),
          if (selectedItems.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedItems.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final emp = entry.value;
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: const Color(0xFF2563EB),
                    child: Text(
                      '$idx',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  label: Text(
                    '$singleLabel $idx: ${emp.name}',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E293B), fontWeight: FontWeight.w500),
                  ),
                  deleteIcon: enabled ? const Icon(Icons.close, size: 16, color: Color(0xFF64748B)) : null,
                  onDeleted: enabled
                      ? () {
                          final updated = List<EmployeeOption>.from(selectedItems)..remove(emp);
                          onChanged(updated);
                        }
                      : null,
                  backgroundColor: const Color(0xFFEFF6FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (enabled)
            SearchableDropdown<EmployeeOption>(
              items: availableEmployees,
              selectedItem: null,
              onChanged: (val) {
                if (val != null) {
                  final updated = List<EmployeeOption>.from(selectedItems)..add(val);
                  onChanged(updated);
                }
              },
              label: '',
              hint: hintText,
              isRequired: isRequired && selectedItems.isEmpty,
              enabled: enabled,
              itemLabel: (item) => item.name,
              itemSubtitle: (item) => item.designation,
            ),
        ],
      ),
    );
  }

  Widget _buildWorkflowContent({required bool isPreview}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildLabel(
                'Enable Process / Workflow',
                isRequired: false,
              ),
            ),
            Switch(
              value: _enableWorkflow,
              activeThumbColor: const Color(0xFF2563EB),
              activeTrackColor: const Color(0xFF93C5FD),
              onChanged: isPreview
                  ? null
                  : (value) {
                      setState(() {
                        _enableWorkflow = value;
                      });
                    },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_enableWorkflow) ...[
          _buildMultiEmployeeSelector(
            key: _reviewerKey,
            label: 'Reviewer(s)',
            singleLabel: 'Reviewer',
            selectedItems: _reviewers,
            isRequired: _enableWorkflow,
            excluded: [
              _assignedEmployee,
            ].whereType<EmployeeOption>().toList(),
            onChanged: (val) {
              setState(() {
                _reviewers = val;
              });
            },
            enabled: !isPreview,
          ),
          const SizedBox(height: 16),
          _buildMultiEmployeeSelector(
            key: _approverKey,
            label: 'Approver(s)',
            singleLabel: 'Approver',
            selectedItems: _approvers,
            isRequired: _enableWorkflow,
            excluded: [
              _assignedEmployee,
              ..._reviewers,
            ].whereType<EmployeeOption>().toList(),
            onChanged: (val) {
              setState(() {
                _approvers = val;
              });
            },
            enabled: !isPreview,
          ),
        ],
      ],
    );
  }

  Widget _buildAttachmentTile(
    String fileName,
    String size,
    IconData icon,
    Color iconColor,
    Color bgColor, {
    required VoidCallback onDelete,
    required bool isPreview,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  size,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (!isPreview)
            GestureDetector(
              onTap: onDelete,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.delete_outline, color: Colors.red, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Upload Attachment',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildUploadOptionTile(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickDocument(ImageSource.gallery);
                    },
                  ),
                  _buildUploadOptionTile(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickDocument(ImageSource.camera);
                    },
                  ),
                  _buildUploadOptionTile(
                    icon: Icons.folder_open_outlined,
                    label: 'Files',
                    onTap: () {
                      Navigator.pop(context);
                      _pickGeneralFile();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDocument(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source);
      if (file != null) {
        final double sizeInMb = (await file.length()) / (1024 * 1024);
        final String sizeStr = '${sizeInMb.toStringAsFixed(1)} MB';
        if (mounted) {
          setState(() {
            _attachments.add({
              'fileName': file.name,
              'filePath': file.path,
              'size': sizeStr,
              'icon': Icons.image,
              'iconColor': Colors.orange,
              'bgColor': const Color(0xFFFFF7ED),
              'isAlreadyUploaded': false,
            });
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickGeneralFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles();
      if (result != null && result.files.single.path != null) {
        final platformFile = result.files.single;
        final String fileName = platformFile.name;
        final int sizeInBytes = platformFile.size;
        final double sizeInMb = sizeInBytes / (1024 * 1024);
        final String sizeStr = sizeInMb >= 0.1
            ? '${sizeInMb.toStringAsFixed(1)} MB'
            : '${(sizeInBytes / 1024).toStringAsFixed(0)} KB';

        IconData fileIcon = Icons.insert_drive_file;
        Color iconColor = Colors.blue;
        Color bgColor = const Color(0xFFEFF6FF);

        final String ext = fileName.split('.').last.toLowerCase();
        if (ext == 'pdf') {
          fileIcon = Icons.picture_as_pdf;
          iconColor = Colors.red;
          bgColor = const Color(0xFFFFF5F5);
        } else if (ext == 'xls' || ext == 'xlsx' || ext == 'csv') {
          fileIcon = Icons.table_chart;
          iconColor = Colors.green;
          bgColor = const Color(0xFFF0FDF4);
        } else if (ext == 'doc' || ext == 'docx') {
          fileIcon = Icons.description;
          iconColor = Colors.blue;
          bgColor = const Color(0xFFEFF6FF);
        } else if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
          fileIcon = Icons.image;
          iconColor = Colors.orange;
          bgColor = const Color(0xFFFFF7ED);
        }

        if (mounted) {
          setState(() {
            _attachments.add({
              'fileName': fileName,
              'filePath': platformFile.path!,
              'size': sizeStr,
              'icon': fileIcon,
              'iconColor': iconColor,
              'bgColor': bgColor,
              'isAlreadyUploaded': false,
            });
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Widget _buildAttachmentsCard({required bool isPreview}) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Attachments ',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                ],
              ),
              if (!isPreview)
                ElevatedButton.icon(
                  onPressed: _showUploadOptions,
                  icon: const Icon(
                    Icons.upload_file_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                  label: Text(
                    'Upload',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_attachments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No attachments uploaded yet.',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
            )
          else
            ..._attachments.asMap().entries.map((entry) {
              int idx = entry.key;
              var doc = entry.value;
              return _buildAttachmentTile(
                doc['fileName']!,
                doc['size']!,
                doc['icon'] as IconData,
                doc['iconColor'] as Color,
                doc['bgColor'] as Color,
                onDelete: () async {
                  if (doc['isAlreadyUploaded'] == true &&
                      doc['fileId'] != null) {
                    final deleteSuccess = await ApiService.deleteAttachment(
                      doc['fileId'],
                    );
                    if (deleteSuccess) {
                      setState(() {
                        _attachments.removeAt(idx);
                      });
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Failed to delete attachment. Please try again.',
                            ),
                          ),
                        );
                      }
                    }
                  } else {
                    setState(() {
                      _attachments.removeAt(idx);
                    });
                  }
                },
                isPreview: isPreview,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildActionButtons({required bool isPreview}) {
    // Preview mode - show Back and Edit buttons
    if (isPreview) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Back',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IndividualTaskScreen(
                      task: widget.task,
                      isEditMode: true,
                    ),
                  ),
                );

                if (result == true && mounted) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Edit',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Edit or Create mode
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _submitIndividualTask,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    widget.isEditMode
                        ? Icons.update
                        : Icons.check_circle_outline,
                    size: 18,
                  ),
            label: Text(
              _isLoading
                  ? (widget.isEditMode ? 'Updating...' : 'Assigning...')
                  : (widget.isEditMode ? 'Update Task' : 'Assign'),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isEditMode
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _showPreviewDialog,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: Text(
              'Preview Task',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
