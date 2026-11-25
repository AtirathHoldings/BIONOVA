import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/visitor_data_service.dart';
import '../../widgets/module_ui_widgets.dart';

class OverdueTrackingView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const OverdueTrackingView({super.key, required this.screenPerm, required this.onNavigate});

  @override
  State<OverdueTrackingView> createState() => _OverdueTrackingViewState();
}

class _OverdueTrackingViewState extends State<OverdueTrackingView> {
  List<Map<String, dynamic>> _visitors = [];
  bool _isLoading = true;
  String? _alertBannerMsg;

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

  Future<void> _forceExit(Map<String, dynamic> v) async {
    final updatedRecord = {...v, 'status': 'Checked Out', 'checkOutTime': DateTime.now().toIso8601String(), 'forceExit': true};
    final updatedList = _visitors.map((x) => x['id'].toString() == v['id'].toString() ? updatedRecord : x).toList();
    setState(() => _visitors = updatedList);
    await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.visitors, updatedList);
    await VisitorDataService.instance.apiCheckOutVisitor(v['id']);
  }

  @override
  Widget build(BuildContext context) {
    final overdueList = _visitors.where((v) => v['status'] == 'Overdue').toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text('Overdue & Overstaying Visitor Alerts', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
          Text('Immediate security escalation for expired passes inside ATEX perimeter', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          const ModuleAlertBanner(
            title: 'Overstay Security Directive Active',
            subtitle: 'Any visitor exceeding their approved pass duration must be contacted immediately via their assigned Host and escorted to Main Gate Check-Out.',
            borderColor: Color(0xFFDC2626),
            bgColor: Color(0xFFFEF2F2),
            iconColor: Color(0xFFB91C1C),
          ),
          if (_alertBannerMsg != null)
            ModuleAlertBanner(
              title: 'Host Escalation Dispatched',
              subtitle: _alertBannerMsg!,
              borderColor: const Color(0xFF059669),
              bgColor: const Color(0xFFECFDF5),
              iconColor: const Color(0xFF047857),
              icon: Icons.notifications_active_outlined,
            ),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (overdueList.isEmpty)
            const ModuleEmptyState(
              icon: Icons.verified_user_outlined,
              title: 'Zero Overdue Visitors',
              subtitle: 'All active on-site personnel are within their authorized gate pass window.',
            )
          else
            ...overdueList.map((v) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ModuleTag(text: '${v['passNumber'] ?? v['id']}', bgColor: const Color(0xFFFEE2E2), textColor: const Color(0xFFDC2626)),
                          const Spacer(),
                          const ModuleTag(text: 'OVERDUE ALERT', bgColor: Color(0xFFDC2626), textColor: Colors.white),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${v['name'] ?? '-'} • ${v['company'] ?? '-'}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800)),
                      Text('Phone: ${v['phone'] ?? '-'} • Host: ${v['hostName'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _alertBannerMsg = 'Security escalation alert sent to host ${v['hostName'] ?? 'Assigned Host'} for ${v['name']}.'),
                            icon: const Icon(Icons.notifications_active, size: 15),
                            label: const Text('Alert Host'),
                          ),
                          const SizedBox(width: 8),
                          if (widget.screenPerm.canEdit)
                            ElevatedButton.icon(
                              onPressed: () => _forceExit(v),
                              icon: const Icon(Icons.logout, size: 15),
                              label: const Text('Force Exit'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                            ),
                        ],
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
