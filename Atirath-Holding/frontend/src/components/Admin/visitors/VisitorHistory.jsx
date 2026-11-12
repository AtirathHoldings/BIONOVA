import React, { useState, useEffect } from "react";
import {
  Clock,
  Calendar,
  Search,
  Download,
  FileText,
  UserCheck,
  Building,
  CheckCircle2,
  Filter
} from "lucide-react";
import {
  STORAGE_KEYS,
  INITIAL_VISITORS,
  getStoredData
} from "./visitorData";

const VisitorHistory = ({ onNavigate }) => {
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

  const [searchTerm, setSearchTerm] = useState("");
  const [dateFilter, setDateFilter] = useState("All");

  const completedVisits = visitors.filter((v) => v.status === "Checked-Out" || v.actualOutTime);

  const exportHistoryCSV = () => {
    const headers = [
      "Pass No",
      "Visitor Name",
      "Organization",
      "Category",
      "Host Employee",
      "Check-In Time",
      "Check-Out Time",
      "Govt ID",
      "Vehicle Plate",
      "Remarks"
    ];
    const rows = completedVisits.map((v) => [
      v.passNo,
      `"${v.name}"`,
      `"${v.organization}"`,
      `"${v.visitorType}"`,
      `"${v.hostEmployee}"`,
      v.actualInTime || v.expectedInTime,
      v.actualOutTime || "12:00 PM",
      `"${v.govtId}"`,
      v.vehicleNo || "N/A",
      `"${v.remarks || 'Standard exit'}"`
    ]);

    const csvContent =
      "data:text/csv;charset=utf-8," +
      [headers.join(","), ...rows.map((e) => e.join(","))].join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `bionova_visitor_history_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const filtered = completedVisits.filter(
    (v) =>
      v.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      v.passNo.toLowerCase().includes(searchTerm.toLowerCase()) ||
      v.organization.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="vm-submodule-container">
      {/* Header */}
      <div className="vm-section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="vm-section-desc" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Historical logs of all perimeter visits, dwell times, host engagements, and security sign-offs.
        </p>
        <button onClick={exportHistoryCSV} className="vm-btn-secondary text-xs" style={{ flexShrink: 0, marginLeft: "auto" }}>
          <Download size={15} /> Export Historical Audit Log
        </button>
      </div>

      {/* KPI Cards */}
      <div className="vm-kpi-grid">
        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#e0e7ff", color: "#4338ca" }}>
            <FileText size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Completed Visits Archived</h3>
            <span className="vm-kpi-value text-indigo-700">{completedVisits.length}</span>
          </div>
        </div>

        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#d1fae5", color: "#059669" }}>
            <Clock size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Average Dwell Duration</h3>
            <span className="vm-kpi-value text-emerald-600">
              {completedVisits.length > 0 ? "2h 45m" : "--"}
            </span>
          </div>
        </div>

        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#dbeafe", color: "#2563eb" }}>
            <CheckCircle2 size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Exit Clearance Adherence</h3>
            <span className="vm-kpi-value text-blue-700">
              {completedVisits.length > 0 ? "100%" : "--"}
            </span>
          </div>
        </div>
      </div>

      {/* Search Toolbar */}
      <div className="vm-controls-card mb-4">
        <input
          type="text"
          placeholder="Search historical visitor archive by name, pass number, or organization..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="vm-input-text w-100"
        />
      </div>

      {/* Table */}
      <div className="vm-table-card">
        <div className="vm-table-responsive">
          <table className="vm-data-table">
            <thead>
              <tr>
                <th>Pass Number</th>
                <th>Visitor & Organization</th>
                <th>Category</th>
                <th>Host & Department</th>
                <th>Check-In Time</th>
                <th>Check-Out Time</th>
                <th>Total Dwell Time</th>
                <th>Govt ID Verification</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan="8" className="text-center py-6 text-slate-500">
                    <div className="d-flex flex-column align-items-center justify-content-center py-4">
                      <Clock size={36} className="text-slate-300 mb-2" />
                      <div className="font-semibold text-slate-700">No archived visitor history</div>
                      <p className="text-xs text-slate-400 mt-1 mb-0">Completed visitor logs will be archived here once visitors check out.</p>
                    </div>
                  </td>
                </tr>
              ) : (
                filtered.map((v) => (
                  <tr key={v.id}>
                    <td>
                      <span className="font-mono font-bold text-blue-700 text-xs">{v.passNo}</span>
                    </td>
                    <td>
                      <div className="font-bold text-slate-900 text-xs">{v.name}</div>
                      <div className="text-xs text-slate-500">{v.organization}</div>
                    </td>
                    <td>
                      <span className="vm-badge-category text-xs">{v.visitorType}</span>
                    </td>
                    <td>
                      <div className="text-xs font-semibold text-slate-800">{v.hostEmployee}</div>
                      <div className="text-xs text-slate-500">{v.plantLocation}</div>
                    </td>
                    <td>
                      <span className="font-mono text-xs font-semibold text-slate-800">
                        {v.actualInTime || v.expectedInTime}
                      </span>
                    </td>
                    <td>
                      <span className="font-mono text-xs font-semibold text-emerald-700">
                        {v.actualOutTime || "--"}
                      </span>
                    </td>
                    <td>
                      <span className="font-mono text-xs text-slate-700 font-bold">
                        {v.dwellTime || "--"}
                      </span>
                    </td>
                    <td>
                    <span className="font-mono text-xs text-slate-600">{v.govtId}</span>
                  </td>
                  <td>
                    <span className="vm-status-badge badge-closed text-xs">
                      Checked-Out
                    </span>
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

export default VisitorHistory;

