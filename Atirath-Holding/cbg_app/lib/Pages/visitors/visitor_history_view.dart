import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/visitor_data_service.dart';
import '../../widgets/module_ui_widgets.dart';

class VisitorHistoryView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const VisitorHistoryView({super.key, required this.screenPerm, required this.onNavigate});

  @override
  State<VisitorHistoryView> createState() => _VisitorHistoryViewState();
}

class _VisitorHistoryViewState extends State<VisitorHistoryView> {
  List<Map<String, dynamic>> _visitors = [];
  bool _isLoading = true;
  String _searchTerm = '';

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

  @override
  Widget build(BuildContext context) {
    final checkedOut = _visitors.where((v) => v['status'] == 'Checked Out').toList();
    final filtered = checkedOut.where((v) {
      final q = _searchTerm.trim().toLowerCase();
      return q.isEmpty ||
          (v['name'] ?? '').toString().toLowerCase().contains(q) ||
          (v['company'] ?? '').toString().toLowerCase().contains(q) ||
          (v['passNumber'] ?? v['id'] ?? '').toString().toLowerCase().contains(q) ||
          (v['hostName'] ?? '').toString().toLowerCase().contains(q);
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
                    Text('Historical Visitor Audit Log', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('Completed visits archive with entry/exit audit trail', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined, color: Color(0xFF2563EB)),
                tooltip: 'Export Historical Audit Log CSV',
                onPressed: () => exportCsvData(
                  context,
                  fileName: 'visitor_audit_history.csv',
                  headers: const ['Pass No', 'Name', 'Company', 'Phone', 'Host', 'Check-In', 'Check-Out', 'Status'],
                  rows: filtered
                      .map((v) => [
                            v['passNumber'] ?? v['id'] ?? '',
                            v['name'] ?? '',
                            v['company'] ?? '',
                            v['phone'] ?? '',
                            v['hostName'] ?? '',
                            v['checkInTime'] ?? '',
                            v['checkOutTime'] ?? '',
                            v['status'] ?? '',
                          ])
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ModuleKpiGrid(items: [
            ModuleKpiItem(label: 'Archived Visits', value: '${checkedOut.length}', subtext: 'Completed gate exits', accentColor: const Color(0xFF2563EB), icon: Icons.history),
            ModuleKpiItem(label: 'Total Directory', value: '${_visitors.length}', subtext: 'Cumulative records', accentColor: const Color(0xFF059669), icon: Icons.folder_shared_outlined),
          ]),
          const SizedBox(height: 12),
          TextField(decoration: moduleInputDecoration('Search historical logs (name, company, pass, host)...'), onChanged: (v) => setState(() => _searchTerm = v)),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(icon: Icons.history_toggle_off, title: 'No Completed Visits Yet', subtitle: 'Checked-out visitors appear in this historical compliance ledger.')
          else
            ...filtered.map((v) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ModuleTag(text: '${v['passNumber'] ?? v['id']}', bgColor: const Color(0xFFF1F5F9), textColor: const Color(0xFF334155)),
                          const Spacer(),
                          const ModuleTag(text: 'Checked Out', bgColor: Color(0xFFE2E8F0), textColor: Color(0xFF475569)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${v['name'] ?? '-'} • ${v['company'] ?? '-'}', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800)),
                      Text('Host: ${v['hostName'] ?? '-'} • Purpose: ${v['purpose'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                      Text('In: ${v['checkInTime'] ?? '-'} | Out: ${v['checkOutTime'] ?? '-'}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
