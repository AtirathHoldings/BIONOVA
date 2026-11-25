import 'package:flutter/material.dart';
import '../../services/rbac_service.dart';
import '../../widgets/module_ui_widgets.dart';
import 'visitor_dashboard_view.dart';
import 'visitor_registration_view.dart';
import 'visitor_list_view.dart';
import 'visit_request_view.dart';
import 'appointment_management_view.dart';
import 'visitor_approval_view.dart';
import 'gate_checkin_view.dart';
import 'gate_checkout_view.dart';
import 'gate_pass_management_view.dart';
import 'qr_verification_view.dart';
import 'vehicle_management_view.dart';
import 'material_inward_view.dart';
import 'material_outward_view.dart';
import 'safety_clearance_view.dart';
import 'visitor_access_management_view.dart';
import 'live_inside_tracking_view.dart';
import 'visitor_history_view.dart';
import 'overdue_tracking_view.dart';
import 'visitor_configuration_view.dart';

class VisitorManagementScreen extends StatefulWidget {
  final String initialSubmodule;

  const VisitorManagementScreen({super.key, this.initialSubmodule = 'dashboard'});

  @override
  State<VisitorManagementScreen> createState() => _VisitorManagementScreenState();
}

class _VisitorManagementScreenState extends State<VisitorManagementScreen> {
  static const List<ModuleSubmoduleItem> _submodules = [
    ModuleSubmoduleItem(key: 'dashboard', title: 'Visitor Operations Center', shortLabel: 'Dashboard', icon: Icons.dashboard_outlined),
    ModuleSubmoduleItem(key: 'registration', title: 'Visitor Registration', shortLabel: 'Registration', icon: Icons.person_add_alt_1_outlined),
    ModuleSubmoduleItem(key: 'list', title: 'Master Visitor Directory', shortLabel: 'Visitor List', icon: Icons.groups_outlined),
    ModuleSubmoduleItem(key: 'request', title: 'Visit Requests', shortLabel: 'Requests', icon: Icons.mail_outline),
    ModuleSubmoduleItem(key: 'appointments', title: 'Appointments', shortLabel: 'Appointments', icon: Icons.calendar_today_outlined),
    ModuleSubmoduleItem(key: 'approvals', title: 'Security & Host Approvals', shortLabel: 'Approvals', icon: Icons.verified_user_outlined),
    ModuleSubmoduleItem(key: 'gate-checkin', title: 'Gate Check-In', shortLabel: 'Check-In', category: 'Gate Management', icon: Icons.login),
    ModuleSubmoduleItem(key: 'gate-checkout', title: 'Gate Check-Out', shortLabel: 'Check-Out', category: 'Gate Management', icon: Icons.logout),
    ModuleSubmoduleItem(key: 'gate-pass', title: 'Gate Pass Management', shortLabel: 'Gate Pass', category: 'Gate Management', icon: Icons.badge_outlined),
    ModuleSubmoduleItem(key: 'qr-verification', title: 'QR Kiosk Verification', shortLabel: 'QR Verify', category: 'Gate Management', icon: Icons.qr_code_scanner, isComingSoon: true),
    ModuleSubmoduleItem(key: 'security-vehicles', title: 'Vehicle Management', shortLabel: 'Vehicles', category: 'Security', icon: Icons.local_shipping_outlined),
    ModuleSubmoduleItem(key: 'material-inward', title: 'Material Inward Gate', shortLabel: 'Inward', category: 'Security', icon: Icons.move_to_inbox_outlined),
    ModuleSubmoduleItem(key: 'material-outward', title: 'Material Outward Gate', shortLabel: 'Outward', category: 'Security', icon: Icons.outbox_outlined),
    ModuleSubmoduleItem(key: 'safety-clearance', title: 'ATEX Safety Clearance', shortLabel: 'Safety', category: 'Security', icon: Icons.health_and_safety_outlined),
    ModuleSubmoduleItem(key: 'access-management', title: 'Zone Access Matrix', shortLabel: 'Zone Access', category: 'Security', icon: Icons.security_outlined),
    ModuleSubmoduleItem(key: 'live-tracking', title: 'Live Inside Tracking', shortLabel: 'Live Inside', category: 'Visitor Tracking', icon: Icons.radar_outlined),
    ModuleSubmoduleItem(key: 'history', title: 'Visitor Audit History', shortLabel: 'History', category: 'Visitor Tracking', icon: Icons.history),
    ModuleSubmoduleItem(key: 'overdue-tracking', title: 'Overdue Visitor Tracking', shortLabel: 'Overdue', category: 'Visitor Tracking', icon: Icons.warning_amber_rounded),
    ModuleSubmoduleItem(key: 'configuration', title: 'Visitor Configuration', shortLabel: 'Config', category: 'Visitor Tracking', icon: Icons.settings_outlined),
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
    final perm = await RbacService.getScreenPermission('VISITOR_MANAGEMENT');
    if (mounted) {
      setState(() {
        _perm = perm;
        _isLoadingPerm = false;
      });
    }
  }

  void _navigateToSubmodule(String key) {
    setState(() => _activeKey = key);
  }

  Widget _buildActiveChild() {
    switch (_activeKey) {
      case 'registration':
        return VisitorRegistrationView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
      case 'list':
        return VisitorListView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
      case 'request':
        return VisitRequestView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
      case 'appointments':
        return AppointmentManagementView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
      case 'approvals':
        return VisitorApprovalView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
      case 'gate-checkin':
        return GateCheckinView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
      case 'gate-checkout':
        return GateCheckoutView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
      case 'gate-pass':
        return GatePassManagementView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
      case 'qr-verification':
        return QrVerificationView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
      case 'security-vehicles':
        return VehicleManagementView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
      case 'material-inward':
        return MaterialInwardView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
      case 'material-outward':
        return MaterialOutwardView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
      case 'safety-clearance':
        return SafetyClearanceView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
      case 'access-management':
        return VisitorAccessManagementView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
      case 'live-tracking':
        return LiveInsideTrackingView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
      case 'history':
        return VisitorHistoryView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
      case 'overdue-tracking':
        return OverdueTrackingView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
      case 'configuration':
        return VisitorConfigurationView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
      case 'dashboard':
      default:
        return VisitorDashboardView(screenPerm: _perm, onNavigate: _navigateToSubmodule);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMeta = _submodules.firstWhere(
      (s) => s.key == _activeKey,
      orElse: () => _submodules.first,
    );

    return ModuleShellScaffold(
      headerTitle: activeMeta.title,
      moduleName: 'Visitor Management',
      submodules: _submodules,
      activeKey: _activeKey,
      onSelectSubmodule: _navigateToSubmodule,
      hasAccess: _perm.canView,
      isLoadingPermissions: _isLoadingPerm,
      accessDeniedMessage:
          'You do not have permission to access the Visitor Management module. Please contact your System Administrator.',
      child: _buildActiveChild(),
    );
  }
}
