import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/visitor_data_service.dart';
import '../../widgets/module_ui_widgets.dart';

class MaterialOutwardView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const MaterialOutwardView({super.key, required this.screenPerm, required this.onNavigate});

  @override
  State<MaterialOutwardView> createState() => _MaterialOutwardViewState();
}

class _MaterialOutwardViewState extends State<MaterialOutwardView> {
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
    final list = await VisitorDataService.instance.getStoredList(VisitorStorageKeys.materialOutward);
    if (mounted) {
      setState(() {
        _items = list;
        _isLoading = false;
      });
    }
  }

  void _openIssueModal() {
    final formKey = GlobalKey<FormState>();
    final passCtrl = TextEditingController();
    final receiverCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final authByCtrl = TextEditingController();
    String passType = 'Non-Returnable (CBG / Bio-Fertilizer Dispatch)';

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
                      Expanded(child: Text('Issue Outward Material Gate Pass', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: passType,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Gate Pass Classification'),
                    items: const [
                      DropdownMenuItem(value: 'Non-Returnable (CBG / Bio-Fertilizer Dispatch)', child: Text('Non-Returnable Dispatch')),
                      DropdownMenuItem(value: 'Returnable (Equipment Repair / Calibration)', child: Text('Returnable Repair / Calibration')),
                      DropdownMenuItem(value: 'Contractor Tools Exit', child: Text('Contractor Tools Exit')),
                    ],
                    onChanged: (v) => setModalState(() => passType = v ?? passType),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: passCtrl, decoration: moduleInputDecoration('Outward Ref / Invoice No')),
                  const SizedBox(height: 10),
                  TextFormField(controller: receiverCtrl, decoration: moduleInputDecoration('Consignee / Receiver *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 10),
                  TextFormField(controller: descCtrl, decoration: moduleInputDecoration('Material / Asset Description *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: qtyCtrl, decoration: moduleInputDecoration('Qty / Volume *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null)),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: authByCtrl, decoration: moduleInputDecoration('Authorized By *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final id = 'MOUT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                        final item = {
                          'id': id,
                          'gatePassNo': passCtrl.text.trim().isEmpty ? id : passCtrl.text.trim(),
                          'passType': passType,
                          'receiver': receiverCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'quantity': qtyCtrl.text.trim(),
                          'authorizedBy': authByCtrl.text.trim(),
                          'status': 'Dispatched',
                          'issuedAt': DateTime.now().toIso8601String(),
                        };
                        final updated = [item, ..._items];
                        setState(() => _items = updated);
                        await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.materialOutward, updated);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('Issue Outward Gate Pass'),
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
          (m['gatePassNo'] ?? m['id'] ?? '').toString().toLowerCase().contains(q) ||
          (m['receiver'] ?? '').toString().toLowerCase().contains(q) ||
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
                    Text('Material Outward & RGP Gate', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('Control CBG cascade dispatches, FOM & returnable gate passes', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              if (widget.screenPerm.canCreate)
                ElevatedButton.icon(
                  onPressed: _openIssueModal,
                  icon: const Icon(Icons.outbox_outlined, size: 15),
                  label: const Text('Issue RGP'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ModuleKpiGrid(items: [
            ModuleKpiItem(label: 'Outward Gate Passes', value: '${_items.length}', subtext: 'Authorized dispatches', accentColor: const Color(0xFFEA580C), icon: Icons.outbox_outlined),
            ModuleKpiItem(label: 'Returnable Assets', value: '${_items.where((x) => (x['passType'] ?? '').toString().contains('Returnable')).length}', subtext: 'Tracked for return', accentColor: const Color(0xFF2563EB), icon: Icons.sync_outlined),
          ]),
          const SizedBox(height: 12),
          TextField(decoration: moduleInputDecoration('Search pass no, receiver, description...'), onChanged: (v) => setState(() => _searchTerm = v)),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(icon: Icons.outbox_outlined, title: 'No Outward Gate Passes', subtitle: 'Issue returnable or non-returnable material exit authorization.')
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
                          ModuleTag(text: '${m['gatePassNo'] ?? m['id']}', bgColor: const Color(0xFFFFF7ED), textColor: const Color(0xFFC2410C)),
                          const Spacer(),
                          ModuleTag(text: '${m['status'] ?? 'Dispatched'}', bgColor: const Color(0xFFD1FAE5), textColor: const Color(0xFF059669)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${m['description'] ?? '-'} (${m['quantity'] ?? '-'})', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800)),
                      Text('Receiver: ${m['receiver'] ?? '-'} • ${m['passType'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                      Text('Authorized By: ${m['authorizedBy'] ?? '-'}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
