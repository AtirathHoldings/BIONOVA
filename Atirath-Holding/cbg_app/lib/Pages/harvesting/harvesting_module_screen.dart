import 'package:flutter/material.dart';
import '../../services/rbac_service.dart';
import '../../widgets/module_ui_widgets.dart';
import '../../utils/app_colors.dart';

class HarvestingModuleScreen extends StatefulWidget {
  final String initialSubmodule;

  const HarvestingModuleScreen({super.key, this.initialSubmodule = 'cycles'});

  @override
  State<HarvestingModuleScreen> createState() => _HarvestingModuleScreenState();
}

class _HarvestingModuleScreenState extends State<HarvestingModuleScreen> {
  static const List<ModuleSubmoduleItem> _submodules = [
    ModuleSubmoduleItem(
      key: 'cycles',
      title: 'Harvest Cycles & Batches',
      shortLabel: 'Cycles',
      icon: Icons.agriculture_outlined,
    ),
    ModuleSubmoduleItem(
      key: 'inward',
      title: 'Feedstock Inward & Weighing',
      shortLabel: 'Inward',
      icon: Icons.scale_outlined,
    ),
    ModuleSubmoduleItem(
      key: 'baling',
      title: 'Silage & Baling Storage',
      shortLabel: 'Storage',
      icon: Icons.warehouse_outlined,
    ),
    ModuleSubmoduleItem(
      key: 'yield',
      title: 'Yield & Acreage Analytics',
      shortLabel: 'Yield',
      icon: Icons.analytics_outlined,
    ),
  ];

  late String _activeKey;
  ScreenPermission _perm = ScreenPermission.full;
  bool _isLoadingPerm = true;

  @override
  void initState() {
    super.initState();
    _activeKey = widget.initialSubmodule;
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final perm = await RbacService.getScreenPermission('HARVESTING_MODULE');
    if (mounted) {
      setState(() {
        _perm = perm;
        _isLoadingPerm = false;
      });
    }
  }

  Widget _buildActiveChild() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCards(),
          const SizedBox(height: 16),
          _buildHarvestBatchesList(),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard('Active Batches', '8', Icons.agriculture, AppColors.primaryBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard('Total Harvest (MT)', '1,420', Icons.eco, AppColors.teal),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            val,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestBatchesList() {
    final batches = [
      {'id': 'HB-2026-001', 'crop': 'Napier Grass (Hybrid)', 'site': 'Anantapur Site Bay 1', 'weight': '180 MT', 'status': 'Completed'},
      {'id': 'HB-2026-002', 'crop': 'Press Mud Biomass', 'site': 'Kurnool Site Bay 2', 'weight': '240 MT', 'status': 'In-Transit'},
      {'id': 'HB-2026-003', 'crop': 'Agricultural Residue', 'site': 'Tirupati Complex Bay 3', 'weight': '125 MT', 'status': 'Active'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Harvesting & Inward Logs',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          ...batches.map((b) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEDF2F7)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.grain, color: AppColors.teal, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b['crop']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('${b['id']} • ${b['site']}', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(b['weight']!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: b['status'] == 'Completed' ? Colors.green.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        b['status']!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: b['status'] == 'Completed' ? Colors.green.shade700 : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMeta = _submodules.firstWhere(
      (s) => s.key == _activeKey,
      orElse: () => _submodules.first,
    );

    return ModuleShellScaffold(
      headerTitle: activeMeta.title,
      moduleName: 'Harvesting',
      submodules: _submodules,
      activeKey: _activeKey,
      onSelectSubmodule: (key) {
        setState(() {
          _activeKey = key;
        });
      },
      hasAccess: _perm.canView,
      isLoadingPermissions: _isLoadingPerm,
      accessDeniedMessage: 'Access Denied: You do not have view permissions for Harvesting.',
      child: _buildActiveChild(),
    );
  }
}
