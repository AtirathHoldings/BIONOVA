import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/inventory_api_service.dart';
import '../../services/rbac_service.dart';
import '../../widgets/module_ui_widgets.dart';

class CivilMaterialsBomView extends StatefulWidget {
  final ScreenPermission screenPerm;

  const CivilMaterialsBomView({super.key, required this.screenPerm});

  @override
  State<CivilMaterialsBomView> createState() => _CivilMaterialsBomViewState();
}

class _CivilMaterialsBomViewState extends State<CivilMaterialsBomView> {
  List<Map<String, dynamic>> _materials = [];
  bool _isLoading = true;
  String _searchTerm = '';
  String _categoryFilter = 'All';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final local = await InventoryApiService.loadLocalList(InventoryStorageKeys.civilBom);
    if (mounted) {
      setState(() {
        _materials = local;
        _isLoading = false;
      });
    }
  }

  double _num(dynamic v) => v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0.0);

  List<Map<String, dynamic>> get _filtered {
    final q = _searchTerm.toLowerCase();
    return _materials.where((item) {
      final matchesSearch = (item['code'] ?? '').toString().toLowerCase().contains(q) ||
          (item['name'] ?? '').toString().toLowerCase().contains(q) ||
          (item['gradeSpec'] ?? '').toString().toLowerCase().contains(q) ||
          (item['allocatedStructure'] ?? '').toString().toLowerCase().contains(q) ||
          (item['supplier'] ?? '').toString().toLowerCase().contains(q);
      final matchesCat = _categoryFilter == 'All' || item['category'] == _categoryFilter;
      final matchesStatus = _statusFilter == 'All' || item['status'] == _statusFilter;
      return matchesSearch && matchesCat && matchesStatus;
    }).toList();
  }

  void _openForm({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final codeCtrl = TextEditingController(text: isEdit ? (existing['code'] ?? '').toString() : 'CIV-MAT-${ts.substring(ts.length - 4)}');
    final nameCtrl = TextEditingController(text: isEdit ? (existing['name'] ?? '').toString() : '');
    final gradeCtrl = TextEditingController(text: isEdit ? (existing['gradeSpec'] ?? '').toString() : '');
    final reqCtrl = TextEditingController(text: isEdit ? (existing['bomRequiredQty'] ?? 100).toString() : '100');
    final procCtrl = TextEditingController(text: isEdit ? (existing['procuredQty'] ?? 80).toString() : '80');
    final stockCtrl = TextEditingController(text: isEdit ? (existing['currentStock'] ?? 20).toString() : '20');
    final costCtrl = TextEditingController(text: isEdit ? (existing['unitCost'] ?? 5000).toString() : '5000');
    final structCtrl = TextEditingController(text: isEdit ? (existing['allocatedStructure'] ?? 'Plant Foundation').toString() : 'Plant Foundation');
    final yardCtrl = TextEditingController(text: isEdit ? (existing['yardLocation'] ?? 'Main Yard Area').toString() : 'Main Yard Area');
    final supCtrl = TextEditingController(text: isEdit ? (existing['supplier'] ?? '').toString() : '');
    final notesCtrl = TextEditingController(text: isEdit ? (existing['notes'] ?? '').toString() : '');

    String category = isEdit ? (existing['category'] ?? 'Concrete Grades').toString() : 'Concrete Grades';
    String uom = isEdit ? (existing['uom'] ?? 'MT').toString() : 'MT';

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
                    const Icon(Icons.engineering_outlined, color: Color(0xFF1677FF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Civil Material' : 'Add Civil Material to BOM',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(child: TextField(controller: codeCtrl, decoration: moduleInputDecoration('Material Code *'))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        isExpanded: true,
                        decoration: moduleInputDecoration('Category *'),
                        items: const [
                          DropdownMenuItem(value: 'Concrete Grades', child: Text('Concrete Grades')),
                          DropdownMenuItem(value: 'TMT Rebars', child: Text('TMT Rebars')),
                          DropdownMenuItem(value: 'Structural Steel', child: Text('Structural Steel')),
                          DropdownMenuItem(value: 'Cement & Aggregates', child: Text('Cement & Aggregates')),
                        ],
                        onChanged: (v) => setModalState(() => category = v ?? 'Concrete Grades'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: moduleInputDecoration('Material Name & Description *')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: gradeCtrl, decoration: moduleInputDecoration('Grade / Standard *'))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: uom,
                        decoration: moduleInputDecoration('UOM *'),
                        items: const [
                          DropdownMenuItem(value: 'MT', child: Text('MT')),
                          DropdownMenuItem(value: 'Cu.m', child: Text('Cu.m')),
                          DropdownMenuItem(value: 'Bags (50Kg)', child: Text('Bags (50Kg)')),
                          DropdownMenuItem(value: 'Lengths', child: Text('Lengths')),
                          DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                        ],
                        onChanged: (v) => setModalState(() => uom = v ?? 'MT'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: reqCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('BOM Qty *'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: procCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Procured *'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Yard Stock *'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Unit Cost (₹) *'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: structCtrl, decoration: moduleInputDecoration('Allocated Structure'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: yardCtrl, decoration: moduleInputDecoration('Yard Location'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: supCtrl, decoration: moduleInputDecoration('Supplier Mill'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: notesCtrl, maxLines: 2, decoration: moduleInputDecoration('Engineering Notes')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final newItem = {
                        'id': isEdit ? existing['id'] : DateTime.now().millisecondsSinceEpoch,
                        'code': codeCtrl.text.trim(),
                        'name': nameCtrl.text.trim(),
                        'category': category,
                        'gradeSpec': gradeCtrl.text.trim(),
                        'uom': uom,
                        'bomRequiredQty': double.tryParse(reqCtrl.text.trim()) ?? 0,
                        'procuredQty': double.tryParse(procCtrl.text.trim()) ?? 0,
                        'currentStock': double.tryParse(stockCtrl.text.trim()) ?? 0,
                        'allocatedQty': isEdit ? _num(existing['allocatedQty']) : 60,
                        'allocatedStructure': structCtrl.text.trim(),
                        'yardLocation': yardCtrl.text.trim(),
                        'unitCost': double.tryParse(costCtrl.text.trim()) ?? 0,
                        'supplier': supCtrl.text.trim(),
                        'status': existing?['status'] ?? 'Adequate',
                        'notes': notesCtrl.text.trim(),
                      };
                      setState(() {
                        if (isEdit) {
                          _materials = _materials.map((m) => m['id'] == existing['id'] ? newItem : m).toList();
                        } else {
                          _materials = [newItem, ..._materials];
                        }
                        InventoryApiService.saveLocalList(InventoryStorageKeys.civilBom, _materials);
                      });
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: Text(isEdit ? 'Update Material' : 'Save BOM Item'),
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

  void _openUsageModal(Map<String, dynamic> mat) {
    final qtyCtrl = TextEditingController();
    final structCtrl = TextEditingController(text: (mat['allocatedStructure'] ?? 'CSTR Digester 1 Foundation').toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Record Structure Material Usage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${mat['name']}', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            Text('Available Yard Stock: ${mat['currentStock']} ${mat['uom']}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF059669))),
            const SizedBox(height: 12),
            TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Quantity Consumed (${mat['uom']}) *')),
            const SizedBox(height: 10),
            TextField(controller: structCtrl, decoration: moduleInputDecoration('Target Foundation / Structure')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
              final curr = _num(mat['currentStock']);
              if (qty <= 0) return;
              if (qty > curr) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Allocation qty ($qty) exceeds yard stock ($curr).')),
                );
                return;
              }
              setState(() {
                _materials = _materials.map((m) {
                  if (m['id'] == mat['id']) {
                    final newStock = curr - qty;
                    final newAlloc = _num(m['allocatedQty']) + qty;
                    final req = _num(m['bomRequiredQty']);
                    final newStatus = newStock <= 0
                        ? 'Critical Shortage'
                        : newStock < (req * 0.15)
                            ? 'Reorder Needed'
                            : 'Adequate';
                    return {
                      ...m,
                      'currentStock': newStock,
                      'allocatedQty': newAlloc,
                      'allocatedStructure': structCtrl.text.trim(),
                      'status': newStatus,
                    };
                  }
                  return m;
                }).toList();
                InventoryApiService.saveLocalList(InventoryStorageKeys.civilBom, _materials);
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            child: const Text('Confirm Usage'),
          ),
        ],
      ),
    );
  }

  void _showDetailModal(Map<String, dynamic> mat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Civil Material Specification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${mat['name']}', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            Text('${mat['code']} • ${mat['category']}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF2563EB))),
            const Divider(height: 16),
            Text('Grade / Standard: ${mat['gradeSpec']}'),
            Text('BOM Required: ${mat['bomRequiredQty']} ${mat['uom']}'),
            Text('Procured: ${mat['procuredQty']} ${mat['uom']}'),
            Text('Available Yard Stock: ${mat['currentStock']} ${mat['uom']}'),
            Text('Allocated Structure: ${mat['allocatedStructure']}'),
            Text('Yard Location: ${mat['yardLocation']}'),
            Text('Supplier: ${mat['supplier'] ?? 'N/A'}'),
            const SizedBox(height: 6),
            Text('Notes: ${(mat['notes'] ?? '').toString().isEmpty ? "None" : mat['notes']}'),
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
        title: const Text('Delete BOM Item'),
        content: const Text('Are you sure you want to delete this civil material BOM record?'),
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
        _materials.removeWhere((m) => m['id'] == id);
        InventoryApiService.saveLocalList(InventoryStorageKeys.civilBom, _materials);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalBomVal = _materials.fold<double>(0, (acc, it) => acc + (_num(it['procuredQty']) * _num(it['unitCost'])));
    final totalStockVal = _materials.fold<double>(0, (acc, it) => acc + (_num(it['currentStock']) * _num(it['unitCost'])));
    final criticalCount = _materials.where((it) => it['status'] == 'Critical Shortage').length;
    final reorderCount = _materials.where((it) => it['status'] == 'Reorder Needed').length;
    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            'Repository of civil construction materials: concrete grades (M25–M50), reinforcement TMT rebars (Fe 500D/550D), structural beams, channels, and columns.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'bionova_civil_bom_${DateTime.now().toIso8601String().split('T').first}.csv',
                    headers: ['Material Code', 'Name', 'Category', 'Grade', 'Unit', 'BOM Required', 'Procured', 'Current Stock', 'Allocated Qty', 'Allocated Structure', 'Yard Location', 'Unit Cost', 'Status', 'Supplier'],
                    rows: filtered
                        .map((m) => [m['code'], m['name'], m['category'], m['gradeSpec'], m['uom'], m['bomRequiredQty'], m['procuredQty'], m['currentStock'], m['allocatedQty'], m['allocatedStructure'], m['yardLocation'], m['unitCost'], m['status'], m['supplier']])
                        .toList(),
                  ),
                  icon: const Icon(Icons.download, size: 15),
                  label: const Text('Export BOM CSV'),
                ),
              ),
              if (widget.screenPerm.canCreate) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Civil BOM'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1677FF), foregroundColor: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          ModuleKpiGrid(
            items: [
              ModuleKpiItem(
                label: 'TOTAL BOM CIVIL ITEMS',
                value: '${_materials.length} Materials',
                subtext: 'Concrete, Steel & Rebars',
                accentColor: const Color(0xFF2563EB),
                icon: Icons.layers_outlined,
              ),
              ModuleKpiItem(
                label: 'PROCURED CAPITAL VALUE',
                value: '₹${(totalBomVal / 100000).toStringAsFixed(2)} L',
                subtext: 'Cumulative Civil Procurement',
                accentColor: const Color(0xFF059669),
                icon: Icons.apartment_outlined,
              ),
              ModuleKpiItem(
                label: 'YARD STOCK AVAILABLE',
                value: '₹${(totalStockVal / 100000).toStringAsFixed(2)} L',
                subtext: 'Unallocated Material on Site',
                accentColor: const Color(0xFFD97706),
                icon: Icons.swap_vert,
              ),
              ModuleKpiItem(
                label: 'CRITICAL / LOW ALERTS',
                value: '${criticalCount + reorderCount} Items',
                subtext: '$criticalCount Critical, $reorderCount Reorder',
                accentColor: criticalCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                valueColor: criticalCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _searchTerm = v),
            decoration: moduleInputDecoration('Search code, material, spec, structure, or supplier...').copyWith(
              prefixIcon: const Icon(Icons.search, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _categoryFilter,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Category'),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Categories')),
                    DropdownMenuItem(value: 'Concrete Grades', child: Text('Concrete Grades')),
                    DropdownMenuItem(value: 'TMT Rebars', child: Text('TMT Rebars')),
                    DropdownMenuItem(value: 'Structural Steel', child: Text('Structural Steel')),
                    DropdownMenuItem(value: 'Cement & Aggregates', child: Text('Cement & Aggregates')),
                  ],
                  onChanged: (v) => setState(() => _categoryFilter = v ?? 'All'),
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
                    DropdownMenuItem(value: 'Adequate', child: Text('Adequate Stock')),
                    DropdownMenuItem(value: 'Reorder Needed', child: Text('Reorder Needed')),
                    DropdownMenuItem(value: 'Critical Shortage', child: Text('Critical Shortage')),
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
              icon: Icons.engineering_outlined,
              title: 'No civil construction materials match filters',
              subtitle: 'Add a civil BOM material or clear active filters.',
            )
          else
            ...filtered.map((mat) {
              final req = _num(mat['bomRequiredQty']);
              final alloc = _num(mat['allocatedQty']);
              final pct = req > 0 ? ((alloc / req) * 100).round().clamp(0, 100) : 0;
              final st = (mat['status'] ?? 'Adequate').toString();
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
                        Expanded(child: Text('${mat['name']}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5))),
                        ModuleTag(
                          text: st,
                          bgColor: st == 'Adequate' ? const Color(0xFFDCFCE7) : st == 'Reorder Needed' ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2),
                          textColor: st == 'Adequate' ? const Color(0xFF166534) : st == 'Reorder Needed' ? const Color(0xFF92400E) : const Color(0xFF991B1B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('${mat['code']} • ${mat['category']} • ${mat['gradeSpec']}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                    Text('Structure: ${mat['allocatedStructure']} ($pct% used) • Yard: ${mat['yardLocation']}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF2563EB))),
                    const SizedBox(height: 6),
                    Text('BOM: ${mat['bomRequiredQty']} ${mat['uom']} | Stock: ${mat['currentStock']} ${mat['uom']}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (widget.screenPerm.canEdit)
                          IconButton(onPressed: () => _openUsageModal(mat), icon: const Icon(Icons.swap_vert, size: 18, color: Color(0xFF2563EB))),
                        IconButton(onPressed: () => _showDetailModal(mat), icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF475569))),
                        if (widget.screenPerm.canEdit)
                          IconButton(onPressed: () => _openForm(existing: mat), icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF059669))),
                        if (widget.screenPerm.canDelete)
                          IconButton(onPressed: () => _deleteItem(mat['id']), icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626))),
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
