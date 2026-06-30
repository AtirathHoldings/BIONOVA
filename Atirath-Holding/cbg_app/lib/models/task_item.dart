import 'package:flutter/material.dart';
import 'project_model.dart';

class TaskItem {
  final String id;
  final String title;
  final String subtitle;
  final String date;
  final String tag;
  final Color tagColor;
  final Color tagBg;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String status;
  final String priority;
  final String? description; // 👈 టాస్క్ డిస్క్రిప్షన్ కోసం ఫీల్డ్
  final String? reviewer;
  final String? approver;

  // Live context properties
  final String? projectName;
  final String? milestoneName;
  final String? projectRemarks;
  final String? milestoneRemarks;
  final String? taskRemarks;
  final String? startDate;
  final String? endDate;
  final String? rawStDt;
  final String? rawEndDt;

  const TaskItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.tag,
    required this.tagColor,
    required this.tagBg,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.status,
    required this.priority,
    this.description,
    this.reviewer,
    this.approver,
    this.projectName,
    this.milestoneName,
    this.projectRemarks,
    this.milestoneRemarks,
    this.taskRemarks,
    this.startDate,
    this.endDate,
    this.rawStDt,
    this.rawEndDt,
  });

  factory TaskItem.fromJson(
    Map<String, dynamic> json,
    ProjectModel project,
    Map<String, dynamic> milestone,
  ) {
    final String taskId = json['taskId']?.toString() ?? '0';
    final String taskNm = json['taskNm'] ?? '';
    final String? taskDesc = json['taskDesc'];
    final String dbStatus = json['taskSts'] ?? 'OPEN';
    
    String status = 'Open';
    if (dbStatus == 'WIP') {
      status = 'In Progress';
    } else if (dbStatus == 'SUBMIT_REVIEW' || dbStatus == 'UNDER_REVIEW') {
      status = 'Under Review';
    } else if (dbStatus == 'COMPLETED') {
      status = 'Completed';
    } else if (dbStatus == 'REWORK') {
      status = 'Rework';
    } else {
      status = 'Open';
    }

    final int noOfDays = json['noOfDays'] ?? 0;
    String priority = 'Low';
    if (noOfDays <= 2) {
      priority = 'High';
    } else if (noOfDays <= 5) {
      priority = 'Medium';
    } else {
      priority = 'Low';
    }

    final String rawEndDt = json['endDt'] ?? '';
    final String rawStDt = json['stDt'] ?? '';
    
    String formatDbDate(String rawDate) {
      if (rawDate.isEmpty) return 'No Date';
      try {
        final parsed = DateTime.parse(rawDate);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return "${parsed.day} ${months[parsed.month - 1]} ${parsed.year}";
      } catch (_) {
        return rawDate;
      }
    }

    String dateStr = 'No Date';
    bool isOverdue = false;

    if (rawEndDt.isNotEmpty) {
      try {
        final parsed = DateTime.parse(rawEndDt);
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        
        if (dbStatus != 'COMPLETED' && parsed.isBefore(todayStart)) {
          isOverdue = true;
        }

        if (parsed.year == today.year && parsed.month == today.month && parsed.day == today.day) {
          dateStr = 'Today';
        } else {
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          dateStr = "${parsed.day} ${months[parsed.month - 1]} ${parsed.year}";
        }
      } catch (_) {
        dateStr = rawEndDt;
      }
    }

    String tag = 'Low';
    if (dbStatus == 'COMPLETED') {
      tag = 'Completed';
    } else if (isOverdue) {
      tag = 'Overdue';
    } else if (priority == 'High') {
      tag = 'Critical';
    } else if (priority == 'Medium') {
      tag = 'High';
    } else {
      tag = 'Low';
    }

    Color tagColor = const Color(0xFF16A34A);
    Color tagBg = const Color(0xFFF0FDF4);
    IconData icon = Icons.assignment_outlined;
    Color iconColor = const Color(0xFF16A34A);
    Color iconBg = const Color(0xFFF0FDF4);

    if (tag == 'Critical' || tag == 'Overdue') {
      tagColor = const Color(0xFFE11D48);
      tagBg = const Color(0xFFFFF1F2);
      icon = tag == 'Overdue' ? Icons.warning_amber_rounded : Icons.assignment_outlined;
      iconColor = const Color(0xFFE11D48);
      iconBg = const Color(0xFFFFF1F2);
    } else if (tag == 'High') {
      tagColor = const Color(0xFFEA580C);
      tagBg = const Color(0xFFFFF7ED);
      icon = Icons.shield_outlined;
      iconColor = const Color(0xFFEA580C);
      iconBg = const Color(0xFFFFF7ED);
    } else if (tag == 'Completed') {
      tagColor = Colors.green;
      tagBg = const Color(0xFFDCFCE7);
      icon = Icons.task_alt;
      iconColor = Colors.green;
      iconBg = const Color(0xFFDCFCE7);
    }

    return TaskItem(
      id: taskId,
      title: taskNm,
      subtitle: "${project.prjCd} • ${milestone['mlstnCd'] ?? 'MS'}",
      date: dateStr,
      tag: tag,
      tagColor: tagColor,
      tagBg: tagBg,
      icon: icon,
      iconColor: iconColor,
      iconBg: iconBg,
      status: status,
      priority: priority,
      description: taskDesc,
      reviewer: 'Siva Rama Krishna',
      approver: 'Vikram Kiran',
      projectName: project.prjNm.isNotEmpty ? project.prjNm : project.name,
      milestoneName: milestone['mlstnTtl'] ?? milestone['title'] ?? '',
      projectRemarks: project.addlRem,
      milestoneRemarks: milestone['addlRem'] ?? milestone['addl_rem'],
      taskRemarks: json['addlRem'] ?? json['addl_rem'],
      startDate: formatDbDate(rawStDt),
      endDate: formatDbDate(rawEndDt),
      rawStDt: rawStDt,
      rawEndDt: rawEndDt,
    );
  }

  bool get hasStarted {
    if (rawStDt == null || rawStDt!.isEmpty) {
      return date == 'Today' || tag == 'Overdue';
    }
    try {
      final parsedStart = DateTime.parse(rawStDt!);
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      return !parsedStart.isAfter(todayStart);
    } catch (_) {
      return true;
    }
  }
}

