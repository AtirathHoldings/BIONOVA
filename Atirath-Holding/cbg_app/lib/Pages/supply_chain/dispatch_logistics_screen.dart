import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/supply_chain_api_service.dart';
import '../../widgets/module_ui_widgets.dart';

class DispatchLogisticsScreen extends StatefulWidget {
  final String initialTab;

  const DispatchLogisticsScreen({super.key, this.initialTab = 'trips'});

  @override
  State<DispatchLogisticsScreen> createState() => _DispatchLogisticsScreenState();
}

class _DispatchLogisticsScreenState extends State<DispatchLogisticsScreen> {
  static const List<ModuleSubmoduleItem> _tabs = [
    ModuleSubmoduleItem(key: 'trips', title: 'Fleet & Dispatch Logistics', shortLabel: 'Trip Sheets', icon: Icons.local_shipping_outlined),
    ModuleSubmoduleItem(key: 'drivers', title: 'Fleet & Dispatch Logistics', shortLabel: 'Drivers', icon: Icons.person_outline),
    ModuleSubmoduleItem(key: 'weighbridge', title: 'Fleet & Dispatch Logistics', shortLabel: 'Weighbridge', icon: Icons.scale_outlined),
    ModuleSubmoduleItem(key: 'routes', title: 'Fleet & Dispatch Logistics', shortLabel: 'Routes & Telemetry', icon: Icons.navigation_outlined),
    ModuleSubmoduleItem(key: 'temperature', title: 'Fleet & Dispatch Logistics', shortLabel: 'Cold Chain Temp', icon: Icons.thermostat_outlined),
  ];

  late String _activeTab;
  ScreenPermission _perm = ScreenPermission.full;
  bool _isLoadingPerm = true;
  bool _isLoading = true;

  List<Map<String, dynamic>> _plants = [];
  List<Map<String, dynamic>> _lands = [];
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _weighbridgeSlips = [];
  List<Map<String, dynamic>> _tempLogs = [];
  final List<Map<String, dynamic>> _routes = [
    {
      'id': 1,
      'badge': 'Corridor 1: Agri Substrate',
      'color': const Color(0xFF2563EB),
      'title': 'Warangal Napier Farms → Hyderabad East CBG',
      'meta': 'Distance: 148 km | Est. Transit: 3h 45m | Highway: NH 163',
      'vehicle': 'TS 08 UB 7712',
      'speed': 'Speed: 52 km/h',
      'driver': 'Nagaraju Rao',
      'eta': 'ETA: 1h 15m remaining',
      'progress': 0.68,
    },
    {
      'id': 2,
      'badge': 'Corridor 2: CBG Mother Cascade',
      'color': const Color(0xFF16A34A),
      'title': 'Hyderabad East CBG → IOCL Retail Dispenser Station',
      'meta': 'Distance: 42 km | Est. Transit: 1h 10m | Industrial Arterial',
      'vehicle': 'TS 07 UA 9901',
      'speed': 'Speed: 40 km/h',
      'driver': 'B. Satyanarayana',
      'eta': 'ETA: 25 mins remaining',
      'progress': 0.45,
    },
  ];

  @override
  void initState() {
    super.initState();
    _activeTab = _tabs.any((t) => t.key == widget.initialTab) ? widget.initialTab : 'trips';
    _initLoad();
  }

