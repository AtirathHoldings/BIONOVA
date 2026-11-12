import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import {
  Users,
  UserCheck,
  UserX,
  Clock,
  ShieldCheck,
  AlertTriangle,
  FileBadge,
  Plus,
  ArrowRight,
  Search,
  CheckCircle2,
  Car,
  HardHat,
  Flame,
  Building,
  RefreshCw,
  LogOut,
  Sparkles,
  QrCode
} from "lucide-react";
import {
  STORAGE_KEYS,
  INITIAL_VISITORS,
  getStoredData,
  saveStoredData
} from "./visitorData";

const VisitorDashboard = ({ onNavigate }) => {
  const navigate = useNavigate();
  const [visitors, setVisitors] = useState(() =>
    getStoredData(STORAGE_KEYS.VISITORS, INITIAL_VISITORS)
  );
  const [filterType, setFilterType] = useState("All");

  const refreshData = () => {
    setVisitors(getStoredData(STORAGE_KEYS.VISITORS, INITIAL_VISITORS));
  };

  useEffect(() => {
    refreshData();
    const handleUpdate = () => refreshData();
    window.addEventListener("bionova_visitor_updated", handleUpdate);
    return () => window.removeEventListener("bionova_visitor_updated", handleUpdate);
  }, []);

  // KPIs
  const liveCount = visitors.filter((v) => v.status === "Checked-In").length;
  const totalToday = visitors.length;
  const pendingApprovals = visitors.filter((v) => v.status === "Pending Approval").length;
  const checkedOutCount = visitors.filter((v) => v.status === "Checked-Out").length;
  const overdueCount = visitors.filter((v) => v.isOverdue || (v.status === "Checked-In" && v.overdueMinutes > 0)).length;
  const safetyClearanceCount = visitors.filter((v) => v.safetyDisclaimerSigned && v.ppeIssued).length;

  const filteredVisitors = visitors.filter((v) => {
    if (filterType === "All") return true;
    if (filterType === "Inside") return v.status === "Checked-In";
    if (filterType === "Pending") return v.status === "Pending Approval";
    if (filterType === "CheckedOut") return v.status === "Checked-Out";
    return true;
  });

  return (
    <div className="vm-submodule-container">
      {/* Top Banner Alert if Overdue visitors exist */}
      {overdueCount > 0 && (
        <div className="vm-alert-banner alert-warning mb-4">
          <div className="d-flex align-items-center gap-3">
            <div className="vm-alert-icon-box">
              <AlertTriangle size={20} className="text-amber-500" />
            </div>
            <div>
              <h4 className="m-0 font-bold text-amber-900" style={{ fontSize: "14px" }}>
                Active Overdue Alert: {overdueCount} Visitor(s) Exceeded Authorized Pass Duration
              </h4>
              <p className="m-0 text-amber-700 text-xs mt-0.5">
                Immediate security action recommended. Check the Overdue Visitor Tracking terminal to alert plant security hosts.
              </p>
            </div>
          </div>
          <button
            onClick={() => onNavigate("overdue-tracking")}
            className="vm-btn-secondary text-xs font-semibold"
            style={{ padding: "6px 14px", borderColor: "#f59e0b", color: "#b45309" }}
          >
            Review Overdue Visitors →
          </button>
        </div>
      )}

      {/* Header & Quick Action Buttons */}
      <div className="vm-section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="vm-section-desc" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Real-time perimeter telemetry, active gate passes, hazardous zone clearances, and security roll call.
        </p>
        <div className="d-flex align-items-center gap-2" style={{ flexShrink: 0, marginLeft: "auto" }}>
          <button
            onClick={refreshData}
            className="vm-btn-secondary text-xs"
            title="Refresh Live Data"
          >
            <RefreshCw size={14} /> Refresh
          </button>
          <button
            onClick={() => onNavigate("gate-checkin")}
            className="vm-btn-secondary text-xs font-semibold"
            style={{ borderColor: "#10b981", color: "#047857" }}
          >
            <UserCheck size={14} /> Quick Check-In
          </button>
          <button
            onClick={() => onNavigate("registration")}
            className="vm-btn-primary text-xs"
          >
            <Plus size={16} /> New Visitor Pass
          </button>
        </div>
      </div>

      {/* KPI Cards Grid */}
      <div className="vm-kpi-grid">
        <div className="vm-kpi-card" onClick={() => onNavigate("live-tracking")} style={{ cursor: "pointer" }}>
          <div className="vm-kpi-icon" style={{ backgroundColor: "#dbeafe", color: "#2563eb" }}>
            <Users size={24} />
          </div>
          <div className="vm-kpi-info">
            <h3>Currently Inside Plant</h3>
            <div className="d-flex align-items-baseline gap-2">
              <span className="vm-kpi-value text-blue-600">{liveCount}</span>
              <span className="text-xs font-semibold text-emerald-600">● Live Active</span>
            </div>
          </div>
        </div>

        <div className="vm-kpi-card" onClick={() => onNavigate("list")} style={{ cursor: "pointer" }}>
          <div className="vm-kpi-icon" style={{ backgroundColor: "#e0e7ff", color: "#4f46e5" }}>
            <FileBadge size={24} />
          </div>
          <div className="vm-kpi-info">
            <h3>Total Passes Today</h3>
            <div className="d-flex align-items-baseline gap-2">
              <span className="vm-kpi-value text-slate-800">{totalToday}</span>
              <span className="text-xs text-slate-500">Issued Passes</span>
            </div>
          </div>
        </div>

        <div className="vm-kpi-card" onClick={() => onNavigate("approvals")} style={{ cursor: "pointer" }}>
          <div className="vm-kpi-icon" style={{ backgroundColor: "#fef3c7", color: "#d97706" }}>
            <Clock size={24} />
          </div>
          <div className="vm-kpi-info">
            <h3>Pending Approvals</h3>
            <div className="d-flex align-items-baseline gap-2">
              <span className="vm-kpi-value text-amber-600">{pendingApprovals}</span>
              <span className="text-xs text-amber-700 font-semibold">Requires Sign-off</span>
            </div>
          </div>
        </div>

        <div className="vm-kpi-card" onClick={() => onNavigate("overdue-tracking")} style={{ cursor: "pointer" }}>
          <div className="vm-kpi-icon" style={{ backgroundColor: overdueCount > 0 ? "#fee2e2" : "#f1f5f9", color: overdueCount > 0 ? "#dc2626" : "#64748b" }}>
            <AlertTriangle size={24} />
          </div>
          <div className="vm-kpi-info">
            <h3>Overdue Pass Duration</h3>
            <div className="d-flex align-items-baseline gap-2">
              <span className={`vm-kpi-value ${overdueCount > 0 ? "text-red-600 font-black" : "text-slate-600"}`}>
                {overdueCount}
              </span>
              <span className="text-xs text-slate-500">Exceeded Time</span>
            </div>
          </div>
        </div>

        <div className="vm-kpi-card" onClick={() => onNavigate("safety-clearance")} style={{ cursor: "pointer" }}>
          <div className="vm-kpi-icon" style={{ backgroundColor: "#d1fae5", color: "#059669" }}>
            <HardHat size={24} />
          </div>
          <div className="vm-kpi-info">
            <h3>Safety & PPE Inducted</h3>
            <div className="d-flex align-items-baseline gap-2">
              <span className="vm-kpi-value text-emerald-600">{safetyClearanceCount}</span>
              <span className="text-xs text-emerald-700 font-semibold">HSE Verified</span>
            </div>
          </div>
        </div>

        <div className="vm-kpi-card" onClick={() => onNavigate("security-vehicles")} style={{ cursor: "pointer" }}>
          <div className="vm-kpi-icon" style={{ backgroundColor: "#f3e8ff", color: "#7c3aed" }}>
            <Car size={24} />
          </div>
          <div className="vm-kpi-info">
            <h3>Active Vehicles Inside</h3>
            <div className="d-flex align-items-baseline gap-2">
              <span className="vm-kpi-value text-purple-700">
                {getStoredData(STORAGE_KEYS.VEHICLES, []).filter((v) => v.status === "Inside Plant" || v.status === "Inside").length}
              </span>
              <span className="text-xs text-purple-600">Spark Arrested</span>
            </div>
          </div>
        </div>
      </div>

      {/* Feature Navigation Tiles */}
      <div className="vm-features-banner mb-4">
        <div className="vm-feature-tile" onClick={() => onNavigate("registration")}>
          <div className="vm-feature-icon bg-blue-50 text-blue-600">
            <Plus size={20} />
          </div>
          <div>
            <div className="vm-feature-name">Register Visitor</div>
            <div className="vm-feature-desc">Issue Gate Pass & Govt ID check</div>
          </div>
        </div>

        <div className="vm-feature-tile" onClick={() => onNavigate("gate-checkin")}>
          <div className="vm-feature-icon bg-emerald-50 text-emerald-600">
            <UserCheck size={20} />
          </div>
          <div>
            <div className="vm-feature-name">Gate Check-In</div>
            <div className="vm-feature-desc">RFID Badge & PPE checklist</div>
          </div>
        </div>

        <div className="vm-feature-tile" onClick={() => onNavigate("gate-checkout")}>
          <div className="vm-feature-icon bg-slate-100 text-slate-700">
            <LogOut size={20} />
          </div>
          <div>
            <div className="vm-feature-name">Gate Check-Out</div>
            <div className="vm-feature-desc">Dwell time audit & pass close</div>
          </div>
        </div>

        <div className="vm-feature-tile" onClick={() => onNavigate("gate-pass")}>
          <div className="vm-feature-icon bg-indigo-50 text-indigo-600">
            <FileBadge size={20} />
          </div>
          <div>
            <div className="vm-feature-name">Digital Gate Passes</div>
            <div className="vm-feature-desc">Print & barcode visual badge</div>
          </div>
        </div>

        <div className="vm-feature-tile" onClick={() => onNavigate("qr-verification")}>
          <div className="vm-feature-icon bg-cyan-50 text-cyan-600">
            <QrCode size={20} />
          </div>
          <div>
            <div className="vm-feature-name d-flex align-items-center gap-1.5">
              QR Verification
              <span className="badge-soon">Coming Soon</span>
            </div>
            <div className="vm-feature-desc">Smart turnstile auto-scan</div>
          </div>
        </div>
      </div>

      {/* Today's Live Visitors Table */}
      <div className="vm-table-card">
        <div className="vm-table-header-row">
          <div>
            <h3 className="vm-table-title">Today's Live Plant Visitor Roster</h3>
            <p className="vm-table-subtitle">Real-time status of personnel entering plant perimeter</p>
          </div>
          <div className="d-flex align-items-center gap-2">
            <div className="vm-filter-pill-group">
              <button
                className={`vm-filter-pill ${filterType === "All" ? "active" : ""}`}
                onClick={() => setFilterType("All")}
              >
                All ({visitors.length})
              </button>
              <button
                className={`vm-filter-pill ${filterType === "Inside" ? "active" : ""}`}
                onClick={() => setFilterType("Inside")}
              >
                Inside Plant ({liveCount})
              </button>
              <button
                className={`vm-filter-pill ${filterType === "Pending" ? "active" : ""}`}
                onClick={() => setFilterType("Pending")}
              >
                Pending ({pendingApprovals})
              </button>
              <button
                className={`vm-filter-pill ${filterType === "CheckedOut" ? "active" : ""}`}
                onClick={() => setFilterType("CheckedOut")}
              >
                Checked Out ({checkedOutCount})
              </button>
            </div>
            <button
              onClick={() => onNavigate("list")}
              className="vm-btn-secondary text-xs"
            >
              View Full Directory <ArrowRight size={14} />
            </button>
          </div>
        </div>

        <div className="vm-table-responsive">
          <table className="vm-data-table">
            <thead>
              <tr>
                <th>Pass No & Visitor</th>
                <th>Organization</th>
                <th>Category</th>
                <th>Host & Department</th>
                <th>In / Out Timings</th>
                <th>Safety & PPE</th>
                <th>Status</th>
                <th style={{ textAlign: "right" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredVisitors.length === 0 ? (
                <tr>
                  <td colSpan="8" className="text-center py-6 text-slate-500">
                    <div className="d-flex flex-column align-items-center justify-content-center py-4">
                      <Users size={36} className="text-slate-300 mb-2" />
                      <div className="font-semibold text-slate-700">No visitors logged today</div>
                      <p className="text-xs text-slate-400 mt-1 mb-0">Use "New Visitor Pass" above to register and check in visitors.</p>
                    </div>
                  </td>
                </tr>
              ) : (
                filteredVisitors.map((v) => (
                <tr key={v.id}>
                  <td>
                    <div className="d-flex align-items-center gap-2.5">
                      <div className="vm-avatar-initials">
                        {v.name.split(" ").map((n) => n[0]).slice(0, 2).join("")}
                      </div>
                      <div>
                        <div className="font-bold text-slate-900" style={{ fontSize: "13.5px" }}>
                          {v.name}
                        </div>
                        <div className="text-xs text-blue-600 font-mono font-medium">
                          {v.passNo}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div className="text-xs font-semibold text-slate-800">{v.organization}</div>
                    <div className="text-xs text-slate-500">{v.phone}</div>
                  </td>
                  <td>
                    <span className="vm-badge-category">{v.visitorType}</span>
                  </td>
                  <td>
                    <div className="text-xs font-medium text-slate-900">{v.hostEmployee}</div>
                    <div className="text-xs text-slate-500">{v.department || v.plantLocation}</div>
                  </td>
                  <td>
                    <div className="text-xs font-mono">
                      <span className="text-slate-500">In:</span>{" "}
                      <span className="font-semibold text-slate-800">{v.actualInTime || v.expectedInTime}</span>
                    </div>
                    {v.actualOutTime ? (
                      <div className="text-xs font-mono text-slate-500">
                        Out: <span className="font-semibold text-emerald-700">{v.actualOutTime}</span>
                      </div>
                    ) : (
                      <div className="text-xs font-mono text-slate-400">
                        Exp. Out: {v.expectedOutTime || "N/A"}
                      </div>
                    )}
                  </td>
                  <td>
                    {v.ppeIssued ? (
                      <span className="vm-status-badge badge-cleared">
                        <CheckCircle2 size={12} /> HSE Cleared
                      </span>
                    ) : (
                      <span className="vm-status-badge badge-warning">
                        Pending PPE
                      </span>
                    )}
                  </td>
                  <td>
                    <span
                      className={`vm-status-badge ${
                        v.status === "Checked-In"
                          ? "badge-active"
                          : v.status === "Pending Approval"
                          ? "badge-pending"
                          : "badge-closed"
                      }`}
                    >
                      {v.status}
                    </span>
                    {v.isOverdue && (
                      <span className="vm-overdue-chip">Overdue</span>
                    )}
                  </td>
                  <td style={{ textAlign: "right" }}>
                    <button
                      onClick={() => onNavigate("gate-pass")}
                      className="vm-action-btn"
                      title="View Gate Pass"
                    >
                      <FileBadge size={15} />
                    </button>
                    {v.status === "Checked-In" && (
                      <button
                        onClick={() => onNavigate("gate-checkout")}
                        className="vm-action-btn text-amber-600"
                        title="Check-Out"
                      >
                        <LogOut size={15} />
                      </button>
                    )}
                    {v.status === "Pending Approval" && (
                      <button
                        onClick={() => onNavigate("approvals")}
                        className="vm-action-btn text-emerald-600"
                        title="Review Approval"
                      >
                        <CheckCircle2 size={15} />
                      </button>
                    )}
                  </td>
                </tr>
              )))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default VisitorDashboard;

