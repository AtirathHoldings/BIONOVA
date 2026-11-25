import 'package:flutter/material.dart';
import '../../services/rbac_service.dart';
import '../../widgets/module_ui_widgets.dart';
import '../../utils/app_colors.dart';

class DprManagementScreen extends StatefulWidget {
  final String initialSubmodule;

  const DprManagementScreen({super.key, this.initialSubmodule = 'reports'});

  @override
  State<DprManagementScreen> createState() => _DprManagementScreenState();
}

class _DprManagementScreenState extends State<DprManagementScreen> {
  static const List<ModuleSubmoduleItem> _submodules = [
    ModuleSubmoduleItem(
      key: 'reports',
      title: 'Daily Progress Reports (DPR)',
      shortLabel: 'Reports',
      icon: Icons.assignment_outlined,
    ),
    ModuleSubmoduleItem(
      key: 'resources',
      title: 'Labor & Machinery Utilization',
      shortLabel: 'Resources',
      icon: Icons.engineering_outlined,
    ),
    ModuleSubmoduleItem(
      key: 'photos',
      title: 'Site Work Log & Photos',
      shortLabel: 'Site Photos',
      icon: Icons.photo_camera_outlined,
    ),
    ModuleSubmoduleItem(
      key: 'blockers',
      title: 'Site Delays & Issues',
      shortLabel: 'Blockers',
      icon: Icons.report_problem_outlined,
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
    final perm = await RbacService.getScreenPermission('DPR_MANAGEMENT');
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
          _buildDprReportsList(),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard('Today Submissions', '3', Icons.fact_check, AppColors.primaryBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard('Active Manpower', '142', Icons.groups, AppColors.teal),
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

  Widget _buildDprReportsList() {
    final reports = [
      {'id': 'DPR-2026-0042', 'site': 'Anantapur CBG Phase 1', 'engineer': 'K. S. Rao', 'progress': 'Digester Foundation Concrete Pour', 'status': 'Approved'},
      {'id': 'DPR-2026-0041', 'site': 'Kurnool Plant Bay 2', 'engineer': 'M. V. Naidu', 'progress': 'Feedstock Silo Structural Fabrication', 'status': 'Submitted'},
      {'id': 'DPR-2026-0040', 'site': 'Tirupati Complex Site 3', 'engineer': 'R. Prasad', 'progress': 'Piping & Compressor Line Pressure Test', 'status': 'Approved'},
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
            'Recent Daily Progress Submissions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          ...reports.map((r) => Container(
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
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment, color: AppColors.primaryBlue, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['progress']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('${r['id']} • ${r['site']} (${r['engineer']})', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: r['status'] == 'Approved' ? Colors.green.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    r['status']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: r['status'] == 'Approved' ? Colors.green.shade700 : Colors.amber.shade800,
                    ),
                  ),
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
      moduleName: 'DPR',
      submodules: _submodules,
      activeKey: _activeKey,
      onSelectSubmodule: (key) {
        setState(() {
          _activeKey = key;
        });
      },
      hasAccess: _perm.canView,
      isLoadingPermissions: _isLoadingPerm,
      accessDeniedMessage: 'Access Denied: You do not have view permissions for DPR Management.',
      child: _buildActiveChild(),
    );
  }
}
