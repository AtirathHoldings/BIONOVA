import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/visitor_data_service.dart';
import '../../widgets/module_ui_widgets.dart';

class LiveInsideTrackingView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const LiveInsideTrackingView({super.key, required this.screenPerm, required this.onNavigate});

  @override
  State<LiveInsideTrackingView> createState() => _LiveInsideTrackingViewState();
}

class _LiveInsideTrackingViewState extends State<LiveInsideTrackingView> {
  List<Map<String, dynamic>> _visitors = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadData(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final list = await VisitorDataService.instance.getStoredList(VisitorStorageKeys.visitors);
    if (mounted) {
      setState(() {
        _visitors = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _quickExit(Map<String, dynamic> v) async {
    final updatedRecord = {...v, 'status': 'Checked Out', 'checkOutTime': DateTime.now().toIso8601String()};
    final updatedList = _visitors.map((x) => x['id'].toString() == v['id'].toString() ? updatedRecord : x).toList();
    setState(() => _visitors = updatedList);
    await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.visitors, updatedList);
    await VisitorDataService.instance.apiCheckOutVisitor(v['id']);
  }

  void _openEmergencyMusterDialog(List<Map<String, dynamic>> inside) {
    final summary = StringBuffer('EMERGENCY EVACUATION MUSTER ROLL (${inside.length} On-Site)\n\n');
    for (final v in inside) {
      summary.writeln('- ${v['name']} (${v['company']}) | Pass: ${v['passNumber'] ?? v['id']} | Host: ${v['hostName']} | Zones: ${(v['allowedZones'] is List) ? (v['allowedZones'] as List).join(',') : v['allowedZones']}');
    }
    showPrintablePreviewDialog(
      context,
      title: 'Emergency Evacuation Muster Roll (${inside.length})',
      copyText: summary.toString(),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCA5A5))),
            child: Text('HIGH-PRIORITY SAFETY MUSTER: ${inside.length} external personnel currently inside BioNova perimeter.',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFB91C1C))),
          ),
          const SizedBox(height: 10),
          if (inside.isEmpty)
            const Text('Zero visitors currently inside premises.')
          else
            ...inside.map((v) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• ${v['name']} (${v['company']}) — RFID: ${v['rfidTag'] ?? '-'} — Host: ${v['hostName'] ?? '-'}',
                      style: GoogleFonts.inter(fontSize: 12.5)),
                )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inside = _visitors.where((v) => v['status'] == 'Checked In' || v['status'] == 'Overdue').toList();
    final highRiskZoneCount = inside.where((v) {
      final zones = (v['allowedZones'] is List) ? (v['allowedZones'] as List).map((e) => e.toString()).toList() : <String>[];
      return zones.contains('Z3') || zones.contains('Z4') || zones.contains('Z5');
    }).length;
    final overdueCount = inside.where((v) => v['status'] == 'Overdue').length;

    return RefreshIndicator(
      onRefresh: () => _loadData(),
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Inside Plant Tracking', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('Auto-refreshes every 15s • Active perimeter headcount & muster roll', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openEmergencyMusterDialog(inside),
                icon: const Icon(Icons.emergency_outlined, size: 16),
                label: const Text('Muster Roll'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ModuleKpiGrid(items: [
            ModuleKpiItem(label: 'Currently Inside', value: '${inside.length}', subtext: 'Active on-site headcount', accentColor: const Color(0xFF059669), icon: Icons.people_alt_outlined),
            ModuleKpiItem(label: 'High-Risk ATEX Zones', value: '$highRiskZoneCount', subtext: 'Authorized for Z3/Z4/Z5', accentColor: const Color(0xFFEA580C), icon: Icons.warning_amber_rounded),
            ModuleKpiItem(label: 'Overdue On-Site', value: '$overdueCount', subtext: 'Exceeding pass duration', accentColor: const Color(0xFFDC2626), icon: Icons.timer_off_outlined),
          ]),
          const SizedBox(height: 14),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (inside.isEmpty)
            const ModuleEmptyState(icon: Icons.radar_outlined, title: 'Plant Perimeter Clear', subtitle: 'No visitors are currently checked inside the plant.')
          else
            ...inside.map((v) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ModuleTag(text: '${v['rfidTag'] ?? v['passNumber'] ?? v['id']}', bgColor: const Color(0xFFD1FAE5), textColor: const Color(0xFF059669)),
                          const Spacer(),
                          ModuleTag(
                            text: '${v['status'] ?? 'Checked In'}',
                            bgColor: v['status'] == 'Overdue' ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
                            textColor: v['status'] == 'Overdue' ? const Color(0xFFDC2626) : const Color(0xFF1D4ED8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${v['name'] ?? '-'} • ${v['company'] ?? '-'}', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800)),
                      Text('Host: ${v['hostName'] ?? '-'} • Zones: ${(v['allowedZones'] is List) ? (v['allowedZones'] as List).join(', ') : v['allowedZones'] ?? 'Z1'}',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                      if (widget.screenPerm.canEdit) ...[
                        const Divider(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () => _quickExit(v),
                            icon: const Icon(Icons.logout, size: 15),
                            label: const Text('Quick Exit'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white),
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
