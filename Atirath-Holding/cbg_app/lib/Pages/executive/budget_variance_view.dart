import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/executive_api_service.dart';
import '../../widgets/module_ui_widgets.dart';

class BudgetVarianceView extends StatefulWidget {
  const BudgetVarianceView({super.key});

  @override
  State<BudgetVarianceView> createState() => _BudgetVarianceViewState();
}

class _BudgetVarianceViewState extends State<BudgetVarianceView> {
  List<Map<String, dynamic>> _costCenters = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _natureFilter = 'All';
  String _plantFilter = 'All';
  String _varianceFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await ExecutiveApiService.getBudgetItems();
    if (mounted) {
      setState(() {
        _costCenters = data;
        _isLoading = false;
      });
    }
  }

  double _num(dynamic v) => v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0.0);

  ({double diff, double pct, bool isOverrun, bool isUnder, String status}) _varianceDetails(
      double baseline, double actual) {
    final diff = actual - baseline;
    final pct = baseline > 0 ? (diff / baseline) * 100 : 0.0;
    final isOverrun = pct > 5.0;
    final isUnder = pct < -1.0;
    final status = isOverrun
        ? 'Cost Overrun (>5%)'
        : pct > 0
            ? 'Mild Overrun (1-5%)'
            : isUnder
                ? 'Favorable / Under Budget'
                : 'On Track';
    return (diff: diff, pct: pct, isOverrun: isOverrun, isUnder: isUnder, status: status);
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _costCenters.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final id = (item['id'] ?? '').toString().toLowerCase();
      final dept = (item['leadDept'] ?? '').toString().toLowerCase();
      final matchesSearch = name.contains(q) || id.contains(q) || dept.contains(q);
      final matchesNature = _natureFilter == 'All' || item['nature'] == _natureFilter;
      final matchesPlant = _plantFilter == 'All' || (item['plant'] ?? '').toString().contains(_plantFilter);

      final v = _varianceDetails(_num(item['baselineBudget']), _num(item['actualIncurred']));
      bool matchesVar = true;
      if (_varianceFilter == 'Overrun') matchesVar = v.isOverrun;
      if (_varianceFilter == 'Under') matchesVar = v.isUnder;

      return matchesSearch && matchesNature && matchesPlant && matchesVar;
    }).toList();
  }

  void _openForm({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final idCtrl = TextEditingController(
      text: isEdit ? (existing['id'] ?? '').toString() : 'CC-NEW-0${_costCenters.length + 1}',
    );
    final nameCtrl = TextEditingController(text: isEdit ? (existing['name'] ?? '').toString() : '');
    final deptCtrl = TextEditingController(text: isEdit ? (existing['leadDept'] ?? '').toString() : 'Plant Engineering');
    final baseCtrl = TextEditingController(text: isEdit ? (existing['baselineBudget'] ?? '').toString() : '5.0');
    final actualCtrl = TextEditingController(text: isEdit ? (existing['actualIncurred'] ?? '').toString() : '3.2');
    final poCtrl = TextEditingController(text: isEdit ? (existing['committedPO'] ?? '').toString() : '0.5');
    final notesCtrl = TextEditingController(text: isEdit ? (existing['notes'] ?? '').toString() : '');

    String nature = isEdit ? (existing['nature'] ?? 'CapEx').toString() : 'CapEx';
    String plant = isEdit ? (existing['plant'] ?? 'Plant 1 - Hyderabad East CBG').toString() : 'Plant 1 - Hyderabad East CBG';

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
                    const Icon(Icons.attach_money, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Cost Center Budget' : 'Add Cost Center Record',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                TextField(controller: idCtrl, decoration: moduleInputDecoration('Cost Center Code *')),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: moduleInputDecoration('Cost Center Name / Description *')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: nature,
                        decoration: moduleInputDecoration('Nature'),
                        items: const [
                          DropdownMenuItem(value: 'CapEx', child: Text('CapEx')),
                          DropdownMenuItem(value: 'OpEx', child: Text('OpEx')),
                        ],
                        onChanged: (v) => setModalState(() => nature = v ?? 'CapEx'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: deptCtrl, decoration: moduleInputDecoration('Lead Dept'))),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: plant,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Plant Facility'),
                  items: const [
                    DropdownMenuItem(value: 'Plant 1 - Hyderabad East CBG', child: Text('Plant 1 - Hyderabad East CBG')),
                    DropdownMenuItem(value: 'Plant 2 - Medak Agri Hub', child: Text('Plant 2 - Medak Agri Hub')),
                    DropdownMenuItem(value: 'Plant 3 - Nalgonda Facility', child: Text('Plant 3 - Nalgonda Facility')),
                    DropdownMenuItem(value: 'All Operations', child: Text('All Operations / Corporate')),
                  ],
                  onChanged: (v) => setModalState(() => plant = v ?? 'Plant 1 - Hyderabad East CBG'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: baseCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: moduleInputDecoration('Baseline (₹ Cr) *'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: actualCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: moduleInputDecoration('Actual (₹ Cr) *'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: poCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: moduleInputDecoration('PO (₹ Cr)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: moduleInputDecoration('Variance Justification / Audit Notes'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please provide Cost Center Name.')),
                        );
                        return;
                      }
                      final item = {
                        'id': idCtrl.text.trim(),
                        'name': nameCtrl.text.trim(),
                        'nature': nature,
                        'plant': plant,
                        'baselineBudget': double.tryParse(baseCtrl.text.trim()) ?? 0.0,
                        'actualIncurred': double.tryParse(actualCtrl.text.trim()) ?? 0.0,
                        'committedPO': double.tryParse(poCtrl.text.trim()) ?? 0.0,
                        'leadDept': deptCtrl.text.trim(),
                        'notes': notesCtrl.text.trim(),
                      };
                      setState(() {
                        if (isEdit) {
                          _costCenters = _costCenters.map((c) => c['id'] == existing['id'] ? item : c).toList();
                        } else {
                          _costCenters = [item, ..._costCenters];
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: Text(isEdit ? 'Update Cost Center' : 'Save Record'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
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

  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Cost Center'),
        content: Text('Delete cost center record $id?'),
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
      ExecutiveApiService.deleteBudgetItem(id).catchError((_) {});
      setState(() => _costCenters.removeWhere((c) => c['id'].toString() == id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalBaseline = _costCenters.fold<double>(0, (s, c) => s + _num(c['baselineBudget']));
    final totalActual = _costCenters.fold<double>(0, (s, c) => s + _num(c['actualIncurred']));
    final netVariance = totalActual - totalBaseline;
    final netPct = totalBaseline > 0 ? (netVariance / totalBaseline) * 100 : 0.0;
    final overrunCount = _costCenters
        .where((c) => _varianceDetails(_num(c['baselineBudget']), _num(c['actualIncurred'])).isOverrun)
        .length;

    final capexSum = _costCenters.where((c) => c['nature'] == 'CapEx').fold<double>(0, (s, c) => s + _num(c['baselineBudget']));
    final opexSum = _costCenters.where((c) => c['nature'] == 'OpEx').fold<double>(0, (s, c) => s + _num(c['baselineBudget']));
    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            'Granular cost-center tracking comparing baseline approved budgets against actual expenditures and encumbrances.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'BioNova_Budget_Variance_Matrix_${DateTime.now().toIso8601String().split('T').first}.csv',
                    headers: ['Cost Center ID', 'Name', 'Nature', 'Plant', 'Baseline (Cr)', 'Actual (Cr)', 'Committed PO (Cr)', 'Variance (Cr)', 'Variance %', 'Status', 'Notes'],
                    rows: filtered.map((c) {
                      final v = _varianceDetails(_num(c['baselineBudget']), _num(c['actualIncurred']));
                      return [
                        c['id'],
                        c['name'],
                        c['nature'],
                        c['plant'],
                        c['baselineBudget'],
                        c['actualIncurred'],
                        c['committedPO'],
                        v.diff.toStringAsFixed(2),
                        '${v.pct.toStringAsFixed(1)}%',
                        v.status,
                        c['notes'],
                      ];
                    }).toList(),
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
                  label: const Text('Add Cost Center'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (overrunCount > 0)
            ModuleAlertBanner(
              title: 'Executive Budget Overrun Trigger ($overrunCount Centers > 5% Overrun)',
              subtitle: '$overrunCount cost center records have exceeded approved tolerance limits.',
              actionLabel: 'Filter Overruns',
              onAction: () => setState(() => _varianceFilter = 'Overrun'),
            ),
          ModuleKpiGrid(
            items: [
              ModuleKpiItem(
                label: 'APPROVED BASELINE BUDGET',
                value: '₹${totalBaseline.toStringAsFixed(1)} Cr',
                subtext: 'CapEx ₹${capexSum.toStringAsFixed(1)} • OpEx ₹${opexSum.toStringAsFixed(1)}',
                accentColor: const Color(0xFF2563EB),
                icon: Icons.pie_chart_outline,
              ),
              ModuleKpiItem(
                label: 'ACTUAL CAPITAL INCURRED',
                value: '₹${totalActual.toStringAsFixed(1)} Cr',
                subtext: 'Utilization: ${totalBaseline > 0 ? ((totalActual / totalBaseline) * 100).round() : 0}%',
                accentColor: totalActual <= totalBaseline ? const Color(0xFF059669) : const Color(0xFFDC2626),
                icon: Icons.account_balance_wallet_outlined,
              ),
              ModuleKpiItem(
                label: 'NET PORTFOLIO VARIANCE',
                value: totalBaseline > 0
                    ? '${netVariance <= 0 ? "-" : "+"}₹${netVariance.abs().toStringAsFixed(2)} Cr'
                    : '₹0.00 Cr',
                subtext: totalBaseline > 0
                    ? '${netPct.abs().toStringAsFixed(1)}% ${netVariance <= 0 ? "Favorable" : "Over Budget"}'
                    : 'No Active Variances',
                accentColor: netVariance <= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                valueColor: netVariance <= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                icon: netVariance <= 0 ? Icons.trending_down : Icons.trending_up,
              ),
              ModuleKpiItem(
                label: 'CRITICAL OVERRUNS (>5%)',
                value: '$overrunCount Centers',
                subtext: overrunCount > 0 ? 'Requires Audit Approval' : 'Zero Cost Overruns',
                accentColor: overrunCount > 0 ? const Color(0xFFEA580C) : const Color(0xFF059669),
                valueColor: overrunCount > 0 ? const Color(0xFFEA580C) : const Color(0xFF059669),
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: moduleInputDecoration('Search cost center name, code, or dept...').copyWith(
              prefixIcon: const Icon(Icons.search, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _natureFilter,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Nature'),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Expenses')),
                    DropdownMenuItem(value: 'CapEx', child: Text('CapEx Only')),
                    DropdownMenuItem(value: 'OpEx', child: Text('OpEx Only')),
                  ],
                  onChanged: (v) => setState(() => _natureFilter = v ?? 'All'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _plantFilter,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Plant'),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Plants')),
                    DropdownMenuItem(value: 'Hyderabad', child: Text('Hyderabad East')),
                    DropdownMenuItem(value: 'Medak', child: Text('Medak Hub')),
                    DropdownMenuItem(value: 'Nalgonda', child: Text('Nalgonda Facility')),
                  ],
                  onChanged: (v) => setState(() => _plantFilter = v ?? 'All'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _varianceFilter,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Variance'),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Overrun', child: Text('Overruns')),
                    DropdownMenuItem(value: 'Under', child: Text('Savings')),
                  ],
                  onChanged: (v) => setState(() => _varianceFilter = v ?? 'All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(
              icon: Icons.account_balance_outlined,
              title: 'No cost center records match current filters',
              subtitle: 'Add a cost center record or clear active filters.',
            )
          else
            ...filtered.map((c) {
              final base = _num(c['baselineBudget']);
              final act = _num(c['actualIncurred']);
              final po = _num(c['committedPO']);
              final v = _varianceDetails(base, act);
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
                            (c['name'] ?? '').toString(),
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                        ),
                        ModuleTag(
                          text: (c['nature'] ?? 'CapEx').toString(),
                          bgColor: c['nature'] == 'CapEx' ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4),
                          textColor: c['nature'] == 'CapEx' ? const Color(0xFF1E40AF) : const Color(0xFF15803D),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${c['id']} • ${c['leadDept']} • ${c['plant']}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Baseline: ₹${base.toStringAsFixed(2)} Cr', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('Actual: ₹${act.toStringAsFixed(2)} Cr', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                        Text('PO: ₹${po.toStringAsFixed(2)} Cr', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF475569))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ModuleTag(
                          text: '${v.diff >= 0 ? "+" : "-"}₹${v.diff.abs().toStringAsFixed(2)} Cr (${v.pct.toStringAsFixed(1)}%) • ${v.status}',
                          bgColor: v.isOverrun ? const Color(0xFFFEE2E2) : v.isUnder ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                          textColor: v.isOverrun ? const Color(0xFF991B1B) : v.isUnder ? const Color(0xFF166534) : const Color(0xFF475569),
                        ),
                        Row(
                          children: [
                            IconButton(onPressed: () => _openForm(existing: c), icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF059669))),
                            IconButton(onPressed: () => _deleteItem(c['id'].toString()), icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626))),
                          ],
                        ),
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
