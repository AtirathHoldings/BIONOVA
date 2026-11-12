import React, { useState, useEffect } from "react";
import {
  Users,
  Clock,
  ShieldCheck,
  AlertTriangle,
  LogOut,
  Phone,
  Flame,
  Printer,
  Radio,
  Building,
  RefreshCw,
  ArrowLeft
} from "lucide-react";
import {
  STORAGE_KEYS,
  INITIAL_VISITORS,
  getStoredData,
  saveStoredData
} from "./visitorData";

const LiveInsideTracking = ({ onNavigate }) => {
  const [visitors, setVisitors] = useState(() =>
    getStoredData(STORAGE_KEYS.VISITORS, INITIAL_VISITORS)
  );

  const [isEvacuationModalOpen, setIsEvacuationModalOpen] = useState(false);

  const refreshList = () => {
    setVisitors(getStoredData(STORAGE_KEYS.VISITORS, INITIAL_VISITORS));
  };

  useEffect(() => {
    refreshList();
    const interval = setInterval(refreshList, 15000); // 15s live polling
    return () => clearInterval(interval);
  }, []);

  const insideVisitors = visitors.filter((v) => v.status === "Checked-In");

  const handleQuickCheckOut = (id) => {
    const outTime = new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    const updated = visitors.map((v) =>
      v.id === id ? { ...v, status: "Checked-Out", actualOutTime: outTime, isOverdue: false } : v
    );
    setVisitors(updated);
    saveStoredData(STORAGE_KEYS.VISITORS, updated);
  };

  return (
    <div className="vm-submodule-container">
      {/* Header */}
      <div className="vm-section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="vm-section-desc" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Continuous real-time tracking of active visitor badges, zone occupancy, and duration timers inside the facility.
        </p>
        <div className="d-flex align-items-center gap-2" style={{ flexShrink: 0, marginLeft: "auto" }}>
          <button
            onClick={() => setIsEvacuationModalOpen(true)}
            className="vm-btn-secondary text-xs"
            style={{ borderColor: "#ef4444", color: "#dc2626", fontWeight: "700" }}
          >
            <Flame size={15} /> Emergency Evacuation Muster List
          </button>
          <button onClick={refreshList} className="vm-btn-secondary text-xs">
            <RefreshCw size={14} /> Refresh
          </button>
        </div>
      </div>

      {/* If isEvacuationModalOpen is true, render Full-Page Muster Card. Otherwise, render Live Tracking */}
      {isEvacuationModalOpen ? (
        <div style={{
          backgroundColor: "#ffffff",
          borderRadius: "14px",
          border: "1px solid #e2e8f0",
          boxShadow: "0 1px 3px rgba(0, 0, 0, 0.05)",
          overflow: "hidden",
          marginTop: "10px"
        }}>
          {/* Header with Back Button */}
          <div style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            padding: "20px 28px",
            borderBottom: "1px solid #e2e8f0",
            backgroundColor: "#fef2f2"
          }}>
            <div>
              <h2 style={{ fontSize: "20px", fontWeight: "700", color: "#991b1b", margin: 0, display: "flex", alignItems: "center", gap: "10px" }}>
                <Flame size={22} color="#dc2626" />
                EMERGENCY EVACUATION MUSTER ROLL
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#b91c1c" }}>
                Critical head count roster of all active personnel inside plant perimeter for roll call verification at Assembly Point A.
              </p>
            </div>
            <button
              type="button"
              onClick={() => setIsEvacuationModalOpen(false)}
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: "8px",
                padding: "8px 16px",
                borderRadius: "8px",
                border: "1px solid #cbd5e1",
                backgroundColor: "#ffffff",
                color: "#475569",
                fontSize: "13px",
                fontWeight: "600",
                cursor: "pointer",
                transition: "all 0.2s ease"
              }}
            >
              <ArrowLeft size={16} /> Back to Live Tracking
            </button>
          </div>

          <div style={{ padding: "28px" }}>
            <div style={{
              padding: "16px 20px",
              backgroundColor: "#fee2e2",
              border: "1px solid #f87171",
              borderRadius: "8px",
              marginBottom: "20px",
              fontSize: "13.5px",
              color: "#7f1d1d"
            }}>
              <strong>CRITICAL SAFETY DIRECTIVE:</strong> This list accounts for all external personnel officially inside plant premises at this timestamp. Assemble at <strong>Assembly Point-A (Main Security Gate)</strong> and perform immediate physical roll call.
            </div>

            <div className="vm-table-responsive">
              <table className="vm-data-table">
                <thead>
                  <tr>
                    <th>Pass No</th>
                    <th>Visitor Name</th>
                    <th>Phone</th>
                    <th>Host Contact</th>
                    <th>Last Known Zone</th>
                  </tr>
                </thead>
                <tbody>
                  {insideVisitors.map((v) => (
                    <tr key={v.id}>
                      <td className="font-mono font-bold text-xs">{v.passNo}</td>
                      <td className="font-bold text-xs">{v.name} ({v.organization})</td>
                      <td className="font-mono text-xs">{v.phone}</td>
                      <td className="text-xs">{v.hostEmployee}</td>
                      <td className="text-xs font-semibold text-slate-700">
                        {(v.assignedZones || ["Admin Building"]).join(", ")}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div style={{
              display: "flex",
              justifyContent: "flex-end",
              alignItems: "center",
              gap: "12px",
              paddingTop: "20px",
              marginTop: "20px",
              borderTop: "1px solid #e2e8f0"
            }}>
              <button
                type="button"
                onClick={() => window.print()}
                className="vm-btn-primary text-xs"
                style={{ backgroundColor: "#dc2626" }}
              >
                <Printer size={15} /> Print Emergency Roll Call
              </button>
              <button
                type="button"
                onClick={() => setIsEvacuationModalOpen(false)}
                className="vm-btn-secondary text-xs"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      ) : (
        <>
          {/* Live Counter Cards */}
          <div className="vm-kpi-grid">
        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#d1fae5", color: "#059669" }}>
            <Users size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Currently On-Site</h3>
            <div className="d-flex align-items-baseline gap-2">
              <span className="vm-kpi-value text-emerald-600">{insideVisitors.length}</span>
              <span className="text-xs font-bold text-emerald-700">● Live Persons</span>
            </div>
          </div>
        </div>

        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#dbeafe", color: "#2563eb" }}>
            <ShieldCheck size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Under Active Escort</h3>
            <span className="vm-kpi-value text-blue-700">
              {insideVisitors.filter((v) => v.escortRequired).length}
            </span>
          </div>
        </div>

        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#fee2e2", color: "#dc2626" }}>
            <AlertTriangle size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Overstay / Overdue Duration</h3>
            <span className="vm-kpi-value text-red-600">
              {insideVisitors.filter((v) => v.isOverdue || v.overdueMinutes > 0).length}
            </span>
          </div>
        </div>
      </div>

      {/* Live Roster Table */}
      <div className="vm-table-card">
        <div className="vm-table-responsive">
          <table className="vm-data-table">
            <thead>
              <tr>
                <th>Visitor & Pass</th>
                <th>Organization</th>
                <th>RFID Smart Badge</th>
                <th>Check-In Time</th>
                <th>Host & Department</th>
                <th>Active Zone Access</th>
                <th>Escort Status</th>
                <th style={{ textAlign: "right" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {insideVisitors.length === 0 ? (
                <tr>
                  <td colSpan="8" className="text-center py-5 text-slate-500">
                    No visitors are currently inside the plant perimeter.
                  </td>
                </tr>
              ) : (
                insideVisitors.map((v) => (
                  <tr key={v.id}>
                    <td>
                      <div className="font-bold text-slate-900 text-xs">{v.name}</div>
                      <div className="font-mono text-xs text-blue-600 font-semibold">{v.passNo}</div>
                      <div className="text-xs text-slate-500">{v.phone}</div>
                    </td>
                    <td>
                      <div className="text-xs font-semibold text-slate-800">{v.organization}</div>
                      <div className="text-xs text-blue-600 font-medium">{v.visitorType}</div>
                    </td>
                    <td>
                      <span className="font-mono font-bold text-indigo-700 bg-indigo-50 px-2 py-0.5 rounded text-xs">
                        {v.badgeRfid || "No RFID"}
                      </span>
                    </td>
                    <td>
                      <div className="font-mono font-bold text-slate-800 text-xs">
                        {v.actualInTime || v.expectedInTime}
                      </div>
                      <div className="text-xs text-slate-500">
                        Exp. Out: {v.expectedOutTime}
                      </div>
                    </td>
                    <td>
                      <div className="text-xs font-semibold text-slate-900">{v.hostEmployee}</div>
                      <div className="text-xs text-slate-500">{v.department || v.plantLocation}</div>
                    </td>
                    <td>
                      <div className="d-flex flex-wrap gap-1">
                        {(v.assignedZones || ["Admin Building"]).map((z, i) => (
                          <span key={i} className="vm-zone-tag">{z}</span>
                        ))}
                      </div>
                    </td>
                    <td>
                      {v.escortRequired ? (
                        <span className="vm-status-badge badge-warning text-xs">
                          Escort: {v.escortName || "Assigned"}
                        </span>
                      ) : (
                        <span className="text-xs text-slate-500">Self Guided</span>
                      )}
                    </td>
                    <td style={{ textAlign: "right" }}>
                      <button
                        onClick={() => handleQuickCheckOut(v.id)}
                        className="vm-btn-secondary text-xs"
                        style={{ padding: "5px 10px", color: "#d97706" }}
                        title="Quick Check-Out"
                      >
                        <LogOut size={13} /> Exit
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
        </>
      )}
    </div>
  );
};

export default LiveInsideTracking;

