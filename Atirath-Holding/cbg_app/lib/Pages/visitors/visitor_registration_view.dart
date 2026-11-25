import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/visitor_data_service.dart';
import '../../widgets/module_ui_widgets.dart';

class VisitorRegistrationView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const VisitorRegistrationView({
    super.key,
    required this.screenPerm,
    required this.onNavigate,
  });

  @override
  State<VisitorRegistrationView> createState() => _VisitorRegistrationViewState();
}

class _VisitorRegistrationViewState extends State<VisitorRegistrationView> {
  static const List<String> _hostList = [
    'Rajesh Sharma (Plant Head)',
    'Anita Desai (EHS Lead)',
    'Vikram Patel (Maintenance Head)',
    'Suresh Raina (Process Engineer)',
    'Priya Menon (Procurement)',
    'Karan Johar (Admin Officer)',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  String _category = 'Vendor / Contractor';
  String _idType = 'Aadhaar Card';
  final _idNumberCtrl = TextEditingController();
  String _hostName = _hostList.first;
  String _plantLocation = 'BioNova CBG Plant - Unit 1';
  String _purpose = 'Equipment Maintenance / Inspection';
  final _vehicleCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '4');
  final Set<String> _selectedZones = {'Z1'};
  bool _safetyBriefingDone = false;
  bool _ppeIssued = false;
  bool _termsAccepted = false;
  bool _submitting = false;
  Map<String, dynamic>? _generatedPass;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _companyCtrl.dispose();
    _idNumberCtrl.dispose();
    _vehicleCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Plant Safety & ATEX Compliance Declaration'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }

    setState(() => _submitting = true);
    final rand = 1000 + Random().nextInt(9000);
    final passNumber = 'VP-${DateTime.now().year}-$rand';
    final rfidTag = 'RFID-$rand';
    final checkInNow = _safetyBriefingDone && _ppeIssued;

    final record = {
      'id': passNumber,
      'passNumber': passNumber,
      'rfidTag': rfidTag,
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'company': _companyCtrl.text.trim().isEmpty ? 'Independent Visitor' : _companyCtrl.text.trim(),
      'category': _category,
      'idType': _idType,
      'idNumber': _idNumberCtrl.text.trim(),
      'hostName': _hostName,
      'plantLocation': _plantLocation,
      'purpose': _purpose,
      'vehicleNo': _vehicleCtrl.text.trim().toUpperCase(),
      'expectedDurationHours': int.tryParse(_durationCtrl.text.trim()) ?? 4,
      'allowedZones': _selectedZones.toList(),
      'safetyBriefingDone': _safetyBriefingDone,
      'ppeIssued': _ppeIssued,
      'status': checkInNow ? 'Checked In' : 'Pending Approval',
      'checkInTime': checkInNow ? DateTime.now().toIso8601String() : null,
      'createdAt': DateTime.now().toIso8601String(),
    };

