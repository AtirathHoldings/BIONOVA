import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/task_item.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import 'main_screen.dart';
import '../services/api_service.dart';
import 'manage_team_screen.dart';
import '../models/employee_option.dart';
import '../widgets/employee_dropdown.dart';
import 'raise_request_screen.dart';
import '../widgets/reassign_icon.dart';

// ============================================================
// ✅ TASK DETAILS SCREEN
// ============================================================
class TaskDetailsScreen extends StatefulWidget {
  final TaskItem? task;
  final bool isIndividualTask;

  const TaskDetailsScreen({
    super.key,
    this.task,
    this.isIndividualTask = false,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  String _status = 'Open';
  String _rawDbStatus = 'OPEN'; // tracks actual DB status: SUBMIT_REVIEW, UNDER_REVIEW, etc.
  int _currentIndex = 2;
  bool _isDataLoaded = false;
  late TaskItem task;
  bool _isLoadingData = false;
  String _userRole = 'user';
  String _reviewerName = '';
  String _approverName = '';
  String _executorName = '';
  String _assignedByName = '';
  int _unreadNotificationCount = 0;
  int? _reviewerEmpId;
  int? _approverEmpId;
  int? _currentEmpId;

  int? _extractTaskNumericId() {
    if (widget.isIndividualTask) {
      if (task.rawData != null) {
        final rawId = task.rawData?['empTaskId'] ??
            task.rawData?['emp_task_id'] ??
            task.rawData?['id'] ??
            task.rawData?['taskId'] ??
            task.rawData?['task_id'];
        if (rawId != null) {
          final digits = rawId.toString().replaceAll(RegExp(r'[^\d]'), '');
          final parsed = int.tryParse(digits);
          if (parsed != null && parsed > 0) return parsed;
        }
      }
    } else {
      if (task.rawData != null) {
        final rawId = task.rawData?['taskId'] ??
            task.rawData?['task_id'] ??
            task.rawData?['liveTaskId'] ??
            task.rawData?['live_task_id'] ??
            task.rawData?['id'];
        if (rawId != null) {
          final digits = rawId.toString().replaceAll(RegExp(r'[^\d]'), '');
          final parsed = int.tryParse(digits);
          if (parsed != null && parsed > 0) return parsed;
        }
      }
    }
    if (task.id.isNotEmpty) {
      final digits = task.id.replaceAll(RegExp(r'[^\d]'), '').trim();
      final parsed = int.tryParse(digits);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  int? _extractDraftTaskId() {
    if (task.drftTaskId == null || task.drftTaskId!.isEmpty) return null;
    final str = task.drftTaskId!.replaceAll(RegExp(r'[^\d]'), '').trim();
    return int.tryParse(str);
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final unreadNotifications = await ApiService.getUnreadNotifications();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadNotifications.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notification count: $e');
    }
  }

  bool _isButtonClicked = false;

  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _assigneeNoteController = TextEditingController();
  final TextEditingController _approverNoteController = TextEditingController();
  final TextEditingController _reviewerNoteController = TextEditingController();

  bool _isEditingAssigneeRemarks = false;
  bool _isEditingApproverRemarks = false;
  bool _isEditingReviewerRemarks = false;
  String _tempAssigneeRemarks = '';
  String _tempApproverRemarks = '';
  String _tempReviewerRemarks = '';

  final Map<String, bool> _expandedRemarks = {
    'Project Remarks': false,
    'Milestone Remarks': false,
    'Task Remarks': false,
    'Executor Remarks': false,
    'Reviewer Remarks': false,
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

    if (text[pos - 1] == '\n') {
      final textBeforeCursor = text.substring(0, pos - 1);
      final lastNewlineIndex = textBeforeCursor.lastIndexOf('\n');
      final startOfLine = lastNewlineIndex == -1 ? 0 : lastNewlineIndex + 1;
      final prevLine = textBeforeCursor.substring(startOfLine);

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

      if (prevLine.startsWith('• ') || prevLine.startsWith('•')) {
        const insertText = '• ';
        final newText =
            text.substring(0, pos) + insertText + text.substring(pos);
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
          final newText =
              text.substring(0, pos) + insertText + text.substring(pos);
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
    if (task.tag == 'Critical' || task.isOverdue) {
      noteMessage = 'It will go to almost critical';
    } else if (task.tag == 'High') {
      noteMessage = 'This task has high priority and needs immediate action.';
    } else if (task.tag == 'Closed' || task.tag == 'Completed') {
      noteMessage = 'This task is successfully closed.';
    } else {
      noteMessage = 'Task is currently ${_status.toLowerCase()}.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(task.icon, color: task.iconColor, size: 22),
            const SizedBox(width: 8),
            Text(
              '${task.tag} Note',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          noteMessage,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _checklist = [];

  List<Map<String, dynamic>> _referenceTasks = [];
  List<EmployeeOption> _currentTaskTeam = [];
  List<EmployeeOption> _allEmployees = [];

  // Upload/Download State & Functions
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _uploadedDocuments = [];
  List<Map<String, dynamic>> _attachments = [];

  Future<void> _downloadFile(String fileName, String? atPath) async {
    if (atPath == null || atPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: No URL provided for $fileName'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final Uri uri = Uri.parse(atPath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
              const Text(
                'Upload Document',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('Uploading ${file.name}...')),
              ],
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.blue.shade700,
          ),
        );

        final double sizeInMb = (await file.length()) / (1024 * 1024);
        final String sizeStr = '${sizeInMb.toStringAsFixed(1)} MB';

        final uploadResult = await ApiService.uploadAttachment(
          taskId: _extractTaskNumericId()!,
          fileNm: file.name,
          atPath: file.path,
          atType: 'UPLOAD',
        );

        if (uploadResult != null && mounted) {
          final int fileId = uploadResult['fileId'] ?? 0;
          setState(() {
            _uploadedDocuments.add({
              'fileId': fileId,
              'fileName': file.name,
              'size': sizeStr,
              'icon': Icons.insert_drive_file,
              'iconColor': Colors.blue,
              'bgColor': const Color(0xFFEFF6FF),
              'atPath': uploadResult['atPath'] ?? uploadResult['url'] ?? '',
            });
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${file.name} uploaded successfully!'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Upload failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading document: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('Uploading $fileName...')),
              ],
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.blue.shade700,
          ),
        );

        final uploadResult = await ApiService.uploadAttachment(
          taskId: _extractTaskNumericId()!,
          fileNm: fileName,
          atPath: platformFile.path!,
          atType: 'UPLOAD',
        );

        if (uploadResult != null && mounted) {
          final int fileId = uploadResult['fileId'] ?? 0;
          setState(() {
            _uploadedDocuments.add({
              'fileId': fileId,
              'fileName': fileName,
              'size': sizeStr,
              'icon': fileIcon,
              'iconColor': iconColor,
              'bgColor': bgColor,
              'atPath': uploadResult['atPath'] ?? uploadResult['url'] ?? '',
            });
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $fileName uploaded successfully!'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Upload failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void dispose() {
    _noteController.dispose();
    _assigneeNoteController.dispose();
    _approverNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadChecklist() async {
    final taskId = _extractTaskNumericId();
    debugPrint('[TaskDetails] _loadChecklist starting for task.id=${task.id}, numId=$taskId, isIndividual=${widget.isIndividualTask}');

    try {
      List<Map<String, dynamic>> items = [];

      // 1) Primary API fetch if numId exists (fresh expanded items from backend DB)
      if (taskId != null && taskId > 0) {
        if (widget.isIndividualTask) {
          items = await ApiService.getIndividualChecklistItems(taskId);
          if (items.isEmpty) {
            items = await ApiService.getLiveChecklistItems(taskId);
          }
        } else {
          items = await ApiService.getLiveChecklistItems(taskId);
          if (items.isEmpty) {
            items = await ApiService.getIndividualChecklistItems(taskId);
          }
        }
      }

      // 2) Fallback to rawData payload if API returned empty
      if (items.isEmpty && task.rawData != null) {
        dynamic rawChecklists = task.rawData?['checklists'] ??
            task.rawData?['checklist'] ??
            task.rawData?['chkList'] ??
            task.rawData?['chk_list'] ??
            task.rawData?['items'] ??
            task.rawData?['chkItems'] ??
            task.rawData?['check_list'];

        if (rawChecklists is String && rawChecklists.trim().isNotEmpty) {
          try {
            rawChecklists = jsonDecode(rawChecklists);
          } catch (e) {
            debugPrint('[TaskDetails] Error parsing rawChecklists string: $e');
          }
        }

        if (rawChecklists is List && rawChecklists.isNotEmpty) {
          debugPrint('[TaskDetails] Found ${rawChecklists.length} items directly in task.rawData');
          items = rawChecklists.map<Map<String, dynamic>>((c) {
            if (c is Map) {
              return {
                'chkId': c['chkId'] ?? c['chk_id'] ?? c['id'],
                'title': (c['chkNm'] ?? c['chk_nm'] ?? c['title'] ?? c['name'] ?? c['chkDesc'] ?? c['chk_desc'] ?? c['text'] ?? '').toString(),
                'isDone': c['chkSts'] == true || c['chkSts'] == 1 || c['chkSts'] == 'true' || c['chkSts'] == 'Y' || c['isDone'] == true || c['chk_sts'] == true || c['chk_sts'] == 1 || c['chk_sts'] == 'true' || c['sts'] == true || c['sts'] == 1 || c['sts'] == 'Y',
                'seq': c['seqNo'] ?? c['seq_no'] ?? c['seq'] ?? 0,
              };
            }
            return {'title': c.toString(), 'isDone': false};
          }).toList();
        }
      }



      if (!mounted) return;

      int lastSeenChkId = 0;
      for (int i = 0; i < items.length; i++) {
        final id = items[i]['chkId'] ?? items[i]['chk_id'];
        if (id != null) {
          lastSeenChkId = (id as num).toInt();
        }
        items[i]['_sortKey'] = lastSeenChkId;
        items[i]['_originalIndex'] = i;
      }

      items.sort((a, b) {
        final keyA = (a['_sortKey'] as num).toInt();
        final keyB = (b['_sortKey'] as num).toInt();
        if (keyA != keyB) {
          return keyA.compareTo(keyB);
        }
        final idxA = (a['_originalIndex'] as num).toInt();
        final idxB = (b['_originalIndex'] as num).toInt();
        return idxA.compareTo(idxB);
      });

      setState(() {
        _checklist = items.map((item) {
          final rawTitle = item['title'] ??
              item['chkNm'] ??
              item['chk_nm'] ??
              item['chkDesc'] ??
              item['chk_desc'] ??
              item['name'] ??
              item['text'] ??
              item['taskChkNm'] ??
              '';
          return {
            'title': rawTitle.toString(),
            'isDone': item['isDone'] == true ||
                item['chkSts'] == true ||
                item['chkSts'] == 1 ||
                item['chkSts'] == 'true' ||
                item['chkSts'] == 'Y',
            'chkId': item['chkId'] ?? item['chk_id'],
          };
        }).where((e) => (e['title'] as String).trim().isNotEmpty).toList();
      });

      debugPrint('[TaskDetails] Checklist loaded successfully => ${_checklist.length} items: $_checklist');
    } catch (e) {
      debugPrint('Error loading checklist: $e');
      if (!mounted) return;
      setState(() {
        _checklist = [];
      });
    }
  }

  Future<void> _loadIndividualTaskProcessConfig() async {
    if (!widget.isIndividualTask) return;

    try {
      String reviewerName = '';
      String approverName = '';
      int? reviewerEmpId;
      int? approverEmpId;

      final revRaw = (widget.task?.rawData?['reviewer'] ?? widget.task?.rawData?['reviewerId'] ?? widget.task?.rawData?['reviewer_id'] ?? widget.task?.rawData?['reviewerEmpId'] ?? '').toString().trim();
      final revNm = (widget.task?.rawData?['reviewerNm'] ?? widget.task?.rawData?['reviewer_nm'] ?? '').toString().trim();
      
      reviewerEmpId = int.tryParse(revRaw);

      if (revNm.isNotEmpty) {
        reviewerName = revNm;
      } else {
        if (reviewerEmpId != null) {
          final rName = await ApiService.getEmployeeName(reviewerEmpId);
          reviewerName = (rName != null && rName.isNotEmpty) ? rName : '';
        } else if (revRaw.isNotEmpty) {
          reviewerName = revRaw;
        }
      }

      final appRaw = (widget.task?.rawData?['approver'] ?? widget.task?.rawData?['approverId'] ?? widget.task?.rawData?['approver_id'] ?? widget.task?.rawData?['approverEmpId'] ?? '').toString().trim();
      final appNm = (widget.task?.rawData?['approverNm'] ?? widget.task?.rawData?['approver_nm'] ?? '').toString().trim();
      
      approverEmpId = int.tryParse(appRaw);

      if (appNm.isNotEmpty) {
        approverName = appNm;
      } else {
        if (approverEmpId != null) {
          final aName = await ApiService.getEmployeeName(approverEmpId);
          approverName = (aName != null && aName.isNotEmpty) ? aName : '';
        } else if (appRaw.isNotEmpty) {
          approverName = appRaw;
        }
      }

      if (!mounted) return;
      setState(() {
        _reviewerName = reviewerName.isNotEmpty ? reviewerName : 'Not assigned';
        _approverName = approverName.isNotEmpty ? approverName : 'Not assigned';
        _reviewerEmpId = reviewerEmpId;
        _approverEmpId = approverEmpId;
      });
    } catch (e) {
      debugPrint('Error loading individual task process config: $e');
      if (!mounted) return;
      setState(() {
        _reviewerName = 'Not assigned';
        _approverName = 'Not assigned';
      });
    }
  }

  Future<void> _loadSavedData() async {
    setState(() {
      _isLoadingData = true;
    });
    debugPrint("==== DEBUG TASK RAW DATA ====");
    debugPrint(widget.task?.rawData?.toString());
    _fetchNotificationCount();

    try {
      final prefs = await SharedPreferences.getInstance();
      _userRole = prefs.getString('userRole') ?? 'user';
      final currentEmpId = prefs.getInt('currentEmpId') ?? await ApiService.getCurrentEmployeeId();
      if (mounted) {
        setState(() {
          _currentEmpId = currentEmpId;
        });
      }

      // ✅ Fetch fresh task details directly from backend
      final numId = _extractTaskNumericId();
      if (numId != null && numId > 0) {
        try {
          if (widget.isIndividualTask) {
            final freshRaw = await ApiService.getIndividualTaskById(numId);
            if (freshRaw != null) {
              final freshItem = TaskItem.fromIndividualTask(freshRaw, currentEmpId?.toString());
              if (mounted) {
                setState(() {
                  task = freshItem;
                  _status = freshItem.status;
                  _rawDbStatus = (freshRaw['taskSts'] ?? freshRaw['status'] ?? '').toString().toUpperCase();
                });
                await _loadChecklist();
              }
            }
          } else {
            final freshRaw = await ApiService.getLiveTask(numId);
            if (freshRaw != null) {
              final freshItem = TaskItem.fromLiveTask(freshRaw, currentEmpId?.toString());
              if (mounted) {
                setState(() {
                  task = freshItem;
                  _status = freshItem.status;
                  _rawDbStatus = (freshRaw['taskSts'] ?? freshRaw['status'] ?? '').toString().toUpperCase();
                });
                await _loadChecklist();
              }
            }
          }
        } catch (e) {
          debugPrint('Error fetching fresh backend task details: $e');
        }
      }

      final execRaw = (task.rawData?['empId'] ?? task.rawData?['empid'] ?? task.rawData?['assignedTo'] ?? '').toString().trim();
      final execNm = (task.rawData?['empNm'] ?? task.rawData?['executorNm'] ?? task.rawData?['assigneeNm'] ?? task.rawData?['emp_nm'] ?? '').toString().trim();
      
      if (execNm.isNotEmpty) {
        if (mounted) setState(() => _executorName = execNm);
      } else if (execRaw.isNotEmpty) {
        final execId = int.tryParse(execRaw);
        if (execId != null) {
          final exName = await ApiService.getEmployeeName(execId);
          if (mounted) {
            setState(() => _executorName = (exName != null && exName.isNotEmpty) ? exName : '');
          }
        } else {
          if (mounted) setState(() => _executorName = execRaw);
        }
      }

      final abRaw = (task.rawData?['assignedBy'] ?? task.rawData?['assigned_by'] ?? task.rawData?['crBy'] ?? task.rawData?['cr_by'] ?? '').toString().trim();
      final abNm = (task.rawData?['assignedByNm'] ?? task.rawData?['assignerNm'] ?? task.rawData?['assigned_by_nm'] ?? task.rawData?['crByNm'] ?? '').toString().trim();
      
      if (abNm.isNotEmpty) {
        if (mounted) setState(() => _assignedByName = abNm);
      } else if (abRaw.isNotEmpty) {
        final abId = int.tryParse(abRaw);
        if (abId != null) {
          final abName = await ApiService.getEmployeeName(abId);
          if (mounted) {
            setState(() => _assignedByName = (abName != null && abName.isNotEmpty) ? abName : '');
          }
        } else {
          if (mounted) setState(() => _assignedByName = abRaw);
        }
      }

      List<EmployeeOption> dbTeam = [];
      if (widget.isIndividualTask) {
        // Load team from local storage
        final savedTeamJson = prefs.getString('task_team_${task.id}');
        if (savedTeamJson != null) {
          final List<dynamic> decoded = jsonDecode(savedTeamJson);
          if (mounted) {
            setState(() {
              _currentTaskTeam = decoded
                  .map((item) => EmployeeOption.fromJson(item))
                  .toList();
            });
          }
        }

        await _loadIndividualTaskProcessConfig();
        await _loadChecklist();

        // Load attachments from DB for individual tasks
        try {
          final List<Map<String, dynamic>> dbAttachments =
              await ApiService.fetchAttachmentsForTask(
                taskId: _extractTaskNumericId()!,
              );
          debugPrint('[IndividualTask] Fetched ${dbAttachments.length} attachments for task ${task.id}');

          final List<Map<String, dynamic>> uploadsList = [];
          final List<Map<String, dynamic>> refsList = [];
          
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

            final mapped = {
              'fileId': att['fileId'],
              'fileName': fileName,
              'size': att['atType'] == 'UPLOAD' ? 'Uploaded' : 'Ref Doc',
              'icon': fileIcon,
              'iconColor': iconColor,
              'bgColor': bgColor,
              'atPath': att['atPath'] ?? '',
            };

            if (att['atType'] == 'UPLOAD') {
              uploadsList.add(mapped);
            } else {
              refsList.add(mapped);
            }
          }

          if (mounted) {
            setState(() {
              _attachments = refsList;
              _uploadedDocuments = uploadsList;
            });
          }
        } catch (e) {
          debugPrint('Error loading attachments for individual task: $e');
        }

        try {
          final history = await ApiService.getTaskHistory(_extractTaskNumericId()!);
          final executorId = int.tryParse((task.rawData?['empId'] ?? task.rawData?['empid'] ?? task.rawData?['assignedTo'] ?? '').toString());
          String? histExecutorNote;
          String? histReviewerNote;
          String? histApproverNote;
          for (var event in history) {
            final eId = int.tryParse(event['empId']?.toString() ?? '');
            final rem = event['remarks']?.toString();
            if (rem != null && rem.trim().isNotEmpty) {
              if (eId == executorId) histExecutorNote = rem;
              if (eId == _reviewerEmpId) histReviewerNote = rem;
              if (eId == _approverEmpId) histApproverNote = rem;
            }
          }

          final prefs = await SharedPreferences.getInstance();
          final String? savedAssigneeNote = prefs.getString('saved_assignee_note_${task.id}');
          final savedApproverNote = prefs.getString('saved_approver_note_${task.id}');
          final savedReviewerNote = prefs.getString('saved_reviewer_note_${task.id}');
          
          if (mounted) {
            setState(() {
              _assigneeNoteController.text = histExecutorNote ?? savedAssigneeNote ?? '';
              _approverNoteController.text = histApproverNote ?? savedApproverNote ?? '';
              _reviewerNoteController.text = histReviewerNote ?? savedReviewerNote ?? '';
            });
          }
        } catch (e) {
          debugPrint("Error loading notes: $e");
        }

        if (mounted) {
          setState(() {
            _status = task.status;
            _rawDbStatus = (task.rawData?['taskSts'] ?? task.rawData?['status'] ?? '').toString().toUpperCase();
            _isButtonClicked = (_status == 'In Progress');
            _isLoadingData = false;
          });
        }
        return;
      }
      try {
        final dbTask = await ApiService.getLiveTask(_extractTaskNumericId()!);
        if (dbTask != null) {
          final String? noteTxt = dbTask['noteTxt'] ?? dbTask['note_txt'];
          if (noteTxt != null && noteTxt.trim().isNotEmpty) {
            final List<String> employeeIds = noteTxt.split(',');
            final dbEmployees = await ApiService.getEmployees();
            for (final empId in employeeIds) {
              final match = dbEmployees.firstWhere(
                (emp) =>
                    emp['id']?.toString() == empId.trim() ||
                    emp['empId']?.toString() == empId.trim(),
                orElse: () => null,
              );
              if (match != null) {
                dbTeam.add(EmployeeOption.fromJson(match));
              }
            }
          }
        } else {
          final savedTeamJson = prefs.getString('task_team_${task.id}');
          if (savedTeamJson != null) {
            final List<dynamic> decoded = jsonDecode(savedTeamJson);
            dbTeam = decoded
                .map((item) => EmployeeOption.fromJson(item))
                .toList();
          }
        }
      } catch (e) {
        debugPrint("Error loading team from db: $e");
        final savedTeamJson = prefs.getString('task_team_${task.id}');
        if (savedTeamJson != null) {
          final List<dynamic> decoded = jsonDecode(savedTeamJson);
          dbTeam = decoded
              .map((item) => EmployeeOption.fromJson(item))
              .toList();
        }
      }

      if (mounted) {
        setState(() {
          _currentTaskTeam = dbTeam;
        });
      }

      // Checklist items are now fetched for both individual and live tasks
      await _loadChecklist();

      final dbEmployees = await ApiService.getEmployees();
      if (mounted) {
        setState(() {
          _allEmployees = dbEmployees
              .map((e) => EmployeeOption.fromJson(e))
              .toList();
        });
      }

      final drftId = task.drftTaskId != null
          ? _extractDraftTaskId()
          : null;
      final List<Map<String, dynamic>> dbAttachments =
          await ApiService.fetchAttachmentsForTask(
            taskId: _extractTaskNumericId()!,
            drftTaskId: drftId,
          );

      final List<Map<String, dynamic>> refs = [];
      final List<Map<String, dynamic>> uploads = [];

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

        final mapped = {
          'fileId': att['fileId'],
          'fileName': fileName,
          'size': 'Ref Doc',
          'icon': fileIcon,
          'iconColor': iconColor,
          'bgColor': bgColor,
          'atPath': att['atPath'] ?? '',
        };

        if (att['atType'] == 'UPLOAD' && att['isLive'] == true) {
          uploads.add(mapped);
        } else {
          refs.add(mapped);
        }
      }

      if (mounted) {
        setState(() {
          _attachments = refs;
          _uploadedDocuments = uploads;
        });
      }

      List<dynamic> configs = await ApiService.getLiveProcessConfig(
        _extractTaskNumericId()!,
      );
      if (configs.isEmpty && task.drftTaskId != null) {
        configs = await ApiService.getDraftProcessConfig(
          int.parse(task.drftTaskId!),
        );
      }
      // Log configs for debugging
      debugPrint('==== PROCESS CONFIGS FOR TASK ${task.id} ====');
      debugPrint('Configs: ${jsonEncode(configs)}');
      debugPrint('============================================');

      String? checkerName;
      String? reviewerName;
      int? reviewerEmpId;
      int? approverEmpId;
      for (final config in configs) {
        if (config is! Map) continue;

        final stepType = config['stepType']?.toString().toUpperCase();
        final rIdVal = config['rId'] ?? config['r_id'] ?? config['rid'];
        final ordrIdVal = config['ordrId'] ?? config['ordr_id'];
        final empIdVal = config['empId'] ?? config['emp_id'] ?? config['empid'];

        if (empIdVal != null) {
          final int empId = (empIdVal as num).toInt();
          final resolvedName = await ApiService.getEmployeeName(empId);
          if (resolvedName != null && resolvedName.isNotEmpty) {
            // Rule 1: Use rId to map roles (rId == 1 Reviewer, rId == 2 Approver)
            if (rIdVal != null) {
              final int rId = (rIdVal as num).toInt();
              if (rId == 1) {
                checkerName = resolvedName;
                reviewerEmpId = empId;
              } else if (rId == 2) {
                reviewerName = resolvedName;
                approverEmpId = empId;
              }
            }
            // Rule 2: Use ordrId to map roles
            else if (ordrIdVal != null) {
              final int ordrId = (ordrIdVal as num).toInt();
              if (ordrId == 1) {
                checkerName = resolvedName;
                reviewerEmpId = empId;
              } else if (ordrId == 2) {
                reviewerName = resolvedName;
                approverEmpId = empId;
              }
            }
            // Rule 3: Fallback to stepType
            else if (stepType != null) {
              if (stepType == 'CHECKER') {
                checkerName = resolvedName;
                reviewerEmpId = empId;
              } else if (stepType == 'REVIEWER' || stepType == 'APPROVER') {
                reviewerName = resolvedName;
                approverEmpId = empId;
              }
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          if (checkerName != null && checkerName.isNotEmpty) {
            _reviewerName = checkerName;
          }
          if (reviewerName != null && reviewerName.isNotEmpty) {
            _approverName = reviewerName;
          }
          _reviewerEmpId = reviewerEmpId;
          _approverEmpId = approverEmpId;
        });
      }
    } catch (e) {
      print("Error loading checklist: $e");
    }

    try {
      final history = await ApiService.getTaskHistory(_extractTaskNumericId()!);
      final executorId = int.tryParse((task.rawData?['empId'] ?? task.rawData?['empid'] ?? task.rawData?['assignedTo'] ?? '').toString());
      String? histExecutorNote;
      String? histReviewerNote;
      String? histApproverNote;
      for (var event in history) {
        final eId = int.tryParse(event['empId']?.toString() ?? '');
        final rem = event['remarks']?.toString();
        if (rem != null && rem.trim().isNotEmpty) {
          if (eId == executorId) histExecutorNote = rem;
          if (eId == _reviewerEmpId) histReviewerNote = rem;
          if (eId == _approverEmpId) histApproverNote = rem;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final String? savedAssigneeNote = prefs.getString('saved_assignee_note_${task.id}');
      final savedApproverNote = prefs.getString('saved_approver_note_${task.id}');
      final savedReviewerNote = prefs.getString('saved_reviewer_note_${task.id}');
      
      setState(() {
        _assigneeNoteController.text = histExecutorNote ?? savedAssigneeNote ?? '';
        _approverNoteController.text = histApproverNote ?? savedApproverNote ?? '';
        _reviewerNoteController.text = histReviewerNote ?? savedReviewerNote ?? '';
      });
    } catch (e) {
      print("Error loading notes: $e");
    }

    setState(() {
      _status = task.status;
      _rawDbStatus = (task.rawData?['taskSts'] ?? task.rawData?['status'] ?? '').toString().toUpperCase();
      _isButtonClicked = (_status == 'In Progress');
      _isLoadingData = false;
    });
  }

  Future<void> _startTask() async {
    setState(() {
      _isLoadingData = true;
    });
    try {
      final taskId = _extractTaskNumericId()!;

      if (widget.isIndividualTask) {
        // Individual tasks: update via individual-tasks status patch endpoint
        final success = await ApiService.updateIndividualTaskStatus(taskId, 'WIP');
        if (!success) throw Exception('Failed to update task status');
      } else {
        // Project tasks: update via project-live endpoint
        final success = await ApiService.updateProjectTaskStatus(taskId, 'WIP');
        if (!success) {
          throw Exception('Failed to update project task status to WIP');
        }
      }

      setState(() {
        _status = 'In Progress';
        _isButtonClicked = true;
      });
      await _updateLocalTaskStatus('In Progress');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Task started! Status updated to In Progress.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        if (mounted) {
          setState(() {
            _isLoadingData = false;
          });
        }
      }
    }
  }

  void _confirmSubmission(bool hasProcess) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Submission'),
          content: Text(
            hasProcess 
              ? 'Are you sure you want to submit this task for review? Please ensure all documents and checklist items are verified.'
              : 'Are you sure you want to mark this task as complete? Please ensure all documents and checklist items are verified.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (hasProcess) {
                  _submitTask();
                } else {
                  _markTaskComplete();
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitTask() async {
    setState(() {
      _isLoadingData = true;
    });
    try {
      final taskId = _extractTaskNumericId()!;

      if (widget.isIndividualTask) {
        if (_status == 'Rework') {
          await ApiService.resubmitTask(taskId, _assigneeNoteController.text);
        } else {
          await ApiService.submitTask(taskId, _assigneeNoteController.text);
        }
      } else {
        // Project task: update status via project-live endpoint
        final success = await ApiService.updateProjectTaskStatus(taskId, 'SUBMIT_REVIEW');
        if (!success) {
          throw Exception('Failed to submit project task for review');
        }
      }

      setState(() {
        _status = 'Under Review';
        _rawDbStatus = 'SUBMIT_REVIEW';
      });
      await _updateLocalTaskStatus('Under Review');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Task submitted for review!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _markTaskComplete() async {
    setState(() {
      _isLoadingData = true;
    });
    try {
      final taskId = _extractTaskNumericId()!;

      if (widget.isIndividualTask) {
        final success = await ApiService.updateIndividualTaskStatus(taskId, 'CLOSED');
        if (!success) {
          throw Exception('Failed to mark individual task as closed');
        }
      } else {
        final success = await ApiService.updateProjectTaskStatus(taskId, 'CLOSED');
        if (!success) {
          throw Exception('Failed to mark project task as closed');
        }
      }

      setState(() {
        _status = 'Closed';
        _rawDbStatus = 'CLOSED';
      });
      await _updateLocalTaskStatus('Closed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Task marked as closed!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }


  // ── Deny action — opens full page RaiseRequestScreen ──────
  Future<void> _showDenyDialog({required bool isChecker}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RaiseRequestScreen(
          task: task,
          isChecker: isChecker,
          initialRemarks: isChecker ? _reviewerNoteController.text : _approverNoteController.text,
        ),
      ),
    );

    if (result == null || result == false || !mounted) return;

    if (result is Map) {
      final String remarks = (result['remarks'] ?? '').toString();
      if (isChecker) {
        _reviewerNoteController.text = remarks;
      } else {
        _approverNoteController.text = remarks;
      }

      if (result['submitted'] == true) {
        final actionType = (result['action'] ?? 'REASSIGN').toString();
        final newStatus = actionType == 'REWORK' ? 'Rework' : 'Reassigned';
        final newRaw = actionType == 'REWORK' ? 'REWORK' : 'REASSIGN';
        setState(() {
          _status = newStatus;
          _rawDbStatus = newRaw;
        });
        await _updateLocalTaskStatus(newStatus);
        return;
      }

      setState(() => _isLoadingData = true);
      try {
        final taskId = _extractTaskNumericId()!;
        final actionType = (result['action'] ?? 'REASSIGN').toString();
        final rejType = actionType == 'REWORK' ? 'REWORK' : 'REASSIGN';
        final displaySts = actionType == 'REWORK' ? 'Rework' : 'Reassigned';

        if (isChecker) {
          try {
            await ApiService.checkerAction(taskId, 'NO', remarks, rejectionType: rejType);
          } catch (_) {
            await ApiService.updateProjectTaskStatus(taskId, rejType);
          }
        } else {
          try {
            await ApiService.reviewerAction(taskId, 'NO', remarks, rejectionType: rejType);
          } catch (_) {
            await ApiService.updateProjectTaskStatus(taskId, rejType);
          }
        }

        setState(() {
          _status = displaySts;
          _rawDbStatus = rejType;
        });
        await _updateLocalTaskStatus(displaySts);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(actionType == 'REWORK' ? '⚠️ Denied! Task sent back for Rework.' : '🔁 Denied! Task reassigned to executor.'),
              backgroundColor: actionType == 'REWORK' ? const Color(0xFFF97316) : const Color(0xFF4F46E5),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error in deny dialog handler: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingData = false);
        }
      }
    }
  }


  Future<void> _handleCheckerAction(String action) async {
    if (action == 'REJECT') {
      await _showDenyDialog(isChecker: true);
      return;
    }
    setState(() => _isLoadingData = true);
    try {
      final taskId = _extractTaskNumericId()!;
      final hasApprover = _approverEmpId != null || 
          (task.approver != null && task.approver.toString().isNotEmpty) ||
          (task.rawData?['approver'] != null && task.rawData!['approver'].toString().isNotEmpty) ||
          (task.rawData?['approverId'] != null || task.rawData?['approver_id'] != null);

      final String finalStatus = hasApprover ? 'WIP' : 'CLOSED';
      final String finalProcess = hasApprover ? 'PENDING_APPROVER' : 'NONE';
      final String displayStatus = hasApprover ? 'Under Review' : 'Closed';

      if (widget.isIndividualTask) {
        final Map<String, dynamic> rawObj = Map<String, dynamic>.from(task.rawData ?? {});
        rawObj['taskSts'] = finalStatus;
        rawObj['prcsYesActn'] = finalProcess;
        if (!hasApprover) {
          rawObj['actCmpDt'] = DateTime.now().toIso8601String().split('T')[0];
        }

        await ApiService.updateIndividualTask(taskId, rawObj);
      } else {
        try {
          await ApiService.checkerAction(taskId, 'YES', _reviewerNoteController.text);
        } catch (_) {
          await ApiService.updateProjectTaskStatus(taskId, finalStatus);
        }
      }

      if (task.rawData != null) {
        task.rawData!['taskSts'] = finalStatus;
        task.rawData!['prcsYesActn'] = finalProcess;
        task.rawData!['prcs_yes_actn'] = finalProcess;
      }

      setState(() {
        _status = displayStatus;
        _rawDbStatus = finalStatus;
      });
      await _updateLocalTaskStatus(displayStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasApprover ? '✅ Approved! Task moved to Approver.' : '✅ Approved! Task closed.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _handleReviewerAction(String action) async {
    if (action == 'REJECT') {
      await _showDenyDialog(isChecker: false);
      return;
    }
    setState(() => _isLoadingData = true);
    try {
      final taskId = _extractTaskNumericId()!;
      if (widget.isIndividualTask) {
        final Map<String, dynamic> rawObj = Map<String, dynamic>.from(task.rawData ?? {});
        rawObj['taskSts'] = 'CLOSED';
        rawObj['prcsYesActn'] = 'NONE';
        rawObj['actCmpDt'] = DateTime.now().toIso8601String().split('T')[0];

        await ApiService.updateIndividualTask(taskId, rawObj);
        await ApiService.updateIndividualTaskStatus(taskId, 'CLOSED');
      } else {
        try {
          await ApiService.reviewerAction(taskId, 'YES', _approverNoteController.text);
        } catch (_) {
          await ApiService.updateProjectTaskStatus(taskId, 'CLOSED');
        }
      }

      if (task.rawData != null) {
        task.rawData!['taskSts'] = 'CLOSED';
        task.rawData!['prcsYesActn'] = 'NONE';
        task.rawData!['prcs_yes_actn'] = 'NONE';
      }

      setState(() {
        _status = 'Closed';
        _rawDbStatus = 'CLOSED';
      });
      await _updateLocalTaskStatus('Closed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Approved! Task closed.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _saveRemarksToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'saved_assignee_note_${task.id}',
      _assigneeNoteController.text,
    );
    await prefs.setString(
      'saved_approver_note_${task.id}',
      _approverNoteController.text,
    );
    await prefs.setString(
      'saved_reviewer_note_${task.id}',
      _reviewerNoteController.text,
    );
  }

  Future<void> _updateStatus(
    String newStatus,
    String displayStatus,
    String successMessage,
  ) async {
    setState(() {
      _isLoadingData = true;
    });
    try {
      final taskId = _extractTaskNumericId()!;

      if (widget.isIndividualTask) {
        final success = await ApiService.updateIndividualTaskStatus(taskId, newStatus);
        if (!success) {
          throw Exception('Failed to update task status');
        }
      } else {
        final success = await ApiService.updateProjectTaskStatus(taskId, newStatus);
        if (!success) {
          throw Exception('Failed to update project task status');
        }
      }
      
      setState(() {
        _status = displayStatus;
      });
      await _updateLocalTaskStatus(displayStatus);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        if (mounted) {
          setState(() {
            _isLoadingData = false;
          });
        }
      }
    }
  }

  Future<void> _updateLocalTaskStatus(String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final taskDataStr = prefs.getString('task_item_data_${task.id}');
      if (taskDataStr != null) {
        final Map<String, dynamic> taskJson = jsonDecode(taskDataStr);
        taskJson['status'] = newStatus;
        if (newStatus == 'Closed' || newStatus == 'Completed') {
          taskJson['tag'] = 'Closed';
          taskJson['tagColor'] = Colors.green.value;
          taskJson['tagBg'] = const Color(0xFFDCFCE7).value;
          taskJson['icon'] = Icons.task_alt.codePoint;
          taskJson['iconColor'] = Colors.green.value;
          taskJson['iconBg'] = const Color(0xFFDCFCE7).value;
        } else if (newStatus == 'In Progress') {
          taskJson['tag'] = 'High';
          taskJson['tagColor'] = const Color(0xFFEA580C).value;
          taskJson['tagBg'] = const Color(0xFFFFF7ED).value;
          taskJson['icon'] = Icons.shield_outlined.codePoint;
          taskJson['iconColor'] = const Color(0xFFEA580C).value;
          taskJson['iconBg'] = const Color(0xFFFFF7ED).value;
        } else if (newStatus == 'Rework') {
          taskJson['tag'] = 'Critical';
          taskJson['tagColor'] = const Color(0xFFE11D48).value;
          taskJson['tagBg'] = const Color(0xFFFFF1F2).value;
          taskJson['icon'] = Icons.assignment_outlined.codePoint;
          taskJson['iconColor'] = const Color(0xFFE11D48).value;
          taskJson['iconBg'] = const Color(0xFFFFF1F2).value;
        }
        await prefs.setString(
          'task_item_data_${task.id}',
          jsonEncode(taskJson),
        );
      }
    } catch (_) {}
  }

  Future<void> _enableEditing() async {
    setState(() {
      _status = 'In Progress';
      _isButtonClicked = true;
    });
    await _updateLocalTaskStatus('In Progress');

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
    final s = status.toUpperCase();
    if (s == 'CLOSED' || s == 'COMPLETED') return const Color(0xFF16A34A); // GREEN
    if (s == 'IN PROGRESS' || s == 'UNDER REVIEW' || s == 'REWORK') return const Color(0xFFF59E0B); // AMBER
    if (s == 'HOLD') return const Color(0xFF7C3AED); // PURPLE
    return const Color(0xFF2563EB); // BLUE (OPEN)
  }

  // ✅ Reusable Employee Dropdown using SearchableDropdown
  Widget _buildEmployeeDropdown({
    required String label,
    required EmployeeOption? selected,
    required ValueChanged<EmployeeOption?> onChanged,
    bool isRequired = true,
  }) {
    // We already have EmployeeOption list in _allEmployees
    return EmployeeDropdown(
      items: _allEmployees,
      selectedItem: selected,
      onChanged: onChanged,
      label: label,
      isRequired: isRequired,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (widget.task != null) {
        task = widget.task!;
        _status = task.status;
        _rawDbStatus = (task.rawData?['taskSts'] ?? task.rawData?['status'] ?? '').toString().toUpperCase();
      } else if (args is TaskItem) {
        task = args;
        _status = task.status;
        _rawDbStatus = (task.rawData?['taskSts'] ?? task.rawData?['status'] ?? '').toString().toUpperCase();
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
          reviewer: '',
          approver: '',
        );
        _status = task.status;
      }
      _isDataLoaded = true;
      _reviewerName = task.reviewer ?? '';
      _approverName = task.approver ?? '';
      _loadSavedData();
    }
  }

  @override
  Widget build(BuildContext context) {

    int completedCount = _checklist
        .where((item) => item['isDone'] == true)
        .length;
    bool isLastBoxChecked =
        _checklist.isNotEmpty && _checklist.last['isDone'] == true;



    final executorId = int.tryParse((task.rawData?['empId'] ?? task.rawData?['empid'] ?? task.rawData?['assignedTo'] ?? '').toString());

    final bool isUserReviewer = (_currentEmpId != null && _reviewerEmpId != null && _currentEmpId == _reviewerEmpId) ||
        (task.reviewer != null && _currentEmpId != null && task.reviewer.toString() == _currentEmpId.toString()) ||
        (_userRole.toLowerCase() == 'checker' || _userRole.toLowerCase() == 'reviewer');

    final bool isUserApprover = (_currentEmpId != null && _approverEmpId != null && _currentEmpId == _approverEmpId) ||
        (task.approver != null && _currentEmpId != null && task.approver.toString() == _currentEmpId.toString()) ||
        (_userRole.toLowerCase() == 'approver');

    String displayRole = 'Executor';
    String actionMessage = task.priority;

    if (_isLoadingData) {
      displayRole = 'Loading...';
    } else if (isUserReviewer) {
      displayRole = 'Reviewer';
    } else if (isUserApprover) {
      displayRole = 'Approver';
    } else if (_currentEmpId != null && (_currentEmpId == executorId || _currentTaskTeam.any((emp) => emp.id == _currentEmpId))) {
      displayRole = 'Executor';
    } else {
      if (_userRole.toLowerCase() == 'checker' || _userRole.toLowerCase() == 'reviewer') {
        displayRole = 'Reviewer';
      } else if (_userRole.toLowerCase() == 'approver') {
        displayRole = 'Approver';
      } else {
        displayRole = 'Executor';
      }
    }

    final String currentProcess = (task.rawData?['prcsYesActn'] ??
            task.rawData?['prcs_yes_actn'] ??
            task.rawData?['prcsActn'] ??
            task.rawData?['prcs_actn'] ??
            task.rawData?['subStatus'] ??
            task.rawData?['sub_status'] ??
            '')
        .toString()
        .toUpperCase()
        .trim();

    final rawSts = task.rawData?['taskSts'] ?? task.rawData?['task_sts'] ?? task.rawData?['status'] ?? task.rawData?['taskStatus'];
    String rawStsStr = '';
    if (rawSts is Map) {
      rawStsStr = (rawSts['statusNm'] ?? rawSts['status_nm'] ?? rawSts['statusId'] ?? '').toString();
    } else if (rawSts != null) {
      rawStsStr = rawSts.toString();
    }

    final bool isClosedTask = _status == 'Closed' ||
        _status == 'Completed' ||
        task.status == 'Closed' ||
        task.status == 'Completed' ||
        rawStsStr.toUpperCase().contains('CLOSED') ||
        rawStsStr.toUpperCase().contains('COMPLETED') ||
        (rawSts is Map && (rawSts['statusId'] == 4 || rawSts['status_id'] == 4));

    final String mainStatus = isClosedTask
        ? 'Closed'
        : (_status == 'Open' || _status == 'Pending')
            ? 'Open'
            : 'In Progress';

    String? subStatusText;
    if (!isClosedTask) {
      if (currentProcess == 'PENDING_REVIEWER') {
        subStatusText = 'Under Review (Reviewer)';
      } else if (currentProcess == 'PENDING_APPROVER') {
        subStatusText = 'Under Review (Approver)';
      } else if (currentProcess == 'REASSIGN' || currentProcess == 'REASSIGNED' || _status == 'Reassigned') {
        subStatusText = 'Reassigned';
      } else if (currentProcess == 'REWORK' || _status == 'Rework') {
        subStatusText = 'Rework Required';
      } else if (_status == 'Under Review') {
        subStatusText = 'Under Review';
      }
    }

    final Color badgeBg = Colors.white;
    final Color badgeTextColor = task.tagColor;
    final Color badgeBorderColor = task.tagColor.withValues(alpha: 0.3);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: CustomHeader(
        title: 'Task Details',
        automaticallyImplyLeading: false,
        notificationCount: _unreadNotificationCount,
        onNotificationTap: () async {
          await Navigator.pushNamed(context, '/notifications');
          _fetchNotificationCount();
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
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: Color(0xFF1E293B),
                    ),
                    label: const Text(
                      'Back',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_status != 'Under Review' && _status != 'Closed' && _status != 'Completed')
                    TextButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageTeamScreen(task: task),
                          ),
                        );
                        _loadSavedData();
                      },
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.deepPurple,
                      ),
                      label: const Text(
                        'Team',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        backgroundColor: Colors.deepPurple.withOpacity(0.08),
                        side: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.2),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
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
                  border: Border.all(
                    color: task.tagColor.withOpacity(0.2),
                    width: 1,
                  ),
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
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(task.icon, color: task.iconColor, size: 28),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (actionMessage.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: badgeBorderColor),
                            ),
                            child: Text(
                              actionMessage,
                              style: TextStyle(
                                color: badgeTextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Meta Information Card
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
                    // ============================================================
                    // ✅ CONDITIONAL PROJECT & MILESTONE / TASK CODE ROWS
                    // ============================================================
                    if (!widget.isIndividualTask) ...[
                      _buildMetaRow(
                        'Project',
                        Icons.folder_open_outlined,
                        task.projectName?.isNotEmpty == true
                            ? task.projectName!
                            : ' - ',
                        isValuePurple: true,
                      ),
                      _buildMetaRow(
                        'Milestone',
                        Icons.layers_outlined,
                        task.milestoneName?.isNotEmpty == true
                            ? task.milestoneName!
                            : ' - ',
                        isValuePurple: true,
                      ),
                    ] else ...[
                      _buildMetaRow(
                        'Task Name',
                        Icons.assignment_outlined,
                        task.title.isNotEmpty ? task.title : ' - ',
                        isValuePurple: true,
                      ),
                      _buildMetaRow(
                        'Task Code',
                        Icons.tag_outlined,
                        task.taskCode.isNotEmpty ? task.taskCode : ' - ',
                        isValuePurple: true,
                      ),
                    ],

                    _buildMetaRow(
                      'Your Role',
                      Icons.person_outline,
                      displayRole,
                      isStatusBadge: true,
                    ),
                    _buildMetaRow(
                      'Start Date',
                      Icons.date_range_outlined,
                      task.startDate ?? 'No Date',
                    ),
                    _buildMetaRow(
                      'Due Date',
                      Icons.calendar_today_outlined,
                      task.endDate ?? task.date,
                      isValueRed: task.date == 'Today',
                    ),
                     if (widget.isIndividualTask && (_isLoadingData || (_assignedByName.trim().isNotEmpty && !_assignedByName.toLowerCase().contains('not assigned') && _assignedByName.toLowerCase() != 'n/a')))
                      _buildMetaRow(
                        'Assigned By',
                        Icons.assignment_ind_outlined,
                        _isLoadingData ? 'Loading...' : _assignedByName,
                      ),
                    if (displayRole != 'Executor' && (_isLoadingData || (_executorName.trim().isNotEmpty && !_executorName.toLowerCase().contains('not assigned') && _executorName.toLowerCase() != 'n/a')))
                      _buildMetaRow(
                        'Executor',
                        Icons.person_outline,
                        _isLoadingData ? 'Loading...' : _executorName,
                      ),
                    if (displayRole != 'Reviewer' && (_isLoadingData || (_reviewerName.trim().isNotEmpty && !_reviewerName.toLowerCase().contains('not assigned') && _reviewerName.toLowerCase() != 'n/a')))
                      _buildMetaRow(
                        'Reviewer',
                        Icons.rate_review_outlined,
                        _isLoadingData ? 'Loading...' : _reviewerName,
                      ),
                    if (displayRole != 'Approver' && (_isLoadingData || (_approverName.trim().isNotEmpty && !_approverName.toLowerCase().contains('not assigned') && _approverName.toLowerCase() != 'n/a')))
                      _buildMetaRow(
                        'Approver',
                        Icons.verified_outlined,
                        _isLoadingData ? 'Loading...' : _approverName,
                      ),
                    _buildMetaRow(
                      'Status',
                      Icons.radio_button_checked,
                      mainStatus,
                      isStatusBadge: true,
                    ),
                    if (subStatusText != null)
                      _buildMetaRow(
                        'Process Status',
                        Icons.sync,
                        subStatusText,
                        isStatusBadge: true,
                      ),
                    _buildTeamAddedMetaRow(),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.description ??
                              'General task evaluation, quality documentation compliance, and regular milestone checks are required for this activity.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                            height: 1.5,
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.0),
                          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ),

                        // Reference Remarks - Only Task Remarks, Executor Remarks, Approver Remarks
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reference Remarks',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (!widget.isIndividualTask) ...[
                              _buildRemarkSection(
                                'Project Remarks',
                                _buildRemarksContentList(
                                  task.projectRemarks ?? '',
                                  const Color(0xFFEA580C),
                                ),
                                const Color(0xFFEA580C),
                              ),
                              _buildRemarkSection(
                                'Milestone Remarks',
                                _buildRemarksContentList(
                                  task.milestoneRemarks ?? '',
                                  const Color(0xFF2563EB),
                                ),
                                const Color(0xFF2563EB),
                              ),
                            ],
                            _buildRemarkSection(
                              'Task Remarks',
                              _buildRemarksContentList(
                                task.taskRemarks ?? '',
                                const Color(0xFF10B981),
                              ),
                              const Color(0xFF10B981),
                            ),
                            _buildRemarkSection(
                              'Executor Remarks',
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
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                '✅ Executor remarks saved successfully!',
                                              ),
                                              backgroundColor: Colors.green,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      onCancel: () {
                                        setState(() {
                                          _assigneeNoteController.text =
                                              _tempAssigneeRemarks;
                                          _isEditingAssigneeRemarks = false;
                                        });
                                      },
                                    )
                                  : ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: _assigneeNoteController,
                                      builder: (context, value, _) =>
                                          _buildRemarksContentWithEdit(
                                            title: 'Executor Remarks',
                                            content: value.text,
                                            themeColor: const Color(0xFF7C3AED),
                                            canEdit: displayRole == 'Executor',
                                            onEditPressed: () {
                                              setState(() {
                                                _tempAssigneeRemarks =
                                                    _assigneeNoteController
                                                        .text;
                                                _isEditingAssigneeRemarks =
                                                    true;
                                              });
                                            },
                                          ),
                                    ),
                              const Color(0xFF7C3AED),
                            ),
                            if (displayRole != 'Executor' || _reviewerNoteController.text.trim().isNotEmpty)
                              _buildRemarkSection(
                                'Reviewer Remarks',
                                _isEditingReviewerRemarks
                                    ? _buildRemarksEditor(
                                        controller: _reviewerNoteController,
                                        themeColor: const Color(0xFF0EA5E9),
                                        onSave: () async {
                                          await _saveRemarksToStorage();
                                          setState(() {
                                            _isEditingReviewerRemarks = false;
                                          });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('✅ Reviewer remarks saved successfully!'),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                        onCancel: () {
                                          setState(() {
                                            _reviewerNoteController.text = _tempReviewerRemarks;
                                            _isEditingReviewerRemarks = false;
                                          });
                                        },
                                      )
                                    : ValueListenableBuilder<TextEditingValue>(
                                        valueListenable: _reviewerNoteController,
                                        builder: (context, value, _) =>
                                            _buildRemarksContentWithEdit(
                                              title: 'Reviewer Remarks',
                                              content: value.text,
                                              themeColor: const Color(0xFF0EA5E9),
                                              canEdit: displayRole == 'Reviewer',
                                              onEditPressed: () {
                                                setState(() {
                                                  _tempReviewerRemarks = _reviewerNoteController.text;
                                                  _isEditingReviewerRemarks = true;
                                                });
                                              },
                                            ),
                                      ),
                                const Color(0xFF0EA5E9),
                              ),
                            if (displayRole != 'Executor' || _approverNoteController.text.trim().isNotEmpty)
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
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '✅ Approver remarks saved successfully!',
                                                ),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                        onCancel: () {
                                          setState(() {
                                            _approverNoteController.text =
                                                _tempApproverRemarks;
                                            _isEditingApproverRemarks = false;
                                          });
                                        },
                                      )
                                    : ValueListenableBuilder<TextEditingValue>(
                                        valueListenable:
                                            _approverNoteController,
                                        builder: (context, value, _) =>
                                            _buildRemarksContentWithEdit(
                                              title: 'Approver Remarks',
                                              content: value.text,
                                              themeColor: const Color(
                                                0xFFE11D48,
                                              ),
                                              canEdit: displayRole == 'Approver',
                                              onEditPressed: () {
                                                setState(() {
                                                  _tempApproverRemarks =
                                                      _approverNoteController
                                                          .text;
                                                  _isEditingApproverRemarks =
                                                      true;
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
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: const EdgeInsets.only(top: 8),
                            title: const Text(
                              'Attachments',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            iconColor: const Color(0xFF64748B),
                            collapsedIconColor: const Color(0xFF64748B),
                            children: _attachments.map((ref) {
                              return _buildAttachmentTile(
                                ref['fileName'] ?? '',
                                ref['size'] ?? '',
                                ref['icon'] as IconData? ??
                                    Icons.description_outlined,
                                ref['iconColor'] as Color? ?? Colors.blue,
                                ref['bgColor'] as Color? ??
                                    const Color(0xFFEFF6FF),
                                atPath: ref['atPath'] as String?,
                                showDownload: true,
                              );
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
                                const Text(
                                  'Documents',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                if (displayRole == 'Executor' && (_status == 'In Progress' || _status == 'Rework')) 
                                  ElevatedButton.icon(
                                    onPressed: _showUploadOptions,
                                    icon: const Icon(
                                    Icons.upload_file_outlined,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'Upload',
                                    style: TextStyle(
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
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._uploadedDocuments.map((doc) {
                              final int? fId = doc['fileId'] as int?;
                              return _buildAttachmentTile(
                                doc['fileName']!,
                                doc['size']!,
                                doc['icon'] as IconData,
                                doc['iconColor'] as Color,
                                doc['bgColor'] as Color,
                                atPath: doc['atPath'] as String?,
                                showDownload: true,
                                onDelete: (fId == null || displayRole != 'Executor')
                                    ? null
                                    : () async {
                                        final bool?
                                        confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                              'Delete Document',
                                            ),
                                            content: const Text(
                                              'Are you sure you want to delete this document?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          final success =
                                              await ApiService.deleteAttachment(
                                                fId,
                                              );
                                          if (success) {
                                            setState(() {
                                              _uploadedDocuments.remove(doc);
                                            });
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    '✅ Document deleted successfully!',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }
                                          } else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    '❌ Failed to delete document.',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

                // 3. Checklist Card (ALWAYS VISIBLE FOR ALL TASKS AND ROLES)
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Checklist',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '$completedCount/${_checklist.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFE2E8F0)),
                    if (_checklist.isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No checklist found',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ] else ...[
                      ...List.generate(_checklist.length, (index) {
                        final item = _checklist[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (displayRole != 'Executor') return;
                                  if (_status == 'Closed' || _status == 'Completed' || _status == 'Under Review') return;

                                  if (item['isDone']) {
                                    final int? chkId = item['chkId'];
                                    if (chkId != null) {
                                      ApiService.reopenChecklistItem(chkId);
                                    }
                                    setState(() {
                                      item['isDone'] = false;
                                    });
                                  } else {
                                    bool canCheck = true;
                                    if (index == _checklist.length - 1) {
                                      for (int i = 0; i < index; i++) {
                                        if (!_checklist[i]['isDone']) {
                                          canCheck = false;
                                          break;
                                        }
                                      }
                                    }

                                    if (canCheck) {
                                      final int? chkId = item['chkId'];
                                      if (chkId != null) {
                                        ApiService.completeChecklistItem(chkId);
                                      }
                                      setState(() {
                                        item['isDone'] = true;
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            '⚠️ Please complete all previous tasks before checking the final one!',
                                          ),
                                          backgroundColor: Colors.orange,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Icon(
                                  item['isDone']
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: item['isDone']
                                      ? Colors.green
                                      : Colors.grey[400],
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item['title'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: item['isDone'] ? const Color(0xFF64748B) : const Color(0xFF1E293B),
                                    fontWeight: FontWeight.w500,
                                    decoration: item['isDone'] ? TextDecoration.lineThrough : TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ============================================================
              // 4. WORKFLOW ACTION SECTION (outer Column level)
              // ============================================================
              if (_isLoadingData)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                  ),
                )
              else
                _buildWorkflowActionBar(
                  isLastBoxChecked: isLastBoxChecked,
                  displayRole: displayRole,
                  isClosedTask: isClosedTask,
                ),

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

  // ============================================================
  // ✅ WORKFLOW ACTION BAR
  // ============================================================
  Widget _buildWorkflowActionBar({
    required bool isLastBoxChecked,
    required String displayRole,
    required bool isClosedTask,
  }) {
    // ── Closed ──────────────────────────────────────────────
    if (isClosedTask) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'Task Closed Successfully!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    final bool isAllChecklistsDone = _checklist.isNotEmpty && 
                                     _checklist.every((item) => item['isDone'] == true);

    final bool isTaskInReviewableState = _status != 'Closed' && _status != 'Completed';

    final String currentProcess = (task.rawData?['prcsYesActn'] ??
            task.rawData?['prcs_yes_actn'] ??
            task.rawData?['prcsActn'] ??
            task.rawData?['prcs_actn'] ??
            task.rawData?['subStatus'] ??
            task.rawData?['sub_status'] ??
            '')
        .toString()
        .toUpperCase()
        .trim();

    // ── Reviewer sees task for review ────────
    if (displayRole == 'Reviewer' && isTaskInReviewableState) {
      if (currentProcess == 'PENDING_APPROVER') {
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Color(0xFF7C3AED), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Approved by Reviewer • Pending Approver',
                    style: TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔔 Reminder sent to Approver!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_active_outlined, size: 18),
                label: const Text('Send Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED),
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        );
      }

      return _buildApproveRejectRow(
        label: 'Reviewer Actions',
        approveLabel: 'Approve',
        rejectLabel: 'Denied',
        approveIcon: Icons.thumb_up_rounded,
        rejectIcon: Icons.cancel_rounded,
        onApprove: () => _handleCheckerAction('APPROVE'),
        onReject: () => _handleCheckerAction('REJECT'),
      );
    }

    // ── Approver sees task for approval ──────────────────
    if (displayRole == 'Approver' && isTaskInReviewableState) {
      final bool hasReviewer = (_reviewerEmpId != null && _reviewerEmpId != 0) ||
          (task.reviewer != null && task.reviewer!.isNotEmpty && task.reviewer != '0' && task.reviewer != 'N/A') ||
          (task.rawData?['reviewer'] != null && task.rawData!['reviewer'].toString().isNotEmpty && task.rawData!['reviewer'].toString() != '0');

      final bool isApprovedByReviewer = currentProcess == 'PENDING_APPROVER' || !hasReviewer;

      if (!isApprovedByReviewer) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_top_rounded, color: Color(0xFFF97316), size: 20),
              SizedBox(width: 10),
              Text(
                'Waiting for Reviewer Review…',
                style: TextStyle(
                  color: Color(0xFFF97316),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }

      return _buildApproveRejectRow(
        label: 'Approver Actions',
        approveLabel: 'Approve',
        rejectLabel: 'Denied',
        approveIcon: Icons.verified_rounded,
        rejectIcon: Icons.cancel_rounded,
        onApprove: () => _handleReviewerAction('APPROVE'),
        onReject: () => _handleReviewerAction('REJECT'),
      );
    }

    // ── Under Review (Executor / Reviewer waiting) ───────────────────────
    if (_status == 'Under Review') {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_top_rounded, color: Color(0xFF7C3AED), size: 20),
                SizedBox(width: 10),
                Text(
                  'Waiting for Review…',
                  style: TextStyle(
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔔 Reminder sent!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: const Text('Send Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7C3AED),
                side: const BorderSide(color: Color(0xFF7C3AED)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    // ── Executor: Open / Pending / Overdue / Assigned ────────────────────────
    if (displayRole == 'Executor' && (_status == 'Open' || _status == 'Pending' || _status == 'Overdue' || _status == 'Assigned' || _status == 'To-Do')) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _startTask,
          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
          label: const Text(
            'Start Working',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
        ),
      );
    }

    // ── Executor: In Progress / Rework / Reassigned / WIP ──────────────────
    if (displayRole == 'Executor' && (_status == 'In Progress' || _status == 'Rework' || _status == 'Reassigned' || _status == 'WIP')) {
      final canSubmit = _checklist.isEmpty || _checklist.every((c) => c['isDone'] == true);
      final hasProcess = _reviewerEmpId != null || _approverEmpId != null;

      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: !canSubmit
                ? ElevatedButton.icon(
                    onPressed: () async {
                      await _saveRemarksToStorage();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Remarks saved!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                    label: const Text(
                      'Update',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _confirmSubmission(hasProcess),
                    icon: Icon(
                      hasProcess
                          ? (_status == 'Rework' || _status == 'Reassigned' ? Icons.redo_rounded : Icons.send_rounded)
                          : Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      hasProcess
                          ? (_status == 'Rework' || _status == 'Reassigned' ? 'Resubmit for Review' : 'Submit for Review')
                          : 'Mark as Complete',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasProcess ? const Color(0xFFEA580C) : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
          ),
        ],
      );
    }

    // ── Default fallback ───────────────────────────────────────
    return const SizedBox.shrink();
  }

  Widget _buildApproveRejectRow({
    required String label,
    required String approveLabel,
    required String rejectLabel,
    required IconData approveIcon,
    required IconData rejectIcon,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onApprove,
                icon: Icon(approveIcon, color: Colors.white, size: 18),
                label: Text(
                  approveLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onReject,
                icon: Icon(rejectIcon, color: Colors.white, size: 18),
                label: Text(
                  rejectLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetaRow(
    String label,
    IconData icon,
    String value, {
    bool isValuePurple = false,
    bool isValueRed = false,
    bool isStatusBadge = false,
  }) {
    Color badgeBgColor = const Color(0xFFEFF6FF);
    Color badgeTextColor = Colors.blue;

    if (label == 'Priority' || label.toLowerCase().contains('priority')) {
      badgeBgColor = getPriorityBg(value);
      badgeTextColor = getPriorityColor(value);
    } else if (value == 'Open' || value == 'Pending') {
      badgeBgColor = const Color(0xFFEFF6FF);
      badgeTextColor = const Color(0xFF2563EB);
    } else if (value == 'In Progress' || value == 'Work In Progress' || value == 'Executor') {
      badgeBgColor = const Color(0xFFFFF7ED);
      badgeTextColor = const Color(0xFFF59E0B);
    } else if (value == 'Closed' || value == 'Completed') {
      badgeBgColor = const Color(0xFFF0FDF4);
      badgeTextColor = const Color(0xFF16A34A);
    } else if (value == 'Rework' || value == 'Rework Required') {
      badgeBgColor = const Color(0xFFFFF7ED);
      badgeTextColor = const Color(0xFFF97316);
    } else if (value == 'Reassign' || value == 'Reassigned') {
      badgeBgColor = const Color(0xFFEEF2FF);
      badgeTextColor = const Color(0xFF4F46E5);
    } else if (value.contains('Under Review')) {
      badgeBgColor = const Color(0xFFF3E8FF);
      badgeTextColor = const Color(0xFF8B5CF6);
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: isStatusBadge
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (value == 'Rework' || value == 'Rework Required') ...[
                            const Icon(Icons.sync_rounded, size: 14, color: Color(0xFFF97316)),
                            const SizedBox(width: 4),
                          ] else if (value == 'Reassign' || value == 'Reassigned') ...[
                            const ReassignIcon(size: 14, color: Color(0xFF4F46E5)),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            value,
                            style: TextStyle(
                              color: badgeTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      value,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isValuePurple
                            ? Colors.purple
                            : isValueRed
                                ? Colors.red
                                : const Color(0xFF1E293B),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(
    String fileName,
    String size,
    IconData icon,
    Color iconColor,
    Color bgColor, {
    String? atPath,
    bool showDownload = true,
    VoidCallback? onDelete,
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
            child: GestureDetector(
              onTap: () => _downloadFile(fileName, atPath),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    size,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          if (showDownload)
            GestureDetector(
              onTap: () => _downloadFile(fileName, atPath),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.download_outlined,
                  color: Colors.blue.shade400,
                  size: 20,
                ),
              ),
            ),
          if (onDelete != null)
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

  Widget _buildTeamAddedMetaRow() {
    final int teamSize = _currentTaskTeam.length;
    if (teamSize == 0) return const SizedBox.shrink();

    final int displayCount = teamSize > 3 ? 3 : teamSize;
    final List<Widget> avatarStack = [];

    final List<Color> bgColors = [
      Colors.deepPurple,
      Colors.teal,
      Colors.amber.shade700,
    ];

    for (int i = 0; i < displayCount; i++) {
      final member = _currentTaskTeam[i];
      final String initials = member.initials;

      avatarStack.add(
        Positioned(
          left: i * 16.0,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColors[i % bgColors.length],
              border: Border.all(color: Colors.white, width: 1.5),
              image: member.profileImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(member.profileImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: member.profileImageUrl == null
                ? Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
      );
    }

    if (teamSize > 3) {
      avatarStack.add(
        Positioned(
          left: 3 * 16.0,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade400,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              "+${teamSize - 3}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    final double stackWidth =
        (displayCount * 16.0) + (teamSize > 3 ? 24.0 : 8.0);

    return GestureDetector(
      onTap: _showTeamMembersDialog,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            const Icon(
              Icons.people_outline,
              size: 18,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 12),
            const Text(
              'Team Added',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const Spacer(),
            SizedBox(
              width: stackWidth,
              height: 24,
              child: Stack(clipBehavior: Clip.none, children: avatarStack),
            ),
          ],
        ),
      ),
    );
  }

  void _showTeamMembersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.people_outline, color: Colors.deepPurple),
            const SizedBox(width: 8),
            const Text(
              'Team Members',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _currentTaskTeam.length,
            itemBuilder: (context, index) {
              final member = _currentTaskTeam[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  backgroundImage: member.profileImageUrl != null
                      ? NetworkImage(member.profileImageUrl!)
                      : null,
                  child: member.profileImageUrl == null
                      ? Text(
                          member.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  member.designation,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksContentList(String content, Color themeColor) {
    final lines = content
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return const Text(
        'No remarks available.',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        String displayText = line.trim();
        Widget leading = const Text(
          '• ',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        );

        if (displayText.startsWith('•')) {
          displayText = displayText.substring(1).trim();
        } else if (RegExp(r'^\d+\.').hasMatch(displayText)) {
          final match = RegExp(r'^\d+\.').firstMatch(displayText);
          if (match != null) {
            leading = Text(
              '${match.group(0)} ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            );
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
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF334155),
                    height: 1.4,
                  ),
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
                controller.selection = TextSelection.collapsed(
                  offset: start + 2,
                );
              },
              icon: Icon(
                Icons.format_list_bulleted,
                size: 14,
                color: themeColor,
              ),
              label: Text(
                'Bullet',
                style: TextStyle(
                  fontSize: 11,
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                final lineCount =
                    '\n'.allMatches(text.substring(0, start)).length + 1;
                final insertText = '$lineCount. ';
                final newText = text.replaceRange(start, end, insertText);
                controller.text = newText;
                controller.selection = TextSelection.collapsed(
                  offset: start + insertText.length,
                );
              },
              icon: Icon(
                Icons.format_list_numbered,
                size: 14,
                color: themeColor,
              ),
              label: Text(
                'Number',
                style: TextStyle(
                  fontSize: 11,
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
            hintText:
                'Enter your remarks (use toolbar above to insert bullets/numbers)...',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
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
              label: Text(
                'Edit Remarks',
                style: TextStyle(
                  fontSize: 12,
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                backgroundColor: themeColor.withValues(alpha: 0.08),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRemarkSection(
    String name,
    Widget contentWidget,
    Color themeColor,
  ) {
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
          crossFadeState: isOpen
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
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
                    border: Border.all(
                      color: themeColor.withValues(alpha: 0.15),
                    ),
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
                      colors: [themeColor.withValues(alpha: 0.95), themeColor],
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
                        isOpen
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
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
                      border: Border.all(
                        color: themeColor.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
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

