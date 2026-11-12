import React, { useState, useEffect } from "react";
import {
  Search,
  Filter,
  Download,
  Printer,
  Eye,
  CheckCircle2,
  XCircle,
  LogOut,
  FileBadge,
  UserCheck,
  Building,
  HardHat,
  Phone,
  Car,
  AlertTriangle,
  X,
  ArrowLeft
} from "lucide-react";
import {
  STORAGE_KEYS,
  INITIAL_VISITORS,
  getStoredData,
  saveStoredData,
  apiUpdateVisitorRecord
} from "./visitorData";

const VisitorList = ({ onNavigate }) => {
  const [visitors, setVisitors] = useState(() =>
    getStoredData(STORAGE_KEYS.VISITORS, INITIAL_VISITORS)
  );

  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("All");
  const [categoryFilter, setCategoryFilter] = useState("All");
  const [plantFilter, setPlantFilter] = useState("All");

  const [selectedVisitor, setSelectedVisitor] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  useEffect(() => {
    setVisitors(getStoredData(STORAGE_KEYS.VISITORS, INITIAL_VISITORS));
    const handleUpdate = (e) => {
      if (e.detail?.key === STORAGE_KEYS.VISITORS && Array.isArray(e.detail.data)) {
        setVisitors(e.detail.data);
      }
    };
    window.addEventListener("bionova_visitor_updated", handleUpdate);
    return () => window.removeEventListener("bionova_visitor_updated", handleUpdate);
  }, []);

  const handleStatusChange = (id, newStatus) => {
    let target = null;
    const updated = visitors.map((v) => {
      if (v.id === id) {
        const now = new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
        target = {
          ...v,
          status: newStatus,
          actualInTime: newStatus === "Checked-In" ? (v.actualInTime || now) : v.actualInTime,
          actualOutTime: newStatus === "Checked-Out" ? now : v.actualOutTime
        };
        return target;
      }
      return v;
    });
    setVisitors(updated);
    saveStoredData(STORAGE_KEYS.VISITORS, updated);
    if (target) {
      apiUpdateVisitorRecord(id, target).catch(() => {});
    }
  };

  const filteredVisitors = visitors.filter((v) => {
    const matchSearch =
      v.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      v.passNo.toLowerCase().includes(searchTerm.toLowerCase()) ||
      v.organization.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (v.phone && v.phone.includes(searchTerm)) ||
      (v.vehicleNo && v.vehicleNo.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchStatus =
      statusFilter === "All" ||
      v.status === statusFilter ||
      (statusFilter === "Overdue" && (v.isOverdue || v.overdueMinutes > 0));

    const matchCategory = categoryFilter === "All" || v.visitorType === categoryFilter;
    const matchPlant = plantFilter === "All" || v.plantLocation.includes(plantFilter);

    return matchSearch && matchStatus && matchCategory && matchPlant;
  });

  const exportToCSV = () => {
    const headers = [
      "Pass No",
      "Visitor Name",
      "Phone",
      "Organization",
      "Category",
      "Host",
      "Status",
      "In Time",
      "Out Time",
      "Vehicle No"
    ];
    const rows = filteredVisitors.map((v) => [
      v.passNo,
      `"${v.name}"`,
      v.phone,
      `"${v.organization}"`,
      `"${v.visitorType}"`,
      `"${v.hostEmployee}"`,
      v.status,
      v.actualInTime || v.expectedInTime,
      v.actualOutTime || "N/A",
      v.vehicleNo || "N/A"
    ]);

    const csvContent =
      "data:text/csv;charset=utf-8," +
      [headers.join(","), ...rows.map((e) => e.join(","))].join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `bionova_visitors_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="vm-submodule-container">
      {/* Header */}
      <div className="vm-section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="vm-section-desc" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Search, filter, inspect, and manage perimeter access passes across all plant complexes.
        </p>
        <div className="d-flex align-items-center gap-2" style={{ flexShrink: 0, marginLeft: "auto" }}>
          <button onClick={exportToCSV} className="vm-btn-secondary text-xs">
            <Download size={15} /> Export CSV
          </button>
          <button onClick={() => onNavigate("registration")} className="vm-btn-primary text-xs">
            + New Visitor Pass
          </button>
        </div>
      </div>

      {/* If isModalOpen and selectedVisitor is true, render Full-Page Pass Card. Otherwise, render Directory & Filters */}
      {isModalOpen && selectedVisitor ? (
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
            backgroundColor: "#fafbfc"
          }}>
            <div>
              <h2 style={{ fontSize: "20px", fontWeight: "700", color: "#0f172a", margin: 0, display: "flex", alignItems: "center", gap: "10px" }}>
                <FileBadge size={22} color="#2563eb" />
                Perimeter Gate Pass: {selectedVisitor.name}
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Official plant perimeter gate pass, safety induction status, and zone authorizations.
              </p>
            </div>
            <button
              type="button"
              onClick={() => setIsModalOpen(false)}
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
              <ArrowLeft size={16} /> Back to Visitor Directory
            </button>
          </div>

          {/* Pass Card Preview Body */}
          <div style={{ padding: "28px", display: "flex", justifyContent: "center" }}>
            <div className="vm-gatepass-card" style={{ maxWidth: "600px", width: "100%", boxShadow: "0 4px 12px rgba(0,0,0,0.08)", borderRadius: "12px", border: "1px solid #e2e8f0" }}>
              <div className="vm-pass-header">
                <div>
                  <div className="vm-pass-brand">BIONOVA CLEAN ENERGY</div>
                  <div className="vm-pass-subtitle">VISITOR SECURITY GATE PASS</div>
                </div>
                <div className="vm-pass-badge-pill">{selectedVisitor.status}</div>
              </div>

              <div className="vm-pass-body">
                <div className="d-flex gap-3 mb-3">
                  <div className="vm-pass-photo-box">
                    <div className="vm-pass-initials">
                      {selectedVisitor.name.split(" ").map((n) => n[0]).slice(0, 2).join("")}
                    </div>
                    <div className="vm-pass-rfid">{selectedVisitor.badgeRfid}</div>
                  </div>
                  <div className="flex-1">
                    <div className="vm-pass-name">{selectedVisitor.name}</div>
                    <div className="vm-pass-org">{selectedVisitor.organization}</div>
                    <div className="vm-pass-category">{selectedVisitor.visitorType}</div>
                    <div className="text-xs text-slate-600 mt-1">
                      Govt ID: <span className="font-mono">{selectedVisitor.govtId}</span>
                    </div>
                  </div>
                </div>

                <div className="vm-pass-grid">
                  <div>
                    <span className="label">Pass Number:</span>
                    <span className="val font-mono font-bold text-blue-700">{selectedVisitor.passNo}</span>
                  </div>
                  <div>
                    <span className="label">Host Employee:</span>
                    <span className="val">{selectedVisitor.hostEmployee}</span>
                  </div>
                  <div>
                    <span className="label">Plant Location:</span>
                    <span className="val">{selectedVisitor.plantLocation}</span>
                  </div>
                  <div>
                    <span className="label">Vehicle No:</span>
                    <span className="val font-mono">{selectedVisitor.vehicleNo || "Pedestrian"}</span>
                  </div>
                  <div style={{ gridColumn: "1 / -1" }}>
                    <span className="label">Purpose:</span>
                    <span className="val">{selectedVisitor.purpose}</span>
                  </div>
                  <div style={{ gridColumn: "1 / -1" }}>
                    <span className="label">Authorized Zones:</span>
                    <div className="d-flex flex-wrap gap-1 mt-1">
                      {(selectedVisitor.assignedZones || ["Admin Building"]).map((z, i) => (
                        <span key={i} className="vm-zone-tag">{z}</span>
                      ))}
                    </div>
                  </div>
                </div>

                <div className="vm-pass-footer">
                  <div className="text-xs text-slate-500 font-mono">
                    Issued: {new Date().toLocaleDateString()} | BioNova Safety Protocol Rev. 2.1
                  </div>
                  <div className="vm-barcode-preview">||| | ||||| | ||| |||| | ||||</div>
                </div>
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "12px", padding: "16px 20px", borderTop: "1px solid #e2e8f0", backgroundColor: "#fafbfc" }}>
                <button
                  type="button"
                  onClick={() => window.print()}
                  className="vm-btn-secondary text-xs"
                >
                  <Printer size={15} /> Print Physical Pass
                </button>
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="vm-btn-primary text-xs"
                >
                  Done
                </button>
              </div>
            </div>
          </div>
        </div>
      ) : (
        <>
          {/* Filter and Search Bar */}
          <div className="vm-controls-card mb-4">
        <div className="d-flex flex-wrap gap-3 align-items-center justify-content-between">
          <div className="d-flex flex-1 gap-2" style={{ minWidth: "280px" }}>
            <div className="vm-search-box w-100">
              <Search size={18} className="text-slate-400" />
              <input
                type="text"
                placeholder="Search by visitor name, pass number, phone, company, or vehicle..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
              {searchTerm && (
                <button onClick={() => setSearchTerm("")} className="vm-search-clear">
                  <X size={14} />
                </button>
              )}
            </div>
          </div>

          <div className="d-flex flex-wrap gap-2 align-items-center">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="vm-select-sm"
            >
              <option value="All">All Statuses</option>
              <option value="Checked-In">Checked-In (Inside)</option>
              <option value="Checked-Out">Checked-Out</option>
              <option value="Pending Approval">Pending Approval</option>
              <option value="Overdue">Overdue Duration</option>
            </select>

            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="vm-select-sm"
            >
              <option value="All">All Categories</option>
              <option value="Vendor / Contractor">Vendor / Contractor</option>
              <option value="Statutory / Govt Inspector">Statutory / Govt Inspector</option>
              <option value="Customer / Offtaker">Customer / Offtaker</option>
              <option value="Transporter / Logistics">Transporter / Logistics</option>
            </select>

            <select
              value={plantFilter}
              onChange={(e) => setPlantFilter(e.target.value)}
              className="vm-select-sm"
            >
              <option value="All">All Plant Complexes</option>
              <option value="Plant 1">Plant 1 (Hyderabad East)</option>
              <option value="Plant 2">Plant 2 (Medak Hub)</option>
            </select>
          </div>
        </div>
      </div>

      {/* Visitors Table */}
      <div className="vm-table-card">
        <div className="vm-table-responsive">
          <table className="vm-data-table">
            <thead>
              <tr>
                <th>Pass Number</th>
                <th>Visitor Details</th>
                <th>Company / Org</th>
                <th>Host & Plant</th>
                <th>Timings</th>
                <th>Vehicle & Badge</th>
                <th>Status</th>
                <th style={{ textAlign: "right" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredVisitors.length === 0 ? (
                <tr>
                  <td colSpan="8" className="text-center py-5 text-slate-500">
                    No visitor records found matching your search and filter criteria.
                  </td>
                </tr>
              ) : (
                filteredVisitors.map((v) => (
                  <tr key={v.id}>
                    <td>
                      <span className="font-mono font-bold text-blue-700 text-xs">
                        {v.passNo}
                      </span>
                    </td>
                    <td>
                      <div className="font-bold text-slate-900" style={{ fontSize: "13.5px" }}>
                        {v.name}
                      </div>
                      <div className="text-xs text-slate-500 d-flex align-items-center gap-1">
                        <Phone size={11} /> {v.phone}
                      </div>
                    </td>
                    <td>
                      <div className="text-xs font-semibold text-slate-800">{v.organization}</div>
                      <div className="text-xs text-blue-600 font-medium">{v.visitorType}</div>
                    </td>
                    <td>
                      <div className="text-xs font-medium text-slate-900">{v.hostEmployee}</div>
                      <div className="text-xs text-slate-500">{v.plantLocation}</div>
                    </td>
                    <td>
                      <div className="text-xs font-mono">
                        <span className="text-slate-500">In:</span>{" "}
                        <span className="font-semibold text-slate-800">
                          {v.actualInTime || v.expectedInTime}
                        </span>
                      </div>
                      <div className="text-xs font-mono text-slate-500">
                        Out:{" "}
                        <span className="font-semibold text-emerald-700">
                          {v.actualOutTime || "—"}
                        </span>
                      </div>
                    </td>
                    <td>
                      <div className="text-xs font-mono font-semibold text-slate-700">
                        {v.vehicleNo !== "N/A" ? v.vehicleNo : "Pedestrian"}
                      </div>
                      <div className="text-xs text-slate-500 font-mono">
                        {v.badgeRfid || "No RFID"}
                      </div>
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
                      {v.isOverdue && <span className="vm-overdue-chip">Overdue</span>}
                    </td>
                    <td style={{ textAlign: "right" }}>
                      <div className="d-flex justify-content-end gap-1">
                        <button
                          onClick={() => {
                            setSelectedVisitor(v);
                            setIsModalOpen(true);
                          }}
                          className="vm-action-btn"
                          title="View Digital Pass Badge"
                        >
                          <Eye size={15} />
                        </button>
                        {v.status === "Checked-In" ? (
                          <button
                            onClick={() => handleStatusChange(v.id, "Checked-Out")}
                            className="vm-action-btn text-amber-600"
                            title="Check-Out Visitor"
                          >
                            <LogOut size={15} />
                          </button>
                        ) : v.status === "Checked-Out" ? (
                          <button
                            onClick={() => handleStatusChange(v.id, "Checked-In")}
                            className="vm-action-btn text-emerald-600"
                            title="Re-admit / Check-In"
                          >
                            <UserCheck size={15} />
                          </button>
                        ) : (
                          <button
                            onClick={() => handleStatusChange(v.id, "Checked-In")}
                            className="vm-action-btn text-blue-600"
                            title="Approve & Check-In"
                          >
                            <CheckCircle2 size={15} />
                          </button>
                        )}
                      </div>
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

export default VisitorList;