    final existing = await VisitorDataService.instance.getStoredList(VisitorStorageKeys.visitors);
    await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.visitors, [record, ...existing]);
    await VisitorDataService.instance.apiCreateVisitorRecord(record);

    if (mounted) {
      setState(() {
        _submitting = false;
        _generatedPass = record;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_generatedPass != null) {
      final p = _generatedPass!;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF10B981), width: 1.5),
            ),
            child: Column(
              children: [
                const Icon(Icons.verified_outlined, color: Color(0xFF059669), size: 46),
                const SizedBox(height: 8),
                Text('Visitor Gate Pass Issued!', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text('Pass ID: ${p['passNumber']} • RFID: ${p['rfidTag']}',
                    style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
                const Divider(height: 22),
                _confirmRow('Visitor', '${p['name']} (${p['company']})'),
                _confirmRow('Phone / ID', '${p['phone']} • ${p['idType']}: ${p['idNumber']}'),
                _confirmRow('Host', '${p['hostName']}'),
                _confirmRow('Allowed Zones', (p['allowedZones'] as List).join(', ')),
                _confirmRow('Status', '${p['status']}'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          _generatedPass = null;
                          _nameCtrl.clear();
                          _phoneCtrl.clear();
                          _emailCtrl.clear();
                          _idNumberCtrl.clear();
                        }),
                        child: const Text('Register Another'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => widget.onNavigate('list'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                        child: const Text('View Directory'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text('Visitor Registration & Pass Generation', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
        Text('Issue RFID badges, verify Govt ID & enforce ATEX plant zone clearance', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
        const SizedBox(height: 14),
        Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. Visitor Identity & Contact', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: moduleInputDecoration('Full Name *'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Visitor name is required' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: moduleInputDecoration('Mobile Number *'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: moduleInputDecoration('Email'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _companyCtrl,
                        decoration: moduleInputDecoration('Company / Organization'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        isExpanded: true,
                        decoration: moduleInputDecoration('Category'),
                        items: const [
                          DropdownMenuItem(value: 'Vendor / Contractor', child: Text('Vendor / Contractor')),
                          DropdownMenuItem(value: 'Auditor / Inspector', child: Text('Auditor / Inspector')),
                          DropdownMenuItem(value: 'VIP / Client / Investor', child: Text('VIP / Client')),
                          DropdownMenuItem(value: 'Transporter / Driver', child: Text('Driver')),
                          DropdownMenuItem(value: 'Interview / Candidate', child: Text('Candidate')),
                        ],
                        onChanged: (v) => setState(() => _category = v ?? _category),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _idType,
                        decoration: moduleInputDecoration('Govt ID Type'),
                        items: const [
                          DropdownMenuItem(value: 'Aadhaar Card', child: Text('Aadhaar')),
                          DropdownMenuItem(value: 'PAN Card', child: Text('PAN Card')),
                          DropdownMenuItem(value: 'Driving License', child: Text('DL')),
                          DropdownMenuItem(value: 'Passport', child: Text('Passport')),
                        ],
                        onChanged: (v) => setState(() => _idType = v ?? _idType),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _idNumberCtrl,
                        decoration: moduleInputDecoration('ID Number *'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('2. Host & Visit Details', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _hostName,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Meeting Host *'),
                  items: _hostList.map((h) => DropdownMenuItem(value: h, child: Text(h, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _hostName = v ?? _hostName),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _plantLocation,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Plant / Unit'),
                  items: const [
                    DropdownMenuItem(value: 'BioNova CBG Plant - Unit 1', child: Text('BioNova CBG Plant - Unit 1')),
                    DropdownMenuItem(value: 'BioNova CBG Plant - Unit 2', child: Text('BioNova CBG Plant - Unit 2')),
                    DropdownMenuItem(value: 'Corporate HQ & Labs', child: Text('Corporate HQ & Labs')),
                  ],
                  onChanged: (v) => setState(() => _plantLocation = v ?? _plantLocation),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _purpose,
                        isExpanded: true,
                        decoration: moduleInputDecoration('Purpose of Visit'),
                        items: const [
                          DropdownMenuItem(value: 'Equipment Maintenance / Inspection', child: Text('Maintenance / Inspection')),
                          DropdownMenuItem(value: 'Safety & PESO Audit', child: Text('Safety & PESO Audit')),
                          DropdownMenuItem(value: 'Feedstock / Logistics', child: Text('Feedstock / Logistics')),
                          DropdownMenuItem(value: 'Business / Executive Meeting', child: Text('Business Meeting')),
                        ],
                        onChanged: (v) => setState(() => _purpose = v ?? _purpose),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _durationCtrl,
                        keyboardType: TextInputType.number,
                        decoration: moduleInputDecoration('Hours'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(controller: _vehicleCtrl, decoration: moduleInputDecoration('Vehicle Reg No (Optional)')),
                const SizedBox(height: 16),
                Text('3. Authorized Plant Zones', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: VisitorDataService.initialZones.map((zone) {
                    final selected = _selectedZones.contains(zone.id);
                    return FilterChip(
                      label: Text('${zone.id} • ${zone.code}', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      selected: selected,
                      selectedColor: Color(zone.colorHex).withValues(alpha: 0.2),
                      onSelected: (val) => setState(() {
                        if (val) {
                          _selectedZones.add(zone.id);
                        } else if (_selectedZones.length > 1) {
                          _selectedZones.remove(zone.id);
                        }
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('4. EHS Safety & PPE Check', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _safetyBriefingDone,
                  onChanged: (v) => setState(() => _safetyBriefingDone = v ?? false),
                  title: Text('ATEX / Biogas Safety Video Briefing Completed', style: GoogleFonts.inter(fontSize: 12.5)),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _ppeIssued,
                  onChanged: (v) => setState(() => _ppeIssued = v ?? false),
                  title: Text('Mandatory PPE Kit Issued (Helmet, Vest, Safety Shoes)', style: GoogleFonts.inter(fontSize: 12.5)),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _termsAccepted,
                  onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                  title: Text('Visitor confirms zero lighters/non-ATEX devices & accepts plant rules *', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_submitting || !widget.screenPerm.canCreate) ? null : _submitRegistration,
                    icon: _submitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.badge_outlined, size: 17),
                    label: Text(_safetyBriefingDone && _ppeIssued ? 'Issue Pass & Check-In Immediately' : 'Generate Pass (Pending Gate Clearance)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _confirmRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          Flexible(child: Text(v, textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
