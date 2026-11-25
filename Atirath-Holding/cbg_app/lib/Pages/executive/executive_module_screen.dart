import 'package:flutter/material.dart';
import '../../services/rbac_service.dart';
import '../../widgets/module_ui_widgets.dart';
import 'executive_cockpit_view.dart';
import 'expansion_pipeline_view.dart';
import 'budget_variance_view.dart';
import 'multi_stream_revenue_view.dart';
import 'compliance_esg_view.dart';
import 'treasury_sourcing_view.dart';
import 'escrow_financing_view.dart';
import 'executive_alert_feed_view.dart';
import 'capex_analytics_view.dart';

class ExecutiveModuleScreen extends StatefulWidget {
  final String initialSubmodule;

  const ExecutiveModuleScreen({super.key, this.initialSubmodule = 'cockpit'});

  @override
  State<ExecutiveModuleScreen> createState() => _ExecutiveModuleScreenState();
}

class _ExecutiveModuleScreenState extends State<ExecutiveModuleScreen> {
  static const List<ModuleSubmoduleItem> _submodules = [
    ModuleSubmoduleItem(
      key: 'cockpit',
      title: 'Executive C-Suite Overview',
      shortLabel: 'Executive Cockpit',
      icon: Icons.dashboard_outlined,
    ),
    ModuleSubmoduleItem(
      key: 'pipeline',
      title: 'Expansion Pipeline Tracker',
      shortLabel: 'Expansion Pipeline',
      icon: Icons.layers_outlined,
    ),
    ModuleSubmoduleItem(
      key: 'budget-variance',
      title: 'CapEx & OpEx Cost Variance Matrix',
      shortLabel: 'Budget Variance',
      icon: Icons.attach_money,
    ),
    ModuleSubmoduleItem(
      key: 'revenue',
      title: 'Consolidated Enterprise Revenue Ledger',
      shortLabel: 'Multi-Stream Revenue',
      icon: Icons.trending_up,
    ),
    ModuleSubmoduleItem(
      key: 'compliance-esg',
      title: 'Regulatory Compliance & ESG Scorecard',
      shortLabel: 'Compliance & ESG',
      icon: Icons.verified_user_outlined,
    ),
    ModuleSubmoduleItem(
      key: 'treasury',
      title: 'Capital Sourcing & Treasury Ledger',
      shortLabel: 'Treasury & Sourcing',
      icon: Icons.account_balance_outlined,
    ),
    ModuleSubmoduleItem(
      key: 'escrow',
      title: 'Escrow & Project Financing Monitor',
      shortLabel: 'Escrow & Financing',
      icon: Icons.work_outline,
    ),
    ModuleSubmoduleItem(
      key: 'alerts',
      title: 'Executive Critical Notification Feed',
      shortLabel: 'Executive Alerts',
      icon: Icons.warning_amber_rounded,
    ),
    ModuleSubmoduleItem(
      key: 'capex-analytics',
      title: 'Project Engineering & CapEx Analytics',
      shortLabel: 'CapEx Analytics',
      icon: Icons.speed_outlined,
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
    final perm = await RbacService.getScreenPermission('EXECUTIVE_MODULE');
    if (mounted) {
      setState(() {
        _perm = perm;
        _isLoadingPerm = false;
      });
    }
  }

  Widget _buildActiveView() {
    switch (_activeKey) {
      case 'pipeline':
        return const ExpansionPipelineView();
      case 'budget-variance':
        return const BudgetVarianceView();
      case 'revenue':
        return const MultiStreamRevenueView();
      case 'compliance-esg':
        return const ComplianceEsgView();
      case 'treasury':
        return const TreasurySourcingView();
      case 'escrow':
        return const EscrowFinancingView();
      case 'alerts':
        return const ExecutiveAlertFeedView();
      case 'capex-analytics':
        return const CapexAnalyticsView();
      case 'cockpit':
      default:
        return ExecutiveCockpitView(
          onNavigateSubmodule: (key) => setState(() => _activeKey = key),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMeta = _submodules.firstWhere(
      (s) => s.key == _activeKey,
      orElse: () => _submodules.first,
    );

    return ModuleShellScaffold(
      headerTitle: _perm.canView ? activeMeta.title : 'Executive C-Suite Overview',
      moduleName: 'Executive Overview',
      submodules: _submodules,
      activeKey: _activeKey,
      onSelectSubmodule: (k) => setState(() => _activeKey = k),
      hasAccess: _perm.canView,
      isLoadingPermissions: _isLoadingPerm,
      accessDeniedMessage:
          'You do not have permission to view the Executive Overview. Please contact your administrator to request access.',
      child: _buildActiveView(),
    );
  }
}
