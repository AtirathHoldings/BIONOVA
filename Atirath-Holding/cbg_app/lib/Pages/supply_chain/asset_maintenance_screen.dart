import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/rbac_service.dart';
import '../../services/supply_chain_api_service.dart';
import '../../widgets/module_ui_widgets.dart';

class AssetMaintenanceScreen extends StatefulWidget {
  final String initialTab;

  const AssetMaintenanceScreen({super.key, this.initialTab = 'assets'});

  @override
  State<AssetMaintenanceScreen> createState() => _AssetMaintenanceScreenState();
}

class _AssetMaintenanceScreenState extends State<AssetMaintenanceScreen> {
  static const List<ModuleSubmoduleItem> _tabs = [
    ModuleSubmoduleItem(key: 'assets', title: 'Asset Maintenance (CMMS)', shortLabel: 'Assets Registry', icon: Icons.precision_manufacturing_outlined),
    ModuleSubmoduleItem(key: 'schedules', title: 'Asset Maintenance (CMMS)', shortLabel: 'PM Schedules', icon: Icons.schedule_outlined),
    ModuleSubmoduleItem(key: 'incidents', title: 'Asset Maintenance (CMMS)', shortLabel: 'Breakdowns', icon: Icons.warning_amber_rounded),
    ModuleSubmoduleItem(key: 'costs', title: 'Asset Maintenance (CMMS)', shortLabel: 'Servicing Costs', icon: Icons.currency_rupee),
  ];

  static final NumberFormat _inrFmt = NumberFormat('#,##,##0', 'en_IN');

  late String _activeTab;
  ScreenPermission _perm = ScreenPermission.full;
  bool _isLoadingPerm = true;
  bool _isLoading = true;

  List<Map<String, dynamic>> _plants = [];
  List<Map<String, dynamic>> _assets = [];
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _incidents = [];
  List<Map<String, dynamic>> _costLogs = [];

  @override
  void initState() {
    super.initState();
    _activeTab = _tabs.any((t) => t.key == widget.initialTab) ? widget.initialTab : 'assets';
    _initLoad();
  }

