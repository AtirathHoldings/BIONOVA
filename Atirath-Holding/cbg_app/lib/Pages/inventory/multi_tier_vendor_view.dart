import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/inventory_api_service.dart';
import '../../services/rbac_service.dart';
import '../../widgets/module_ui_widgets.dart';

class MultiTierVendorView extends StatefulWidget {
  final ScreenPermission screenPerm;

  const MultiTierVendorView({super.key, required this.screenPerm});

  @override
  State<MultiTierVendorView> createState() => _MultiTierVendorViewState();
}

class _MultiTierVendorViewState extends State<MultiTierVendorView> {
  List<Map<String, dynamic>> _vendors = [];
  bool _isLoading = true;
  String _searchTerm = '';
  String _tierFilter = 'ALL';
  String _categoryFilter = 'ALL';
  String _msmeFilter = 'ALL';
  String _gradeFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final local = await InventoryApiService.loadLocalList(InventoryStorageKeys.vendors);
    if (mounted) {
      setState(() {
        _vendors = local;
        _isLoading = false;
      });
    }
    final live = await InventoryApiService.getInventoryVendors();
    if (live.isNotEmpty && mounted) {
      setState(() {
        _vendors = live;
        _isLoading = false;
      });
      await InventoryApiService.saveLocalList(InventoryStorageKeys.vendors, live);
    }
  }

  Future<void> _persistVendors(List<Map<String, dynamic>> updated) async {
    setState(() => _vendors = updated);
    await InventoryApiService.saveLocalList(InventoryStorageKeys.vendors, updated);
  }

  void _openVendorForm({Map<String, dynamic>? existing}) {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(text: (existing?['vendorCode'] ?? '').toString());
    final nameCtrl = TextEditingController(text: (existing?['name'] ?? '').toString());
    String tier = (existing?['tier'] ?? 'Tier-1 Strategic OEM').toString();
    String category = (existing?['category'] ?? 'Plant & Process OEM').toString();
    final gstinCtrl = TextEditingController(text: (existing?['gstin'] ?? '').toString());
    final panCtrl = TextEditingController(text: (existing?['pan'] ?? '').toString());
    bool msmeStatus = existing?['msmeStatus'] == true;
    final udyamCtrl = TextEditingController(text: (existing?['udyamNo'] ?? '').toString());
    final cityCtrl = TextEditingController(text: (existing?['city'] ?? '').toString());
    final stateCtrl = TextEditingController(text: (existing?['state'] ?? '').toString());
    final contactCtrl = TextEditingController(text: (existing?['contactPerson'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (existing?['phone'] ?? '').toString());
    final emailCtrl = TextEditingController(text: (existing?['email'] ?? '').toString());
    String paymentTerms = (existing?['paymentTerms'] ?? 'Net 30 Days').toString();
    final creditCtrl = TextEditingController(text: (existing?['creditLimit'] ?? '2500000').toString());
    final onTimeCtrl = TextEditingController(text: (existing?['onTimeDeliveryRate'] ?? '95').toString());
    final qualityCtrl = TextEditingController(text: (existing?['qualityScore'] ?? '94').toString());
    String grade = (existing?['performanceGrade'] ?? 'A').toString();
    String slaStatus = (existing?['slaStatus'] ?? 'Compliant').toString();
    final contractCtrl = TextEditingController(text: (existing?['activeContractRef'] ?? '').toString());
    final notesCtrl = TextEditingController(text: (existing?['notes'] ?? '').toString());

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          existing == null ? 'Onboard Multi-Tier Vendor' : 'Edit Vendor Profile',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  Text('1. Statutory & Tax Profile', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: codeCtrl, decoration: moduleInputDecoration('Vendor Code', hint: 'VND-1001'))),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: nameCtrl,
                          decoration: moduleInputDecoration('Company / Legal Name *'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: tier,
                    decoration: moduleInputDecoration('Vendor Tier'),
                    items: const [
                      DropdownMenuItem(value: 'Tier-1 Strategic OEM', child: Text('Tier-1 Strategic OEM')),
                      DropdownMenuItem(value: 'Tier-2 Regional Vendor', child: Text('Tier-2 Regional Vendor')),
                      DropdownMenuItem(value: 'Tier-3 Local/MSME Supplier', child: Text('Tier-3 Local/MSME Supplier')),
                    ],
                    onChanged: (v) => setModalState(() => tier = v ?? tier),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: moduleInputDecoration('Procurement Category'),
                    items: const [
                      DropdownMenuItem(value: 'Plant & Process OEM', child: Text('Plant & Process OEM')),
                      DropdownMenuItem(value: 'Civil & Structural', child: Text('Civil & Structural')),
                      DropdownMenuItem(value: 'Biomass & Feedstock', child: Text('Biomass & Feedstock')),
                      DropdownMenuItem(value: 'Piping, Valves & Instrumentation', child: Text('Piping, Valves & Instrumentation')),
                      DropdownMenuItem(value: 'Chemicals & Consumables', child: Text('Chemicals & Consumables')),
                      DropdownMenuItem(value: 'Logistics & Cascade Transport', child: Text('Logistics & Cascade Transport')),
                    ],
                    onChanged: (v) => setModalState(() => category = v ?? category),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: gstinCtrl, decoration: moduleInputDecoration('GSTIN'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: panCtrl, decoration: moduleInputDecoration('PAN'))),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('MSME Registered Supplier', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    value: msmeStatus,
                    onChanged: (v) => setModalState(() => msmeStatus = v),
                  ),
                  if (msmeStatus) ...[
                    TextFormField(controller: udyamCtrl, decoration: moduleInputDecoration('Udyam Registration No')),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: cityCtrl, decoration: moduleInputDecoration('City'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: stateCtrl, decoration: moduleInputDecoration('State'))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('2. Commercials & SLA Metrics', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: contactCtrl, decoration: moduleInputDecoration('Primary Contact'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: moduleInputDecoration('Phone'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: moduleInputDecoration('Official Email')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: paymentTerms,
                          decoration: moduleInputDecoration('Payment Terms'),
                          items: const [
                            DropdownMenuItem(value: 'Advance', child: Text('Advance')),
                            DropdownMenuItem(value: 'Net 15 Days', child: Text('Net 15 Days')),
                            DropdownMenuItem(value: 'Net 30 Days', child: Text('Net 30 Days')),
                            DropdownMenuItem(value: 'Net 45 Days (MSME)', child: Text('Net 45 Days (MSME)')),
                            DropdownMenuItem(value: 'Net 60 Days', child: Text('Net 60 Days')),
                          ],
                          onChanged: (v) => setModalState(() => paymentTerms = v ?? paymentTerms),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: creditCtrl,
                          keyboardType: TextInputType.number,
                          decoration: moduleInputDecoration('Credit Limit (INR)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: onTimeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: moduleInputDecoration('On-Time Delivery %'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: qualityCtrl,
                          keyboardType: TextInputType.number,
                          decoration: moduleInputDecoration('Quality Index (0-100)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: grade,
                          decoration: moduleInputDecoration('Grade'),
                          items: const [
                            DropdownMenuItem(value: 'A+', child: Text('A+')),
                            DropdownMenuItem(value: 'A', child: Text('A')),
                            DropdownMenuItem(value: 'B', child: Text('B')),
                            DropdownMenuItem(value: 'C', child: Text('C')),
                            DropdownMenuItem(value: 'Suspended', child: Text('Suspended')),
                          ],
                          onChanged: (v) => setModalState(() => grade = v ?? grade),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: slaStatus,
                          decoration: moduleInputDecoration('SLA Status'),
                          items: const [
                            DropdownMenuItem(value: 'Compliant', child: Text('Compliant')),
                            DropdownMenuItem(value: 'Watchlist', child: Text('Watchlist')),
                            DropdownMenuItem(value: 'Blacklisted', child: Text('Blacklisted')),
                          ],
                          onChanged: (v) => setModalState(() => slaStatus = v ?? slaStatus),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: contractCtrl, decoration: moduleInputDecoration('Active Contract Ref')),
                  const SizedBox(height: 10),
                  TextFormField(controller: notesCtrl, maxLines: 2, decoration: moduleInputDecoration('Audit / Compliance Notes')),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final id = existing?['id'] ?? 'VND-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                        final payload = {
                          'id': id,
                          'vendorCode': codeCtrl.text.trim().isEmpty ? id.toString() : codeCtrl.text.trim(),
                          'name': nameCtrl.text.trim(),
                          'tier': tier,
                          'category': category,
                          'gstin': gstinCtrl.text.trim().toUpperCase(),
                          'pan': panCtrl.text.trim().toUpperCase(),
                          'msmeStatus': msmeStatus,
                          'udyamNo': udyamCtrl.text.trim(),
                          'city': cityCtrl.text.trim(),
                          'state': stateCtrl.text.trim(),
                          'contactPerson': contactCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'paymentTerms': paymentTerms,
                          'creditLimit': double.tryParse(creditCtrl.text.trim()) ?? 0,
                          'onTimeDeliveryRate': double.tryParse(onTimeCtrl.text.trim()) ?? 95,
                          'qualityScore': double.tryParse(qualityCtrl.text.trim()) ?? 94,
                          'performanceGrade': grade,
                          'slaStatus': slaStatus,
                          'activeContractRef': contractCtrl.text.trim(),
                          'notes': notesCtrl.text.trim(),
                        };
                        try {
                          await InventoryApiService.saveInventoryVendor(payload, id: existing?['id']);
                        } catch (_) {}
                        final updated = existing == null
                            ? [payload, ..._vendors]
                            : _vendors.map((v) => v['id'].toString() == existing['id'].toString() ? payload : v).toList();
                        await _persistVendors(updated);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: Text(existing == null ? 'Onboard Vendor' : 'Save Vendor Updates'),
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

  void _openDossier(Map<String, dynamic> v) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${v['name'] ?? ''} (${v['vendorCode'] ?? v['id']})', style: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _dRow('Tier', '${v['tier'] ?? '-'}'),
              _dRow('Category', '${v['category'] ?? '-'}'),
              _dRow('GSTIN / PAN', '${v['gstin'] ?? '-'} / ${v['pan'] ?? '-'}'),
              _dRow('MSME', v['msmeStatus'] == true ? 'Yes (${v['udyamNo'] ?? 'Registered'})' : 'Non-MSME'),
              _dRow('Location', '${v['city'] ?? '-'}, ${v['state'] ?? '-'}'),
              _dRow('Contact', '${v['contactPerson'] ?? '-'} • ${v['phone'] ?? '-'}'),
              _dRow('Email', '${v['email'] ?? '-'}'),
              _dRow('Payment Terms', '${v['paymentTerms'] ?? '-'}'),
              _dRow('Credit Limit', '₹${v['creditLimit'] ?? 0}'),
              _dRow('On-Time / Quality', '${v['onTimeDeliveryRate'] ?? 0}% / ${v['qualityScore'] ?? 0}/100'),
              _dRow('Grade / SLA', '${v['performanceGrade'] ?? '-'} / ${v['slaStatus'] ?? '-'}'),
              _dRow('Contract Ref', '${v['activeContractRef'] ?? '-'}'),
              if ((v['notes'] ?? '').toString().isNotEmpty) _dRow('Notes', '${v['notes']}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _dRow(String k, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 105, child: Text(k, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)))),
          Expanded(child: Text(val, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _vendors.length;
    final msmeCount = _vendors.where((v) => v['msmeStatus'] == true).length;
    final msmePercent = total == 0 ? 0 : ((msmeCount / total) * 100).round();
    final avgOnTime = total == 0
        ? 0.0
        : _vendors.fold<double>(0, (s, v) => s + (double.tryParse((v['onTimeDeliveryRate'] ?? 0).toString()) ?? 0)) / total;
    final avgQuality = total == 0
        ? 0.0
        : _vendors.fold<double>(0, (s, v) => s + (double.tryParse((v['qualityScore'] ?? 0).toString()) ?? 0)) / total;
    final totalCreditCr = _vendors.fold<double>(0, (s, v) => s + (double.tryParse((v['creditLimit'] ?? 0).toString()) ?? 0)) / 10000000.0;

    final filtered = _vendors.where((v) {
      final q = _searchTerm.trim().toLowerCase();
      final matchSearch = q.isEmpty ||
          (v['name'] ?? '').toString().toLowerCase().contains(q) ||
          (v['vendorCode'] ?? '').toString().toLowerCase().contains(q) ||
          (v['gstin'] ?? '').toString().toLowerCase().contains(q) ||
          (v['city'] ?? '').toString().toLowerCase().contains(q);
      final matchTier = _tierFilter == 'ALL' || v['tier'] == _tierFilter;
      final matchCat = _categoryFilter == 'ALL' || v['category'] == _categoryFilter;
      final matchMsme = _msmeFilter == 'ALL' || (_msmeFilter == 'MSME' ? v['msmeStatus'] == true : v['msmeStatus'] != true);
      final matchGrade = _gradeFilter == 'ALL' || v['performanceGrade'] == _gradeFilter;
      return matchSearch && matchTier && matchCat && matchMsme && matchGrade;
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
                    Text('Multi-Tier Vendor Database', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                    Text('Strategic OEMs, MSME compliance, GSTIN & SLA scorecards', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined, color: Color(0xFF2563EB)),
                onPressed: () => exportCsvData(
                  context,
                  fileName: 'multi_tier_vendors.csv',
                  headers: const ['Code', 'Name', 'Tier', 'Category', 'GSTIN', 'MSME', 'City', 'Contact', 'Phone', 'Payment Terms', 'Credit Limit', 'On-Time %', 'Quality', 'Grade', 'SLA'],
                  rows: filtered
                      .map((v) => [
                            v['vendorCode'] ?? v['id'] ?? '',
                            v['name'] ?? '',
                            v['tier'] ?? '',
                            v['category'] ?? '',
                            v['gstin'] ?? '',
                            v['msmeStatus'] == true ? 'Yes' : 'No',
                            v['city'] ?? '',
                            v['contactPerson'] ?? '',
                            v['phone'] ?? '',
                            v['paymentTerms'] ?? '',
                            v['creditLimit'] ?? 0,
                            v['onTimeDeliveryRate'] ?? 0,
                            v['qualityScore'] ?? 0,
                            v['performanceGrade'] ?? '',
                            v['slaStatus'] ?? '',
                          ])
                      .toList(),
                ),
              ),
              if (widget.screenPerm.canCreate)
                ElevatedButton.icon(
                  onPressed: () => _openVendorForm(),
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('Add Vendor'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ModuleAlertBanner(
            title: 'MSME Priority Procurement Policy: $msmePercent% Verified MSME Share',
            subtitle: 'Portfolio Average Quality Index: ${avgQuality.toStringAsFixed(1)}/100 • 45-Day MSME Payment Compliance Active',
            borderColor: const Color(0xFF2563EB),
            bgColor: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF1D4ED8),
            icon: Icons.verified_outlined,
          ),
          ModuleKpiGrid(items: [
            ModuleKpiItem(label: 'Total Vendors', value: '$total', subtext: '$msmeCount MSME Registered', accentColor: const Color(0xFF2563EB), icon: Icons.storefront_outlined),
            ModuleKpiItem(label: 'Avg On-Time Delivery', value: '${avgOnTime.toStringAsFixed(1)}%', subtext: 'SLA adherence', accentColor: const Color(0xFF16A34A), icon: Icons.local_shipping_outlined),
            ModuleKpiItem(label: 'Avg Quality Index', value: '${avgQuality.toStringAsFixed(1)}/100', subtext: 'Audit composite score', accentColor: const Color(0xFF7C3AED), icon: Icons.workspace_premium_outlined),
            ModuleKpiItem(label: 'Credit Exposure', value: '₹${totalCreditCr.toStringAsFixed(2)} Cr', subtext: 'Approved trade credit', accentColor: const Color(0xFFEA580C), icon: Icons.account_balance_wallet_outlined),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              children: [
                TextField(
                  decoration: moduleInputDecoration('Search vendor, code, GSTIN, city...'),
                  onChanged: (v) => setState(() => _searchTerm = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('tier-$_tierFilter'),
                        initialValue: _tierFilter,
                        isExpanded: true,
                        decoration: moduleInputDecoration('Tier'),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Tiers')),
                          DropdownMenuItem(value: 'Tier-1 Strategic OEM', child: Text('Tier-1 OEM')),
                          DropdownMenuItem(value: 'Tier-2 Regional Vendor', child: Text('Tier-2 Regional')),
                          DropdownMenuItem(value: 'Tier-3 Local/MSME Supplier', child: Text('Tier-3 MSME')),
                        ],
                        onChanged: (v) => setState(() => _tierFilter = v ?? 'ALL'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('msme-$_msmeFilter'),
                        initialValue: _msmeFilter,
                        decoration: moduleInputDecoration('MSME'),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All')),
                          DropdownMenuItem(value: 'MSME', child: Text('MSME Only')),
                          DropdownMenuItem(value: 'Non-MSME', child: Text('Non-MSME')),
                        ],
                        onChanged: (v) => setState(() => _msmeFilter = v ?? 'ALL'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('grade-$_gradeFilter'),
                        initialValue: _gradeFilter,
                        decoration: moduleInputDecoration('Grade'),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All')),
                          DropdownMenuItem(value: 'A+', child: Text('A+')),
                          DropdownMenuItem(value: 'A', child: Text('A')),
                          DropdownMenuItem(value: 'B', child: Text('B')),
                          DropdownMenuItem(value: 'C', child: Text('C')),
                          DropdownMenuItem(value: 'Suspended', child: Text('Suspended')),
                        ],
                        onChanged: (v) => setState(() => _gradeFilter = v ?? 'ALL'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('cat-$_categoryFilter'),
                        initialValue: _categoryFilter,
                        isExpanded: true,
                        decoration: moduleInputDecoration('Category'),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Categories')),
                          DropdownMenuItem(value: 'Plant & Process OEM', child: Text('Plant & Process OEM')),
                          DropdownMenuItem(value: 'Civil & Structural', child: Text('Civil & Structural')),
                          DropdownMenuItem(value: 'Biomass & Feedstock', child: Text('Biomass & Feedstock')),
                          DropdownMenuItem(value: 'Piping, Valves & Instrumentation', child: Text('Piping & Valves')),
                          DropdownMenuItem(value: 'Chemicals & Consumables', child: Text('Chemicals')),
                          DropdownMenuItem(value: 'Logistics & Cascade Transport', child: Text('Logistics')),
                        ],
                        onChanged: (v) => setState(() => _categoryFilter = v ?? 'ALL'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() {
                        _searchTerm = '';
                        _tierFilter = 'ALL';
                        _categoryFilter = 'ALL';
                        _msmeFilter = 'ALL';
                        _gradeFilter = 'ALL';
                      }),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(
              icon: Icons.storefront_outlined,
              title: 'No Vendors Registered',
              subtitle: 'Onboard approved OEMs, civil contractors, and biomass suppliers.',
            )
          else
            ...filtered.map((v) {
              final grade = (v['performanceGrade'] ?? 'A').toString();
              final sla = (v['slaStatus'] ?? 'Compliant').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ModuleTag(text: '${v['vendorCode'] ?? v['id']}', bgColor: const Color(0xFFEFF6FF), textColor: const Color(0xFF1D4ED8)),
                        const SizedBox(width: 6),
                        if (v['msmeStatus'] == true)
                          const ModuleTag(text: 'MSME', bgColor: Color(0xFFD1FAE5), textColor: Color(0xFF059669)),
                        const Spacer(),
                        ModuleTag(
                          text: 'Grade $grade • $sla',
                          bgColor: sla == 'Compliant' ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                          textColor: sla == 'Compliant' ? const Color(0xFF059669) : const Color(0xFFDC2626),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text((v['name'] ?? '').toString(), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                    Text('${v['tier'] ?? '-'} • ${v['category'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                    const SizedBox(height: 4),
                    Text('GSTIN: ${v['gstin'] ?? '-'} • ${v['city'] ?? '-'}, ${v['state'] ?? '-'}',
                        style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    Text(
                      'On-Time: ${v['onTimeDeliveryRate'] ?? 0}% | Quality: ${v['qualityScore'] ?? 0}/100 | Terms: ${v['paymentTerms'] ?? '-'}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _openDossier(v),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('Dossier'),
                        ),
                        if (widget.screenPerm.canEdit)
                          TextButton.icon(
                            onPressed: () => _openVendorForm(existing: v),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit'),
                          ),
                        if (widget.screenPerm.canDelete)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 19),
                            onPressed: () async {
                              try {
                                await InventoryApiService.deleteInventoryVendor(v['id']);
                              } catch (_) {}
                              await _persistVendors(_vendors.where((x) => x['id'].toString() != v['id'].toString()).toList());
                            },
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
