import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/priority_helper.dart';

// ============================================================
// ✅ EXTERNAL TASK DETAILS SCREEN (100% Identical UI to TaskDetailsScreen)
// ============================================================
class ExternalTaskScreen extends StatefulWidget {
  final String token;

  const ExternalTaskScreen({super.key, required this.token});

  @override
  State<ExternalTaskScreen> createState() => _ExternalTaskScreenState();
}

class _ExternalTaskScreenState extends State<ExternalTaskScreen> {
  bool _isLoadingData = true;
  String? _errorMessage;
  Map<String, dynamic>? _taskData;
  bool _isExpired = false;
  String? _expiredReason;
  String? _expiredMessage;

  final TextEditingController _assigneeNoteController = TextEditingController();
  final TextEditingController _reviewerNoteController = TextEditingController();
  final TextEditingController _approverNoteController = TextEditingController();
  bool _isUpdatingStatus = false;
  bool _isSavingRemarks = false;
  bool _isEditingAssigneeRemarks = false;
  bool _isEditingReviewerRemarks = false;
  bool _isEditingApproverRemarks = false;
  String _tempAssigneeRemarks = '';
  String _tempReviewerRemarks = '';
  String _tempApproverRemarks = '';

  final Map<String, bool> _expandedRemarks = {
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

  List<Map<String, dynamic>> _checklist = [];
  List<Map<String, dynamic>> _attachments = [];
  List<Map<String, dynamic>> _uploadedDocuments = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadExternalTask();
  }

  @override
  void dispose() {
    _assigneeNoteController.dispose();
    _reviewerNoteController.dispose();
    _approverNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadExternalTask() async {
    if (widget.token.isEmpty) {
      setState(() {
        _isLoadingData = false;
        _errorMessage = "Invalid or missing task link token.";
      });
      return;
    }

    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    final res = await ApiService.fetchExternalTask(widget.token);

    if (!mounted) return;

    if (res["success"] == true) {
      final data = res["data"] as Map<String, dynamic>;
      _parseTaskPayload(data, isExpired: data["isExpired"] == true);
    } else if (res["isExpired"] == true) {
      final data = (res["data"] is Map<String, dynamic>) ? res["data"] as Map<String, dynamic> : null;
      setState(() {
        _isLoadingData = false;
        _isExpired = true;
        _expiredReason = res["expiredReason"];
        _expiredMessage = res["message"] ?? "This task access link has expired.";
      });
      if (data != null) {
        _parseTaskPayload(data, isExpired: true);
      }
    } else {
      setState(() {
        _isLoadingData = false;
        _errorMessage = res["message"] ?? "Unable to fetch task details.";
      });
    }
  }

  void _parseTaskPayload(Map<String, dynamic> data, {required bool isExpired}) {
    final rawChecklists = data["checklists"] as List? ?? [];
    final rawAttachments = data["attachments"] as List? ?? [];

    final List<Map<String, dynamic>> mappedChecklist = rawChecklists.map<Map<String, dynamic>>((c) {
      return {
        'chkId': c['chkId'] ?? c['id'],
        'chkCd': c['chkCd'] ?? '',
        'title': (c['chkNm'] ?? c['chkDesc'] ?? c['title'] ?? 'Checklist item').toString(),
        'isDone': c['chkSts'] == true || c['completed'] == true,
      };
    }).toList();

    final List<Map<String, dynamic>> refsList = [];
    final List<Map<String, dynamic>> uploadsList = [];

    for (final att in rawAttachments) {
      final String fileName = att['fileNm'] ?? att['fileName'] ?? 'Attachment';
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
        'fileId': att['fileId'] ?? att['id'],
        'fileName': fileName,
        'size': att['atType'] == 'UPLOAD' ? 'Uploaded' : 'Ref Doc',
        'icon': fileIcon,
        'iconColor': iconColor,
        'bgColor': bgColor,
        'atPath': att['atPath'] ?? att['url'] ?? '',
      };

      if (att['atType'] == 'UPLOAD') {
        uploadsList.add(mapped);
      } else {
        refsList.add(mapped);
      }
    }

    setState(() {
      _isLoadingData = false;
      _taskData = data;
      _isExpired = isExpired || data["isExpired"] == true;
      _expiredReason = data["expiredReason"];
      _expiredMessage = data["expiredMessage"];
      _checklist = mappedChecklist;
      _attachments = refsList;
      _uploadedDocuments = uploadsList;
      _assigneeNoteController.text = (data["executorRem"] ?? data["addlRem"] ?? data["noteTxt"] ?? "").toString();
      _reviewerNoteController.text = (data["reviewerRem"] ?? data["reviewerNote"] ?? data["checkerRem"] ?? "").toString();
      _approverNoteController.text = (data["approverRem"] ?? data["approverNote"] ?? "").toString();
    });
  }

