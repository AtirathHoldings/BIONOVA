import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/visitor_data_service.dart';
import '../../widgets/module_ui_widgets.dart';

class VisitRequestView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const VisitRequestView({
    super.key,
    required this.screenPerm,
    required this.onNavigate,
  });

  @override
  State<VisitRequestView> createState() => _VisitRequestViewState();
}

class _VisitRequestViewState extends State<VisitRequestView> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String _searchTerm = '';
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await VisitorDataService.instance.getStoredList(VisitorStorageKeys.requests);
    if (mounted) {
      setState(() {
        _requests = list;
        _isLoading = false;
      });
    }
  }

  void _openSubmitRequestModal() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final hostCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T').first);
    String urgency = 'Normal';

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
                      Expanded(child: Text('Submit Pre-Visit Request', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: moduleInputDecoration('Visitor Name *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: companyCtrl, decoration: moduleInputDecoration('Company'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: moduleInputDecoration('Phone *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: hostCtrl, decoration: moduleInputDecoration('Host Employee *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: dateCtrl, decoration: moduleInputDecoration('Requested Date'))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: urgency,
                          decoration: moduleInputDecoration('Priority'),
                          items: const [
                            DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                            DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                            DropdownMenuItem(value: 'VIP', child: Text('VIP')),
                          ],
                          onChanged: (v) => setModalState(() => urgency = v ?? urgency),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: purposeCtrl, maxLines: 2, decoration: moduleInputDecoration('Purpose / Work Scope *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final item = {
                          'id': 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                          'visitorName': nameCtrl.text.trim(),
                          'company': companyCtrl.text.trim().isEmpty ? 'External' : companyCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'hostName': hostCtrl.text.trim(),
                          'requestedDate': dateCtrl.text.trim(),
                          'urgency': urgency,
                          'purpose': purposeCtrl.text.trim(),
                          'status': 'Pending',
                        };
                        final updated = [item, ..._requests];
                        setState(() => _requests = updated);
                        await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.requests, updated);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('Submit Request'),
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

  Future<void> _setStatus(Map<String, dynamic> req, String status) async {
    final updated = _requests.map((r) => r['id'].toString() == req['id'].toString() ? {...r, 'status': status} : r).toList();
    setState(() => _requests = updated);
    await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.requests, updated);
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _requests.where((r) => r['status'] == 'Pending').length;
    final approvedCount = _requests.where((r) => r['status'] == 'Approved').length;
    final rejectedCount = _requests.where((r) => r['status'] == 'Rejected').length;

    final filtered = _requests.where((r) {
      final q = _searchTerm.trim().toLowerCase();
      final matchQ = q.isEmpty ||
          (r['visitorName'] ?? r['name'] ?? '').toString().toLowerCase().contains(q) ||
          (r['company'] ?? '').toString().toLowerCase().contains(q) ||
          (r['hostName'] ?? '').toString().toLowerCase().contains(q);
      final matchSt = _statusFilter == 'ALL' || r['status'] == _statusFilter;
      return matchQ && matchSt;
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
                    Text('Pre-Visit Request Portal', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('Advance entry clearance requests from contractors & clients', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              if (widget.screenPerm.canCreate)
                ElevatedButton.icon(
                  onPressed: _openSubmitRequestModal,
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('New Request'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ModuleKpiGrid(items: [
            ModuleKpiItem(label: 'Total Requests', value: '${_requests.length}', subtext: 'Logged applications', accentColor: const Color(0xFF2563EB), icon: Icons.mail_outline),
            ModuleKpiItem(label: 'Pending Review', value: '$pendingCount', subtext: 'Awaiting clearance', accentColor: const Color(0xFFD97706), icon: Icons.hourglass_empty),
            ModuleKpiItem(label: 'Approved', value: '$approvedCount', subtext: 'Cleared for gate pass', accentColor: const Color(0xFF059669), icon: Icons.check_circle_outline),
            ModuleKpiItem(label: 'Rejected', value: '$rejectedCount', subtext: 'Declined', accentColor: const Color(0xFFDC2626), icon: Icons.cancel_outlined),
          ]),
          const SizedBox(height: 12),
          TextField(
            decoration: moduleInputDecoration('Search visitor, company, host...'),
            onChanged: (v) => setState(() => _searchTerm = v),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['ALL', 'Pending', 'Approved', 'Rejected'].map((st) {
                final selected = _statusFilter == st;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(st),
                    selected: selected,
                    onSelected: (_) => setState(() => _statusFilter = st),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(icon: Icons.inbox_outlined, title: 'No Visit Requests', subtitle: 'Submit a pre-visit request for advance security clearance.')
          else
            ...filtered.map((r) {
              final st = (r['status'] ?? 'Pending').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ModuleTag(text: '${r['id'] ?? ''}', bgColor: const Color(0xFFEFF6FF), textColor: const Color(0xFF1D4ED8)),
                        const SizedBox(width: 6),
                        ModuleTag(text: '${r['urgency'] ?? 'Normal'}', bgColor: const Color(0xFFF1F5F9), textColor: const Color(0xFF334155)),
                        const Spacer(),
                        ModuleTag(
                          text: st,
                          bgColor: st == 'Approved' ? const Color(0xFFD1FAE5) : (st == 'Rejected' ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7)),
                          textColor: st == 'Approved' ? const Color(0xFF059669) : (st == 'Rejected' ? const Color(0xFFDC2626) : const Color(0xFFD97706)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${r['visitorName'] ?? r['name'] ?? '-'} • ${r['company'] ?? '-'}', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    Text('Host: ${r['hostName'] ?? '-'} • Date: ${r['requestedDate'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                    const SizedBox(height: 4),
                    Text('${r['purpose'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    if (st == 'Pending' && widget.screenPerm.canEdit) ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => _setStatus(r, 'Rejected'), child: const Text('Reject', style: TextStyle(color: Color(0xFFDC2626)))),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _setStatus(r, 'Approved'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
                            child: const Text('Approve'),
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
