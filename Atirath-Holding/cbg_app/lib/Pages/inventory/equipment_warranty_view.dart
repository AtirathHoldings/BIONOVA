import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/inventory_api_service.dart';
import '../../services/rbac_service.dart';
import '../../widgets/module_ui_widgets.dart';

class EquipmentWarrantyView extends StatefulWidget {
  final ScreenPermission screenPerm;

  const EquipmentWarrantyView({super.key, required this.screenPerm});

  @override
  State<EquipmentWarrantyView> createState() => _EquipmentWarrantyViewState();
}

class _EquipmentWarrantyViewState extends State<EquipmentWarrantyView> {
  List<Map<String, dynamic>> _warranties = [];
  bool _isLoading = true;
  String _searchTerm = '';
  String _statusFilter = 'All';
  String _oemFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final local = await InventoryApiService.loadLocalList(InventoryStorageKeys.warranties);
    if (mounted) {
      setState(() {
        _warranties = local;
        _isLoading = false;
      });
    }
  }

  int _daysRemaining(dynamic endDateStr) {
    if (endDateStr == null || endDateStr.toString().isEmpty) return 0;
    final target = DateTime.tryParse(endDateStr.toString());
    if (target == null) return 0;
    final today = DateTime(2026, 11, 2);
    return target.difference(today).inDays;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchTerm.toLowerCase();
    return _warranties.where((item) {
      final matchesSearch = (item['assetTag'] ?? '').toString().toLowerCase().contains(q) ||
          (item['machineName'] ?? '').toString().toLowerCase().contains(q) ||
          (item['serialNo'] ?? '').toString().toLowerCase().contains(q) ||
          (item['oem'] ?? '').toString().toLowerCase().contains(q) ||
          (item['contractType'] ?? '').toString().toLowerCase().contains(q) ||
          (item['plantLocation'] ?? '').toString().toLowerCase().contains(q);
      final matchesStatus = _statusFilter == 'All' || item['status'] == _statusFilter;
      final matchesOem = _oemFilter == 'All' || (item['oem'] ?? '').toString().contains(_oemFilter);
      return matchesSearch && matchesStatus && matchesOem;
    }).toList();
  }

  void _openForm({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final tagCtrl = TextEditingController(text: isEdit ? (existing['assetTag'] ?? '').toString() : 'EQ-NEW-${ts.substring(ts.length - 3)}');
    final nameCtrl = TextEditingController(text: isEdit ? (existing['machineName'] ?? '').toString() : '');
    final serialCtrl = TextEditingController(text: isEdit ? (existing['serialNo'] ?? '').toString() : '');
    final oemCtrl = TextEditingController(text: isEdit ? (existing['oem'] ?? '').toString() : '');
    final commCtrl = TextEditingController(text: isEdit ? (existing['commissionDate'] ?? '2025-03-01').toString() : '2025-03-01');
    final startCtrl = TextEditingController(text: isEdit ? (existing['warrantyStartDate'] ?? '2025-03-01').toString() : '2025-03-01');
    final endCtrl = TextEditingController(text: isEdit ? (existing['warrantyEndDate'] ?? '2027-03-01').toString() : '2027-03-01');
    final slaCtrl = TextEditingController(text: isEdit ? (existing['slaResponseHours'] ?? 24).toString() : '24');
    final contactCtrl = TextEditingController(text: isEdit ? (existing['serviceContact'] ?? '').toString() : '');
    final emailCtrl = TextEditingController(text: isEdit ? (existing['serviceEmail'] ?? '').toString() : '');
    final nextSvcCtrl = TextEditingController(text: isEdit ? (existing['nextServiceDate'] ?? '2026-12-01').toString() : '2026-12-01');

    String plant = isEdit ? (existing['plantLocation'] ?? 'Plant 1 - Hyderabad East CBG').toString() : 'Plant 1 - Hyderabad East CBG';
    String contractType = isEdit ? (existing['contractType'] ?? 'Comprehensive OEM AMC').toString() : 'Comprehensive OEM AMC';

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
                    const Icon(Icons.verified_user_outlined, color: Color(0xFF1677FF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Machinery Warranty' : 'Register Heavy Machinery',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(child: TextField(controller: tagCtrl, decoration: moduleInputDecoration('Asset Tag Code *'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: serialCtrl, decoration: moduleInputDecoration('Serial Number *'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: moduleInputDecoration('Machine / Heavy Equipment Name *')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: oemCtrl, decoration: moduleInputDecoration('OEM Manufacturer *'))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: plant,
                        isExpanded: true,
                        decoration: moduleInputDecoration('Plant Site *'),
                        items: const [
                          DropdownMenuItem(value: 'Plant 1 - Hyderabad East CBG', child: Text('Plant 1 - Hyderabad East CBG')),
                          DropdownMenuItem(value: 'Plant 2 - Medak Agri Hub', child: Text('Plant 2 - Medak Agri Hub')),
                          DropdownMenuItem(value: 'Plant 3 - Nalgonda Biomass Facility', child: Text('Plant 3 - Nalgonda Biomass Facility')),
                        ],
                        onChanged: (v) => setModalState(() => plant = v ?? 'Plant 1 - Hyderabad East CBG'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: commCtrl, decoration: moduleInputDecoration('Commission Date *'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: startCtrl, decoration: moduleInputDecoration('Warranty Start *'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: endCtrl, decoration: moduleInputDecoration('Warranty End *'))),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: contractType,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Service Contract Type'),
                  items: const [
                    DropdownMenuItem(value: 'Comprehensive OEM AMC', child: Text('Comprehensive OEM AMC')),
                    DropdownMenuItem(value: 'Non-Comprehensive AMC', child: Text('Non-Comprehensive AMC')),
                    DropdownMenuItem(value: 'Standard 2-Year OEM Warranty', child: Text('Standard 2-Year OEM Warranty')),
                    DropdownMenuItem(value: 'Full Lifecycle Care Program', child: Text('Full Lifecycle Care Program')),
                    DropdownMenuItem(value: 'Hydro-Testing & Structural Warranty', child: Text('Hydro-Testing & Structural Warranty')),
                    DropdownMenuItem(value: 'Direct OEM Warranty', child: Text('Direct OEM Warranty')),
                  ],
                  onChanged: (v) => setModalState(() => contractType = v ?? 'Comprehensive OEM AMC'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: slaCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('SLA Response (Hrs) *'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: contactCtrl, decoration: moduleInputDecoration('OEM Support Contact *'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: emailCtrl, decoration: moduleInputDecoration('OEM Service Email'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: nextSvcCtrl, decoration: moduleInputDecoration('Next Service Date'))),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final days = _daysRemaining(endCtrl.text.trim());
                      final computedStatus = days <= 0 ? 'Expired' : days <= 60 ? 'Expiring Soon' : 'Active';
                      final item = {
                        'id': isEdit ? existing['id'] : DateTime.now().millisecondsSinceEpoch,
                        'assetTag': tagCtrl.text.trim(),
                        'machineName': nameCtrl.text.trim(),
                        'serialNo': serialCtrl.text.trim(),
                        'oem': oemCtrl.text.trim(),
                        'plantLocation': plant,
                        'purchaseDate': existing?['purchaseDate'] ?? '2025-01-01',
                        'commissionDate': commCtrl.text.trim(),
                        'warrantyStartDate': startCtrl.text.trim(),
                        'warrantyEndDate': endCtrl.text.trim(),
                        'contractType': contractType,
                        'slaResponseHours': int.tryParse(slaCtrl.text.trim()) ?? 24,
                        'serviceContact': contactCtrl.text.trim(),
                        'serviceEmail': emailCtrl.text.trim(),
                        'status': computedStatus,
                        'nextServiceDate': nextSvcCtrl.text.trim(),
                        'claimHistory': existing?['claimHistory'] ?? '0 Claims Filed',
                      };
                      setState(() {
                        if (isEdit) {
                          _warranties = _warranties.map((w) => w['id'] == existing['id'] ? item : w).toList();
                        } else {
                          _warranties = [item, ..._warranties];
                        }
                        InventoryApiService.saveLocalList(InventoryStorageKeys.warranties, _warranties);
                      });
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: Text(isEdit ? 'Update Details' : 'Register Machinery'),
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

  void _openClaimModal(Map<String, dynamic> machine) {
    final subjectCtrl = TextEditingController();
    String severity = 'Major (Performance Degraded)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Log Official Warranty Claim'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${machine['machineName']}', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              Text('Serial: ${machine['serialNo']} • OEM: ${machine['oem']}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF92400E))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: severity,
                isExpanded: true,
                decoration: moduleInputDecoration('Claim Severity'),
                items: const [
                  DropdownMenuItem(value: 'Critical (Plant Stopped)', child: Text('Critical (Plant Stopped)')),
                  DropdownMenuItem(value: 'Major (Performance Degraded)', child: Text('Major (Performance Degraded)')),
                  DropdownMenuItem(value: 'Minor (Preventive Part Wear)', child: Text('Minor (Preventive Part Wear)')),
                ],
                onChanged: (v) => setDialogState(() => severity = v ?? 'Major (Performance Degraded)'),
              ),
              const SizedBox(height: 10),
              TextField(controller: subjectCtrl, maxLines: 3, decoration: moduleInputDecoration('Defect Description *')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (subjectCtrl.text.trim().isEmpty) return;
                setState(() {
                  _warranties = _warranties.map((w) {
                    if (w['id'] == machine['id']) {
                      return {
                        ...w,
                        'status': 'Claim in Progress',
                        'claimHistory': 'Active Claim Filed ($severity): ${subjectCtrl.text.trim()} [Logged ${DateTime.now().toIso8601String().split('T').first}]',
                      };
                    }
                    return w;
                  }).toList();
                  InventoryApiService.saveLocalList(InventoryStorageKeys.warranties, _warranties);
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Warranty Claim lodged with OEM (${machine['oem']})!')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
              child: const Text('Submit Claim'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailModal(Map<String, dynamic> m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Heavy Machinery Warranty Dossier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${m['machineName']}', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            Text('Asset: ${m['assetTag']} • Serial: ${m['serialNo']}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E40AF))),
            const Divider(height: 16),
            Text('OEM: ${m['oem']}'),
            Text('Site: ${m['plantLocation']}'),
            Text('Validity: ${m['warrantyStartDate']} to ${m['warrantyEndDate']}'),
            Text('Contract: ${m['contractType']}'),
            Text('SLA: ${m['slaResponseHours']} Hours'),
            Text('Support: ${m['serviceContact']} | ${m['serviceEmail']}'),
            const SizedBox(height: 6),
            Text('Claim History: ${m['claimHistory'] ?? 'None'}'),
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
        title: const Text('Delete Warranty Entry'),
        content: const Text('Are you sure you want to remove this equipment warranty registry entry?'),
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
        _warranties.removeWhere((w) => w['id'] == id);
        InventoryApiService.saveLocalList(InventoryStorageKeys.warranties, _warranties);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _warranties.where((w) => w['status'] == 'Active').length;
    final expiringCount = _warranties.where((w) => w['status'] == 'Expiring Soon').length;
    final expiredCount = _warranties.where((w) => w['status'] == 'Expired').length;
    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            'Serial-number-level tracking for heavy plant machinery, OEM details, expiration countdowns, automated lapse alerts, and active service contracts.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'bionova_equipment_warranties_${DateTime.now().toIso8601String().split('T').first}.csv',
                    headers: ['Asset Tag', 'Machine Name', 'Serial No', 'OEM', 'Plant Site', 'Commission Date', 'Warranty Start', 'Warranty End', 'Contract Type', 'SLA Hours', 'Service Contact', 'Status', 'Claim History'],
                    rows: filtered
                        .map((w) => [w['assetTag'], w['machineName'], w['serialNo'], w['oem'], w['plantLocation'], w['commissionDate'], w['warrantyStartDate'], w['warrantyEndDate'], w['contractType'], w['slaResponseHours'], w['serviceContact'], w['status'], w['claimHistory']])
                        .toList(),
                  ),
                  icon: const Icon(Icons.download, size: 15),
                  label: const Text('Export Registry'),
                ),
              ),
              if (widget.screenPerm.canCreate) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Register Machine'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1677FF), foregroundColor: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (expiringCount > 0)
            ModuleAlertBanner(
              title: 'Machinery Warranty Lapse Alert: $expiringCount Units Expiring < 60 Days!',
              subtitle: 'Critical plant units require urgent OEM AMC renewal or inspection sign-off.',
              actionLabel: 'Review Expiring',
              onAction: () => setState(() => _statusFilter = 'Expiring Soon'),
            ),
          ModuleKpiGrid(
            items: [
              ModuleKpiItem(label: 'REGISTERED MACHINERY', value: '${_warranties.length} Assets', subtext: 'Across 3 Operating Sites', accentColor: const Color(0xFF2563EB), icon: Icons.precision_manufacturing_outlined),
              ModuleKpiItem(label: 'ACTIVE OEM WARRANTIES', value: '$activeCount Units', subtext: 'Comprehensive Protection', accentColor: const Color(0xFF059669), icon: Icons.verified_user_outlined),
              ModuleKpiItem(label: 'EXPIRING IN <60 DAYS', value: '$expiringCount Units', subtext: 'Initiate AMC Renewal', accentColor: const Color(0xFFD97706), valueColor: const Color(0xFFD97706), icon: Icons.schedule),
              ModuleKpiItem(label: 'LAPSED / EXPIRED AMC', value: '$expiredCount Units', subtext: 'Unprotected Risk', accentColor: const Color(0xFFDC2626), valueColor: const Color(0xFFDC2626), icon: Icons.error_outline),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _searchTerm = v),
            decoration: moduleInputDecoration('Search Asset Tag, Machine Name, Serial, OEM...').copyWith(prefixIcon: const Icon(Icons.search, size: 18)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Status'),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(value: 'Expiring Soon', child: Text('Expiring Soon')),
                    DropdownMenuItem(value: 'Claim in Progress', child: Text('Claim in Progress')),
                    DropdownMenuItem(value: 'Expired', child: Text('Expired')),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v ?? 'All'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _oemFilter,
                  isExpanded: true,
                  decoration: moduleInputDecoration('OEM'),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All OEMs')),
                    DropdownMenuItem(value: 'Bauer', child: Text('Bauer')),
                    DropdownMenuItem(value: 'Sulzer', child: Text('Sulzer')),
                    DropdownMenuItem(value: 'Thermax', child: Text('Thermax')),
                    DropdownMenuItem(value: 'Cummins', child: Text('Cummins')),
                    DropdownMenuItem(value: 'Alfa Laval', child: Text('Alfa Laval')),
                    DropdownMenuItem(value: 'Aerzen', child: Text('Aerzen')),
                  ],
                  onChanged: (v) => setState(() => _oemFilter = v ?? 'All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(icon: Icons.verified_user_outlined, title: 'No machinery matches warranty filters', subtitle: 'Register machinery or clear active filters.')
          else
            ...filtered.map((item) {
              final days = _daysRemaining(item['warrantyEndDate']);
              final st = (item['status'] ?? 'Active').toString();
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
                        Expanded(child: Text('${item['machineName']}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5))),
                        ModuleTag(
                          text: st,
                          bgColor: st == 'Active' ? const Color(0xFFDCFCE7) : st == 'Expiring Soon' ? const Color(0xFFFEF3C7) : st == 'Claim in Progress' ? const Color(0xFFE0E7FF) : const Color(0xFFFEE2E2),
                          textColor: st == 'Active' ? const Color(0xFF166534) : st == 'Expiring Soon' ? const Color(0xFF92400E) : st == 'Claim in Progress' ? const Color(0xFF3730A3) : const Color(0xFF991B1B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('${item['assetTag']} • S/N: ${item['serialNo']}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF2563EB))),
                    Text('${item['oem']} • ${item['plantLocation']}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                    Text('${item['contractType']} (SLA: ${item['slaResponseHours']}h)', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          days <= 0 ? 'Lapsed (0 Days)' : '$days Days Left (Exp: ${item['warrantyEndDate']})',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: days <= 0 ? const Color(0xFFDC2626) : days <= 60 ? const Color(0xFFD97706) : const Color(0xFF059669)),
                        ),
                        Row(
                          children: [
                            if (widget.screenPerm.canEdit && st != 'Expired')
                              IconButton(onPressed: () => _openClaimModal(item), icon: const Icon(Icons.report_problem_outlined, size: 18, color: Color(0xFFD97706))),
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