// రెండు స్క్రీన్స్‌లోనూ కనిపించే కామన్ టాస్క్ డేటా పూల్ (Global Tasks)
final List<TaskItem> globalTasks = [
  const TaskItem(
    id: '1',
    title: 'Update excavation progress',
    subtitle: 'PRJ-001 • MS-002',
    date: 'Today',
    tag: 'Critical',
    tagColor: Color(0xFFE11D48),
    tagBg: Color(0xFFFFF1F2),
    icon: Icons.assignment_outlined,
    iconColor: Color(0xFFE11D48),
    iconBg: Color(0xFFFFF1F2),
    status: 'In Progress',
    priority: 'High',
    description: 'Monitor ongoing site excavation, track mud removal volume, and ensure ground leveling alignment matches structural drawings.',
  ),
  const TaskItem(
    id: '2',
    title: 'Upload PCC inspection report',
    subtitle: 'PRJ-001 • MS-001',
    date: 'Today',
    tag: 'High',
    tagColor: Color(0xFFEA580C),
    tagBg: Color(0xFFFFF7ED),
    icon: Icons.shield_outlined,
    iconColor: Color(0xFFEA580C),
    iconBg: Color(0xFFFFF7ED),
    status: 'Open',
    priority: 'Medium',
    description: 'Perform visual quality checks on Plain Cement Concrete (PCC) leveling, verify thickness parameters, and compile the final report.',
  ),
  const TaskItem(
    id: '3',
    title: 'Complete safety checklist',
    subtitle: 'PRJ-005 • MS-005',
    date: '28 Jun 2026',
    tag: 'Low',
    tagColor: Color(0xFF16A34A),
    tagBg: Color(0xFFF0FDF4),
    icon: Icons.people_outline,
    iconColor: Color(0xFF16A34A),
    iconBg: Color(0xFFF0FDF4),
    status: 'Pending',
    priority: 'Low',
    description: 'Inspect labor safety gear including helmets and harnesses, check onsite medical kit readiness, and update safety compliance guidelines.',
    reviewer: 'Ravi Kumar',
  ),
  const TaskItem(
    id: '4',
    title: 'Submit daily progress report',
    subtitle: 'PRJ-001 • MS-004',
    date: '29 Jun 2026',
    tag: 'High',
    tagColor: Color(0xFFEA580C),
    tagBg: Color(0xFFFFF7ED),
    icon: Icons.description_outlined,
    iconColor: Color(0xFFEA580C),
    iconBg: Color(0xFFFFF7ED),
    status: 'Pending',
    priority: 'Medium',
    description: 'Summarize today\'s material consumption, record active labor count, log total heavy machinery running hours, and submit to the supervisor.',
    approver: 'Ravi Kumar',
  ),
  const TaskItem(
    id: '5',
    title: 'Grouting Work Review',
    subtitle: 'PRJ-002 • MS-003',
    date: '20 Jun 2026',
    tag: 'Completed',
    tagColor: Colors.green,
    tagBg: Color(0xFFDCFCE7),
    icon: Icons.task_alt,
    iconColor: Colors.green,
    iconBg: Color(0xFFDCFCE7),
    status: 'Completed',
    priority: 'Low',
    description: 'Review structural concrete foundation grouting stability, examine final core pressure tests, and archive the approval documents.',
  ),
  const TaskItem(
    id: '6',
    title: 'Equipment Inspection Delay',
    subtitle: 'PRJ-005 • MS-006',
    date: '21 Jun 2026',
    tag: 'Overdue',
    tagColor: Colors.red,
    tagBg: Color(0xFFFEE2E2),
    icon: Icons.warning_amber_rounded,
    iconColor: Colors.red,
    iconBg: Color(0xFFFEE2E2),
    status: 'Overdue',
    priority: 'High',
    description: 'Critical inspection for mechanical heavy assets has been delayed. Immediate evaluation required for main concrete mixer and breakdown risk mitigation.',
  ),
];