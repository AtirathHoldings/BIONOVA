import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/visitor_data_service.dart';
import '../../widgets/module_ui_widgets.dart';

class VisitorListView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const VisitorListView({
    super.key,
    required this.screenPerm,
    required this.onNavigate,
  });

  @override
  State<VisitorListView> createState() => _VisitorListViewState();
}

class _VisitorListViewState extends State<VisitorListView> {
  List<Map<String, dynamic>> _visitors = [];
  bool _isLoading = true;
  String _searchTerm = '';
  String _statusFilter = 'ALL';
  String _categoryFilter = 'ALL';
  String _plantFilter = 'ALL';

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

  Future<void> _updateStatus(Map<String, dynamic> visitor, String newStatus) async {
    final now = DateTime.now().toIso8601String();
    final updatedRecord = {
      ...visitor,
      'status': newStatus,
      if (newStatus == 'Checked In') 'checkInTime': visitor['checkInTime'] ?? now,
      if (newStatus == 'Checked Out') 'checkOutTime': now,
    };
    final updatedList = _visitors.map((v) => v['id'].toString() == visitor['id'].toString() ? updatedRecord : v).toList();
    setState(() => _visitors = updatedList);
    await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.visitors, updatedList);
    if (newStatus == 'Checked In') {
      await VisitorDataService.instance.apiCheckInVisitor(visitor['id']);
    } else if (newStatus == 'Checked Out') {
      await VisitorDataService.instance.apiCheckOutVisitor(visitor['id']);
    } else {
      await VisitorDataService.instance.apiUpdateVisitorRecord(visitor['id'], updatedRecord);
    }
  }

  void _showDigitalPass(Map<String, dynamic> v) {
    final zones = (v['allowedZones'] is List) ? (v['allowedZones'] as List).join(', ') : (v['allowedZones'] ?? 'Z1').toString();
    showPrintablePreviewDialog(
      context,
      title: 'Digital Visitor Pass • ${v['passNumber'] ?? v['id']}',
      copyText: 'BIONOVA VISITOR PASS\nPass: ${v['passNumber'] ?? v['id']}\nRFID: ${v['rfidTag'] ?? '-'}\nName: ${v['name']}\nCompany: ${v['company']}\nHost: ${v['hostName']}\nZones: $zones\nStatus: ${v['status']}',
      content: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFCBD5E1))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text((v['name'] ?? '-').toString(), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
            Text('${v['company'] ?? '-'} • ${v['category'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF475569))),
            const Divider(),
            Text('Pass No: ${v['passNumber'] ?? v['id']}'),
            Text('RFID Badge: ${v['rfidTag'] ?? '-'}'),
            Text('Host: ${v['hostName'] ?? '-'}'),
            Text('Plant: ${v['plantLocation'] ?? '-'}'),
            Text('Authorized Zones: $zones'),
            Text('Status: ${v['status'] ?? '-'}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _visitors.where((v) {
      final q = _searchTerm.trim().toLowerCase();
      final matchQ = q.isEmpty ||
          (v['name'] ?? '').toString().toLowerCase().contains(q) ||
          (v['company'] ?? '').toString().toLowerCase().contains(q) ||
          (v['passNumber'] ?? v['id'] ?? '').toString().toLowerCase().contains(q) ||
          (v['phone'] ?? '').toString().toLowerCase().contains(q);
      final matchStatus = _statusFilter == 'ALL' || v['status'] == _statusFilter;
      final matchCategory = _categoryFilter == 'ALL' || v['category'] == _categoryFilter;
      final matchPlant = _plantFilter == 'ALL' || v['plantLocation'] == _plantFilter;
      return matchQ && matchStatus && matchCategory && matchPlant;
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
                    Text('Master Visitor Directory', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                    Text('${_visitors.length} total visitor records across plant gates', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined, color: Color(0xFF2563EB)),
                onPressed: () => exportCsvData(
                  context,
                  fileName: 'visitor_directory.csv',
                  headers: const ['Pass No', 'Name', 'Phone', 'Company', 'Category', 'Host', 'Plant', 'Status'],
                  rows: filtered
                      .map((v) => [
                            v['passNumber'] ?? v['id'] ?? '',
                            v['name'] ?? '',
                            v['phone'] ?? '',
                            v['company'] ?? '',
                            v['category'] ?? '',
                            v['hostName'] ?? '',
                            v['plantLocation'] ?? '',
                            v['status'] ?? '',
                          ])
                      .toList(),
                ),
              ),
              if (widget.screenPerm.canCreate)
                ElevatedButton.icon(
                  onPressed: () => widget.onNavigate('registration'),
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('New Pass'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              children: [
                TextField(
                  decoration: moduleInputDecoration('Search name, pass no, company, phone...'),
                  onChanged: (v) => setState(() => _searchTerm = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('vst-$_statusFilter'),
                        initialValue: _statusFilter,
                        isExpanded: true,
                        decoration: moduleInputDecoration('Status'),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
                          DropdownMenuItem(value: 'Checked In', child: Text('Checked In')),
                          DropdownMenuItem(value: 'Pending Approval', child: Text('Pending Approval')),
                          DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
                          DropdownMenuItem(value: 'Checked Out', child: Text('Checked Out')),
                          DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                        ],
                        onChanged: (v) => setState(() => _statusFilter = v ?? 'ALL'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('vcat-$_categoryFilter'),
                        initialValue: _categoryFilter,
                        isExpanded: true,
                        decoration: moduleInputDecoration('Category'),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Categories')),
                          DropdownMenuItem(value: 'Vendor / Contractor', child: Text('Vendor / Contractor')),
                          DropdownMenuItem(value: 'Auditor / Inspector', child: Text('Auditor')),
                          DropdownMenuItem(value: 'VIP / Client / Investor', child: Text('VIP / Client')),
                          DropdownMenuItem(value: 'Transporter / Driver', child: Text('Driver')),
                          DropdownMenuItem(value: 'Interview / Candidate', child: Text('Candidate')),
                        ],
                        onChanged: (v) => setState(() => _categoryFilter = v ?? 'ALL'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey('vplt-$_plantFilter'),
                  initialValue: _plantFilter,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Plant Location'),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All Plant Locations')),
                    DropdownMenuItem(value: 'BioNova CBG Plant - Unit 1', child: Text('BioNova CBG Plant - Unit 1')),
                    DropdownMenuItem(value: 'BioNova CBG Plant - Unit 2', child: Text('BioNova CBG Plant - Unit 2')),
                    DropdownMenuItem(value: 'Corporate HQ & Labs', child: Text('Corporate HQ & Labs')),
                  ],
                  onChanged: (v) => setState(() => _plantFilter = v ?? 'ALL'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(
              icon: Icons.people_outline,
              title: 'No Visitors Match Filters',
              subtitle: 'Register a visitor pass or reset filters.',
            )
          else
            ...filtered.map((v) {
              final st = (v['status'] ?? 'Pending Approval').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ModuleTag(text: '${v['passNumber'] ?? v['id']}', bgColor: const Color(0xFFEFF6FF), textColor: const Color(0xFF1D4ED8)),
                        const SizedBox(width: 6),
                        if ((v['rfidTag'] ?? '').toString().isNotEmpty)
                          ModuleTag(text: '${v['rfidTag']}', bgColor: const Color(0xFFF1F5F9), textColor: const Color(0xFF334155)),
                        const Spacer(),
                        ModuleTag(
                          text: st,
                          bgColor: st == 'Checked In'
                              ? const Color(0xFFD1FAE5)
                              : (st == 'Overdue' ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7)),
                          textColor: st == 'Checked In'
                              ? const Color(0xFF059669)
                              : (st == 'Overdue' ? const Color(0xFFDC2626) : const Color(0xFFD97706)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${v['name'] ?? '-'} • ${v['company'] ?? '-'}', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    Text('Phone: ${v['phone'] ?? '-'} • Host: ${v['hostName'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                    Text('${v['category'] ?? '-'} • ${v['plantLocation'] ?? '-'}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                    const Divider(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showDigitalPass(v),
                          icon: const Icon(Icons.badge_outlined, size: 15),
                          label: const Text('Digital Pass'),
                        ),
                        if (widget.screenPerm.canEdit && (st == 'Pending Approval' || st == 'Checked Out'))
                          ElevatedButton(
                            onPressed: () => _updateStatus(v, 'Checked In'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                            child: Text(st == 'Checked Out' ? 'Re-Admit' : 'Approve & Check-In'),
                          ),
                        if (widget.screenPerm.canEdit && (st == 'Checked In' || st == 'Overdue'))
                          ElevatedButton(
                            onPressed: () => _updateStatus(v, 'Checked Out'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white, minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                            child: const Text('Check Out'),
                          ),
                      ],
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
