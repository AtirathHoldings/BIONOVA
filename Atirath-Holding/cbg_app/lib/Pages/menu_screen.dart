import 'package:flutter/material.dart';
import '../widgets/header.dart';
import 'settings_screen.dart';
import 'main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/rbac_service.dart';
import '../utils/app_colors.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _hasInventoryAccess = false;
  bool _hasVisitorAccess = false;
  bool _hasExecutiveAccess = false;
  bool _hasSupplyChainAccess = false;
  bool _hasHarvestingAccess = false;
  bool _hasDprAccess = false;

  @override
  void initState() {
    super.initState();
    _loadModuleAccess();
  }

  Future<void> _loadModuleAccess() async {
    final results = await Future.wait([
      RbacService.hasModuleSidebarAccess('INVENTORY_MANAGEMENT'),
      RbacService.hasModuleSidebarAccess('VISITOR_MANAGEMENT'),
      RbacService.hasModuleSidebarAccess('EXECUTIVE_MODULE'),
      RbacService.hasModuleSidebarAccess('PROCUREMENT_MANAGEMENT'),
      RbacService.hasModuleSidebarAccess('ASSET_MAINTENANCE'),
      RbacService.hasModuleSidebarAccess('FLEET_DISPATCH'),
      RbacService.hasModuleSidebarAccess('HARVESTING_MODULE'),
      RbacService.hasModuleSidebarAccess('DPR_MANAGEMENT'),
    ]);
    if (mounted) {
      setState(() {
        _hasInventoryAccess = results[0];
        _hasVisitorAccess = results[1];
        _hasExecutiveAccess = results[2];
        _hasSupplyChainAccess = results[3] || results[4] || results[5];
        _hasHarvestingAccess = results[6];
        _hasDprAccess = results[7];
      });
    }
  }

  final List<Map<String, dynamic>> menuItems = [
    {'title': 'My Projects', 'icon': Icons.folder_open_outlined, 'color': AppColors.purple, 'target': 'projects'},
    {'title': 'My Tasks', 'icon': Icons.check_box_outlined, 'color': AppColors.open, 'target': 'tasks'},
    {
      'title': 'Assignments', 
      'icon': Icons.person_add_alt_1_outlined, 
      'color': AppColors.teal, 
      'target': 'individual_tasks_list',
      'subItems': [
        {'title': 'My Assignments', 'tabIndex': 0},
        {'title': 'Assigned by Me', 'tabIndex': 1},
      ]
    },
    {'title': 'Calendar', 'icon': Icons.calendar_today_outlined, 'color': AppColors.inProgress, 'target': 'calendar'},
    {'title': 'Settings', 'icon': Icons.settings_outlined, 'color': AppColors.textGrey, 'target': 'settings'},
    {'title': 'Logout', 'icon': Icons.logout_outlined, 'color': AppColors.overdue, 'target': 'logout'},
  ];

  static const List<Map<String, String>> _inventorySubItems = [
    {'title': 'Agri-Inventory Overview', 'key': 'overview'},
    {'title': 'Civil Materials & BOM', 'key': 'civil-bom'},
    {'title': 'Fasteners & Hardware', 'key': 'fasteners'},
    {'title': 'Piping & Instrumentation', 'key': 'piping'},
    {'title': 'Equipment Warranty', 'key': 'warranty'},
    {'title': 'Stock & Expiry Alerts', 'key': 'alerts'},
    {'title': 'Warehouse & Weighbridge', 'key': 'weightbridge'},
    {'title': 'Multi-Tier Vendor DB', 'key': 'vendors'},
  ];

  static const List<Map<String, String>> _executiveSubItems = [
    {'title': 'Executive Cockpit', 'key': 'cockpit'},
    {'title': 'Expansion Pipeline', 'key': 'pipeline'},
    {'title': 'Budget Variance', 'key': 'budget-variance'},
    {'title': 'Multi-Stream Revenue', 'key': 'revenue'},
    {'title': 'Compliance & ESG', 'key': 'compliance-esg'},
    {'title': 'Treasury & Sourcing', 'key': 'treasury'},
    {'title': 'Escrow & Financing', 'key': 'escrow'},
    {'title': 'Executive Alerts', 'key': 'alerts'},
    {'title': 'CapEx Analytics', 'key': 'capex-analytics'},
  ];

  static const List<Map<String, String>> _visitorDirectItems = [
    {'title': 'Dashboard', 'key': 'dashboard'},
    {'title': 'Visitor Registration', 'key': 'registration'},
    {'title': 'Visitor List', 'key': 'list'},
    {'title': 'Visit Requests', 'key': 'request'},
    {'title': 'Appointments', 'key': 'appointments'},
    {'title': 'Approvals', 'key': 'approvals'},
  ];

  static const List<Map<String, dynamic>> _visitorGroups = [
    {
      'title': 'Gate Management',
      'items': [
        {'title': 'Gate Check-In', 'key': 'gate-checkin'},
        {'title': 'Gate Check-Out', 'key': 'gate-checkout'},
        {'title': 'Gate Pass Management', 'key': 'gate-pass'},
        {'title': 'QR Verification (Soon)', 'key': 'qr-verification'},
      ],
    },
    {
      'title': 'Security Management',
      'items': [
        {'title': 'Vehicle Entry', 'key': 'security-vehicles'},
        {'title': 'Material Inward', 'key': 'material-inward'},
        {'title': 'Material Outward', 'key': 'material-outward'},
        {'title': 'Safety Clearance', 'key': 'safety-clearance'},
        {'title': 'Zone Access', 'key': 'access-management'},
      ],
    },
    {
      'title': 'Visitor Tracking',
      'items': [
        {'title': 'Live Inside Tracking', 'key': 'live-tracking'},
        {'title': 'Visitor History', 'key': 'history'},
        {'title': 'Overdue Visitors', 'key': 'overdue-tracking'},
        {'title': 'Configuration', 'key': 'configuration'},
      ],
    },
  ];

  void _handleNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications clicked')),
    );
  }

  void _navigateToScreen(String target) {
    switch (target) {
      case 'dashboard':
        if (MainScreen.navigatorKey.currentState != null) {
          MainScreen.navigatorKey.currentState!.changeTab(0);
        }
        break;
      case 'projects':
        if (MainScreen.navigatorKey.currentState != null) {
          MainScreen.navigatorKey.currentState!.changeTab(1);
        }
        break;
      case 'tasks':
        if (MainScreen.navigatorKey.currentState != null) {
          MainScreen.navigatorKey.currentState!.changeTab(2);
        }
        break;
      case 'individual_tasks_list':
        Navigator.pushNamed(context, '/individual-tasks-list');
        break;
      case 'calendar':
        if (MainScreen.navigatorKey.currentState != null) {
          MainScreen.navigatorKey.currentState!.changeTab(3);
        }
        break;
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.overdue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    RbacService.clearMemoryCache();
    await ApiService.clearCache(clearAuth: true);

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/signin', 
        (route) => false
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Widget _buildSimpleSubTile(String title, VoidCallback onTap, {double leftPadding = 68}) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: leftPadding, right: 20),
      dense: true,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textGrey,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 14,
        color: AppColors.textLight,
      ),
      onTap: onTap,
    );
  }

  Widget _buildModuleExpansion({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
      ),
      trailing: const Icon(
        Icons.keyboard_arrow_down,
        size: 16,
        color: AppColors.textLight,
      ),
      shape: const Border(),
      collapsedShape: const Border(),
      children: children,
    );
  }

  List<Widget> _buildMenuRows() {
    final List<Widget> rows = [];

    void addStandardItem(Map<String, dynamic> item) {
      final isLogout = item['target'] == 'logout';
      final hasSubItems = item['subItems'] != null;

      if (hasSubItems) {
        rows.add(_buildModuleExpansion(
          title: item['title'] as String,
          icon: item['icon'] as IconData,
          color: item['color'] as Color,
          children: (item['subItems'] as List<dynamic>).map((subItem) {
            final subMap = subItem as Map<String, dynamic>;
            return _buildSimpleSubTile(
              subMap['title'] as String,
              () {
                Navigator.pushNamed(
                  context,
                  '/individual-tasks-list',
                  arguments: subMap['tabIndex'] as int,
                );
              },
            );
          }).toList(),
        ));
        return;
      }

      rows.add(ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (item['color'] as Color).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            item['icon'] as IconData,
            color: isLogout ? AppColors.overdue : item['color'] as Color,
            size: 18,
          ),
        ),
        title: Text(
          item['title'] as String,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: isLogout ? AppColors.overdue : AppColors.textDark,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: 16,
          color: isLogout ? AppColors.overdue : AppColors.textLight,
        ),
        onTap: () => _navigateToScreen(item['target'] as String),
      ));
    }

    for (final item in menuItems) {
      if (item['target'] == 'settings') {
        if (_hasInventoryAccess) {
          rows.add(_buildModuleExpansion(
            title: 'Inventory',
            icon: Icons.inventory_2_outlined,
            color: AppColors.primaryBlue,
            children: _inventorySubItems
                .map((s) => _buildSimpleSubTile(
                      s['title']!,
                      () => Navigator.pushNamed(context, '/inventory', arguments: s['key']),
                    ))
                .toList(),
          ));
        }

        if (_hasVisitorAccess) {
          rows.add(_buildModuleExpansion(
            title: 'Visitor Management',
            icon: Icons.badge_outlined,
            color: AppColors.open,
            children: [
              ..._visitorDirectItems.map((s) => _buildSimpleSubTile(
                    s['title']!,
                    () => Navigator.pushNamed(context, '/visitor-management', arguments: s['key']),
                  )),
              ..._visitorGroups.map((grp) {
                final subList = grp['items'] as List<Map<String, String>>;
                return ExpansionTile(
                  tilePadding: const EdgeInsets.only(left: 68, right: 20),
                  dense: true,
                  title: Text(
                    grp['title'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  trailing: const Icon(Icons.keyboard_arrow_down, size: 15, color: AppColors.textLight),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  children: subList
                      .map((s) => _buildSimpleSubTile(
                            s['title']!,
                            () => Navigator.pushNamed(context, '/visitor-management', arguments: s['key']),
                            leftPadding: 84,
                          ))
                      .toList(),
                );
              }),
            ],
          ));
        }

        if (_hasExecutiveAccess) {
          rows.add(_buildModuleExpansion(
            title: 'Executive Overview',
            icon: Icons.analytics_outlined,
            color: AppColors.purple,
            children: _executiveSubItems
                .map((s) => _buildSimpleSubTile(
                      s['title']!,
                      () => Navigator.pushNamed(context, '/executive', arguments: s['key']),
                    ))
                .toList(),
          ));
        }

        if (_hasSupplyChainAccess) {
          rows.add(_buildModuleExpansion(
            title: 'Supply Chain & Operations',
            icon: Icons.local_shipping_outlined,
            color: AppColors.teal,
            children: [
              _buildSimpleSubTile(
                'Procurement & PO',
                () => Navigator.pushNamed(context, '/procurement'),
              ),
              _buildSimpleSubTile(
                'Asset Maintenance (CMMS)',
                () => Navigator.pushNamed(context, '/asset-maintenance'),
              ),
              _buildSimpleSubTile(
                'Fleet & Dispatch Logistics',
                () => Navigator.pushNamed(context, '/dispatch-logistics'),
              ),
            ],
          ));
        }

        if (_hasHarvestingAccess) {
          rows.add(ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.agriculture_outlined, color: AppColors.teal, size: 18),
            ),
            title: const Text(
              'Harvesting & Feedstock',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.textDark),
            ),
            trailing: const Icon(Icons.chevron_right, size: 16, color: AppColors.textLight),
            onTap: () => Navigator.pushNamed(context, '/harvesting'),
          ));
        }

        if (_hasDprAccess) {
          rows.add(ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_outlined, color: AppColors.primaryBlue, size: 18),
            ),
            title: const Text(
              'Daily Progress Report (DPR)',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.textDark),
            ),
            trailing: const Icon(Icons.chevron_right, size: 16, color: AppColors.textLight),
            onTap: () => Navigator.pushNamed(context, '/dpr'),
          ));
        }
      }

      addStandardItem(item);
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _buildMenuRows();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: rows.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
        itemBuilder: (context, index) => rows[index],
      ),
    );
  }
}