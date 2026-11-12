import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import {
  TrendingUp,
  DollarSign,
  PieChart,
  Gauge,
  MapPin,
  Building,
  Users,
  ShieldCheck,
  CheckCircle2,
  AlertCircle,
  Clock,
  Printer,
  ChevronRight,
  ArrowUpRight,
  ArrowDownRight,
  Briefcase,
  Zap,
  Activity,
  Flame,
  Sprout,
  Landmark,
  FileText,
  AlertTriangle,
  Layers,
  ArrowRight
} from "lucide-react";
import { getCockpitKpis } from "./executiveApi";

const ExecutiveCockpitOverview = () => {
  const navigate = useNavigate();
  const [kpis, setKpis] = useState(null);

  useEffect(() => {
    getCockpitKpis().then(data => {
      if (data && Object.keys(data).length > 0) setKpis(data);
    }).catch(err => console.warn("Failed to load cockpit KPIs:", err));
  }, []);
  const [selectedPeriod, setSelectedPeriod] = useState("FY 2026-27 (YTD)");
  const [selectedUnit, setSelectedUnit] = useState("All Operations");

  // Dynamic values adjusted slightly by filter
  const isMedak = selectedUnit.includes("Medak");
  const isNalgonda = selectedUnit.includes("Nalgonda");
  const isHyderabad = selectedUnit.includes("Hyderabad");

  const totalCapex = Number(kpis?.totalCapexApprovedCr || 0);
  const capexIncurred = Number(kpis?.totalCapexSpentCr || 0);
  const capexProgress = totalCapex > 0 ? Math.round((capexIncurred / totalCapex) * 100) : 0;

  const totalOpex = Number(kpis?.actualBudgetCr || 0);
  const opexIncurred = Number(kpis?.baselineBudgetCr || 0);
  const opexProgress = totalOpex > 0 ? Math.round((opexIncurred / totalOpex) * 100) : 0;

  const totalAcres = 0;
  const cultivatedAcres = 0;
  const infraAcres = 0;
  const prepAcres = 0;

  const handlePrint = () => {
    window.print();
  };

  const quickNavModules = [
    {
      title: "Expansion Pipeline",
      desc: "Greenfield & Brownfield construction velocity",
      path: "/executive/pipeline",
      icon: Layers,
      color: "#2563eb",
      badge: `${kpis?.activeProjectsCount || 0} Active Plants`
    },
    {
      title: "Budget Variance Matrix",
      desc: "Granular CapEx & OpEx cost-center variance",
      path: "/executive/budget-variance",
      icon: DollarSign,
      color: "#059669",
      badge: "Runway: Healthy"
    },
    {
      title: "Multi-Stream Revenue",
      desc: "CBG, FOM, Carbon Credits & Tipping fees",
      path: "/executive/revenue",
      icon: TrendingUp,
      color: "#1677ff",
      badge: `₹${((kpis?.totalRevenueInr || 0) / 10000000).toFixed(1)} Cr Revenue`
    },
    {
      title: "Compliance & ESG Registry",
      desc: "PESO, SPCB CTO permits & sustainability scores",
      path: "/executive/compliance-esg",
      icon: ShieldCheck,
      color: "#059669",
      badge: `${kpis?.totalCompliances || 0} Compliances`
    },
    {
      title: "Treasury & Capital Sourcing",
      desc: "Debt facilities, green bonds & equity drawdowns",
      path: "/executive/treasury",
      icon: Landmark,
      color: "#7c3aed",
      badge: "Credit Lines"
    },
    {
      title: "Escrow & Financing Monitor",
      desc: "Dedicated project escrow accounts & DSRA",
      path: "/executive/escrow",
      icon: Briefcase,
      color: "#0284c7",
      badge: "Escrow DSRA"
    },
    {
      title: "Executive Alert Center",
      desc: "High-priority budget, license & safety triggers",
      path: "/executive/alerts",
      icon: AlertTriangle,
      color: "#dc2626",
      badge: `${kpis?.activeAlertsCount || 0} Priority Alerts`
    },
    {
      title: "Project & CapEx Analytics",
      desc: "Engineering milestones, telemetry & burn rate",
      path: "/executive/capex-analytics",
      icon: Gauge,
      color: "#d97706",
      badge: "Analytics"
    }
  ];

  return (
    <div>
      {/* Header & Controls */}
      <div className="exec-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="exec-subtitle" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Comprehensive C-suite cockpit aggregating financial execution, project velocity, land utilization, and department-level governance.
        </p>

        <div className="exec-controls" style={{ display: "flex", gap: "12px", alignItems: "center", flexShrink: 0, marginLeft: "auto", flexWrap: "wrap" }}>
          <select
            className="exec-select"
            value={selectedUnit}
            onChange={(e) => setSelectedUnit(e.target.value)}
          >
            <option value="All Operations">All Operations & Sites</option>
            <option value="Plant 1 - Hyderabad East CBG">Plant 1 - Hyderabad East CBG</option>
            <option value="Plant 2 - Medak Agri Hub">Plant 2 - Medak Agri Hub</option>
            <option value="Plant 3 - Nalgonda Biomass Facility">Plant 3 - Nalgonda Facility</option>
          </select>

          <select
            className="exec-select"
            value={selectedPeriod}
            onChange={(e) => setSelectedPeriod(e.target.value)}
          >
            <option value="FY 2026-27 (YTD)">FY 2026-27 (YTD)</option>
            <option value="Q3 (Oct - Dec 2026)">Q3 (Oct - Dec 2026)</option>
            <option value="Q2 (Jul - Sep 2026)">Q2 (Jul - Sep 2026)</option>
            <option value="Annual Forecast 2027">Annual Forecast 2027</option>
          </select>

          <button className="exec-btn-print" onClick={handlePrint}>
            <Printer size={15} />
            Export Executive PDF
          </button>
        </div>
      </div>

      {/* Strategic Highlights Banner */}
      <div className="exec-hero-banner">
        <div className="exec-hero-left">
          <h2>
            <Flame size={22} color="#38bdf8" />
            BioNova Clean Energy & Agritech Holdings
          </h2>
          <p>
            Real-time executive cockpit tracking enterprise financial execution, expansion milestones, agricultural feedstock land utilization, and statutory governance.
          </p>
        </div>

        <div className="exec-hero-stats">
          <div className="exec-stat-item">
            <div className="exec-stat-num">₹{totalCapex} Cr</div>
            <div className="exec-stat-label">Capital Portfolio</div>
          </div>
          <div className="exec-stat-item">
            <div className="exec-stat-num">{totalCapex > 0 ? "24.5%" : "--"}</div>
            <div className="exec-stat-label">Projected IRR / ROI</div>
          </div>
          <div className="exec-stat-item">
            <div className="exec-stat-num">{totalAcres > 0 ? `${totalAcres.toLocaleString()} Ac` : "--"}</div>
            <div className="exec-stat-label">Total Land Holding</div>
          </div>
        </div>
      </div>

      {/* Quick Navigation to 8 Submodules */}
      <div style={{ marginBottom: "28px" }}>
        <div style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: "14px"
        }}>
          <div>
            <h3 style={{ fontSize: "16px", fontWeight: "700", color: "#0f172a", margin: 0 }}>
              Executive Submodule Portals
            </h3>
            <p style={{ fontSize: "13px", color: "#64748b", margin: "2px 0 0 0" }}>
              Direct access into deep-dive ledgers, telemetry monitors, and compliance registries
            </p>
          </div>
        </div>

        <div style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))",
          gap: "14px"
        }}>
          {quickNavModules.map((mod, idx) => {
            const ModIcon = mod.icon;
            return (
              <div
                key={idx}
                onClick={() => navigate(mod.path)}
                style={{
                  backgroundColor: "#ffffff",
                  borderRadius: "12px",
                  padding: "16px",
                  border: "1px solid #e2e8f0",
                  cursor: "pointer",
                  transition: "all 0.2s ease",
                  display: "flex",
                  flexDirection: "column",
                  justifyContent: "space-between",
                  boxShadow: "0 1px 3px rgba(0, 0, 0, 0.05)"
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.borderColor = mod.color;
                  e.currentTarget.style.transform = "translateY(-2px)";
                  e.currentTarget.style.boxShadow = "0 8px 16px -4px rgba(0,0,0,0.08)";
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.borderColor = "#e2e8f0";
                  e.currentTarget.style.transform = "none";
                  e.currentTarget.style.boxShadow = "0 1px 3px rgba(0,0,0,0.05)";
                }}
              >
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "10px" }}>
                  <div style={{
                    width: "38px",
                    height: "38px",
                    borderRadius: "10px",
                    backgroundColor: `${mod.color}15`,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    color: mod.color
                  }}>
                    <ModIcon size={20} />
                  </div>
                  <span style={{
                    fontSize: "11px",
                    fontWeight: "600",
                    color: mod.color,
                    backgroundColor: `${mod.color}12`,
                    padding: "3px 8px",
                    borderRadius: "6px"
                  }}>
                    {mod.badge}
                  </span>
                </div>

                <div>
                  <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#0f172a", margin: "0 0 4px 0" }}>
                    {mod.title}
                  </h4>
                  <p style={{ fontSize: "12px", color: "#64748b", margin: 0, lineHeight: "1.4" }}>
                    {mod.desc}
                  </p>
                </div>

                <div style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "flex-end",
                  gap: "4px",
                  marginTop: "12px",
                  fontSize: "12px",
                  fontWeight: "600",
                  color: mod.color
                }}>
                  Launch Portal <ArrowRight size={14} />
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* 4 Core Pillars Grid */}
      <div className="exec-sections-grid">
        {/* PILLAR 1: FINANCIAL HEALTH & BUDGET VARIANCE */}
        <div className="exec-card">
          <div className="exec-card-header">
            <div className="exec-card-title">
              <DollarSign size={20} color="#1677ff" />
              <h3>Financial Execution & Budget Adherence</h3>
            </div>
            <span className="exec-tag exec-tag-green">Healthy Runway</span>
          </div>

          <div className="exec-fin-metrics">
            <div className="exec-fin-tile">
              <div className="exec-fin-tile-label">Capex Allocated</div>
              <div className="exec-fin-tile-val">₹{totalCapex} Cr</div>
              <div className="exec-fin-tile-sub" style={{ color: "#059669" }}>
                <ArrowDownRight size={14} /> ₹{capexIncurred} Cr Incurred ({capexProgress}%)
              </div>
            </div>

            <div className="exec-fin-tile">
              <div className="exec-fin-tile-label">Annualized Opex</div>
              <div className="exec-fin-tile-val">₹{totalOpex} Cr</div>
              <div className="exec-fin-tile-sub" style={{ color: "#2563eb" }}>
                <Activity size={14} /> ₹{opexIncurred} Cr Burn Rate ({opexProgress}%)
              </div>
            </div>

            <div className="exec-fin-tile">
              <div className="exec-fin-tile-label">Annual Revenue Run-Rate</div>
              <div className="exec-fin-tile-val">
                ₹{((kpis?.totalRevenueInr || 0) / 10000000).toFixed(1)} Cr/yr
              </div>
              <div className="exec-fin-tile-sub" style={{ color: "#059669" }}>
                <ArrowUpRight size={14} /> Live Invoiced Revenue
              </div>
            </div>

            <div className="exec-fin-tile">
              <div className="exec-fin-tile-label">EBITDA Margin Index</div>
              <div className="exec-fin-tile-val">--</div>
              <div className="exec-fin-tile-sub" style={{ color: "#64748b" }}>
                Audited at FY Close
              </div>
            </div>
          </div>

          <div className="exec-bar-group">
            <div className="exec-bar-labels">
              <span>Capex Deployment ({capexProgress}%)</span>
              <span>₹{capexIncurred} / ₹{totalCapex} Cr</span>
            </div>
            <div className="exec-bar-track">
              <div className="exec-bar-fill" style={{ width: `${capexProgress}%`, backgroundColor: "#10b981" }} />
            </div>
          </div>

          <div className="exec-bar-group">
            <div className="exec-bar-labels">
              <span>Opex Adherence ({opexProgress}%)</span>
              <span>₹{opexIncurred} / ₹{totalOpex} Cr</span>
            </div>
            <div className="exec-bar-track">
              <div className="exec-bar-fill" style={{ width: `${opexProgress}%`, backgroundColor: "#3b82f6" }} />
            </div>
          </div>
        </div>

        {/* PILLAR 2: PROJECT VELOCITY & MILESTONE ACHIEVEMENT */}
        <div className="exec-card">
          <div className="exec-card-header">
            <div className="exec-card-title">
              <Gauge size={20} color="#1677ff" />
              <h3>Project Velocity & Execution Velocity</h3>
            </div>
            <span className="exec-tag exec-tag-blue">
              {kpis?.activeProjectsCount ? `${kpis.activeProjectsCount} Active Plants` : "0 Active Plants"}
            </span>
          </div>

          {kpis?.activeProjectsCount > 0 ? (
            <div className="exec-bar-group">
              <div className="exec-bar-labels">
                <span>Active Capital Projects In Execution</span>
                <span style={{ color: "#059669" }}>{kpis.activeProjectsCount} Projects Active</span>
              </div>
              <div className="exec-bar-track">
                <div className="exec-bar-fill" style={{ width: "100%", backgroundColor: "#10b981" }} />
              </div>
            </div>
          ) : (
            <div style={{ textAlign: "center", padding: "28px 10px", color: "#64748b", fontSize: "13px" }}>
              No active expansion projects registered. Create projects in the Expansion Pipeline to track engineering velocity.
            </div>
          )}

          <div className="exec-velocity-kpis">
            <div className="exec-velocity-box">
              <div className="exec-velocity-num" style={{ color: "#10b981" }}>0</div>
              <div className="exec-velocity-lbl">Completed Milestones</div>
            </div>
            <div className="exec-velocity-box">
              <div className="exec-velocity-num" style={{ color: "#3b82f6" }}>{kpis?.activeProjectsCount || 0}</div>
              <div className="exec-velocity-lbl">Active In-Progress</div>
            </div>
            <div className="exec-velocity-box">
              <div className="exec-velocity-num" style={{ color: "#64748b" }}>0</div>
              <div className="exec-velocity-lbl">Critical Blockers</div>
            </div>
          </div>
        </div>

        {/* PILLAR 3: LAND UTILIZATION & AGRONOMIC YIELD */}
        <div className="exec-card">
          <div className="exec-card-header">
            <div className="exec-card-title">
              <MapPin size={20} color="#059669" />
              <h3>Farmland Asset Utilization</h3>
            </div>
            <span className="exec-tag exec-tag-amber">
              {totalAcres > 0 ? "Active Yield" : "0 Acres Registered"}
            </span>
          </div>

          <div className="exec-land-breakdown">
            <div className="exec-land-tile" style={{ borderLeftColor: "#10b981" }}>
              <div style={{ fontSize: "12px", color: "#64748b", fontWeight: 600 }}>CULTIVATED BIOMASS</div>
              <div style={{ fontSize: "20px", fontWeight: "800", color: "#0f172a", marginTop: "4px" }}>
                {cultivatedAcres.toLocaleString()} Acres
              </div>
              <div style={{ fontSize: "12px", color: "#059669", marginTop: "2px" }}>
                Registered Crops
              </div>
            </div>

            <div className="exec-land-tile" style={{ borderLeftColor: "#3b82f6" }}>
              <div style={{ fontSize: "12px", color: "#64748b", fontWeight: 600 }}>PLANT INFRASTRUCTURE</div>
              <div style={{ fontSize: "20px", fontWeight: "800", color: "#0f172a", marginTop: "4px" }}>
                {infraAcres.toLocaleString()} Acres
              </div>
              <div style={{ fontSize: "12px", color: "#2563eb", marginTop: "2px" }}>
                Processing & Digester Footprint
              </div>
            </div>

            <div className="exec-land-tile" style={{ borderLeftColor: "#f59e0b" }}>
              <div style={{ fontSize: "12px", color: "#64748b", fontWeight: 600 }}>UNDER PREPARATION</div>
              <div style={{ fontSize: "20px", fontWeight: "800", color: "#0f172a", marginTop: "4px" }}>
                {prepAcres.toLocaleString()} Acres
              </div>
              <div style={{ fontSize: "12px", color: "#d97706", marginTop: "2px" }}>
                Land Preparation
              </div>
            </div>

            <div className="exec-land-tile" style={{ borderLeftColor: "#7c3aed" }}>
              <div style={{ fontSize: "12px", color: "#64748b", fontWeight: 600 }}>BIOMASS YIELD EFFICIENCY</div>
              <div style={{ fontSize: "20px", fontWeight: "800", color: "#0f172a", marginTop: "4px" }}>
                --
              </div>
              <div style={{ fontSize: "12px", color: "#7c3aed", marginTop: "2px" }}>
                Awaiting Harvest Data
              </div>
            </div>
          </div>

          <div style={{ background: "#f8fafc", padding: "12px 16px", borderRadius: "8px", fontSize: "13px", color: "#334155" }}>
            <strong>Agronomy Note:</strong> Soil moisture sensors and feedstock telemetry log real-time agricultural data once land parcels and feedstock cycles are configured.
          </div>
        </div>

        {/* PILLAR 4: DEPARTMENT GOVERNANCE & HEADCOUNT */}
        <div className="exec-card">
          <div className="exec-card-header">
            <div className="exec-card-title">
              <Users size={20} color="#7c3aed" />
              <h3>Department Operational Summaries</h3>
            </div>
            <span className="exec-tag exec-tag-purple">
              {kpis?.totalCompliances > 0 ? "100% Governance" : "-- Governance"}
            </span>
          </div>

          <table className="exec-dept-table">
            <thead>
              <tr>
                <th>Department</th>
                <th>Headcount</th>
                <th>Active Tasks</th>
                <th>SLA %</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
      <tr>
        <td colSpan="5" style={{ textAlign: "center", padding: "24px", color: "#64748b" }}>
          No departmental incident escalations or active compliance variances reported.
        </td>
      </tr>
    </tbody>
          </table>
        </div>

        {/* STRATEGIC RISK RADAR & DECISIONS */}
        <div className="exec-risks-card">
          <div className="exec-card-header">
            <div className="exec-card-title">
              <ShieldCheck size={20} color="#dc2626" />
              <h3>Strategic Risk Radar & Executive Action Items</h3>
            </div>
            <span style={{ fontSize: "12px", color: "#64748b" }}>C-Suite Quarterly Governance Review</span>
          </div>

          <div className="exec-risks-grid">
      <div className="exec-risk-tile low" style={{ gridColumn: "1 / -1", textAlign: "center", padding: "20px" }}>
        <div style={{ color: "#059669", fontWeight: "700", fontSize: "14px" }}>
          ✓ All Operational & Statutory Risk Indicators are Clear
        </div>
        <div style={{ fontSize: "12px", color: "#64748b", marginTop: "6px" }}>
          Live telemetry and environmental compliance monitors show zero active breaches across facilities.
        </div>
      </div>
    </div>
  </div>
</div>
</div>
);
};

export default ExecutiveCockpitOverview;

