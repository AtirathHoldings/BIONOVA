import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_item.dart';
import '../widgets/header.dart'; 
import '../widgets/footer.dart'; 
import 'main_screen.dart'; 
import '../services/api_service.dart'; 

class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({super.key});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  String _status = 'Open';
  int _currentIndex = 2; 
  bool _isDataLoaded = false;
  late TaskItem task; 
  bool _isLoadingData = false;
  String _userRole = 'user';
  List<dynamic> _processHistory = [];
  String _reviewerName = 'Siva Rama Krishna';
  String _approverName = 'Vikram Kiran';

  // 🔘 Button state ni track cheyadaniki
  // ignore: unused_field
  bool _isButtonClicked = false;

  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _assigneeNoteController = TextEditingController();
  final TextEditingController _approverNoteController = TextEditingController();

  bool _isEditingAssigneeRemarks = false;
  bool _isEditingApproverRemarks = false;
  String _tempAssigneeRemarks = '';
  String _tempApproverRemarks = '';

  final Map<String, bool> _expandedRemarks = {
    'Project Remarks': false,
    'Milestone Remarks': false,
    'Task Remarks': false,
    'Assignee Remarks': false,
    'Approver Remarks': false,
  };

  void _toggleRemark(String name) {
    setState(() {
      _expandedRemarks[name] = !(_expandedRemarks[name] ?? false);
    });
  }

  void _handleListFormatting(TextEditingController controller) {
    final text = controller.text;
    final selection = controller.selection;
    final pos = selection.baseOffset;

    if (pos <= 0) return;

    // Check if the character just typed is a newline
    if (text[pos - 1] == '\n') {
      final textBeforeCursor = text.substring(0, pos - 1);
      final lastNewlineIndex = textBeforeCursor.lastIndexOf('\n');
      final startOfLine = lastNewlineIndex == -1 ? 0 : lastNewlineIndex + 1;
      final prevLine = textBeforeCursor.substring(startOfLine);

      // If previous line is just empty bullet "•" or "• " (or number like "1. "), finish/clear it
      if (prevLine.trim() == '•' || prevLine.trim() == '• ') {
        final newText = text.substring(0, startOfLine) + text.substring(pos);
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: startOfLine),
        );
        return;
      }
      final emptyNumMatch = RegExp(r'^(\d+)\.\s*$').firstMatch(prevLine);
      if (emptyNumMatch != null) {
        final newText = text.substring(0, startOfLine) + text.substring(pos);
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: startOfLine),
        );
        return;
      }

      // Otherwise, check if previous line has a bullet or a number
      if (prevLine.startsWith('• ') || prevLine.startsWith('•')) {
        const insertText = '• ';
        final newText = text.substring(0, pos) + insertText + text.substring(pos);
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: pos + insertText.length),
        );
      } else {
        final numberPattern = RegExp(r'^(\d+)\.\s+(.*)');
        final match = numberPattern.firstMatch(prevLine);
        if (match != null) {
          final currentNum = int.parse(match.group(1)!);
          final nextNum = currentNum + 1;
          final insertText = '$nextNum. ';
          final newText = text.substring(0, pos) + insertText + text.substring(pos);
          controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: pos + insertText.length),
          );
        }
      }
    }
  }

  void _showStatusNote(BuildContext context, TaskItem task) {
    String noteMessage = '';
    if (task.tag == 'Critical' || task.tag == 'Overdue') {
      noteMessage = 'It will go to almost critical';
    } else if (task.tag == 'High') {
      noteMessage = 'This task has high priority and needs immediate action.';
    } else if (task.tag == 'Completed') {
      noteMessage = 'This task is successfully completed.';
    } else {
      noteMessage = 'Task is currently ${_status.toLowerCase()}.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(
              task.tag == 'Critical' || task.tag == 'Overdue' 
                  ? Icons.warning_amber_rounded 
                  : task.tag == 'High' 
                      ? Icons.info_outline 
                      : Icons.check_circle_outline, 
              color: task.tagColor, 
              size: 22,
            ),
            const SizedBox(width: 8),
            Text('${task.tag} Note', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(noteMessage, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _checklist = [
    {'title': 'Review inspection report', 'isDone': false},
    {'title': 'Verify equipment standards', 'isDone': false},
    {'title': 'Check safety compliance', 'isDone': false},
    {'title': 'Approve and submit', 'isDone': false},
  ];

  final List<Map<String, String>> _referenceTasks = [
    {'title': 'Foundation Concrete Pouring Layout', 'code': 'PRJ-001 • Ref Doc'},
    {'title': 'Piping Material Verification Sheet', 'code': 'PRJ-002 • Checklist'},
    {'title': 'Site Safety Clearance Certificate', 'code': 'PRJ-001 • Approved'},
  ];

  final List<Map<String, String>> _currentTaskTeam = [
    {'name': 'Vikram Kiran', 'role': 'Project Manager', 'initials': 'VK'},
  ];

  final List<Map<String, String>> _availableUsers = [
    {'name': 'Rahul Sharma', 'role': 'Site Engineer', 'initials': 'RS'},
    {'name': 'Siva Rama Krishna', 'role': 'QA/QC Inspector', 'initials': 'SR'},
    {'name': 'Kalyan Prasad', 'role': 'Safety Officer', 'initials': 'KP'},
    {'name': 'Ananya Reddy', 'role': 'Structural Consultant', 'initials': 'AR'},
  ];

  @override
  void dispose() {
    _noteController.dispose();
    _assigneeNoteController.dispose();
    _approverNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _userRole = prefs.getString('userRole') ?? 'user';

      // Load live checklist
      final dbChecklist = await ApiService.getLiveChecklistItems(int.parse(task.id));
      if (mounted) {
        setState(() {
          _checklist = dbChecklist;
        });
      }

      // Load process config reviewers/approvers
      final configs = await ApiService.getLiveProcessConfig(int.parse(task.id));
      String? checkerName;
      String? reviewerName;
      for (final config in configs) {
        final stepType = config['stepType'];
        if (stepType == 'CHECKER') {
          final empId = config['empId'] ?? config['emp_id'];
          if (empId != null) {
            checkerName = await ApiService.getEmployeeName((empId as num).toInt());
          }
        } else if (stepType == 'REVIEWER') {
          final rId = config['rId'] ?? config['r_id'] ?? config['rid'];
          if (rId != null) {
            reviewerName = await ApiService.getReviewerName((rId as num).toInt());
          }
        }
      }
      if (mounted) {
        setState(() {
          if (checkerName != null) _reviewerName = checkerName;
          if (reviewerName != null) _approverName = reviewerName;
        });
      }
    } catch (e) {
      print("Error loading checklist: $e");
    }

    try {
      final history = await ApiService.getProcessHistory(int.parse(task.id));
      if (mounted) {
        setState(() {
          _processHistory = history;
        });

        // Find checker and reviewer remarks
        String? dbAssigneeRemarks;
        String? dbApproverRemarks;
        for (final event in history.reversed) {
          final actorRole = event['actorRole'];
          final remarks = event['remarks'];
          if (actorRole == 'CHECKER' && dbAssigneeRemarks == null) {
            dbAssigneeRemarks = remarks;
          } else if (actorRole == 'REVIEWER' && dbApproverRemarks == null) {
            dbApproverRemarks = remarks;
          }
        }

        final prefs = await SharedPreferences.getInstance();
        final String? savedAssigneeNote = prefs.getString('saved_assignee_note_${task.id}');
        setState(() {
          _assigneeNoteController.text = savedAssigneeNote ?? dbAssigneeRemarks ??
              '• Daily material log sheet and active labor count checklist uploaded by Ravi Kumar (You).\n• Shuttering assets have been moved to the storage yard after cleanup.';
        });

        final String? savedApproverNote = prefs.getString('saved_approver_note_${task.id}');
        setState(() {
          _approverNoteController.text = savedApproverNote ?? dbApproverRemarks ??
              '• Initial review cleared.\n• Ensure drawings are signed before final validation.';
        });
      }
    } catch (e) {
      print("Error loading process history: $e");
      
      final prefs = await SharedPreferences.getInstance();
      final String? savedAssigneeNote = prefs.getString('saved_assignee_note_${task.id}');
      setState(() {
        _assigneeNoteController.text = savedAssigneeNote ??
            '• Daily material log sheet and active labor count checklist uploaded by Ravi Kumar (You).\n• Shuttering assets have been moved to the storage yard after cleanup.';
      });

      final String? savedApproverNote = prefs.getString('saved_approver_note_${task.id}');
      setState(() {
        _approverNoteController.text = savedApproverNote ??
            '• Initial review cleared.\n• Ensure drawings are signed before final validation.';
      });
    }

    setState(() {
      _status = task.status;
      _isButtonClicked = (_status == 'In Progress');
      _isLoadingData = false;
    });
  }

  Future<void> _startTask() async {
    setState(() {
      _isLoadingData = true;
    });
    try {
      await ApiService.startTask(int.parse(task.id));
      setState(() {
        _status = 'In Progress';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Task started! Status updated to In Progress.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting task: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _submitTask() async {
    setState(() {
      _isLoadingData = true;
    });
    try {
      if (task.status == 'Rework' || _status == 'Rework') {
        await ApiService.resubmitTask(int.parse(task.id), _assigneeNoteController.text);
      } else {
        await ApiService.submitTask(int.parse(task.id), _assigneeNoteController.text);
      }
      setState(() {
        _status = 'Under Review';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Task submitted for review!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting task: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _handleCheckerAction(String action) async {
    setState(() {
      _isLoadingData = true;
    });
    try {
      await ApiService.checkerAction(int.parse(task.id), action, _approverNoteController.text);
      setState(() {
        if (action == 'APPROVE') {
          _status = 'Under Review';
        } else {
          _status = 'Rework';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'APPROVE' 
            ? '✅ Checker approved! Task moved to Under Review.' 
            : '❌ Checker rejected! Task moved back to Rework.'), 
          backgroundColor: action == 'APPROVE' ? Colors.green : Colors.red
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _handleReviewerAction(String action) async {
    setState(() {
      _isLoadingData = true;
    });
    try {
      await ApiService.reviewerAction(int.parse(task.id), action, _approverNoteController.text);
      setState(() {
        if (action == 'APPROVE') {
          _status = 'Completed';
        } else {
          _status = 'Rework';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'APPROVE' 
            ? '✅ Approver approved! Task completed.' 
            : '❌ Approver rejected! Task moved back to Rework.'), 
          backgroundColor: action == 'APPROVE' ? Colors.green : Colors.red
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _saveRemarksToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_assignee_note_${task.id}', _assigneeNoteController.text);
    await prefs.setString('saved_approver_note_${task.id}', _approverNoteController.text);
  }

  Future<void> _enableEditing() async {
    setState(() {
      _status = 'In Progress';
      _isButtonClicked = true; 
    });
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✏️ Task opened for editing.'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green.shade700;
      case 'In Progress':
        return Colors.blue.shade700;
      case 'Under Review':
        return Colors.orange.shade600;
      case 'Open':
      default:
        return Colors.orange.shade800;
    }
  }

  void _showAddTeamBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder( 
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assign Team Member',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Search and add a person to this milestone task',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name or role...',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_currentTaskTeam.isNotEmpty) ...[
                    const Text('Assigned Members', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ..._currentTaskTeam.map((user) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade50,
                            child: Text(user['initials']!, style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          title: Text(user['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text(user['role']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          trailing: const Text('Assigned', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        )),
                    const SizedBox(height: 16),
                  ],

                  const Text('Available to Assign', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200, 
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _availableUsers.length,
                      itemBuilder: (context, index) {
                        final user = _availableUsers[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade50,
                            child: Text(user['initials']!, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          title: Text(user['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          subtitle: Text(user['role']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          trailing: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _currentTaskTeam.add(user);
                                _availableUsers.removeAt(index);
                              });
                              setModalState(() {}); 
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('👤 ${user['name']} assigned to this task.'),
                                  backgroundColor: Colors.deepPurple,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              minimumSize: const Size(60, 30),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            child: const Text('Add', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
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

  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is TaskItem) {
        task = args;
        _status = task.status;
      } else {
        task = const TaskItem(
          id: '0',
          title: 'Default Task',
          subtitle: 'PRJ-005 • MS-005', 
          date: 'Today',
          tag: 'Medium',
          tagColor: Colors.orange,
          tagBg: Color(0xFFFEF3C7),
          icon: Icons.assignment_outlined,
          iconColor: Colors.orange,
          iconBg: Color(0xFFFEF3C7),
          status: 'Open',
          priority: 'Medium',
          reviewer: 'Siva Rama Krishna',
          approver: 'Vikram Kiran',
        );
        _status = task.status;
      }
      _isDataLoaded = true;
      _reviewerName = task.reviewer ?? 'Siva Rama Krishna';
      _approverName = task.approver ?? 'Vikram Kiran';
      _loadSavedData();
    }

    int completedCount = _checklist.where((item) => item['isDone'] == true).length;
    bool isLastBoxChecked = _checklist.isNotEmpty && _checklist.last['isDone'] == true;

    // 📋 Button Text and Color logic 
    String buttonText = 'Update';
    Color buttonColor = Colors.deepPurple;

    if (_status == 'Completed') {
      buttonText = 'Completed';
      buttonColor = Colors.green.shade700;
    } else if (_status == 'Under Review') {
      buttonText = 'Under Review';
      buttonColor = Colors.grey;
    } else if (_status == 'Pending' || _status == 'Open' || _status == 'Overdue') {
      buttonText = 'Start Working';
      buttonColor = Colors.blue;
    } else if (_status == 'In Progress' || _status == 'Rework') {
      if (isLastBoxChecked) {
        buttonText = 'Submit for Review';
        buttonColor = Colors.orange.shade900;
      } else {
        buttonText = 'Update';
        buttonColor = Colors.deepPurple;
      }
    } else {
      buttonText = 'Start Working';
      buttonColor = Colors.blue;
    }

    final String reviewerName = _reviewerName;
    final String approverName = _approverName;
    
    String displayRole = 'Assignee';
    String actionMessage = 'Do the task';
    
    if (reviewerName.toLowerCase().contains('ravi') || _userRole == 'checker' || _userRole == 'Reviewer') {
      displayRole = 'Reviewer';
      actionMessage = 'Review the work';
    } else if (approverName.toLowerCase().contains('ravi') || _userRole == 'reviewer' || _userRole == 'Approver') {
      displayRole = 'Approver';
      actionMessage = 'Approve the work';
    } else {
      displayRole = 'Assignee';
      actionMessage = 'Do the task';
    }

    final Color badgeBg = Colors.white;
    final Color badgeTextColor = task.tagColor;
    final Color badgeBorderColor = task.tagColor.withValues(alpha: 0.3);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: CustomHeader(
        title: 'Task Details', 
        automaticallyImplyLeading: false, 
        onNotificationTap: () {
          Navigator.pushNamed(context, '/notifications');
        },
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, '/main');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF1E293B)),
                    label: const Text('Back', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
                  ),
                  TextButton.icon(
                    onPressed: _showAddTeamBottomSheet, 
                    icon: const Icon(Icons.add, size: 16, color: Colors.deepPurple),
                    label: const Text('Team', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      backgroundColor: Colors.deepPurple.withOpacity(0.08), 
                      side: BorderSide(color: Colors.deepPurple.withOpacity(0.2), width: 1), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 1. Top Header Card Banner
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: task.tagBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: task.tagColor.withOpacity(0.2), width: 1),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showStatusNote(context, task),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          task.tag == 'Critical' || task.tag == 'Overdue' 
                              ? Icons.warning_amber_rounded 
                              : task.tag == 'High' 
                                  ? Icons.info_outline 
                                  : Icons.check_circle_outline, 
                          color: task.tagColor, 
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeBg, 
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: badgeBorderColor),
                            ),
                            child: Text(actionMessage, style: TextStyle(color: badgeTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 6),
                          Text(task.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_status, style: TextStyle(color: _getStatusColor(_status), fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Meta Information Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetaRow('Project', Icons.folder_open_outlined, task.projectName ?? 'Commercial Complex Build', isValuePurple: true),
                    _buildMetaRow('Milestone', Icons.layers_outlined, task.milestoneName ?? 'Phase 1 Foundation Pouring', isValuePurple: true),
                    _buildMetaRow('Your Role', Icons.person_outline, displayRole, isStatusBadge: true),
                    _buildMetaRow('Start Date', Icons.date_range_outlined, task.startDate ?? 'No Date'), 
                    _buildMetaRow('Due Date', Icons.calendar_today_outlined, task.endDate ?? task.date, isValueRed: task.date == 'Today'),   
                    _buildMetaRow('Reviewer', Icons.rate_review_outlined, _reviewerName),
                    _buildMetaRow('Approver', Icons.verified_outlined, _approverName),
                    _buildMetaRow('Status', Icons.radio_button_checked, _status, isStatusBadge: true),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 8),
                        Text(
                          task.description ?? 'General task evaluation, quality documentation compliance, and regular milestone checks are required for this activity.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.5),
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.0),
                          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ),
                        
                        // 5 Types of Remarks Dropdowns (using custom arrow banners)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Reference Remarks', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            const SizedBox(height: 12),
                            _buildRemarkSection(
                              'Project Remarks',
                              _buildRemarksContentList(
                                task.projectRemarks != null && task.projectRemarks!.isNotEmpty
                                    ? task.projectRemarks!
                                    : '• Please strictly follow the site safety protocols and ensure all environmental compliance logs are updated for PRJ-001.\n• Concrete pour checks must be double-certified by the engineering team.',
                                const Color(0xFFEA580C),
                              ),
                              const Color(0xFFEA580C),
                            ),
                            _buildRemarkSection(
                              'Milestone Remarks',
                              _buildRemarksContentList(
                                task.milestoneRemarks != null && task.milestoneRemarks!.isNotEmpty
                                    ? task.milestoneRemarks!
                                    : '• Excavation and PCC foundation leveling milestones must complete testing cycles on schedule.\n• Ensure target timeline is strictly updated daily in the Gantt charts.',
                                const Color(0xFF2563EB),
                              ),
                              const Color(0xFF2563EB),
                            ),
                            _buildRemarkSection(
                              'Task Remarks',
                              _buildRemarksContentList(
                                task.taskRemarks != null && task.taskRemarks!.isNotEmpty
                                    ? task.taskRemarks!
                                    : '• Verify structural alignment of columns C1 to C10 with QA inspectors before concrete pouring.\n• Maintain checklist completion sequence in structural documents.',
                                const Color(0xFF10B981),
                              ),
                              const Color(0xFF10B981),
                            ),
                            _buildRemarkSection(
                              'Assignee Remarks',
                              _isEditingAssigneeRemarks
                                  ? _buildRemarksEditor(
                                      controller: _assigneeNoteController,
                                      themeColor: const Color(0xFF7C3AED),
                                      onSave: () async {
                                        await _saveRemarksToStorage();
                                        setState(() {
                                          _isEditingAssigneeRemarks = false;
                                        });
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('✅ Assignee remarks saved successfully!'),
                                              backgroundColor: Colors.green,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      onCancel: () {
                                        setState(() {
                                          _assigneeNoteController.text = _tempAssigneeRemarks;
                                          _isEditingAssigneeRemarks = false;
                                        });
                                      },
                                    )
                                  : ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: _assigneeNoteController,
                                      builder: (context, value, _) => _buildRemarksContentWithEdit(
                                        title: 'Assignee Remarks',
                                        content: value.text,
                                        themeColor: const Color(0xFF7C3AED),
                                        canEdit: displayRole == 'Assignee',
                                        onEditPressed: () {
                                          setState(() {
                                            _tempAssigneeRemarks = _assigneeNoteController.text;
                                            _isEditingAssigneeRemarks = true;
                                          });
                                        },
                                      ),
                                    ),
                              const Color(0xFF7C3AED),
                            ),
                            if (displayRole != 'Assignee')
                              _buildRemarkSection(
                                'Approver Remarks',
                                _isEditingApproverRemarks
                                    ? _buildRemarksEditor(
                                        controller: _approverNoteController,
                                        themeColor: const Color(0xFFE11D48),
                                        onSave: () async {
                                          await _saveRemarksToStorage();
                                          setState(() {
                                            _isEditingApproverRemarks = false;
                                          });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('✅ Approver remarks saved successfully!'),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                        onCancel: () {
                                          setState(() {
                                            _approverNoteController.text = _tempApproverRemarks;
                                            _isEditingApproverRemarks = false;
                                          });
                                        },
                                      )
                                    : ValueListenableBuilder<TextEditingValue>(
                                        valueListenable: _approverNoteController,
                                        builder: (context, value, _) => _buildRemarksContentWithEdit(
                                          title: 'Approver Remarks',
                                          content: value.text,
                                          themeColor: const Color(0xFFE11D48),
                                          canEdit: displayRole == 'Reviewer' || displayRole == 'Approver',
                                          onEditPressed: () {
                                            setState(() {
                                              _tempApproverRemarks = _approverNoteController.text;
                                              _isEditingApproverRemarks = true;
                                            });
                                          },
                                        ),
                                      ),
                                const Color(0xFFE11D48),
                              ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.0),
                          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ),
                        Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent), 
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: const EdgeInsets.only(top: 8),
                            title: const Text('Attachments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            iconColor: const Color(0xFF64748B),
                            collapsedIconColor: const Color(0xFF64748B),
                            children: _referenceTasks.map((ref) {
                              return _buildAttachmentTile(ref['title']!, ref['code']!, Icons.description_outlined, Colors.blue, const Color(0xFFEFF6FF), showDownload: true);
                            }).toList(),
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.0),
                          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Documents', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.upload_file_outlined, color: Colors.white, size: 14),
                                  label: const Text('Upload', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue, 
                                    elevation: 0, 
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero, 
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildAttachmentTile('Inspection_Report.pdf', '1.2 MB', Icons.picture_as_pdf, Colors.red, const Color(0xFFFFF5F5), showDownload: false),
                            _buildAttachmentTile('Equipment_Checklist.xlsx', '450 KB', Icons.table_chart, Colors.green, const Color(0xFFF0FDF4), showDownload: false),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // 3. Checklist Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Checklist', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        Text('$completedCount/${_checklist.length}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFE2E8F0)),
                    ...List.generate(_checklist.length, (index) {
                      final item = _checklist[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_status != 'In Progress') return; 

                                if (item['isDone']) {
                                  bool hasLaterDone = false;
                                  for (int i = index + 1; i < _checklist.length; i++) {
                                    if (_checklist[i]['isDone']) {
                                      hasLaterDone = true;
                                      break;
                                    }
                                  }
                                  if (hasLaterDone) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('⚠️ Please uncheck the below items first!'), backgroundColor: Colors.orange, duration: Duration(seconds: 2)),
                                    );
                                    return;
                                  }
                                  final int? chkId = item['chkId'];
                                  if (chkId != null) {
                                    ApiService.reopenChecklistItem(chkId);
                                  }
                                  setState(() { item['isDone'] = false; });
                                } 
                                else {
                                  bool canCheck = true;
                                  for (int i = 0; i < index; i++) {
                                    if (!_checklist[i]['isDone']) { canCheck = false; break; }
                                  }

                                  if (canCheck) {
                                    final int? chkId = item['chkId'];
                                    if (chkId != null) {
                                      ApiService.completeChecklistItem(chkId);
                                    }
                                    setState(() { item['isDone'] = true; });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('⚠️ Please complete the previous tasks in order!'), backgroundColor: Colors.orange, duration: Duration(seconds: 2)),
                                    );
                                  }
                                }
                              },
                              child: Icon(
                                item['isDone'] ? Icons.check_box : Icons.check_box_outline_blank,
                                color: _status != 'In Progress' 
                                    ? Colors.grey[300] 
                                    : (item['isDone'] ? Colors.green : Colors.grey[400]),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item['title'], 
                              style: TextStyle(
                                fontSize: 13, 
                                color: _status != 'In Progress' ? Colors.grey : const Color(0xFF1E293B), 
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.none, 
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 12),
                    
                    if (_isLoadingData)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(color: Colors.deepPurple),
                        ),
                      )
                    else if (_status == 'Completed')
                      Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200, width: 1),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text('Task Completed Successfully!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _enableEditing,
                              icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                              label: const Text('Edit Task', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.blue, width: 1),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (displayRole == 'Reviewer' && _status == 'Under Review')
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleCheckerAction('APPROVE'),
                              icon: const Icon(Icons.check, color: Colors.white, size: 16),
                              label: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleCheckerAction('REJECT'),
                              icon: const Icon(Icons.close, color: Colors.white, size: 16),
                              label: const Text('Reject (Rework)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (displayRole == 'Approver' && _status == 'Under Review')
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleReviewerAction('APPROVE'),
                              icon: const Icon(Icons.verified, color: Colors.white, size: 16),
                              label: const Text('Final Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleReviewerAction('REJECT'),
                              icon: const Icon(Icons.close, color: Colors.white, size: 16),
                              label: const Text('Reject (Rework)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_status == 'Under Review') 
                              ? null 
                              : () async {
                                  if (_status == 'Pending' || _status == 'Open' || _status == 'Overdue') {
                                    await _startTask();
                                  } 
                                  else if (_status == 'In Progress' || _status == 'Rework') {
                                    if (isLastBoxChecked) {
                                      await _submitTask();
                                    } else {
                                      await _saveRemarksToStorage();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('✅ Remarks updated! Complete the checklist to submit for review.'), backgroundColor: Colors.green),
                                      );
                                    }
                                  }
                                }, 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor, 
                            disabledBackgroundColor: Colors.grey.shade400,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            buttonText, 
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_processHistory.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.history, color: Colors.blue, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Process History',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _processHistory.length,
                        itemBuilder: (context, index) {
                          final event = _processHistory[index];
                          final bool isLast = index == _processHistory.length - 1;
                          final String actorRole = event['actorRole'] ?? '';
                          final String prcsSts = event['prcsSts'] ?? '';
                          final String remarks = event['remarks'] ?? '';
                          final String remarksTs = event['remarksTs'] ?? '';
                          
                          // Format date nicely
                          String formattedTime = '';
                          if (remarksTs.isNotEmpty) {
                            try {
                              final parsed = DateTime.parse(remarksTs);
                              final hour = parsed.hour > 12 ? parsed.hour - 12 : (parsed.hour == 0 ? 12 : parsed.hour);
                              final period = parsed.hour >= 12 ? 'PM' : 'AM';
                              final minute = parsed.minute.toString().padLeft(2, '0');
                              final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                              formattedTime = "${parsed.day} ${months[parsed.month - 1]} ${parsed.year} • $hour:$minute $period";
                            } catch (_) {
                              formattedTime = remarksTs;
                            }
                          }

                          Color dotColor = Colors.grey;
                          IconData dotIcon = Icons.circle;
                          if (prcsSts == 'YES') {
                            dotColor = Colors.green;
                            dotIcon = Icons.check_circle_outline;
                          } else if (prcsSts == 'NO') {
                            dotColor = Colors.red;
                            dotIcon = Icons.cancel_outlined;
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: dotColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(dotIcon, color: dotColor, size: 16),
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 50,
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            actorRole == 'CHECKER' ? 'Checker' : 'Reviewer',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          if (formattedTime.isNotEmpty)
                                            Text(
                                              formattedTime,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        remarks,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                    ],
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
              const SizedBox(height: 16),
            ],
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

  Widget _buildMetaRow(String label, IconData icon, String value, {bool isValuePurple = false, bool isValueRed = false, bool isStatusBadge = false}) {
    Color badgeBgColor = const Color(0xFFEFF6FF);
    Color badgeTextColor = Colors.blue;

    if (value == 'Open' || value == 'Pending') {
      badgeBgColor = Colors.amber.shade50;
      badgeTextColor = Colors.amber.shade800;
    } else if (value == 'In Progress' || value == 'Assignee') {
      badgeBgColor = const Color(0xFFEFF6FF);
      badgeTextColor = Colors.blue.shade700;
    } else if (value == 'Completed') {
      badgeBgColor = Colors.green.shade50;
      badgeTextColor = Colors.green;
    } else if (value == 'Reviewer') {
      badgeBgColor = const Color(0xFFF3E8FF);
      badgeTextColor = Colors.purple.shade700;
    } else if (value == 'Approver') {
      badgeBgColor = const Color(0xFFFFF7ED);
      badgeTextColor = Colors.orange.shade800;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const Spacer(),
          if (isStatusBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(6)),
              child: Text(value, style: TextStyle(color: badgeTextColor, fontSize: 12, fontWeight: FontWeight.w600)),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isValuePurple ? Colors.purple : isValueRed ? Colors.red : const Color(0xFF1E293B),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(String fileName, String size, IconData icon, Color iconColor, Color bgColor, {bool showDownload = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(size, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          if (showDownload) Icon(Icons.download_outlined, color: Colors.blue.shade400, size: 20),
        ],
      ),
    );
  }

  Widget _buildRemarksContentList(String content, Color themeColor) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      return const Text('No remarks available.', style: TextStyle(fontSize: 12, color: Colors.grey));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        String displayText = line.trim();
        Widget leading = const Text('• ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold));
        
        if (displayText.startsWith('•')) {
          displayText = displayText.substring(1).trim();
        } else if (RegExp(r'^\d+\.').hasMatch(displayText)) {
          final match = RegExp(r'^\d+\.').firstMatch(displayText);
          if (match != null) {
            leading = Text('${match.group(0)} ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: themeColor));
            displayText = displayText.substring(match.end).trim();
          }
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              Expanded(
                child: Text(
                  displayText,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.4),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRemarksEditor({
    required TextEditingController controller,
    required Color themeColor,
    required VoidCallback onSave,
    required VoidCallback onCancel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                final text = controller.text;
                final selection = controller.selection;
                final start = selection.start < 0 ? 0 : selection.start;
                final end = selection.end < 0 ? 0 : selection.end;
                final newText = text.replaceRange(start, end, '• ');
                controller.text = newText;
                controller.selection = TextSelection.collapsed(offset: start + 2);
              },
              icon: Icon(Icons.format_list_bulleted, size: 14, color: themeColor),
              label: Text('Bullet', style: TextStyle(fontSize: 11, color: themeColor, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                backgroundColor: themeColor.withValues(alpha: 0.08),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                final text = controller.text;
                final selection = controller.selection;
                final start = selection.start < 0 ? 0 : selection.start;
                final end = selection.end < 0 ? 0 : selection.end;
                final lineCount = '\n'.allMatches(text.substring(0, start)).length + 1;
                final insertText = '$lineCount. ';
                final newText = text.replaceRange(start, end, insertText);
                controller.text = newText;
                controller.selection = TextSelection.collapsed(offset: start + insertText.length);
              },
              icon: Icon(Icons.format_list_numbered, size: 14, color: themeColor),
              label: Text('Number', style: TextStyle(fontSize: 11, color: themeColor, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                backgroundColor: themeColor.withValues(alpha: 0.08),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: 'Enter your remarks (use toolbar above to insert bullets/numbers)...',
            hintStyle: const TextStyle(fontSize: 11.5, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: themeColor.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: themeColor, width: 1.5),
            ),
          ),
          onChanged: (val) {
            _handleListFormatting(controller);
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Save', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRemarksContentWithEdit({
    required String title,
    required String content,
    required Color themeColor,
    required bool canEdit,
    required VoidCallback onEditPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRemarksContentList(content, themeColor),
        if (canEdit) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onEditPressed,
              icon: Icon(Icons.edit_note, size: 16, color: themeColor),
              label: Text('Edit Remarks', style: TextStyle(fontSize: 12, color: themeColor, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                backgroundColor: themeColor.withValues(alpha: 0.08),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRemarkSection(String name, Widget contentWidget, Color themeColor) {
    final bool isOpen = _expandedRemarks[name] ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ArrowRemarkBanner(
          title: name,
          themeColor: themeColor,
          isOpen: isOpen,
          onTap: () => _toggleRemark(name),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: isOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 3, color: themeColor),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.04),
                    border: Border.all(color: themeColor.withValues(alpha: 0.15)),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: contentWidget,
                ),
              ),
            ],
          ),
          secondChild: const SizedBox(height: 8),
        ),
      ],
    );
  }

}

class ArrowRemarkBanner extends StatelessWidget {
  final String title;
  final Color themeColor;
  final VoidCallback onTap;
  final bool isOpen;

  const ArrowRemarkBanner({
    super.key,
    required this.title,
    required this.themeColor,
    required this.onTap,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context) {
    const double height = 36.0;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height + 8, 
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Positioned(
              left: 14,
              right: 0,
              top: 4,
              bottom: 4,
              child: ClipPath(
                clipper: ArrowBannerClipper(),
                child: Container(
                  padding: const EdgeInsets.only(left: 36, right: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        themeColor.withValues(alpha: 0.95),
                        themeColor,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Icon(
                        isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 4,
              top: 4,
              bottom: 4,
              child: Center(
                child: Transform.rotate(
                  angle: 0.785398, // 45 degrees
                  child: Container(
                    width: height * 0.65,
                    height: height * 0.65,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: themeColor.withValues(alpha: 0.8), width: 1.5),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: themeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArrowBannerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - size.height / 2, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width - size.height / 2, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}