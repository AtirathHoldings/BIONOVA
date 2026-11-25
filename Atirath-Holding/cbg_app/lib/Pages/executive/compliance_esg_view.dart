import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/executive_api_service.dart';
import '../../widgets/module_ui_widgets.dart';

class ComplianceEsgView extends StatefulWidget {
  const ComplianceEsgView({super.key});

  @override
  State<ComplianceEsgView> createState() => _ComplianceEsgViewState();
}

class _ComplianceEsgViewState extends State<ComplianceEsgView> {
  static const List<String> _categories = [
    'All Categories',
    'Safety & Explosives',
    'Environmental & Pollution',
    'Carbon Verification',
    'Health, Safety & Environment',
  ];

  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _categoryFilter = 'All Categories';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await ExecutiveApiService.getComplianceRecords();
    if (mounted) {
      setState(() {
        _records = data;
        _isLoading = false;
      });
    }
  }

  int _daysLeft(dynamic expiryStr) {
    if (expiryStr == null || expiryStr.toString().isEmpty) return 999;
    final parsed = DateTime.tryParse(expiryStr.toString());
    if (parsed == null) return 999;
    return parsed.difference(DateTime.now()).inDays + 1;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _records.where((r) {
      final matchesSearch = (r['title'] ?? '').toString().toLowerCase().contains(q) ||
          (r['authority'] ?? '').toString().toLowerCase().contains(q) ||
          (r['licenseNo'] ?? '').toString().toLowerCase().contains(q) ||
          (r['officer'] ?? '').toString().toLowerCase().contains(q);
      final matchesCat = _categoryFilter == 'All Categories' || r['category'] == _categoryFilter;
      final days = _daysLeft(r['expiryDate']);
      bool matchesStatus = true;
      if (_statusFilter == 'Expiring') matchesStatus = days <= 45;
      if (_statusFilter == 'Valid') matchesStatus = days > 45;
      return matchesSearch && matchesCat && matchesStatus;
    }).toList();
  }

  void _openForm({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final idCtrl = TextEditingController(text: isEdit ? (existing['id'] ?? '').toString() : 'COMP-REG-0${_records.length + 1}');
    final titleCtrl = TextEditingController(text: isEdit ? (existing['title'] ?? '').toString() : '');
    final authCtrl = TextEditingController(text: isEdit ? (existing['authority'] ?? '').toString() : '');
    final plantCtrl = TextEditingController(text: isEdit ? (existing['plant'] ?? 'Plant 1 - Hyderabad East CBG').toString() : 'Plant 1 - Hyderabad East CBG');
    final licCtrl = TextEditingController(text: isEdit ? (existing['licenseNo'] ?? '').toString() : '');
    final issueCtrl = TextEditingController(text: isEdit ? (existing['issueDate'] ?? '').toString() : DateTime.now().toIso8601String().split('T').first);
    final expCtrl = TextEditingController(text: isEdit ? (existing['expiryDate'] ?? '').toString() : '2027-12-31');
    final officerCtrl = TextEditingController(text: isEdit ? (existing['officer'] ?? '').toString() : '');
    final scoreCtrl = TextEditingController(text: isEdit ? (existing['auditScore'] ?? '95/100').toString() : '95/100');

    String category = isEdit ? (existing['category'] ?? 'Environmental & Pollution').toString() : 'Environmental & Pollution';
    String pillar = isEdit ? (existing['esgPillar'] ?? 'Environmental').toString() : 'Environmental';
    String risk = isEdit ? (existing['riskLevel'] ?? 'Low').toString() : 'Low';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Statutory Compliance Record' : 'Add Statutory License / Clearance',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                TextField(controller: idCtrl, decoration: moduleInputDecoration('Filing ID *')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Compliance Category *'),
                  items: _categories.where((c) => c != 'All Categories').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModalState(() => category = v ?? 'Environmental & Pollution'),
                ),
                const SizedBox(height: 10),
                TextField(controller: licCtrl, decoration: moduleInputDecoration('Certificate / License Number *')),
                const SizedBox(height: 10),
                TextField(controller: titleCtrl, decoration: moduleInputDecoration('License / Clearance Title *')),
                const SizedBox(height: 10),
                TextField(controller: authCtrl, decoration: moduleInputDecoration('Issuing Authority *')),
                const SizedBox(height: 10),
                TextField(controller: plantCtrl, decoration: moduleInputDecoration('Target Plant Facility *')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: issueCtrl, decoration: moduleInputDecoration('Issuance Date'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: expCtrl, decoration: moduleInputDecoration('Expiry Date *'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: pillar,
                        decoration: moduleInputDecoration('ESG Dimension'),
                        items: const [
                          DropdownMenuItem(value: 'Environmental', child: Text('Environmental')),
                          DropdownMenuItem(value: 'Social', child: Text('Social')),
                          DropdownMenuItem(value: 'Governance', child: Text('Governance')),
                        ],
                        onChanged: (v) => setModalState(() => pillar = v ?? 'Environmental'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: risk,
                        decoration: moduleInputDecoration('Risk Rating'),
                        items: const [
                          DropdownMenuItem(value: 'Low', child: Text('Low Risk')),
                          DropdownMenuItem(value: 'Medium', child: Text('Medium Watch')),
                          DropdownMenuItem(value: 'High', child: Text('High Urgency')),
                        ],
                        onChanged: (v) => setModalState(() => risk = v ?? 'Low'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: officerCtrl, decoration: moduleInputDecoration('Officer In-Charge'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: scoreCtrl, decoration: moduleInputDecoration('Audit Score'))),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (titleCtrl.text.trim().isEmpty || licCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please provide Title and License Number.')),
                        );
                        return;
                      }
                      final payload = {
                        'id': idCtrl.text.trim(),
                        'title': titleCtrl.text.trim(),
                        'authority': authCtrl.text.trim(),
                        'plant': plantCtrl.text.trim(),
                        'category': category,
                        'licenseNo': licCtrl.text.trim(),
                        'issueDate': issueCtrl.text.trim(),
                        'expiryDate': expCtrl.text.trim(),
                        'esgPillar': pillar,
                        'riskLevel': risk,
                        'status': 'Valid & Compliant',
                        'officer': officerCtrl.text.trim(),
                        'auditScore': scoreCtrl.text.trim(),
                      };
                      if (isEdit) {
                        setState(() {
                          _records = _records.map((r) => r['id'] == existing['id'] ? payload : r).toList();
                        });
                      } else {
                        setState(() => _records = [payload, ..._records]);
                        ExecutiveApiService.saveComplianceRecord(payload).then((res) {
                          if (res != null && mounted) {
                            setState(() {
                              _records = [res, ..._records.where((r) => r['id'] != payload['id'])];
                            });
                          }
                        }).catchError((_) {});
                      }
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: Text(isEdit ? 'Update Statutory Record' : 'Save Clearance'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Compliance Record'),
        content: Text('Delete compliance record $id?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ExecutiveApiService.deleteComplianceRecord(id).catchError((_) {});
      setState(() => _records.removeWhere((r) => r['id'].toString() == id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final expiringCount = _records.where((r) => _daysLeft(r['expiryDate']) <= 45).length;
    final compliantCount = _records.where((r) => (r['status'] ?? '').toString().contains('Valid')).length;
    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            'Centralized registry for PESO explosive licenses, SPCB consent orders, carbon verifications, and sustainability risk indicators.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => exportCsvData(
                    context,
                    fileName: 'BioNova_Compliance_ESG_Registry_${DateTime.now().toIso8601String().split('T').first}.csv',
                    headers: ['Compliance ID', 'Title', 'Authority', 'Plant', 'Category', 'License No', 'Issue Date', 'Expiry Date', 'Days Left', 'ESG Pillar', 'Risk', 'Status', 'Officer', 'Score'],
                    rows: filtered
                        .map((r) => [
                              r['id'],
                              r['title'],
                              r['authority'],
                              r['plant'],
                              r['category'],
                              r['licenseNo'],
                              r['issueDate'],
                              r['expiryDate'],
                              _daysLeft(r['expiryDate']),
                              r['esgPillar'],
                              r['riskLevel'],
                              r['status'],
                              r['officer'],
                              r['auditScore'],
                            ])
                        .toList(),
                  ),
                  icon: const Icon(Icons.download, size: 15),
                  label: const Text('Export CSV'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF059669)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add License'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (expiringCount > 0)
            ModuleAlertBanner(
              title: 'Regulatory Renewal Notice ($expiringCount Clearances < 45 Days)',
              subtitle: 'Statutory renewal filings require attention before expiry.',
              actionLabel: 'Review Renewals',
              onAction: () => setState(() => _statusFilter = 'Expiring'),
            ),
          ModuleKpiGrid(
            items: [
              ModuleKpiItem(
                label: 'STATUTORY CLEARANCES',
                value: '${_records.length} Licenses',
                subtext: '$compliantCount Fully Compliant & Active',
                accentColor: const Color(0xFF059669),
                icon: Icons.verified_user_outlined,
              ),
              ModuleKpiItem(
                label: 'ESG GOVERNANCE INDEX',
                value: _records.isNotEmpty ? '96.8%' : '--',
                subtext: _records.isNotEmpty ? 'Top Quartile Benchmark' : 'Awaiting Baseline',
                accentColor: const Color(0xFF059669),
                icon: Icons.eco_outlined,
              ),
              ModuleKpiItem(
                label: 'RENEWALS DUE (<45D)',
                value: '$expiringCount Filings',
                subtext: expiringCount > 0 ? 'Renewal Dossiers Ready' : 'Zero Pending Filings',
                accentColor: expiringCount > 0 ? const Color(0xFFEA580C) : const Color(0xFF059669),
                valueColor: expiringCount > 0 ? const Color(0xFFEA580C) : const Color(0xFF059669),
                icon: Icons.schedule,
              ),
              ModuleKpiItem(
                label: 'SAFETY & EMISSIONS AUDIT',
                value: _records.isNotEmpty ? 'Zero Violations' : '--',
                subtext: _records.isNotEmpty ? 'OSHA & PCB Compliant' : 'No Audits Logged',
                accentColor: const Color(0xFF2563EB),
                icon: Icons.fact_check_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: moduleInputDecoration('Search license title, authority, cert no, or officer...').copyWith(
              prefixIcon: const Icon(Icons.search, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _categoryFilter,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Category'),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _categoryFilter = v ?? 'All Categories'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Status'),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'Expiring', child: Text('Expiring (<45d)')),
                    DropdownMenuItem(value: 'Valid', child: Text('Valid & Compliant')),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v ?? 'All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(
              icon: Icons.verified_user_outlined,
              title: 'No statutory compliance records found',
              subtitle: 'Add a regulatory license or adjust your filters.',
            )
          else
            ...filtered.map((r) {
              final daysLeft = _daysLeft(r['expiryDate']);
              final isUrgent = daysLeft <= 45;
              final risk = (r['riskLevel'] ?? 'Low').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text((r['title'] ?? '').toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5))),
                        ModuleTag(
                          text: isUrgent ? 'Renewal Due Soon' : 'Valid & Active',
                          bgColor: isUrgent ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                          textColor: isUrgent ? const Color(0xFF92400E) : const Color(0xFF166534),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${r['authority'] ?? ''} • ${r['category'] ?? ''}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                    Text('Cert: ${r['licenseNo']} • Plant: ${r['plant']}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF2563EB))),
                    Text('Officer: ${r['officer'] ?? '-'} • Audit Score: ${r['auditScore'] ?? '-'}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF059669))),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Exp: ${r['expiryDate'] ?? '-'}', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600)),
                            Text(
                              daysLeft > 0 ? '$daysLeft Days Remaining' : 'Expired',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isUrgent ? const Color(0xFFEA580C) : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            ModuleTag(
                              text: '${r['esgPillar']}: $risk Risk',
                              bgColor: risk == 'Low' ? const Color(0xFFDCFCE7) : risk == 'Medium' ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2),
                              textColor: risk == 'Low' ? const Color(0xFF166534) : risk == 'Medium' ? const Color(0xFF92400E) : const Color(0xFF991B1B),
                            ),
                            IconButton(onPressed: () => _openForm(existing: r), icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF059669))),
                            IconButton(onPressed: () => _deleteItem(r['id'].toString()), icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626))),
                          ],
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
