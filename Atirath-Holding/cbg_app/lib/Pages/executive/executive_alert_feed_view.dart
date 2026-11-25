import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/executive_api_service.dart';
import '../../widgets/module_ui_widgets.dart';

class ExecutiveAlertFeedView extends StatefulWidget {
  const ExecutiveAlertFeedView({super.key});

  @override
  State<ExecutiveAlertFeedView> createState() => _ExecutiveAlertFeedViewState();
}

class _ExecutiveAlertFeedViewState extends State<ExecutiveAlertFeedView> {
  static const List<String> _categories = [
    'All Categories',
    'Project Budget Variance',
    'Regulatory Expiry',
    'Fund Burn Rate',
    'Safety / ESG',
  ];

  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _catFilter = 'All Categories';
  String _severityFilter = 'All';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await ExecutiveApiService.getExecutiveAlerts();
    if (mounted) {
      setState(() {
        _alerts = data;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _alerts.where((a) {
      final matchesSearch = (a['title'] ?? '').toString().toLowerCase().contains(q) ||
          (a['triggerDetail'] ?? '').toString().toLowerCase().contains(q) ||
          (a['plant'] ?? '').toString().toLowerCase().contains(q) ||
          (a['id'] ?? '').toString().toLowerCase().contains(q);
      final matchesCat = _catFilter == 'All Categories' || a['category'] == _catFilter;
      final matchesSev = _severityFilter == 'All' || a['severity'] == _severityFilter;
      final matchesSt = _statusFilter == 'All' || a['status'] == _statusFilter;
      return matchesSearch && matchesCat && matchesSev && matchesSt;
    }).toList();
  }

  void _openBroadcastForm() {
    final idCtrl = TextEditingController(text: 'ALT-INC-0${_alerts.length + 1}');
    final titleCtrl = TextEditingController();
    final plantCtrl = TextEditingController(text: 'Plant 1 - Hyderabad East CBG');
    final metricCtrl = TextEditingController();
    final detailCtrl = TextEditingController();
    final actionCtrl = TextEditingController();

    String category = 'Project Budget Variance';
    String severity = 'Critical';

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
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Broadcast Executive Critical Alert',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Alert Category *'),
                  items: _categories.where((c) => c != 'All Categories').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModalState(() => category = v ?? 'Project Budget Variance'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: severity,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Severity *'),
                  items: const [
                    DropdownMenuItem(value: 'Critical', child: Text('Critical (Immediate C-Suite)')),
                    DropdownMenuItem(value: 'Warning', child: Text('Warning (48-Hr Action)')),
                  ],
                  onChanged: (v) => setModalState(() => severity = v ?? 'Critical'),
                ),
                const SizedBox(height: 10),
                TextField(controller: plantCtrl, decoration: moduleInputDecoration('Impacted Plant Facility *')),
                const SizedBox(height: 10),
                TextField(controller: metricCtrl, decoration: moduleInputDecoration('Metric / Threshold Triggered')),
                const SizedBox(height: 10),
                TextField(controller: titleCtrl, decoration: moduleInputDecoration('Alert Headline *')),
                const SizedBox(height: 10),
                TextField(controller: detailCtrl, maxLines: 3, decoration: moduleInputDecoration('Trigger Details & Context *')),
                const SizedBox(height: 10),
                TextField(controller: actionCtrl, decoration: moduleInputDecoration('Recommended Executive Action')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (titleCtrl.text.trim().isEmpty || detailCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please provide Title and Trigger Detail.')),
                        );
                        return;
                      }
                      final alert = {
                        'id': idCtrl.text.trim(),
                        'title': titleCtrl.text.trim(),
                        'category': category,
                        'severity': severity,
                        'plant': plantCtrl.text.trim(),
                        'triggerDetail': detailCtrl.text.trim(),
                        'metric': metricCtrl.text.trim(),
                        'action': actionCtrl.text.trim(),
                        'timestamp': DateTime.now().toString().substring(0, 16),
                        'status': 'Active',
                      };
                      setState(() => _alerts = [alert, ..._alerts]);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.campaign, size: 16),
                    label: const Text('Broadcast Executive Notice'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateStatus(String id, String newStatus) {
    setState(() {
      _alerts = _alerts.map((a) => a['id'].toString() == id ? {...a, 'status': newStatus} : a).toList();
    });
  }

  Future<void> _deleteAlert(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dismiss Alert'),
        content: Text('Delete alert notice $id?'),
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
      setState(() => _alerts.removeWhere((a) => a['id'].toString() == id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCritical = _alerts.where((a) => a['severity'] == 'Critical' && a['status'] == 'Active').length;
    final budgetAlerts = _alerts.where((a) => (a['category'] ?? '').toString().contains('Budget')).length;
    final regAlerts = _alerts.where((a) => (a['category'] ?? '').toString().contains('Regulatory')).length;
    final resolvedCount = _alerts.where((a) => a['status'] == 'Resolved').length;
    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            'Dynamic high-priority warning telemetry across project budget overruns (>5%), regulatory license expiries, safety incidents, and cash burn rate.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'BioNova_Executive_Alerts_${DateTime.now().toIso8601String().split('T').first}.csv',
                    headers: ['Alert ID', 'Title', 'Category', 'Severity', 'Plant', 'Metric', 'Trigger Detail', 'Action', 'Timestamp', 'Status'],
                    rows: filtered
                        .map((a) => [a['id'], a['title'], a['category'], a['severity'], a['plant'], a['metric'], a['triggerDetail'], a['action'], a['timestamp'], a['status']])
                        .toList(),
                  ),
                  icon: const Icon(Icons.download, size: 15),
                  label: const Text('Export CSV'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF059669)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openBroadcastForm,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Broadcast Alert'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ModuleKpiGrid(
            items: [
              ModuleKpiItem(
                label: 'ACTIVE CRITICAL INCIDENTS',
                value: '$activeCritical Incidents',
                subtext: activeCritical > 0 ? 'Requires Intervention' : 'All Systems Nominal',
                accentColor: activeCritical > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                valueColor: activeCritical > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                icon: Icons.report_problem_outlined,
              ),
              ModuleKpiItem(
                label: 'BUDGET OVERRUNS (>5%)',
                value: '$budgetAlerts Triggers',
                subtext: budgetAlerts > 0 ? 'Tolerance Limit Exceeded' : 'Zero Overruns Detected',
                accentColor: budgetAlerts > 0 ? const Color(0xFFEA580C) : const Color(0xFF64748B),
                icon: Icons.attach_money,
              ),
              ModuleKpiItem(
                label: 'REGULATORY WARNINGS',
                value: '$regAlerts Permits',
                subtext: regAlerts > 0 ? 'Filing Packets Underway' : 'Zero Pending Filings',
                accentColor: regAlerts > 0 ? const Color(0xFFD97706) : const Color(0xFF64748B),
                icon: Icons.verified_user_outlined,
              ),
              ModuleKpiItem(
                label: 'RESOLVED / MITIGATED',
                value: '$resolvedCount Closed',
                subtext: resolvedCount > 0 ? 'Action Items Completed' : 'No Prior Incidents',
                accentColor: resolvedCount > 0 ? const Color(0xFF059669) : const Color(0xFF64748B),
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: moduleInputDecoration('Search alerts by title, details, or facility...').copyWith(
              prefixIcon: const Icon(Icons.search, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _catFilter,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Category'),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _catFilter = v ?? 'All Categories'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _severityFilter,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Severity'),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Severities')),
                    DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                    DropdownMenuItem(value: 'Warning', child: Text('Warning')),
                  ],
                  onChanged: (v) => setState(() => _severityFilter = v ?? 'All'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Status'),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(value: 'In Review', child: Text('In Review')),
                    DropdownMenuItem(value: 'Acknowledged', child: Text('Acknowledged')),
                    DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
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
              icon: Icons.notifications_none,
              title: 'No executive alerts found',
              subtitle: 'All monitored thresholds and compliance parameters are clear.',
            )
          else
            ...filtered.map((a) {
              final isCritical = a['severity'] == 'Critical';
              final isResolved = a['status'] == 'Resolved';
              final leftColor = isResolved ? const Color(0xFF94A3B8) : isCritical ? const Color(0xFFDC2626) : const Color(0xFFD97706);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isResolved ? const Color(0xFFF8FAFC) : isCritical ? const Color(0xFFFFF5F5) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: leftColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ModuleTag(
                          text: (a['severity'] ?? 'Warning').toString().toUpperCase(),
                          bgColor: isCritical ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                          textColor: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('${a['category']}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                        ),
                        IconButton(onPressed: () => _deleteAlert(a['id'].toString()), icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF94A3B8))),
                      ],
                    ),
                    Text('${a['plant']} • ${a['timestamp'] ?? ''}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    Text((a['title'] ?? '').toString(), style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text((a['triggerDetail'] ?? '').toString(), style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF334155))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RECOMMENDED ACTION: ${a['action'] ?? '-'}', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ModuleTag(
                                text: 'Status: ${a['status']}',
                                bgColor: isResolved ? const Color(0xFFDCFCE7) : a['status'] == 'Active' ? const Color(0xFFFEE2E2) : const Color(0xFFE0E7FF),
                                textColor: isResolved ? const Color(0xFF166534) : a['status'] == 'Active' ? const Color(0xFF991B1B) : const Color(0xFF3730A3),
                              ),
                              Row(
                                children: [
                                  if (a['status'] == 'Active')
                                    TextButton(
                                      onPressed: () => _updateStatus(a['id'].toString(), 'Acknowledged'),
                                      child: const Text('Acknowledge'),
                                    ),
                                  if (!isResolved)
                                    ElevatedButton.icon(
                                      onPressed: () => _updateStatus(a['id'].toString(), 'Resolved'),
                                      icon: const Icon(Icons.check, size: 14),
                                      label: const Text('Resolve'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF059669),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: Size.zero,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
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
