import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/rbac_service.dart';
import '../../services/supply_chain_api_service.dart';
import '../../widgets/module_ui_widgets.dart';

class ProcurementManagementScreen extends StatefulWidget {
  final String initialTab;

  const ProcurementManagementScreen({super.key, this.initialTab = 'pos'});

  @override
  State<ProcurementManagementScreen> createState() => _ProcurementManagementScreenState();
}

class _ProcurementManagementScreenState extends State<ProcurementManagementScreen> {
  static const List<ModuleSubmoduleItem> _tabs = [
    ModuleSubmoduleItem(key: 'pos', title: 'Procurement & PO', shortLabel: 'Purchase Orders', icon: Icons.shopping_cart_outlined),
    ModuleSubmoduleItem(key: 'requisitions', title: 'Procurement & PO', shortLabel: 'Requisitions (PR)', icon: Icons.fact_check_outlined),
    ModuleSubmoduleItem(key: 'vendors', title: 'Procurement & PO', shortLabel: 'Suppliers', icon: Icons.business_outlined),
    ModuleSubmoduleItem(key: 'deliveries', title: 'Procurement & PO', shortLabel: 'GRN & Deliveries', icon: Icons.local_shipping_outlined),
  ];

  static final NumberFormat _inrFmt = NumberFormat('#,##,##0', 'en_IN');

  late String _activeTab;
  ScreenPermission _perm = ScreenPermission.full;
  bool _isLoadingPerm = true;
  bool _isLoading = true;

