import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/executive_api_service.dart';
import '../../widgets/module_ui_widgets.dart';

class TreasurySourcingView extends StatefulWidget {
  const TreasurySourcingView({super.key});

  @override
  State<TreasurySourcingView> createState() => _TreasurySourcingViewState();
}

class _TreasurySourcingViewState extends State<TreasurySourcingView> {
  static const List<String> _capitalTypes = [
    'All Classes',
    'Commercial Debt',
    'Concessional Green Debt',
    'Institutional Equity',
    'Promoter Capital',
    'Government Subsidy',
    'Green Bonds',
  ];

  List<Map<String, dynamic>> _facilities = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _typeFilter = 'All Classes';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await ExecutiveApiService.getFundingSources();
    if (mounted) {
      setState(() {
        _facilities = data;
        _isLoading = false;
      });
    }
  }

  double _num(dynamic v) => v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0.0);

  List<Map<String, dynamic>> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _facilities.where((f) {
      final matchesSearch = (f['name'] ?? '').toString().toLowerCase().contains(q) ||
          (f['institution'] ?? '').toString().toLowerCase().contains(q) ||
          (f['target'] ?? '').toString().toLowerCase().contains(q) ||
          (f['id'] ?? '').toString().toLowerCase().contains(q);
      final matchesType = _typeFilter == 'All Classes' || f['type'] == _typeFilter;
      return matchesSearch && matchesType;
    }).toList();
  }

  void _openForm({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final idCtrl = TextEditingController(text: isEdit ? (existing['id'] ?? '').toString() : 'TR-FACILITY-0${_facilities.length + 1}');
    final nameCtrl = TextEditingController(text: isEdit ? (existing['name'] ?? '').toString() : '');
    final instCtrl = TextEditingController(text: isEdit ? (existing['institution'] ?? '').toString() : '');
    final sancCtrl = TextEditingController(text: isEdit ? (existing['sanctioned'] ?? '').toString() : '');
    final recCtrl = TextEditingController(text: isEdit ? (existing['received'] ?? '').toString() : '');
    final rateCtrl = TextEditingController(text: isEdit ? (existing['interestRate'] ?? '').toString() : '8.50% p.a.');
    final tenorCtrl = TextEditingController(text: isEdit ? (existing['tenor'] ?? '').toString() : '10 Years');
    final targetCtrl = TextEditingController(text: isEdit ? (existing['target'] ?? '').toString() : '');

    String type = isEdit ? (existing['type'] ?? 'Commercial Debt').toString() : 'Commercial Debt';

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
                    const Icon(Icons.account_balance, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Capital Facility' : 'Add Capital Facility / Tranche',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                TextField(controller: idCtrl, decoration: moduleInputDecoration('Facility ID *')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Capital Class *'),
                  items: _capitalTypes.where((c) => c != 'All Classes').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModalState(() => type = v ?? 'Commercial Debt'),
                ),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: moduleInputDecoration('Facility / Instrument Name *')),
                const SizedBox(height: 10),
                TextField(controller: instCtrl, decoration: moduleInputDecoration('Lending Institution / Investor *')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sancCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: moduleInputDecoration('Sanctioned (₹ Cr) *'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: recCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: moduleInputDecoration('Disbursed (₹ Cr) *'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: rateCtrl, decoration: moduleInputDecoration('Interest Rate'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: tenorCtrl, decoration: moduleInputDecoration('Tenor'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: targetCtrl, decoration: moduleInputDecoration('Target Project Allocation')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty || instCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please provide Facility Name and Institution.')),
                        );
                        return;
                      }
                      final item = {
                        'id': idCtrl.text.trim(),
                        'name': nameCtrl.text.trim(),
                        'type': type,
                        'institution': instCtrl.text.trim(),
                        'sanctioned': double.tryParse(sancCtrl.text.trim()) ?? 0.0,
                        'received': double.tryParse(recCtrl.text.trim()) ?? 0.0,
                        'outstanding': _num(existing?['outstanding']),
                        'interestRate': rateCtrl.text.trim(),
                        'tenor': tenorCtrl.text.trim(),
                        'target': targetCtrl.text.trim(),
                        'status': existing?['status'] ?? 'Active & Disbursing',
                      };
                      setState(() {
                        if (isEdit) {
                          _facilities = _facilities.map((f) => f['id'] == existing['id'] ? item : f).toList();
                        } else {
                          _facilities = [item, ..._facilities];
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: Text(isEdit ? 'Update Facility' : 'Save Facility'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
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
        title: const Text('Delete Treasury Facility'),
        content: Text('Delete treasury facility $id?'),
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
      ExecutiveApiService.deleteFundingSource(id).catchError((_) {});
      setState(() => _facilities.removeWhere((f) => f['id'].toString() == id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSanctioned = _facilities.fold<double>(0, (s, f) => s + _num(f['sanctioned']));
    final totalReceived = _facilities.fold<double>(0, (s, f) => s + _num(f['received']));
    final treasuryBuffer = totalSanctioned - totalReceived;
    final totalDebt = _facilities
        .where((f) => (f['type'] ?? '').toString().contains('Debt') || (f['type'] ?? '').toString().contains('Bond'))
        .fold<double>(0, (s, f) => s + _num(f['sanctioned']));
    final totalEquity = _facilities
        .where((f) => (f['type'] ?? '').toString().contains('Equity') || (f['type'] ?? '').toString().contains('Promoter'))
        .fold<double>(0, (s, f) => s + _num(f['sanctioned']));
    final totalSubsidy = _facilities
        .where((f) => (f['type'] ?? '').toString().contains('Subsidy'))
        .fold<double>(0, (s, f) => s + _num(f['sanctioned']));

    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            'Consolidated enterprise capital structure tracking institutional equity, term debt consortiums, green bonds, and SATAT subsidies.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'BioNova_Treasury_Sourcing_Ledger_${DateTime.now().toIso8601String().split('T').first}.csv',
                    headers: ['Facility ID', 'Name', 'Type', 'Institution', 'Sanctioned (Cr)', 'Received (Cr)', 'Outstanding (Cr)', 'Interest Rate', 'Tenor', 'Target', 'Status'],
                    rows: filtered
                        .map((f) => [f['id'], f['name'], f['type'], f['institution'], f['sanctioned'], f['received'], f['outstanding'], f['interestRate'], f['tenor'], f['target'], f['status']])
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
                  label: const Text('Add Facility'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ModuleKpiGrid(
            items: [
              ModuleKpiItem(
                label: 'TOTAL CAPITAL SANCTIONED',
                value: '₹${totalSanctioned.toStringAsFixed(1)} Cr',
                subtext: 'Debt ₹${totalDebt.toStringAsFixed(1)} • Equity ₹${totalEquity.toStringAsFixed(1)}',
                accentColor: const Color(0xFF2563EB),
                icon: Icons.account_balance_outlined,
              ),
              ModuleKpiItem(
                label: 'CUMULATIVE FUNDS RECEIVED',
                value: '₹${totalReceived.toStringAsFixed(1)} Cr',
                subtext: '${totalSanctioned > 0 ? ((totalReceived / totalSanctioned) * 100).round() : 0}% Disbursed',
                accentColor: const Color(0xFF059669),
                icon: Icons.trending_up,
              ),
              ModuleKpiItem(
                label: 'AVAILABLE TREASURY BUFFER',
                value: '₹${treasuryBuffer.toStringAsFixed(1)} Cr',
                subtext: 'Undrawn Sanctioned Lines',
                accentColor: const Color(0xFF059669),
                valueColor: const Color(0xFF059669),
                icon: Icons.savings_outlined,
              ),
              ModuleKpiItem(
                label: 'BLENDED COST OF DEBT',
                value: totalDebt > 0 ? '8.12%' : '--',
                subtext: totalDebt > 0 ? 'Weighted Avg Green Rate' : 'No Active Debt',
                accentColor: const Color(0xFF2563EB),
                icon: Icons.percent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Capital Structure Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enterprise Capital Structure (Total ₹${totalSanctioned.toStringAsFixed(1)} Cr)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  'Debt-to-Equity Ratio: ${totalDebt > 0 ? (totalDebt / (totalEquity > 0 ? totalEquity : 1)).toStringAsFixed(2) : "0.00"}x (Target < 2.5x)',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 10,
                    child: totalSanctioned <= 0
                        ? Container(color: const Color(0xFFF1F5F9))
                        : Row(
                            children: [
                              if (totalDebt > 0) Expanded(flex: (totalDebt * 10).round(), child: Container(color: const Color(0xFF2563EB))),
                              if (totalEquity > 0) Expanded(flex: (totalEquity * 10).round(), child: Container(color: const Color(0xFF059669))),
                              if (totalSubsidy > 0) Expanded(flex: (totalSubsidy * 10).round(), child: Container(color: const Color(0xFFF59E0B))),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text('• Term Debt & Green Bonds: ₹${totalDebt.toStringAsFixed(1)} Cr', style: GoogleFonts.inter(fontSize: 11.5)),
                Text('• Institutional & Promoter Equity: ₹${totalEquity.toStringAsFixed(1)} Cr', style: GoogleFonts.inter(fontSize: 11.5)),
                Text('• MNRE SATAT Subsidies: ₹${totalSubsidy.toStringAsFixed(1)} Cr', style: GoogleFonts.inter(fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: moduleInputDecoration('Search facility name, lender, ID, or purpose...').copyWith(
              prefixIcon: const Icon(Icons.search, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _typeFilter,
            isExpanded: true,
            decoration: moduleInputDecoration('Capital Class'),
            items: _capitalTypes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _typeFilter = v ?? 'All Classes'),
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(
              icon: Icons.account_balance_outlined,
              title: 'No capital facilities found',
              subtitle: 'Add a capital facility or adjust your filters.',
            )
          else
            ...filtered.map((f) {
              final sanc = _num(f['sanctioned']);
              final rec = _num(f['received']);
              final status = (f['status'] ?? 'Active & Disbursing').toString();
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
                        Expanded(child: Text((f['name'] ?? '').toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5))),
                        ModuleTag(
                          text: status,
                          bgColor: status.contains('Active') ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE),
                          textColor: status.contains('Active') ? const Color(0xFF166534) : const Color(0xFF1E40AF),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${f['institution']} • ${f['type']}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                    Text('Target: ${f['target'] ?? '-'} • ${f['interestRate']} • ${f['tenor']}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF2563EB))),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sanctioned: ₹${sanc.toStringAsFixed(1)} Cr | Drawn: ₹${rec.toStringAsFixed(1)} Cr (${sanc > 0 ? ((rec / sanc) * 100).round() : 0}%)',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF059669)),
                        ),
                        Row(
                          children: [
                            IconButton(onPressed: () => _openForm(existing: f), icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF059669))),
                            IconButton(onPressed: () => _deleteItem(f['id'].toString()), icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626))),
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
