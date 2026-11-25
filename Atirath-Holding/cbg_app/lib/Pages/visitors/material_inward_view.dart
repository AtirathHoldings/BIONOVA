import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/visitor_data_service.dart';
import '../../widgets/module_ui_widgets.dart';

class MaterialInwardView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const MaterialInwardView({super.key, required this.screenPerm, required this.onNavigate});

  @override
  State<MaterialInwardView> createState() => _MaterialInwardViewState();
}

class _MaterialInwardViewState extends State<MaterialInwardView> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await VisitorDataService.instance.getStoredList(VisitorStorageKeys.materialInward);
    if (mounted) {
      setState(() {
        _items = list;
        _isLoading = false;
      });
    }
  }

  void _openLogModal() {
    final formKey = GlobalKey<FormState>();
    final challanCtrl = TextEditingController();
    final poCtrl = TextEditingController();
    final supplierCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final vehicleCtrl = TextEditingController();
    String category = 'Biomass Feedstock';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Log Inward Material Gate Entry', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: challanCtrl, decoration: moduleInputDecoration('Challan / DC No *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null)),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: poCtrl, decoration: moduleInputDecoration('PO Number'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: supplierCtrl, decoration: moduleInputDecoration('Supplier / Vendor *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: moduleInputDecoration('Material Category'),
                    items: const [
                      DropdownMenuItem(value: 'Biomass Feedstock', child: Text('Biomass Feedstock')),
                      DropdownMenuItem(value: 'Engineering / Piping Spares', child: Text('Engineering / Piping Spares')),
                      DropdownMenuItem(value: 'Chemicals & Inoculum', child: Text('Chemicals & Inoculum')),
                      DropdownMenuItem(value: 'Contractor Tools (Returnable)', child: Text('Contractor Tools (Returnable)')),
                    ],
                    onChanged: (v) => setModalState(() => category = v ?? category),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: descCtrl, decoration: moduleInputDecoration('Item Description *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: qtyCtrl, decoration: moduleInputDecoration('Quantity / UOM *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null)),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: vehicleCtrl, decoration: moduleInputDecoration('Vehicle No'))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final item = {
                          'id': 'MIN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                          'challanNo': challanCtrl.text.trim(),
                          'poNumber': poCtrl.text.trim(),
                          'supplier': supplierCtrl.text.trim(),
                          'category': category,
                          'description': descCtrl.text.trim(),
                          'quantity': qtyCtrl.text.trim(),
                          'vehicleNo': vehicleCtrl.text.trim().toUpperCase(),
                          'status': 'Verified at Gate',
                          'loggedAt': DateTime.now().toIso8601String(),
                        };
                        final updated = [item, ..._items];
                        setState(() => _items = updated);
                        await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.materialInward, updated);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('Log Inward Consignment'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((m) {
      final q = _searchTerm.trim().toLowerCase();
      return q.isEmpty ||
          (m['challanNo'] ?? '').toString().toLowerCase().contains(q) ||
          (m['supplier'] ?? '').toString().toLowerCase().contains(q) ||
          (m['description'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Material Inward Gate Ledger', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('Verify inward challans, feedstock deliveries & contractor tools', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              if (widget.screenPerm.canCreate)
                ElevatedButton.icon(
                  onPressed: _openLogModal,
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('Log Inward'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ModuleKpiGrid(items: [
            ModuleKpiItem(label: 'Total Consignments', value: '${_items.length}', subtext: 'Inward gate entries', accentColor: const Color(0xFF059669), icon: Icons.move_to_inbox_outlined),
            ModuleKpiItem(label: 'Verified at Gate', value: '${_items.where((x) => x['status'] == 'Verified at Gate').length}', subtext: 'Cleared to yard', accentColor: const Color(0xFF2563EB), icon: Icons.verified_outlined),
          ]),
          const SizedBox(height: 12),
          TextField(decoration: moduleInputDecoration('Search challan, supplier, material...'), onChanged: (v) => setState(() => _searchTerm = v)),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(icon: Icons.move_to_inbox_outlined, title: 'No Inward Material Records', subtitle: 'Log supplier challans and inward deliveries at the security gate.')
          else
            ...filtered.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ModuleTag(text: '${m['challanNo'] ?? m['id']}', bgColor: const Color(0xFFEFF6FF), textColor: const Color(0xFF1D4ED8)),
                          const Spacer(),
                          ModuleTag(text: '${m['status'] ?? 'Verified'}', bgColor: const Color(0xFFD1FAE5), textColor: const Color(0xFF059669)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${m['description'] ?? '-'} (${m['quantity'] ?? '-'})', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800)),
                      Text('Supplier: ${m['supplier'] ?? '-'} • ${m['category'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                      Text('PO: ${m['poNumber'] ?? '-'} • Vehicle: ${m['vehicleNo'] ?? '-'}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
