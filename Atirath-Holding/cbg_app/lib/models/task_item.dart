import 'package:flutter/material.dart';

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
  });
}

// రెండు స్క్రీన్స్‌లోనూ కనిపించే కామన్ టాస్క్ డేటా పూల్ (Global Tasks)
final List<TaskItem> globalTasks = [
  const TaskItem(
    id: '1',
    title: 'Update excavation progress',
    subtitle: 'PRJ-001 • Excavation Work',
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
    subtitle: 'PRJ-001 • PCC Work',
    date: 'Today',
    tag: 'High',
    tagColor: Color(0xFFEA580C),
    tagBg: Color(0xFFFFF7ED),
    icon: Icons.shield_outlined,
    iconColor: Color(0xFFEA580C),
    iconBg: Color(0xFFFFF7ED),
    status: 'Pending',
    priority: 'Medium',
    description: 'Perform visual quality checks on Plain Cement Concrete (PCC) leveling, verify thickness parameters, and compile the final report.',
  ),
  const TaskItem(
    id: '3',
    title: 'Complete safety checklist',
    subtitle: 'PRJ-005 • Safety',
    date: '30 May 2025',
    tag: 'Low',
    tagColor: Color(0xFF16A34A),
    tagBg: Color(0xFFF0FDF4),
    icon: Icons.people_outline,
    iconColor: Color(0xFF16A34A),
    iconBg: Color(0xFFF0FDF4),
    status: 'Pending',
    priority: 'Low',
    description: 'Inspect labor safety gear including helmets and harnesses, check onsite medical kit readiness, and update safety compliance guidelines.',
  ),
  const TaskItem(
    id: '4',
    title: 'Submit daily progress report',
    subtitle: 'PRJ-001 • Daily Reporting',
    date: '31 May 2025',
    tag: 'High',
    tagColor: Color(0xFFEA580C),
    tagBg: Color(0xFFFFF7ED),
    icon: Icons.description_outlined,
    iconColor: Color(0xFFEA580C),
    iconBg: Color(0xFFFFF7ED),
    status: 'Pending',
    priority: 'Medium',
    description: 'Summarize today\'s material consumption, record active labor count, log total heavy machinery running hours, and submit to the supervisor.',
  ),
  const TaskItem(
    id: '5',
    title: 'Grouting Work Review',
    subtitle: 'PRJ-002 • Infrastructure',
    date: '10 Jun 2025',
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
    subtitle: 'PRJ-005 • Maintenance',
    date: 'May 10, 2024',
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