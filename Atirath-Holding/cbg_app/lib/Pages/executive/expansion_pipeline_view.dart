import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/executive_api_service.dart';
import '../../widgets/module_ui_widgets.dart';

class ExpansionPipelineView extends StatefulWidget {
  const ExpansionPipelineView({super.key});

  @override
  State<ExpansionPipelineView> createState() => _ExpansionPipelineViewState();
}

class _ExpansionPipelineViewState extends State<ExpansionPipelineView> {
  static const List<String> _stages = [
    'All Stages',
    'Land Acquisition',
    'Civil Foundation',
    'Mechanical Erection',
    'E&I Installation',
    'Cold/Hot Commissioning',
  ];

  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _stageFilter = 'All Stages';
  String _typeFilter = 'All Types';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final data = await ExecutiveApiService.getPipelineProjects();
    if (mounted) {
      setState(() {
        _projects = data;
        _isLoading = false;
      });
    }
  }

  double _num(dynamic v) => v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0.0);

  List<Map<String, dynamic>> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _projects.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final id = (p['id'] ?? '').toString().toLowerCase();
      final loc = (p['location'] ?? '').toString().toLowerCase();
      final pm = (p['leadPM'] ?? '').toString().toLowerCase();
      final matchesSearch = name.contains(q) || id.contains(q) || loc.contains(q) || pm.contains(q);
      final matchesStage = _stageFilter == 'All Stages' || p['stage'] == _stageFilter;
      final matchesType = _typeFilter == 'All Types' || p['type'] == _typeFilter;
      return matchesSearch && matchesStage && matchesType;
    }).toList();
  }

  void _openForm({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final idCtrl = TextEditingController(
      text: isEdit ? (existing['id'] ?? '').toString() : 'EXP-PLANT-0${_projects.length + 1}',
    );
    final nameCtrl = TextEditingController(text: isEdit ? (existing['name'] ?? '').toString() : '');
    final locCtrl = TextEditingController(text: isEdit ? (existing['location'] ?? '').toString() : '');
    final capCtrl = TextEditingController(text: isEdit ? (existing['capacity'] ?? '').toString() : '');
    final compCtrl = TextEditingController(text: isEdit ? (existing['completionPct'] ?? 0).toString() : '0');
    final capexAppCtrl = TextEditingController(text: isEdit ? (existing['capexApproved'] ?? '').toString() : '');
    final capexSpentCtrl = TextEditingController(text: isEdit ? (existing['capexSpent'] ?? '').toString() : '');
    final targetDateCtrl = TextEditingController(text: isEdit ? (existing['targetCommissioning'] ?? '').toString() : '');
    final pmCtrl = TextEditingController(text: isEdit ? (existing['leadPM'] ?? '').toString() : '');
    final milestoneCtrl = TextEditingController(text: isEdit ? (existing['upcomingMilestone'] ?? '').toString() : '');

    String type = isEdit ? (existing['type'] ?? 'Greenfield').toString() : 'Greenfield';
    String stage = isEdit ? (existing['stage'] ?? 'Civil Foundation').toString() : 'Civil Foundation';
    String status = isEdit ? (existing['status'] ?? 'On Track').toString() : 'On Track';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.layers, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Expansion Pipeline Project' : 'Add New Expansion Pipeline Project',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                TextField(controller: idCtrl, decoration: moduleInputDecoration('Project Code *')),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: moduleInputDecoration('Project Facility Name *')),
                const SizedBox(height: 10),
                TextField(controller: locCtrl, decoration: moduleInputDecoration('Location / Regional Site *')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: moduleInputDecoration('Project Type'),
                        items: const [
                          DropdownMenuItem(value: 'Greenfield', child: Text('Greenfield')),
                          DropdownMenuItem(value: 'Brownfield', child: Text('Brownfield')),
                        ],
                        onChanged: (v) => setModalState(() => type = v ?? 'Greenfield'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(controller: capCtrl, decoration: moduleInputDecoration('Capacity', hint: '20 TPD CBG')),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: stage,
                  decoration: moduleInputDecoration('Current Execution Stage'),
                  items: _stages.where((s) => s != 'All Stages').map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setModalState(() => stage = v ?? 'Civil Foundation'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: moduleInputDecoration('Operational Status'),
                        items: const [
                          DropdownMenuItem(value: 'Ahead of Schedule', child: Text('Ahead of Schedule')),
                          DropdownMenuItem(value: 'On Track', child: Text('On Track')),
                          DropdownMenuItem(value: 'Hot Commissioning', child: Text('Hot Commissioning')),
                          DropdownMenuItem(value: 'Permit Review', child: Text('Permit Review')),
                          DropdownMenuItem(value: 'Delay Mitigation', child: Text('Delay Mitigation')),
                        ],
                        onChanged: (v) => setModalState(() => status = v ?? 'On Track'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: compCtrl,
                        keyboardType: TextInputType.number,
                        decoration: moduleInputDecoration('Completion (%)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: milestoneCtrl, decoration: moduleInputDecoration('Immediate Milestone / Next Step')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: capexAppCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: moduleInputDecoration('Approved CapEx (₹ Cr) *'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: capexSpentCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: moduleInputDecoration('Actual CapEx (₹ Cr)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: targetDateCtrl,
                        readOnly: true,
                        decoration: moduleInputDecoration('Target Commissioning'),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            targetDateCtrl.text = picked.toIso8601String().split('T').first;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: pmCtrl, decoration: moduleInputDecoration('Lead PM'))),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty || locCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please provide Project Name and Location.')),
                        );
                        return;
                      }
                      final payload = {
                        'id': idCtrl.text.trim(),
                        'name': nameCtrl.text.trim(),
                        'type': type,
                        'location': locCtrl.text.trim(),
                        'capacity': capCtrl.text.trim(),
                        'stage': stage,
                        'startDate': existing?['startDate'] ?? DateTime.now().toIso8601String().split('T').first,
                        'targetCommissioning': targetDateCtrl.text.trim(),
                        'completionPct': int.tryParse(compCtrl.text.trim()) ?? 0,
                        'capexApproved': capexAppCtrl.text.trim(),
                        'capexSpent': capexSpentCtrl.text.trim(),
                        'leadPM': pmCtrl.text.trim(),
                        'status': status,
                        'upcomingMilestone': milestoneCtrl.text.trim(),
                      };

                      if (isEdit) {
                        setState(() {
                          _projects = _projects
                              .map((p) => p['id'] == existing['id'] ? payload : p)
                              .toList();
                        });
                      } else {
                        setState(() => _projects = [payload, ..._projects]);
                        ExecutiveApiService.savePipelineProject(payload).then((res) {
                          if (res != null && mounted) {
                            setState(() {
                              _projects = [res, ..._projects.where((p) => p['id'] != payload['id'])];
                            });
                          }
                        }).catchError((_) {});
                      }
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: Text(isEdit ? 'Update Pipeline Project' : 'Save Pipeline Project'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('${p['name'] ?? ''}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${p['id']} • ${p['type']}', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
            const SizedBox(height: 6),
            Text('Location: ${p['location'] ?? ''}'),
            Text('Current Stage: ${p['stage'] ?? ''}'),
            Text('Plant Capacity: ${p['capacity'] ?? ''}'),
            Text('CapEx Budget: ₹${p['capexApproved'] ?? 0} Cr Approved (₹${p['capexSpent'] ?? 0} Cr Deployed)'),
            Text('Completion: ${p['completionPct'] ?? 0}% • Target: ${p['targetCommissioning'] ?? ''}'),
            Text('Lead PM: ${p['leadPM'] ?? ''}'),
            Text('Next Milestone: ${p['upcomingMilestone'] ?? ''}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _deleteProject(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to remove project $id from pipeline?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ExecutiveApiService.deletePipelineProject(id).catchError((_) {});
      setState(() => _projects.removeWhere((p) => p['id'].toString() == id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCapex = _projects.fold<double>(0, (acc, p) => acc + _num(p['capexApproved']));
    final totalSpent = _projects.fold<double>(0, (acc, p) => acc + _num(p['capexSpent']));
    final avgCompletion = _projects.isEmpty
        ? 0
        : (_projects.fold<double>(0, (acc, p) => acc + _num(p['completionPct'])) / _projects.length).round();
    final gfCount = _projects.where((p) => p['type'] == 'Greenfield').length;
    final bfCount = _projects.where((p) => p['type'] == 'Brownfield').length;
    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: _loadProjects,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            'Executive monitoring of Greenfield and Brownfield bio-refinery capital projects across regional growth corridors.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'BioNova_Expansion_Pipeline_${DateTime.now().toIso8601String().split('T').first}.csv',
                    headers: ['ID', 'Name', 'Type', 'Location', 'Stage', 'Completion %', 'Capex Approved (Cr)', 'Capex Spent (Cr)', 'Lead PM', 'Status', 'Milestone'],
                    rows: filtered
                        .map((p) => [
                              p['id'],
                              p['name'],
                              p['type'],
                              p['location'],
                              p['stage'],
                              '${p['completionPct']}%',
                              p['capexApproved'],
                              p['capexSpent'],
                              p['leadPM'],
                              p['status'],
                              p['upcomingMilestone'],
                            ])
                        .toList(),
                  ),
                  icon: const Icon(Icons.download, size: 15),
                  label: const Text('Export CSV'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF059669)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Project'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ModuleKpiGrid(
            items: [
              ModuleKpiItem(
                label: 'TOTAL EXPANSION CAPEX',
                value: '₹${totalCapex.toStringAsFixed(1)} Cr',
                subtext: '₹${totalSpent.toStringAsFixed(1)} Cr Deployed (${totalCapex > 0 ? ((totalSpent / totalCapex) * 100).round() : 0}%)',
                accentColor: const Color(0xFF059669),
                icon: Icons.account_balance_wallet_outlined,
              ),
              ModuleKpiItem(
                label: 'ACTIVE CAPITAL PROJECTS',
                value: '${_projects.length} Facilities',
                subtext: '$gfCount Greenfield • $bfCount Brownfield',
                accentColor: const Color(0xFF2563EB),
                icon: Icons.factory_outlined,
              ),
              ModuleKpiItem(
                label: 'AVG PIPELINE VELOCITY',
                value: _projects.isNotEmpty ? '$avgCompletion%' : '--',
                subtext: _projects.isNotEmpty ? '+3.4% Milestone Pace' : 'No Active Projects',
                accentColor: const Color(0xFF059669),
                icon: Icons.trending_up,
              ),
              ModuleKpiItem(
                label: 'NEAREST COMMISSIONING',
                value: _projects.isNotEmpty ? (_projects.first['name'] ?? 'Upcoming Unit').toString() : '--',
                subtext: _projects.isNotEmpty ? '${_projects.first['completionPct'] ?? 0}% Execution Complete' : 'No Scheduled Commissioning',
                accentColor: const Color(0xFFD97706),
                icon: Icons.schedule,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: moduleInputDecoration('Search project name, ID, location, or PM...').copyWith(
              prefixIcon: const Icon(Icons.search, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _typeFilter,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Type'),
                  items: const [
                    DropdownMenuItem(value: 'All Types', child: Text('All Project Types')),
                    DropdownMenuItem(value: 'Greenfield', child: Text('Greenfield')),
                    DropdownMenuItem(value: 'Brownfield', child: Text('Brownfield')),
                  ],
                  onChanged: (v) => setState(() => _typeFilter = v ?? 'All Types'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _stageFilter,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Stage'),
                  items: _stages.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _stageFilter = v ?? 'All Stages'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(
              icon: Icons.layers_outlined,
              title: 'No expansion projects match criteria',
              subtitle: 'Add a pipeline project or adjust your search filters.',
            )
          else
            ...filtered.map((p) {
              final capApp = _num(p['capexApproved']);
              final capSpent = _num(p['capexSpent']);
              final pct = _num(p['completionPct']).clamp(0, 100);
              final status = (p['status'] ?? 'On Track').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (p['name'] ?? '').toString(),
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A)),
                          ),
                        ),
                        ModuleTag(
                          text: status,
                          bgColor: status.contains('Ahead') || status.contains('Commissioning')
                              ? const Color(0xFFDCFCE7)
                              : status.contains('Track')
                                  ? const Color(0xFFDBEAFE)
                                  : const Color(0xFFFEF3C7),
                          textColor: status.contains('Ahead') || status.contains('Commissioning')
                              ? const Color(0xFF166534)
                              : status.contains('Track')
                                  ? const Color(0xFF1E40AF)
                                  : const Color(0xFF92400E),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p['id']} • ${p['type']} • ${p['capacity'] ?? ''}',
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                    ),
                    Text(
                      'Location: ${p['location']} • PM: ${p['leadPM']}',
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF2563EB)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stage: ${p['stage']} (Next: ${p['upcomingMilestone'] ?? '-'})',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('CapEx: ₹${capSpent.toStringAsFixed(1)} / ₹${capApp.toStringAsFixed(1)} Cr', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                        Text('${pct.round()}% • Target: ${p['targetCommissioning'] ?? '-'}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct / 100.0,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation(pct > 80 ? const Color(0xFF10B981) : pct > 50 ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(onPressed: () => _showDetails(p), icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF1677FF))),
                        IconButton(onPressed: () => _openForm(existing: p), icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF059669))),
                        IconButton(onPressed: () => _deleteProject(p['id'].toString()), icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626))),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
