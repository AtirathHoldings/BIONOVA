import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/visitor_data_service.dart';
import '../../widgets/module_ui_widgets.dart';

class VisitorAccessManagementView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const VisitorAccessManagementView({super.key, required this.screenPerm, required this.onNavigate});

  @override
  State<VisitorAccessManagementView> createState() => _VisitorAccessManagementViewState();
}

class _VisitorAccessManagementViewState extends State<VisitorAccessManagementView> {
  List<Map<String, dynamic>> _visitors = [];
  bool _isLoading = true;
  String _searchTerm = '';
  String _zoneFilter = 'ALL';

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

  List<String> _getZones(Map<String, dynamic> v) {
    final z = v['allowedZones'];
    if (z is List) return z.map((e) => e.toString()).toList();
    return ['Z1'];
  }

  Future<void> _toggleZone(Map<String, dynamic> visitor, String zoneId) async {
    if (!widget.screenPerm.canEdit) return;
    final current = _getZones(visitor);
    if (current.contains(zoneId)) {
      if (current.length > 1) current.remove(zoneId);
    } else {
      current.add(zoneId);
    }
    final updatedRecord = {...visitor, 'allowedZones': current};
    final updatedList = _visitors.map((x) => x['id'].toString() == visitor['id'].toString() ? updatedRecord : x).toList();
    setState(() => _visitors = updatedList);
    await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.visitors, updatedList);
    await VisitorDataService.instance.apiUpdateVisitorRecord(visitor['id'], updatedRecord);
  }

  @override
  Widget build(BuildContext context) {
    final activeVisitors = _visitors.where((v) => v['status'] == 'Checked In').toList();

    final filtered = _visitors.where((v) {
      final q = _searchTerm.trim().toLowerCase();
      final matchQ = q.isEmpty ||
          (v['name'] ?? '').toString().toLowerCase().contains(q) ||
          (v['passNumber'] ?? v['id'] ?? '').toString().toLowerCase().contains(q);
      final matchZone = _zoneFilter == 'ALL' || _getZones(v).contains(_zoneFilter);
      return matchQ && matchZone;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text('Plant Zone Access Control Matrix', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
          Text('Live visitor occupancy & RFID zone clearance across ATEX zones Z1-Z5', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          // 5 Plant Zone Cards
          ...VisitorDataService.initialZones.map((zone) {
            final count = activeVisitors.where((v) => _getZones(v).contains(zone.id)).length;
            final zColor = Color(zone.colorHex);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border(left: BorderSide(color: zColor, width: 4), top: const BorderSide(color: Color(0xFFE2E8F0)), right: const BorderSide(color: Color(0xFFE2E8F0)), bottom: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('${zone.id} (${zone.code})', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800, color: zColor)),
                            const SizedBox(width: 6),
                            ModuleTag(text: zone.riskLevel, bgColor: zColor.withValues(alpha: 0.12), textColor: zColor),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(zone.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                        Text('PPE: ${zone.ppeMandatory.join(', ')}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text('$count', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: zColor)),
                      Text('Active', style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(decoration: moduleInputDecoration('Search visitor or pass no...'), onChanged: (v) => setState(() => _searchTerm = v)),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('zflt-$_zoneFilter'),
                  initialValue: _zoneFilter,
                  decoration: moduleInputDecoration('Zone'),
                  items: [
                    const DropdownMenuItem(value: 'ALL', child: Text('All Zones')),
                    ...VisitorDataService.initialZones.map((z) => DropdownMenuItem(value: z.id, child: Text('${z.id} (${z.code})'))),
                  ],
                  onChanged: (v) => setState(() => _zoneFilter = v ?? 'ALL'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(icon: Icons.security_outlined, title: 'No Visitors Found', subtitle: 'No visitors match the selected zone access filters.')
          else
            ...filtered.map((v) {
              final allowed = _getZones(v);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${v['name'] ?? '-'} (${v['passNumber'] ?? v['id']})', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    Text('${v['company'] ?? '-'} • ${v['status'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: VisitorDataService.initialZones.map((z) {
                        final has = allowed.contains(z.id);
                        final zCol = Color(z.colorHex);
                        return FilterChip(
                          label: Text(z.id, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: has ? zCol : const Color(0xFF64748B))),
                          selected: has,
                          selectedColor: zCol.withValues(alpha: 0.16),
                          onSelected: widget.screenPerm.canEdit ? (_) => _toggleZone(v, z.id) : null,
                        );
                      }).toList(),
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
