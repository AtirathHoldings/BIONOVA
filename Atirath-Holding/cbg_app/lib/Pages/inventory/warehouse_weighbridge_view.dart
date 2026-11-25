import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/inventory_api_service.dart';
import '../../services/rbac_service.dart';
import '../../widgets/module_ui_widgets.dart';

class WarehouseWeighbridgeView extends StatefulWidget {
  final ScreenPermission screenPerm;

  const WarehouseWeighbridgeView({super.key, required this.screenPerm});

  @override
  State<WarehouseWeighbridgeView> createState() => _WarehouseWeighbridgeViewState();
}

class _WarehouseWeighbridgeViewState extends State<WarehouseWeighbridgeView> {
  static const List<Map<String, dynamic>> _warehouseZones = [
    {'name': 'Zone 1: Raw Biomass Silo Yard', 'capacity': 8000.0, 'unit': 'MT', 'color': Color(0xFF16A34A)},
    {'name': 'Zone 2: Chemical & Enzyme Additives Warehouse', 'capacity': 500.0, 'unit': 'MT', 'color': Color(0xFF2563EB)},
    {'name': 'Zone 3: Mechanical & P&ID Spares Store', 'capacity': 1200.0, 'unit': 'Bins', 'color': Color(0xFF7C3AED)},
    {'name': 'Zone 4: High-Pressure CBG Cascade Yard', 'capacity': 40.0, 'unit': 'Cascades', 'color': Color(0xFFEA580C)},
  ];