  Future<void> _initLoad() async {
    final perm = await RbacService.getScreenPermission('FLEET_DISPATCH');
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
      SupplyChainApiService.getVehicleTripSheets(),
      SupplyChainApiService.getDrivers(),
      SupplyChainApiService.getLogisticsWeighbridgeSlips(),
      SupplyChainApiService.getTransitTemperatureLogs(),
      SupplyChainApiService.getPlants(),
      SupplyChainApiService.getLands(),
    ]);
    if (mounted) {
      setState(() {
        _trips = results[0];
        _drivers = results[1];
        _weighbridgeSlips = results[2];
        _tempLogs = results[3];
        _plants = results[4];
        _lands = results[5];
        _isLoading = false;
      });
    }
  }

  double _num(dynamic v) => double.tryParse((v ?? '0').toString()) ?? 0;

  List<String> _originOptions() {
    final list = _lands
        .map((l) => '${l['landName'] ?? l['surveyNo'] ?? 'Lot'} (${l['district'] ?? 'Farm Site'})')
        .where((s) => s.trim().isNotEmpty)
        .toSet()
        .toList();
    if (list.isEmpty) {
      list.addAll([
        'Warangal Napier Grass Hub (Lot A)',
        'Karimnagar Energy Maize Parcel (Lot B)',
      ]);
    }
    return list;
  }

  List<String> _destOptions() {
    final list = _plants
        .map((p) => (p['plantNm'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (list.isEmpty) {
      list.addAll([
        'Hyderabad East CBG Plant',
        'Warangal Bio-Energy & Fertilizer Hub',
        'IOCL CNG Retail Mother Station',
      ]);
    }
    return list;
  }

  List<String> _driverOptions() {
    final list = _drivers.map((d) => (d['name'] ?? '').toString()).where((s) => s.isNotEmpty).toSet().toList();
    if (list.isEmpty) list.add('Nagaraju Rao');
    return list;
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

  void _openCreateTripModal() {
    final nextSeq = (_trips.length + 1).toString().padLeft(4, '0');
    final origins = _originOptions();
    final dests = _destOptions();
    final drvs = _driverOptions();
    final formKey = GlobalKey<FormState>();

    final tripCtrl = TextEditingController(text: 'TRP-2026-$nextSeq');
    String origin = origins.first;
    String destination = dests.first;
    final vehicleCtrl = TextEditingController(text: 'TS 08 UB 7712 (10-Wheeler Tipper)');
    String assignedDriver = drvs.first;
    String cargoCategory = 'Raw Agri Biomass / Napier Grass';
    final qtyCtrl = TextEditingController(text: '25.5');

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
                      const Icon(Icons.local_shipping_outlined, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Create Vehicle Dispatch Trip Sheet', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: tripCtrl, decoration: moduleInputDecoration('Trip Sheet # *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: origin,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Origin Farm Lot *'),
                    items: origins.map((o) => DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setModalState(() => origin = v ?? origin),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: destination,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Destination Plant / Hub *'),
                    items: dests.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setModalState(() => destination = v ?? destination),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: vehicleCtrl, decoration: moduleInputDecoration('Assigned Transport Vehicle *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: assignedDriver,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Commercial Driver'),
                    items: drvs.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setModalState(() => assignedDriver = v ?? assignedDriver),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: cargoCategory,
                          isExpanded: true,
                          decoration: moduleInputDecoration('Cargo Classification'),
                          items: const [
                            DropdownMenuItem(value: 'Raw Agri Biomass / Napier Grass', child: Text('Raw Agri Biomass / Napier Grass')),
                            DropdownMenuItem(value: 'Press Mud / Poultry Litter Substrate', child: Text('Press Mud / Poultry Litter')),
                            DropdownMenuItem(value: 'Compressed Bio-Gas (CBG) Cascades', child: Text('CBG Cascades')),
                            DropdownMenuItem(value: 'Fermented Organic Manure (FOM) Bulk', child: Text('FOM Organic Manure')),
                            DropdownMenuItem(value: 'Liquid Bio-Fertilizer Tanker (LFOM)', child: Text('Liquid LFOM Tanker')),
                          ],
                          onChanged: (v) => setModalState(() => cargoCategory = v ?? cargoCategory),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: moduleInputDecoration('Qty (MT) *'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        await SupplyChainApiService.saveVehicleTripSheet({
                          'tripNumber': tripCtrl.text.trim(),
                          'origin': origin,
                          'destination': destination,
                          'assignedVehicle': vehicleCtrl.text.trim(),
                          'assignedDriver': assignedDriver,
                          'cargoCategory': cargoCategory,
                          'dispatchQtyMT': double.tryParse(qtyCtrl.text.trim()) ?? 0,
                          'dispatchDateTime': DateTime.now().toIso8601String().substring(0, 16),
                          'status': 'Dispatched / En Route',
                        });
                        await _loadAllData();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('Dispatch Vehicle & Issue Trip Sheet'),
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

  void _openCreateDriverModal() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final licCtrl = TextEditingController();
    final expCtrl = TextEditingController(
      text: DateTime.now().add(const Duration(days: 730)).toIso8601String().split('T').first,
    );
    final vehCtrl = TextEditingController(text: 'TS 08 UB 7712');
    String dutyStatus = 'Available';
    bool hazmat = true;

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
                      const Icon(Icons.person_outline, color: Color(0xFF059669)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Register Commercial Fleet Driver', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: nameCtrl, decoration: moduleInputDecoration('Driver Full Name *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: moduleInputDecoration('Contact Phone *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null)),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: licCtrl, decoration: moduleInputDecoration('HCV License # *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: expCtrl, decoration: moduleInputDecoration('License Expiry'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: vehCtrl, decoration: moduleInputDecoration('Assigned Vehicle'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: dutyStatus,
                    decoration: moduleInputDecoration('Duty Status'),
                    items: const [
                      DropdownMenuItem(value: 'Available', child: Text('Available in Fleet Yard')),
                      DropdownMenuItem(value: 'On Active Trip', child: Text('On Active Trip')),
                      DropdownMenuItem(value: 'Resting / Off-Duty', child: Text('Resting / Off-Duty')),
                    ],
                    onChanged: (v) => setModalState(() => dutyStatus = v ?? dutyStatus),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: hazmat,
                    onChanged: (v) => setModalState(() => hazmat = v ?? true),
                    title: Text('CBG Hazmat Certified Driver', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        await SupplyChainApiService.saveDriver({
                          'name': nameCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'licenseNumber': licCtrl.text.trim(),
                          'licenseExpiry': expCtrl.text.trim(),
                          'hazmatCertified': hazmat,
                          'assignedVehicle': vehCtrl.text.trim(),
                          'dutyStatus': dutyStatus,
                        });
                        await _loadAllData();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('Save Driver Record'),
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

  void _openCreateWeighbridgeModal() {
    final nextSeq = (_weighbridgeSlips.length + 1).toString().padLeft(4, '0');
    final tripNums = _trips.map((t) => (t['tripNumber'] ?? '').toString()).where((s) => s.isNotEmpty).toList();
    if (tripNums.isEmpty) tripNums.add('TRP-2026-0001');
    final formKey = GlobalKey<FormState>();

    final slipCtrl = TextEditingController(text: 'WBS-2026-$nextSeq');
    String tripNumber = tripNums.first;
    final vehCtrl = TextEditingController(text: 'TS 08 UB 7712');
    final grossCtrl = TextEditingController(text: '36.8');
    final tareCtrl = TextEditingController(text: '11.2');
    final opCtrl = TextEditingController(text: 'Ramesh Goud');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final gross = double.tryParse(grossCtrl.text.trim()) ?? 0;
          final tare = double.tryParse(tareCtrl.text.trim()) ?? 0;
          final net = (gross - tare).clamp(0, 999999);
          return Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.scale_outlined, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Record Plant Gate Weighbridge Slip', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(controller: slipCtrl, decoration: moduleInputDecoration('Weighbridge Slip # *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: tripNumber,
                      isExpanded: true,
                      decoration: moduleInputDecoration('Linked Trip Sheet #'),
                      items: tripNums.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setModalState(() => tripNumber = v ?? tripNumber),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(controller: vehCtrl, decoration: moduleInputDecoration('Vehicle Reg No *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: grossCtrl,
                            keyboardType: TextInputType.number,
                            decoration: moduleInputDecoration('Gross (MT) *'),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: tareCtrl,
                            keyboardType: TextInputType.number,
                            decoration: moduleInputDecoration('Tare (MT) *'),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8)),
                      child: Text('Net Certified Payload: ${net.toStringAsFixed(2)} MT', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: const Color(0xFF16A34A))),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(controller: opCtrl, decoration: moduleInputDecoration('Scale Operator Name')),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          await SupplyChainApiService.saveLogisticsWeighbridgeSlip({
                            'slipNumber': slipCtrl.text.trim(),
                            'tripNumber': tripNumber,
                            'vehicleNo': vehCtrl.text.trim().toUpperCase(),
                            'inboundGrossMT': gross,
                            'outboundTareMT': tare,
                            'netWeightMT': double.parse(net.toStringAsFixed(2)),
                            'operatorName': opCtrl.text.trim(),
                            'scaleTimestamp': DateTime.now().toIso8601String().replaceAll('T', ' ').substring(0, 19),
                            'status': 'Verified & Stamped',
                          });
                          await _loadAllData();
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                        child: const Text('Certify & Save Weighbridge Slip'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openCreateTempModal() {
    final nextSeq = (_tempLogs.length + 1).toString().padLeft(3, '0');
    final tripNums = _trips.map((t) => (t['tripNumber'] ?? '').toString()).where((s) => s.isNotEmpty).toList();
    if (tripNums.isEmpty) tripNums.add('TRP-2026-0001');
    final formKey = GlobalKey<FormState>();

    final tagCtrl = TextEditingController(text: 'SNS-TMP-$nextSeq');
    String tripNumber = tripNums.first;
    final cargoCtrl = TextEditingController(text: 'Silage Feedstock Substrate');
    final curCtrl = TextEditingController(text: '18.4');
    final maxCtrl = TextEditingController(text: '28.0');
    final ambCtrl = TextEditingController(text: '32.5');

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
                      const Icon(Icons.thermostat_outlined, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Record Transit Temperature Telematics', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: tagCtrl, decoration: moduleInputDecoration('Sensor Tag ID *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: tripNumber,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Linked Trip Sheet'),
                    items: tripNums.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setModalState(() => tripNumber = v ?? tripNumber),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: cargoCtrl, decoration: moduleInputDecoration('Cargo Description')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: curCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Current Temp (°C) *'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(controller: maxCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Safe Max (°C)'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(controller: ambCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Ambient (°C)'))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final cur = double.tryParse(curCtrl.text.trim()) ?? 0;
                        final max = double.tryParse(maxCtrl.text.trim()) ?? 28;
                        final status = cur > max
                            ? 'Critical Thermal Excursion!'
                            : (cur > max - 2 ? 'Warning: Rising' : 'Optimal');
                        await SupplyChainApiService.saveTransitTemperatureLog({
                          'sensorTag': tagCtrl.text.trim(),
                          'tripNumber': tripNumber,
                          'cargoType': cargoCtrl.text.trim(),
                          'currentTempC': cur,
                          'minThresholdC': 12.0,
                          'maxThresholdC': max,
                          'ambientTempC': double.tryParse(ambCtrl.text.trim()) ?? 32.5,
                          'logTimestamp': DateTime.now().toIso8601String().substring(0, 16),
                          'status': status,
                        });
                        await _loadAllData();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('Save Telemetry Record'),
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

  void _openWeighbridgeCertificate(Map<String, dynamic> slip) {
    final text = '''
OFFICIAL WEIGHBRIDGE CERTIFICATE - BioNova Industrial Weighbridge Station #1
Slip Reference: ${slip['slipNumber']}
Vehicle Reg #: ${slip['vehicleNo']}
Linked Trip: ${slip['tripNumber']}
Timestamp: ${slip['scaleTimestamp']}
Gross Inbound Weight: ${slip['inboundGrossMT']} MT
Empty Vehicle Tare: ${slip['outboundTareMT']} MT
NET CERTIFIED PAYLOAD: ${slip['netWeightMT']} MT
''';
    showPrintablePreviewDialog(
      context,
      title: 'Weighbridge Certificate • ${slip['slipNumber']}',
      copyText: text,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OFFICIAL WEIGHBRIDGE CERTIFICATE', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
          Text('BioNova Industrial Weighbridge Station #1', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
          const Divider(),
          Text('Slip Reference: ${slip['slipNumber']}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
          Text('Linked Trip: ${slip['tripNumber']}'),
          Text('Vehicle Reg #: ${slip['vehicleNo']}'),
          Text('Timestamp: ${slip['scaleTimestamp']}'),
          const Divider(),
          Text('Gross Inbound Weight: ${slip['inboundGrossMT']} MT'),
          Text('Empty Vehicle Tare: ${slip['outboundTareMT']} MT'),
          const SizedBox(height: 6),
          Text('NET CERTIFIED PAYLOAD: ${slip['netWeightMT']} MT',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF16A34A))),
        ],
      ),
    );
  }

  Widget _buildCorridorCard({
    required String badge,
    required Color color,
    required String title,
    required String meta,
    required String vehicle,
    required String speed,
    required String driver,
    required String eta,
    required double progress,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ModuleTag(text: badge, bgColor: color.withValues(alpha: 0.14), textColor: color),
              const Spacer(),
              Text('● LIVE TRANSIT', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A))),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800)),
          Text(meta, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Vehicle: $vehicle', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    Text(speed, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Driver: $driver', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    Text(eta, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: progress, minHeight: 7, backgroundColor: const Color(0xFFE2E8F0), color: color),
          ),
        ],
      ),
    );
  }

  void _openCreateRouteModal() {
    final formKey = GlobalKey<FormState>();
    final nextSeq = _routes.length + 1;
    final nameCtrl = TextEditingController(text: 'Corridor $nextSeq: Agri Biomass Transit');
    String category = 'Agri Substrate';
    final originCtrl = TextEditingController(text: 'Warangal Napier Farms');
    final destCtrl = TextEditingController(text: 'Hyderabad East CBG');
    final distCtrl = TextEditingController(text: '120');
    final timeCtrl = TextEditingController(text: '3h 15m');
    final highwayCtrl = TextEditingController(text: 'NH 163');
    final vehCtrl = TextEditingController(text: 'TS 08 UB 7712');
    final driverCtrl = TextEditingController(text: 'Nagaraju Rao');
    final speedCtrl = TextEditingController(text: '50');
    final etaCtrl = TextEditingController(text: '1h 30m remaining');
    double progress = 0.50;

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
                      const Icon(Icons.navigation_outlined, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Add Dispatch Route Corridor', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: moduleInputDecoration('Corridor Name *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Corridor Category'),
                    items: const [
                      DropdownMenuItem(value: 'Agri Substrate', child: Text('Agri Substrate')),
                      DropdownMenuItem(value: 'CBG Mother Cascade', child: Text('CBG Mother Cascade')),
                      DropdownMenuItem(value: 'Organic Bio-Fertilizer', child: Text('Organic Bio-Fertilizer')),
                      DropdownMenuItem(value: 'Plant Equipment', child: Text('Plant Equipment')),
                    ],
                    onChanged: (v) => setModalState(() => category = v ?? category),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: originCtrl, decoration: moduleInputDecoration('Origin *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null)),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: destCtrl, decoration: moduleInputDecoration('Destination *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: distCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Distance (km)'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: timeCtrl, decoration: moduleInputDecoration('Est. Transit'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: highwayCtrl, decoration: moduleInputDecoration('Highway / Route')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: vehCtrl, decoration: moduleInputDecoration('Vehicle Reg #'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: driverCtrl, decoration: moduleInputDecoration('Driver Name'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: speedCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Speed (km/h)'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: etaCtrl, decoration: moduleInputDecoration('ETA Remaining'))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final col = category == 'CBG Mother Cascade'
                            ? const Color(0xFF16A34A)
                            : (category == 'Organic Bio-Fertilizer' ? const Color(0xFFD97706) : const Color(0xFF2563EB));
                        setState(() {
                          _routes.insert(0, {
                            'id': DateTime.now().millisecondsSinceEpoch,
                            'badge': nameCtrl.text.trim(),
                            'color': col,
                            'title': '${originCtrl.text.trim()} → ${destCtrl.text.trim()}',
                            'meta': 'Distance: ${distCtrl.text.trim()} km | Est. Transit: ${timeCtrl.text.trim()} | Highway: ${highwayCtrl.text.trim()}',
                            'vehicle': vehCtrl.text.trim(),
                            'speed': 'Speed: ${speedCtrl.text.trim()} km/h',
                            'driver': driverCtrl.text.trim(),
                            'eta': 'ETA: ${etaCtrl.text.trim()}',
                            'progress': progress,
                          });
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                      child: const Text('Add Route Corridor'),
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

  Widget _buildTabContent() {
    final activeTrips = _trips.where((t) => (t['status'] ?? '').toString().contains('En Route') || (t['status'] ?? '').toString().contains('Dispatched')).length;
    final totalWeightMT = _trips.fold<double>(0, (s, t) => s + _num(t['dispatchQtyMT']));
    final availDrivers = _drivers.where((d) => d['dutyStatus'] == 'Available').length;
    final tempAlerts = _tempLogs.where((t) => (t['status'] ?? '').toString().contains('Critical') || (t['status'] ?? '').toString().contains('Warning')).length;

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
                    Text('Fleet & Dispatch Logistics', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('Farm-to-plant trip sheets, driver roster, weighbridge & cold-chain telemetry', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              if (_perm.canCreate)
                ElevatedButton.icon(
                  onPressed: _activeTab == 'trips'
                      ? _openCreateTripModal
                      : _activeTab == 'drivers'
                          ? _openCreateDriverModal
                          : _activeTab == 'weighbridge'
                              ? _openCreateWeighbridgeModal
                              : _activeTab == 'routes'
                                  ? _openCreateRouteModal
                                  : _openCreateTempModal,
                  icon: const Icon(Icons.add, size: 15),
                  label: Text(
                    _activeTab == 'trips'
                        ? 'Trip'
                        : _activeTab == 'drivers'
                            ? 'Driver'
                            : _activeTab == 'weighbridge'
                                ? 'Slip'
                                : _activeTab == 'routes'
                                    ? 'Route'
                                    : 'Temp Log',
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ModuleKpiGrid(items: [
            ModuleKpiItem(label: 'Active In-Transit Trips', value: '$activeTrips', subtext: '${_trips.length} total trips', accentColor: const Color(0xFF2563EB), icon: Icons.local_shipping_outlined),
            ModuleKpiItem(label: 'Total Weight Dispatched', value: '${totalWeightMT.toStringAsFixed(1)} MT', subtext: 'Biomass & CBG', accentColor: const Color(0xFF16A34A), icon: Icons.scale_outlined),
            ModuleKpiItem(label: 'Drivers Available', value: '$availDrivers', subtext: '${_drivers.length} roster drivers', accentColor: const Color(0xFFD97706), icon: Icons.person_outline),
            ModuleKpiItem(label: 'Cold Chain Excursions', value: '$tempAlerts', subtext: '${_tempLogs.length} sensor logs', accentColor: const Color(0xFFDC2626), icon: Icons.thermostat_outlined),
          ]),
          const SizedBox(height: 14),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_activeTab == 'trips') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Vehicle Trip Sheets (${_trips.length})', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.download_outlined, color: Color(0xFF2563EB)),
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'trip_sheets.csv',
                    headers: const ['Trip #', 'Origin', 'Destination', 'Cargo', 'Vehicle', 'Driver', 'Qty (MT)', 'Status'],
                    rows: _trips.map((t) => [t['tripNumber'] ?? '', t['origin'] ?? '', t['destination'] ?? '', t['cargoCategory'] ?? '', t['assignedVehicle'] ?? '', t['assignedDriver'] ?? '', t['dispatchQtyMT'] ?? 0, t['status'] ?? '']).toList(),
                  ),
                ),
              ],
            ),
            if (_trips.isEmpty)
              const ModuleEmptyState(icon: Icons.local_shipping_outlined, title: 'No Trip Sheets Dispatched', subtitle: 'Bridge farm lots & processing facilities by generating a trip sheet.')
            else
              ..._trips.map((t) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ModuleTag(text: '${t['tripNumber'] ?? ''}', bgColor: const Color(0xFFEFF6FF), textColor: const Color(0xFF1D4ED8)),
                            const Spacer(),
                            ModuleTag(text: '${t['status'] ?? 'Dispatched'}', bgColor: const Color(0xFFDBEAFE), textColor: const Color(0xFF1D4ED8)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${t['origin'] ?? '-'} → ${t['destination'] ?? '-'}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800)),
                        Text('${t['cargoCategory'] ?? '-'} • ${t['dispatchQtyMT'] ?? 0} MT', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                        Text('Vehicle: ${t['assignedVehicle'] ?? '-'} • Driver: ${t['assignedDriver'] ?? '-'}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                        if (_perm.canDelete)
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 19),
                              onPressed: () async {
                                if (await _confirmDelete('${t['tripNumber']}')) {
                                  await SupplyChainApiService.deleteVehicleTripSheet(t['id']);
                                  await _loadAllData();
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  )),
          ] else if (_activeTab == 'drivers') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Driver Roster (${_drivers.length})', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.download_outlined, color: Color(0xFF2563EB)),
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'driver_roster.csv',
                    headers: const ['Name', 'Phone', 'License', 'Expiry', 'Hazmat', 'Vehicle', 'Duty Status'],
                    rows: _drivers.map((d) => [d['name'] ?? '', d['phone'] ?? '', d['licenseNumber'] ?? '', d['licenseExpiry'] ?? '', d['hazmatCertified'] == true ? 'Yes' : 'No', d['assignedVehicle'] ?? '', d['dutyStatus'] ?? '']).toList(),
                  ),
                ),
              ],
            ),
            if (_drivers.isEmpty)
              const ModuleEmptyState(icon: Icons.person_outline, title: 'No Commercial Drivers Registered', subtitle: 'Maintain heavy vehicle licenses, hazmat certs & duty status.')
            else
              ..._drivers.map((d) {
                final st = (d['dutyStatus'] ?? 'Available').toString();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('${d['name'] ?? '-'}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800))),
                          ModuleTag(
                            text: st,
                            bgColor: st == 'Available' ? const Color(0xFFD1FAE5) : const Color(0xFFDBEAFE),
                            textColor: st == 'Available' ? const Color(0xFF059669) : const Color(0xFF1D4ED8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('License: ${d['licenseNumber'] ?? '-'} (Exp: ${d['licenseExpiry'] ?? '-'})', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                      Text('Phone: ${d['phone'] ?? '-'} • Truck: ${d['assignedVehicle'] ?? '-'}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ModuleTag(
                            text: d['hazmatCertified'] == true ? 'CBG Hazmat Certified' : 'Standard HCV',
                            bgColor: d['hazmatCertified'] == true ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                            textColor: d['hazmatCertified'] == true ? const Color(0xFF059669) : const Color(0xFF475569),
                          ),
                          const Spacer(),
                          if (_perm.canDelete)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 19),
                              onPressed: () async {
                                if (await _confirmDelete('${d['name']}')) {
                                  await SupplyChainApiService.deleteDriver(d['id']);
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
          ] else if (_activeTab == 'weighbridge') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Weighbridge Slip Logs (${_weighbridgeSlips.length})', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.download_outlined, color: Color(0xFF2563EB)),
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'fleet_weighbridge_slips.csv',
                    headers: const ['Slip #', 'Trip Ref', 'Vehicle', 'Gross (MT)', 'Tare (MT)', 'Net (MT)', 'Timestamp', 'Status'],
                    rows: _weighbridgeSlips.map((w) => [w['slipNumber'] ?? '', w['tripNumber'] ?? '', w['vehicleNo'] ?? '', w['inboundGrossMT'] ?? 0, w['outboundTareMT'] ?? 0, w['netWeightMT'] ?? 0, w['scaleTimestamp'] ?? '', w['status'] ?? '']).toList(),
                  ),
                ),
              ],
            ),
            if (_weighbridgeSlips.isEmpty)
              const ModuleEmptyState(icon: Icons.scale_outlined, title: 'No Weighbridge Slips Recorded', subtitle: 'Reconcile gross, tare, and net tonnage for fleet movements.')
            else
              ..._weighbridgeSlips.map((w) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ModuleTag(text: '${w['slipNumber'] ?? ''}', bgColor: const Color(0xFFEFF6FF), textColor: const Color(0xFF1D4ED8)),
                            const SizedBox(width: 6),
                            ModuleTag(text: '${w['tripNumber'] ?? ''}', bgColor: const Color(0xFFF1F5F9), textColor: const Color(0xFF334155)),
                            const Spacer(),
                            ModuleTag(text: '${w['status'] ?? 'Verified & Stamped'}', bgColor: const Color(0xFFD1FAE5), textColor: const Color(0xFF059669)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Vehicle: ${w['vehicleNo'] ?? '-'} • Net: ${w['netWeightMT'] ?? 0} MT', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800)),
                        Text('Gross: ${w['inboundGrossMT'] ?? 0} MT | Tare: ${w['outboundTareMT'] ?? 0} MT | ${w['scaleTimestamp'] ?? ''}',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(onPressed: () => _openWeighbridgeCertificate(w), icon: const Icon(Icons.print_outlined, size: 16), label: const Text('Certificate')),
                            if (_perm.canDelete)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 19),
                                onPressed: () async {
                                  if (await _confirmDelete('${w['slipNumber']}')) {
                                    await SupplyChainApiService.deleteLogisticsWeighbridgeSlip(w['id']);
                                    await _loadAllData();
                                  }
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  )),
          ] else if (_activeTab == 'routes') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Live Fleet Dispatch Corridors (${_routes.length})', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                if (_perm.canCreate)
                  TextButton.icon(
                    onPressed: _openCreateRouteModal,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Route'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_routes.isEmpty)
              const ModuleEmptyState(icon: Icons.navigation_outlined, title: 'No Route Corridors', subtitle: 'Add a new dispatch corridor to track transit telemetry.')
            else
              ..._routes.map((r) => _buildCorridorCard(
                    badge: r['badge'] ?? 'Corridor',
                    color: r['color'] as Color? ?? const Color(0xFF2563EB),
                    title: r['title'] ?? '',
                    meta: r['meta'] ?? '',
                    vehicle: r['vehicle'] ?? '',
                    speed: r['speed'] ?? '',
                    driver: r['driver'] ?? '',
                    eta: r['eta'] ?? '',
                    progress: (r['progress'] is num) ? (r['progress'] as num).toDouble() : 0.5,
                  )),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transit Temperature Telemetry (${_tempLogs.length})', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.download_outlined, color: Color(0xFF2563EB)),
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'temperature_logs.csv',
                    headers: const ['Sensor Tag', 'Trip Ref', 'Cargo Type', 'Current Temp C', 'Max Safe C', 'Ambient C', 'Status'],
                    rows: _tempLogs.map((l) => [l['sensorTag'] ?? '', l['tripNumber'] ?? '', l['cargoType'] ?? '', l['currentTempC'] ?? 0, l['maxThresholdC'] ?? 0, l['ambientTempC'] ?? 0, l['status'] ?? '']).toList(),
                  ),
                ),
              ],
            ),
            if (_tempLogs.isEmpty)
              const ModuleEmptyState(icon: Icons.thermostat_outlined, title: 'No Temperature Logs Recorded', subtitle: 'Prevent feedstock self-heating through IoT sensor temperature logs.')
            else
              ..._tempLogs.map((l) {
                final st = (l['status'] ?? 'Optimal').toString();
                final isCrit = st.contains('Critical');
                final isWarn = st.contains('Warning');
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ModuleTag(text: '${l['sensorTag'] ?? ''}', bgColor: const Color(0xFFEFF6FF), textColor: const Color(0xFF1D4ED8)),
                          const SizedBox(width: 6),
                          ModuleTag(text: '${l['tripNumber'] ?? ''}', bgColor: const Color(0xFFF1F5F9), textColor: const Color(0xFF334155)),
                          const Spacer(),
                          ModuleTag(
                            text: st,
                            bgColor: isCrit ? const Color(0xFFFEE2E2) : (isWarn ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5)),
                            textColor: isCrit ? const Color(0xFFDC2626) : (isWarn ? const Color(0xFFD97706) : const Color(0xFF059669)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${l['cargoType'] ?? '-'} • Reading: ${l['currentTempC'] ?? 0}°C',
                          style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800, color: isCrit ? const Color(0xFFDC2626) : const Color(0xFF0F172A))),
                      Text('Max Safe: ${l['maxThresholdC'] ?? 0}°C | Ambient: ${l['ambientTempC'] ?? 0}°C',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                      if (_perm.canDelete)
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 19),
                            onPressed: () async {
                              if (await _confirmDelete('${l['sensorTag']}')) {
                                await SupplyChainApiService.deleteTransitTemperatureLog(l['id']);
                                await _loadAllData();
                              }
                            },
                          ),
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
      onSelectSubmodule: (k) => setState(() => _activeTab = k),
      hasAccess: _perm.canView,
      isLoadingPermissions: _isLoadingPerm,
      accessDeniedMessage: 'You do not have view permissions for the Fleet & Dispatch Logistics module. Please contact your system administrator.',
      child: _buildTabContent(),
    );
  }
}
