import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_item.dart';
import '../widgets/header.dart'; 
import '../widgets/footer.dart'; 
import 'main_screen.dart'; 

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

  // 🔘 Button state ni track cheyadaniki
  bool _isButtonClicked = false;

  final TextEditingController _noteController = TextEditingController();

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
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final String? savedChecklist = prefs.getString('saved_checklist_${task.id ?? "0"}');
    if (savedChecklist != null) {
      setState(() {
        _checklist = List<Map<String, dynamic>>.from(json.decode(savedChecklist));
      });
    }

    final String? savedNote = prefs.getString('saved_note_${task.id ?? "0"}');
    if (savedNote != null) {
      setState(() {
        _noteController.text = savedNote;
      });
    }

    final String? savedStatus = prefs.getString('task_status_${task.id ?? "0"}');
    if (savedStatus != null) {
      setState(() {
        _status = savedStatus;
      });
    }

    final bool? savedClickState = prefs.getBool('btn_clicked_${task.id ?? "0"}');
    if (savedClickState != null) {
      setState(() {
        _isButtonClicked = savedClickState;
      });
    } else {
      setState(() {
        _isButtonClicked = (_status == 'In Progress');
      });
    }
  }

  Future<void> _saveChecklistToStorage({bool isSubmitReview = false}) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (isSubmitReview) {
      setState(() {
        _status = 'Completed';
        _isButtonClicked = false; 
      });
      await prefs.setString('task_status_${task.id ?? "0"}', 'Completed');
      await prefs.setBool('btn_clicked_${task.id ?? "0"}', false);
    }

    final String encodedChecklist = json.encode(_checklist);
    await prefs.setString('saved_checklist_${task.id ?? "0"}', encodedChecklist);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSubmitReview ? '✅ Task Completed Successfully!' : '✅ Checklist updated successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _enableEditing() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _status = 'In Progress';
      _isButtonClicked = true; 
    });
    await prefs.setString('task_status_${task.id ?? "0"}', 'In Progress');
    await prefs.setBool('btn_clicked_${task.id ?? "0"}', true);
    
    if (mounted) {
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
    } else if (_status == 'Pending' || _status == 'Open' || _status == 'Overdue') {
      buttonText = 'Start Working';
      buttonColor = Colors.blue;
    } else if (_status == 'In Progress') {
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

    String originalProjectCode = task.subtitle.split('•').first.trim();
    String milestoneCode = originalProjectCode;
    if (milestoneCode.contains('PRJ-')) {
      milestoneCode = milestoneCode.replaceAll('PRJ-', 'MS-');
    }

    String combinedCode = '$originalProjectCode  •  $milestoneCode';

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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(task.icon, color: task.iconColor, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2), 
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.withOpacity(0.2)),
                            ),
                            child: Text(combinedCode, style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
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
                    _buildMetaRow('Project', Icons.folder_open_outlined, 'Commercial Complex Build', isValuePurple: true),
                    _buildMetaRow('Milestone', Icons.layers_outlined, 'Phase 1 Foundation Pouring', isValuePurple: true),
                    _buildMetaRow('Start Date', Icons.date_range_outlined, '22 Jun 2026'), 
                    _buildMetaRow('Due Date', Icons.calendar_today_outlined, task.date, isValueRed: task.date == 'Today'),   
                    _buildMetaRow('Reviewer', Icons.rate_review_outlined, task.reviewer ?? 'Siva Rama Krishna'),
                    _buildMetaRow('Approver', Icons.verified_outlined, task.approver ?? 'Vikram Kiran'),
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
                        
                        // Reference Note Box
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF9E7), 
                            borderRadius: BorderRadius.circular(12), 
                            border: Border.all(color: const Color(0xFFF9E79F), width: 1.2),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Reference Note', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFB7950B))),
                              const SizedBox(height: 12),
                              ...(_noteController.text.isNotEmpty 
                                  ? _noteController.text.split('\n').where((text) => text.trim().isNotEmpty).map((point) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('• ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF7D6608))),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                point.trim(),
                                                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.4),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList() 
                                  : [const Text('No reference notes available.', style: TextStyle(fontSize: 13, color: Colors.grey))]),
                            ],
                          ),
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
                                  setState(() { item['isDone'] = false; });
                                } 
                                else {
                                  bool canCheck = true;
                                  for (int i = 0; i < index; i++) {
                                    if (!_checklist[i]['isDone']) { canCheck = false; break; }
                                  }

                                  if (canCheck) {
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
                    
                    if (_status == 'Completed')
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
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            
                            if (_status == 'Pending' || _status == 'Open' || _status == 'Overdue') {
                              setState(() {
                                _status = 'In Progress';
                                _isButtonClicked = true;
                              });
                              await prefs.setBool('btn_clicked_${task.id ?? "0"}', true);
                              await prefs.setString('task_status_${task.id ?? "0"}', 'In Progress');
                            } 
                            else if (_status == 'In Progress') {
                              if (isLastBoxChecked) {
                                await _saveChecklistToStorage(isSubmitReview: true);
                              } else {
                                await _saveChecklistToStorage(isSubmitReview: false);
                              }
                            }
                          }, 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor, 
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomFooter(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (MainScreen.navigatorKey.currentState != null) {
            MainScreen.navigatorKey.currentState!.changeTab(index);
          }
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
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
    } else if (value == 'In Progress') {
      badgeBgColor = const Color(0xFFEFF6FF);
      badgeTextColor = Colors.blue;
    } else if (value == 'Completed') {
      badgeBgColor = Colors.green.shade50;
      badgeTextColor = Colors.green;
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
}