  List<Map<String, dynamic>> _slips = [];
  bool _isLoading = true;
  String _searchTerm = '';
  String _statusFilter = 'ALL';
  final TextEditingController _scanCtrl = TextEditingController();
  Map<String, dynamic>? _scanResult;
  String? _scanError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final local = await InventoryApiService.loadLocalList(InventoryStorageKeys.weighbridge);
    if (mounted) {
      setState(() {
        _slips = local;
        _isLoading = false;
      });
    }
    final live = await InventoryApiService.getWeighbridgeSlips();
    if (live.isNotEmpty && mounted) {
      setState(() {
        _slips = live;
        _isLoading = false;
      });
      await InventoryApiService.saveLocalList(InventoryStorageKeys.weighbridge, live);
    }
  }

  Future<void> _persistSlips(List<Map<String, dynamic>> updated) async {
    setState(() => _slips = updated);
    await InventoryApiService.saveLocalList(InventoryStorageKeys.weighbridge, updated);
  }

  void _performScan() {
    final code = _scanCtrl.text.trim().toLowerCase();
    if (code.isEmpty) {
      setState(() {
        _scanResult = null;
        _scanError = 'Enter a Slip ID, Vehicle No, or RFID Tag to scan.';
      });
      return;
    }
    final match = _slips.where((s) {
      return (s['slipNo'] ?? s['id'] ?? '').toString().toLowerCase() == code ||
          (s['vehicleNo'] ?? '').toString().toLowerCase().contains(code) ||
          (s['rfidTag'] ?? '').toString().toLowerCase() == code;
    }).toList();
    setState(() {
      if (match.isNotEmpty) {
        _scanResult = match.first;
        _scanError = null;
      } else {
        _scanResult = null;
        _scanError = 'No weighbridge record found matching "${_scanCtrl.text.trim()}".';
      }
    });
  }

  void _openWeighInModal() {
    final formKey = GlobalKey<FormState>();
    final vehicleCtrl = TextEditingController();
    final transporterCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final supplierCtrl = TextEditingController();
    final materialCtrl = TextEditingController(text: 'Napier Grass / Biomass');
    final grossCtrl = TextEditingController();
    final moistureCtrl = TextEditingController(text: '14');
    final operatorCtrl = TextEditingController();
    String selectedZone = _warehouseZones.first['name'] as String;
    String status = 'Pending Tare';

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
                      const Icon(Icons.scale_outlined, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('New Truck Weigh-In (Gross)', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: vehicleCtrl,
                          decoration: moduleInputDecoration('Vehicle No *', hint: 'MH-12-TR-4421'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: transporterCtrl,
                          decoration: moduleInputDecoration('Transporter'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: driverCtrl, decoration: moduleInputDecoration('Driver Name'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: moduleInputDecoration('Driver Phone'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: supplierCtrl,
                          decoration: moduleInputDecoration('Supplier / Farm *'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: materialCtrl,
                          decoration: moduleInputDecoration('Material *'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedZone,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Target Warehouse Zone'),
                    items: _warehouseZones
                        .map((z) => DropdownMenuItem<String>(value: z['name'] as String, child: Text(z['name'] as String, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setModalState(() => selectedZone = v ?? selectedZone),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: grossCtrl,
                          keyboardType: TextInputType.number,
                          decoration: moduleInputDecoration('Gross Weight (kg) *'),
                          validator: (v) {
                            final n = double.tryParse(v ?? '');
                            if (n == null || n < 1000) return 'Min 1000 kg';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: moistureCtrl,
                          keyboardType: TextInputType.number,
                          decoration: moduleInputDecoration('Moisture % (0-100)'),
                          validator: (v) {
                            final n = double.tryParse(v ?? '0');
                            if (n == null || n < 0 || n > 100) return '0-100%';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: operatorCtrl, decoration: moduleInputDecoration('Weighbridge Operator'))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: moduleInputDecoration('Initial Gate Status'),
                          items: const [
                            DropdownMenuItem(value: 'Pending Tare', child: Text('Pending Tare')),
                            DropdownMenuItem(value: 'Rejected', child: Text('Rejected (QC Fail)')),
                          ],
                          onChanged: (v) => setModalState(() => status = v ?? status),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final slipId = 'WB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                        final gross = double.parse(grossCtrl.text.trim());
                        final moisture = double.tryParse(moistureCtrl.text.trim()) ?? 0;
                        final newSlip = {
                          'id': slipId,
                          'slipNo': slipId,
                          'rfidTag': 'RFID-${slipId.replaceAll('WB-', '')}',
                          'vehicleNo': vehicleCtrl.text.trim().toUpperCase(),
                          'transporter': transporterCtrl.text.trim(),
                          'driverName': driverCtrl.text.trim(),
                          'driverPhone': phoneCtrl.text.trim(),
                          'supplier': supplierCtrl.text.trim(),
                          'materialName': materialCtrl.text.trim(),
                          'warehouseZone': selectedZone,
                          'grossWeightKg': gross,
                          'tareWeightKg': 0,
                          'netWeightKg': 0,
                          'moisturePercent': moisture,
                          'netDryWeightKg': 0,
                          'weighbridgeOperator': operatorCtrl.text.trim().isEmpty ? 'Gate Operator' : operatorCtrl.text.trim(),
                          'status': status,
                          'grossTime': DateTime.now().toIso8601String(),
                          'tareTime': null,
                        };
                        try {
                          await InventoryApiService.saveWeighbridgeSlip(newSlip);
                        } catch (_) {}
                        await _persistSlips([newSlip, ..._slips]);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Record Gross Weigh-In'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
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

  void _openTareModal(Map<String, dynamic> slip) {
    final tareCtrl = TextEditingController();
    final gross = double.tryParse((slip['grossWeightKg'] ?? 0).toString()) ?? 0;
    final moisture = double.tryParse((slip['moisturePercent'] ?? 0).toString()) ?? 0;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Record Tare Weight • ${slip['slipNo'] ?? slip['id']}', style: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vehicle: ${slip['vehicleNo'] ?? '-'} • Gross: ${gross.toStringAsFixed(0)} kg • Moisture: ${moisture.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF475569))),
              const SizedBox(height: 12),
              TextField(
                controller: tareCtrl,
                keyboardType: TextInputType.number,
                decoration: moduleInputDecoration('Empty Tare Weight (kg) *', hint: 'Must be < Gross Weight'),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 6),
                Text(errorMsg!, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFDC2626))),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final tare = double.tryParse(tareCtrl.text.trim());
                if (tare == null || tare <= 0 || tare >= gross) {
                  setDlgState(() => errorMsg = 'Tare weight must be > 0 and less than gross weight (${gross.toStringAsFixed(0)} kg).');
                  return;
                }
                final netKg = gross - tare;
                final netDryKg = (netKg * (1 - moisture / 100)).round();
                final updated = _slips.map((s) {
                  if (s['id'].toString() == slip['id'].toString()) {
                    final copy = {
                      ...s,
                      'tareWeightKg': tare,
                      'netWeightKg': netKg,
                      'netDryWeightKg': netDryKg,
                      'status': 'Completed',
                      'tareTime': DateTime.now().toIso8601String(),
                    };
                    try {
                      InventoryApiService.saveWeighbridgeSlip(copy, id: s['id']);
                    } catch (_) {}
                    return copy;
                  }
                  return s;
                }).toList();
                await _persistSlips(updated);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
              child: const Text('Complete & Compute Net'),
            ),
          ],
        ),
      ),
    );
  }

  void _openPrintSlip(Map<String, dynamic> slip) {
    final summary = '''
BIONOVA WEIGHBRIDGE SLIP
Slip No: ${slip['slipNo'] ?? slip['id']}
Vehicle No: ${slip['vehicleNo']}
Transporter: ${slip['transporter'] ?? '-'}
Driver: ${slip['driverName'] ?? '-'} (${slip['driverPhone'] ?? '-'})
Supplier: ${slip['supplier']}
Material: ${slip['materialName']}
Zone: ${slip['warehouseZone']}
Gross Weight: ${slip['grossWeightKg']} kg
Tare Weight: ${slip['tareWeightKg']} kg
Net Weight: ${slip['netWeightKg']} kg
Moisture %: ${slip['moisturePercent']}%
Net Dry Biomass Weight: ${slip['netDryWeightKg']} kg
Status: ${slip['status']}
''';
    showPrintablePreviewDialog(
      context,
      title: 'Weighbridge Slip • ${slip['slipNo'] ?? slip['id']}',
      copyText: summary,
      content: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFF8FAFC),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BioNova Biogas Complex - Digital Weighbridge Slip', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13.5)),
            const Divider(),
            _slipRow('Slip No', '${slip['slipNo'] ?? slip['id']}'),
            _slipRow('Vehicle', '${slip['vehicleNo'] ?? '-'}'),
            _slipRow('Supplier', '${slip['supplier'] ?? '-'}'),
            _slipRow('Material', '${slip['materialName'] ?? '-'}'),
            _slipRow('Target Zone', '${slip['warehouseZone'] ?? '-'}'),
            const Divider(),
            _slipRow('Gross Weight', '${slip['grossWeightKg']} kg'),
            _slipRow('Tare Weight', '${slip['tareWeightKg']} kg'),
            _slipRow('Net Weight', '${slip['netWeightKg']} kg'),
            _slipRow('Moisture Ded.', '${slip['moisturePercent']}%'),
            _slipRow('Net Dry Biomass', '${slip['netDryWeightKg']} kg', bold: true),
            const Divider(),
            _slipRow('Status', '${slip['status'] ?? '-'}'),
          ],
        ),
      ),
    );
  }

  Widget _slipRow(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = _slips.where((s) => s['status'] == 'Completed').toList();
    final totalBiomassMT = completed.fold<double>(0, (sum, s) => sum + (double.tryParse((s['netWeightKg'] ?? 0).toString()) ?? 0)) / 1000.0;
    final activeOnScale = _slips.where((s) => s['status'] == 'Pending Tare').length;
    final rejectedCount = _slips.where((s) => s['status'] == 'Rejected').length;

    final filtered = _slips.where((s) {
      final q = _searchTerm.trim().toLowerCase();
      final matchQ = q.isEmpty ||
          (s['vehicleNo'] ?? '').toString().toLowerCase().contains(q) ||
          (s['supplier'] ?? '').toString().toLowerCase().contains(q) ||
          (s['materialName'] ?? '').toString().toLowerCase().contains(q) ||
          (s['slipNo'] ?? s['id'] ?? '').toString().toLowerCase().contains(q);
      final matchStatus = _statusFilter == 'ALL' || s['status'] == _statusFilter;
      return matchQ && matchStatus;
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
                    Text('Warehouse & Weighbridge Portal', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                    Text('Gross/Tare biomass weighment, dry-weight adjustment & zone storage', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined, color: Color(0xFF2563EB)),
                onPressed: () => exportCsvData(
                  context,
                  fileName: 'weighbridge_slips.csv',
                  headers: const ['Slip No', 'Vehicle No', 'Transporter', 'Supplier', 'Material', 'Zone', 'Gross (kg)', 'Tare (kg)', 'Net (kg)', 'Moisture %', 'Dry Net (kg)', 'Status', 'Time'],
                  rows: filtered
                      .map((s) => [
                            s['slipNo'] ?? s['id'] ?? '',
                            s['vehicleNo'] ?? '',
                            s['transporter'] ?? '',
                            s['supplier'] ?? '',
                            s['materialName'] ?? '',
                            s['warehouseZone'] ?? '',
                            s['grossWeightKg'] ?? 0,
                            s['tareWeightKg'] ?? 0,
                            s['netWeightKg'] ?? 0,
                            s['moisturePercent'] ?? 0,
                            s['netDryWeightKg'] ?? 0,
                            s['status'] ?? '',
                            s['grossTime'] ?? '',
                          ])
                      .toList(),
                ),
              ),
              if (widget.screenPerm.canCreate)
                ElevatedButton.icon(
                  onPressed: _openWeighInModal,
                  icon: const Icon(Icons.local_shipping_outlined, size: 15),
                  label: const Text('Weigh-In'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ModuleKpiGrid(items: [
            ModuleKpiItem(label: 'Net Biomass Received', value: '${totalBiomassMT.toStringAsFixed(2)} MT', subtext: 'Completed weighments', accentColor: const Color(0xFF16A34A), icon: Icons.eco_outlined),
            ModuleKpiItem(label: 'Total Slips Logged', value: '${_slips.length}', subtext: 'Inward & outward', accentColor: const Color(0xFF2563EB), icon: Icons.receipt_long_outlined),
            ModuleKpiItem(label: 'Active on Scale', value: '$activeOnScale', subtext: 'Pending tare weight', accentColor: const Color(0xFFD97706), icon: Icons.scale_outlined),
            ModuleKpiItem(label: 'QC Rejected Trucks', value: '$rejectedCount', subtext: 'Blocked at weighbridge', accentColor: const Color(0xFFDC2626), icon: Icons.cancel_outlined),
          ]),
          const SizedBox(height: 14),
          // Barcode / RFID Scanner Card
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
                Text('RFID / Barcode Weighbridge Scanner', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _scanCtrl,
                        decoration: moduleInputDecoration('Scan Slip No, Vehicle No, or RFID Tag'),
                        onSubmitted: (_) => _performScan(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _performScan,
                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                      label: const Text('Scan'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                    ),
                  ],
                ),
                if (_scanError != null) ...[
                  const SizedBox(height: 8),
                  Text(_scanError!, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFDC2626))),
                ],
                if (_scanResult != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFBFDBFE))),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_scanResult!['slipNo'] ?? _scanResult!['id']} • ${_scanResult!['vehicleNo']}',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                              Text('${_scanResult!['materialName']} (${_scanResult!['status']})',
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155))),
                            ],
                          ),
                        ),
                        if (_scanResult!['status'] == 'Pending Tare' && widget.screenPerm.canEdit)
                          ElevatedButton(
                            onPressed: () => _openTareModal(_scanResult!),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
                            child: const Text('Record Tare'),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Warehouse Zones Occupancy
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
                Text('Warehouse Zone Capacity Utilization', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                const SizedBox(height: 10),
                ..._warehouseZones.map((zone) {
                  final zoneName = zone['name'] as String;
                  final cap = zone['capacity'] as double;
                  final unit = zone['unit'] as String;
                  final color = zone['color'] as Color;
                  final zoneSlips = completed.where((s) => s['warehouseZone'] == zoneName).toList();
                  final used = unit == 'MT'
                      ? zoneSlips.fold<double>(0, (sum, s) => sum + (double.tryParse((s['netWeightKg'] ?? 0).toString()) ?? 0)) / 1000.0
                      : zoneSlips.length.toDouble();
                  final pct = (used / cap).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(zoneName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
                            Text('${used.toStringAsFixed(unit == 'MT' ? 1 : 0)} / ${cap.toStringAsFixed(0)} $unit',
                                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFF1F5F9),
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Filter bar
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  decoration: moduleInputDecoration('Search slip, vehicle, supplier...'),
                  onChanged: (v) => setState(() => _searchTerm = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('wb-st-$_statusFilter'),
                  initialValue: _statusFilter,
                  decoration: moduleInputDecoration('Status'),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All')),
                    DropdownMenuItem(value: 'Pending Tare', child: Text('Pending Tare')),
                    DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v ?? 'ALL'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(
              icon: Icons.scale_outlined,
              title: 'No Weighbridge Slips',
              subtitle: 'Record truck gross weight to generate digital weighbridge slips.',
            )
          else
            ...filtered.map((s) {
              final st = (s['status'] ?? 'Pending Tare').toString();
              final Color badgeBg = st == 'Completed'
                  ? const Color(0xFFD1FAE5)
                  : (st == 'Rejected' ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7));
              final Color badgeFg = st == 'Completed'
                  ? const Color(0xFF059669)
                  : (st == 'Rejected' ? const Color(0xFFDC2626) : const Color(0xFFD97706));
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
                        Text('${s['slipNo'] ?? s['id']} • ${s['vehicleNo'] ?? '-'}',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: const Color(0xFF0F172A))),
                        const Spacer(),
                        ModuleTag(text: st, bgColor: badgeBg, textColor: badgeFg),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${s['materialName'] ?? '-'} • ${s['supplier'] ?? '-'}',
                        style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF334155))),
                    Text('${s['warehouseZone'] ?? '-'}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text('Gross: ${s['grossWeightKg'] ?? 0} kg', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('Tare: ${s['tareWeightKg'] ?? 0} kg', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('Net Dry: ${s['netDryWeightKg'] ?? 0} kg (${s['moisturePercent'] ?? 0}% M)',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A))),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _openPrintSlip(s),
                          icon: const Icon(Icons.print_outlined, size: 16),
                          label: const Text('Slip'),
                        ),
                        if (st == 'Pending Tare' && widget.screenPerm.canEdit)
                          ElevatedButton(
                            onPressed: () => _openTareModal(s),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Record Tare'),
                          ),
                        if (widget.screenPerm.canDelete)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 19),
                            onPressed: () async {
                              try {
                                await InventoryApiService.deleteWeighbridgeSlip(s['id']);
                              } catch (_) {}
                              await _persistSlips(_slips.where((x) => x['id'].toString() != s['id'].toString()).toList());
                            },
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
