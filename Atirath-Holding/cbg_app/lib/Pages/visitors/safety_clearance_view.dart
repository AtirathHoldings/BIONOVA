import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/visitor_data_service.dart';
import '../../widgets/module_ui_widgets.dart';

class SafetyClearanceView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const SafetyClearanceView({super.key, required this.screenPerm, required this.onNavigate});

  @override
  State<SafetyClearanceView> createState() => _SafetyClearanceViewState();
}

class _SafetyClearanceViewState extends State<SafetyClearanceView> {
  List<Map<String, dynamic>> _clearances = [];
  bool _isLoading = true;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await VisitorDataService.instance.getStoredList(VisitorStorageKeys.safetyClearance);
    if (mounted) {
      setState(() {
        _clearances = list;
        _isLoading = false;
      });
    }
  }

  void _openInductionModal() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final officerCtrl = TextEditingController();
    bool helmet = true;
    bool safetyShoes = true;
    bool h2sBadge = false;
    bool emergencyBriefed = true;
    bool sparkFree = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Record ATEX Safety Induction', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: nameCtrl, decoration: moduleInputDecoration('Visitor / Contractor Name *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: companyCtrl, decoration: moduleInputDecoration('Company'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: officerCtrl, decoration: moduleInputDecoration('EHS Officer *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(contentPadding: EdgeInsets.zero, value: helmet, onChanged: (v) => setModalState(() => helmet = v ?? true), title: const Text('Hard Hat & Hi-Vis Vest Verified')),
                  CheckboxListTile(contentPadding: EdgeInsets.zero, value: safetyShoes, onChanged: (v) => setModalState(() => safetyShoes = v ?? true), title: const Text('Anti-Static / Steel-Toe Safety Shoes Verified')),
                  CheckboxListTile(contentPadding: EdgeInsets.zero, value: h2sBadge, onChanged: (v) => setModalState(() => h2sBadge = v ?? false), title: const Text('Personal H2S / LEL Gas Detector Issued')),
                  CheckboxListTile(contentPadding: EdgeInsets.zero, value: sparkFree, onChanged: (v) => setModalState(() => sparkFree = v ?? true), title: const Text('Zero Ignition Sources / Non-ATEX Phones Surrendered')),
                  CheckboxListTile(contentPadding: EdgeInsets.zero, value: emergencyBriefed, onChanged: (v) => setModalState(() => emergencyBriefed = v ?? true), title: const Text('Emergency Muster Point & Siren Protocol Briefed')),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final cleared = helmet && safetyShoes && emergencyBriefed && sparkFree;
                        final item = {
                          'id': 'EHS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                          'visitorName': nameCtrl.text.trim(),
                          'company': companyCtrl.text.trim(),
                          'ehsOfficer': officerCtrl.text.trim(),
                          'ppeHelmet': helmet,
                          'ppeShoes': safetyShoes,
                          'h2sBadge': h2sBadge,
                          'sparkFree': sparkFree,
                          'emergencyBriefed': emergencyBriefed,
                          'status': cleared ? 'ATEX Cleared' : 'Hold / Incomplete',
                          'inductedAt': DateTime.now().toIso8601String(),
                        };
                        final updated = [item, ..._clearances];
                        setState(() => _clearances = updated);
                        await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.safetyClearance, updated);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('Issue EHS Safety Certificate'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clearedCount = _clearances.where((c) => c['status'] == 'ATEX Cleared').length;
    final filtered = _clearances.where((c) {
      final q = _searchTerm.trim().toLowerCase();
      return q.isEmpty ||
          (c['visitorName'] ?? '').toString().toLowerCase().contains(q) ||
          (c['company'] ?? '').toString().toLowerCase().contains(q);
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
                    Text('ATEX Safety & PPE Clearance', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('Mandatory induction logs, PPE kits & H2S zone safety compliance', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              if (widget.screenPerm.canCreate)
                ElevatedButton.icon(
                  onPressed: _openInductionModal,
                  icon: const Icon(Icons.health_and_safety, size: 15),
                  label: const Text('Induct'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const ModuleAlertBanner(
            title: 'Mandatory PESO & ATEX Zone-1 Biogas Plant Safety Protocol',
            subtitle: 'No contractor or visitor may enter Digester (Z3), Scrubber (Z4), or CBG Cascade (Z5) areas without verified induction, PPE kit, and spark-free check.',
            borderColor: Color(0xFFDC2626),
            bgColor: Color(0xFFFEF2F2),
            iconColor: Color(0xFFB91C1C),
          ),
          ModuleKpiGrid(items: [
            ModuleKpiItem(label: 'Safety Inductions', value: '${_clearances.length}', subtext: 'Logged records', accentColor: const Color(0xFF2563EB), icon: Icons.assignment_turned_in_outlined),
            ModuleKpiItem(label: 'ATEX Cleared', value: '$clearedCount', subtext: 'Full PPE verified', accentColor: const Color(0xFF059669), icon: Icons.verified_user_outlined),
          ]),
          const SizedBox(height: 12),
          TextField(decoration: moduleInputDecoration('Search visitor or company...'), onChanged: (v) => setState(() => _searchTerm = v)),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(icon: Icons.health_and_safety_outlined, title: 'No Safety Inductions Logged', subtitle: 'Record mandatory visitor & contractor EHS safety inductions.')
          else
            ...filtered.map((c) {
              final st = (c['status'] ?? 'ATEX Cleared').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ModuleTag(text: '${c['id'] ?? ''}', bgColor: const Color(0xFFEFF6FF), textColor: const Color(0xFF1D4ED8)),
                        const Spacer(),
                        ModuleTag(
                          text: st,
                          bgColor: st == 'ATEX Cleared' ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                          textColor: st == 'ATEX Cleared' ? const Color(0xFF059669) : const Color(0xFFDC2626),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${c['visitorName'] ?? '-'} (${c['company'] ?? '-'})', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    Text('Inducted By: ${c['ehsOfficer'] ?? '-'} • H2S Badge: ${c['h2sBadge'] == true ? 'Issued' : 'No'}',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
