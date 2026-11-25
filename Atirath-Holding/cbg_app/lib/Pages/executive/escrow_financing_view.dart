import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/executive_api_service.dart';
import '../../widgets/module_ui_widgets.dart';

class EscrowFinancingView extends StatefulWidget {
  const EscrowFinancingView({super.key});

  @override
  State<EscrowFinancingView> createState() => _EscrowFinancingViewState();
}

class _EscrowFinancingViewState extends State<EscrowFinancingView> {
  static const List<String> _categories = [
    'All Types',
    'Disbursement Escrow',
    'DSRA Reserve Account',
    'Retention Escrow',
  ];

  List<Map<String, dynamic>> _escrows = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _catFilter = 'All Types';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await ExecutiveApiService.getEscrowAccounts();
    if (mounted) {
      setState(() {
        _escrows = data;
        _isLoading = false;
      });
    }
  }

  double _num(dynamic v) => v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0.0);

  List<Map<String, dynamic>> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _escrows.where((e) {
      final matchesSearch = (e['title'] ?? '').toString().toLowerCase().contains(q) ||
          (e['accountNo'] ?? '').toString().toLowerCase().contains(q) ||
          (e['custodian'] ?? '').toString().toLowerCase().contains(q) ||
          (e['plant'] ?? '').toString().toLowerCase().contains(q);
      final matchesCat = _catFilter == 'All Types' || e['category'] == _catFilter;
      return matchesSearch && matchesCat;
    }).toList();
  }

  void _openForm({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final idCtrl = TextEditingController(text: isEdit ? (existing['id'] ?? '').toString() : 'ESC-ACC-0${_escrows.length + 1}');
    final acCtrl = TextEditingController(text: isEdit ? (existing['accountNo'] ?? '').toString() : '');
    final titleCtrl = TextEditingController(text: isEdit ? (existing['title'] ?? '').toString() : '');
    final custCtrl = TextEditingController(text: isEdit ? (existing['custodian'] ?? '').toString() : '');
    final plantCtrl = TextEditingController(text: isEdit ? (existing['plant'] ?? 'Plant 1 - Hyderabad East CBG').toString() : 'Plant 1 - Hyderabad East CBG');
    final sigCtrl = TextEditingController(text: isEdit ? (existing['signatory'] ?? '').toString() : '');
    final balCtrl = TextEditingController(text: isEdit ? (existing['balance'] ?? '').toString() : '');
    final inCtrl = TextEditingController(text: isEdit ? (existing['inflow'] ?? '').toString() : '');
    final outCtrl = TextEditingController(text: isEdit ? (existing['outflow'] ?? '').toString() : '');
    final dsraCtrl = TextEditingController(text: isEdit ? (existing['dsraRequirement'] ?? '').toString() : '');

    String category = isEdit ? (existing['category'] ?? 'Disbursement Escrow').toString() : 'Disbursement Escrow';

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
                    const Icon(Icons.work_outline, color: Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Dedicated Escrow Account' : 'Add Dedicated Escrow Account',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(child: TextField(controller: idCtrl, decoration: moduleInputDecoration('Escrow ID *'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: acCtrl, decoration: moduleInputDecoration('Bank Account No *'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: titleCtrl, decoration: moduleInputDecoration('Escrow Account Title *')),
                const SizedBox(height: 10),
                TextField(controller: custCtrl, decoration: moduleInputDecoration('Custodian Bank / Trustee *')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Account Category'),
                  items: _categories.where((c) => c != 'All Types').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModalState(() => category = v ?? 'Disbursement Escrow'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: plantCtrl, decoration: moduleInputDecoration('Plant Facility'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: sigCtrl, decoration: moduleInputDecoration('Signatory'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: balCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: moduleInputDecoration('Balance (₹ Cr) *'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: inCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: moduleInputDecoration('Inflows (₹ Cr) *'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: outCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: moduleInputDecoration('Outflows (₹ Cr) *'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dsraCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: moduleInputDecoration('Min DSRA Requirement (₹ Cr)'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (titleCtrl.text.trim().isEmpty || acCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please provide Escrow Title and Account Number.')),
                        );
                        return;
                      }
                      final item = {
                        'id': idCtrl.text.trim(),
                        'accountNo': acCtrl.text.trim(),
                        'title': titleCtrl.text.trim(),
                        'custodian': custCtrl.text.trim(),
                        'plant': plantCtrl.text.trim(),
                        'category': category,
                        'inflow': double.tryParse(inCtrl.text.trim()) ?? 0.0,
                        'outflow': double.tryParse(outCtrl.text.trim()) ?? 0.0,
                        'balance': double.tryParse(balCtrl.text.trim()) ?? 0.0,
                        'dsraRequirement': double.tryParse(dsraCtrl.text.trim()) ?? 0.0,
                        'covenantStatus': existing?['covenantStatus'] ?? 'Compliant',
                        'lastAuditDate': existing?['lastAuditDate'] ?? DateTime.now().toIso8601String().split('T').first,
                        'signatory': sigCtrl.text.trim(),
                      };
                      setState(() {
                        if (isEdit) {
                          _escrows = _escrows.map((e) => e['id'] == existing['id'] ? item : e).toList();
                        } else {
                          _escrows = [item, ..._escrows];
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: Text(isEdit ? 'Update Escrow Account' : 'Save Escrow Account'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
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
        title: const Text('Delete Escrow Account'),
        content: Text('Delete escrow record $id?'),
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
      ExecutiveApiService.deleteEscrowAccount(id).catchError((_) {});
      setState(() => _escrows.removeWhere((e) => e['id'].toString() == id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalBalance = _escrows.fold<double>(0, (s, e) => s + _num(e['balance']));
    final totalInflows = _escrows.fold<double>(0, (s, e) => s + _num(e['inflow']));
    final totalOutflows = _escrows.fold<double>(0, (s, e) => s + _num(e['outflow']));
    final totalDsra = _escrows.where((e) => (e['category'] ?? '').toString().contains('DSRA')).fold<double>(0, (s, e) => s + _num(e['balance']));
    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            'Dedicated escrow account ledgers, Debt Service Reserve Accounts (DSRA), and institutional lender milestone drawdowns.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'BioNova_Escrow_Financing_Monitor_${DateTime.now().toIso8601String().split('T').first}.csv',
                    headers: ['Escrow ID', 'Account No', 'Title', 'Custodian Bank', 'Plant', 'Category', 'Inflow (Cr)', 'Outflow (Cr)', 'Balance (Cr)', 'DSRA Req (Cr)', 'Covenant', 'Audit Date', 'Signatory'],
                    rows: filtered
                        .map((e) => [e['id'], e['accountNo'], e['title'], e['custodian'], e['plant'], e['category'], e['inflow'], e['outflow'], e['balance'], e['dsraRequirement'], e['covenantStatus'], e['lastAuditDate'], e['signatory']])
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
                  label: const Text('Add Escrow'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ModuleKpiGrid(
            items: [
              ModuleKpiItem(
                label: 'TOTAL ESCROW BALANCE',
                value: '₹${totalBalance.toStringAsFixed(1)} Cr',
                subtext: 'Liquid in Scheduled Banks',
                accentColor: const Color(0xFF059669),
                icon: Icons.account_balance_wallet_outlined,
              ),
              ModuleKpiItem(
                label: 'DSRA RESERVE COVERAGE',
                value: '₹${totalDsra.toStringAsFixed(1)} Cr',
                subtext: totalDsra > 0 ? '100% Covenant Compliant' : 'No Active DSRA Accounts',
                accentColor: totalDsra > 0 ? const Color(0xFF059669) : const Color(0xFF64748B),
                icon: Icons.verified_user_outlined,
              ),
              ModuleKpiItem(
                label: 'CUMULATIVE INFLOWS',
                value: '₹${totalInflows.toStringAsFixed(1)} Cr',
                subtext: 'Disbursements & Subsidies',
                accentColor: const Color(0xFF2563EB),
                icon: Icons.arrow_downward,
              ),
              ModuleKpiItem(
                label: 'TOTAL CAPITAL DRAWN',
                value: '₹${totalOutflows.toStringAsFixed(1)} Cr',
                subtext: 'Certified by Engineers',
                accentColor: const Color(0xFF64748B),
                icon: Icons.arrow_upward,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: moduleInputDecoration('Search escrow title, account no, custodian, or plant...').copyWith(
              prefixIcon: const Icon(Icons.search, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _catFilter,
            isExpanded: true,
            decoration: moduleInputDecoration('Account Type'),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _catFilter = v ?? 'All Types'),
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(
              icon: Icons.work_outline,
              title: 'No escrow accounts match current search',
              subtitle: 'Add an escrow account or adjust your filters.',
            )
          else
            ...filtered.map((e) {
              final inflow = _num(e['inflow']);
              final outflow = _num(e['outflow']);
              final bal = _num(e['balance']);
              final dsra = _num(e['dsraRequirement']);
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
                        Expanded(child: Text((e['title'] ?? '').toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5))),
                        ModuleTag(
                          text: (e['covenantStatus'] ?? 'Compliant').toString(),
                          bgColor: const Color(0xFFDCFCE7),
                          textColor: const Color(0xFF166534),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${e['custodian']} • A/C: ${e['accountNo']}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF2563EB))),
                    Text('${e['category']} • ${e['plant']}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('In: ₹${inflow.toStringAsFixed(1)} Cr', style: GoogleFonts.inter(fontSize: 12)),
                        Text('Out: ₹${outflow.toStringAsFixed(1)} Cr', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                        Text('Bal: ₹${bal.toStringAsFixed(1)} Cr', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF059669))),
                      ],
                    ),
                    if (dsra > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Min DSRA Req: ₹${dsra.toStringAsFixed(1)} Cr • Audited: ${e['lastAuditDate'] ?? '-'}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(onPressed: () => _openForm(existing: e), icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF059669))),
                        IconButton(onPressed: () => _deleteItem(e['id'].toString()), icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626))),
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
