import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/task_item.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../services/api_service.dart';
import 'main_screen.dart';
import '../widgets/reassign_icon.dart';

class RaiseRequestScreen extends StatefulWidget {
  final TaskItem? task;
  final bool isChecker;
  final String? initialRemarks;

  const RaiseRequestScreen({
    super.key,
    this.task,
    this.isChecker = false,
    this.initialRemarks,
  });

  @override
  State<RaiseRequestScreen> createState() => _RaiseRequestScreenState();
}

class _RaiseRequestScreenState extends State<RaiseRequestScreen> {
  int? _selectedTaskId;
  String _selectedTaskTitle = '';
  String _impactLevel = 'High';
  String? _attachedFileName;
  String? _attachedFilePath;
  late TextEditingController _reasonCtrl;
  int _unreadNotificationCount = 0;
  List<TaskItem> _availableTasks = [];
  bool _isLoadingTasks = false;
  bool _isSubmitting = false;
  List<dynamic> _allMilestones = [];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _selectedTaskTitle = widget.task!.title;
      _selectedTaskId = _extractTaskNumericId(widget.task!);
    }
    _reasonCtrl = TextEditingController(text: widget.initialRemarks ?? '');
    _fetchNotifications();
    _loadMilestones();
    if (widget.task == null) {
      _fetchAvailableTasks();
    }
  }

  Future<void> _loadMilestones() async {
    try {
      final milestones = await ApiService.getAllMilestones();
      if (mounted) {
        setState(() {
          _allMilestones = milestones;
        });
      }
    } catch (_) {}
  }

  bool get _isReworkDisabled {
    TaskItem? targetTask = widget.task;
    if (targetTask == null && _availableTasks.isNotEmpty && _selectedTaskId != null) {
      try {
        targetTask = _availableTasks.firstWhere(
          (t) => _extractTaskNumericId(t) == _selectedTaskId,
          orElse: () => _availableTasks.first,
        );
      } catch (_) {}
    }
    if (targetTask == null) return false;

    // Rule 1: Assignment / Individual tasks -> Rework disabled
    if (targetTask.isIndividualTask) {
      return true;
    }

    final raw = targetTask.rawData ?? {};
    final mId = raw['mId'] ?? raw['mid'] ?? raw['m_id'];
    if (mId == null) return true;

    final prjId = raw['prjId'] ?? raw['prjid'] ?? raw['prj_id'];

    // Rule 2: 1st Milestone tasks of any project -> Rework disabled
    final mOrder = raw['milestoneOrdrId'] ?? raw['milestoneOrder'] ?? raw['mOrdrId'] ?? raw['ordrId'] ?? raw['ordr_id'];
    if (mOrder != null && (mOrder == 1 || mOrder == '1')) {
      return true;
    }

    if (_allMilestones.isNotEmpty) {
      final prjMilestones = _allMilestones.where((m) {
        final mPrj = m['prjId'] ?? m['prjid'] ?? m['prj_id'];
        return mPrj != null && prjId != null && mPrj.toString() == prjId.toString();
      }).toList();

      if (prjMilestones.isNotEmpty) {
        prjMilestones.sort((a, b) {
          final ordA = a['ordrId'] ?? a['ordr_id'] ?? a['mId'] ?? a['mid'] ?? 0;
          final ordB = b['ordrId'] ?? b['ordr_id'] ?? b['mId'] ?? b['mid'] ?? 0;
          return (ordA as num).compareTo(ordB as num);
        });

        final firstMId = prjMilestones.first['mId'] ?? prjMilestones.first['mid'] ?? prjMilestones.first['m_id'];
        if (firstMId != null && firstMId.toString() == mId.toString()) {
          return true;
        }
      }
    }

    return false;
  }

  int? _extractTaskNumericId(TaskItem item) {
    if (item.rawData != null) {
      final rawId = item.rawData?['taskId'] ??
          item.rawData?['task_id'] ??
          item.rawData?['liveTaskId'] ??
          item.rawData?['live_task_id'] ??
          item.rawData?['empTaskId'] ??
          item.rawData?['emp_task_id'] ??
          item.rawData?['id'];
      if (rawId != null) {
        final digits = rawId.toString().replaceAll(RegExp(r'[^\d]'), '');
        final parsed = int.tryParse(digits);
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    if (item.id.isNotEmpty) {
      final digits = item.id.replaceAll(RegExp(r'[^\d]'), '').trim();
      final parsed = int.tryParse(digits);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  Future<void> _fetchAvailableTasks() async {
    setState(() => _isLoadingTasks = true);
    try {
      final tasks = await ApiService.getLiveTasks();
      if (mounted) {
        setState(() {
          _availableTasks = tasks;
          if (tasks.isNotEmpty && _selectedTaskId == null) {
            _selectedTaskId = _extractTaskNumericId(tasks.first);
            _selectedTaskTitle = tasks.first.title;
          }
          _isLoadingTasks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTasks = false);
      }
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final unread = await ApiService.getUnreadNotifications();
      if (mounted) {
        setState(() => _unreadNotificationCount = unread.length);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  int? _extractExecutorEmpId(TaskItem? item) {
    if (item == null || item.rawData == null) return null;
    final raw = item.rawData;
    final rawId = raw?['empId'] ??
        raw?['empid'] ??
        raw?['emp_id'] ??
        raw?['assignedTo'] ??
        raw?['assigned_to'] ??
        raw?['executorId'] ??
        raw?['executor_id'] ??
        raw?['executor'];
    if (rawId != null) {
      final digits = rawId.toString().replaceAll(RegExp(r'[^\d]'), '');
      final parsed = int.tryParse(digits);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  Future<void> _handleRework() async {
    if (_isSubmitting) return;

    final remarks = _reasonCtrl.text.trim();
    TaskItem? targetTask = widget.task;
    
    if (targetTask == null && _availableTasks.isNotEmpty && _selectedTaskId != null) {
      try {
        targetTask = _availableTasks.firstWhere(
          (t) => _extractTaskNumericId(t) == _selectedTaskId,
          orElse: () => _availableTasks.first,
        );
      } catch (_) {}
    }

    if (_selectedTaskId == null && targetTask != null) {
      _selectedTaskId = _extractTaskNumericId(targetTask);
    }

    if (_selectedTaskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid task for rework.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final taskId = _selectedTaskId!;
    final executorId = _extractExecutorEmpId(targetTask);
    final bool isIndiv = targetTask?.isIndividualTask == true;
    final String currentUserName = await ApiService.getCurrentEmployeeName();

    try {
      if (isIndiv) {
        final Map<String, dynamic> rawObj = Map<String, dynamic>.from(targetTask?.rawData ?? {});
        rawObj['taskSts'] = 'WIP';
        rawObj['prcsYesActn'] = 'REWORK';
        rawObj['subStatus'] = 'REWORK';
        rawObj['sub_status'] = 'REWORK';
        if (executorId != null) rawObj['empId'] = executorId;
        if (remarks.isNotEmpty) {
          final prefix = '[Rejected - $currentUserName]';
          final existingRem = rawObj['remarks'];
          rawObj['remarks'] = existingRem != null && existingRem.toString().isNotEmpty 
              ? '${existingRem.toString()}\n---\n$prefix: $remarks' 
              : '$prefix: $remarks';
        }
        await ApiService.updateIndividualTask(taskId, rawObj)
            .timeout(const Duration(seconds: 4))
            .catchError((_) => false);
      } else {
        final Map<String, dynamic> rawObj = Map<String, dynamic>.from(targetTask?.rawData ?? {});
        rawObj['taskSts'] = 'WIP';
        rawObj['prcsYesActn'] = 'REWORK';
        rawObj['subStatus'] = 'REWORK';
        rawObj['sub_status'] = 'REWORK';
        if (executorId != null) rawObj['empId'] = executorId;
        if (remarks.isNotEmpty) {
          final prefix = '[Rejected - $currentUserName]';
          final existingRem = rawObj['addlRem'] ?? rawObj['remarks'];
          rawObj['addlRem'] = existingRem != null ? '$existingRem\n---\n$prefix: $remarks' : '$prefix: $remarks';
        }
        await ApiService.updateTaskLiveFull(taskId, rawObj)
            .timeout(const Duration(seconds: 4))
            .catchError((_) => false);

        bool primaryDone = false;
        if (widget.isChecker) {
          try {
            await ApiService.checkerAction(taskId, 'NO', remarks, rejectionType: 'REWORK', targetEmpId: executorId)
                .timeout(const Duration(seconds: 4));
            primaryDone = true;
          } catch (e) {
            debugPrint('Checker action rework failed: $e');
          }
        } else {
          try {
            await ApiService.reviewerAction(taskId, 'NO', remarks, rejectionType: 'REWORK', targetEmpId: executorId)
                .timeout(const Duration(seconds: 4));
            primaryDone = true;
          } catch (e) {
            debugPrint('Reviewer action rework failed: $e');
          }
        }

        if (!primaryDone) {
          try {
            await ApiService.updateProjectTaskStatus(taskId, 'REWORK')
                .timeout(const Duration(seconds: 4));
          } catch (e2) {
            debugPrint('Fallback project status update failed: $e2');
          }
        }
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        final taskDataStr = prefs.getString('task_item_data_$taskId');
        if (taskDataStr != null) {
          final Map<String, dynamic> taskJson = jsonDecode(taskDataStr);
          taskJson['status'] = 'Rework';
          taskJson['taskSts'] = 'WIP';
          taskJson['subStatus'] = 'REWORK';
          taskJson['prcsYesActn'] = 'REWORK';
          await prefs.setString('task_item_data_$taskId', jsonEncode(taskJson));
        }
      } catch (_) {}

    } catch (e) {
      debugPrint('Rework handling error: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Task sent back for Rework.'),
          backgroundColor: Color(0xFFF97316),
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, {
        'submitted': true,
        'action': 'REWORK',
        'taskId': taskId,
        'taskTitle': _selectedTaskTitle,
        'remarks': remarks,
        'impact': _impactLevel,
        'attachment': _attachedFilePath,
      });
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleReassign() async {
    if (_isSubmitting) return;

    final remarks = _reasonCtrl.text.trim();
    TaskItem? targetTask = widget.task;
    
    if (targetTask == null && _availableTasks.isNotEmpty && _selectedTaskId != null) {
      try {
        targetTask = _availableTasks.firstWhere(
          (t) => _extractTaskNumericId(t) == _selectedTaskId,
          orElse: () => _availableTasks.first,
        );
      } catch (_) {}
    }

    if (_selectedTaskId == null && targetTask != null) {
      _selectedTaskId = _extractTaskNumericId(targetTask);
    }

    if (_selectedTaskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid task to reassign.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final taskId = _selectedTaskId!;
    final executorId = _extractExecutorEmpId(targetTask);
    final bool isIndiv = targetTask?.isIndividualTask == true;
    final String currentUserName = await ApiService.getCurrentEmployeeName();

    try {
      if (isIndiv) {
        // Backend update for Individual Task reassignment to executor
        final Map<String, dynamic> rawObj = Map<String, dynamic>.from(targetTask?.rawData ?? {});
        rawObj['taskSts'] = 'WIP';
        rawObj['prcsYesActn'] = 'REASSIGN';
        rawObj['subStatus'] = 'REASSIGN';
        rawObj['sub_status'] = 'REASSIGN';
        if (executorId != null) rawObj['empId'] = executorId;
        if (remarks.isNotEmpty) {
          final prefix = '[Reassigned - $currentUserName]';
          final existingRem = rawObj['remarks'];
          rawObj['remarks'] = existingRem != null && existingRem.toString().isNotEmpty 
              ? '${existingRem.toString()}\n---\n$prefix: $remarks' 
              : '$prefix: $remarks';
        }
        await ApiService.updateIndividualTask(taskId, rawObj)
            .timeout(const Duration(seconds: 4))
            .catchError((_) => false);
      } else {
        // Backend update for Live Project Task reassignment to executor
        final Map<String, dynamic> rawObj = Map<String, dynamic>.from(targetTask?.rawData ?? {});
        rawObj['taskSts'] = 'WIP';
        rawObj['prcsYesActn'] = 'REASSIGN';
        rawObj['subStatus'] = 'REASSIGN';
        rawObj['sub_status'] = 'REASSIGN';
        if (executorId != null) rawObj['empId'] = executorId;
        if (remarks.isNotEmpty) {
          final prefix = '[Reassigned - $currentUserName]';
          final existingRem = rawObj['addlRem'] ?? rawObj['remarks'];
          rawObj['addlRem'] = existingRem != null ? '$existingRem\n---\n$prefix: $remarks' : '$prefix: $remarks';
        }
        await ApiService.updateTaskLiveFull(taskId, rawObj)
            .timeout(const Duration(seconds: 4))
            .catchError((_) => false);

        bool primaryDone = false;
        if (widget.isChecker) {
          try {
            await ApiService.checkerAction(taskId, 'NO', remarks, rejectionType: 'REASSIGN', targetEmpId: executorId)
                .timeout(const Duration(seconds: 4));
            primaryDone = true;
          } catch (e) {
            debugPrint('Checker action failed: $e');
          }
        } else {
          try {
            await ApiService.reviewerAction(taskId, 'NO', remarks, rejectionType: 'REASSIGN', targetEmpId: executorId)
                .timeout(const Duration(seconds: 4));
            primaryDone = true;
          } catch (e) {
            debugPrint('Reviewer action failed: $e');
          }
        }

        if (!primaryDone) {
          try {
            await ApiService.updateProjectTaskStatus(taskId, 'REASSIGN')
                .timeout(const Duration(seconds: 4));
          } catch (e2) {
            debugPrint('Fallback project status update failed: $e2');
          }
        }
      }

      // Update local storage so local cached state reflects REASSIGN for executor
      try {
        final prefs = await SharedPreferences.getInstance();
        final taskDataStr = prefs.getString('task_item_data_$taskId');
        if (taskDataStr != null) {
          final Map<String, dynamic> taskJson = jsonDecode(taskDataStr);
          taskJson['status'] = 'Reassigned';
          taskJson['taskSts'] = 'REASSIGN';
          await prefs.setString('task_item_data_$taskId', jsonEncode(taskJson));
        }
      } catch (_) {}

    } catch (e) {
      debugPrint('Reassign handling error: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔁 Task successfully reassigned to executor.'),
          backgroundColor: Color(0xFF2563EB),
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, {
        'submitted': true,
        'action': 'REASSIGN',
        'taskId': taskId,
        'taskTitle': _selectedTaskTitle,
        'remarks': remarks,
        'impact': _impactLevel,
        'attachment': _attachedFilePath,
      });
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      appBar: CustomHeader(
        title: widget.task != null ? 'Deny / Reject Task' : 'Raise Request',
        automaticallyImplyLeading: false,
        notificationCount: _unreadNotificationCount,
        onNotificationTap: () async {
          await Navigator.pushNamed(context, '/notifications');
          _fetchNotifications();
        },
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Raise Request Title + Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.task != null ? 'Deny / Reject Task' : 'Raise Request',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

                // Task Dropdown Label
                const Text(
                  'Task Dropdown',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                // Task Dropdown Selector
                if (_isLoadingTasks)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    initialValue: _selectedTaskId,
                    hint: const Text('Select Task', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                    items: widget.task != null
                        ? [
                            DropdownMenuItem<int>(
                              value: _selectedTaskId,
                              child: Text(
                                _selectedTaskTitle,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]
                        : _availableTasks.map((t) {
                            final tId = _extractTaskNumericId(t);
                            return DropdownMenuItem<int>(
                              value: tId,
                              child: Text(
                                t.title,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedTaskId = val;
                        if (widget.task == null && _availableTasks.isNotEmpty) {
                          final selected = _availableTasks.firstWhere(
                            (t) => _extractTaskNumericId(t) == val,
                            orElse: () => _availableTasks.first,
                          );
                          _selectedTaskTitle = selected.title;
                        }
                      });
                    },
                  ),
                const SizedBox(height: 18),

                // Reason Label
                const Text(
                  'Reason',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                // Reason Text Input Area
                TextField(
                  controller: _reasonCtrl,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: 'Enter detailed reason...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),

                // Attachments & Impact Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Attachments (optional)
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Attachments (optional)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              try {
                                final result = await FilePicker.pickFiles();
                                if (result != null && result.files.isNotEmpty) {
                                  setState(() {
                                    _attachedFileName = result.files.first.name;
                                    _attachedFilePath = result.files.first.path;
                                  });
                                }
                              } catch (e) {
                                debugPrint('Error picking file: $e');
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.attach_file, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _attachedFileName ?? 'Click or drag files to upload',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: _attachedFileName != null ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                        fontWeight: _attachedFileName != null ? FontWeight.bold : FontWeight.w400,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Right Column: Impact Dropdown
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Impact',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            initialValue: _impactLevel,
                            items: const [
                              DropdownMenuItem(value: 'Low', child: Text('Low', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'Medium', child: Text('Medium', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'High', child: Text('High', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'Critical', child: Text('Critical', style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _impactLevel = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Action Buttons Footer Row (Cancel, Rework & Reassign)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (!_isReworkDisabled) ...[
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _handleRework,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 16),
                        label: const Text(
                          'Rework',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _handleReassign,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      icon: const ReassignIcon(color: Colors.white, size: 16),
                      label: const Text(
                        'Reassign',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
          ),
        ),
      ),
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
