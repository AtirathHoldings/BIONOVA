import 'package:flutter/material.dart';
import '../../services/rbac_service.dart';
import '../../widgets/module_ui_widgets.dart';
import 'agri_inventory_overview_view.dart';
import 'civil_materials_bom_view.dart';
import 'fasteners_hardware_view.dart';
import 'piping_instrumentation_view.dart';
import 'equipment_warranty_view.dart';
import 'stock_expiry_alerts_view.dart';
import 'warehouse_weighbridge_view.dart';
import 'multi_tier_vendor_view.dart';

class InventoryManagementScreen extends StatefulWidget {
  final String initialSubmodule;

  const InventoryManagementScreen({super.key, this.initialSubmodule = 'overview'});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  static const List<ModuleSubmoduleItem> _submodules = [
    ModuleSubmoduleItem(
      key: 'overview',
      title: 'Agri-Inventory Overview',
      shortLabel: 'Overview',
      icon: Icons.inventory_2_outlined,
    ),
    ModuleSubmoduleItem(
      key: 'civil-bom',
      title: 'Civil Materials & BOM',
      shortLabel: 'Civil BOM',
      icon: Icons.foundation_outlined,
    ),
    ModuleSubmoduleItem(
      key: 'fasteners',
      title: 'Fasteners & Hardware',
      shortLabel: 'Fasteners',
      icon: Icons.build_outlined,
    ),
    ModuleSubmoduleItem(
      key: 'piping',
      title: 'Piping & Instrumentation',
      shortLabel: 'Piping',
      icon: Icons.plumbing_outlined,
    ),
    ModuleSubmoduleItem(
      key: 'warranty',
      title: 'Equipment Warranty & AMC',
      shortLabel: 'Warranty',
      icon: Icons.verified_user_outlined,
    ),
    ModuleSubmoduleItem(
      key: 'alerts',
      title: 'Stock & Expiry Alerts',
      shortLabel: 'Alerts',
      icon: Icons.warning_amber_rounded,
    ),
    ModuleSubmoduleItem(
      key: 'weightbridge',
      title: 'Warehouse & Weighbridge',
      shortLabel: 'Weighbridge',
      icon: Icons.scale_outlined,
    ),
    ModuleSubmoduleItem(
      key: 'vendors',
      title: 'Multi-Tier Vendor DB',
      shortLabel: 'Vendors',
      icon: Icons.storefront_outlined,
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
    final perm = await RbacService.getScreenPermission('INVENTORY_MANAGEMENT');
    if (mounted) {
      setState(() {
        _perm = perm;
        _isLoadingPerm = false;
      });
    }
  }

  Widget _buildActiveChild() {
    switch (_activeKey) {
      case 'civil-bom':
        return CivilMaterialsBomView(screenPerm: _perm);
      case 'fasteners':
        return FastenersHardwareView(screenPerm: _perm);
      case 'piping':
        return PipingInstrumentationView(screenPerm: _perm);
      case 'warranty':
        return EquipmentWarrantyView(screenPerm: _perm);
      case 'alerts':
        return StockExpiryAlertsView(screenPerm: _perm);
      case 'weightbridge':
        return WarehouseWeighbridgeView(screenPerm: _perm);
      case 'vendors':
        return MultiTierVendorView(screenPerm: _perm);
      case 'overview':
      default:
        return AgriInventoryOverviewView(screenPerm: _perm);
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
      moduleName: 'Inventory Management',
      submodules: _submodules,
      activeKey: _activeKey,
      onSelectSubmodule: (k) => setState(() => _activeKey = k),
      hasAccess: _perm.canView,
      isLoadingPermissions: _isLoadingPerm,
      accessDeniedMessage:
          'You do not have permission to access the Inventory Management module. Please contact your System Administrator.',
      child: _buildActiveChild(),
    );
  }
}
