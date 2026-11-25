import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/inventory_api_service.dart';
import '../../services/rbac_service.dart';
import '../../widgets/module_ui_widgets.dart';

class AgriInventoryOverviewView extends StatefulWidget {
  final ScreenPermission screenPerm;

  const AgriInventoryOverviewView({super.key, required this.screenPerm});

  @override
  State<AgriInventoryOverviewView> createState() => _AgriInventoryOverviewViewState();
}

class _AgriInventoryOverviewViewState extends State<AgriInventoryOverviewView> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String _searchTerm = '';
  String _categoryFilter = 'All';
  String _statusFilter = 'All';
  String _plantFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final local = await InventoryApiService.loadLocalList(InventoryStorageKeys.items);
    if (mounted && local.isNotEmpty) {
      setState(() {
        _items = local;
        _isLoading = false;
      });
    }
    final remote = await InventoryApiService.getInventoryItems();
    if (mounted) {
      setState(() {
        if (remote.isNotEmpty) {
          _items = remote;
          InventoryApiService.saveLocalList(InventoryStorageKeys.items, _items);
        }
        _isLoading = false;
      });
    }
  }

  double _num(dynamic v) => v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0.0);

  ({String label, Color bg, Color fg}) _stockStatus(double current, double threshold) {
    if (current <= 0) return (label: 'Out of Stock', bg: const Color(0xFFFEE2E2), fg: const Color(0xFF991B1B));
    if (current <= threshold) return (label: 'Low Stock', bg: const Color(0xFFFEF3C7), fg: const Color(0xFF92400E));
    return (label: 'In Stock', bg: const Color(0xFFDCFCE7), fg: const Color(0xFF166534));
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchTerm.toLowerCase();
    return _items.where((item) {
      final matchesSearch = (item['name'] ?? '').toString().toLowerCase().contains(q) ||
          (item['sku'] ?? '').toString().toLowerCase().contains(q) ||
          (item['batchNo'] ?? '').toString().toLowerCase().contains(q) ||
          (item['supplier'] ?? '').toString().toLowerCase().contains(q);
      final matchesCat = _categoryFilter == 'All' || item['category'] == _categoryFilter;
      final matchesPlant = _plantFilter == 'All' || item['plantLocation'] == _plantFilter;
      final st = _stockStatus(_num(item['currentStock']), _num(item['reorderThreshold'])).label;
      final matchesStatus = _statusFilter == 'All' || st == _statusFilter;
      return matchesSearch && matchesCat && matchesPlant && matchesStatus;
    }).toList();
  }

  void _openForm({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final nowTs = DateTime.now().millisecondsSinceEpoch.toString();
    final skuCtrl = TextEditingController(
      text: isEdit ? (existing['sku'] ?? '').toString() : 'INV-${nowTs.substring(nowTs.length - 6)}',
    );
    final nameCtrl = TextEditingController(text: isEdit ? (existing['name'] ?? '').toString() : '');
    final batchCtrl = TextEditingController(
      text: isEdit ? (existing['batchNo'] ?? '').toString() : 'BN-LOT-${DateTime.now().year}-${100 + (DateTime.now().millisecond % 899)}',
    );
    final stockCtrl = TextEditingController(text: isEdit ? (existing['currentStock'] ?? 0).toString() : '100');
    final threshCtrl = TextEditingController(text: isEdit ? (existing['reorderThreshold'] ?? 20).toString() : '20');
    final costCtrl = TextEditingController(text: isEdit ? (existing['unitCost'] ?? 50).toString() : '50');
    final expCtrl = TextEditingController(text: isEdit ? (existing['expiryDate'] ?? '').toString() : '');
    final supCtrl = TextEditingController(text: isEdit ? (existing['supplier'] ?? '').toString() : '');
    final notesCtrl = TextEditingController(text: isEdit ? (existing['notes'] ?? '').toString() : '');

    String category = isEdit ? (existing['category'] ?? 'Seeds').toString() : 'Seeds';
    String uom = isEdit ? (existing['uom'] ?? 'Kg').toString() : 'Kg';
    String plant = isEdit ? (existing['plantLocation'] ?? 'Plant 1 - Hyderabad East CBG').toString() : 'Plant 1 - Hyderabad East CBG';

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
                    const Icon(Icons.inventory_2_outlined, color: Color(0xFF1677FF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Inventory Item' : 'Add New Inventory Item',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(child: TextField(controller: skuCtrl, decoration: moduleInputDecoration('SKU Code *'))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: moduleInputDecoration('Category *'),
                        items: const [
                          DropdownMenuItem(value: 'Seeds', child: Text('Seeds')),
                          DropdownMenuItem(value: 'Agrochemicals', child: Text('Agrochemicals')),
                          DropdownMenuItem(value: 'Equipment', child: Text('Equipment')),
                        ],
                        onChanged: (v) => setModalState(() => category = v ?? 'Seeds'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: moduleInputDecoration('Item Name *')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: batchCtrl, decoration: moduleInputDecoration('Batch / Lot No *'))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: uom,
                        decoration: moduleInputDecoration('UOM *'),
                        items: const [
                          DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                          DropdownMenuItem(value: 'Liters', child: Text('Liters')),
                          DropdownMenuItem(value: 'Units', child: Text('Units')),
                          DropdownMenuItem(value: 'Stems', child: Text('Stems')),
                          DropdownMenuItem(value: 'Meters', child: Text('Meters')),
                        ],
                        onChanged: (v) => setModalState(() => uom = v ?? 'Kg'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: plant,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Plant Location *'),
                  items: const [
                    DropdownMenuItem(value: 'Plant 1 - Hyderabad East CBG', child: Text('Plant 1 - Hyderabad East CBG')),
                    DropdownMenuItem(value: 'Plant 2 - Medak Agri Hub', child: Text('Plant 2 - Medak Agri Hub')),
                    DropdownMenuItem(value: 'Plant 3 - Nalgonda Biomass Facility', child: Text('Plant 3 - Nalgonda Biomass Facility')),
                  ],
                  onChanged: (v) => setModalState(() => plant = v ?? 'Plant 1 - Hyderabad East CBG'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Current Stock *'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: threshCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Threshold *'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Unit Cost (₹)'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: expCtrl,
                        readOnly: true,
                        decoration: moduleInputDecoration('Expiry Date'),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) expCtrl.text = picked.toIso8601String().split('T').first;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: supCtrl, decoration: moduleInputDecoration('Supplier'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: notesCtrl, maxLines: 2, decoration: moduleInputDecoration('Operational & Storage Notes')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an item name.')));
                        return;
                      }
                      final newItem = {
                        'id': isEdit ? existing['id'] : DateTime.now().millisecondsSinceEpoch,
                        'sku': skuCtrl.text.trim(),
                        'name': nameCtrl.text.trim(),
                        'category': category,
                        'batchNo': batchCtrl.text.trim(),
                        'currentStock': double.tryParse(stockCtrl.text.trim()) ?? 0,
                        'reorderThreshold': double.tryParse(threshCtrl.text.trim()) ?? 0,
                        'uom': uom,
                        'plantLocation': plant,
                        'unitCost': double.tryParse(costCtrl.text.trim()) ?? 0,
                        'expiryDate': expCtrl.text.trim(),
                        'supplier': supCtrl.text.trim(),
                        'notes': notesCtrl.text.trim(),
                      };
                      setState(() {
                        if (isEdit) {
                          _items = _items.map((it) => it['id'] == existing['id'] ? newItem : it).toList();
                        } else {
                          _items = [newItem, ..._items];
                          InventoryApiService.saveInventoryItem(newItem).then((res) {
                            if (res != null && mounted) {
                              setState(() {
                                _items = [res, ..._items.where((i) => i['id'] != newItem['id'])];
                              });
                              InventoryApiService.saveLocalList(InventoryStorageKeys.items, _items);
                            }
                          }).catchError((_) {});
                        }
                        InventoryApiService.saveLocalList(InventoryStorageKeys.items, _items);
                      });
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: Text(isEdit ? 'Save Changes' : 'Create Inventory Item'),
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

  void _openAdjustModal(Map<String, dynamic> item) {
    final qtyCtrl = TextEditingController();
    String adjType = 'add';
    String reason = 'Received Shipment';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Quick Stock Adjustment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item['name']}', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                Text('Current Stock: ${item['currentStock']} ${item['uom']}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1677FF))),
                const SizedBox(height: 12),
                RadioGroup<String>(
                  groupValue: adjType,
                  onChanged: (v) => setDialogState(() => adjType = v ?? adjType),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      RadioListTile<String>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: 'add',
                        title: Text('Add Inward Stock (+)'),
                      ),
                      RadioListTile<String>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: 'subtract',
                        title: Text('Deduct Outward Usage (-)'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: moduleInputDecoration('Quantity (${item['uom']}) *'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Reason'),
                  items: const [
                    DropdownMenuItem(value: 'Received Shipment', child: Text('Received Shipment from Vendor')),
                    DropdownMenuItem(value: 'Transferred to Field', child: Text('Dispatched to Farmland / Digester')),
                    DropdownMenuItem(value: 'Cycle Count Variance', child: Text('Audit / Physical Count Variance')),
                    DropdownMenuItem(value: 'Damaged / Spoiled', child: Text('Damaged or Expired Stock Write-off')),
                  ],
                  onChanged: (v) => setDialogState(() => reason = v ?? 'Received Shipment'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
                if (qty <= 0) return;
                setState(() {
                  _items = _items.map((it) {
                    if (it['id'] == item['id']) {
                      final curr = _num(it['currentStock']);
                      final updated = adjType == 'add' ? curr + qty : (curr - qty).clamp(0, double.infinity);
                      return {...it, 'currentStock': updated};
                    }
                    return it;
                  }).toList();
                  InventoryApiService.saveLocalList(InventoryStorageKeys.items, _items);
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1677FF), foregroundColor: Colors.white),
              child: const Text('Apply Adjustment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailModal(Map<String, dynamic> item) {
    final stock = _num(item['currentStock']);
    final cost = _num(item['unitCost']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Inventory Item Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item['name']}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
            Text('${item['sku']} • ${item['category']}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1677FF))),
            const Divider(height: 16),
            Text('Batch / Lot: ${item['batchNo']}'),
            Text('Plant: ${item['plantLocation']}'),
            Text('Current Stock: $stock ${item['uom']} (Threshold: ${item['reorderThreshold']} ${item['uom']})'),
            Text('Unit Cost: ₹$cost • Total Value: ₹${(stock * cost).round()}'),
            Text('Expiry Date: ${(item['expiryDate'] ?? '').toString().isEmpty ? "N/A" : item['expiryDate']}'),
            Text('Supplier: ${(item['supplier'] ?? '').toString().isEmpty ? "N/A" : item['supplier']}'),
            const SizedBox(height: 6),
            Text('Notes: ${(item['notes'] ?? '').toString().isEmpty ? "None." : item['notes']}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _deleteItem(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this inventory item?'),
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
      InventoryApiService.deleteInventoryItem(id).catchError((_) {});
      setState(() {
        _items.removeWhere((it) => it['id'] == id);
        InventoryApiService.saveLocalList(InventoryStorageKeys.items, _items);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalValuation = _items.fold<double>(0, (sum, i) => sum + (_num(i['currentStock']) * _num(i['unitCost'])));
    final lowStockCount = _items.where((i) => _num(i['currentStock']) > 0 && _num(i['currentStock']) <= _num(i['reorderThreshold'])).length;
    final outCount = _items.where((i) => _num(i['currentStock']) <= 0).length;
    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            'Track seeds, agrochemicals, processing equipment, batch numbers, stock levels, and automated reorder alerts.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'bionova_inventory_${DateTime.now().toIso8601String().split('T').first}.csv',
                    headers: ['SKU', 'Item Name', 'Category', 'Batch No', 'Stock', 'UOM', 'Threshold', 'Plant Location', 'Unit Cost (INR)', 'Total Value', 'Expiry Date', 'Supplier'],
                    rows: filtered
                        .map((it) => [
                              it['sku'],
                              it['name'],
                              it['category'],
                              it['batchNo'],
                              it['currentStock'],
                              it['uom'],
                              it['reorderThreshold'],
                              it['plantLocation'],
                              it['unitCost'],
                              _num(it['currentStock']) * _num(it['unitCost']),
                              it['expiryDate'] ?? 'N/A',
                              it['supplier'] ?? '',
                            ])
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
                    label: const Text('Add Item'),
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
                label: 'TOTAL TRACKED ITEMS',
                value: '${_items.length} SKUs',
                subtext: 'Across 3 Plant Sites',
                accentColor: const Color(0xFF059669),
                icon: Icons.inventory_2_outlined,
              ),
              ModuleKpiItem(
                label: 'TOTAL VALUATION',
                value: '₹${totalValuation.round()}',
                subtext: 'Current Stock Asset Value',
                accentColor: const Color(0xFF2563EB),
                icon: Icons.layers_outlined,
              ),
              ModuleKpiItem(
                label: 'LOW STOCK WARNINGS',
                value: '$lowStockCount Items',
                subtext: 'Below Reorder Threshold',
                accentColor: const Color(0xFFD97706),
                icon: Icons.warning_amber_rounded,
              ),
              ModuleKpiItem(
                label: 'DEPLETED STOCK',
                value: '$outCount Items',
                subtext: 'Requires immediate restock',
                accentColor: const Color(0xFFDC2626),
                icon: Icons.remove_shopping_cart_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _searchTerm = v),
            decoration: moduleInputDecoration('Search SKU, item name, batch, or supplier...').copyWith(
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
                    DropdownMenuItem(value: 'Seeds', child: Text('Seeds')),
                    DropdownMenuItem(value: 'Agrochemicals', child: Text('Agrochemicals')),
                    DropdownMenuItem(value: 'Equipment', child: Text('Equipment')),
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
                    DropdownMenuItem(value: 'All', child: Text('All Levels')),
                    DropdownMenuItem(value: 'In Stock', child: Text('In Stock')),
                    DropdownMenuItem(value: 'Low Stock', child: Text('Low Stock')),
                    DropdownMenuItem(value: 'Out of Stock', child: Text('Out of Stock')),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v ?? 'All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _plantFilter,
            isExpanded: true,
            decoration: moduleInputDecoration('Plant Location'),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All Plant Locations')),
              DropdownMenuItem(value: 'Plant 1 - Hyderabad East CBG', child: Text('Plant 1 - Hyderabad East CBG')),
              DropdownMenuItem(value: 'Plant 2 - Medak Agri Hub', child: Text('Plant 2 - Medak Agri Hub')),
              DropdownMenuItem(value: 'Plant 3 - Nalgonda Biomass Facility', child: Text('Plant 3 - Nalgonda Biomass Facility')),
            ],
            onChanged: (v) => setState(() => _plantFilter = v ?? 'All'),
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No inventory records match filters',
              subtitle: 'Add a new inventory item or clear active filters.',
            )
          else
            ...filtered.map((item) {
              final st = _stockStatus(_num(item['currentStock']), _num(item['reorderThreshold']));
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
                        ModuleTag(text: st.label, bgColor: st.bg, textColor: st.fg),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('${item['sku']} • ${item['category']} • Batch: ${item['batchNo']}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                    Text('${item['plantLocation']} • Exp: ${(item['expiryDate'] ?? '').toString().isEmpty ? "N/A" : item['expiryDate']}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Stock: ${item['currentStock']} ${item['uom']} (Min: ${item['reorderThreshold']} ${item['uom']})',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                        ),
                        Row(
                          children: [
                            if (widget.screenPerm.canEdit)
                              IconButton(onPressed: () => _openAdjustModal(item), icon: const Icon(Icons.swap_vert, size: 18, color: Color(0xFF3B82F6))),
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
