import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/visitor_data_service.dart';
import '../../widgets/module_ui_widgets.dart';

class VisitorDashboardView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const VisitorDashboardView({
    super.key,
    required this.screenPerm,
    required this.onNavigate,
  });

  @override
  State<VisitorDashboardView> createState() => _VisitorDashboardViewState();
}

class _VisitorDashboardViewState extends State<VisitorDashboardView> {
  List<Map<String, dynamic>> _visitors = [];
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _appointments = [];
  String _rosterFilter = 'ALL';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    VisitorDataService.instance.addListener(_onServiceUpdate);
    _loadData();
  }

  @override
  void dispose() {
    VisitorDataService.instance.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    _reloadFromCacheOnly();
  }

  Future<void> _reloadFromCacheOnly() async {
    final v = await VisitorDataService.instance.getStoredList(VisitorStorageKeys.visitors);
    final r = await VisitorDataService.instance.getStoredList(VisitorStorageKeys.requests);
    final vh = await VisitorDataService.instance.getStoredList(VisitorStorageKeys.vehicles);
    final a = await VisitorDataService.instance.getStoredList(VisitorStorageKeys.appointments);
    if (mounted) {
      setState(() {
        _visitors = v;
        _requests = r;
        _vehicles = vh;
        _appointments = a;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final v = await VisitorDataService.instance.getStoredList(VisitorStorageKeys.visitors);
    final r = await VisitorDataService.instance.getStoredList(VisitorStorageKeys.requests);
    final vh = await VisitorDataService.instance.getStoredList(VisitorStorageKeys.vehicles);
    final a = await VisitorDataService.instance.getStoredList(VisitorStorageKeys.appointments);
    if (mounted) {
      setState(() {
        _visitors = v;
        _requests = r;
        _vehicles = vh;
        _appointments = a;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkedInCount = _visitors.where((v) => v['status'] == 'Checked In').length;
    final overdueList = _visitors.where((v) => v['status'] == 'Overdue').toList();
    final pendingApprovals = _visitors.where((v) => v['status'] == 'Pending Approval').length +
        _requests.where((r) => r['status'] == 'Pending').length;
    final checkedOutCount = _visitors.where((v) => v['status'] == 'Checked Out').length;
    final vehiclesInside = _vehicles.where((vh) => vh['status'] == 'Inside').length;
    final confirmedAppts = _appointments.where((a) => a['status'] == 'Confirmed').length;

    final filteredRoster = _visitors.where((v) {
      if (_rosterFilter == 'ALL') return true;
      return v['status'] == _rosterFilter;
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
                    Text('Visitor Operations Center', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                    Text('Live plant security posture, gate flow & ATEX visitor tracking', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, color: Color(0xFF2563EB)),
                tooltip: 'Refresh Feed',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.onNavigate('gate-checkin'),
                  icon: const Icon(Icons.qr_code_scanner, size: 16),
                  label: const Text('Quick Check-In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (widget.screenPerm.canCreate)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onNavigate('registration'),
                    icon: const Icon(Icons.badge_outlined, size: 16),
                    label: const Text('New Visitor Pass'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (overdueList.isNotEmpty)
            ModuleAlertBanner(
              title: '${overdueList.length} Overdue / Overstaying Visitor(s) On-Site',
              subtitle: 'Visitors have exceeded their authorized pass duration and require immediate security muster check.',
              borderColor: const Color(0xFFDC2626),
              bgColor: const Color(0xFFFEF2F2),
              iconColor: const Color(0xFFB91C1C),
              actionLabel: 'Inspect Overdue',
              onAction: () => widget.onNavigate('overdue-tracking'),
            ),
          ModuleKpiGrid(items: [
            ModuleKpiItem(label: 'Visitors Inside Plant', value: '$checkedInCount', subtext: 'Active RFID badges', accentColor: const Color(0xFF059669), icon: Icons.groups_outlined, onTap: () => widget.onNavigate('live-tracking')),
            ModuleKpiItem(label: 'Pending Approvals', value: '$pendingApprovals', subtext: 'Host/EHS clearance', accentColor: const Color(0xFFD97706), icon: Icons.pending_actions_outlined, onTap: () => widget.onNavigate('approvals')),
            ModuleKpiItem(label: 'Overdue Alerts', value: '${overdueList.length}', subtext: 'Exceeded pass time', accentColor: const Color(0xFFDC2626), icon: Icons.warning_amber_rounded, onTap: () => widget.onNavigate('overdue-tracking')),
            ModuleKpiItem(label: 'Checked Out Today', value: '$checkedOutCount', subtext: 'Cleared & exited', accentColor: const Color(0xFF2563EB), icon: Icons.logout_outlined, onTap: () => widget.onNavigate('history')),
            ModuleKpiItem(label: 'Vehicles Inside', value: '$vehiclesInside', subtext: 'Spark-arrested fleet', accentColor: const Color(0xFF7C3AED), icon: Icons.local_shipping_outlined, onTap: () => widget.onNavigate('security-vehicles')),
            ModuleKpiItem(label: 'Pre-Booked Appts', value: '$confirmedAppts', subtext: 'Confirmed slots', accentColor: const Color(0xFF0891B2), icon: Icons.calendar_today_outlined, onTap: () => widget.onNavigate('appointments')),
          ]),
          const SizedBox(height: 14),
          // 5 Quick Action Feature Tiles
          Text('Gate & Security Modules', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _featureTile('Gate Passes', Icons.badge_outlined, const Color(0xFF2563EB), () => widget.onNavigate('gate-pass')),
              _featureTile('Material Gate', Icons.inventory_outlined, const Color(0xFFEA580C), () => widget.onNavigate('material-inward')),
              _featureTile('ATEX Safety', Icons.health_and_safety_outlined, const Color(0xFF059669), () => widget.onNavigate('safety-clearance')),
              _featureTile('Zone Matrix', Icons.security_outlined, const Color(0xFF7C3AED), () => widget.onNavigate('access-management')),
              _featureTile('Live Muster', Icons.radar_outlined, const Color(0xFFDC2626), () => widget.onNavigate('live-tracking')),
            ],
          ),
          const SizedBox(height: 16),
          // Today's Roster with filter pills
          Row(
            children: [
              Expanded(child: Text("Today's Gate Roster", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)))),
              TextButton(
                onPressed: () => widget.onNavigate('list'),
                child: const Text('View Directory →'),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['ALL', 'Checked In', 'Pending Approval', 'Overdue', 'Checked Out'].map((f) {
                final selected = _rosterFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(f, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : const Color(0xFF334155))),
                    selected: selected,
                    selectedColor: const Color(0xFF2563EB),
                    onSelected: (_) => setState(() => _rosterFilter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
          else if (filteredRoster.isEmpty)
            const ModuleEmptyState(
              icon: Icons.badge_outlined,
              title: 'No Visitors in Roster',
              subtitle: 'Register a new visitor pass or verify pending visit requests.',
            )
          else
            ...filteredRoster.take(15).map((v) {
              final st = (v['status'] ?? 'Pending Approval').toString();
              final Color bg = st == 'Checked In'
                  ? const Color(0xFFD1FAE5)
                  : (st == 'Overdue'
                      ? const Color(0xFFFEE2E2)
                      : (st == 'Checked Out' ? const Color(0xFFE2E8F0) : const Color(0xFFFEF3C7)));
              final Color fg = st == 'Checked In'
                  ? const Color(0xFF059669)
                  : (st == 'Overdue'
                      ? const Color(0xFFDC2626)
                      : (st == 'Checked Out' ? const Color(0xFF475569) : const Color(0xFFD97706)));
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: Text(
                        ((v['name'] ?? 'V').toString().isNotEmpty ? (v['name'] ?? 'V').toString()[0] : 'V').toUpperCase(),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${v['name'] ?? '-'} (${v['passNumber'] ?? v['id'] ?? '-'})',
                              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                          Text('${v['company'] ?? '-'} • Host: ${v['hostName'] ?? '-'}',
                              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    ModuleTag(text: st, bgColor: bg, textColor: fg),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _featureTile(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 106,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }
}
