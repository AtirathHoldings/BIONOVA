import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../services/visitor_data_service.dart';
import '../../widgets/module_ui_widgets.dart';

class VehicleManagementView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const VehicleManagementView({super.key, required this.screenPerm, required this.onNavigate});

  @override
  State<VehicleManagementView> createState() => _VehicleManagementViewState();
}

class _VehicleManagementViewState extends State<VehicleManagementView> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await VisitorDataService.instance.getStoredList(VisitorStorageKeys.vehicles);
    if (mounted) {
      setState(() {
        _vehicles = list;
        _isLoading = false;
      });
    }
  }

  void _openRegisterVehicleModal() {
    final formKey = GlobalKey<FormState>();
    final regCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String vehicleType = 'Biomass Tractor / Tipper';
    String purpose = 'Feedstock Delivery';
    bool sparkArrestorFitted = true;

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
                      Expanded(child: Text('Register Vehicle Gate Entry', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: regCtrl,
                    decoration: moduleInputDecoration('Vehicle Registration No *', hint: 'MH-14-CV-9981'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: driverCtrl, decoration: moduleInputDecoration('Driver Name *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null)),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: moduleInputDecoration('Driver Phone'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: vehicleType,
                    decoration: moduleInputDecoration('Vehicle Class'),
                    items: const [
                      DropdownMenuItem(value: 'Biomass Tractor / Tipper', child: Text('Biomass Tractor / Tipper')),
                      DropdownMenuItem(value: 'CBG High-Pressure Cascade Truck', child: Text('CBG Cascade Truck')),
                      DropdownMenuItem(value: 'Heavy Crane / Maintenance', child: Text('Heavy Crane / Maintenance')),
                      DropdownMenuItem(value: 'Light Commercial / Passenger Car', child: Text('Passenger Car / LCV')),
                    ],
                    onChanged: (v) => setModalState(() => vehicleType = v ?? vehicleType),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: purpose,
                    decoration: moduleInputDecoration('Purpose'),
                    items: const [
                      DropdownMenuItem(value: 'Feedstock Delivery', child: Text('Feedstock Delivery')),
                      DropdownMenuItem(value: 'CBG Cascade Dispatch', child: Text('CBG Cascade Dispatch')),
                      DropdownMenuItem(value: 'Slurry / Digestate Hauling', child: Text('Slurry / Digestate Hauling')),
                      DropdownMenuItem(value: 'Visitor / Inspection', child: Text('Visitor / Inspection')),
                    ],
                    onChanged: (v) => setModalState(() => purpose = v ?? purpose),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: sparkArrestorFitted,
                    onChanged: (v) => setModalState(() => sparkArrestorFitted = v ?? true),
                    title: Text('PESO Exhaust Spark Arrestor Verified & Fitted', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final item = {
                          'id': 'VEH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                          'vehicleNo': regCtrl.text.trim().toUpperCase(),
                          'driverName': driverCtrl.text.trim(),
                          'driverPhone': phoneCtrl.text.trim(),
                          'vehicleType': vehicleType,
                          'purpose': purpose,
                          'sparkArrestor': sparkArrestorFitted,
                          'status': 'Inside',
                          'entryTime': DateTime.now().toIso8601String(),
                        };
                        final updated = [item, ..._vehicles];
                        setState(() => _vehicles = updated);
                        await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.vehicles, updated);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('Log Vehicle Entry'),
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

  Future<void> _markExit(Map<String, dynamic> vh) async {
    final updated = _vehicles
        .map((x) => x['id'].toString() == vh['id'].toString() ? {...x, 'status': 'Exited', 'exitTime': DateTime.now().toIso8601String()} : x)
        .toList();
    setState(() => _vehicles = updated);
    await VisitorDataService.instance.saveStoredData(VisitorStorageKeys.vehicles, updated);
  }

  @override
  Widget build(BuildContext context) {
    final insideCount = _vehicles.where((v) => v['status'] == 'Inside').length;
    final exitedCount = _vehicles.where((v) => v['status'] == 'Exited').length;
    final sparkVerified = _vehicles.where((v) => v['sparkArrestor'] == true).length;

    final filtered = _vehicles.where((v) => _filter == 'ALL' || v['status'] == _filter).toList();

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
                    Text('Vehicle & Fleet Security Gate', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('Track biomass tippers, CBG cascades & spark-arrestor checks', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              if (widget.screenPerm.canCreate)
                ElevatedButton.icon(
                  onPressed: _openRegisterVehicleModal,
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('Log Entry'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ModuleKpiGrid(items: [
            ModuleKpiItem(label: 'Vehicles Inside', value: '$insideCount', subtext: 'Currently inside yard', accentColor: const Color(0xFF059669), icon: Icons.local_shipping_outlined),
            ModuleKpiItem(label: 'Exited Fleet', value: '$exitedCount', subtext: 'Cleared & dispatched', accentColor: const Color(0xFF2563EB), icon: Icons.done_all),
            ModuleKpiItem(label: 'Spark Arrested', value: '$sparkVerified', subtext: 'PESO ATEX compliant', accentColor: const Color(0xFFD97706), icon: Icons.local_fire_department_outlined),
            ModuleKpiItem(label: 'Total Logged', value: '${_vehicles.length}', subtext: 'All movements', accentColor: const Color(0xFF7C3AED), icon: Icons.list_alt),
          ]),
          const SizedBox(height: 12),
          Row(
            children: ['ALL', 'Inside', 'Exited'].map((f) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(label: Text(f), selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const ModuleEmptyState(icon: Icons.directions_car_outlined, title: 'No Vehicle Logs', subtitle: 'Log truck & vehicle entries at the security gate.')
          else
            ...filtered.map((vh) {
              final st = (vh['status'] ?? 'Inside').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('${vh['vehicleNo'] ?? '-'}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        if (vh['sparkArrestor'] == true)
                          const ModuleTag(text: 'Spark Arrested', bgColor: Color(0xFFD1FAE5), textColor: Color(0xFF059669)),
                        const Spacer(),
                        ModuleTag(
                          text: st,
                          bgColor: st == 'Inside' ? const Color(0xFFFEF3C7) : const Color(0xFFE2E8F0),
                          textColor: st == 'Inside' ? const Color(0xFFD97706) : const Color(0xFF475569),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${vh['vehicleType'] ?? '-'} • ${vh['purpose'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF334155))),
                    Text('Driver: ${vh['driverName'] ?? '-'} (${vh['driverPhone'] ?? '-'})', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    if (st == 'Inside' && widget.screenPerm.canEdit) ...[
                      const Divider(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => _markExit(vh),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white),
                          child: const Text('Record Gate Exit'),
                        ),
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
