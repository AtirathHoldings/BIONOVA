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
  bool _isSubmitting = false;
  List<dynamic> _allMilestones = [];
  List<dynamic> _employees = [];

  String _activeTab = 'REWORK';
  String? _selectedTargetMilestone;
  String? _selectedTargetDeliverable;
  int? _selectedReassignEmpId;

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
    _loadEmployees();
    _fetchAvailableTasks();
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

  Future<void> _loadEmployees() async {
    try {
      final emps = await ApiService.getEmployees();
      if (mounted) {
        setState(() {
          _employees = emps;
        });
      }
    } catch (_) {}
  }

  List<dynamic> get _availableMilestones {
    TaskItem? targetTask = widget.task;
    if (targetTask == null && _availableTasks.isNotEmpty && _selectedTaskId != null) {
      try {
        targetTask = _availableTasks.firstWhere(
          (t) => _extractTaskNumericId(t) == _selectedTaskId,
          orElse: () => _availableTasks.first,
        );
      } catch (_) {}
    }
    if (targetTask == null) return [];
    final raw = targetTask.rawData ?? {};
    final prjId = raw['prjId'] ?? raw['prjid'] ?? raw['prj_id'] ?? targetTask.projectId;
    final currentMId = (raw['mId'] ?? raw['mid'] ?? raw['m_id'] ?? raw['milestoneId'])?.toString();

    final prjMilestones = _allMilestones.where((m) {
      final mPrj = m['prjId'] ?? m['prjid'] ?? m['prj_id'];
      if (prjId != null && mPrj != null && prjId.toString().isNotEmpty) {
        return mPrj.toString() == prjId.toString();
      }
      final mTitle = (m['mlstnTtl'] ?? m['title'] ?? '').toString().toLowerCase();
      return mTitle.contains('postman');
    }).toList();

    final filtered = prjMilestones.where((m) {
      final mId = (m['mId'] ?? m['mid'] ?? m['id'])?.toString();
      final mTitle = (m['mlstnTtl'] ?? m['title'] ?? m['name'] ?? '').toString().toLowerCase();
      if (currentMId != null && mId != null && currentMId == mId) return false;
      if (mTitle.contains('milestone 2') || mTitle.contains('(m2)')) return false;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return [
        {'mId': '1', 'mlstnTtl': 'Postman Test Milestone 1'}
      ];
    }
    return filtered;
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
    try {
      final tasks = await ApiService.getLiveTasks();
      if (mounted) {
        setState(() {
          _availableTasks = tasks;
          if (tasks.isNotEmpty && _selectedTaskId == null) {
            _selectedTaskId = _extractTaskNumericId(tasks.first);
            _selectedTaskTitle = tasks.first.title;
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch available tasks: $e');
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

    final String targetMStr = _selectedTargetMilestone ?? 'Postman Test Milestone 1';
    final String targetTStr = _selectedTargetDeliverable ?? 'TSK-001 - Postman Test Task1(m1)';
    final String formattedRemarks = '[Target Milestone: $targetMStr | Target Task: $targetTStr]\n$remarks';

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
              ? '${existingRem.toString()}\n---\n$prefix: $formattedRemarks' 
              : '$prefix: $formattedRemarks';
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
          rawObj['addlRem'] = existingRem != null ? '$existingRem\n---\n$prefix: $formattedRemarks' : '$prefix: $formattedRemarks';
        }
        await ApiService.updateTaskLiveFull(taskId, rawObj)
            .timeout(const Duration(seconds: 4))
            .catchError((_) => false);

        bool primaryDone = false;
        if (widget.isChecker) {
          try {
            await ApiService.checkerAction(taskId, 'NO', formattedRemarks, rejectionType: 'REWORK', targetEmpId: executorId)
                .timeout(const Duration(seconds: 4));
            primaryDone = true;
          } catch (e) {
            debugPrint('Checker action rework failed: $e');
          }
        } else {
          try {
            await ApiService.reviewerAction(taskId, 'NO', formattedRemarks, rejectionType: 'REWORK', targetEmpId: executorId)
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
        'remarks': formattedRemarks,
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
    final executorId = _selectedReassignEmpId ?? _extractExecutorEmpId(targetTask);
    final bool isIndiv = targetTask?.isIndividualTask == true;
    final String currentUserName = await ApiService.getCurrentEmployeeName();

    try {
      if (isIndiv) {
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
          content: Text('🔁 Task successfully reassigned.'),
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
    final bool canRework = !_isReworkDisabled;
    final bool isReworkMode = canRework && _activeTab == 'REWORK';

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
                    canRework ? 'Raise Request / Review Action' : 'Reassign Task',
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

              const SizedBox(height: 16),

              // Request Type Selector Tabs - ONLY shown if Rework is allowed
              if (canRework) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _activeTab = 'REWORK'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isReworkMode ? const Color(0xFF3B82F6) : const Color(0xFFF8FAFC),
                          foregroundColor: isReworkMode ? Colors.white : const Color(0xFF475569),
                          elevation: isReworkMode ? 1 : 0,
                          side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.sync_rounded, size: 16),
                        label: const Text('Rework Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _activeTab = 'REASSIGN'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !isReworkMode ? const Color(0xFF4F46E5) : const Color(0xFFF8FAFC),
                          foregroundColor: !isReworkMode ? Colors.white : const Color(0xFF475569),
                          elevation: !isReworkMode ? 1 : 0,
                          side: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: ReassignIcon(color: !isReworkMode ? Colors.white : const Color(0xFF4F46E5), size: 16),
                        label: const Text('Reassign Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // REWORK MODE FORM
              if (isReworkMode) ...[
                // Select Target Milestone Label
                const Text(
                  'Select Target Milestone',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  initialValue: _selectedTargetMilestone ?? (_availableMilestones.isNotEmpty ? (_availableMilestones.first['mlstnTtl'] ?? _availableMilestones.first['title'] ?? '').toString() : null),
                  hint: const Text('Select Milestone', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                  items: _availableMilestones.map((m) {
                    final title = (m['mlstnTtl'] ?? m['title'] ?? m['name'] ?? 'Milestone').toString();
                    return DropdownMenuItem<String>(
                      value: title,
                      child: Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedTargetMilestone = val;
                      _selectedTargetDeliverable = null;
                    });
                  },
                ),
                const SizedBox(height: 18),

                // Select Target Task / Deliverable Label
                const Text(
                  'Select Target Task / Deliverable',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  initialValue: _selectedTargetDeliverable ?? 'TSK-001 - Postman Test Task1(m1)',
                  hint: const Text('Select Task / Deliverable', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                  items: [
                    const DropdownMenuItem<String>(
                      value: 'TSK-001 - Postman Test Task1(m1)',
                      child: Text('TSK-001 - Postman Test Task1(m1)', style: TextStyle(fontSize: 13, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                    ),
                    ..._availableTasks
                        .where((t) => !t.title.toLowerCase().contains('(m2)'))
                        .map((t) => DropdownMenuItem<String>(
                              value: t.title,
                              child: Text(t.title, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                            )),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedTargetDeliverable = val);
                  },
                ),
                const SizedBox(height: 18),
              ],

              // REASSIGN MODE FORM
              if (!isReworkMode) ...[
                const Text(
                  'Reassign Target (Executor)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  initialValue: _selectedReassignEmpId,
                  hint: const Text('Select Employee to Reassign', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                  items: _employees.map((emp) {
                    final eId = int.tryParse((emp['empId'] ?? emp['id'] ?? 0).toString()) ?? 0;
                    final name = (emp['empNm'] ?? emp['emp_nm'] ?? emp['name'] ?? 'Employee $eId').toString();
                    return DropdownMenuItem<int>(
                      value: eId,
                      child: Text(name, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedReassignEmpId = val);
                  },
                ),
                const SizedBox(height: 18),
              ],

              // Reason Label
              const Text(
                'Reason',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonCtrl,
                maxLines: 4,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: isReworkMode ? 'Enter detailed reason for rework...' : 'Enter detailed reason for reassigning...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 18),

              // Attachments & Impact Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Attachments
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Attachments (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
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
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
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
                        const Text('Impact', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
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
                            if (val != null) setState(() => _impactLevel = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Action Buttons Footer Row
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
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  if (isReworkMode)
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _handleRework,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 16),
                      label: const Text('Submit Rework', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _handleReassign,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      icon: const ReassignIcon(color: Colors.white, size: 16),
                      label: const Text('Submit Reassign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