  Future<void> _initLoad() async {
    final perm = await RbacService.getScreenPermission('ASSET_MAINTENANCE');
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
      SupplyChainApiService.getMachineryAssets(),
      SupplyChainApiService.getMaintenanceSchedules(),
      SupplyChainApiService.getBreakdownIncidents(),
      SupplyChainApiService.getServicingCostLogs(),
      SupplyChainApiService.getPlants(),
    ]);
    if (mounted) {
      setState(() {
        _assets = results[0];
        _schedules = results[1];
        _incidents = results[2];
        _costLogs = results[3];
        _plants = results[4];
        _isLoading = false;
      });
    }
  }

  double _num(dynamic v) => double.tryParse((v ?? '0').toString()) ?? 0;

  String _fmtInr(dynamic v) => '₹${_inrFmt.format(_num(v).round())}';

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
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return str;
    }
  }

  String _criticalityLabel(String? crit) {
    final c = (crit ?? '').trim();
    if (c.isEmpty) return 'Standard Auxiliary';
    if (c.startsWith('A') || c.toLowerCase().contains('critical')) return 'Critical Asset';
    if (c.startsWith('B') || c.toLowerCase().contains('essential')) return 'Essential Asset';
    if (c.startsWith('C') || c.toLowerCase().contains('standard') || c.toLowerCase().contains('auxiliary')) return 'Standard Auxiliary';
    return c;
  }

  String _generateNextAssetTag() {
    final currentYear = DateTime.now().year;
    final prefix = 'AST-$currentYear-';
    int maxSeq = 0;
    for (final a in _assets) {
      final code = (a['assetCode'] ?? a['asset_code'] ?? '').toString();
      if (code.startsWith(prefix)) {
        final digits = code.substring(prefix.length).replaceAll(RegExp(r'[^0-9]'), '');
        final val = int.tryParse(digits) ?? 0;
        if (val > maxSeq) maxSeq = val;
      }
    }
    return 'AST-$currentYear-${(maxSeq + 1).toString().padLeft(4, '0')}';
  }

  void _viewAssetDetails(Map<String, dynamic> a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.precision_manufacturing_outlined, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                a['assetCode']?.toString() ?? 'Asset Details',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Equipment Name', a['name']?.toString() ?? '—'),
              _detailRow('Category', a['category']?.toString() ?? '—'),
              _detailRow('Plant Facility', a['facility']?.toString() ?? '—'),
              _detailRow('OEM Manufacturer', a['oemManufacturer']?.toString() ?? '—'),
              _detailRow('Model & Serial', a['modelSerial']?.toString() ?? '—'),
              _detailRow('Commissioning Date', _formatToDDMMYYYY(a['commissionDate'])),
              _detailRow('Criticality', _criticalityLabel(a['criticality']?.toString())),
              _detailRow('Status', a['operatingStatus']?.toString() ?? 'Operational'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)))),
        ],
      ),
    );
  }

  List<String> _plantOptions() {
    final names = _plants
        .map((p) => (p['plantNm'] ?? p['name'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (names.isEmpty) names.add('Plant 1 - Hyderabad East CBG');
    return names;
  }

  List<String> _assetOptions(String fallback) {
    final names = _assets
        .map((a) => (a['name'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (names.isEmpty) names.add(fallback);
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

  void _openCreateAssetModal([Map<String, dynamic>? editing]) {
    final nextTag = _generateNextAssetTag();
    final plantList = _plantOptions();
    final formKey = GlobalKey<FormState>();

    final codeCtrl = TextEditingController(text: editing != null ? (editing['assetCode'] ?? editing['asset_code'] ?? nextTag).toString() : nextTag);
    final nameCtrl = TextEditingController(text: editing != null ? (editing['name'] ?? '').toString() : '');
    String category = (editing != null && editing['category'] != null) ? editing['category'].toString() : 'Anaerobic Digester & Agitators';
    String facility = (editing != null && editing['facility'] != null) ? editing['facility'].toString() : plantList.first;
    final oemCtrl = TextEditingController(text: editing != null ? (editing['oemManufacturer'] ?? '').toString() : 'Linde / Neuman & Esser');
    final serialCtrl = TextEditingController(text: editing != null ? (editing['modelSerial'] ?? '').toString() : 'NEA-CBG-450');
    final dateCtrl = TextEditingController(text: editing != null ? _formatToDDMMYYYY(editing['commissionDate']) : _formatToDDMMYYYY(DateTime.now()));
    String criticality = _criticalityLabel(editing != null ? editing['criticality']?.toString() : 'Critical Asset');
    String status = (editing != null && editing['operatingStatus'] != null) ? editing['operatingStatus'].toString() : 'Operational';

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
                      const Icon(Icons.precision_manufacturing_outlined, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(editing != null ? 'Edit Machinery Asset' : 'Register Machinery Asset', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: codeCtrl,
                    readOnly: true,
                    decoration: moduleInputDecoration('Asset Identification Tag * (Auto)').copyWith(fillColor: const Color(0xFFF8FAFC), filled: true),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: moduleInputDecoration('Machine / Asset Name *', hint: 'Primary Bio-Gas CSTR Digester Agitator'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (RegExp(r'[0-9]').hasMatch(v)) return 'Numbers not allowed in name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Asset Category'),
                    items: const [
                      DropdownMenuItem(value: 'Harvesting Tractors & Farm Machinery', child: Text('Harvesting Tractors & Farm Machinery')),
                      DropdownMenuItem(value: 'Anaerobic Digester & Agitators', child: Text('Anaerobic Digester & Agitators')),
                      DropdownMenuItem(value: 'Gas Upgradation & Compressors', child: Text('Gas Upgradation & Compressors')),
                      DropdownMenuItem(value: 'Cold Storages & Chilling Plants', child: Text('Cold Storages & Chilling Plants')),
                      DropdownMenuItem(value: 'Power Generators & Cogeneration', child: Text('Power Generators & Cogeneration')),
                    ],
                    onChanged: (v) => setModalState(() => category = v ?? category),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: facility,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Plant Facility'),
                    items: plantList.map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setModalState(() => facility = v ?? facility),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: oemCtrl,
                          decoration: moduleInputDecoration('OEM Manufacturer'),
                          validator: (v) {
                            if (v != null && RegExp(r'[0-9]').hasMatch(v)) return 'Numbers not allowed';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: serialCtrl,
                          decoration: moduleInputDecoration('Model / Serial *'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: dateCtrl,
                          readOnly: true,
                          decoration: moduleInputDecoration('Commissioning Date *').copyWith(
                            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setModalState(() {
                                dateCtrl.text = _formatToDDMMYYYY(picked);
                              });
                            }
                          },
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: criticality,
                          isExpanded: true,
                          decoration: moduleInputDecoration('Criticality'),
                          items: const [
                            DropdownMenuItem(value: 'Critical Asset', child: Text('Critical Asset')),
                            DropdownMenuItem(value: 'Essential Asset', child: Text('Essential Asset')),
                            DropdownMenuItem(value: 'Standard Auxiliary', child: Text('Standard Auxiliary')),
                          ],
                          onChanged: (v) => setModalState(() => criticality = v ?? criticality),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: moduleInputDecoration('Operating Status'),
                    items: const [
                      DropdownMenuItem(value: 'Operational', child: Text('Operational')),
                      DropdownMenuItem(value: 'Maintenance Due', child: Text('Maintenance Due')),
                      DropdownMenuItem(value: 'Under Breakdown', child: Text('Under Breakdown')),
                      DropdownMenuItem(value: 'Decommissioned', child: Text('Decommissioned')),
                    ],
                    onChanged: (v) => setModalState(() => status = v ?? status),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        await SupplyChainApiService.saveMachineryAsset({
                          if (editing != null && editing['id'] != null) 'id': editing['id'],
                          'assetCode': codeCtrl.text.trim(),
                          'name': nameCtrl.text.trim(),
                          'category': category,
                          'facility': facility,
                          'oemManufacturer': oemCtrl.text.trim(),
                          'modelSerial': serialCtrl.text.trim(),
                          'commissionDate': dateCtrl.text.trim(),
                          'criticality': criticality,
                          'operatingStatus': status,
                        });
                        await _loadAllData();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: Text(editing != null ? 'Update Machinery Record' : 'Save Machinery Record'),
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

  void _openCreateScheduleModal() {
    final nextSeq = (_schedules.length + 1).toString().padLeft(4, '0');
    final assetList = _assetOptions('High-Pressure CBG Compressor Train 1');
    final formKey = GlobalKey<FormState>();

    final codeCtrl = TextEditingController(text: 'PMS-2026-$nextSeq');
    String assetName = assetList.first;
    String frequency = 'Monthly Overhaul & Calibration';
    final dueCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 10)).toIso8601String().split('T').first);
    final techCtrl = TextEditingController(text: 'Suresh Reddy (Lead Reliability Engineer)');
    final checklistCtrl = TextEditingController(text: '1. Inspect oil seals & lubricant levels\n2. Calibrate pressure transducer transmitters\n3. Check gas sensor alarms & valves');

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
                      const Icon(Icons.schedule_outlined, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Configure Preventive Maintenance (PM)', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: codeCtrl, decoration: moduleInputDecoration('PM Schedule Code *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: assetName,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Select Machinery Asset *'),
                    items: assetList.map((a) => DropdownMenuItem(value: a, child: Text(a, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setModalState(() => assetName = v ?? assetName),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: frequency,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Inspection Frequency'),
                    items: const [
                      DropdownMenuItem(value: 'Daily Inspection', child: Text('Daily Operator Inspection')),
                      DropdownMenuItem(value: 'Weekly Lubrication', child: Text('Weekly Lubrication & Seals')),
                      DropdownMenuItem(value: 'Monthly Overhaul & Calibration', child: Text('Monthly Overhaul & Calibration')),
                      DropdownMenuItem(value: 'Running Meter: 500 Hrs', child: Text('Running Meter: 500 Hours')),
                      DropdownMenuItem(value: 'Running Meter: 2000 Hrs', child: Text('Running Meter: 2,000 Hours Major AMC')),
                    ],
                    onChanged: (v) => setModalState(() => frequency = v ?? frequency),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: dueCtrl, decoration: moduleInputDecoration('Next Due Date *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null)),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: techCtrl, decoration: moduleInputDecoration('Lead Technician'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: checklistCtrl, maxLines: 3, decoration: moduleInputDecoration('Mandatory Checklist Steps (SOP)')),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        await SupplyChainApiService.saveMaintenanceSchedule({
                          'scheduleCode': codeCtrl.text.trim(),
                          'assetName': assetName,
                          'facility': _plantOptions().first,
                          'frequency': frequency,
                          'nextDueDate': dueCtrl.text.trim(),
                          'meterThresholdHrs': 500,
                          'checklistItems': checklistCtrl.text.trim(),
                          'leadTechnician': techCtrl.text.trim(),
                          'status': 'Upcoming',
                        });
                        await _loadAllData();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('Save PM Schedule'),
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

  void _openCreateIncidentModal() {
    final nextSeq = (_incidents.length + 1).toString().padLeft(4, '0');
    final assetList = _assetOptions('Primary CSTR Biogas Digester Agitator #2');
    final formKey = GlobalKey<FormState>();

    final ticketCtrl = TextEditingController(text: 'INC-2026-$nextSeq');
    String assetName = assetList.first;
    String severity = 'Major (Process Bottleneck)';
    final downtimeCtrl = TextEditingController(text: '2.5');
    final symptomCtrl = TextEditingController(text: 'High mechanical vibration detected on agitator gear unit.');
    final rcaCtrl = TextEditingController(text: 'Flushed gearbox, installed high-temp synthetic gear oil, and re-torqued motor bolts.');

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
                      const Icon(Icons.local_fire_department_outlined, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Log Unscheduled Breakdown Incident', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: ticketCtrl, decoration: moduleInputDecoration('Incident Ticket # *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: assetName,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Affected Machinery Asset *'),
                    items: assetList.map((a) => DropdownMenuItem(value: a, child: Text(a, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setModalState(() => assetName = v ?? assetName),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: severity,
                          isExpanded: true,
                          decoration: moduleInputDecoration('Severity Level'),
                          items: const [
                            DropdownMenuItem(value: 'Critical (Plant Trip Risk)', child: Text('Critical (Plant Trip)')),
                            DropdownMenuItem(value: 'Major (Process Bottleneck)', child: Text('Major (Bottleneck)')),
                            DropdownMenuItem(value: 'Minor (Auxiliary Fault)', child: Text('Minor (Auxiliary)')),
                          ],
                          onChanged: (v) => setModalState(() => severity = v ?? severity),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: downtimeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: moduleInputDecoration('Downtime (Hrs)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: symptomCtrl, maxLines: 2, decoration: moduleInputDecoration('Failure Symptom *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 10),
                  TextFormField(controller: rcaCtrl, maxLines: 2, decoration: moduleInputDecoration('RCA & Corrective Action')),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        await SupplyChainApiService.saveBreakdownIncident({
                          'ticketNumber': ticketCtrl.text.trim(),
                          'facility': _plantOptions().first,
                          'assetName': assetName,
                          'reportedTime': DateTime.now().toIso8601String().substring(0, 16),
                          'severity': severity,
                          'symptomDescription': symptomCtrl.text.trim(),
                          'downtimeHours': double.tryParse(downtimeCtrl.text.trim()) ?? 0,
                          'correctiveAction': rcaCtrl.text.trim(),
                          'status': 'In Progress / Under Repair',
                        });
                        await _loadAllData();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('Log Incident & Notify Team'),
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

  void _openCreateCostModal() {
    final nextSeq = (_costLogs.length + 1).toString().padLeft(4, '0');
    final assetList = _assetOptions('Heavy-Duty Harvesting Biomass Tractor');
    final formKey = GlobalKey<FormState>();

    final logCtrl = TextEditingController(text: 'CST-2026-$nextSeq');
    String assetName = assetList.first;
    String serviceNature = 'Emergency Breakdown Repair';
    final dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T').first);
    final sparesCostCtrl = TextEditingController(text: '18500');
    final laborCostCtrl = TextEditingController(text: '4500');
    final vendorFeeCtrl = TextEditingController(text: '7000');
    final vendorCtrl = TextEditingController(text: 'Mahindra & Mahindra Authorized Heavy Farm Service Center');
    final sparesDescCtrl = TextEditingController(text: 'High-Pressure Hydraulic Hose & Coupling O-Rings');

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
                      const Icon(Icons.currency_rupee, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Record Servicing Cost & Spares', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: logCtrl, decoration: moduleInputDecoration('Service Log # *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: assetName,
                    isExpanded: true,
                    decoration: moduleInputDecoration('Serviced Machinery Asset *'),
                    items: assetList.map((a) => DropdownMenuItem(value: a, child: Text(a, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setModalState(() => assetName = v ?? assetName),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: serviceNature,
                          isExpanded: true,
                          decoration: moduleInputDecoration('Nature of Service'),
                          items: const [
                            DropdownMenuItem(value: 'Preventive Routine Service', child: Text('Preventive Routine')),
                            DropdownMenuItem(value: 'Emergency Breakdown Repair', child: Text('Emergency Breakdown')),
                            DropdownMenuItem(value: 'Annual Overhaul AMC', child: Text('Annual Overhaul AMC')),
                          ],
                          onChanged: (v) => setModalState(() => serviceNature = v ?? serviceNature),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: dateCtrl, decoration: moduleInputDecoration('Service Date'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: sparesCostCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Spares (₹)'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(controller: laborCostCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Labor (₹)'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(controller: vendorFeeCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Vendor Fee (₹)'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: vendorCtrl, decoration: moduleInputDecoration('External Service Provider')),
                  const SizedBox(height: 10),
                  TextFormField(controller: sparesDescCtrl, decoration: moduleInputDecoration('Spare Parts Description')),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final sc = double.tryParse(sparesCostCtrl.text.trim()) ?? 0;
                        final lc = double.tryParse(laborCostCtrl.text.trim()) ?? 0;
                        final vc = double.tryParse(vendorFeeCtrl.text.trim()) ?? 0;
                        await SupplyChainApiService.saveServicingCostLog({
                          'logNumber': logCtrl.text.trim(),
                          'assetName': assetName,
                          'facility': _plantOptions().first,
                          'serviceDate': dateCtrl.text.trim(),
                          'serviceNature': serviceNature,
                          'sparesConsumed': sparesDescCtrl.text.trim(),
                          'sparesCost': sc,
                          'laborCost': lc,
                          'externalVendorFee': vc,
                          'totalCost': sc + lc + vc,
                          'servicingVendor': vendorCtrl.text.trim(),
                        });
                        await _loadAllData();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('Save Cost Ledger Entry'),
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
    final activeBreakdowns = _incidents.where((i) => i['status'] != 'Closed' && i['status'] != 'Resolved').length;
    final upcomingPms = _schedules.where((s) => s['status'] == 'Upcoming' || s['status'] == 'Due').length;
    final totalMaintCost = _costLogs.fold<double>(0, (s, c) => s + _num(c['totalCost']));

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
                    Text('Equipment & Asset Maintenance (CMMS)', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('Plant machinery registry, PM schedules, breakdown incidents & costs', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              if (_perm.canCreate)
                ElevatedButton.icon(
                  onPressed: _activeTab == 'assets'
                      ? _openCreateAssetModal
                      : _activeTab == 'schedules'
                          ? _openCreateScheduleModal
                          : _activeTab == 'incidents'
                              ? _openCreateIncidentModal
                              : _openCreateCostModal,
                  icon: Icon(_activeTab == 'incidents' ? Icons.local_fire_department_outlined : Icons.add, size: 15),
                  label: Text(
                    _activeTab == 'assets'
                        ? 'Asset'
                        : _activeTab == 'schedules'
                            ? 'PM'
                            : _activeTab == 'incidents'
                                ? 'Incident'
                                : 'Cost',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _activeTab == 'incidents' ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ModuleKpiGrid(items: [
            ModuleKpiItem(label: 'Machinery Assets', value: '${_assets.length}', subtext: 'Registered infrastructure', accentColor: const Color(0xFF2563EB), icon: Icons.precision_manufacturing_outlined),
            ModuleKpiItem(label: 'Active Breakdowns', value: '$activeBreakdowns', subtext: '${_incidents.length} total incidents', accentColor: const Color(0xFFDC2626), icon: Icons.warning_amber_rounded),
            ModuleKpiItem(label: 'Scheduled PMs Due', value: '$upcomingPms', subtext: '${_schedules.length} total schedules', accentColor: const Color(0xFFD97706), icon: Icons.schedule_outlined),
            ModuleKpiItem(label: 'Cumulative Servicing Cost', value: _fmtInr(totalMaintCost), subtext: '${_costLogs.length} cost logs', accentColor: const Color(0xFF16A34A), icon: Icons.currency_rupee),
          ]),
          const SizedBox(height: 14),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_activeTab == 'assets') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Machinery Directory (${_assets.length})', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.download_outlined, color: Color(0xFF2563EB)),
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'plant_machinery_assets.csv',
                    headers: const ['Asset Tag', 'Name', 'Category', 'Facility', 'OEM', 'Model', 'Criticality', 'Status'],
                    rows: _assets.map((a) => [a['assetCode'] ?? '', a['name'] ?? '', a['category'] ?? '', a['facility'] ?? '', a['oemManufacturer'] ?? '', a['modelSerial'] ?? '', a['criticality'] ?? '', a['operatingStatus'] ?? '']).toList(),
                  ),
                ),
              ],
            ),
            if (_assets.isEmpty)
              const ModuleEmptyState(icon: Icons.precision_manufacturing_outlined, title: 'No Machinery Registered Yet', subtitle: 'Track plant tractors, bio-digesters & compressors by registering an asset.')
            else
              ..._assets.map((a) {
                final crit = (a['criticality'] ?? 'A').toString();
                final op = (a['operatingStatus'] ?? 'Operational').toString();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ModuleTag(text: '${a['assetCode'] ?? ''}', bgColor: const Color(0xFFEFF6FF), textColor: const Color(0xFF1D4ED8)),
                          const SizedBox(width: 6),
                          ModuleTag(
                            text: _criticalityLabel(crit),
                            bgColor: (crit.startsWith('A') || crit.toLowerCase().contains('critical')) ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                            textColor: (crit.startsWith('A') || crit.toLowerCase().contains('critical')) ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                          ),
                          const Spacer(),
                          ModuleTag(
                            text: op,
                            bgColor: op == 'Operational' ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                            textColor: op == 'Operational' ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${a['name'] ?? '-'}', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800)),
                      Text('${a['category'] ?? '-'} • ${a['facility'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                      Text('OEM: ${a['oemManufacturer'] ?? '-'} (${a['modelSerial'] ?? '-'})', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, color: Color(0xFF2563EB), size: 20),
                            tooltip: 'View Asset Details',
                            onPressed: () => _viewAssetDetails(a),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF475569), size: 20),
                            tooltip: 'Edit Machinery Details',
                            onPressed: () => _openCreateAssetModal(a),
                          ),
                          if (_perm.canDelete)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
                              tooltip: 'Delete Asset',
                              onPressed: () async {
                                if (await _confirmDelete('${a['name']}')) {
                                  await SupplyChainApiService.deleteMachineryAsset(a['id']);
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
          ] else if (_activeTab == 'schedules') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Preventive Maintenance Schedules (${_schedules.length})', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.download_outlined, color: Color(0xFF2563EB)),
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'pm_schedules.csv',
                    headers: const ['Schedule Code', 'Asset', 'Frequency', 'Next Due', 'Technician', 'Status'],
                    rows: _schedules.map((s) => [s['scheduleCode'] ?? '', s['assetName'] ?? '', s['frequency'] ?? '', s['nextDueDate'] ?? '', s['leadTechnician'] ?? '', s['status'] ?? '']).toList(),
                  ),
                ),
              ],
            ),
            if (_schedules.isEmpty)
              const ModuleEmptyState(icon: Icons.schedule_outlined, title: 'No PM Schedules Configured', subtitle: 'Establish routine servicing intervals to prevent un-planned outages.')
            else
              ..._schedules.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ModuleTag(text: '${s['scheduleCode'] ?? ''}', bgColor: const Color(0xFFEFF6FF), textColor: const Color(0xFF1D4ED8)),
                            const Spacer(),
                            ModuleTag(text: '${s['status'] ?? 'Upcoming'}', bgColor: const Color(0xFFDBEAFE), textColor: const Color(0xFF1D4ED8)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${s['assetName'] ?? '-'}', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800)),
                        Text('${s['frequency'] ?? '-'} • Due: ${s['nextDueDate'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                        Text('Lead Engineer: ${s['leadTechnician'] ?? '-'}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                        if (_perm.canDelete)
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 19),
                              onPressed: () async {
                                if (await _confirmDelete('${s['scheduleCode']}')) {
                                  await SupplyChainApiService.deleteMaintenanceSchedule(s['id']);
                                  await _loadAllData();
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  )),
          ] else if (_activeTab == 'incidents') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Breakdown Incidents (${_incidents.length})', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.download_outlined, color: Color(0xFF2563EB)),
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'breakdown_incidents.csv',
                    headers: const ['Ticket #', 'Asset', 'Severity', 'Reported Time', 'Downtime Hrs', 'Symptom', 'Status'],
                    rows: _incidents.map((i) => [i['ticketNumber'] ?? '', i['assetName'] ?? '', i['severity'] ?? '', i['reportedTime'] ?? '', i['downtimeHours'] ?? 0, i['symptomDescription'] ?? '', i['status'] ?? '']).toList(),
                  ),
                ),
              ],
            ),
            if (_incidents.isEmpty)
              const ModuleEmptyState(icon: Icons.warning_amber_rounded, title: 'No Breakdowns Reported', subtitle: 'All machinery is operating within parameters without downtime incidents.')
            else
              ..._incidents.map((i) {
                final sev = (i['severity'] ?? '').toString();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ModuleTag(text: '${i['ticketNumber'] ?? ''}', bgColor: const Color(0xFFFEE2E2), textColor: const Color(0xFFDC2626)),
                          const SizedBox(width: 6),
                          ModuleTag(
                            text: sev.split(' ').first,
                            bgColor: sev.startsWith('Critical') ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                            textColor: sev.startsWith('Critical') ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                          ),
                          const Spacer(),
                          ModuleTag(text: '${i['downtimeHours'] ?? 0}h downtime', bgColor: const Color(0xFFFEF3C7), textColor: const Color(0xFFD97706)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${i['assetName'] ?? '-'}', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800)),
                      Text('${i['symptomDescription'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                      Text('Status: ${i['status'] ?? '-'} • ${i['reportedTime'] ?? '-'}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                      if (_perm.canDelete)
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 19),
                            onPressed: () async {
                              if (await _confirmDelete('${i['ticketNumber']}')) {
                                await SupplyChainApiService.deleteBreakdownIncident(i['id']);
                                await _loadAllData();
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                );
              }),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Servicing Costs & Spares (${_costLogs.length})', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.download_outlined, color: Color(0xFF2563EB)),
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'servicing_costs.csv',
                    headers: const ['Log #', 'Asset', 'Nature', 'Date', 'Spares Cost', 'Labor Cost', 'Vendor Fee', 'Total Cost', 'Vendor'],
                    rows: _costLogs.map((c) => [c['logNumber'] ?? '', c['assetName'] ?? '', c['serviceNature'] ?? '', c['serviceDate'] ?? '', c['sparesCost'] ?? 0, c['laborCost'] ?? 0, c['externalVendorFee'] ?? 0, c['totalCost'] ?? 0, c['servicingVendor'] ?? '']).toList(),
                  ),
                ),
              ],
            ),
            if (_costLogs.isEmpty)
              const ModuleEmptyState(icon: Icons.currency_rupee, title: 'No Cost Entries Found', subtitle: 'Track cumulative repair expenses, spare usage & service fees.')
            else
              ..._costLogs.map((c) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ModuleTag(text: '${c['logNumber'] ?? ''}', bgColor: const Color(0xFFEFF6FF), textColor: const Color(0xFF1D4ED8)),
                            const Spacer(),
                            Text(_fmtInr(c['totalCost']), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${c['assetName'] ?? '-'}', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800)),
                        Text('${c['serviceNature'] ?? '-'} • ${c['serviceDate'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                        Text('Spares: ${_fmtInr(c['sparesCost'])} | Labor: ${_fmtInr(c['laborCost'])} • Vendor: ${c['servicingVendor'] ?? 'In-House'}',
                            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                        if (_perm.canDelete)
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 19),
                              onPressed: () async {
                                if (await _confirmDelete('${c['logNumber']}')) {
                                  await SupplyChainApiService.deleteServicingCostLog(c['id']);
                                  await _loadAllData();
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  )),
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
      accessDeniedMessage: 'You do not have view permissions for the Equipment & Asset Maintenance module. Please contact your administrator.',
      child: _buildTabContent(),
    );
  }
}
