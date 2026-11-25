import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/visitor_data_service.dart';
import '../../widgets/module_ui_widgets.dart';

class AppointmentManagementView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const AppointmentManagementView({
    super.key,
    required this.screenPerm,
    required this.onNavigate,
  });

  @override
  State<AppointmentManagementView> createState() => _AppointmentManagementViewState();
}

class _AppointmentManagementViewState extends State<AppointmentManagementView> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await VisitorDataService.instance.getStoredList(VisitorStorageKeys.appointments);
    if (mounted) {
      setState(() {
        _appointments = list;
        _isLoading = false;
      });
    }
  }

  void _openScheduleModal() {
    final formKey = GlobalKey<FormState>();
    final guestCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final hostCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T').first);
    final slotCtrl = TextEditingController(text: '10:30 AM - 12:00 PM');
    final roomCtrl = TextEditingController(text: 'Plant Conference Room A');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Schedule Plant Appointment', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(controller: guestCtrl, decoration: moduleInputDecoration('Guest / Delegate Name *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                const SizedBox(height: 10),
                TextFormField(controller: companyCtrl, decoration: moduleInputDecoration('Organization')),
                const SizedBox(height: 10),
                TextFormField(controller: hostCtrl, decoration: moduleInputDecoration('Host Employee *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextFormField(controller: dateCtrl, decoration: moduleInputDecoration('Date'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(controller: slotCtrl, decoration: moduleInputDecoration('Time Slot'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(controller: roomCtrl, decoration: moduleInputDecoration('Meeting Location / Bay')),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final item = {
                        'id': 'APT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                        'guestName': guestCtrl.text.trim(),
                        'company': companyCtrl.text.trim(),
                        'hostName': hostCtrl.text.trim(),
                        'date': dateCtrl.text.trim(),
                        'timeSlot': slotCtrl.text.trim(),
                        'location': roomCtrl.text.trim(),
                        'status': 'Confirmed',
                      };
                      final updated = [item, ..._appointments];
                      setState(() => _appointments = updated);
                      await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.appointments, updated);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                    child: const Text('Confirm Appointment'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateAppointmentStatus(Map<String, dynamic> apt, String status) async {
    final updated = _appointments.map((a) => a['id'].toString() == apt['id'].toString() ? {...a, 'status': status} : a).toList();
    setState(() => _appointments = updated);
    await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.appointments, updated);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _appointments.where((a) {
      final q = _searchTerm.trim().toLowerCase();
      return q.isEmpty ||
          (a['guestName'] ?? '').toString().toLowerCase().contains(q) ||
          (a['hostName'] ?? '').toString().toLowerCase().contains(q) ||
          (a['company'] ?? '').toString().toLowerCase().contains(q);
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
                    Text('Appointment Scheduling', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('Pre-booked delegation slots & conference bay allocations', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              if (widget.screenPerm.canCreate)
                ElevatedButton.icon(
                  onPressed: _openScheduleModal,
                  icon: const Icon(Icons.event_available, size: 15),
                  label: const Text('Schedule'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: moduleInputDecoration('Search guest, host, organization...'),
            onChanged: (v) => setState(() => _searchTerm = v),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(icon: Icons.calendar_month_outlined, title: 'No Appointments Scheduled', subtitle: 'Book confirmed time slots for external delegations & auditors.')
          else
            ...filtered.map((a) {
              final st = (a['status'] ?? 'Confirmed').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ModuleTag(text: '${a['id'] ?? ''}', bgColor: const Color(0xFFEFF6FF), textColor: const Color(0xFF1D4ED8)),
                        const Spacer(),
                        ModuleTag(
                          text: st,
                          bgColor: st == 'Confirmed' ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                          textColor: st == 'Confirmed' ? const Color(0xFF059669) : const Color(0xFFDC2626),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${a['guestName'] ?? '-'} (${a['company'] ?? '-'})', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    Text('Host: ${a['hostName'] ?? '-'} • ${a['location'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                    Text('Slot: ${a['date'] ?? '-'} | ${a['timeSlot'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
                    if (widget.screenPerm.canEdit) ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (st != 'Confirmed')
                            TextButton(onPressed: () => _updateAppointmentStatus(a, 'Confirmed'), child: const Text('Confirm')),
                          if (st != 'Cancelled')
                            TextButton(onPressed: () => _updateAppointmentStatus(a, 'Cancelled'), child: const Text('Cancel', style: TextStyle(color: Color(0xFFDC2626)))),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