  List<Map<String, dynamic>> _plants = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _requisitions = [];
  List<Map<String, dynamic>> _purchaseOrders = [];
  List<Map<String, dynamic>> _deliveryNotes = [];

  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _activeTab = _tabs.any((t) => t.key == widget.initialTab) ? widget.initialTab : 'pos';
    _initLoad();
  }

  Future<void> _initLoad() async {
    final perm = await RbacService.getScreenPermission('PROCUREMENT_MANAGEMENT');
    if (mounted) {
      setState(() {
        _perm = perm;
        _isLoadingPerm = false;
      });
    }
    if (perm.canView) {
      await _loadAllData();
    }
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      SupplyChainApiService.getProcurementSuppliers(),
      SupplyChainApiService.getPurchaseRequisitions(),
      SupplyChainApiService.getPurchaseOrders(),
      SupplyChainApiService.getDeliveryNotes(),
      SupplyChainApiService.getPlants(),
    ]);
    if (mounted) {
      setState(() {
        _suppliers = results[0];
        _requisitions = results[1];
        _purchaseOrders = results[2];
        _deliveryNotes = results[3];
        _plants = results[4];
        _isLoading = false;
      });
    }
  }

  double _num(dynamic v) => double.tryParse((v ?? '0').toString()) ?? 0;

  String _fmtInr(dynamic v) => '₹${_inrFmt.format(_num(v).round())}';

  List<String> _plantOptions() {
    final names = _plants
        .map((p) => (p['plantNm'] ?? p['name'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (names.isEmpty) names.add('Plant 1 - Hyderabad East CBG');
    return names;
  }

  List<String> _supplierOptions() {
    final names = _suppliers
        .map((s) => (s['name'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (names.isEmpty) names.add('Agritech Agro Bio Solutions Ltd');
    return names;
  }

  Future<bool> _confirmDelete(String label) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete $label?'),
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
    return res == true;
  }

  void _viewSupplierDetails(Map<String, dynamic> s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.business_outlined, color: Color(0xFF7C3AED), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s['name']?.toString() ?? 'Supplier Details',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Strategic Tier', s['tier']?.toString() ?? '—'),
              _detailRow('Supply Category', s['category']?.toString() ?? '—'),
              _detailRow('GSTIN Number', s['gstin']?.toString() ?? '—'),
              _detailRow('Contact Person', s['contactPerson']?.toString() ?? '—'),
              _detailRow('Phone Number', s['phone']?.toString() ?? '—'),
              _detailRow('Email Address', s['email']?.toString() ?? '—'),
              _detailRow('Payment Terms', s['paymentTerms']?.toString() ?? '—'),
              _detailRow('Account Status', s['status']?.toString() ?? 'Active'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 1),
          Text(value, style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A), fontWeight: FontWeight.w600)),
          const Divider(height: 10, color: Color(0xFFF1F5F9)),
        ],
      ),
    );
  }

  String _generateNextPoNumber() {
    final currentYear = DateTime.now().year;
    final prefix = 'PO-$currentYear-';
    int maxSeq = 0;
    for (final po in _purchaseOrders) {
      final poNum = (po['poNumber'] ?? '').toString().trim();
      if (poNum.startsWith(prefix)) {
        final rest = poNum.substring(prefix.length);
        final numPart = int.tryParse(rest);
        if (numPart != null && numPart > maxSeq) {
          maxSeq = numPart;
        }
      }
    }
    final nextSeq = (maxSeq + 1).toString().padLeft(4, '0');
    return '$prefix$nextSeq';
  }

  String _generateNextGrnNumber() {
    final currentYear = DateTime.now().year;
    final prefix = 'GRN-$currentYear-';
    int maxSeq = 0;
    for (final g in _deliveryNotes) {
      final num = (g['grnNumber'] ?? '').toString().trim();
      if (num.startsWith(prefix)) {
        final rest = num.substring(prefix.length).replaceAll(RegExp(r'[^0-9]'), '');
        final val = int.tryParse(rest);
        if (val != null && val > maxSeq) {
          maxSeq = val;
        }
      }
    }
    return '$prefix${(maxSeq + 1).toString().padLeft(4, '0')}';
  }

  void _viewGrnDetails(Map<String, dynamic> g) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.local_shipping_outlined, color: Color(0xFFD97706), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                g['grnNumber']?.toString() ?? 'GRN Details',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('PO Reference', g['poNumber']?.toString() ?? '—'),
              _detailRow('Supplier / Consignor', g['supplierName']?.toString() ?? '—'),
              _detailRow('Logistics Transporter', g['transporter']?.toString() ?? '—'),
              _detailRow('Vehicle Registration No', g['vehicleNo']?.toString() ?? '—'),
              _detailRow('E-Way Bill Number', g['eWayBill']?.toString() ?? '—'),
              _detailRow('Received Date', _formatToDDMMYYYY(g['receivedDate']?.toString())),
              _detailRow('Receiving Zone', g['receivingZone']?.toString() ?? 'Raw Feedstock Silo Yard'),
              _detailRow('Ordered Qty', '${g['orderedQty'] ?? 0} MT'),
              _detailRow('Actual Inward Received', '${g['receivedQty'] ?? 0} MT'),
              _detailRow('QC Inspection Status', g['inspectionStatus']?.toString() ?? 'Under Inspection'),
              if (g['remarks'] != null && g['remarks'].toString().isNotEmpty)
                _detailRow('Remarks / QC Notes', g['remarks'].toString()),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatToDDMMYYYY(dynamic val) {
    if (val == null) return '';
    final str = val.toString().trim();
    if (str.isEmpty) return '';
    if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(str)) return str;
    final isoMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(str);
    if (isoMatch != null) {
      return '${isoMatch.group(3)}-${isoMatch.group(2)}-${isoMatch.group(1)}';
    }
    try {
      final dt = DateTime.parse(str);
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      return '$d-$m-$y';
    } catch (_) {
      return str;
    }
  }

  DateTime _parseDateString(String val) {
    try {
      final parts = val.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        } else if (parts[2].length == 4) {
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      }
      return DateTime.parse(val);
    } catch (_) {
      return DateTime.now();
    }
  }

  // --- CREATE PURCHASE ORDER ---
  void _openCreatePoModal() {
    final nextPoNum = _generateNextPoNumber();
    final supList = _supplierOptions();
    final plantList = _plantOptions();
    final formKey = GlobalKey<FormState>();

    final poNumCtrl = TextEditingController(text: nextPoNum);
    String supplierName = supList.first;
    String plantFacility = plantList.first;
    final now = DateTime.now();
    final in14Days = now.add(const Duration(days: 14));
    final orderDateCtrl = TextEditingController(
      text: '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}',
    );
    final deliveryDateCtrl = TextEditingController(
      text: '${in14Days.day.toString().padLeft(2, '0')}-${in14Days.month.toString().padLeft(2, '0')}-${in14Days.year}',
    );
    String paymentTerms = 'Net 30 Days';
    final addressCtrl = TextEditingController(text: 'BioNova Industrial Bio-Energy Complex, Site Bay 4');

    final List<Map<String, dynamic>> items = [
      {
        'description': 'Energy Napier Grass Feedstock Consignment',
        'sku': 'SKU-AGRI-01',
        'qty': 100.0,
        'unit': 'MT',
        'unitPrice': 2200.0,
        'taxRate': 5.0,
        'lineTotal': 231000.0,
      }
    ];

    void recalcRow(Map<String, dynamic> row) {
      final qty = _num(row['qty']);
      final price = _num(row['unitPrice']);
      final tax = _num(row['taxRate']);
      final sub = qty * price;
      row['lineTotal'] = (sub + (sub * tax) / 100).roundToDouble();
    }

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_cart_outlined, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Generate Enterprise Purchase Order', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: poNumCtrl,
                    readOnly: true,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                    decoration: moduleInputDecoration('PO Number * (Auto-generated)').copyWith(
                      prefixIcon: const Icon(Icons.lock_outline, size: 18, color: Color(0xFF64748B)),
                      fillColor: const Color(0xFFF1F5F9),
                      filled: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: supplierName,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Supplier / Vendor *'),
                    items: supList.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setModalState(() => supplierName = v ?? supplierName),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: plantFacility,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Receiving Plant Facility *'),
                    items: plantList.map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setModalState(() => plantFacility = v ?? plantFacility),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: orderDateCtrl,
                          readOnly: true,
                          decoration: moduleInputDecoration('PO Order Date').copyWith(
                            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF2563EB)),
                          ),
                          onTap: () async {
                            final initial = _parseDateString(orderDateCtrl.text);
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: initial,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setModalState(() {
                                final d = picked.day.toString().padLeft(2, '0');
                                final m = picked.month.toString().padLeft(2, '0');
                                final y = picked.year.toString();
                                orderDateCtrl.text = '$d-$m-$y';
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: deliveryDateCtrl,
                          readOnly: true,
                          decoration: moduleInputDecoration('Expected Delivery *').copyWith(
                            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF2563EB)),
                          ),
                          onTap: () async {
                            final initial = _parseDateString(deliveryDateCtrl.text);
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: initial,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setModalState(() {
                                final d = picked.day.toString().padLeft(2, '0');
                                final m = picked.month.toString().padLeft(2, '0');
                                final y = picked.year.toString();
                                deliveryDateCtrl.text = '$d-$m-$y';
                              });
                            }
                          },
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: paymentTerms,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Payment Terms'),
                    items: const [
                      DropdownMenuItem(value: 'Immediate on Delivery', child: Text('Immediate on Delivery')),
                      DropdownMenuItem(value: 'Net 15 Days', child: Text('Net 15 Days')),
                      DropdownMenuItem(value: 'Net 30 Days', child: Text('Net 30 Days')),
                      DropdownMenuItem(value: 'Net 45 Days', child: Text('Net 45 Days')),
                      DropdownMenuItem(value: 'Advance 20% + Balance on GRN', child: Text('Advance 20% + Balance on GRN')),
                    ],
                    onChanged: (v) => setModalState(() => paymentTerms = v ?? paymentTerms),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: addressCtrl, decoration: moduleInputDecoration('Delivery Terms & Shipping Address')),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PO Line Items (${items.length})', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                      TextButton.icon(
                        onPressed: () => setModalState(() {
                          items.add({'description': '', 'sku': '', 'qty': 1.0, 'unit': 'MT', 'unitPrice': 0.0, 'taxRate': 18.0, 'lineTotal': 0.0});
                        }),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Row'),
                      ),
                    ],
                  ),
                  ...items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final it = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: it['description'].toString(),
                                  decoration: moduleInputDecoration('Item Description *'),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                  onChanged: (v) => it['description'] = v,
                                ),
                              ),
                              if (items.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 18),
                                  onPressed: () => setModalState(() => items.removeAt(idx)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: it['sku'].toString(),
                                  decoration: moduleInputDecoration('SKU'),
                                  onChanged: (v) => it['sku'] = v,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: it['qty'].toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: moduleInputDecoration('Qty'),
                                  onChanged: (v) => setModalState(() {
                                    it['qty'] = double.tryParse(v) ?? 0;
                                    recalcRow(it);
                                  }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: it['unit'].toString(),
                                  decoration: moduleInputDecoration('Unit'),
                                  items: const [
                                    DropdownMenuItem(value: 'MT', child: Text('MT')),
                                    DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                                    DropdownMenuItem(value: 'Ltr', child: Text('Ltr')),
                                    DropdownMenuItem(value: 'Nos', child: Text('Nos')),
                                    DropdownMenuItem(value: 'Meters', child: Text('Meters')),
                                    DropdownMenuItem(value: 'Sets', child: Text('Sets')),
                                  ],
                                  onChanged: (v) => setModalState(() => it['unit'] = v ?? 'MT'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: it['unitPrice'].toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: moduleInputDecoration('Rate (₹)'),
                                  onChanged: (v) => setModalState(() {
                                    it['unitPrice'] = double.tryParse(v) ?? 0;
                                    recalcRow(it);
                                  }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _num(it['taxRate']).round().toString(),
                                  decoration: moduleInputDecoration('GST %'),
                                  items: const [
                                    DropdownMenuItem(value: '0', child: Text('0%')),
                                    DropdownMenuItem(value: '5', child: Text('5%')),
                                    DropdownMenuItem(value: '12', child: Text('12%')),
                                    DropdownMenuItem(value: '18', child: Text('18%')),
                                    DropdownMenuItem(value: '28', child: Text('28%')),
                                  ],
                                  onChanged: (v) => setModalState(() {
                                    it['taxRate'] = double.tryParse(v ?? '0') ?? 0;
                                    recalcRow(it);
                                  }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(_fmtInr(it['lineTotal']), style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final subtotal = items.fold<double>(0, (s, it) => s + _num(it['qty']) * _num(it['unitPrice']));
                        final taxTotal = items.fold<double>(0, (s, it) => s + _num(it['qty']) * _num(it['unitPrice']) * (_num(it['taxRate']) / 100.0));
                        final totalAmount = (subtotal + taxTotal).round();
                        await SupplyChainApiService.savePurchaseOrder({
                          'poNumber': poNumCtrl.text.trim(),
                          'supplierName': supplierName,
                          'plantFacility': plantFacility,
                          'orderDate': orderDateCtrl.text.trim(),
                          'deliveryDate': deliveryDateCtrl.text.trim(),
                          'paymentTerms': paymentTerms,
                          'deliveryTerms': 'FOR Destination Plant Site',
                          'shippingAddress': addressCtrl.text.trim(),
                          'items': items,
                          'subtotal': subtotal,
                          'taxTotal': taxTotal,
                          'totalAmount': totalAmount,
                          'status': 'Issued',
                        });
                        await _loadAllData();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.save_outlined, size: 16),
                      label: const Text('Save & Issue Purchase Order'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
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

  // --- CREATE PURCHASE REQUISITION ---
  void _openCreatePrModal() {
    final nextSeq = (_requisitions.length + 1).toString().padLeft(4, '0');
    final plantList = _plantOptions();
    final formKey = GlobalKey<FormState>();

    final prNumCtrl = TextEditingController(text: 'PR-2026-$nextSeq');
    String department = 'Biogas Operations';
    String plantFacility = plantList.first;
    String priority = 'Normal';
    final justCtrl = TextEditingController(text: 'Critical raw substrate procurement for anaerobic digester continuous feeding.');

    final List<Map<String, dynamic>> items = [
      {'itemName': 'Silage Bacterial Inoculant Enzyme', 'qty': 25, 'uom': 'Kg', 'estCost': 45000.0}
    ];

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fact_check_outlined, color: Color(0xFF059669)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Raise Purchase Requisition (PR)', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: prNumCtrl,
                    decoration: moduleInputDecoration('PR Requisition # *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: department,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Requesting Department *'),
                    items: const [
                      DropdownMenuItem(value: 'Biogas Operations', child: Text('Biogas Operations')),
                      DropdownMenuItem(value: 'Mechanical Maintenance', child: Text('Mechanical Maintenance')),
                      DropdownMenuItem(value: 'Agri Logistics', child: Text('Agri Logistics')),
                      DropdownMenuItem(value: 'Civil Infrastructure', child: Text('Civil Infrastructure')),
                      DropdownMenuItem(value: 'Quality Assurance & Lab', child: Text('Quality Assurance & Lab')),
                    ],
                    onChanged: (v) => setModalState(() => department = v ?? department),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: plantFacility,
                          isExpanded: true,
                          decoration: moduleInputDecoration('Target Facility'),
                          items: plantList.map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setModalState(() => plantFacility = v ?? plantFacility),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: priority,
                          decoration: moduleInputDecoration('Priority'),
                          items: const [
                            DropdownMenuItem(value: 'Low', child: Text('Low')),
                            DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                            DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                          ],
                          onChanged: (v) => setModalState(() => priority = v ?? priority),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: justCtrl,
                    maxLines: 2,
                    decoration: moduleInputDecoration('Business Justification *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Required Materials (${items.length})', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      TextButton.icon(
                        onPressed: () => setModalState(() => items.add({'itemName': '', 'qty': 1, 'uom': 'MT', 'estCost': 0.0})),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Row'),
                      ),
                    ],
                  ),
                  ...items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final it = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: it['itemName'].toString(),
                                  decoration: moduleInputDecoration('Item Name *'),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                  onChanged: (v) => it['itemName'] = v,
                                ),
                              ),
                              if (items.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 18),
                                  onPressed: () => setModalState(() => items.removeAt(idx)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: it['qty'].toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: moduleInputDecoration('Qty'),
                                  onChanged: (v) => it['qty'] = double.tryParse(v) ?? 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: it['uom'].toString(),
                                  decoration: moduleInputDecoration('UOM'),
                                  onChanged: (v) => it['uom'] = v,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: it['estCost'].toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: moduleInputDecoration('Est Cost (₹)'),
                                  onChanged: (v) => it['estCost'] = double.tryParse(v) ?? 0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final totalEst = items.fold<double>(0, (s, it) => s + _num(it['estCost']));
                        await SupplyChainApiService.savePurchaseRequisition({
                          'prNumber': prNumCtrl.text.trim(),
                          'department': department,
                          'plantFacility': plantFacility,
                          'priority': priority,
                          'requiredDate': DateTime.now().add(const Duration(days: 7)).toIso8601String().split('T').first,
                          'justification': justCtrl.text.trim(),
                          'items': items,
                          'totalEstCost': totalEst,
                          'status': 'Pending Approval',
                        });
                        await _loadAllData();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('Submit Requisition for Approval'),
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

  // --- CREATE / EDIT SUPPLIER ---
  void _openCreateSupplierModal([Map<String, dynamic>? editing]) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: editing != null ? (editing['name'] ?? '').toString() : '');
    String tier = (editing != null && editing['tier'] != null) ? editing['tier'].toString() : 'Tier 1 - Strategic EPC / OEM';
    String category = (editing != null && editing['category'] != null) ? editing['category'].toString() : 'Biomass Feedstock & Silage';
    final gstinCtrl = TextEditingController(text: editing != null ? (editing['gstin'] ?? '').toString() : '');
    final contactCtrl = TextEditingController(text: editing != null ? (editing['contactPerson'] ?? '').toString() : '');
    final phoneCtrl = TextEditingController(text: editing != null ? (editing['phone'] ?? '').toString() : '');
    final emailCtrl = TextEditingController(text: editing != null ? (editing['email'] ?? '').toString() : '');
    String paymentTerms = (editing != null && editing['paymentTerms'] != null) ? editing['paymentTerms'].toString() : 'Net 30 Days';

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
                      const Icon(Icons.business_outlined, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(editing != null ? 'Edit Vendor / Supplier' : 'Onboard Vendor / Supplier', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: moduleInputDecoration('Vendor / Legal Entity Name *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: tier,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Vendor Strategic Tier'),
                    items: const [
                      DropdownMenuItem(value: 'Tier 1 - Strategic EPC / OEM', child: Text('Tier 1 - Strategic EPC / OEM')),
                      DropdownMenuItem(value: 'Tier 2 - Equipment & Spares', child: Text('Tier 2 - Equipment & Spares')),
                      DropdownMenuItem(value: 'Tier 3 - Feedstock & Consumables', child: Text('Tier 3 - Feedstock & Consumables')),
                    ],
                    onChanged: (v) => setModalState(() => tier = v ?? tier),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Supply Category'),
                    items: const [
                      DropdownMenuItem(value: 'Biomass Feedstock & Silage', child: Text('Biomass Feedstock & Silage')),
                      DropdownMenuItem(value: 'Plant Construction & Civil', child: Text('Plant Construction & Civil')),
                      DropdownMenuItem(value: 'Piping & Valves (P&ID)', child: Text('Piping & Valves (P&ID)')),
                      DropdownMenuItem(value: 'Gas Upgradation & Compressors', child: Text('Gas Upgradation & Compressors')),
                      DropdownMenuItem(value: 'Chemicals, Enzymes & Consumables', child: Text('Chemicals, Enzymes & Consumables')),
                    ],
                    onChanged: (v) => setModalState(() => category = v ?? category),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: gstinCtrl,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(15),
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    ],
                    decoration: moduleInputDecoration('GSTIN Number *', hint: '36AABCB1234F1Z8'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final reg = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                      if (!reg.hasMatch(v.trim().toUpperCase())) {
                        return 'Invalid GSTIN (15 chars, e.g. 36AABCB1234F1Z8)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: contactCtrl,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s.]')),
                          ],
                          decoration: moduleInputDecoration('Contact Person'),
                          validator: (v) {
                            if (v != null && RegExp(r'\d').hasMatch(v)) {
                              return 'Names only (no numbers)';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: moduleInputDecoration('Phone (Starts with 6-9)'),
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) {
                                return '10 digits starting with 6, 7, 8, or 9';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: moduleInputDecoration('Email Address'),
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) {
                          return 'Enter valid email (@gmail.com or business email)';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: paymentTerms,
                    decoration: moduleInputDecoration('Default Payment Terms'),
                    items: const [
                      DropdownMenuItem(value: 'Net 30 Days', child: Text('Net 30 Days')),
                      DropdownMenuItem(value: 'Net 45 Days', child: Text('Net 45 Days')),
                      DropdownMenuItem(value: 'Advance 10% + Net 30', child: Text('Advance 10% + Net 30')),
                    ],
                    onChanged: (v) => setModalState(() => paymentTerms = v ?? paymentTerms),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        await SupplyChainApiService.saveProcurementSupplier({
                          if (editing != null && editing['id'] != null) 'id': editing['id'],
                          'name': nameCtrl.text.trim(),
                          'tier': tier,
                          'category': category,
                          'gstin': gstinCtrl.text.trim().toUpperCase(),
                          'contactPerson': contactCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'paymentTerms': paymentTerms,
                          'rating': editing != null ? (editing['rating'] ?? 5) : 5,
                          'status': editing != null ? (editing['status'] ?? 'Active') : 'Active',
                        });
                        await _loadAllData();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: Text(editing != null ? 'Update Supplier Record' : 'Save Supplier Record'),
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

  // --- CREATE / EDIT DELIVERY NOTE (GRN) ---
  void _openCreateGrnModal([Map<String, dynamic>? editing]) {
    final formKey = GlobalKey<FormState>();
    final poList = _purchaseOrders.map((p) => (p['poNumber'] ?? '').toString()).where((s) => s.isNotEmpty).toList();
    if (poList.isEmpty) poList.add('PO-2026-0001');

    final grnNumber = editing != null ? (editing['grnNumber'] ?? '').toString() : _generateNextGrnNumber();
    final grnCtrl = TextEditingController(text: grnNumber);
    String poRef = editing != null ? (editing['poNumber'] ?? poList.first).toString() : poList.first;
    final supCtrl = TextEditingController(text: editing != null ? (editing['supplierName'] ?? '').toString() : (_suppliers.isNotEmpty ? (_suppliers.first['name'] ?? '').toString() : 'Atirath Bio Supplies Ltd'));
    final transCtrl = TextEditingController(text: editing != null ? (editing['transporter'] ?? '').toString() : 'Gati-KWE Logistics Fleet');
    final vehCtrl = TextEditingController(text: editing != null ? (editing['vehicleNo'] ?? '').toString() : '');
    final ewayCtrl = TextEditingController(text: editing != null ? (editing['eWayBill'] ?? '').toString() : '');
    final ordCtrl = TextEditingController(text: editing != null ? (editing['orderedQty']?.toString() ?? '100') : '100');
    final dispCtrl = TextEditingController(text: editing != null ? (editing['dispatchedQty']?.toString() ?? '100') : '100');
    final recCtrl = TextEditingController(text: editing != null ? (editing['receivedQty']?.toString() ?? '98.5') : '98.5');
    String qcStatus = editing != null ? (editing['inspectionStatus'] ?? 'Passed QC - Stock Updated').toString() : 'Passed QC - Stock Updated';

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
                      const Icon(Icons.local_shipping_outlined, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          editing != null ? 'Edit Delivery Note (GRN)' : 'Record Inward Delivery Note (GRN)',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: grnCtrl,
                    readOnly: true,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    decoration: moduleInputDecoration('GRN Note # (Auto-generated, Locked)').copyWith(
                      prefixIcon: const Icon(Icons.lock_outline, size: 18, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: poRef,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Reference Purchase Order'),
                    items: poList.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) {
                      setModalState(() {
                        poRef = v ?? poRef;
                        final selPo = _purchaseOrders.firstWhere((p) => (p['poNumber'] ?? '').toString() == poRef, orElse: () => {});
                        if (selPo.isNotEmpty && selPo['supplierName'] != null) {
                          supCtrl.text = selPo['supplierName'].toString();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: supCtrl, decoration: moduleInputDecoration('Supplier / Vendor Name')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: transCtrl, decoration: moduleInputDecoration('Transporter'))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: vehCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: moduleInputDecoration('Vehicle Reg No *', hint: 'TS 08 UB 7712'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final reg = RegExp(r'^[A-Z]{2}[ -]?[0-9]{1,2}[ -]?[A-Z]{1,3}[ -]?[0-9]{4}$');
                            if (!reg.hasMatch(v.trim().toUpperCase())) {
                              return 'Format: TS 08 UB 7712';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: ewayCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                      LengthLimitingTextInputFormatter(16),
                    ],
                    decoration: moduleInputDecoration('E-Way Bill Number * (12 digits)', hint: '2418-9921-0842'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (RegExp(r'[a-zA-Z]').hasMatch(v)) return 'Alphabets not allowed';
                      final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                      if (digits.length != 12) return 'Must be 12 digits (e.g. 2418-9921-0842)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: ordCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Ordered (MT)'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(controller: dispCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Dispatched (MT)'))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: recCtrl,
                          keyboardType: TextInputType.number,
                          decoration: moduleInputDecoration('Received (MT) *'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: qcStatus,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Inspection Quality Status'),
                    items: const [
                      DropdownMenuItem(value: 'Passed QC - Stock Updated', child: Text('Passed QC - Stock Updated')),
                      DropdownMenuItem(value: 'Under Inspection', child: Text('Under Inspection')),
                      DropdownMenuItem(value: 'Discrepancy / Weight Shortage Flagged', child: Text('Discrepancy / Weight Shortage Flagged')),
                      DropdownMenuItem(value: 'Rejected Off-Spec', child: Text('Rejected Off-Spec')),
                    ],
                    onChanged: (v) => setModalState(() => qcStatus = v ?? qcStatus),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final rec = double.tryParse(recCtrl.text.trim()) ?? 0;
                        await SupplyChainApiService.saveDeliveryNote({
                          if (editing != null && editing['id'] != null) 'id': editing['id'],
                          'grnNumber': grnCtrl.text.trim(),
                          'poNumber': poRef,
                          'supplierName': supCtrl.text.trim(),
                          'transporter': transCtrl.text.trim(),
                          'vehicleNo': vehCtrl.text.trim().toUpperCase(),
                          'eWayBill': ewayCtrl.text.trim(),
                          'receivedDate': editing != null ? (editing['receivedDate'] ?? DateTime.now().toIso8601String().split('T').first) : DateTime.now().toIso8601String().split('T').first,
                          'receivingZone': 'Raw Feedstock Silo Yard',
                          'orderedQty': double.tryParse(ordCtrl.text.trim()) ?? 0,
                          'dispatchedQty': double.tryParse(dispCtrl.text.trim()) ?? 0,
                          'receivedQty': rec,
                          'acceptedQty': rec,
                          'rejectedQty': 0,
                          'inspectionStatus': qcStatus,
                        });
                        await _loadAllData();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: Text(editing != null ? 'Update Delivery Note' : 'Confirm Receipt & Update Inventory'),
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

  void _openPoVoucher(Map<String, dynamic> po) {
    final items = (po['items'] is List) ? (po['items'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
    final buf = StringBuffer('BIONOVA ENERGY PRIVATE LIMITED - PURCHASE ORDER\n');
    buf.writeln('PO Number: ${po['poNumber']} | Order Date: ${_formatToDDMMYYYY(po['orderDate'])}');
    buf.writeln('Vendor: ${po['supplierName']} | Plant: ${po['plantFacility']}');
    buf.writeln('Payment Terms: ${po['paymentTerms']} | Delivery: ${po['deliveryTerms']}');
    for (final it in items) {
      buf.writeln('- ${it['description']}: ${it['qty']} ${it['unit']} x ${_fmtInr(it['unitPrice'])} (GST ${it['taxRate']}%) = ${_fmtInr(it['lineTotal'])}');
    }
    buf.writeln('Grand Total: ${_fmtInr(po['totalAmount'])}');

    showPrintablePreviewDialog(
      context,
      title: 'Purchase Order Voucher • ${po['poNumber']}',
      copyText: buf.toString(),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BIONOVA ENERGY PRIVATE LIMITED', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
          Text('Corporate Procurement & Materials Management Division', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
          const Divider(),
          Text('PO Reference: ${po['poNumber']}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
          Text('Vendor: ${po['supplierName']}'),
          Text('Destination: ${po['plantFacility']}'),
          Text('Order Date: ${_formatToDDMMYYYY(po['orderDate'])} | Payment: ${po['paymentTerms']}'),
          const Divider(),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${it['description']} (${it['qty']} ${it['unit']})', style: GoogleFonts.inter(fontSize: 12))),
                    Text(_fmtInr(it['lineTotal']), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              )),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total:', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
              Text(_fmtInr(po['totalAmount']), style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: const Color(0xFF0F172A))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    final totalPoSpend = _purchaseOrders.fold<double>(0, (s, p) => s + _num(p['totalAmount']));
    final pendingPrCount = _requisitions.where((r) => r['status'] == 'Pending Approval').length;
    final activeSuppliersCount = _suppliers.where((s) => s['status'] == 'Active').length;

    final filteredPos = _purchaseOrders.where((po) {
      final q = _searchQuery.trim().toLowerCase();
      final matchSearch = q.isEmpty ||
          (po['poNumber'] ?? '').toString().toLowerCase().contains(q) ||
          (po['supplierName'] ?? '').toString().toLowerCase().contains(q) ||
          (po['plantFacility'] ?? '').toString().toLowerCase().contains(q);
      final matchStatus = _statusFilter == 'All' || po['status'] == _statusFilter;
      return matchSearch && matchStatus;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Procurement & PO Management', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('Multi-tier supplier contracts, PR approvals, POs & GRN receipts', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              if (_perm.canCreate)
                ElevatedButton.icon(
                  onPressed: _activeTab == 'pos'
                      ? _openCreatePoModal
                      : _activeTab == 'requisitions'
                          ? _openCreatePrModal
                          : _activeTab == 'vendors'
                              ? _openCreateSupplierModal
                              : _openCreateGrnModal,
                  icon: const Icon(Icons.add, size: 15),
                  label: Text(
                    _activeTab == 'pos'
                        ? 'New PO'
                        : _activeTab == 'requisitions'
                            ? 'Raise PR'
                            : _activeTab == 'vendors'
                                ? 'Supplier'
                                : 'Log GRN',
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ModuleKpiGrid(items: [
            ModuleKpiItem(label: 'Total Active PO Value', value: _fmtInr(totalPoSpend), subtext: '${_purchaseOrders.length} orders', accentColor: const Color(0xFF2563EB), icon: Icons.currency_rupee),
            ModuleKpiItem(label: 'Approved Vendors', value: '$activeSuppliersCount', subtext: '${_suppliers.length} total registered', accentColor: const Color(0xFF16A34A), icon: Icons.business_outlined),
            ModuleKpiItem(label: 'Pending PR Approvals', value: '$pendingPrCount', subtext: '${_requisitions.length} requisitions', accentColor: const Color(0xFFD97706), icon: Icons.schedule_outlined),
            ModuleKpiItem(label: 'Inbound GRN Receipts', value: '${_deliveryNotes.length}', subtext: 'Delivery notes logged', accentColor: const Color(0xFF9333EA), icon: Icons.inventory_outlined),
          ]),
          const SizedBox(height: 14),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_activeTab == 'pos') ...[
            Row(
              children: [
                Expanded(
                  child: Text('Active Purchase Orders (${filteredPos.length})', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: const Icon(Icons.download_outlined, color: Color(0xFF2563EB)),
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'purchase_orders.csv',
                    headers: const ['PO Number', 'Supplier', 'Plant', 'Order Date', 'Expected Delivery', 'Total Amount', 'Status'],
                    rows: _purchaseOrders
                        .map((p) => [p['poNumber'] ?? '', p['supplierName'] ?? '', p['plantFacility'] ?? '', _formatToDDMMYYYY(p['orderDate']), _formatToDDMMYYYY(p['deliveryDate']), p['totalAmount'] ?? 0, p['status'] ?? ''])
                        .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: moduleInputDecoration('Search PO #, supplier, facility...'),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('po-st-$_statusFilter'),
                    initialValue: _statusFilter,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Status'),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                      DropdownMenuItem(value: 'Issued', child: Text('Issued')),
                      DropdownMenuItem(value: 'Partially Delivered', child: Text('Partially Delivered')),
                      DropdownMenuItem(value: 'Fully Delivered', child: Text('Fully Delivered')),
                      DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                    ],
                    onChanged: (v) => setState(() => _statusFilter = v ?? 'All'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (filteredPos.isEmpty)
              const ModuleEmptyState(icon: Icons.shopping_cart_outlined, title: 'No Purchase Orders Found', subtitle: 'Generate your first PO to manage vendor commitments.')
            else
              ...filteredPos.map((po) {
                final st = (po['status'] ?? 'Issued').toString();
                final itemsLen = (po['items'] is List) ? (po['items'] as List).length : 1;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ModuleTag(text: '${po['poNumber'] ?? ''}', bgColor: const Color(0xFFEFF6FF), textColor: const Color(0xFF1D4ED8)),
                          const Spacer(),
                          ModuleTag(
                            text: st,
                            bgColor: st == 'Fully Delivered' ? const Color(0xFFD1FAE5) : (st == 'Issued' ? const Color(0xFFDBEAFE) : const Color(0xFFFEF3C7)),
                            textColor: st == 'Fully Delivered' ? const Color(0xFF059669) : (st == 'Issued' ? const Color(0xFF1D4ED8) : const Color(0xFFD97706)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${po['supplierName'] ?? '-'}', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800)),
                      Text('${po['plantFacility'] ?? '-'} • $itemsLen item(s)', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                      Text('Order: ${_formatToDDMMYYYY(po['orderDate'])} | ETA: ${_formatToDDMMYYYY(po['deliveryDate'])}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                      const SizedBox(height: 6),
                      Text('Total: ${_fmtInr(po['totalAmount'])}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                      const Divider(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(onPressed: () => _openPoVoucher(po), icon: const Icon(Icons.print_outlined, size: 16), label: const Text('Voucher')),
                          if (_perm.canDelete)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 19),
                              onPressed: () async {
                                if (await _confirmDelete('${po['poNumber']}')) {
                                  await SupplyChainApiService.deletePurchaseOrder(po['id']);
                                  await _loadAllData();
                                }
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ] else if (_activeTab == 'requisitions') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Purchase Requisitions (${_requisitions.length})', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.download_outlined, color: Color(0xFF2563EB)),
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'purchase_requisitions.csv',
                    headers: const ['PR Number', 'Department', 'Plant', 'Priority', 'Est Cost', 'Status'],
                    rows: _requisitions.map((r) => [r['prNumber'] ?? '', r['department'] ?? '', r['plantFacility'] ?? '', r['priority'] ?? '', r['totalEstCost'] ?? 0, r['status'] ?? '']).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_requisitions.isEmpty)
              const ModuleEmptyState(icon: Icons.fact_check_outlined, title: 'No Requisitions Found', subtitle: 'Raise a PR to initiate the approval cycle.')
            else
              ..._requisitions.map((pr) {
                final st = (pr['status'] ?? 'Pending Approval').toString();
                final prio = (pr['priority'] ?? 'Normal').toString();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ModuleTag(text: '${pr['prNumber'] ?? ''}', bgColor: const Color(0xFFF1F5F9), textColor: const Color(0xFF0F172A)),
                          const SizedBox(width: 6),
                          ModuleTag(
                            text: prio,
                            bgColor: prio == 'Urgent' ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                            textColor: prio == 'Urgent' ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                          ),
                          const Spacer(),
                          ModuleTag(
                            text: st,
                            bgColor: st == 'Approved' ? const Color(0xFFD1FAE5) : (st == 'Rejected' ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7)),
                            textColor: st == 'Approved' ? const Color(0xFF059669) : (st == 'Rejected' ? const Color(0xFFDC2626) : const Color(0xFFD97706)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${pr['department'] ?? '-'} • ${pr['plantFacility'] ?? '-'}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('Est Budget: ${_fmtInr(pr['totalEstCost'])} • ${(pr['items'] is List) ? (pr['items'] as List).length : 1} item(s)',
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                      if (st == 'Pending Approval' && _perm.canEdit) ...[
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async {
                                await SupplyChainApiService.savePurchaseRequisition({...pr, 'status': 'Rejected'});
                                await _loadAllData();
                              },
                              child: const Text('Reject', style: TextStyle(color: Color(0xFFDC2626))),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                await SupplyChainApiService.savePurchaseRequisition({...pr, 'status': 'Approved'});
                                await _loadAllData();
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      ] else if (_perm.canDelete) ...[
                        const Divider(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 19),
                            onPressed: () async {
                              if (await _confirmDelete('${pr['prNumber']}')) {
                                await SupplyChainApiService.deletePurchaseRequisition(pr['id']);
                                await _loadAllData();
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ] else if (_activeTab == 'vendors') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Supplier Directory (${_suppliers.length})', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.download_outlined, color: Color(0xFF2563EB)),
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'suppliers_directory.csv',
                    headers: const ['Name', 'Tier', 'Category', 'GSTIN', 'Contact', 'Phone', 'Payment Terms', 'Status'],
                    rows: _suppliers.map((s) => [s['name'] ?? '', s['tier'] ?? '', s['category'] ?? '', s['gstin'] ?? '', s['contactPerson'] ?? '', s['phone'] ?? '', s['paymentTerms'] ?? '', s['status'] ?? '']).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: moduleInputDecoration('Search vendor name, category, contact, phone, GSTIN...'),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 8),
            if (_suppliers.isEmpty)
              const ModuleEmptyState(icon: Icons.business_outlined, title: 'No Suppliers Registered', subtitle: 'Build your multi-tier supply network by onboarding your first vendor.')
            else
              ..._suppliers
                  .where((s) {
                    if (_searchQuery.trim().isEmpty) return true;
                    final q = _searchQuery.toLowerCase().trim();
                    return (s['name']?.toString().toLowerCase().contains(q) == true) ||
                        (s['tier']?.toString().toLowerCase().contains(q) == true) ||
                        (s['category']?.toString().toLowerCase().contains(q) == true) ||
                        (s['gstin']?.toString().toLowerCase().contains(q) == true) ||
                        (s['contactPerson']?.toString().toLowerCase().contains(q) == true) ||
                        (s['phone']?.toString().toLowerCase().contains(q) == true) ||
                        (s['email']?.toString().toLowerCase().contains(q) == true);
                  })
                  .map((s) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text('${s['name'] ?? '-'}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800))),
                                ModuleTag(text: '${s['status'] ?? 'Active'}', bgColor: const Color(0xFFD1FAE5), textColor: const Color(0xFF059669)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ModuleTag(text: '${s['tier'] ?? '-'}', bgColor: const Color(0xFFF3E8FF), textColor: const Color(0xFF7C3AED)),
                            const SizedBox(height: 6),
                            Text('${s['category'] ?? '-'} • GSTIN: ${s['gstin'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                            Text('Contact: ${s['contactPerson'] ?? '-'} (${s['phone'] ?? '-'}) • ${s['paymentTerms'] ?? '-'}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility_outlined, color: Color(0xFF2563EB), size: 20),
                                  tooltip: 'View Supplier Details',
                                  onPressed: () => _viewSupplierDetails(s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF475569), size: 20),
                                  tooltip: 'Edit Supplier Details',
                                  onPressed: () => _openCreateSupplierModal(s),
                                ),
                                if (_perm.canDelete)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
                                    onPressed: () async {
                                      if (await _confirmDelete('${s['name']}')) {
                                        await SupplyChainApiService.deleteProcurementSupplier(s['id']);
                                        await _loadAllData();
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      )),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Delivery Notes & GRN (${_deliveryNotes.length})', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.download_outlined, color: Color(0xFF2563EB)),
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'delivery_notes_grn.csv',
                    headers: const ['GRN Number', 'PO Number', 'Supplier', 'Vehicle No', 'Received Date', 'Received Qty', 'Status'],
                    rows: _deliveryNotes.map((g) => [g['grnNumber'] ?? '', g['poNumber'] ?? '', g['supplierName'] ?? '', g['vehicleNo'] ?? '', g['receivedDate'] ?? '', g['receivedQty'] ?? 0, g['inspectionStatus'] ?? '']).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: moduleInputDecoration('Search GRN #, PO #, supplier, vehicle reg, transporter...'),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 8),
            if (_deliveryNotes.isEmpty)
              const ModuleEmptyState(icon: Icons.local_shipping_outlined, title: 'No Delivery Notes Logged', subtitle: 'Track incoming consignments and reconcile delivered weights.')
            else
              ..._deliveryNotes
                  .where((g) {
                    if (_searchQuery.trim().isEmpty) return true;
                    final q = _searchQuery.toLowerCase().trim();
                    return (g['grnNumber']?.toString().toLowerCase().contains(q) == true) ||
                        (g['poNumber']?.toString().toLowerCase().contains(q) == true) ||
                        (g['supplierName']?.toString().toLowerCase().contains(q) == true) ||
                        (g['vehicleNo']?.toString().toLowerCase().contains(q) == true) ||
                        (g['transporter']?.toString().toLowerCase().contains(q) == true) ||
                        (g['eWayBill']?.toString().toLowerCase().contains(q) == true) ||
                        (g['inspectionStatus']?.toString().toLowerCase().contains(q) == true);
                  })
                  .map((g) {
                final qc = (g['inspectionStatus'] ?? '').toString();
                final passed = qc.contains('Passed');
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ModuleTag(text: '${g['grnNumber'] ?? ''}', bgColor: const Color(0xFFEFF6FF), textColor: const Color(0xFF1D4ED8)),
                          const SizedBox(width: 6),
                          ModuleTag(text: '${g['poNumber'] ?? ''}', bgColor: const Color(0xFFF1F5F9), textColor: const Color(0xFF334155)),
                          const Spacer(),
                          ModuleTag(
                            text: qc,
                            bgColor: passed ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                            textColor: passed ? const Color(0xFF059669) : const Color(0xFFD97706),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${g['supplierName'] ?? '-'} • ${g['receivedQty'] ?? 0} MT', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800)),
                      Text('Vehicle: ${g['vehicleNo'] ?? '-'} • Received: ${_formatToDDMMYYYY(g['receivedDate']?.toString())}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, color: Color(0xFF2563EB), size: 20),
                            tooltip: 'View GRN Details',
                            onPressed: () => _viewGrnDetails(g),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF475569), size: 20),
                            tooltip: 'Edit Delivery Note',
                            onPressed: () => _openCreateGrnModal(g),
                          ),
                          if (_perm.canDelete)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
                              tooltip: 'Delete GRN',
                              onPressed: () async {
                                if (await _confirmDelete('${g['grnNumber']}')) {
                                  await SupplyChainApiService.deleteDeliveryNote(g['id']);
                                  await _loadAllData();
                                }
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMeta = _tabs.firstWhere((t) => t.key == _activeTab, orElse: () => _tabs.first);
    return ModuleShellScaffold(
      headerTitle: activeMeta.title,
      moduleName: 'Supply Chain & Operations',
      submodules: _tabs,
      activeKey: _activeTab,
      onSelectSubmodule: (k) => setState(() {
        _activeTab = k;
        _searchQuery = '';
        _statusFilter = 'All';
      }),
      hasAccess: _perm.canView,
      isLoadingPermissions: _isLoadingPerm,
      accessDeniedMessage: 'You do not have view permissions for the Procurement & PO Management module. Please contact your system administrator.',
      child: _buildTabContent(),
    );
  }
}
