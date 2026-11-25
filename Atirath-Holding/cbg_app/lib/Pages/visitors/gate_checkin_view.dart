import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/visitor_data_service.dart';
import '../../widgets/module_ui_widgets.dart';

class GateCheckinView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const GateCheckinView({super.key, required this.screenPerm, required this.onNavigate});

  @override
  State<GateCheckinView> createState() => _GateCheckinViewState();
}

class _GateCheckinViewState extends State<GateCheckinView> {
  List<Map<String, dynamic>> _visitors = [];
  bool _isLoading = true;
  String _searchTerm = '';
  Map<String, dynamic>? _selected;
  final TextEditingController _rfidCtrl = TextEditingController();
  bool _ppeVerified = false;
  bool _govtIdVerified = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _rfidCtrl.dispose();
    super.dispose();
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

  Future<void> _executeCheckIn() async {
    if (_selected == null) return;
    if (!_ppeVerified || !_govtIdVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verify Govt ID & Mandatory PPE Kit before gate check-in.'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }
    final v = _selected!;
    final updatedRecord = {
      ...v,
      'rfidTag': _rfidCtrl.text.trim().isEmpty ? (v['rfidTag'] ?? 'RFID-GATE') : _rfidCtrl.text.trim(),
      'ppeIssued': true,
      'status': 'Checked In',
      'checkInTime': DateTime.now().toIso8601String(),
    };
    final updatedList = _visitors.map((x) => x['id'].toString() == v['id'].toString() ? updatedRecord : x).toList();
    setState(() {
      _visitors = updatedList;
      _selected = null;
      _ppeVerified = false;
      _govtIdVerified = false;
    });
    await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.visitors, updatedList);
    await VisitorDataService.instance.apiCheckInVisitor(v['id']);
    await VisitorDataService.instance.apiUpdateVisitorRecord(v['id'], updatedRecord);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${v['name']} checked in at main security gate.'), backgroundColor: const Color(0xFF059669)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final awaiting = _visitors.where((v) => v['status'] != 'Checked In').where((v) {
      final q = _searchTerm.trim().toLowerCase();
      return q.isEmpty ||
          (v['name'] ?? '').toString().toLowerCase().contains(q) ||
          (v['passNumber'] ?? v['id'] ?? '').toString().toLowerCase().contains(q) ||
          (v['phone'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text('Gate Check-In Console', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
          Text('Verify pass, assign RFID tag & clear physical entry at security gate', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          TextField(
            decoration: moduleInputDecoration('Lookup visitor name, Pass No, phone...'),
            onChanged: (v) => setState(() => _searchTerm = v),
          ),
          const SizedBox(height: 12),
          if (_selected != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF10B981))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Checking In: ${_selected!['name'] ?? '-'}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selected = null)),
                    ],
                  ),
                  Text('Pass: ${_selected!['passNumber'] ?? _selected!['id']} • Host: ${_selected!['hostName'] ?? '-'}',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155))),
                  const SizedBox(height: 10),
                  TextField(controller: _rfidCtrl, decoration: moduleInputDecoration('Assign / Confirm RFID Tag')),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _govtIdVerified,
                    onChanged: (v) => setState(() => _govtIdVerified = v ?? false),
                    title: Text('Original Govt ID Checked (${_selected!['idType'] ?? 'ID'}: ${_selected!['idNumber'] ?? '-'})', style: GoogleFonts.inter(fontSize: 12.5)),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _ppeVerified,
                    onChanged: (v) => setState(() => _ppeVerified = v ?? false),
                    title: Text('PPE Kit & Safety Badge Issued for Zone Entry', style: GoogleFonts.inter(fontSize: 12.5)),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.screenPerm.canEdit ? _executeCheckIn : null,
                      icon: const Icon(Icons.login, size: 16),
                      label: const Text('Confirm Gate Entry & Check-In'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (awaiting.isEmpty)
            const ModuleEmptyState(icon: Icons.how_to_reg_outlined, title: 'No Visitors Awaiting Gate Check-In', subtitle: 'Register a visitor pass or search for returning visitors.')
          else
            ...awaiting.map((v) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${v['name'] ?? '-'} (${v['passNumber'] ?? v['id']})', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                            Text('${v['company'] ?? '-'} • Host: ${v['hostName'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() {
                          _selected = v;
                          _rfidCtrl.text = (v['rfidTag'] ?? '').toString();
                          _ppeVerified = false;
                          _govtIdVerified = false;
                        }),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                        child: const Text('Select'),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
