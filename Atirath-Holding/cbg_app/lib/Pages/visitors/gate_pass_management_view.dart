import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/visitor_data_service.dart';
import '../../widgets/module_ui_widgets.dart';

class GatePassManagementView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const GatePassManagementView({super.key, required this.screenPerm, required this.onNavigate});

  @override
  State<GatePassManagementView> createState() => _GatePassManagementViewState();
}

class _GatePassManagementViewState extends State<GatePassManagementView> {
  List<Map<String, dynamic>> _visitors = [];
  bool _isLoading = true;
  String? _selectedPassId;

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
        if (list.isNotEmpty && _selectedPassId == null) {
          _selectedPassId = (list.first['id'] ?? '').toString();
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _visitors.where((v) => v['id'].toString() == _selectedPassId).firstOrNull ?? (_visitors.isNotEmpty ? _visitors.first : null);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text('Gate Pass Management & Badge Print', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
          Text('Select an active pass to preview or print high-visibility ATEX gate badge', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_visitors.isEmpty)
            const ModuleEmptyState(icon: Icons.badge_outlined, title: 'No Gate Passes Issued', subtitle: 'Register a visitor to generate a printable RFID gate pass badge.')
          else ...[
            DropdownButtonFormField<String>(
              key: ValueKey('pass-${selected?['id']}'),
              initialValue: selected?['id']?.toString(),
              isExpanded: true,
              decoration: moduleInputDecoration('Select Visitor Gate Pass'),
              items: _visitors.map((v) => DropdownMenuItem<String>(
                value: v['id'].toString(),
                child: Text('${v['passNumber'] ?? v['id']} - ${v['name'] ?? '-'}', overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (v) => setState(() => _selectedPassId = v),
            ),
            const SizedBox(height: 16),
            if (selected != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0F172A), width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user, color: Color(0xFF38BDF8), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('BIONOVA BIOGAS PLANT • GATE PASS', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                          ),
                          ModuleTag(text: '${selected['status'] ?? '-'}', bgColor: Colors.white, textColor: const Color(0xFF0F172A)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text((selected['name'] ?? '-').toString(), style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                    Text('${selected['company'] ?? '-'} • ${selected['category'] ?? '-'}', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
                    const Divider(height: 22),
                    _badgeRow('Pass Number', '${selected['passNumber'] ?? selected['id']}'),
                    _badgeRow('RFID Badge', '${selected['rfidTag'] ?? 'Unassigned'}'),
                    _badgeRow('Meeting Host', '${selected['hostName'] ?? '-'}'),
                    _badgeRow('Plant Unit', '${selected['plantLocation'] ?? '-'}'),
                    _badgeRow('Authorized Zones', (selected['allowedZones'] is List) ? (selected['allowedZones'] as List).join(', ') : '${selected['allowedZones'] ?? 'Z1'}'),
                    _badgeRow('PPE Cleared', selected['ppeIssued'] == true ? 'Verified & Issued' : 'Pending'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final zones = (selected['allowedZones'] is List) ? (selected['allowedZones'] as List).join(', ') : '${selected['allowedZones'] ?? 'Z1'}';
                          showPrintablePreviewDialog(
                            context,
                            title: 'Print Gate Badge • ${selected['passNumber'] ?? selected['id']}',
                            copyText: 'BIONOVA GATE PASS\nName: ${selected['name']}\nPass: ${selected['passNumber'] ?? selected['id']}\nRFID: ${selected['rfidTag']}\nCompany: ${selected['company']}\nHost: ${selected['hostName']}\nZones: $zones\nStatus: ${selected['status']}',
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${selected['name']} (${selected['passNumber'] ?? selected['id']})', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15)),
                                const SizedBox(height: 6),
                                Text('Company: ${selected['company']}'),
                                Text('Host: ${selected['hostName']}'),
                                Text('RFID: ${selected['rfidTag'] ?? '-'}'),
                                Text('Zones: $zones'),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.print_outlined, size: 16),
                        label: const Text('Print / Copy Gate Pass'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _badgeRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          Flexible(child: Text(v, textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)))),
        ],
      ),
    );
  }
}
