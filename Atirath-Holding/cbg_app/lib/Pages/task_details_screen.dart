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
  List<int> _reviewerEmpIds = [];
  List<int> _approverEmpIds = [];
  int? _currentEmpId;

  bool get _isExternalExecutor {
    final raw = task.rawData ?? {};

    final isExtVal = raw['isExternal'] ??
        raw['is_external'] ??
        raw['isExt'] ??
        raw['is_ext'] ??
        raw['external'];
    if (isExtVal == true ||
        isExtVal == 1 ||
        isExtVal == '1' ||
        isExtVal == 'true' ||
        isExtVal == 'Y' ||
        isExtVal == 'yes' ||
        isExtVal == 'YES') {
      return true;
    }

    final extNm = (raw['extEmpNm'] ?? raw['ext_emp_nm'] ?? '').toString().trim();
    if (extNm.isNotEmpty) return true;

    final extEmail = (raw['extEmpEmail'] ?? raw['ext_emp_email'] ?? '').toString().trim();
    if (extEmail.isNotEmpty) return true;

    final extId = (raw['extEmpId'] ?? raw['ext_emp_id'] ?? '').toString().trim();
    if (extId.isNotEmpty) return true;

    final empType = (raw['empType'] ??
            raw['emp_type'] ??
            raw['empTyp'] ??
            raw['emp_typ'] ??
            raw['executorType'] ??
            raw['executor_type'] ??
            raw['assignedToType'] ??
            raw['assigned_to_type'] ??
            raw['taskType'] ??
            raw['task_type'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();
    if (empType == 'EXT' ||
        empType == 'EXTERNAL' ||
        empType == 'EXTERNAL_TASK' ||
        empType == 'EXTERNAL_GUEST' ||
        empType == 'GUEST') {
      return true;
    }

    final roleStr = (raw['executorRole'] ??
            raw['executor_role'] ??
            raw['role'] ??
            raw['userRole'] ??
            raw['user_role'] ??
            '')
        .toString()
        .toLowerCase();
    if (roleStr.contains('external')) return true;

    if (_executorName.toLowerCase().contains('(external)') ||
        _executorName.toLowerCase().contains('external guest')) {
      return true;
    }
    if (task.subtitle.toLowerCase().contains('external')) return true;

    final execRawId = (raw['empId'] ??
            raw['empid'] ??
            raw['assignedTo'] ??
            raw['executorId'] ??
            raw['executor_id'] ??
            '')
        .toString()
        .trim();
    if (execRawId.isNotEmpty && _allEmployees.isNotEmpty) {
      try {
        final match = _allEmployees.firstWhere(
          (e) => e.id == execRawId,
          orElse: () => EmployeeOption(name: '', designation: ''),
        );
        if (match.designation.toLowerCase().contains('external') ||
            (match.companyName != null &&
                match.companyName!.toLowerCase().contains('external'))) {
          return true;
        }
      } catch (_) {}
    }

    return false;
  }

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

  String _formatDisplayName(String? name) {
    if (name == null) return 'Unassigned';
    final trimmed = name.trim();
    if (trimmed.isEmpty ||
        RegExp(r'^\d+$').hasMatch(trimmed) ||
        trimmed.toLowerCase() == 'null' ||
        trimmed.toLowerCase() == 'n/a' ||
        trimmed.toLowerCase() == 'not assigned') {
      return 'Unassigned';
    }
    return trimmed;
  }

  Future<void> _resolveReviewerAndApprover() async {
    String foundReviewerName = '';
    String foundApproverName = '';
    int? foundReviewerId;
    int? foundApproverId;

    final raw = task.rawData ?? {};

    // 1) Direct check from task.rawData or task model
    final revNm = (raw['reviewerNm'] ?? raw['reviewer_nm'] ?? raw['reviewerName'] ?? raw['reviewer_name'] ?? raw['revNm'] ?? raw['rev_nm'])?.toString().trim();
    if (revNm != null && revNm.isNotEmpty && !revNm.toLowerCase().contains('not assigned') && !RegExp(r'^\d+$').hasMatch(revNm)) {
      foundReviewerName = revNm;
    }

    final revIdRaw = (raw['reviewerId'] ?? raw['reviewer_id'] ?? raw['reviewer'] ?? raw['reviewerEmpId'] ?? raw['reviewer_emp_id'] ?? raw['revEmpId'] ?? raw['rev_emp_id'] ?? raw['revId'] ?? raw['rev_id'] ?? task.reviewer)?.toString().trim();
    if (revIdRaw != null && revIdRaw.isNotEmpty) {
      final parsedId = int.tryParse(revIdRaw);
      if (parsedId != null && parsedId > 0) {
        foundReviewerId = parsedId;
        final resolvedName = await ApiService.getEmployeeName(parsedId);
        if (resolvedName != null && resolvedName.isNotEmpty && !RegExp(r'^\d+$').hasMatch(resolvedName.trim())) {
          foundReviewerName = resolvedName;
        } else if (foundReviewerName.isEmpty || RegExp(r'^\d+$').hasMatch(foundReviewerName)) {
          foundReviewerName = 'Unassigned';
        }
      } else if (foundReviewerName.isEmpty) {
        foundReviewerName = RegExp(r'^\d+$').hasMatch(revIdRaw) ? 'Unassigned' : revIdRaw;
      }
    }

    final appNm = (raw['approverNm'] ?? raw['approver_nm'] ?? raw['approverName'] ?? raw['approver_name'] ?? raw['appNm'] ?? raw['app_nm'] ?? raw['checkerNm'] ?? raw['checker_nm'])?.toString().trim();
    if (appNm != null && appNm.isNotEmpty && !appNm.toLowerCase().contains('not assigned') && !RegExp(r'^\d+$').hasMatch(appNm)) {
      foundApproverName = appNm;
    }

    final appIdRaw = (raw['approverId'] ?? raw['approver_id'] ?? raw['approver'] ?? raw['approverEmpId'] ?? raw['approver_emp_id'] ?? raw['appEmpId'] ?? raw['app_emp_id'] ?? raw['checkerId'] ?? raw['checker_id'] ?? task.approver)?.toString().trim();
    if (appIdRaw != null && appIdRaw.isNotEmpty) {
      final parsedId = int.tryParse(appIdRaw);
      if (parsedId != null && parsedId > 0) {
        foundApproverId = parsedId;
        final resolvedName = await ApiService.getEmployeeName(parsedId);
        if (resolvedName != null && resolvedName.isNotEmpty && !RegExp(r'^\d+$').hasMatch(resolvedName.trim())) {
          foundApproverName = resolvedName;
        } else if (foundApproverName.isEmpty || RegExp(r'^\d+$').hasMatch(foundApproverName)) {
          foundApproverName = 'Unassigned';
        }
      } else if (foundApproverName.isEmpty) {
        foundApproverName = RegExp(r'^\d+$').hasMatch(appIdRaw) ? 'Unassigned' : appIdRaw;
      }
    }

    // 2) Fetch process config from API
    final numId = _extractTaskNumericId();
    if (numId != null && numId > 0) {
      List<dynamic> configs = [];
      try {
        if (widget.isIndividualTask) {
          configs = await ApiService.getLiveProcessConfigs(numId);
          if (configs.isEmpty) {
            configs = await ApiService.getLiveProcessConfig(numId);
          }
        } else {
          configs = await ApiService.getLiveProcessConfig(numId);
          if (configs.isEmpty) {
            configs = await ApiService.getLiveProcessConfigs(numId);
          }
          if (configs.isEmpty && task.drftTaskId != null) {
            final drftId = int.tryParse(task.drftTaskId!);
            if (drftId != null) {
              configs = await ApiService.getDraftProcessConfig(drftId);
            }
          }
        }
      } catch (e) {
        debugPrint('[TaskDetails] Error fetching process config: $e');
      }

      final List<String> revNames = [];
      final List<String> appNames = [];
      final List<int> revIds = [];
      final List<int> appIds = [];

      if (configs.isNotEmpty) {
        for (final item in configs) {
          if (item is! Map) continue;
          final config = Map<String, dynamic>.from(item);

          final stepType = (config['stepType'] ?? config['step_type'] ?? '').toString().toUpperCase();
          final stepLabel = (config['stepLabel'] ?? config['step_label'] ?? '').toString().toUpperCase();
          final rIdVal = (config['rId'] ?? config['r_id'] ?? config['rid'])?.toString();

          final empIdVal = config['empId'] ?? config['emp_id'] ?? config['empid'];
          final empId = empIdVal != null ? int.tryParse(empIdVal.toString()) : null;

          String empName = (config['empNm'] ?? config['emp_nm'] ?? config['employeeName'] ?? config['employee_name'] ?? '').toString().trim();
          if ((empName.isEmpty || RegExp(r'^\d+$').hasMatch(empName)) && empId != null && empId > 0) {
            final resolved = await ApiService.getEmployeeName(empId);
            if (resolved != null && resolved.isNotEmpty && !RegExp(r'^\d+$').hasMatch(resolved.trim())) {
              empName = resolved;
            } else {
              empName = 'Unassigned';
            }
          }

          if (stepType == 'REVIEWER' || stepLabel == 'REVIEWER' || stepLabel.contains('REVIEW') || rIdVal == '1') {
            if (empId != null) {
              foundReviewerId ??= empId;
              if (!revIds.contains(empId)) revIds.add(empId);
            }
            if (empName.isNotEmpty && !revNames.contains(empName)) revNames.add(empName);
          } else if (stepType == 'CHECKER' || stepType == 'APPROVER' || stepLabel == 'APPROVER' || stepLabel.contains('APPROV') || stepLabel.contains('CHECK') || rIdVal == '2') {
            if (empId != null) {
              foundApproverId ??= empId;
              if (!appIds.contains(empId)) appIds.add(empId);
            }
            if (empName.isNotEmpty && !appNames.contains(empName)) appNames.add(empName);
          }
        }

        if (revNames.isNotEmpty) {
          foundReviewerName = revNames.join(', ');
        }
        if (appNames.isNotEmpty) {
          foundApproverName = appNames.join(', ');
        }
      }

      // Also incorporate IDs from task model / rawData
      if (foundReviewerId != null && !revIds.contains(foundReviewerId)) {
        revIds.add(foundReviewerId);
      }
      for (final r in task.reviewers) {
        final parsed = int.tryParse(r.toString());
        if (parsed != null && !revIds.contains(parsed)) revIds.add(parsed);
      }
      if (foundApproverId != null && !appIds.contains(foundApproverId)) {
        appIds.add(foundApproverId);
      }
      for (final a in task.approvers) {
        final parsed = int.tryParse(a.toString());
        if (parsed != null && !appIds.contains(parsed)) appIds.add(parsed);
      }

      if (!mounted) return;
      setState(() {
        if (foundReviewerName.isNotEmpty && foundReviewerName.toLowerCase() != 'n/a') {
          _reviewerName = RegExp(r'^\d+$').hasMatch(foundReviewerName.trim()) ? 'Unassigned' : foundReviewerName;
        }
        if (foundApproverName.isNotEmpty && foundApproverName.toLowerCase() != 'n/a') {
          _approverName = RegExp(r'^\d+$').hasMatch(foundApproverName.trim()) ? 'Unassigned' : foundApproverName;
        }
        if (foundReviewerId != null) _reviewerEmpId = foundReviewerId;
        if (foundApproverId != null) _approverEmpId = foundApproverId;
        _reviewerEmpIds = revIds;
        _approverEmpIds = appIds;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      if (foundReviewerName.isNotEmpty && foundReviewerName.toLowerCase() != 'n/a') {
        _reviewerName = RegExp(r'^\d+$').hasMatch(foundReviewerName.trim()) ? 'Unassigned' : foundReviewerName;
      }
      if (foundApproverName.isNotEmpty && foundApproverName.toLowerCase() != 'n/a') {
        _approverName = RegExp(r'^\d+$').hasMatch(foundApproverName.trim()) ? 'Unassigned' : foundApproverName;
      }
      if (foundReviewerId != null) {
        _reviewerEmpId = foundReviewerId;
        if (!_reviewerEmpIds.contains(foundReviewerId)) _reviewerEmpIds.add(foundReviewerId);
      }
      if (foundApproverId != null) {
        _approverEmpId = foundApproverId;
        if (!_approverEmpIds.contains(foundApproverId)) _approverEmpIds.add(foundApproverId);
      }
    });
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
                  _status = freshItem.isUnderReview
                      ? 'Under Review'
                      : freshItem.isRework
                          ? 'Rework'
                          : freshItem.isReassigned
                              ? 'Reassigned'
                              : freshItem.isCompleted
                                  ? 'Closed'
                                  : freshItem.isInProgress
                                      ? 'In Progress'
                                      : freshItem.status;
                  _rawDbStatus = (freshRaw['taskSts'] ?? freshRaw['status'] ?? '').toString().toUpperCase();
                  _isButtonClicked = (_status == 'In Progress' || _status == 'Work In Progress' || _status == 'WIP');
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
                  _status = freshItem.isUnderReview
                      ? 'Under Review'
                      : freshItem.isRework
                          ? 'Rework'
                          : freshItem.isReassigned
                              ? 'Reassigned'
                              : freshItem.isCompleted
                                  ? 'Closed'
                                  : freshItem.isInProgress
                                      ? 'In Progress'
                                      : freshItem.status;
                  _rawDbStatus = (freshRaw['taskSts'] ?? freshRaw['status'] ?? '').toString().toUpperCase();
                  _isButtonClicked = (_status == 'In Progress' || _status == 'Work In Progress' || _status == 'WIP');
                });
                await _loadChecklist();
              }
            }
          }
        } catch (e) {
          debugPrint('Error fetching fresh backend task details: $e');
        }
      }

      final execRaw = (task.rawData?['empId'] ??
              task.rawData?['empid'] ??
              task.rawData?['assignedTo'] ??
              task.rawData?['extEmpId'] ??
              task.rawData?['ext_emp_id'] ??
              '')
          .toString()
          .trim();
      final execNm = (task.rawData?['extEmpNm'] ??
              task.rawData?['ext_emp_nm'] ??
              task.rawData?['empNm'] ??
              task.rawData?['executorNm'] ??
              task.rawData?['assigneeNm'] ??
              task.rawData?['emp_nm'] ??
              task.rawData?['assignedToNm'] ??
              task.rawData?['assigned_to_name'] ??
              '')
          .toString()
          .trim();
      
      if (execNm.isNotEmpty && !RegExp(r'^\d+$').hasMatch(execNm)) {
        if (mounted) setState(() => _executorName = execNm);
      } else if (execRaw.isNotEmpty) {
        final execId = int.tryParse(execRaw);
        if (execId != null) {
          final exName = await ApiService.getEmployeeName(execId);
          if (mounted) {
            setState(() => _executorName = (exName != null && exName.isNotEmpty && !RegExp(r'^\d+$').hasMatch(exName)) ? exName : 'Unassigned');
          }
        } else {
          if (mounted) setState(() => _executorName = (execRaw.isEmpty || RegExp(r'^\d+$').hasMatch(execRaw)) ? 'Unassigned' : execRaw);
        }
      }

      final abRaw = (task.rawData?['assignedBy'] ?? task.rawData?['assigned_by'] ?? task.rawData?['crBy'] ?? task.rawData?['cr_by'] ?? '').toString().trim();
      final abNm = (task.rawData?['assignedByNm'] ?? task.rawData?['assignerNm'] ?? task.rawData?['assigned_by_nm'] ?? task.rawData?['crByNm'] ?? '').toString().trim();
      
      if (abNm.isNotEmpty && !RegExp(r'^\d+$').hasMatch(abNm)) {
        if (mounted) setState(() => _assignedByName = abNm);
      } else if (abRaw.isNotEmpty) {
        final abId = int.tryParse(abRaw);
        if (abId != null) {
          final abName = await ApiService.getEmployeeName(abId);
          if (mounted) {
            setState(() => _assignedByName = (abName != null && abName.isNotEmpty && !RegExp(r'^\d+$').hasMatch(abName)) ? abName : 'Unassigned');
          }
        } else {
          if (mounted) setState(() => _assignedByName = (abRaw.isEmpty || RegExp(r'^\d+$').hasMatch(abRaw)) ? 'Unassigned' : abRaw);
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

        await _resolveReviewerAndApprover();
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
            _status = task.isUnderReview
                ? 'Under Review'
                : task.isRework
                    ? 'Rework'
                    : task.isReassigned
                        ? 'Reassigned'
                        : task.isCompleted
                            ? 'Closed'
                            : task.isInProgress
                                ? 'In Progress'
                                : task.status;
            _rawDbStatus = (task.rawData?['taskSts'] ?? task.rawData?['status'] ?? '').toString().toUpperCase();
            _isButtonClicked = (_status == 'In Progress' || _status == 'Work In Progress' || _status == 'WIP');
          });
        }
      }
      try {
        final taskIdInt = _extractTaskNumericId() ?? int.tryParse(task.id);
        if (taskIdInt != null) {
          final contributors = await ApiService.getContributors(taskIdInt, widget.isIndividualTask);
          if (contributors.isNotEmpty) {
            final dbEmployees = await ApiService.getEmployees();
            for (final c in contributors) {
              final cEmpId = (c['empId'] ?? c['id'] ?? c['emp_id'])?.toString();
              if (cEmpId != null) {
                final match = dbEmployees.firstWhere(
                  (emp) => emp['id']?.toString() == cEmpId || emp['empId']?.toString() == cEmpId,
                  orElse: () => null,
                );
                if (match != null && !dbTeam.any((e) => e.id == match['id']?.toString())) {
                  dbTeam.add(EmployeeOption.fromJson(match));
                }
              }
            }
          }
        }
        if (dbTeam.isEmpty) {
          final dbTask = widget.isIndividualTask
              ? await ApiService.getIndividualTaskById(_extractTaskNumericId() ?? int.parse(task.id))
              : await ApiService.getLiveTask(_extractTaskNumericId() ?? int.parse(task.id));
          if (dbTask != null) {
            final String? noteTxt = dbTask['noteTxt'] ?? dbTask['note_txt'];
            dynamic rawTeam = dbTask['teamMembers'] ?? dbTask['team_members'] ?? dbTask['team'];
            final dbEmployees = await ApiService.getEmployees();

            if (rawTeam is List && rawTeam.isNotEmpty) {
              for (final tm in rawTeam) {
                final tmId = tm is Map ? (tm['empId'] ?? tm['emp_id'] ?? tm['id'])?.toString() : tm.toString();
                if (tmId != null) {
                  final match = dbEmployees.firstWhere(
                    (emp) => emp['id']?.toString() == tmId.trim() || emp['empId']?.toString() == tmId.trim(),
                    orElse: () => null,
                  );
                  if (match != null && !dbTeam.any((e) => e.id == match['id']?.toString())) {
                    dbTeam.add(EmployeeOption.fromJson(match));
                  }
                }
              }
            }

            if (noteTxt != null && noteTxt.trim().isNotEmpty) {
              final List<String> employeeIds = noteTxt.split(',');
              for (final empId in employeeIds) {
                final match = dbEmployees.firstWhere(
                  (emp) => emp['id']?.toString() == empId.trim() || emp['empId']?.toString() == empId.trim(),
                  orElse: () => null,
                );
                if (match != null && !dbTeam.any((e) => e.id == match['id']?.toString())) {
                  dbTeam.add(EmployeeOption.fromJson(match));
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Error loading team from db: $e");
      }

      if (mounted) {
        setState(() {
          if (dbTeam.isNotEmpty) {
            _currentTaskTeam = dbTeam;
          }
          _isLoadingData = false;
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

      await _resolveReviewerAndApprover();

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

    } catch (e) {
      debugPrint('Error in _loadSavedData: $e');
    } finally {
      if (mounted) {
        setState(() {
          _status = task.isUnderReview
              ? 'Under Review'
              : task.isRework
                  ? 'Rework'
                  : task.isReassigned
                      ? 'Reassigned'
                      : task.isCompleted
                          ? 'Closed'
                          : task.isInProgress
                              ? 'In Progress'
                              : task.status;
          _rawDbStatus = (task.rawData?['taskSts'] ?? task.rawData?['status'] ?? '').toString().toUpperCase();
          _isButtonClicked = (_status == 'In Progress' || _status == 'Work In Progress' || _status == 'WIP');
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _startTask() async {
    setState(() {
      _isLoadingData = true;
    });
    try {
      final taskId = _extractTaskNumericId()!;

      if (widget.isIndividualTask) {
        // Individual tasks: update via individual-tasks status patch endpoint
        bool success = await ApiService.updateIndividualTaskStatus(taskId, 'WIP');
        if (!success) {
          try {
            await ApiService.startTask(taskId);
            success = true;
          } catch (_) {}
        }
        if (!success) throw Exception('Failed to update task status');
      } else {
        // Project tasks: update via project-live endpoint
        bool success = await ApiService.updateProjectTaskStatus(taskId, 'WIP');
        if (!success) {
          try {
            await ApiService.startTask(taskId);
            success = true;
          } catch (_) {}
        }
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
        setState(() {
          _isLoadingData = false;
        });
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
        if (_status == 'Rework' || _status == 'Reassigned') {
          await ApiService.resubmitTask(taskId, _assigneeNoteController.text);
        } else {
          await ApiService.submitTask(taskId, _assigneeNoteController.text);
        }
      } else {
        // Project task: update status via project-live endpoint
        bool success = await ApiService.updateProjectTaskStatus(taskId, 'SUBMIT_REVIEW');
        if (!success) {
          try {
            if (_status == 'Rework' || _status == 'Reassigned') {
              await ApiService.resubmitTask(taskId, _assigneeNoteController.text);
            } else {
              await ApiService.submitTask(taskId, _assigneeNoteController.text);
            }
            success = true;
          } catch (_) {}
        }
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
          taskJson['tagColor'] = const Color(0xFFEF4444).value; // BIONOVA High #EF4444
          taskJson['tagBg'] = const Color(0xFFFEF2F2).value;
          taskJson['icon'] = Icons.shield_outlined.codePoint;
          taskJson['iconColor'] = const Color(0xFFEF4444).value;
          taskJson['iconBg'] = const Color(0xFFFEF2F2).value;
        } else if (newStatus == 'Rework') {
          taskJson['tag'] = 'Critical';
          taskJson['tagColor'] = const Color(0xFFB91C1C).value; // BIONOVA Critical #B91C1C
          taskJson['tagBg'] = const Color(0xFFFEE2E2).value;
          taskJson['icon'] = Icons.assignment_outlined.codePoint;
          taskJson['iconColor'] = const Color(0xFFB91C1C).value;
          taskJson['iconBg'] = const Color(0xFFFEE2E2).value;
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
      _reviewerName = (task.reviewer != null && !RegExp(r'^\d+$').hasMatch(task.reviewer!.trim()) && !task.reviewer!.toLowerCase().contains('not assigned')) ? task.reviewer! : '';
      _approverName = (task.approver != null && !RegExp(r'^\d+$').hasMatch(task.approver!.trim()) && !task.approver!.toLowerCase().contains('not assigned')) ? task.approver! : '';
      final initialExecNm = (task.rawData?['extEmpNm'] ??
              task.rawData?['ext_emp_nm'] ??
              task.rawData?['empNm'] ??
              task.rawData?['executorNm'] ??
              task.rawData?['assigneeNm'] ??
              task.rawData?['emp_nm'] ??
              task.rawData?['assignedToNm'] ??
              task.rawData?['assigned_to_name'] ??
              '')
          .toString()
          .trim();
      if (initialExecNm.isNotEmpty && !RegExp(r'^\d+$').hasMatch(initialExecNm)) {
        _executorName = initialExecNm;
      }
      final initialAbNm = (task.rawData?['assignedByNm'] ??
              task.rawData?['assignerNm'] ??
              task.rawData?['assigned_by_nm'] ??
              task.rawData?['crByNm'] ??
              task.rawData?['crtdByNm'] ??
              task.rawData?['createdByNm'] ??
              '')
          .toString()
          .trim();
      if (initialAbNm.isNotEmpty && !RegExp(r'^\d+$').hasMatch(initialAbNm)) {
        _assignedByName = initialAbNm;
      }
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



    final executorId = int.tryParse((task.rawData?['empId'] ??
            task.rawData?['empid'] ??
            task.rawData?['assignedTo'] ??
            task.rawData?['assigned_to'] ??
            task.rawData?['extEmpId'] ??
            task.rawData?['ext_emp_id'] ??
            task.rawData?['doerId'] ??
            task.rawData?['doer_id'] ??
            task.rawData?['executorId'] ??
            task.rawData?['executor_id'] ??
            task.rawData?['assigneeId'] ??
            task.rawData?['assignee'] ??
            '')
        .toString());

    final assignerId = int.tryParse((task.rawData?['assignedBy'] ??
            task.rawData?['assigned_by'] ??
            task.rawData?['crBy'] ??
            task.rawData?['cr_by'] ??
            task.rawData?['crtdBy'] ??
            task.rawData?['crtd_by'] ??
            task.rawData?['createdBy'] ??
            task.rawData?['created_by'] ??
            '')
        .toString());

    final bool isDirectReviewer = (_currentEmpId != null && (_reviewerEmpId == _currentEmpId || _reviewerEmpIds.contains(_currentEmpId))) ||
        (task.reviewer != null && _currentEmpId != null && task.reviewer.toString() == _currentEmpId.toString()) ||
        (_currentEmpId != null && task.reviewers.contains(_currentEmpId.toString())) ||
        (task.isCurrentUserReviewer);

    final bool isDirectApprover = (_currentEmpId != null && (_approverEmpId == _currentEmpId || _approverEmpIds.contains(_currentEmpId))) ||
        (task.approver != null && _currentEmpId != null && task.approver.toString() == _currentEmpId.toString()) ||
        (_currentEmpId != null && task.approvers.contains(_currentEmpId.toString())) ||
        (task.isCurrentUserApprover);

    final bool isUserReviewer = isDirectReviewer;
    final bool isUserApprover = isDirectApprover;

    final bool isPrimaryExecutor = _currentEmpId != null && 
        ((executorId != null && _currentEmpId.toString() == executorId.toString()) ||
         (task.rawData?['empId']?.toString() == _currentEmpId.toString()) ||
         (task.rawData?['empid']?.toString() == _currentEmpId.toString()) ||
         (task.rawData?['assignedTo']?.toString() == _currentEmpId.toString()) ||
         (task.rawData?['assigned_to']?.toString() == _currentEmpId.toString()) ||
         (task.rawData?['doerId']?.toString() == _currentEmpId.toString()) ||
         (task.rawData?['doer_id']?.toString() == _currentEmpId.toString()) ||
         (task.rawData?['extEmpId']?.toString() == _currentEmpId.toString()) ||
         (task.rawData?['ext_emp_id']?.toString() == _currentEmpId.toString()));

    final bool isAssignedExecutor = isPrimaryExecutor || 
        task.isCurrentUserExecutor ||
        (_currentEmpId != null && _currentTaskTeam.any((emp) => emp.id?.toString() == _currentEmpId.toString()));

    final bool isDirectAssigner = (_currentEmpId != null && assignerId != null && _currentEmpId == assignerId) ||
        task.isCurrentUserAssigner;

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
        task.isCompleted ||
        rawStsStr.toUpperCase().contains('CLOSED') ||
        rawStsStr.toUpperCase().contains('COMPLETED') ||
        _rawDbStatus.contains('CLOSED') ||
        _rawDbStatus.contains('COMPLETED') ||
        (rawSts is Map && (rawSts['statusId'] == 4 || rawSts['status_id'] == 4));

    final bool isSubmittedByExecutor = _status == 'Under Review' ||
        task.status == 'Under Review' ||
        task.isUnderReview ||
        _rawDbStatus == 'SUBMIT_REVIEW' ||
        _rawDbStatus == 'UNDER_REVIEW' ||
        _rawDbStatus == 'SUBMITTED' ||
        _rawDbStatus.contains('REVIEW') ||
        rawStsStr.toUpperCase().contains('REVIEW') ||
        rawStsStr.toUpperCase().contains('SUBMIT') ||
        currentProcess == 'PENDING_REVIEWER' ||
        currentProcess == 'PENDING_APPROVER' ||
        currentProcess == 'SUBMIT_REVIEW' ||
        currentProcess == 'UNDER_REVIEW';

    final bool hasReviewer = (_reviewerEmpId != null && _reviewerEmpId != 0) ||
        _reviewerEmpIds.isNotEmpty ||
        (task.reviewer != null && task.reviewer!.isNotEmpty && task.reviewer != '0' && task.reviewer != 'N/A') ||
        (task.reviewers.isNotEmpty) ||
        (task.rawData?['reviewer'] != null && task.rawData!['reviewer'].toString().isNotEmpty && task.rawData!['reviewer'].toString() != '0') ||
        (task.rawData?['reviewerId'] != null || task.rawData?['reviewer_id'] != null) ||
        (_reviewerName.trim().isNotEmpty && _reviewerName.toLowerCase() != 'unassigned');

    final bool hasApprover = (_approverEmpId != null && _approverEmpId != 0) ||
        _approverEmpIds.isNotEmpty ||
        (task.approver != null && task.approver!.isNotEmpty && task.approver != '0' && task.approver != 'N/A') ||
        (task.approvers.isNotEmpty) ||
        (task.rawData?['approver'] != null && task.rawData!['approver'].toString().isNotEmpty && task.rawData!['approver'].toString() != '0') ||
        (task.rawData?['approverId'] != null || task.rawData?['approver_id'] != null) ||
        (_approverName.trim().isNotEmpty && _approverName.toLowerCase() != 'unassigned');

    final bool isApprovedByReviewer = currentProcess == 'PENDING_APPROVER' ||
        task.rawData?['prcsYesActn'] == 'PENDING_APPROVER' ||
        task.rawData?['prcs_yes_actn'] == 'PENDING_APPROVER' ||
        task.rawData?['subStatus']?.toString().toUpperCase() == 'PENDING_APPROVER' ||
        task.rawData?['sub_status']?.toString().toUpperCase() == 'PENDING_APPROVER' ||
        !hasReviewer;

    String displayRole = 'Executor';
    String actionMessage = task.priority;

    if (_isLoadingData) {
      displayRole = 'Loading...';
    } else if (isSubmittedByExecutor && isDirectReviewer) {
      displayRole = 'Reviewer';
    } else if (isSubmittedByExecutor && isDirectApprover) {
      displayRole = 'Approver';
    } else if (isAssignedExecutor) {
      displayRole = 'Executor';
    } else if (isDirectReviewer) {
      displayRole = 'Reviewer';
    } else if (isDirectApprover) {
      displayRole = 'Approver';
    } else if (isDirectAssigner) {
      displayRole = 'Assigner';
    } else if (_userRole.toLowerCase() == 'checker' || _userRole.toLowerCase() == 'reviewer') {
      displayRole = 'Reviewer';
    } else if (_userRole.toLowerCase() == 'approver') {
      displayRole = 'Approver';
    } else if (_userRole.toLowerCase() == 'admin' || _userRole.toLowerCase() == 'super_admin') {
      displayRole = 'Admin';
    } else if (_userRole.toLowerCase() == 'project_manager' || _userRole.toLowerCase() == 'manager') {
      displayRole = 'Manager';
    } else {
      displayRole = 'Viewer';
    }

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
                  if (_status != 'Under Review' && _status != 'Closed' && _status != 'Completed' && isPrimaryExecutor && !isUserReviewer && !isUserApprover)
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
                  color: isClosedTask ? const Color(0xFFF0FDF4) : task.tagBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isClosedTask ? const Color(0xFF16A34A).withValues(alpha: 0.2) : task.tagColor.withValues(alpha: 0.2),
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
                        child: Icon(
                          isClosedTask ? Icons.task_alt : task.icon,
                          color: isClosedTask ? const Color(0xFF16A34A) : task.iconColor,
                          size: 28,
                        ),
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
                          if (isClosedTask) ...[
                            const SizedBox(height: 6),
                            _buildLeadLagBadge(calculateTaskLeadLag(task, isClosedTask)),
                          ],
                        ],
                      ),
                    ),
                    if (!isClosedTask && actionMessage.isNotEmpty) ...[
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
                      (displayRole == 'Executor' && _isExternalExecutor)
                          ? 'Executor (External)'
                          : displayRole,
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
                    if (isClosedTask)
                      _buildMetaRow(
                        'Schedule',
                        Icons.timer_outlined,
                        calculateTaskLeadLag(task, isClosedTask),
                        isLeadLagBadge: true,
                      ),
                     if (widget.isIndividualTask && (_isLoadingData || _assignedByName.trim().isNotEmpty))
                      _buildMetaRow(
                        'Assigned By',
                        Icons.assignment_ind_outlined,
                        _isLoadingData ? 'Loading...' : _formatDisplayName(_assignedByName),
                      ),
                    if (displayRole != 'Executor' && (_isLoadingData || _executorName.trim().isNotEmpty))
                      _buildMetaRow(
                        _isExternalExecutor ? 'Executor (External)' : 'Executor',
                        Icons.person_outline,
                        _isLoadingData ? 'Loading...' : _formatDisplayName(_executorName),
                      ),
                    if (displayRole != 'Reviewer' && (_isLoadingData || _reviewerName.trim().isNotEmpty))
                      _buildMetaRow(
                        'Reviewer',
                        Icons.rate_review_outlined,
                        _isLoadingData ? 'Loading...' : _formatDisplayName(_reviewerName),
                      ),
                    if (displayRole != 'Approver' && (_isLoadingData || _approverName.trim().isNotEmpty))
                      _buildMetaRow(
                        'Approver',
                        Icons.verified_outlined,
                        _isLoadingData ? 'Loading...' : _formatDisplayName(_approverName),
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
                    _buildTaskProgressMetaRow(),

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
                                const Color(0xFF059669),
                              ),
                              const Color(0xFF059669),
                            ),
                            _buildRemarkSection(
                              'Executor Remarks',
                              _isEditingAssigneeRemarks
                                  ? _buildRemarksEditor(
                                      controller: _assigneeNoteController,
                                      themeColor: const Color(0xFF4F46E5),
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
                                            themeColor: const Color(0xFF4F46E5),
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
                              const Color(0xFF4F46E5),
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
                                              canEdit: displayRole == 'Reviewer' && isSubmittedByExecutor && currentProcess != 'PENDING_APPROVER',
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
                                              canEdit: displayRole == 'Approver' && isSubmittedByExecutor && isApprovedByReviewer,
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
                  hasReviewer: hasReviewer,
                  hasApprover: hasApprover,
                  isSubmittedByExecutor: isSubmittedByExecutor,
                  isApprovedByReviewer: isApprovedByReviewer,
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
    required bool hasReviewer,
    required bool hasApprover,
    required bool isSubmittedByExecutor,
    required bool isApprovedByReviewer,
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

    final bool isTaskInReviewableState = !isClosedTask;

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

    final String sUpper = _status.toUpperCase().replaceAll('_', ' ').trim();
    final String rawUpper = _rawDbStatus.toUpperCase().replaceAll('_', ' ').trim();

    final bool isStatusOpen = sUpper == 'OPEN' || 
        sUpper == 'PENDING' || 
        sUpper == 'OVERDUE' || 
        sUpper == 'ASSIGNED' || 
        sUpper == 'TO-DO' || 
        sUpper == 'TODO' || 
        sUpper == 'DRAFT' || 
        sUpper == 'NEW' || 
        rawUpper == 'OPEN' || 
        rawUpper == 'PENDING' || 
        rawUpper == '1' || 
        task.isOpen;

    final bool isStatusInProgress = sUpper == 'IN PROGRESS' || 
        sUpper == 'WORK IN PROGRESS' || 
        sUpper == 'WIP' || 
        rawUpper == 'WIP' || 
        rawUpper == '3' || 
        rawUpper == 'IN PROGRESS' || 
        rawUpper == 'WORK IN PROGRESS' || 
        task.isInProgress;

    final bool isStatusRework = sUpper == 'REWORK' || 
        rawUpper == 'REWORK' || 
        currentProcess == 'REWORK' || 
        task.isRework;

    final bool isStatusReassigned = sUpper == 'REASSIGNED' || 
        sUpper == 'REASSIGN' || 
        rawUpper == 'REASSIGNED' || 
        rawUpper == 'REASSIGN' || 
        currentProcess == 'REASSIGN' || 
        currentProcess == 'REASSIGNED' || 
        task.isReassigned;

    final bool isStatusUnderReview = sUpper == 'UNDER REVIEW' || 
        isSubmittedByExecutor;

    final bool isAdminOrManager = displayRole == 'Admin' || displayRole == 'Manager';
    final bool isReviewerRole = displayRole == 'Reviewer';
    final bool isApproverRole = displayRole == 'Approver';
    final bool isExecutorRole = displayRole == 'Executor';

    // ── Reviewer sees task for review ────────
    if (isReviewerRole && isTaskInReviewableState) {
      // 1. Initial stage: Executor has not completed/submitted yet -> Reviewer buttons must NOT appear!
      if (!isSubmittedByExecutor) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top_rounded, color: Color(0xFF64748B), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isStatusRework
                      ? 'Task in Rework by Executor • Waiting for Submission…'
                      : isStatusReassigned
                          ? 'Task Reassigned • Waiting for Executor to Submit…'
                          : isStatusOpen
                              ? 'Task Open • Waiting for Executor to Submit…'
                              : 'Task in Progress by Executor • Waiting for Submission…',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }

      // 2. Reviewer already approved and it's pending Approver
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
                  Expanded(
                    child: Text(
                      'Approved by Reviewer • Pending Approver',
                      style: TextStyle(
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
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

      // 3. Executor completed & submitted -> Reviewer gets Approve & Denied buttons!
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
    if (isApproverRole && isTaskInReviewableState) {
      // 1. Initial stage: Executor has not completed/submitted yet -> Approver buttons must NOT appear!
      if (!isSubmittedByExecutor) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top_rounded, color: Color(0xFF64748B), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isStatusRework
                      ? 'Task in Rework by Executor • Waiting for Submission…'
                      : isStatusReassigned
                          ? 'Task Reassigned • Waiting for Executor to Submit…'
                          : isStatusOpen
                              ? 'Task Open • Waiting for Executor to Submit…'
                              : 'Task in Progress by Executor • Waiting for Submission…',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }

      // 2. Executor has submitted, but Reviewer has not approved yet -> Approver buttons must NOT appear!
      if (hasReviewer && !isApprovedByReviewer) {
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
              Expanded(
                child: Text(
                  'Waiting for Reviewer Review…',
                  style: TextStyle(
                    color: Color(0xFFF97316),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }

      // 3. Reviewer has submitted/approved (or task has no reviewer) -> Approver gets Approve & Denied buttons!
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

    // ── Admin / Manager Oversight ───────────────────────────────────────
    if (isAdminOrManager && isTaskInReviewableState) {
      if (isSubmittedByExecutor) {
        if (hasReviewer && !isApprovedByReviewer) {
          return _buildApproveRejectRow(
            label: 'Reviewer Actions ($displayRole Override)',
            approveLabel: 'Approve (Reviewer)',
            rejectLabel: 'Denied',
            approveIcon: Icons.thumb_up_rounded,
            rejectIcon: Icons.cancel_rounded,
            onApprove: () => _handleCheckerAction('APPROVE'),
            onReject: () => _handleCheckerAction('REJECT'),
          );
        } else {
          return _buildApproveRejectRow(
            label: 'Approver Actions ($displayRole Override)',
            approveLabel: 'Approve & Close',
            rejectLabel: 'Denied',
            approveIcon: Icons.verified_rounded,
            rejectIcon: Icons.cancel_rounded,
            onApprove: () => _handleReviewerAction('APPROVE'),
            onReject: () => _handleReviewerAction('REJECT'),
          );
        }
      }

      if (isStatusOpen) {
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

      if (isStatusInProgress || isStatusRework || isStatusReassigned) {
        final canSubmit = _checklist.isEmpty || _checklist.every((c) => c['isDone'] == true);
        final hasProcess = hasReviewer || hasApprover || _reviewerEmpId != null || _approverEmpId != null;

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
                            ? (isStatusRework || isStatusReassigned ? Icons.redo_rounded : Icons.send_rounded)
                            : Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        hasProcess
                            ? (isStatusRework || isStatusReassigned ? 'Resubmit for Review' : 'Submit for Review')
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
    }

    // ── Executor: Under Review ──────────────────────────────────────────
    if (isExecutorRole && isStatusUnderReview) {
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
                Icon(Icons.hourglass_top_rounded, color: Color(0xFF7C3AED), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Waiting for Review…',
                    style: TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
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

    // ── Executor: Open / Pending / Overdue / Assigned ────────────────────
    if (isExecutorRole && isStatusOpen) {
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

    // ── Executor: In Progress / Rework / Reassigned / WIP ────────────────
    if (isExecutorRole && (isStatusInProgress || isStatusRework || isStatusReassigned)) {
      final canSubmit = _checklist.isEmpty || _checklist.every((c) => c['isDone'] == true);
      final hasProcess = hasReviewer || hasApprover || _reviewerEmpId != null || _approverEmpId != null;

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
                          ? (isStatusRework || isStatusReassigned ? Icons.redo_rounded : Icons.send_rounded)
                          : Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      hasProcess
                          ? (isStatusRework || isStatusReassigned ? 'Resubmit for Review' : 'Submit for Review')
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

    // ── Assigner / Viewer / Fallback Status Banner ───────────────────────
    final String execDisplay = _formatDisplayName(_executorName).isNotEmpty && _formatDisplayName(_executorName) != 'Unassigned'
        ? _formatDisplayName(_executorName)
        : 'Executor';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_ind_outlined, color: Color(0xFF64748B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isStatusRework
                  ? 'Task in Rework • Assigned to $execDisplay'
                  : isStatusReassigned
                      ? 'Task Reassigned • Assigned to $execDisplay'
                      : isStatusOpen
                          ? 'Task Open • Assigned to $execDisplay'
                          : isStatusUnderReview
                              ? 'Task Under Review • Assigned to $execDisplay'
                              : 'Task in Progress • Assigned to $execDisplay',
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
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
    bool isLeadLagBadge = false,
  }) {
    if (isLeadLagBadge) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                child: _buildLeadLagBadge(value),
              ),
            ),
          ],
        ),
      );
    }

    Color badgeBgColor = const Color(0xFFEFF6FF);
    Color badgeTextColor = Colors.blue;

    if (label == 'Priority' || label.toLowerCase().contains('priority')) {
      badgeBgColor = getPriorityBg(value);
      badgeTextColor = getPriorityColor(value);
    } else if (value == 'Open' || value == 'Pending') {
      badgeBgColor = const Color(0xFFEFF6FF);
      badgeTextColor = const Color(0xFF2563EB);
    } else if (value == 'In Progress' ||
        value == 'Work In Progress' ||
        value == 'Executor' ||
        value == 'Executor (External)' ||
        value.contains('Executor')) {
      badgeBgColor = const Color(0xFFFEF3C7);
      badgeTextColor = const Color(0xFFF59E0B);
    } else if (value == 'Assigner' || value == 'Assigned By' || value == 'Assigned by Me' || value == 'Creator') {
      badgeBgColor = const Color(0xFFEFF6FF);
      badgeTextColor = const Color(0xFF2563EB);
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
    } else if (value == 'Admin' || value == 'Manager' || value == 'Viewer') {
      badgeBgColor = const Color(0xFFF1F5F9);
      badgeTextColor = const Color(0xFF475569);
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
    if (teamSize == 0) {
      return _buildMetaRow(
        'Team Members',
        Icons.people_outline,
        _isLoadingData ? 'Loading...' : 'None',
      );
    }

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
              'Team Members',
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

  double calculateTaskProgress() {
    final statusUpper = (task.status).toUpperCase();
    final rawStsUpper = (_rawDbStatus).toUpperCase();
    final isClosed = task.isCompleted ||
        statusUpper == 'CLOSED' ||
        statusUpper == 'COMPLETED' ||
        rawStsUpper == 'CLOSED' ||
        rawStsUpper == 'COMPLETED' ||
        rawStsUpper == 'C';

    final hasReviewer = _reviewerName.isNotEmpty &&
        !_reviewerName.toLowerCase().contains('not assigned') &&
        _reviewerName.toLowerCase() != 'n/a';
    final hasApprover = _approverName.isNotEmpty &&
        !_approverName.toLowerCase().contains('not assigned') &&
        _approverName.toLowerCase() != 'n/a';
    final bool hasProcess = hasReviewer || hasApprover;

    final int totalChecklists = _checklist.length;
    int completedChecklists = 0;
    for (final item in _checklist) {
      if (item is Map) {
        final isChecked = item['isDone'] == true ||
            item['isChecked'] == true ||
            item['is_checked'] == true ||
            item['checked'] == true ||
            item['sts'] == 'C' ||
            item['status'] == 'Completed' ||
            item['status'] == 'C';
        if (isChecked) completedChecklists++;
      }
    }

    if (isClosed) return 100.0;

    if (!hasProcess) {
      // WITHOUT PROCESS: 100% checklist-driven
      if (totalChecklists > 0) {
        return (completedChecklists / totalChecklists) * 100.0;
      } else {
        if (statusUpper == 'IN PROGRESS' || statusUpper == 'WIP' || statusUpper == 'UNDER REVIEW') {
          return 50.0;
        }
        return 0.0;
      }
    } else {
      // WITH PROCESS: Reviewer = 10%, Approver = 10%, Executor/Checklist = 80%
      double progress = 0.0;

      // 1) Executor / Checklist phase (Max 80%)
      final bool isSubmittedOrBeyond = statusUpper.contains('REVIEW') ||
          statusUpper.contains('APPROV') ||
          statusUpper.contains('SUBMIT') ||
          rawStsUpper.contains('REVIEW') ||
          rawStsUpper.contains('APPROV');

      if (isSubmittedOrBeyond) {
        progress = 80.0;
      } else if (totalChecklists > 0) {
        progress = (completedChecklists / totalChecklists) * 80.0;
      } else if (statusUpper == 'IN PROGRESS' || statusUpper == 'WIP') {
        progress = 40.0;
      } else {
        progress = 0.0;
      }

      // 2) Reviewer phase (+10%)
      final bool isReviewerDone = statusUpper.contains('APPROV') ||
          statusUpper.contains('APPROVED') ||
          statusUpper == 'CLOSED' ||
          statusUpper == 'COMPLETED' ||
          rawStsUpper.contains('APPROV');
      if (isReviewerDone) {
        progress += 10.0;
      }

      // 3) Approver phase (+10%)
      if (isClosed) {
        progress += 10.0;
      }

      return progress.clamp(0.0, 100.0);
    }
  }

    Widget _buildTaskProgressMetaRow() {
    final double progressPct = calculateTaskProgress();
    final String pctStr = '${progressPct.toStringAsFixed(1)}%';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                size: 18,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 12),
              const Text(
                'Task Progress',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 0.5),
                ),
                child: Text(
                  pctStr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (progressPct / 100.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                progressPct >= 100.0
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF2563EB),
              ),
            ),
          ),
        ],
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

String calculateTaskLeadLag(TaskItem task, [bool? isCompletedOverride]) {
  final bool isCompleted = isCompletedOverride ?? task.isCompleted;

  // Check explicit backend lead/lag/schedule status first
  final String? apiStatus = task.rawData?['leadLagStatus']?.toString() ?? 
                            task.rawData?['lead_lag_status']?.toString() ?? 
                            task.rawData?['leadLagStatusStr']?.toString() ?? 
                            task.rawData?['scheduleStatus']?.toString();
  if (apiStatus != null && 
      apiStatus.isNotEmpty && 
      apiStatus.toLowerCase() != 'null' && 
      apiStatus.toLowerCase() != 'n/a') {
    return _cleanLeadLagLabel(apiStatus);
  }

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
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  if (!isCompleted) {
    final diffDays = targetDate.difference(today).inDays;
    if (diffDays < 0) {
      return 'OVERDUE (${diffDays.abs()} DAYS)';
    } else if (diffDays == 0) {
      return 'DUE TODAY';
    } else {
      return 'LEAD ($diffDays DAYS)';
    }
  }

  // Task IS completed -> Calculate exact Lead/Lag days relative to actual completed date
  String? actStr = task.rawData?['compDt']?.toString() ??
                   task.rawData?['completedDt']?.toString() ??
                   task.rawData?['actCmpDt']?.toString() ??
                   task.rawData?['act_cmp_dt']?.toString() ??
                   task.rawData?['actlEndDt']?.toString() ??
                   task.rawData?['updDt']?.toString();
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

  String cleaned = s.replaceAll(RegExp(r'^schedule:\s*', caseSensitive: false), '').replaceAll('+', '').replaceAll('-', '').trim();
  return cleaned.toUpperCase();
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
          ),
        ),
      ],
    ),
  );
}

