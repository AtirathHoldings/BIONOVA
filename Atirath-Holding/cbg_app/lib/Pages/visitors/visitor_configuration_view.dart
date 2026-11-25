import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/visitor_data_service.dart';
import '../../widgets/module_ui_widgets.dart';

class VisitorConfigurationView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const VisitorConfigurationView({super.key, required this.screenPerm, required this.onNavigate});

  @override
  State<VisitorConfigurationView> createState() => _VisitorConfigurationViewState();
}

class _VisitorConfigurationViewState extends State<VisitorConfigurationView> {
  Map<String, dynamic> _config = VisitorDataService.initialConfig();
  bool _isLoading = true;
  final _plantCtrl = TextEditingController();
  final _maxHoursCtrl = TextEditingController();
  final _openCtrl = TextEditingController();
  final _closeCtrl = TextEditingController();
  final _overdueCtrl = TextEditingController();
  final _blkNameCtrl = TextEditingController();
  final _blkReasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _plantCtrl.dispose();
    _maxHoursCtrl.dispose();
    _openCtrl.dispose();
    _closeCtrl.dispose();
    _overdueCtrl.dispose();
    _blkNameCtrl.dispose();
    _blkReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cfg = await VisitorDataService.instance.getStoredConfig();
    if (mounted) {
      setState(() {
        _config = cfg;
        _plantCtrl.text = (cfg['plantName'] ?? 'BioNova Biogas Complex').toString();
        _maxHoursCtrl.text = (cfg['maxPassDurationHours'] ?? 8).toString();
        _openCtrl.text = (cfg['gateOpeningTime'] ?? '06:00 AM').toString();
        _closeCtrl.text = (cfg['gateClosingTime'] ?? '10:00 PM').toString();
        _overdueCtrl.text = (cfg['autoOverdueThresholdMinutes'] ?? 30).toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    final updated = {
      ..._config,
      'plantName': _plantCtrl.text.trim(),
      'maxPassDurationHours': int.tryParse(_maxHoursCtrl.text.trim()) ?? 8,
      'gateOpeningTime': _openCtrl.text.trim(),
      'gateClosingTime': _closeCtrl.text.trim(),
      'autoOverdueThresholdMinutes': int.tryParse(_overdueCtrl.text.trim()) ?? 30,
    };
    setState(() => _config = updated);
    await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.config, updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visitor Security Policy Configuration Saved'), backgroundColor: Color(0xFF059669)),
      );
    }
  }

  Future<void> _addBlacklisted() async {
    if (_blkNameCtrl.text.trim().isEmpty) return;
    final current = List<Map<String, dynamic>>.from(
      (_config['blacklistedVisitors'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
    );
    current.insert(0, {
      'id': 'BLK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'name': _blkNameCtrl.text.trim(),
      'reason': _blkReasonCtrl.text.trim().isEmpty ? 'Security Policy Violation' : _blkReasonCtrl.text.trim(),
      'addedAt': DateTime.now().toIso8601String(),
    });
    _blkNameCtrl.clear();
    _blkReasonCtrl.clear();
    final updated = {..._config, 'blacklistedVisitors': current};
    setState(() => _config = updated);
    await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.config, updated);
  }

  Future<void> _removeBlacklisted(String id) async {
    final current = List<Map<String, dynamic>>.from(
      (_config['blacklistedVisitors'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
    )..removeWhere((b) => b['id'].toString() == id);
    final updated = {..._config, 'blacklistedVisitors': current};
    setState(() => _config = updated);
    await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.config, updated);
  }

  @override
  Widget build(BuildContext context) {
    final blacklist = (_config['blacklistedVisitors'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text('Gate & Security Configuration', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
          Text('Pass durations, gate timings, EHS enforcement rules & security blacklist', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gate Timing & Duration Policy', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
                const SizedBox(height: 10),
                TextField(controller: _plantCtrl, decoration: moduleInputDecoration('Complex / Plant Name')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _openCtrl, decoration: moduleInputDecoration('Gate Opening'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _closeCtrl, decoration: moduleInputDecoration('Gate Closing'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _maxHoursCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Max Pass Hours'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _overdueCtrl, keyboardType: TextInputType.number, decoration: moduleInputDecoration('Overdue Grace (min)'))),
                  ],
                ),
                const Divider(height: 22),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Require Original Govt ID Verification', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  value: _config['requireGovtId'] == true,
                  onChanged: (v) => setState(() => _config = {..._config, 'requireGovtId': v}),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Require ATEX Safety Induction Briefing', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  value: _config['requireSafetyInduction'] == true,
                  onChanged: (v) => setState(() => _config = {..._config, 'requireSafetyInduction': v}),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Require Host Approval for Contractors/Vendors', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  value: _config['requireHostApprovalForVendors'] == true,
                  onChanged: (v) => setState(() => _config = {..._config, 'requireHostApprovalForVendors': v}),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.screenPerm.canEdit ? _saveConfig : null,
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Save Policy Configuration'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Barred & Blacklisted Individuals', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626))),
                const SizedBox(height: 10),
                if (widget.screenPerm.canEdit) ...[
                  TextField(controller: _blkNameCtrl, decoration: moduleInputDecoration('Full Name / ID Number')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _blkReasonCtrl, decoration: moduleInputDecoration('Reason for Blacklist'))),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addBlacklisted,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                        child: const Text('Bar Entry'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (blacklist.isEmpty)
                  Text('No barred individuals recorded.', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)))
                else
                  ...blacklist.map((b) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.block, color: Color(0xFFDC2626)),
                        title: Text((b['name'] ?? '').toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        subtitle: Text((b['reason'] ?? '').toString(), style: GoogleFonts.inter(fontSize: 12)),
                        trailing: widget.screenPerm.canDelete
                            ? IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)), onPressed: () => _removeBlacklisted(b['id'].toString()))
                            : null,
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
