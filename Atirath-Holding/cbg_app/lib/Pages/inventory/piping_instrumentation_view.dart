import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/inventory_api_service.dart';
import '../../services/rbac_service.dart';
import '../../widgets/module_ui_widgets.dart';

class PipingInstrumentationView extends StatefulWidget {
  final ScreenPermission screenPerm;

  const PipingInstrumentationView({super.key, required this.screenPerm});

  @override
  State<PipingInstrumentationView> createState() => _PipingInstrumentationViewState();
}

class _PipingInstrumentationViewState extends State<PipingInstrumentationView> {
  List<Map<String, dynamic>> _spares = [];
  bool _isLoading = true;
  String _searchTerm = '';
  String _categoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final local = await InventoryApiService.loadLocalList(InventoryStorageKeys.piping);
    if (mounted) {
      setState(() {
        _spares = local;
        _isLoading = false;
      });
    }
  }

  double _num(dynamic v) => v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0.0);

  List<Map<String, dynamic>> get _filtered {
    final q = _searchTerm.toLowerCase();
    return _spares.where((item) {
      final matchesSearch = (item['tagNo'] ?? '').toString().toLowerCase().contains(q) ||
          (item['name'] ?? '').toString().toLowerCase().contains(q) ||
          (item['material'] ?? '').toString().toLowerCase().contains(q) ||
          (item['sizeRating'] ?? '').toString().toLowerCase().contains(q) ||
          (item['pidLineRef'] ?? '').toString().toLowerCase().contains(q) ||
          (item['supplier'] ?? '').toString().toLowerCase().contains(q);
      final matchesCat = _categoryFilter == 'All' || item['category'] == _categoryFilter;
      return matchesSearch && matchesCat;
    }).toList();
  }

  void _openForm({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final tagCtrl = TextEditingController(text: isEdit ? (existing['tagNo'] ?? '').toString() : 'PID-VLV-${ts.substring(ts.length - 4)}');
    final nameCtrl = TextEditingController(text: isEdit ? (existing['name'] ?? '').toString() : '');
    final matCtrl = TextEditingController(text: isEdit ? (existing['material'] ?? 'Forged Steel A105 / SS316').toString() : 'Forged Steel A105 / SS316');
    final sizeCtrl = TextEditingController(text: isEdit ? (existing['sizeRating'] ?? '2-Inch Class 300 (50 Bar)').toString() : '2-Inch Class 300 (50 Bar)');
    final connCtrl = TextEditingController(text: isEdit ? (existing['endConnection'] ?? 'Flanged ANSI 300# RF').toString() : 'Flanged ANSI 300# RF');
    final tempCtrl = TextEditingController(text: isEdit ? (existing['operatingTemp'] ?? '-20°C to +120°C').toString() : '-20°C to +120°C');
    final stockCtrl = TextEditingController(text: isEdit ? (existing['currentStock'] ?? 5).toString() : '5');
    final threshCtrl = TextEditingController(text: isEdit ? (existing['reorderThreshold'] ?? 2).toString() : '2');
    final costCtrl = TextEditingController(text: isEdit ? (existing['unitCost'] ?? 25000).toString() : '25000');
    final lineCtrl = TextEditingController(text: isEdit ? (existing['pidLineRef'] ?? '').toString() : '');
    final locCtrl = TextEditingController(text: isEdit ? (existing['location'] ?? 'Instrument Store Room').toString() : 'Instrument Store Room');
    final supCtrl = TextEditingController(text: isEdit ? (existing['supplier'] ?? '').toString() : '');
    final notesCtrl = TextEditingController(text: isEdit ? (existing['notes'] ?? '').toString() : '');

    String category = isEdit ? (existing['category'] ?? 'Manual Valves').toString() : 'Manual Valves';
    String uom = isEdit ? (existing['uom'] ?? 'Units').toString() : 'Units';

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
                    const Icon(Icons.settings_input_component_outlined, color: Color(0xFF1677FF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit P&ID Hardware' : 'Add P&ID Hardware / Valve',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(child: TextField(controller: tagCtrl, decoration: moduleInputDecoration('P&ID Tag No *'))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        isExpanded: true,
                        decoration: moduleInputDecoration('Category *'),
                        items: const [
                          DropdownMenuItem(value: 'Pipes & Tubing', child: Text('Pipes & Tubing')),
                          DropdownMenuItem(value: 'Manual Valves', child: Text('Manual Valves')),
                          DropdownMenuItem(value: 'Pneumatic Valves', child: Text('Pneumatic Valves')),
                          DropdownMenuItem(value: 'Flame Arrestors & PRVs', child: Text('Flame Arrestors & PRVs')),
                          DropdownMenuItem(value: 'Flow Meters & Instrumentation', child: Text('Flow Meters')),
                        ],
                        onChanged: (v) => setModalState(() => category = v ?? 'Manual Valves'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: moduleInputDecoration('Item Name & Technical Description *')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: matCtrl, decoration: moduleInputDecoration('Material / Metallurgy *'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: sizeCtrl, decoration: moduleInputDecoration('Size & Pressure Rating *'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: connCtrl, decoration: moduleInputDecoration('End Connection *'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: tempCtrl, decoration: moduleInputDecoration('Operating Temp'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Stock *'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: threshCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Threshold *'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Cost (₹) *'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: uom,
                        decoration: moduleInputDecoration('UOM *'),
                        items: const [
                          DropdownMenuItem(value: 'Units', child: Text('Units')),
                          DropdownMenuItem(value: 'Meters', child: Text('Meters')),
                          DropdownMenuItem(value: 'Lengths', child: Text('Lengths')),
                        ],
                        onChanged: (v) => setModalState(() => uom = v ?? 'Units'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: lineCtrl, decoration: moduleInputDecoration('P&ID Line Ref'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: locCtrl, decoration: moduleInputDecoration('Warehouse Location'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: supCtrl, decoration: moduleInputDecoration('Approved OEM'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: notesCtrl, maxLines: 2, decoration: moduleInputDecoration('Engineering Notes')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final item = {
                        'id': isEdit ? existing['id'] : DateTime.now().millisecondsSinceEpoch,
                        'tagNo': tagCtrl.text.trim(),
                        'name': nameCtrl.text.trim(),
                        'category': category,
                        'material': matCtrl.text.trim(),
                        'sizeRating': sizeCtrl.text.trim(),
                        'endConnection': connCtrl.text.trim(),
                        'operatingTemp': tempCtrl.text.trim(),
                        'currentStock': double.tryParse(stockCtrl.text.trim()) ?? 0,
                        'reorderThreshold': double.tryParse(threshCtrl.text.trim()) ?? 0,
                        'uom': uom,
                        'location': locCtrl.text.trim(),
                        'unitCost': double.tryParse(costCtrl.text.trim()) ?? 0,
                        'supplier': supCtrl.text.trim(),
                        'pidLineRef': lineCtrl.text.trim(),
                        'notes': notesCtrl.text.trim(),
                      };
                      setState(() {
                        if (isEdit) {
                          _spares = _spares.map((s) => s['id'] == existing['id'] ? item : s).toList();
                        } else {
                          _spares = [item, ..._spares];
                        }
                        InventoryApiService.saveLocalList(InventoryStorageKeys.piping, _spares);
                      });
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: Text(isEdit ? 'Update Hardware' : 'Save P&ID Hardware'),
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

  void _showDetailModal(Map<String, dynamic> s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('P&ID Engineering Datasheet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s['name']}', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            Text('Tag: ${s['tagNo']} • ${s['category']}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF2563EB))),
            const Divider(height: 16),
            Text('Size & Rating: ${s['sizeRating']}'),
            Text('Metallurgy: ${s['material']}'),
            Text('End Connection: ${s['endConnection']}'),
            Text('Temp Range: ${s['operatingTemp']}'),
            Text('Process Line: ${s['pidLineRef']}'),
            Text('Stock on Hand: ${s['currentStock']} ${s['uom']}'),
            Text('Unit Replacement Cost: ₹${s['unitCost']}'),
            Text('OEM / Supplier: ${s['supplier'] ?? 'N/A'}'),
            const SizedBox(height: 6),
            Text('Notes: ${(s['notes'] ?? '').toString().isEmpty ? "Standard API / IS compliant." : s['notes']}'),
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
        title: const Text('Delete P&ID Hardware'),
        content: const Text('Are you sure you want to delete this P&ID hardware record?'),
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
        _spares.removeWhere((s) => s['id'] == id);
        InventoryApiService.saveLocalList(InventoryStorageKeys.piping, _spares);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalVal = _spares.fold<double>(0, (acc, it) => acc + (_num(it['currentStock']) * _num(it['unitCost'])));
    final lowCount = _spares.where((it) => _num(it['currentStock']) <= _num(it['reorderThreshold'])).length;
    final criticalCount = _spares.where((it) => it['category'] == 'Flame Arrestors & PRVs' || it['category'] == 'Pneumatic Valves').length;
    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            'Manage HDPE PE100 slurry pipes, carbon/stainless steel high-pressure gas pipes, ball/butterfly/pneumatic valves, flame arrestors, PRVs, and flow meters.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'bionova_pid_spares_${DateTime.now().toIso8601String().split('T').first}.csv',
                    headers: ['P&ID Tag', 'Description', 'Category', 'Material', 'Size / Rating', 'End Connection', 'Operating Temp', 'Stock', 'Threshold', 'UOM', 'Location', 'Unit Cost', 'P&ID Line Ref', 'Supplier'],
                    rows: filtered
                        .map((s) => [s['tagNo'], s['name'], s['category'], s['material'], s['sizeRating'], s['endConnection'], s['operatingTemp'], s['currentStock'], s['reorderThreshold'], s['uom'], s['location'], s['unitCost'], s['pidLineRef'], s['supplier']])
                        .toList(),
                  ),
                  icon: const Icon(Icons.download, size: 15),
                  label: const Text('Export P&ID CSV'),
                ),
              ),
              if (widget.screenPerm.canCreate) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add P&ID Hardware'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1677FF), foregroundColor: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          ModuleKpiGrid(
            items: [
              ModuleKpiItem(label: 'TOTAL P&ID LINE ITEMS', value: '${_spares.length} Spares', subtext: 'Pipes, Valves, PRVs', accentColor: const Color(0xFF2563EB), icon: Icons.layers_outlined),
              ModuleKpiItem(label: 'INVENTORY VALUATION', value: '₹${(totalVal / 100000).toStringAsFixed(2)} L', subtext: 'Capital Mechanical Assets', accentColor: const Color(0xFF059669), icon: Icons.speed),
              ModuleKpiItem(label: 'SAFETY CRITICAL UNITS', value: '$criticalCount Items', subtext: 'ATEX Flame Arrestors & PRVs', accentColor: const Color(0xFFD97706), icon: Icons.local_fire_department),
              ModuleKpiItem(label: 'LOW STOCK WARNINGS', value: '$lowCount Spares', subtext: 'Below Minimum Stock', accentColor: lowCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B), valueColor: lowCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF0F172A), icon: Icons.warning_amber_rounded),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _searchTerm = v),
            decoration: moduleInputDecoration('Search P&ID tag, material, size, line ref, or supplier...').copyWith(prefixIcon: const Icon(Icons.search, size: 18)),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _categoryFilter,
            isExpanded: true,
            decoration: moduleInputDecoration('P&ID Category'),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All P&ID Categories')),
              DropdownMenuItem(value: 'Pipes & Tubing', child: Text('Pipes & Tubing')),
              DropdownMenuItem(value: 'Manual Valves', child: Text('Manual Valves')),
              DropdownMenuItem(value: 'Pneumatic Valves', child: Text('Pneumatic Actuated ESD Valves')),
              DropdownMenuItem(value: 'Flame Arrestors & PRVs', child: Text('Flame Arrestors & PRVs')),
              DropdownMenuItem(value: 'Flow Meters & Instrumentation', child: Text('Flow Meters & Instrumentation')),
            ],
            onChanged: (v) => setState(() => _categoryFilter = v ?? 'All'),
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(icon: Icons.layers_outlined, title: 'No P&ID hardware matches filters', subtitle: 'Add P&ID hardware or clear active filters.')
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
                        ModuleTag(text: '${item['tagNo']}', bgColor: const Color(0xFFEFF6FF), textColor: const Color(0xFF1D4ED8)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('${item['category']} • ${item['sizeRating']}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                    Text('${item['material']} • ${item['endConnection']}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF475569))),
                    Text('Line: ${item['pidLineRef']} • Loc: ${item['location']}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF2563EB))),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Stock: ${item['currentStock']} ${item['uom']} (Min: ${item['reorderThreshold']})',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: isLow ? const Color(0xFFDC2626) : const Color(0xFF059669)),
                        ),
                        Row(
                          children: [
                            IconButton(onPressed: () => _showDetailModal(item), icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF475569))),
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
