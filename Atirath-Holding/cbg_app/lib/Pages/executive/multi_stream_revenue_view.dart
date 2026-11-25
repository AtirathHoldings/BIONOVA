import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/executive_api_service.dart';
import '../../widgets/module_ui_widgets.dart';

class MultiStreamRevenueView extends StatefulWidget {
  const MultiStreamRevenueView({super.key});

  @override
  State<MultiStreamRevenueView> createState() => _MultiStreamRevenueViewState();
}

class _MultiStreamRevenueViewState extends State<MultiStreamRevenueView> {
  static const List<String> _streams = [
    'All Streams',
    'Compressed Biogas (CBG)',
    'Fermented Organic Manure (FOM)',
    'Carbon Offset Credits (CERs)',
    'Municipal Tipping Fees',
  ];

  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _streamFilter = 'All Streams';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await ExecutiveApiService.getRevenueRecords();
    if (mounted) {
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    }
  }

  double _num(dynamic v) => v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0.0);

  String _formatINR(double val) {
    if (val >= 10000000) return '₹${(val / 10000000).toStringAsFixed(2)} Cr';
    if (val >= 100000) return '₹${(val / 100000).toStringAsFixed(2)} Lac';
    return '₹${val.round()}';
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _transactions.where((t) {
      final matchesSearch = (t['offtaker'] ?? '').toString().toLowerCase().contains(q) ||
          (t['id'] ?? '').toString().toLowerCase().contains(q) ||
          (t['plant'] ?? '').toString().toLowerCase().contains(q);
      final matchesStream = _streamFilter == 'All Streams' || t['stream'] == _streamFilter;
      final matchesStatus = _statusFilter == 'All' || t['paymentStatus'] == _statusFilter;
      return matchesSearch && matchesStream && matchesStatus;
    }).toList();
  }

  void _openForm({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final idCtrl = TextEditingController(
      text: isEdit ? (existing['id'] ?? '').toString() : 'REV-INV-2026-${_transactions.length + 120}',
    );
    final offtakerCtrl = TextEditingController(text: isEdit ? (existing['offtaker'] ?? '').toString() : '');
    final plantCtrl = TextEditingController(text: isEdit ? (existing['plant'] ?? 'Plant 1 - Hyderabad East').toString() : 'Plant 1 - Hyderabad East');
    final volCtrl = TextEditingController(text: isEdit ? (existing['volume'] ?? '').toString() : '100.0 MT');
    final rateCtrl = TextEditingController(text: isEdit ? (existing['unitRate'] ?? '').toString() : '₹76.00 / kg');
    final amtCtrl = TextEditingController(text: isEdit ? (existing['amount'] ?? '').toString() : '7600000');
    final invDateCtrl = TextEditingController(
      text: isEdit ? (existing['invoiceDate'] ?? '').toString() : DateTime.now().toIso8601String().split('T').first,
    );
    final dueDateCtrl = TextEditingController(text: isEdit ? (existing['dueDate'] ?? '').toString() : '2026-12-15');
    final utrCtrl = TextEditingController(text: isEdit ? (existing['utr'] ?? '-').toString() : '-');

    String stream = isEdit ? (existing['stream'] ?? 'Compressed Biogas (CBG)').toString() : 'Compressed Biogas (CBG)';
    String payStatus = isEdit ? (existing['paymentStatus'] ?? 'Pending').toString() : 'Pending';

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
                    const Icon(Icons.trending_up, color: Color(0xFF1677FF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Revenue Invoice' : 'Record Revenue Invoice',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                TextField(controller: idCtrl, decoration: moduleInputDecoration('Invoice ID *')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: stream,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Revenue Stream *'),
                  items: _streams.where((s) => s != 'All Streams').map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setModalState(() => stream = v ?? 'Compressed Biogas (CBG)'),
                ),
                const SizedBox(height: 10),
                TextField(controller: offtakerCtrl, decoration: moduleInputDecoration('Offtaker / Buyer *')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: plantCtrl, decoration: moduleInputDecoration('Plant Site'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: volCtrl, decoration: moduleInputDecoration('Volume & Unit'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: rateCtrl, decoration: moduleInputDecoration('Unit Rate'))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: amtCtrl,
                        keyboardType: TextInputType.number,
                        decoration: moduleInputDecoration('Amount (₹ INR) *'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: invDateCtrl, decoration: moduleInputDecoration('Invoice Date'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: dueDateCtrl, decoration: moduleInputDecoration('Due Date'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: payStatus,
                        decoration: moduleInputDecoration('Payment Status'),
                        items: const [
                          DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'Settled', child: Text('Settled')),
                          DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
                        ],
                        onChanged: (v) => setModalState(() => payStatus = v ?? 'Pending'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: utrCtrl, decoration: moduleInputDecoration('Bank UTR Ref'))),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (offtakerCtrl.text.trim().isEmpty || amtCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please provide Offtaker and Amount.')),
                        );
                        return;
                      }
                      final item = {
                        'id': idCtrl.text.trim(),
                        'stream': stream,
                        'offtaker': offtakerCtrl.text.trim(),
                        'volume': volCtrl.text.trim(),
                        'unitRate': rateCtrl.text.trim(),
                        'amount': double.tryParse(amtCtrl.text.trim()) ?? 0.0,
                        'invoiceDate': invDateCtrl.text.trim(),
                        'dueDate': dueDateCtrl.text.trim(),
                        'paymentStatus': payStatus,
                        'utr': utrCtrl.text.trim(),
                        'plant': plantCtrl.text.trim(),
                      };
                      setState(() {
                        if (isEdit) {
                          _transactions = _transactions.map((t) => t['id'] == existing['id'] ? item : t).toList();
                        } else {
                          _transactions = [item, ..._transactions];
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: Text(isEdit ? 'Update Invoice' : 'Save Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1677FF),
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
        title: const Text('Delete Invoice'),
        content: Text('Delete revenue invoice $id?'),
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
      ExecutiveApiService.deleteRevenueRecord(id).catchError((_) {});
      setState(() => _transactions.removeWhere((t) => t['id'].toString() == id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = _transactions.fold<double>(0, (s, t) => s + _num(t['amount']));
    final settledRevenue = _transactions.where((t) => t['paymentStatus'] == 'Settled').fold<double>(0, (s, t) => s + _num(t['amount']));
    final pendingRevenue = _transactions.where((t) => t['paymentStatus'] == 'Pending').fold<double>(0, (s, t) => s + _num(t['amount']));
    final overdueRevenue = _transactions.where((t) => t['paymentStatus'] == 'Overdue').fold<double>(0, (s, t) => s + _num(t['amount']));

    final cbgTotal = _transactions.where((t) => (t['stream'] ?? '').toString().contains('Biogas')).fold<double>(0, (s, t) => s + _num(t['amount']));
    final fomTotal = _transactions.where((t) => (t['stream'] ?? '').toString().contains('Manure')).fold<double>(0, (s, t) => s + _num(t['amount']));
    final cerTotal = _transactions.where((t) => (t['stream'] ?? '').toString().contains('Carbon')).fold<double>(0, (s, t) => s + _num(t['amount']));
    final tipTotal = _transactions.where((t) => (t['stream'] ?? '').toString().contains('Tipping')).fold<double>(0, (s, t) => s + _num(t['amount']));

    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            'Multi-stream revenue telemetry aggregating CBG cascade off-takes, organic manure sales, carbon credits (CERs), and municipal tipping fees.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'BioNova_MultiStream_Revenue_${DateTime.now().toIso8601String().split('T').first}.csv',
                    headers: ['Invoice ID', 'Stream', 'Offtaker', 'Volume', 'Unit Rate', 'Amount (INR)', 'Invoice Date', 'Due Date', 'Status', 'UTR Ref', 'Plant Site'],
                    rows: filtered
                        .map((t) => [t['id'], t['stream'], t['offtaker'], t['volume'], t['unitRate'], t['amount'], t['invoiceDate'], t['dueDate'], t['paymentStatus'], t['utr'], t['plant']])
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
                  label: const Text('Record Invoice'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1677FF), foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ModuleKpiGrid(
            items: [
              ModuleKpiItem(
                label: 'TOTAL BOOKED REVENUE',
                value: _formatINR(totalRevenue),
                subtext: 'Settled: ${_formatINR(settledRevenue)} (${totalRevenue > 0 ? ((settledRevenue / totalRevenue) * 100).round() : 0}%)',
                accentColor: const Color(0xFF059669),
                icon: Icons.currency_rupee,
              ),
              ModuleKpiItem(
                label: 'CBG SALES REALIZATION',
                value: _formatINR(cbgTotal),
                subtext: '${totalRevenue > 0 ? ((cbgTotal / totalRevenue) * 100).round() : 0}% of Portfolio',
                accentColor: const Color(0xFF2563EB),
                icon: Icons.local_fire_department,
              ),
              ModuleKpiItem(
                label: 'CARBON CREDIT MONETIZATION',
                value: _formatINR(cerTotal),
                subtext: cerTotal > 0 ? 'Verified Carbon Credits Active' : 'No Active Carbon Credits',
                accentColor: cerTotal > 0 ? const Color(0xFF059669) : const Color(0xFF64748B),
                icon: Icons.air,
              ),
              ModuleKpiItem(
                label: 'RECEIVABLES & OVERDUE',
                value: _formatINR(pendingRevenue + overdueRevenue),
                subtext: 'Overdue: ${_formatINR(overdueRevenue)}',
                accentColor: overdueRevenue > 0 ? const Color(0xFFDC2626) : const Color(0xFFF59E0B),
                valueColor: overdueRevenue > 0 ? const Color(0xFFDC2626) : const Color(0xFFF59E0B),
                icon: Icons.schedule,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Distribution Portfolio Card
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
                Text('Revenue Stream Distribution Portfolio', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5)),
                Text('Target: 60% CBG, 20% FOM, 15% CERs, 5% Municipal', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _streamChip('CBG Offtakes', _formatINR(cbgTotal), totalRevenue > 0 ? ((cbgTotal / totalRevenue) * 100).round() : 0, const Color(0xFF2563EB))),
                    const SizedBox(width: 8),
                    Expanded(child: _streamChip('FOM Manure', _formatINR(fomTotal), totalRevenue > 0 ? ((fomTotal / totalRevenue) * 100).round() : 0, const Color(0xFF10B981))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _streamChip('Carbon CERs', _formatINR(cerTotal), totalRevenue > 0 ? ((cerTotal / totalRevenue) * 100).round() : 0, const Color(0xFF7C3AED))),
                    const SizedBox(width: 8),
                    Expanded(child: _streamChip('Tipping Fees', _formatINR(tipTotal), totalRevenue > 0 ? ((tipTotal / totalRevenue) * 100).round() : 0, const Color(0xFFF59E0B))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: moduleInputDecoration('Search by offtaker, invoice ID, or plant...').copyWith(
              prefixIcon: const Icon(Icons.search, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _streamFilter,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Stream'),
                  items: _streams.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _streamFilter = v ?? 'All Streams'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Status'),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'Settled', child: Text('Settled')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v ?? 'All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No revenue transactions found',
              subtitle: 'Record a revenue invoice or adjust your filters.',
            )
          else
            ...filtered.map((t) {
              final amt = _num(t['amount']);
              final status = (t['paymentStatus'] ?? 'Pending').toString();
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
                          child: Text((t['offtaker'] ?? '').toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        ),
                        ModuleTag(
                          text: status,
                          bgColor: status == 'Settled' ? const Color(0xFFDCFCE7) : status == 'Pending' ? const Color(0xFFDBEAFE) : const Color(0xFFFEF3C7),
                          textColor: status == 'Settled' ? const Color(0xFF166534) : status == 'Pending' ? const Color(0xFF1E40AF) : const Color(0xFF92400E),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${t['id']} • ${t['stream']} • UTR: ${t['utr'] ?? '-'}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF2563EB))),
                    Text('${t['plant']} • Vol: ${t['volume']} (${t['unitRate']})', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatINR(amt), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800)),
                            Text('Inv: ${t['invoiceDate']} • Due: ${t['dueDate']}', style: GoogleFonts.inter(fontSize: 11, color: status == 'Overdue' ? const Color(0xFFDC2626) : const Color(0xFF64748B))),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(onPressed: () => _openForm(existing: t), icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF059669))),
                            IconButton(onPressed: () => _deleteItem(t['id'].toString()), icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626))),
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

  Widget _streamChip(String title, String val, int pct, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 3.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(val, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          Text('$pct% share', style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }
}
