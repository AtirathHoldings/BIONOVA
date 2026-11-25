import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/inventory_api_service.dart';
import '../../services/rbac_service.dart';
import '../../widgets/module_ui_widgets.dart';

class FastenersHardwareView extends StatefulWidget {
  final ScreenPermission screenPerm;

  const FastenersHardwareView({super.key, required this.screenPerm});

  @override
  State<FastenersHardwareView> createState() => _FastenersHardwareViewState();
}

class _FastenersHardwareViewState extends State<FastenersHardwareView> {
  List<Map<String, dynamic>> _fasteners = [];
  bool _isLoading = true;
  String _searchTerm = '';
  String _gradeFilter = 'All';
  String _coatingFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final local = await InventoryApiService.loadLocalList(InventoryStorageKeys.fasteners);
    if (mounted) {
      setState(() {
        _fasteners = local;
        _isLoading = false;
      });
    }
  }

  double _num(dynamic v) => v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0.0);

  List<Map<String, dynamic>> get _filtered {
    final q = _searchTerm.toLowerCase();
    return _fasteners.where((item) {
      final matchesSearch = (item['sku'] ?? '').toString().toLowerCase().contains(q) ||
          (item['name'] ?? '').toString().toLowerCase().contains(q) ||
          (item['threadSpec'] ?? '').toString().toLowerCase().contains(q) ||
          (item['batchNo'] ?? '').toString().toLowerCase().contains(q) ||
          (item['mtcCertNo'] ?? '').toString().toLowerCase().contains(q) ||
          (item['application'] ?? '').toString().toLowerCase().contains(q);
      final matchesGrade = _gradeFilter == 'All' || (item['grade'] ?? '').toString().contains(_gradeFilter);
      final matchesCoat = _coatingFilter == 'All' || (item['coating'] ?? '').toString().contains(_coatingFilter);
      return matchesSearch && matchesGrade && matchesCoat;
    }).toList();
  }

  void _openForm({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final skuCtrl = TextEditingController(text: isEdit ? (existing['sku'] ?? '').toString() : 'FST-NEW-${ts.substring(ts.length - 4)}');
    final nameCtrl = TextEditingController(text: isEdit ? (existing['name'] ?? '').toString() : '');
    final gradeCtrl = TextEditingController(text: isEdit ? (existing['grade'] ?? 'Grade 10.9').toString() : 'Grade 10.9');
    final threadCtrl = TextEditingController(text: isEdit ? (existing['threadSpec'] ?? 'M16 x 2.0mm').toString() : 'M16 x 2.0mm');
    final batchCtrl = TextEditingController(text: isEdit ? (existing['batchNo'] ?? '').toString() : 'BAT-${ts.substring(ts.length - 6)}');
    final heatCtrl = TextEditingController(text: isEdit ? (existing['heatNo'] ?? '').toString() : 'HT-${ts.substring(ts.length - 5)}');
    final mtcCtrl = TextEditingController(text: isEdit ? (existing['mtcCertNo'] ?? '').toString() : 'MTC-EN10204-${ts.substring(ts.length - 4)}');
    final stockCtrl = TextEditingController(text: isEdit ? (existing['currentStock'] ?? 500).toString() : '500');
    final threshCtrl = TextEditingController(text: isEdit ? (existing['reorderThreshold'] ?? 200).toString() : '200');
    final costCtrl = TextEditingController(text: isEdit ? (existing['unitCost'] ?? 85).toString() : '85');
    final locCtrl = TextEditingController(text: isEdit ? (existing['location'] ?? 'Store Room B - Bin 10').toString() : 'Store Room B - Bin 10');
    final appCtrl = TextEditingController(text: isEdit ? (existing['application'] ?? '').toString() : '');

    String category = isEdit ? (existing['category'] ?? 'High-Tensile Bolts').toString() : 'High-Tensile Bolts';
    String coating = isEdit ? (existing['coating'] ?? 'Hot-Dip Galvanized (HDG 65µm)').toString() : 'PTFE / Teflon (FluoroKote#1)';
    const coatingOpts = [
      'Hot-Dip Galvanized (HDG 65µm)',
      'PTFE / Teflon (FluoroKote#1)',
      'Geomet 500 (Non-Electrolytic)',
      'Passivated SS 316 (ASTM A380)',
      'Zinc Yellow Trivalent Passivated',
      'Ruspert 1000-Hr Salt Spray',
    ];
    if (!coatingOpts.contains(coating)) coating = coatingOpts.first;

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
                    const Icon(Icons.build_outlined, color: Color(0xFF1677FF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Fastener Item' : 'Add Fastener / Hardware Item',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(child: TextField(controller: skuCtrl, decoration: moduleInputDecoration('SKU / Part Code *'))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        isExpanded: true,
                        decoration: moduleInputDecoration('Category *'),
                        items: const [
                          DropdownMenuItem(value: 'High-Tensile Bolts', child: Text('High-Tensile Bolts')),
                          DropdownMenuItem(value: 'Stainless Steel Fasteners', child: Text('Stainless Steel')),
                          DropdownMenuItem(value: 'Anchors & Hardware', child: Text('Anchors & Hardware')),
                          DropdownMenuItem(value: 'Screws & Joining Hardware', child: Text('Screws & PEB')),
                        ],
                        onChanged: (v) => setModalState(() => category = v ?? 'High-Tensile Bolts'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: moduleInputDecoration('Fastener Name & Dimension *')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: gradeCtrl, decoration: moduleInputDecoration('Grade / Metallurgy *'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: threadCtrl, decoration: moduleInputDecoration('Thread Spec *'))),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: coating,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Anti-Corrosion Coating'),
                  items: coatingOpts.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModalState(() => coating = v ?? coatingOpts.first),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: batchCtrl, decoration: moduleInputDecoration('Batch No *'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: heatCtrl, decoration: moduleInputDecoration('Heat Cast No *'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: mtcCtrl, decoration: moduleInputDecoration('MTC Cert No *'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Stock Qty *'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: threshCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Min Threshold *'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Unit Cost (₹) *'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: locCtrl, decoration: moduleInputDecoration('Storage Bin / Rack Location')),
                const SizedBox(height: 10),
                TextField(controller: appCtrl, decoration: moduleInputDecoration('Plant Application')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final item = {
                        'id': isEdit ? existing['id'] : DateTime.now().millisecondsSinceEpoch,
                        'sku': skuCtrl.text.trim(),
                        'name': nameCtrl.text.trim(),
                        'category': category,
                        'grade': gradeCtrl.text.trim(),
                        'threadSpec': threadCtrl.text.trim(),
                        'coating': coating,
                        'batchNo': batchCtrl.text.trim(),
                        'heatNo': heatCtrl.text.trim(),
                        'mtcCertNo': mtcCtrl.text.trim(),
                        'mtcFileName': existing?['mtcFileName'] ?? 'Mill_Test_Certificate.pdf',
                        'tensileStrength': existing?['tensileStrength'] ?? '1040 MPa',
                        'yieldStrength': existing?['yieldStrength'] ?? '940 MPa',
                        'currentStock': double.tryParse(stockCtrl.text.trim()) ?? 0,
                        'reorderThreshold': double.tryParse(threshCtrl.text.trim()) ?? 0,
                        'uom': 'Pcs',
                        'location': locCtrl.text.trim(),
                        'unitCost': double.tryParse(costCtrl.text.trim()) ?? 0,
                        'supplier': existing?['supplier'] ?? '',
                        'application': appCtrl.text.trim(),
                      };
                      setState(() {
                        if (isEdit) {
                          _fasteners = _fasteners.map((f) => f['id'] == existing['id'] ? item : f).toList();
                        } else {
                          _fasteners = [item, ..._fasteners];
                        }
                        InventoryApiService.saveLocalList(InventoryStorageKeys.fasteners, _fasteners);
                      });
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: Text(isEdit ? 'Update Fastener' : 'Save Fastener Record'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1677FF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openMtcModal(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Mill Test Certificate (MTC) EN 10204 Type 3.1'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cert No: ${item['mtcCertNo']}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: const Color(0xFF1677FF))),
            Text('Batch / Heat: ${item['heatNo']} (${item['batchNo']})', style: GoogleFonts.inter(fontSize: 12)),
            const Divider(height: 16),
            Text('Material: ${item['name']}'),
            Text('Grade: ${item['grade']}'),
            Text('Coating: ${item['coating']}'),
            Text('Tensile Strength: ${item['tensileStrength'] ?? '1040 MPa'}'),
            Text('Yield Strength: ${item['yieldStrength'] ?? '940 MPa'}'),
            Text('Supplier / Mill: ${item['supplier'] ?? 'N/A'}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _deleteItem(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Fastener'),
        content: const Text('Are you sure you want to delete this structural fastener record?'),
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
      setState(() {
        _fasteners.removeWhere((f) => f['id'] == id);
        InventoryApiService.saveLocalList(InventoryStorageKeys.fasteners, _fasteners);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalUnits = _fasteners.fold<double>(0, (acc, it) => acc + _num(it['currentStock']));
    final totalVal = _fasteners.fold<double>(0, (acc, it) => acc + (_num(it['currentStock']) * _num(it['unitCost'])));
    final lowCount = _fasteners.where((it) => _num(it['currentStock']) <= _num(it['reorderThreshold'])).length;
    final mtcCount = _fasteners.where((it) => (it['mtcCertNo'] ?? '').toString().isNotEmpty).length;
    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            'High-tensile bolts (Grades 8.8, 10.9, 12.9), stainless fasteners (SS 304/316), anti-corrosion coatings, thread specs, and digital MTC certificates.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'bionova_fasteners_${DateTime.now().toIso8601String().split('T').first}.csv',
                    headers: ['SKU', 'Item Name', 'Category', 'Grade', 'Thread Spec', 'Coating', 'Batch No', 'Heat No', 'MTC Cert No', 'Stock', 'Threshold', 'UOM', 'Location', 'Unit Cost', 'Supplier', 'Application'],
                    rows: filtered
                        .map((f) => [f['sku'], f['name'], f['category'], f['grade'], f['threadSpec'], f['coating'], f['batchNo'], f['heatNo'], f['mtcCertNo'], f['currentStock'], f['reorderThreshold'], f['uom'], f['location'], f['unitCost'], f['supplier'], f['application']])
                        .toList(),
                  ),
                  icon: const Icon(Icons.download, size: 15),
                  label: const Text('Export CSV'),
                ),
              ),
              if (widget.screenPerm.canCreate) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Fastener'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1677FF), foregroundColor: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          ModuleKpiGrid(
            items: [
              ModuleKpiItem(label: 'FASTENER SKUS TRACKED', value: '${_fasteners.length} SKUs', subtext: 'Bolts, Nuts, Rods & Screws', accentColor: const Color(0xFF2563EB), icon: Icons.layers_outlined),
              ModuleKpiItem(label: 'TOTAL PHYSICAL UNITS', value: '${totalUnits.round()} Pcs', subtext: '₹${(totalVal / 100000).toStringAsFixed(2)} Lakhs', accentColor: const Color(0xFF059669), icon: Icons.build_outlined),
              ModuleKpiItem(label: 'MTC VERIFIED BATCHES', value: '$mtcCount / ${_fasteners.length}', subtext: 'EN 10204 3.1 Certificates', accentColor: const Color(0xFF4F46E5), icon: Icons.verified_outlined),
              ModuleKpiItem(label: 'LOW STOCK WARNINGS', value: '$lowCount Fasteners', subtext: 'Under Safety Level', accentColor: lowCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B), valueColor: lowCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF0F172A), icon: Icons.warning_amber_rounded),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _searchTerm = v),
            decoration: moduleInputDecoration('Search SKU, Name, Thread, Batch, MTC Cert...').copyWith(prefixIcon: const Icon(Icons.search, size: 18)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _gradeFilter,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Grade'),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Grades')),
                    DropdownMenuItem(value: '10.9', child: Text('Grade 10.9')),
                    DropdownMenuItem(value: '8.8', child: Text('Grade 8.8')),
                    DropdownMenuItem(value: '12.9', child: Text('Grade 12.9')),
                    DropdownMenuItem(value: '316', child: Text('SS 316')),
                    DropdownMenuItem(value: '304', child: Text('SS 304')),
                  ],
                  onChanged: (v) => setState(() => _gradeFilter = v ?? 'All'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _coatingFilter,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Coating'),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Coatings')),
                    DropdownMenuItem(value: 'PTFE', child: Text('PTFE / Teflon')),
                    DropdownMenuItem(value: 'Galvanized', child: Text('HDG Galvanized')),
                    DropdownMenuItem(value: 'Geomet', child: Text('Geomet 500')),
                    DropdownMenuItem(value: 'Passivated', child: Text('Passivated SS')),
                  ],
                  onChanged: (v) => setState(() => _coatingFilter = v ?? 'All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(icon: Icons.build_outlined, title: 'No fasteners match filters', subtitle: 'Add a fastener item or adjust filters.')
          else
            ...filtered.map((item) {
              final isLow = _num(item['currentStock']) <= _num(item['reorderThreshold']);
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
                        Expanded(child: Text('${item['name']}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5))),
                        ModuleTag(text: '${item['grade']}', bgColor: const Color(0xFFEFF6FF), textColor: const Color(0xFF1D4ED8)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('${item['sku']} • ${item['threadSpec']} • ${item['coating']}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                    Text('Lot: ${item['batchNo']} • Heat: ${item['heatNo']} • Bin: ${item['location']}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item['currentStock']} ${item['uom']} (Min: ${item['reorderThreshold']})',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: isLow ? const Color(0xFFDC2626) : const Color(0xFF059669)),
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => _openMtcModal(item),
                              icon: const Icon(Icons.verified_outlined, size: 15),
                              label: Text('${item['mtcCertNo']}', style: GoogleFonts.inter(fontSize: 11)),
                            ),
                            if (widget.screenPerm.canEdit)
                              IconButton(onPressed: () => _openForm(existing: item), icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF059669))),
                            if (widget.screenPerm.canDelete)
                              IconButton(onPressed: () => _deleteItem(item['id']), icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626))),
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
