import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/executive_api_service.dart';
import '../../widgets/module_ui_widgets.dart';

class CapexAnalyticsView extends StatefulWidget {
  const CapexAnalyticsView({super.key});

  @override
  State<CapexAnalyticsView> createState() => _CapexAnalyticsViewState();
}

class _CapexAnalyticsViewState extends State<CapexAnalyticsView> {
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final projects = await ExecutiveApiService.getPipelineProjects();
    if (mounted) {
      setState(() {
        _data = projects
            .map((p) => {
                  'id': p['projectCode'] ?? p['id'],
                  'project': p['name'] ?? '',
                  'engineeringPackage': p['upcomingMilestone'] ?? p['stage'] ?? 'Civil Works',
                  'approvedCapex': _num(p['capexApproved']),
                  'actualSpent': _num(p['capexSpent']),
                  'plannedProgress': _num(p['completionPct']),
                  'actualProgress': _num(p['completionPct']),
                  'monthlyBurn': 0.0,
                  'digesterCapacity': p['capacity'] ?? '',
                  'gasCompressionSkid': '',
                  'plannedFinish': p['targetCommissioning'] ?? '',
                  'health': p['status'] ?? 'On Track',
                  'leadEngineer': p['leadPM'] ?? '',
                })
            .toList();
        _isLoading = false;
      });
    }
  }

  double _num(dynamic v) => v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0.0);

  List<Map<String, dynamic>> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _data.where((item) {
      final matchesSearch = (item['project'] ?? '').toString().toLowerCase().contains(q) ||
          (item['engineeringPackage'] ?? '').toString().toLowerCase().contains(q) ||
          (item['leadEngineer'] ?? '').toString().toLowerCase().contains(q) ||
          (item['id'] ?? '').toString().toLowerCase().contains(q);
      final matchesStatus = _statusFilter == 'All' || item['health'] == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _openForm({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final idCtrl = TextEditingController(text: isEdit ? (existing['id'] ?? '').toString() : 'ENG-PLANT-0${_data.length + 1}');
    final pkgCtrl = TextEditingController(text: isEdit ? (existing['engineeringPackage'] ?? '').toString() : '');
    final capexCtrl = TextEditingController(text: isEdit ? (existing['approvedCapex'] ?? '').toString() : '');
    final spentCtrl = TextEditingController(text: isEdit ? (existing['actualSpent'] ?? '').toString() : '');
    final burnCtrl = TextEditingController(text: isEdit ? (existing['monthlyBurn'] ?? '').toString() : '1.5');
    final progCtrl = TextEditingController(text: isEdit ? (existing['actualProgress'] ?? 0).toString() : '0');
    final digCtrl = TextEditingController(text: isEdit ? (existing['digesterCapacity'] ?? '').toString() : '');
    final skidCtrl = TextEditingController(text: isEdit ? (existing['gasCompressionSkid'] ?? '').toString() : '');
    final finishCtrl = TextEditingController(text: isEdit ? (existing['plannedFinish'] ?? '').toString() : '');
    final engCtrl = TextEditingController(text: isEdit ? (existing['leadEngineer'] ?? '').toString() : '');

    String project = isEdit ? (existing['project'] ?? 'Plant 1 - Hyderabad East CBG').toString() : 'Plant 1 - Hyderabad East CBG';
    const plantOptions = [
      'Plant 1 - Hyderabad East CBG',
      'Plant 2 - Medak Agri Hub',
      'Plant 3 - Nalgonda Biomass Facility',
      'Plant 4 - Bidar Agro Conversion Unit',
    ];
    if (!plantOptions.contains(project)) {
      project = plantOptions.first;
    }

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
              children: [
                Row(
                  children: [
                    const Icon(Icons.speed, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Engineering Telemetry' : 'Add Project Telemetry Package',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                TextField(controller: idCtrl, decoration: moduleInputDecoration('Telemetry ID *')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: project,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Plant Facility *'),
                  items: plantOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setModalState(() => project = v ?? plantOptions.first),
                ),
                const SizedBox(height: 10),
                TextField(controller: pkgCtrl, decoration: moduleInputDecoration('Engineering Package Description *')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: capexCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: moduleInputDecoration('Approved CapEx (Cr) *'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: spentCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: moduleInputDecoration('Actual Spent (Cr) *'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: burnCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: moduleInputDecoration('Monthly Burn (Cr/mo)'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: progCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Actual Progress (%)'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: digCtrl, decoration: moduleInputDecoration('Digester Capacity'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: skidCtrl, decoration: moduleInputDecoration('Gas Compression Skid'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: finishCtrl, decoration: moduleInputDecoration('Target Date'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: engCtrl, decoration: moduleInputDecoration('Lead Engineer'))),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (pkgCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please provide Engineering Package and Project.')),
                        );
                        return;
                      }
                      final item = {
                        'id': idCtrl.text.trim(),
                        'project': project,
                        'engineeringPackage': pkgCtrl.text.trim(),
                        'approvedCapex': double.tryParse(capexCtrl.text.trim()) ?? 0.0,
                        'actualSpent': double.tryParse(spentCtrl.text.trim()) ?? 0.0,
                        'plannedProgress': double.tryParse(existing?['plannedProgress']?.toString() ?? '') ?? 0.0,
                        'actualProgress': double.tryParse(progCtrl.text.trim()) ?? 0.0,
                        'monthlyBurn': double.tryParse(burnCtrl.text.trim()) ?? 0.0,
                        'digesterCapacity': digCtrl.text.trim(),
                        'gasCompressionSkid': skidCtrl.text.trim(),
                        'plannedFinish': finishCtrl.text.trim(),
                        'health': existing?['health'] ?? 'On Schedule',
                        'leadEngineer': engCtrl.text.trim(),
                      };
                      setState(() {
                        if (isEdit) {
                          _data = _data.map((i) => i['id'] == existing['id'] ? item : i).toList();
                        } else {
                          _data = [item, ..._data];
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: Text(isEdit ? 'Update Telemetry Record' : 'Save Telemetry Record'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Telemetry'),
        content: Text('Delete engineering analytics record $id?'),
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
      setState(() => _data.removeWhere((i) => i['id'].toString() == id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCapex = _data.fold<double>(0, (s, i) => s + _num(i['approvedCapex']));
    final totalSpent = _data.fold<double>(0, (s, i) => s + _num(i['actualSpent']));
    final totalBurn = _data.fold<double>(0, (s, i) => s + _num(i['monthlyBurn']));
    final avgProgress = _data.isEmpty
        ? 0
        : (_data.fold<double>(0, (s, i) => s + _num(i['actualProgress'])) / _data.length).round();
    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            'Consolidated project engineering telemetry, milestone burn velocity, digester capacity progression, and CapEx execution analytics.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'BioNova_Capex_Engineering_Analytics_${DateTime.now().toIso8601String().split('T').first}.csv',
                    headers: ['ID', 'Project', 'Package', 'Approved Capex (Cr)', 'Actual Spent (Cr)', 'Planned %', 'Actual %', 'Monthly Burn', 'Digester', 'Gas Skid', 'Target Date', 'Status', 'Lead Engineer'],
                    rows: filtered
                        .map((i) => [i['id'], i['project'], i['engineeringPackage'], i['approvedCapex'], i['actualSpent'], '${i['plannedProgress']}%', '${i['actualProgress']}%', i['monthlyBurn'], i['digesterCapacity'], i['gasCompressionSkid'], i['plannedFinish'], i['health'], i['leadEngineer']])
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
                  label: const Text('Update Telemetry'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ModuleKpiGrid(
            items: [
              ModuleKpiItem(
                label: 'CAPEX DEPLOYED',
                value: '₹${totalSpent.toStringAsFixed(1)} Cr',
                subtext: '${totalCapex > 0 ? ((totalSpent / totalCapex) * 100).round() : 0}% of ₹${totalCapex.toStringAsFixed(1)} Cr',
                accentColor: const Color(0xFF059669),
                icon: Icons.attach_money,
              ),
              ModuleKpiItem(
                label: 'CASH BURN VELOCITY',
                value: '₹${totalBurn.toStringAsFixed(2)} Cr/mo',
                subtext: _data.isNotEmpty ? 'Healthy Runway: 14+ Mo' : 'No Active Burn Logged',
                accentColor: const Color(0xFF2563EB),
                icon: Icons.speed,
              ),
              ModuleKpiItem(
                label: 'AVG MILESTONE PACE',
                value: _data.isNotEmpty ? '$avgProgress%' : '--',
                subtext: _data.isNotEmpty ? '+2.8% Ahead of Baseline' : 'No Active Milestones',
                accentColor: const Color(0xFF059669),
                icon: Icons.trending_up,
              ),
              ModuleKpiItem(
                label: 'DIGESTER CAPACITY',
                value: _data.isNotEmpty ? '30,500 m³' : '--',
                subtext: _data.isNotEmpty ? '3,000 Nm³/hr Scrubbing' : 'Awaiting Commissioning',
                accentColor: const Color(0xFF059669),
                icon: Icons.factory_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: moduleInputDecoration('Search project, package, or lead engineer...').copyWith(
              prefixIcon: const Icon(Icons.search, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _statusFilter,
            isExpanded: true,
            decoration: moduleInputDecoration('Health Status'),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All Health Statuses')),
              DropdownMenuItem(value: 'Ahead of Schedule', child: Text('Ahead of Schedule')),
              DropdownMenuItem(value: 'On Schedule', child: Text('On Schedule')),
              DropdownMenuItem(value: 'Permit Sync In Progress', child: Text('Permit Sync In Progress')),
            ],
            onChanged: (v) => setState(() => _statusFilter = v ?? 'All'),
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(
              icon: Icons.speed_outlined,
              title: 'No engineering analytics records found',
              subtitle: 'Update a telemetry package or adjust filters.',
            )
          else
            ...filtered.map((item) {
              final app = _num(item['approvedCapex']);
              final spent = _num(item['actualSpent']);
              final burn = _num(item['monthlyBurn']);
              final actProg = _num(item['actualProgress']).clamp(0, 100);
              final planProg = _num(item['plannedProgress']).clamp(0, 100);
              final health = (item['health'] ?? 'On Track').toString();
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
                        Expanded(child: Text((item['project'] ?? '').toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5))),
                        ModuleTag(
                          text: health,
                          bgColor: health.contains('Ahead') ? const Color(0xFFDCFCE7) : health.contains('On') ? const Color(0xFFDBEAFE) : const Color(0xFFFEF3C7),
                          textColor: health.contains('Ahead') ? const Color(0xFF166534) : health.contains('On') ? const Color(0xFF1E40AF) : const Color(0xFF92400E),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('${item['engineeringPackage']}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
                    Text('Lead: ${item['leadEngineer']} • Finish: ${item['plannedFinish']}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Spent: ₹${spent.toStringAsFixed(1)} / ₹${app.toStringAsFixed(1)} Cr', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                        Text('Burn: ₹${burn.toStringAsFixed(2)} Cr/mo', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Actual: ${actProg.round()}%', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                        Text('Planned: ${planProg.round()}%', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: actProg / 100.0,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation(actProg >= planProg ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(onPressed: () => _openForm(existing: item), icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF059669))),
                        IconButton(onPressed: () => _deleteItem(item['id'].toString()), icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626))),
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
