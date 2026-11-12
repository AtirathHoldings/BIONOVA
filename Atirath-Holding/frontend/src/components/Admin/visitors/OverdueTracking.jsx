import React, { useState, useEffect } from "react";
import {
  AlertTriangle,
  Clock,
  Bell,
  Phone,
  ShieldAlert,
  LogOut,
  CheckCircle2,
  UserCheck,
  Send
} from "lucide-react";
import {
  STORAGE_KEYS,
  INITIAL_VISITORS,
  getStoredData,
  saveStoredData
} from "./visitorData";

const OverdueTracking = ({ onNavigate }) => {
  const [visitors, setVisitors] = useState(() =>
    getStoredData(STORAGE_KEYS.VISITORS, INITIAL_VISITORS)
  );

  useEffect(() => {
    const handleUpdate = () => {
      setVisitors(getStoredData(STORAGE_KEYS.VISITORS, INITIAL_VISITORS));
    };
    window.addEventListener("bionova_visitor_updated", handleUpdate);
    return () => window.removeEventListener("bionova_visitor_updated", handleUpdate);
  }, []);

  const [alertSuccess, setAlertSuccess] = useState("");

  const overdueList = visitors.filter(
    (v) => (v.isOverdue || v.overdueMinutes > 0) && v.status === "Checked-In"
  );

  const handleTriggerHostAlert = (visitor) => {
    setAlertSuccess(
      `Automated SMS & System Alert dispatched to host: ${visitor.hostEmployee} regarding visitor ${visitor.name}.`
    );
    setTimeout(() => setAlertSuccess(""), 5000);
  };

  const handleForceCheckout = (id) => {
    const outTime = new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    const updated = visitors.map((v) =>
      v.id === id
        ? {
            ...v,
            status: "Checked-Out",
            actualOutTime: outTime,
            isOverdue: false,
            overdueMinutes: 0,
            remarks: "Checked out after security overdue notification"
          }
        : v
    );

    setVisitors(updated);
    saveStoredData(STORAGE_KEYS.VISITORS, updated);
  };

  return (
    <div className="vm-submodule-container">
      {/* Header */}
      <div className="vm-section-header" style={{ marginBottom: "20px" }}>
        <p className="vm-section-desc" style={{ margin: 0, color: "#64748b", fontSize: "14px" }}>
          Monitor and escalate personnel who have exceeded their authorized pass duration within the plant perimeter.
        </p>
      </div>

      {alertSuccess && (
        <div className="vm-alert-banner alert-success mb-4">
          <CheckCircle2 size={18} className="text-emerald-600" />
          <span className="text-xs font-semibold text-emerald-800">{alertSuccess}</span>
        </div>
      )}

      {/* Critical Alert Warning */}
      <div className="vm-alert-banner alert-warning mb-4" style={{ backgroundColor: "#fef2f2", borderColor: "#fca5a5" }}>
        <div className="d-flex align-items-center gap-3">
          <ShieldAlert size={24} className="text-red-600 flex-shrink-0" />
          <div>
            <h4 className="m-0 font-bold text-red-900" style={{ fontSize: "14px" }}>
              Active Overstay Security Directives
            </h4>
            <p className="m-0 text-red-800 text-xs mt-0.5">
              Any visitor exceeding pass limits by over 30 minutes triggers automated security patrol dispatch. Ensure host employee confirms visitor location immediately.
            </p>
          </div>
        </div>
      </div>

      {/* Overdue Table */}
      <div className="vm-table-card">
        <div className="vm-table-header-row">
          <div>
            <h3 className="vm-table-title">Overdue Visitors In Plant ({overdueList.length})</h3>
            <p className="vm-table-subtitle">Personnel past their approved check-out threshold</p>
          </div>
        </div>

        <div className="vm-table-responsive">
          <table className="vm-data-table">
            <thead>
              <tr>
                <th>Pass & Visitor</th>
                <th>Organization</th>
                <th>Check-In Time</th>
                <th>Expected Out</th>
                <th>Overdue Duration</th>
                <th>Host Employee</th>
                <th>Last Assigned Zone</th>
                <th style={{ textAlign: "right" }}>Security Actions</th>
              </tr>
            </thead>
            <tbody>
              {overdueList.length === 0 ? (
                <tr>
                  <td colSpan="8" className="text-center py-5 text-slate-500">
                    <CheckCircle2 size={32} className="text-emerald-500 mb-2 mx-auto" />
                    <div className="font-bold text-slate-800">Zero Overdue Visitors</div>
                    <div className="text-xs text-slate-500">All visitors are operating strictly within their approved timelines.</div>
                  </td>
                </tr>
              ) : (
                overdueList.map((v) => (
                  <tr key={v.id}>
                    <td>
                      <div className="font-bold text-slate-900 text-xs">{v.name}</div>
                      <div className="font-mono text-xs text-red-600 font-bold">{v.passNo}</div>
                      <div className="text-xs text-slate-500">{v.phone}</div>
                    </td>
                    <td>
                      <div className="text-xs font-semibold text-slate-800">{v.organization}</div>
                      <div className="text-xs text-blue-600">{v.visitorType}</div>
                    </td>
                    <td>
                      <span className="font-mono text-xs font-semibold text-slate-800">
                        {v.actualInTime || v.expectedInTime}
                      </span>
                    </td>
                    <td>
                      <span className="font-mono text-xs font-semibold text-slate-500">
                        {v.expectedOutTime}
                      </span>
                    </td>
                    <td>
                      <span className="text-xs font-bold font-mono text-red-700 bg-red-100 px-2 py-0.5 rounded border border-red-300">
                        + {v.overdueMinutes || 0} Minutes Overdue
                      </span>
                    </td>
                    <td>
                      <div className="text-xs font-bold text-slate-900">{v.hostEmployee}</div>
                      <div className="text-xs text-slate-500">{v.department}</div>
                    </td>
                    <td>
                      <div className="text-xs text-slate-700 font-medium">
                        {(v.assignedZones || ["Admin Building"]).join(", ")}
                      </div>
                    </td>
                    <td style={{ textAlign: "right" }}>
                      <div className="d-flex justify-content-end gap-1">
                        <button
                          onClick={() => handleTriggerHostAlert(v)}
                          className="vm-btn-secondary text-xs"
                          style={{ padding: "5px 10px", borderColor: "#f59e0b", color: "#b45309" }}
                          title="Alert Host"
                        >
                          <Bell size={13} /> Alert Host
                        </button>
                        <button
                          onClick={() => handleForceCheckout(v.id)}
                          className="vm-btn-secondary text-xs"
                          style={{ padding: "5px 10px", color: "#dc2626" }}
                          title="Force Check-Out"
                        >
                          <LogOut size={13} /> Exit
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default OverdueTracking;

