import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/visitor_data_service.dart';
import '../../widgets/module_ui_widgets.dart';

class GateCheckoutView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const GateCheckoutView({super.key, required this.screenPerm, required this.onNavigate});

  @override
  State<GateCheckoutView> createState() => _GateCheckoutViewState();
}

class _GateCheckoutViewState extends State<GateCheckoutView> {
  List<Map<String, dynamic>> _visitors = [];
  bool _isLoading = true;
  String _searchTerm = '';
  Map<String, dynamic>? _selected;
  bool _rfidReturned = false;
  bool _ppeReturned = false;
  bool _materialsCleared = false;

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

  Future<void> _executeCheckOut() async {
    if (_selected == null) return;
    if (!_rfidReturned || !_ppeReturned || !_materialsCleared) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete RFID, PPE return & security baggage/material check first.'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }
    final v = _selected!;
    final updatedRecord = {
      ...v,
      'status': 'Checked Out',
      'checkOutTime': DateTime.now().toIso8601String(),
    };
    final updatedList = _visitors.map((x) => x['id'].toString() == v['id'].toString() ? updatedRecord : x).toList();
    setState(() {
      _visitors = updatedList;
      _selected = null;
      _rfidReturned = false;
      _ppeReturned = false;
      _materialsCleared = false;
    });
    await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.visitors, updatedList);
    await VisitorDataService.instance.apiCheckOutVisitor(v['id']);
    await VisitorDataService.instance.apiUpdateVisitorRecord(v['id'], updatedRecord);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${v['name']} checked out and RFID cleared.'), backgroundColor: const Color(0xFF059669)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final insideList = _visitors.where((v) => v['status'] == 'Checked In' || v['status'] == 'Overdue').where((v) {
      final q = _searchTerm.trim().toLowerCase();
      return q.isEmpty ||
          (v['name'] ?? '').toString().toLowerCase().contains(q) ||
          (v['passNumber'] ?? v['id'] ?? '').toString().toLowerCase().contains(q) ||
          (v['rfidTag'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text('Gate Check-Out & Badge Return', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
          Text('Collect RFID passes, inspect returnable PPE & log plant exit timestamps', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          TextField(
            decoration: moduleInputDecoration('Search visitor inside plant (name, Pass No, RFID)...'),
            onChanged: (v) => setState(() => _searchTerm = v),
          ),
          const SizedBox(height: 12),
          if (_selected != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEA580C))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Checking Out: ${_selected!['name'] ?? '-'}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selected = null)),
                    ],
                  ),
                  Text('RFID: ${_selected!['rfidTag'] ?? '-'} • Pass: ${_selected!['passNumber'] ?? _selected!['id']}',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155))),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _rfidReturned,
                    onChanged: (v) => setState(() => _rfidReturned = v ?? false),
                    title: Text('RFID Visitor Badge Collected & Deactivated', style: GoogleFonts.inter(fontSize: 12.5)),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _ppeReturned,
                    onChanged: (v) => setState(() => _ppeReturned = v ?? false),
                    title: Text('Loaned PPE Kit & Gas Detector Returned', style: GoogleFonts.inter(fontSize: 12.5)),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _materialsCleared,
                    onChanged: (v) => setState(() => _materialsCleared = v ?? false),
                    title: Text('No Unauthorized Tools / Plant Material Carried Out', style: GoogleFonts.inter(fontSize: 12.5)),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.screenPerm.canEdit ? _executeCheckOut : null,
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Complete Gate Check-Out'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (insideList.isEmpty)
            const ModuleEmptyState(icon: Icons.logout_outlined, title: 'No Active Visitors Inside', subtitle: 'All registered visitors have exited the premises.')
          else
            ...insideList.map((v) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${v['name'] ?? '-'} (${v['rfidTag'] ?? v['passNumber'] ?? v['id']})', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                            Text('${v['company'] ?? '-'} • ${v['status']}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() {
                          _selected = v;
                          _rfidReturned = false;
                          _ppeReturned = false;
                          _materialsCleared = false;
                        }),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white),
                        child: const Text('Check Out'),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