  Future<void> _updateTaskStatus(String targetStatus, {String? subStatus}) async {
    if (_isUpdatingStatus || _isExpired) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    final res = await ApiService.updateExternalTaskStatus(
      widget.token,
      taskSts: targetStatus,
      subStatus: subStatus,
      remarks: _assigneeNoteController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isUpdatingStatus = false;
    });

    if (res["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            targetStatus == 'WIP'
                ? '✅ Task Started Successfully!'
                : '✅ Task Submitted for Review Successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadExternalTask();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res["message"] ?? 'Failed to update task status.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveRemarks() async {
    if (_isSavingRemarks || _isExpired) return;

    setState(() {
      _isSavingRemarks = true;
    });

    final res = await ApiService.updateExternalTaskStatus(
      widget.token,
      remarks: _assigneeNoteController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSavingRemarks = false;
      _isEditingAssigneeRemarks = false;
    });

    if (res["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Executor remarks saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res["message"] ?? 'Failed to save remarks.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleChecklist(int index, bool newValue) async {
    final taskSts = (_taskData?["taskSts"] ?? "").toString().toUpperCase();
    if (taskSts != "WIP" && taskSts != "IN PROGRESS") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Checklist can only be updated when task is In Progress (WIP). Click 'Start Working' first."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (newValue == true) {
      if (index == _checklist.length - 1) {
        for (int i = 0; i < _checklist.length - 1; i++) {
          if (_checklist[i]['isDone'] != true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Please complete all previous tasks before checking the final one!'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
        }
      }
    }

    final item = _checklist[index];
    final chkId = item["chkId"];
    if (chkId == null) return;

    setState(() {
      _checklist[index]["isDone"] = newValue;
    });

    final success = await ApiService.updateExternalChecklistItem(widget.token, chkId, newValue);

    if (!success && mounted) {
      setState(() {
        _checklist[index]["isDone"] = !newValue;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to update checklist item.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
    if (_isExpired) return;
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
        final double sizeInMb = (await file.length()) / (1024 * 1024);
        final String sizeStr = '${sizeInMb.toStringAsFixed(1)} MB';

        setState(() {
          _uploadedDocuments.add({
            'fileId': DateTime.now().millisecondsSinceEpoch,
            'fileName': file.name,
            'size': sizeStr,
            'icon': Icons.image,
            'iconColor': Colors.orange,
            'bgColor': const Color(0xFFFFF7ED),
            'atPath': file.path,
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${file.name} selected!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e'), backgroundColor: Colors.red),
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
        }

        setState(() {
          _uploadedDocuments.add({
            'fileId': DateTime.now().millisecondsSinceEpoch,
            'fileName': fileName,
            'size': sizeStr,
            'icon': fileIcon,
            'iconColor': iconColor,
            'bgColor': bgColor,
            'atPath': platformFile.path!,
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $fileName selected!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ============================================================
  // ✅ EXTERNAL PROFILE & NOTIFICATION DIALOGS
  // ============================================================

  void _showExternalProfileDialog() {
    final extEmpNm = _taskData?["extEmpNm"] ?? _taskData?["employeeName"] ?? "External Guest";
    final extEmpEmail = _taskData?["extEmpEmail"] ?? _taskData?["email"] ?? "—";
    final companyNm = _taskData?["companyNm"] ?? "—";
    final expiryDt = _taskData?["expiryDt"];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryBlue.withAlpha(30),
              child: const Icon(Icons.person_outline_rounded, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'External Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Text(
                  'Guest / External Workspace',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 16),
            _buildProfileDetailRow(Icons.badge_outlined, 'Name', extEmpNm),
            _buildProfileDetailRow(Icons.email_outlined, 'Email', extEmpEmail),
            _buildProfileDetailRow(Icons.business_outlined, 'Company', companyNm),
            _buildProfileDetailRow(Icons.security_outlined, 'Access Role', 'External Assignee'),
            _buildProfileDetailRow(Icons.timer_outlined, 'Link Expiry', _formatDate(expiryDt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ),
          const Text(' :  ', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  void _showExternalNotificationDialog() {
    final expiryDt = _taskData?["expiryDt"];
    final isSeqLocked = _taskData?["isSequentialLocked"] == true;
    final lockReason = _taskData?["lockReason"];
    final taskNm = _taskData?["taskNm"] ?? "Assigned Task";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppColors.openBg, shape: BoxShape.circle),
              child: const Icon(Icons.notifications_active_outlined, color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Task Notifications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotificationItem(
              icon: Icons.task_alt_rounded,
              title: 'Task Assignment',
              desc: 'You have external access for task: $taskNm',
              time: 'Active',
              color: AppColors.primaryBlue,
            ),
            if (expiryDt != null) ...[
              const SizedBox(height: 8),
              _buildNotificationItem(
                icon: Icons.timer_outlined,
                title: 'Access Expiry Deadline',
                desc: 'This link is valid until ${_formatDate(expiryDt)}',
                time: 'Notice',
                color: AppColors.inProgress,
              ),
            ],
            if (isSeqLocked) ...[
              const SizedBox(height: 8),
              _buildNotificationItem(
                icon: Icons.lock_clock_rounded,
                title: 'Sequential Dependency',
                desc: lockReason ?? 'Predecessor task must be completed first.',
                time: 'Warning',
                color: AppColors.overdue,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String desc,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
                    Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B), height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ MAIN BUILD METHOD (Matches TaskDetailsScreen Exactly)
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('External task session active.'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: _buildExternalAppBar(),
        body: _buildBodyContent(),
      ),
    );
  }

  PreferredSizeWidget _buildExternalAppBar() {
    final extEmpNm = _taskData?["extEmpNm"] ?? _taskData?["employeeName"] ?? "Guest";
    final firstLetter = extEmpNm.isNotEmpty ? extEmpNm[0].toUpperCase() : "G";

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Image.asset(
            'assets/BioNova.webp',
            height: 32,
            width: 32,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text('CBG', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          const Text(
            'Task Details',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B), size: 20),
          tooltip: 'Refresh Task Details',
          onPressed: _loadExternalTask,
        ),
        GestureDetector(
          onTap: _showExternalProfileDialog,
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6C4EFF),
              child: Text(
                firstLetter,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFF1F5F9), height: 1),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoadingData) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryBlue),
            SizedBox(height: 16),
            Text('Loading task workspace...', style: TextStyle(color: AppColors.textGrey, fontSize: 14)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: AppColors.overdueBg, shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded, color: AppColors.overdue, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadExternalTask,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final task = _taskData ?? {};
    final taskCode = task["taskCd"] ?? "TSK-${task["taskId"] ?? ""}";
    final taskTitle = task["taskNm"] ?? "Untitled Task";
    final taskDesc = task["taskDesc"] ?? "General task evaluation, quality documentation compliance, and regular milestone checks are required for this activity.";
    final prjNm = task["prjNm"] ?? "Project";
    final mlstnTtl = task["mlstnTtl"] ?? "Milestone";
    final taskSts = (task["taskSts"] ?? "OPEN").toString().toUpperCase();
    final stDt = task["stDt"] ?? "";
    final endDt = task["endDt"] ?? "";
    final expiryDt = task["expiryDt"] ?? "";
    final isSequentialLocked = task["isSequentialLocked"] == true;
    final lockReason = task["lockReason"];
    final String extEmpNm = (task["extEmpNm"] ?? task["ext_emp_nm"] ?? task["empNm"] ?? task["emp_nm"] ?? task["employeeName"] ?? task["employee_name"] ?? task["executorNm"] ?? task["executor_nm"] ?? task["assignedToNm"] ?? task["assigned_to_name"] ?? "External Guest").toString().trim();
    final String extEmpEmail = (task["extEmpEmail"] ?? task["email"] ?? "").toString().trim();
    final String companyNm = (task["companyNm"] ?? task["company_nm"] ?? task["companyName"] ?? "").toString().trim();
    final String reviewerNm = (task["reviewerNm"] ?? task["reviewer_nm"] ?? task["reviewerName"] ?? task["reviewer_name"] ?? task["reviewer"] ?? task["checkerNm"] ?? task["checker_nm"] ?? "").toString().trim();
    final String approverNm = (task["approverNm"] ?? task["approver_nm"] ?? task["approverName"] ?? task["approver_name"] ?? task["approver"] ?? task["apprEmpNm"] ?? task["appr_emp_nm"] ?? "").toString().trim();

    // Dynamic Priority Calculation matching Web priority.js
    final priorityMeta = PriorityHelper.calculateDynamicPriority(
      basePriority: task["priority"],
      startDateVal: stDt,
      endDateVal: endDt,
    );

    final String priority = priorityMeta.name;
    final Color priorityColor = priorityMeta.color;
    final Color priorityBg = priorityMeta.bgColor;
    final Color priorityBorderColor = priorityMeta.borderColor;
    final IconData priorityIcon = priorityMeta.icon;

    int completedCount = _checklist.where((item) => item['isDone'] == true).length;
    bool isLastBoxChecked = _checklist.isNotEmpty && _checklist.last['isDone'] == true;

    final String mainStatus = _isExpired
        ? 'Expired'
        : (taskSts == 'CLOSED' || taskSts == 'COMPLETED')
            ? 'Closed'
            : (taskSts == 'OPEN')
                ? 'Open'
                : 'In Progress';

    String? subStatusText;
    if (!_isExpired && (taskSts == 'SUBMIT_REVIEW' || taskSts == 'UNDER_REVIEW' || taskSts == 'UNDER REVIEW')) {
      subStatusText = 'Under Review';
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expiry Alert Banner (If Expired)
            if (_isExpired) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.overdueBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.overdue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.overdue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Access Link Expired / Locked',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.overdue, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _expiredMessage ?? 'This access link for the task is no longer active.',
                            style: const TextStyle(color: AppColors.textDark, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Sequential Lock Banner
            if (isSequentialLocked) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_clock_rounded, color: Colors.amber.shade800, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sequential Task Locked',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lockReason ?? 'Predecessor task must be completed first before starting this task.',
                            style: TextStyle(color: Colors.amber.shade800, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 1. Top Header Card Banner (Exact match to TaskDetailsScreen)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: priorityBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: priorityBorderColor,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(priorityIcon, color: priorityColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          taskTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: priorityBorderColor),
                        ),
                        child: Text(
                          priority,
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Meta Information Card (Exact match to TaskDetailsScreen)
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
                  _buildMetaRow('Project', Icons.folder_open_outlined, prjNm, isValuePurple: true),
                  _buildMetaRow('Milestone', Icons.layers_outlined, mlstnTtl, isValuePurple: true),
                  _buildMetaRow('Task Code', Icons.tag_outlined, taskCode, isValuePurple: true),
                  _buildMetaRow('Your Role', Icons.person_outline, 'External Guest', isStatusBadge: true),
                  _buildMetaRow('Start Date', Icons.date_range_outlined, _formatDate(stDt)),
                  _buildMetaRow('Due Date', Icons.calendar_today_outlined, _formatDate(endDt)),
                  if (expiryDt.toString().isNotEmpty)
                    _buildMetaRow('Link Expiry', Icons.timer_outlined, _formatDate(expiryDt), isValueRed: true),
                  _buildMetaRow('Executor', Icons.person_outline, extEmpNm + (companyNm.isNotEmpty ? ' ($companyNm)' : '')),
                  _buildMetaRow('Reviewer', Icons.rate_review_outlined, (reviewerNm != null && reviewerNm.toString().trim().isNotEmpty && reviewerNm.toString() != '0') ? reviewerNm.toString() : 'N/A'),
                  _buildMetaRow('Approver', Icons.verified_outlined, (approverNm != null && approverNm.toString().trim().isNotEmpty && approverNm.toString() != '0') ? approverNm.toString() : 'N/A'),
                  _buildMetaRow('Status', Icons.radio_button_checked, mainStatus, isStatusBadge: true),
                  if (subStatusText != null)
                    _buildMetaRow('Process Status', Icons.sync, subStatusText, isStatusBadge: true),

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
                        taskDesc,
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

                      // Reference Remarks - Matching TaskDetailsScreen EXACTLY
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
                          _buildRemarkSection(
                            'Task Remarks',
                            _buildRemarksContentList(
                              (task["addlRem"] ?? task["noteTxt"] ?? '').toString(),
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
                                    onSave: _saveRemarks,
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
                                      title: 'Executor Remarks',
                                      content: value.text,
                                      themeColor: const Color(0xFF4F46E5),
                                      canEdit: !_isExpired,
                                      onEditPressed: () {
                                        setState(() {
                                          _tempAssigneeRemarks = _assigneeNoteController.text;
                                          _isEditingAssigneeRemarks = true;
                                        });
                                      },
                                    ),
                                  ),
                            const Color(0xFF4F46E5),
                          ),
                          _buildRemarkSection(
                            'Reviewer Remarks',
                            _isEditingReviewerRemarks
                                ? _buildRemarksEditor(
                                    controller: _reviewerNoteController,
                                    themeColor: const Color(0xFF7C3AED),
                                    onSave: _saveRemarks,
                                    onCancel: () {
                                      setState(() {
                                        _reviewerNoteController.text = _tempReviewerRemarks;
                                        _isEditingReviewerRemarks = false;
                                      });
                                    },
                                  )
                                : ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: _reviewerNoteController,
                                    builder: (context, value, _) => _buildRemarksContentWithEdit(
                                      title: 'Reviewer Remarks',
                                      content: value.text,
                                      themeColor: const Color(0xFF7C3AED),
                                      canEdit: !_isExpired,
                                      onEditPressed: () {
                                        setState(() {
                                          _tempReviewerRemarks = _reviewerNoteController.text;
                                          _isEditingReviewerRemarks = true;
                                        });
                                      },
                                    ),
                                  ),
                            const Color(0xFF7C3AED),
                          ),
                          _buildRemarkSection(
                            'Approver Remarks',
                            _isEditingApproverRemarks
                                ? _buildRemarksEditor(
                                    controller: _approverNoteController,
                                    themeColor: const Color(0xFF059669),
                                    onSave: _saveRemarks,
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
                                      themeColor: const Color(0xFF059669),
                                      canEdit: !_isExpired,
                                      onEditPressed: () {
                                        setState(() {
                                          _tempApproverRemarks = _approverNoteController.text;
                                          _isEditingApproverRemarks = true;
                                        });
                                      },
                                    ),
                                  ),
                            const Color(0xFF059669),
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.0),
                        child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                      ),

                      // Attachments ExpansionTile - Matching TaskDetailsScreen EXACTLY
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
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
                          children: _attachments.isEmpty
                              ? [const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No reference attachments found.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))))]
                              : _attachments.map((ref) {
                                  return _buildAttachmentTile(
                                    ref['fileName'] ?? '',
                                    ref['size'] ?? '',
                                    ref['icon'] as IconData? ?? Icons.description_outlined,
                                    ref['iconColor'] as Color? ?? Colors.blue,
                                    ref['bgColor'] as Color? ?? const Color(0xFFEFF6FF),
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

                      // Documents Uploaded Column - Matching TaskDetailsScreen EXACTLY
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
                              if (!_isExpired)
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
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_uploadedDocuments.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('No uploaded documents.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            )
                          else
                            ..._uploadedDocuments.map((doc) {
                              return _buildAttachmentTile(
                                doc['fileName']!,
                                doc['size']!,
                                doc['icon'] as IconData,
                                doc['iconColor'] as Color,
                                doc['bgColor'] as Color,
                                atPath: doc['atPath'] as String?,
                                showDownload: true,
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

            // 3. Checklist Card (Exact match to TaskDetailsScreen)
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
                      final bool isDone = item['isDone'] == true;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _isExpired ? null : () => _toggleChecklist(index, !isDone),
                              child: Icon(
                                isDone ? Icons.check_box : Icons.check_box_outline_blank,
                                color: isDone ? Colors.green : Colors.grey[400],
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['title'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDone ? const Color(0xFF64748B) : const Color(0xFF1E293B),
                                  fontWeight: FontWeight.w500,
                                  decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
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

            // 4. Workflow Action Section (Exact match to TaskDetailsScreen)
            _buildWorkflowActionBar(
              isLastBoxChecked: isLastBoxChecked,
              taskSts: taskSts,
              isSequentialLocked: isSequentialLocked,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ✅ HELPER WIDGETS MATCHING TaskDetailsScreen EXACTLY
  // ============================================================

  Widget _buildMetaRow(
    String label,
    IconData icon,
    String value, {
    bool isValuePurple = false,
    bool isValueRed = false,
    bool isStatusBadge = false,
  }) {
    Color valueColor = const Color(0xFF475569);
    if (isValuePurple) valueColor = const Color(0xFF7C3AED);
    if (isValueRed) valueColor = const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          const Text(' :  ', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Expanded(
            child: isStatusBadge
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.getStatusBgColor(value),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.getStatusColor(value).withOpacity(0.3)),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          color: AppColors.getStatusColor(value),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: valueColor),
                  ),
          ),
        ],
      ),
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
                    color: themeColor.withOpacity(0.04),
                    border: Border.all(color: themeColor.withOpacity(0.15)),
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

  Widget _buildRemarksContentList(String text, Color color) {
    if (text.trim().isEmpty) {
      return const Text('No remarks available.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic));
    }
    return Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), height: 1.4));
  }

  Widget _buildRemarksContentWithEdit({
    required String title,
    required String content,
    required Color themeColor,
    required bool canEdit,
    required VoidCallback onEditPressed,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            content.trim().isNotEmpty ? content : 'No $title entered yet.',
            style: TextStyle(
              fontSize: 12,
              color: content.trim().isNotEmpty ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
              fontStyle: content.trim().isNotEmpty ? FontStyle.normal : FontStyle.italic,
              height: 1.4,
            ),
          ),
        ),
        if (canEdit)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF7C3AED)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onEditPressed,
            tooltip: 'Edit $title',
          ),
      ],
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
        TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: 'Enter executor remarks...',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: themeColor.withOpacity(0.3)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttachmentTile(
    String fileName,
    String size,
    IconData icon,
    Color iconColor,
    Color bgColor, {
    String? atPath,
    bool showDownload = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showDownload)
            IconButton(
              icon: const Icon(Icons.file_download_outlined, color: Color(0xFF64748B), size: 18),
              onPressed: () => _downloadFile(fileName, atPath),
              tooltip: 'Download / View',
            ),
        ],
      ),
    );
  }

  Widget _buildWorkflowActionBar({
    required bool isLastBoxChecked,
    required String taskSts,
    required bool isSequentialLocked,
  }) {
    if (_isExpired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.overdueBg, borderRadius: BorderRadius.circular(12)),
        child: const Text(
          '🔒 Task Link Expired — Further edits disabled.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.overdue, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );
    }

    if (isSequentialLocked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
        child: Text(
          '🔒 Task Locked: Waiting for predecessor task to complete.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );
    }

    // ── Open / Pending / Assigned ────────
    if (taskSts == 'OPEN' || taskSts == 'PENDING' || taskSts == 'ASSIGNED') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isUpdatingStatus ? null : () => _updateTaskStatus('WIP'),
          icon: _isUpdatingStatus
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
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

    // ── In Progress / WIP / Rework / Reassigned ────────
    if (taskSts == 'WIP' || taskSts == 'IN PROGRESS' || taskSts == 'REWORK' || taskSts == 'REASSIGNED') {
      final canSubmit = _checklist.isEmpty || _checklist.every((c) => c['isDone'] == true);
      final reviewerNm = (_taskData?["reviewerNm"] ?? _taskData?["reviewer_nm"] ?? _taskData?["reviewer"] ?? '').toString();
      final approverNm = (_taskData?["approverNm"] ?? _taskData?["approver_nm"] ?? _taskData?["approver"] ?? '').toString();
      final hasProcess = reviewerNm.isNotEmpty || approverNm.isNotEmpty;

      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: !canSubmit
                ? ElevatedButton.icon(
                    onPressed: () async {
                      await _saveRemarks();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Remarks & Checklist updated!'),
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
                    onPressed: _isUpdatingStatus ? null : () => _updateTaskStatus('SUBMIT_REVIEW', subStatus: 'Under Review'),
                    icon: _isUpdatingStatus
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(
                            hasProcess
                                ? (taskSts == 'REWORK' || taskSts == 'REASSIGNED' ? Icons.redo_rounded : Icons.send_rounded)
                                : Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                    label: Text(
                      hasProcess
                          ? (taskSts == 'REWORK' || taskSts == 'REASSIGNED' ? 'Resubmit for Review' : 'Submit for Review')
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

    // ── Under Review / SUBMIT_REVIEW ────────
    if (taskSts == 'SUBMIT_REVIEW' || taskSts == 'UNDER_REVIEW' || taskSts == 'UNDER REVIEW') {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
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

    if (taskSts == 'CLOSED' || taskSts == 'COMPLETED') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.closedBg, borderRadius: BorderRadius.circular(12)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.closed, size: 20),
            SizedBox(width: 8),
            Text('Task Completed & Closed', style: TextStyle(color: AppColors.closed, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '—';
    final str = dateVal.toString();
    if (str.isEmpty) return '—';
    try {
      final dt = DateTime.parse(str);
      return '${dt.day.toString().padLeft(2, '0')}-${_monthName(dt.month)}-${dt.year}';
    } catch (_) {
      return str;
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
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
    const double height = 38.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        height: height,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Positioned(
              left: 14,
              right: 0,
              top: 0,
              bottom: 0,
              child: ClipPath(
                clipper: ArrowBannerClipper(),
                child: Container(
                  padding: const EdgeInsets.only(left: 36, right: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [themeColor.withOpacity(0.95), themeColor],
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
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Icon(
                        isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 20,
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
                    width: height * 0.62,
                    height: height * 0.62,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: themeColor,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
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
