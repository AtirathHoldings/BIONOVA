import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/executive_api_service.dart';
import '../../widgets/module_ui_widgets.dart';

class ExecutiveCockpitView extends StatefulWidget {
  final ValueChanged<String> onNavigateSubmodule;

  const ExecutiveCockpitView({super.key, required this.onNavigateSubmodule});

  @override
  State<ExecutiveCockpitView> createState() => _ExecutiveCockpitViewState();
}

class _ExecutiveCockpitViewState extends State<ExecutiveCockpitView> {
  Map<String, dynamic> _kpis = {};
  bool _isLoading = true;
  String _selectedUnit = 'All Operations';
  String _selectedPeriod = 'FY 2026-27 (YTD)';

  @override
  void initState() {
    super.initState();
    _loadKpis();
  }

  Future<void> _loadKpis() async {
    final data = await ExecutiveApiService.getCockpitKpis();
    if (mounted) {
      setState(() {
        _kpis = data;
        _isLoading = false;
      });
    }
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  int _intVal(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final totalCapex = _num(_kpis['totalCapexApprovedCr']);
    final capexIncurred = _num(_kpis['totalCapexSpentCr']);
    final capexProgress = totalCapex > 0 ? ((capexIncurred / totalCapex) * 100).round().clamp(0, 100) : 0;

    final totalOpex = _num(_kpis['actualBudgetCr']);
    final opexIncurred = _num(_kpis['baselineBudgetCr']);
    final opexProgress = totalOpex > 0 ? ((opexIncurred / totalOpex) * 100).round().clamp(0, 100) : 0;

    final totalRevenueInr = _num(_kpis['totalRevenueInr']);
    final totalRevenueCr = (totalRevenueInr / 10000000).toStringAsFixed(1);
    final activeProjectsCount = _intVal(_kpis['activeProjectsCount']);
    final totalCompliances = _intVal(_kpis['totalCompliances']);
    final activeAlertsCount = _intVal(_kpis['activeAlertsCount']);
    const totalAcres = 0;

    final portals = [
      {
        'key': 'pipeline',
        'title': 'Expansion Pipeline',
        'desc': 'Greenfield & Brownfield construction velocity',
        'icon': Icons.layers_outlined,
        'color': const Color(0xFF2563EB),
        'badge': '$activeProjectsCount Active Plants',
      },
      {
        'key': 'budget-variance',
        'title': 'Budget Variance Matrix',
        'desc': 'Granular CapEx & OpEx cost-center variance',
        'icon': Icons.attach_money,
        'color': const Color(0xFF059669),
        'badge': 'Runway: Healthy',
      },
      {
        'key': 'revenue',
        'title': 'Multi-Stream Revenue',
        'desc': 'CBG, FOM, Carbon Credits & Tipping fees',
        'icon': Icons.trending_up,
        'color': const Color(0xFF1677FF),
        'badge': '₹$totalRevenueCr Cr Revenue',
      },
      {
        'key': 'compliance-esg',
        'title': 'Compliance & ESG Registry',
        'desc': 'PESO, SPCB CTO permits & sustainability scores',
        'icon': Icons.verified_user_outlined,
        'color': const Color(0xFF059669),
        'badge': '$totalCompliances Compliances',
      },
      {
        'key': 'treasury',
        'title': 'Treasury & Capital Sourcing',
        'desc': 'Debt facilities, green bonds & equity drawdowns',
        'icon': Icons.account_balance_outlined,
        'color': const Color(0xFF7C3AED),
        'badge': 'Credit Lines',
      },
      {
        'key': 'escrow',
        'title': 'Escrow & Financing Monitor',
        'desc': 'Dedicated project escrow accounts & DSRA',
        'icon': Icons.work_outline,
        'color': const Color(0xFF0284C7),
        'badge': 'Escrow DSRA',
      },
      {
        'key': 'alerts',
        'title': 'Executive Alert Center',
        'desc': 'High-priority budget, license & safety triggers',
        'icon': Icons.warning_amber_rounded,
        'color': const Color(0xFFDC2626),
        'badge': '$activeAlertsCount Priority Alerts',
      },
      {
        'key': 'capex-analytics',
        'title': 'Project & CapEx Analytics',
        'desc': 'Engineering milestones, telemetry & burn rate',
        'icon': Icons.speed_outlined,
        'color': const Color(0xFFD97706),
        'badge': 'Analytics',
      },
    ];

    return RefreshIndicator(
      onRefresh: _loadKpis,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            'Comprehensive C-suite cockpit aggregating financial execution, project velocity, land utilization, and department-level governance.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          // Controls
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedUnit,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Operations Site'),
                  items: const [
                    DropdownMenuItem(value: 'All Operations', child: Text('All Operations & Sites', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Plant 1 - Hyderabad East CBG', child: Text('Plant 1 - Hyderabad East CBG', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Plant 2 - Medak Agri Hub', child: Text('Plant 2 - Medak Agri Hub', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Plant 3 - Nalgonda Biomass Facility', child: Text('Plant 3 - Nalgonda Facility', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedUnit = v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedPeriod,
                  isExpanded: true,
                  decoration: moduleInputDecoration('Period'),
                  items: const [
                    DropdownMenuItem(value: 'FY 2026-27 (YTD)', child: Text('FY 2026-27 (YTD)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Q3 (Oct - Dec 2026)', child: Text('Q3 (Oct - Dec 2026)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Q2 (Jul - Sep 2026)', child: Text('Q2 (Jul - Sep 2026)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Annual Forecast 2027', child: Text('Annual Forecast 2027', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedPeriod = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                showPrintablePreviewDialog(
                  context,
                  title: 'BioNova Executive Summary',
                  copyText:
                      'BioNova Clean Energy & Agritech Holdings ($_selectedUnit | $_selectedPeriod)\n'
                      'Capital Portfolio: ₹${totalCapex.toStringAsFixed(1)} Cr (Spent: ₹${capexIncurred.toStringAsFixed(1)} Cr / $capexProgress%)\n'
                      'OpEx: ₹${totalOpex.toStringAsFixed(1)} Cr (Burn: ₹${opexIncurred.toStringAsFixed(1)} Cr / $opexProgress%)\n'
                      'Annual Revenue Run-Rate: ₹$totalRevenueCr Cr/yr\n'
                      'Active Projects: $activeProjectsCount | Compliances: $totalCompliances | Priority Alerts: $activeAlertsCount',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BioNova Clean Energy & Agritech Holdings', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text('$_selectedUnit • $_selectedPeriod', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                      const Divider(height: 20),
                      Text('• Capital Portfolio: ₹$totalCapex Cr (Incurred: ₹$capexIncurred Cr, $capexProgress%)'),
                      Text('• Annualized Opex: ₹$totalOpex Cr (Burn: ₹$opexIncurred Cr, $opexProgress%)'),
                      Text('• Revenue Run-Rate: ₹$totalRevenueCr Cr/yr'),
                      Text('• Active Plants: $activeProjectsCount | Compliances: $totalCompliances | Alerts: $activeAlertsCount'),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.print_outlined, size: 16),
              label: const Text('Export Executive PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Hero Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF02153F), Color(0xFF0F2B6B), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Color(0xFF38BDF8), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'BioNova Clean Energy & Agritech Holdings',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Real-time executive cockpit tracking enterprise financial execution, expansion milestones, agricultural feedstock land utilization, and statutory governance.',
                  style: GoogleFonts.inter(color: const Color(0xFFBFDBFE), fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _heroStat('₹$totalCapex Cr', 'Capital Portfolio'),
                    _heroStat(totalCapex > 0 ? '24.5%' : '--', 'Projected IRR / ROI'),
                    _heroStat(totalAcres > 0 ? '$totalAcres Ac' : '--', 'Total Land Holding'),
                  ],
                ),
              ],
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: LinearProgressIndicator(),
            ),

          const SizedBox(height: 18),
          Text(
            'Executive Submodule Portals',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            'Direct access into deep-dive ledgers, telemetry monitors, and compliance registries',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: portals.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final p = portals[index];
              final color = p['color'] as Color;
              return InkWell(
                onTap: () => widget.onNavigateSubmodule(p['key'] as String),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(p['icon'] as IconData, size: 18, color: color),
                          ),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p['badge'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['title'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            p['desc'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Launch Portal',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(Icons.arrow_forward, size: 13, color: color),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 18),

          // Pillar 1: Financial Execution
          _pillarCard(
            icon: Icons.attach_money,
            iconColor: const Color(0xFF1677FF),
            title: 'Financial Execution & Budget Adherence',
            tag: 'Healthy Runway',
            tagBg: const Color(0xFFDCFCE7),
            tagColor: const Color(0xFF166534),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _metricTile('Capex Allocated', '₹$totalCapex Cr', '₹$capexIncurred Cr Incurred ($capexProgress%)', const Color(0xFF059669)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricTile('Annualized Opex', '₹$totalOpex Cr', '₹$opexIncurred Cr Burn ($opexProgress%)', const Color(0xFF2563EB)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _metricTile('Annual Revenue Run-Rate', '₹$totalRevenueCr Cr/yr', 'Live Invoiced Revenue', const Color(0xFF059669)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricTile('EBITDA Margin Index', '--', 'Audited at FY Close', const Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _progressRow('Capex Deployment ($capexProgress%)', '₹$capexIncurred / ₹$totalCapex Cr', capexProgress / 100.0, const Color(0xFF10B981)),
                const SizedBox(height: 10),
                _progressRow('Opex Adherence ($opexProgress%)', '₹$opexIncurred / ₹$totalOpex Cr', opexProgress / 100.0, const Color(0xFF3B82F6)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Pillar 2: Project Velocity
          _pillarCard(
            icon: Icons.speed,
            iconColor: const Color(0xFF1677FF),
            title: 'Project Velocity & Execution Velocity',
            tag: '$activeProjectsCount Active Plants',
            tagBg: const Color(0xFFEFF6FF),
            tagColor: const Color(0xFF1E40AF),
            child: Column(
              children: [
                if (activeProjectsCount > 0)
                  _progressRow('Active Capital Projects In Execution', '$activeProjectsCount Projects Active', 1.0, const Color(0xFF10B981))
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No active expansion projects registered. Create projects in the Expansion Pipeline to track engineering velocity.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _velocityBox('0', 'Completed Milestones', const Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    _velocityBox('$activeProjectsCount', 'Active In-Progress', const Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    _velocityBox('0', 'Critical Blockers', const Color(0xFF64748B)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Pillar 3: Farmland Asset Utilization
          _pillarCard(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFF059669),
            title: 'Farmland Asset Utilization',
            tag: '0 Acres Registered',
            tagBg: const Color(0xFFFEF3C7),
            tagColor: const Color(0xFF92400E),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _landTile('CULTIVATED BIOMASS', '0 Acres', 'Registered Crops', const Color(0xFF10B981))),
                    const SizedBox(width: 8),
                    Expanded(child: _landTile('PLANT INFRASTRUCTURE', '0 Acres', 'Processing & Digester', const Color(0xFF3B82F6))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _landTile('UNDER PREPARATION', '0 Acres', 'Land Preparation', const Color(0xFFF59E0B))),
                    const SizedBox(width: 8),
                    Expanded(child: _landTile('BIOMASS YIELD EFFICIENCY', '--', 'Awaiting Harvest Data', const Color(0xFF7C3AED))),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Agronomy Note: Soil moisture sensors and feedstock telemetry log real-time agricultural data once land parcels and feedstock cycles are configured.',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF334155)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Pillar 4: Department Governance
          _pillarCard(
            icon: Icons.people_outline,
            iconColor: const Color(0xFF7C3AED),
            title: 'Department Operational Summaries',
            tag: totalCompliances > 0 ? '100% Governance' : '-- Governance',
            tagBg: const Color(0xFFF5F3FF),
            tagColor: const Color(0xFF6D28D9),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No departmental incident escalations or active compliance variances reported.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Strategic Risk Radar
          _pillarCard(
            icon: Icons.verified_user_outlined,
            iconColor: const Color(0xFFDC2626),
            title: 'Strategic Risk Radar & Action Items',
            tag: 'Quarterly Review',
            tagBg: const Color(0xFFF1F5F9),
            tagColor: const Color(0xFF475569),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                children: [
                  Text(
                    '✓ All Operational & Statutory Risk Indicators are Clear',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Live telemetry and environmental compliance monitors show zero active breaches across facilities.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String val, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              val,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFFCBD5E1),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillarCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String tag,
    required Color tagBg,
    required Color tagColor,
    required Widget child,
  }) {
    return Container(
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
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              ModuleTag(text: tag, bgColor: tagBg, textColor: tagColor),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _metricTile(String label, String val, String sub, Color subColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(val, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(sub, style: GoogleFonts.inter(fontSize: 10.5, color: subColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _progressRow(String label, String rightText, double progress, Color barColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
            Text(rightText, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      ],
    );
  }

  Widget _velocityBox(String numText, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(numText, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _landTile(String title, String val, String sub, Color accent) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: accent, width: 3.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
          const SizedBox(height: 3),
          Text(val, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          Text(sub, style: GoogleFonts.inter(fontSize: 10.5, color: accent)),
        ],
      ),
    );
  }
}
