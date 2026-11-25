import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/visitor_data_service.dart';
import '../../widgets/module_ui_widgets.dart';

class VisitorApprovalView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const VisitorApprovalView({
    super.key,
    required this.screenPerm,
    required this.onNavigate,
  });

  @override
  State<VisitorApprovalView> createState() => _VisitorApprovalViewState();
}

class _VisitorApprovalViewState extends State<VisitorApprovalView> {
  List<Map<String, dynamic>> _visitors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await VisitorDataService.instance.getStoredList(VisitorStorageKeys.visitors);
    if (mounted) {
      setState(() {
        _visitors = list;
        _isLoading = false;
      });
    }
  }

  void _openAuthorizeModal(Map<String, dynamic> visitor) {
    final escortCtrl = TextEditingController(text: (visitor['hostName'] ?? '').toString());
    final remarksCtrl = TextEditingController();
    bool requireMandatoryPpe = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Review & Authorize Entry', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${visitor['name'] ?? '-'} (${visitor['company'] ?? '-'})', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                Text('Pass: ${visitor['passNumber'] ?? visitor['id']} • Purpose: ${visitor['purpose'] ?? '-'}',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                const SizedBox(height: 12),
                TextField(controller: escortCtrl, decoration: moduleInputDecoration('Assigned Escort / Host')),
                const SizedBox(height: 10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: requireMandatoryPpe,
                  onChanged: (v) => setDlgState(() => requireMandatoryPpe = v ?? true),
                  title: Text('Mandatory PPE & ATEX Inspection Required', style: GoogleFonts.inter(fontSize: 12)),
                ),
                TextField(controller: remarksCtrl, maxLines: 2, decoration: moduleInputDecoration('Security / EHS Remarks')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final updatedRecord = {...visitor, 'status': 'Rejected', 'approvalRemarks': remarksCtrl.text.trim()};
                final updated = _visitors.map((v) => v['id'].toString() == visitor['id'].toString() ? updatedRecord : v).toList();
                setState(() => _visitors = updated);
                await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.visitors, updated);
                await VisitorDataService.instance.apiUpdateVisitorRecord(visitor['id'], updatedRecord);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Reject', style: TextStyle(color: Color(0xFFDC2626))),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedRecord = {
                  ...visitor,
                  'status': 'Checked In',
                  'checkInTime': DateTime.now().toIso8601String(),
                  'escortName': escortCtrl.text.trim(),
                  'ppeIssued': requireMandatoryPpe,
                  'approvalRemarks': remarksCtrl.text.trim(),
                };
                final updated = _visitors.map((v) => v['id'].toString() == visitor['id'].toString() ? updatedRecord : v).toList();
                setState(() => _visitors = updated);
                await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.visitors, updated);
                await VisitorDataService.instance.apiCheckInVisitor(visitor['id']);
                await VisitorDataService.instance.apiUpdateVisitorRecord(visitor['id'], updatedRecord);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
              child: const Text('Grant Entry & Check-In'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingQueue = _visitors.where((v) => v['status'] == 'Pending Approval').toList();
    final approvedActive = _visitors.where((v) => v['status'] == 'Checked In').length;
    final rejectedCount = _visitors.where((v) => v['status'] == 'Rejected').length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text('Security & Host Approvals', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
          Text('Authorize visitor plant access, assign escorts & validate PPE compliance', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          ModuleKpiGrid(items: [
            ModuleKpiItem(label: 'Pending Clearance', value: '${pendingQueue.length}', subtext: 'Awaiting authorization', accentColor: const Color(0xFFD97706), icon: Icons.pending_actions_outlined),
            ModuleKpiItem(label: 'Active Authorized', value: '$approvedActive', subtext: 'Cleared & inside plant', accentColor: const Color(0xFF059669), icon: Icons.verified_user_outlined),
            ModuleKpiItem(label: 'Rejected Entries', value: '$rejectedCount', subtext: 'Denied at gate', accentColor: const Color(0xFFDC2626), icon: Icons.block_outlined),
            ModuleKpiItem(label: 'Total Processed', value: '${_visitors.length}', subtext: 'All passes', accentColor: const Color(0xFF2563EB), icon: Icons.assignment_turned_in_outlined),
          ]),
          const SizedBox(height: 14),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (pendingQueue.isEmpty)
            const ModuleEmptyState(
              icon: Icons.verified_outlined,
              title: 'Approval Queue Clear',
              subtitle: 'No pending visitor passes require gate authorization right now.',
            )
          else
            ...pendingQueue.map((v) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ModuleTag(text: '${v['passNumber'] ?? v['id']}', bgColor: const Color(0xFFFEF3C7), textColor: const Color(0xFFD97706)),
                          const Spacer(),
                          ModuleTag(text: '${v['category'] ?? '-'}', bgColor: const Color(0xFFF1F5F9), textColor: const Color(0xFF334155)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${v['name'] ?? '-'} • ${v['company'] ?? '-'}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800)),
                      Text('Host: ${v['hostName'] ?? '-'} • Purpose: ${v['purpose'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                      if (widget.screenPerm.canEdit) ...[
                        const Divider(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () => _openAuthorizeModal(v),
                            icon: const Icon(Icons.verified_user_outlined, size: 15),
                            label: const Text('Review & Authorize'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
