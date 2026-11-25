import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/inventory_api_service.dart';
import '../../services/rbac_service.dart';
import '../../widgets/module_ui_widgets.dart';

class StockExpiryAlertsView extends StatefulWidget {
  final ScreenPermission screenPerm;

  const StockExpiryAlertsView({super.key, required this.screenPerm});

  @override
  State<StockExpiryAlertsView> createState() => _StockExpiryAlertsViewState();
}

class _StockExpiryAlertsViewState extends State<StockExpiryAlertsView> {
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  String _searchTerm = '';
  String _typeFilter = 'ALL';
  String _severityFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final local = await InventoryApiService.loadLocalList(InventoryStorageKeys.alerts);
    if (mounted) {
      setState(() {
        _alerts = local;
        _isLoading = false;
      });
    }
    final live = await InventoryApiService.getStockAlerts();
    if (live.isNotEmpty && mounted) {
      setState(() {
        _alerts = live;
        _isLoading = false;
      });
      await InventoryApiService.saveLocalList(InventoryStorageKeys.alerts, live);
    }
  }

  Future<void> _persistAlerts(List<Map<String, dynamic>> updated) async {
    setState(() => _alerts = updated);
    await InventoryApiService.saveLocalList(InventoryStorageKeys.alerts, updated);
  }

  Color _severityBg(String severity) {
    switch (severity) {
      case 'Critical':
        return const Color(0xFFFEE2E2);
      case 'High':
        return const Color(0xFFFFEDD5);
      case 'Medium':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  Color _severityFg(String severity) {
    switch (severity) {
      case 'Critical':
        return const Color(0xFFDC2626);
      case 'High':
        return const Color(0xFFEA580C);
      case 'Medium':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF2563EB);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Resolved':
        return const Color(0xFFD1FAE5);
      case 'Quarantined':
        return const Color(0xFFF3E8FF);
      default:
        return const Color(0xFFFEE2E2);
    }
  }

  Color _statusFg(String status) {
    switch (status) {
      case 'Resolved':
        return const Color(0xFF059669);
      case 'Quarantined':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFFDC2626);
    }
  }

  void _openCreateAlertModal() {
    final formKey = GlobalKey<FormState>();
    String type = 'Low Stock Alert';
    String severity = 'High';
    final titleCtrl = TextEditingController();
    final materialCtrl = TextEditingController();
    final batchCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final currentCtrl = TextEditingController();
    final thresholdCtrl = TextEditingController();
    final actionCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Log Manual Quality / Safety Alert',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: type,
                          decoration: moduleInputDecoration('Alert Type'),
                          items: const [
                            DropdownMenuItem(value: 'Low Stock Alert', child: Text('Low Stock Alert')),
                            DropdownMenuItem(value: 'Batch Expiry Alert', child: Text('Batch Expiry Alert')),
                            DropdownMenuItem(value: 'Quality Rejection Alert', child: Text('Quality Rejection Alert')),
                          ],
                          onChanged: (v) => setModalState(() => type = v ?? type),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: severity,
                          decoration: moduleInputDecoration('Severity'),
                          items: const [
                            DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                            DropdownMenuItem(value: 'High', child: Text('High')),
                            DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                            DropdownMenuItem(value: 'Low', child: Text('Low')),
                          ],
                          onChanged: (v) => setModalState(() => severity = v ?? severity),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: moduleInputDecoration('Alert Title *', hint: 'e.g., High Moisture Biomass Batch'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: materialCtrl,
                    decoration: moduleInputDecoration('Material Name *', hint: 'e.g., Napier Grass Silage'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: batchCtrl,
                          decoration: moduleInputDecoration('Batch / Lot No'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: locationCtrl,
                          decoration: moduleInputDecoration('Plant / Yard Location'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: currentCtrl,
                          decoration: moduleInputDecoration('Current Observed Value', hint: 'e.g., 32% Moisture'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: thresholdCtrl,
                          decoration: moduleInputDecoration('Threshold / Limit', hint: 'e.g., Max 20%'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: actionCtrl,
                    maxLines: 2,
                    decoration: moduleInputDecoration('Required Action / Corrective Step'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final newAlert = {
                          'id': 'ALT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                          'type': type,
                          'severity': severity,
                          'title': titleCtrl.text.trim(),
                          'materialName': materialCtrl.text.trim(),
                          'batchNo': batchCtrl.text.trim().isEmpty ? 'N/A' : batchCtrl.text.trim(),
                          'plantLocation': locationCtrl.text.trim().isEmpty ? 'Central Plant Store' : locationCtrl.text.trim(),
                          'currentVal': currentCtrl.text.trim().isEmpty ? '-' : currentCtrl.text.trim(),
                          'thresholdVal': thresholdCtrl.text.trim().isEmpty ? '-' : thresholdCtrl.text.trim(),
                          'actionRequired': actionCtrl.text.trim().isEmpty ? 'Inspect & remediate immediately' : actionCtrl.text.trim(),
                          'status': 'Active',
                          'createdAt': DateTime.now().toIso8601String(),
                        };
                        try {
                          await InventoryApiService.saveStockAlert(newAlert);
                        } catch (_) {}
                        await _persistAlerts([newAlert, ..._alerts]);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.add_alert_outlined, size: 16),
                      label: const Text('Submit Safety / Stock Alert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
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

  void _openResolveModal(Map<String, dynamic> alert) {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Resolve Alert: ${alert['id'] ?? ''}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${alert['title'] ?? ''} (${alert['materialName'] ?? ''})',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: moduleInputDecoration('Resolution / Corrective Notes *', hint: 'Describe PO raised, batch replaced, or action taken'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (notesCtrl.text.trim().isEmpty) return;
              final updatedList = _alerts.map((a) {
                if (a['id'].toString() == alert['id'].toString()) {
                  final copy = {
                    ...a,
                    'status': 'Resolved',
                    'resolutionNotes': notesCtrl.text.trim(),
                    'resolvedAt': DateTime.now().toIso8601String(),
                  };
                  try {
                    InventoryApiService.saveStockAlert(copy, id: a['id']);
                  } catch (_) {}
                  return copy;
                }
                return a;
              }).toList();
              await _persistAlerts(updatedList);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );
  }

  Future<void> _quarantineAlert(Map<String, dynamic> alert) async {
    final updatedList = _alerts.map((a) {
      if (a['id'].toString() == alert['id'].toString()) {
        final copy = {...a, 'status': 'Quarantined'};
        try {
          InventoryApiService.saveStockAlert(copy, id: a['id']);
        } catch (_) {}
        return copy;
      }
      return a;
    }).toList();
    await _persistAlerts(updatedList);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Batch ${alert['batchNo'] ?? ''} placed in Quarantine')),
      );
    }
  }

  Future<void> _deleteAlert(dynamic id) async {
    try {
      await InventoryApiService.deleteStockAlert(id);
    } catch (_) {}
    await _persistAlerts(_alerts.where((a) => a['id'].toString() != id.toString()).toList());
  }

  @override
  Widget build(BuildContext context) {
    final activeAlerts = _alerts.where((a) => a['status'] != 'Resolved').toList();
    final criticalCount = activeAlerts.where((a) => a['severity'] == 'Critical').length;
    final lowStockCount = activeAlerts.where((a) => a['type'] == 'Low Stock Alert').length;
    final expiryCount = activeAlerts.where((a) => a['type'] == 'Batch Expiry Alert').length;
    final rejectionCount = activeAlerts.where((a) => a['type'] == 'Quality Rejection Alert').length;

    final filtered = _alerts.where((a) {
      final q = _searchTerm.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          (a['materialName'] ?? '').toString().toLowerCase().contains(q) ||
          (a['batchNo'] ?? '').toString().toLowerCase().contains(q) ||
          (a['title'] ?? '').toString().toLowerCase().contains(q) ||
          (a['plantLocation'] ?? '').toString().toLowerCase().contains(q);
      final matchesType = _typeFilter == 'ALL' || a['type'] == _typeFilter;
      final matchesSeverity = _severityFilter == 'ALL' || a['severity'] == _severityFilter;
      return matchesSearch && matchesType && matchesSeverity;
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
                    Text('Stock, Expiry & Quality Alerts', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                    Text('Automated reorder thresholds, chemical shelf-life & rejection quarantine', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined, color: Color(0xFF2563EB)),
                tooltip: 'Export Alerts CSV',
                onPressed: () => exportCsvData(
                  context,
                  fileName: 'stock_expiry_alerts.csv',
                  headers: const ['Alert ID', 'Type', 'Severity', 'Title', 'Material', 'Batch', 'Location', 'Current', 'Threshold', 'Action', 'Status'],
                  rows: filtered
                      .map((a) => [
                            a['id'] ?? '',
                            a['type'] ?? '',
                            a['severity'] ?? '',
                            a['title'] ?? '',
                            a['materialName'] ?? '',
                            a['batchNo'] ?? '',
                            a['plantLocation'] ?? '',
                            a['currentVal'] ?? '',
                            a['thresholdVal'] ?? '',
                            a['actionRequired'] ?? '',
                            a['status'] ?? '',
                          ])
                      .toList(),
                ),
              ),
              if (widget.screenPerm.canCreate)
                ElevatedButton.icon(
                  onPressed: _openCreateAlertModal,
                  icon: const Icon(Icons.add_alert, size: 15),
                  label: const Text('Log Alert'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (lowStockCount > 0)
            ModuleAlertBanner(
              title: '$lowStockCount Low Stock Reorder Alert(s)',
              subtitle: 'Critical spare parts or chemical consumables below minimum safety threshold.',
              borderColor: const Color(0xFFD97706),
              bgColor: const Color(0xFFFEFCE8),
              iconColor: const Color(0xFFB45309),
            ),
          if (expiryCount > 0)
            ModuleAlertBanner(
              title: '$expiryCount Batch Expiry Alert(s)',
              subtitle: 'Enzymes, catalysts or sealed consumables approaching shelf-life expiry.',
              borderColor: const Color(0xFFEA580C),
              bgColor: const Color(0xFFFFF7ED),
              iconColor: const Color(0xFFC2410C),
            ),
          if (rejectionCount > 0)
            ModuleAlertBanner(
              title: '$rejectionCount Quality Rejection Alert(s)',
              subtitle: 'Non-conforming feedstock or materials requiring lab review & quarantine.',
              borderColor: const Color(0xFFDC2626),
              bgColor: const Color(0xFFFEF2F2),
              iconColor: const Color(0xFFB91C1C),
            ),
          ModuleKpiGrid(items: [
            ModuleKpiItem(label: 'Critical Active', value: '$criticalCount', subtext: 'Immediate escalation', accentColor: const Color(0xFFDC2626), icon: Icons.gpp_maybe_outlined),
            ModuleKpiItem(label: 'Low Stock', value: '$lowStockCount', subtext: 'Below reorder point', accentColor: const Color(0xFFD97706), icon: Icons.inventory_2_outlined),
            ModuleKpiItem(label: 'Batch Expiry', value: '$expiryCount', subtext: 'Near / expired shelf-life', accentColor: const Color(0xFFEA580C), icon: Icons.hourglass_bottom_outlined),
            ModuleKpiItem(label: 'Quality Rejections', value: '$rejectionCount', subtext: 'Lab / QC hold', accentColor: const Color(0xFF7C3AED), icon: Icons.science_outlined),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                TextField(
                  decoration: moduleInputDecoration('Search alerts (material, batch, plant)...'),
                  onChanged: (v) => setState(() => _searchTerm = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('type-$_typeFilter'),
                        initialValue: _typeFilter,
                        decoration: moduleInputDecoration('Type'),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Types')),
                          DropdownMenuItem(value: 'Low Stock Alert', child: Text('Low Stock Alert')),
                          DropdownMenuItem(value: 'Batch Expiry Alert', child: Text('Batch Expiry Alert')),
                          DropdownMenuItem(value: 'Quality Rejection Alert', child: Text('Quality Rejection')),
                        ],
                        onChanged: (v) => setState(() => _typeFilter = v ?? 'ALL'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('sev-$_severityFilter'),
                        initialValue: _severityFilter,
                        decoration: moduleInputDecoration('Severity'),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Severities')),
                          DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                          DropdownMenuItem(value: 'High', child: Text('High')),
                          DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'Low', child: Text('Low')),
                        ],
                        onChanged: (v) => setState(() => _severityFilter = v ?? 'ALL'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(
              icon: Icons.verified_outlined,
              title: 'No Stock or Expiry Alerts Found',
              subtitle: 'All material batches and safety thresholds match current filters.',
            )
          else
            ...filtered.map((a) {
              final sev = (a['severity'] ?? 'Medium').toString();
              final status = (a['status'] ?? 'Active').toString();
              final isQuality = a['type'] == 'Quality Rejection Alert';
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
                        ModuleTag(text: sev, bgColor: _severityBg(sev), textColor: _severityFg(sev)),
                        const SizedBox(width: 6),
                        ModuleTag(text: (a['type'] ?? 'Alert').toString(), bgColor: const Color(0xFFF1F5F9), textColor: const Color(0xFF334155)),
                        const Spacer(),
                        ModuleTag(text: status, bgColor: _statusBg(status), textColor: _statusFg(status)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text((a['title'] ?? '').toString(), style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text(
                      '${a['materialName'] ?? '-'} • Batch: ${a['batchNo'] ?? '-'} • ${a['plantLocation'] ?? '-'}',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Observed: ${a['currentVal'] ?? '-'} | Threshold: ${a['thresholdVal'] ?? '-'}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                    ),
                    if ((a['actionRequired'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Action: ${a['actionRequired']}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    ],
                    if ((a['resolutionNotes'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                        child: Text('Resolution: ${a['resolutionNotes']}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF065F46))),
                      ),
                    ],
                    if (widget.screenPerm.canEdit || widget.screenPerm.canDelete) ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (widget.screenPerm.canEdit && status != 'Resolved') ...[
                            if (isQuality && status != 'Quarantined')
                              TextButton.icon(
                                onPressed: () => _quarantineAlert(a),
                                icon: const Icon(Icons.block, size: 15, color: Color(0xFF7C3AED)),
                                label: const Text('Quarantine', style: TextStyle(color: Color(0xFF7C3AED))),
                              ),
                            ElevatedButton.icon(
                              onPressed: () => _openResolveModal(a),
                              icon: const Icon(Icons.check_circle_outline, size: 15),
                              label: const Text('Resolve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                          if (widget.screenPerm.canDelete)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 19),
                              onPressed: () => _deleteAlert(a['id']),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
