import React, { useState, useEffect } from "react";
import {
  ShieldAlert,
  ShieldCheck,
  Lock,
  Unlock,
  Building,
  Flame,
  AlertTriangle,
  UserCheck,
  CheckCircle2,
  Search,
  Filter
} from "lucide-react";
import {
  STORAGE_KEYS,
  INITIAL_ZONES,
  INITIAL_VISITORS,
  getStoredData,
  saveStoredData
} from "./visitorData";

const VisitorAccessManagement = ({ onNavigate }) => {
  const [zones] = useState(INITIAL_ZONES);
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
  const [selectedZone, setSelectedZone] = useState("All");

  const toggleZonePermission = (visitorId, zoneName) => {
    const updated = visitors.map((v) => {
      if (v.id === visitorId) {
        const currentZones = v.assignedZones || [];
        const exists = currentZones.includes(zoneName);
        return {
          ...v,
          assignedZones: exists
            ? currentZones.filter((z) => z !== zoneName)
            : [...currentZones, zoneName]
        };
      }
      return v;
    });

    setVisitors(updated);
    saveStoredData(STORAGE_KEYS.VISITORS, updated);
  };

  const filteredVisitors = visitors.filter((v) => {
    const matchSearch =
      v.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      v.organization.toLowerCase().includes(searchTerm.toLowerCase()) ||
      v.passNo.toLowerCase().includes(searchTerm.toLowerCase());
    const matchZone =
      selectedZone === "All" || (v.assignedZones && v.assignedZones.includes(selectedZone));
    return matchSearch && matchZone;
  });

  return (
    <div className="vm-submodule-container">
      {/* Header */}
      <div className="vm-section-header" style={{ marginBottom: "20px" }}>
        <p className="vm-section-desc" style={{ margin: 0, color: "#64748b", fontSize: "14px" }}>
          Define, enforce, and dynamically modify perimeter zone permissions across ATEX explosive and general plant sectors.
        </p>
      </div>

      {/* Zone Overview Cards */}
      <div className="row g-3 mb-4">
        {zones.map((z) => {
          const authorizedCount = visitors.filter(
            (v) => v.assignedZones && v.assignedZones.includes(z.name)
          ).length;
          return (
            <div key={z.id} className="col-12 col-md-6 col-lg-4">
              <div
                className="vm-card p-3 h-100"
                style={{ borderLeft: `4px solid ${z.color}` }}
              >
                <div className="d-flex justify-content-between align-items-start mb-1.5">
                  <span className="font-mono text-xs font-bold text-slate-500">{z.code}</span>
                  <span
                    className="text-xs font-bold px-2 py-0.5 rounded"
                    style={{ backgroundColor: `${z.color}15`, color: z.color }}
                  >
                    {z.riskLevel}
                  </span>
                </div>
                <h4 className="font-bold text-slate-900 text-sm mb-1">{z.name}</h4>
                <p className="text-xs text-slate-600 mb-2">{z.description}</p>
                <div className="d-flex justify-content-between align-items-center text-xs pt-2 border-t border-slate-100">
                  <span className="text-slate-500">Authorized Personnel:</span>
                  <span className="font-bold text-slate-900">{authorizedCount} Active</span>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Search & Filter */}
      <div className="vm-controls-card mb-4">
        <div className="d-flex justify-content-between align-items-center flex-wrap gap-2">
          <input
            type="text"
            placeholder="Search visitor name or organization..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="vm-input-text flex-1"
            style={{ maxWidth: "380px" }}
          />
          <div className="d-flex align-items-center gap-2">
            <span className="text-xs font-bold text-slate-600">Filter By Zone:</span>
            <select
              value={selectedZone}
              onChange={(e) => setSelectedZone(e.target.value)}
              className="vm-select-sm"
            >
              <option value="All">All Security Zones</option>
              {zones.map((z) => (
                <option key={z.id} value={z.name}>
                  {z.name}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Matrix Table */}
      <div className="vm-table-card">
        <div className="vm-table-responsive">
          <table className="vm-data-table">
            <thead>
              <tr>
                <th>Visitor & Pass</th>
                <th>Category</th>
                <th style={{ textAlign: "center" }}>Admin Lobby</th>
                <th style={{ textAlign: "center" }}>Weighbridge</th>
                <th style={{ textAlign: "center" }}>Digesters</th>
                <th style={{ textAlign: "center" }}>Gas ATEX Unit</th>
                <th style={{ textAlign: "center" }}>Cascade Bay</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {filteredVisitors.length === 0 ? (
                <tr>
                  <td colSpan="8" className="text-center py-6 text-slate-500">
                    <div className="d-flex flex-column align-items-center justify-content-center py-4">
                      <ShieldCheck size={36} className="text-slate-300 mb-2" />
                      <div className="font-semibold text-slate-700">No active visitor zone access records</div>
                      <p className="text-xs text-slate-400 mt-1 mb-0">Authorized zone access permissions will appear once visitors are checked in.</p>
                    </div>
                  </td>
                </tr>
              ) : (
                filteredVisitors.map((v) => (
                <tr key={v.id}>
                  <td>
                    <div className="font-bold text-slate-900 text-xs">{v.name}</div>
                    <div className="font-mono text-xs text-blue-600 font-semibold">{v.passNo}</div>
                    <div className="text-xs text-slate-500">{v.organization}</div>
                  </td>
                  <td>
                    <span className="vm-badge-category text-xs">{v.visitorType}</span>
                  </td>
                  <td style={{ textAlign: "center" }}>
                    <button
                      onClick={() => toggleZonePermission(v.id, "Admin Building")}
                      className={`vm-zone-matrix-btn ${
                        v.assignedZones?.includes("Admin Building") ? "granted" : "denied"
                      }`}
                    >
                      {v.assignedZones?.includes("Admin Building") ? "Granted" : "Restricted"}
                    </button>
                  </td>
                  <td style={{ textAlign: "center" }}>
                    <button
                      onClick={() => toggleZonePermission(v.id, "Weighbridge")}
                      className={`vm-zone-matrix-btn ${
                        v.assignedZones?.includes("Weighbridge") ? "granted" : "denied"
                      }`}
                    >
                      {v.assignedZones?.includes("Weighbridge") ? "Granted" : "Restricted"}
                    </button>
                  </td>
                  <td style={{ textAlign: "center" }}>
                    <button
                      onClick={() => toggleZonePermission(v.id, "Anaerobic Digesters")}
                      className={`vm-zone-matrix-btn ${
                        v.assignedZones?.includes("Anaerobic Digesters") ? "granted" : "denied"
                      }`}
                    >
                      {v.assignedZones?.includes("Anaerobic Digesters") ? "Granted" : "Restricted"}
                    </button>
                  </td>
                  <td style={{ textAlign: "center" }}>
                    <button
                      onClick={() => toggleZonePermission(v.id, "Gas Purification Unit")}
                      className={`vm-zone-matrix-btn ${
                        v.assignedZones?.includes("Gas Purification Unit") ||
                        v.assignedZones?.includes("Gas Compression")
                          ? "granted"
                          : "denied"
                      }`}
                    >
                      {v.assignedZones?.includes("Gas Purification Unit") ||
                      v.assignedZones?.includes("Gas Compression")
                        ? "Granted"
                        : "Restricted"}
                    </button>
                  </td>
                  <td style={{ textAlign: "center" }}>
                    <button
                      onClick={() => toggleZonePermission(v.id, "Cascade Filling Bay")}
                      className={`vm-zone-matrix-btn ${
                        v.assignedZones?.includes("Cascade Filling Bay") ? "granted" : "denied"
                      }`}
                    >
                      {v.assignedZones?.includes("Cascade Filling Bay") ? "Granted" : "Restricted"}
                    </button>
                  </td>
                  <td>
                    <span
                      className={`vm-status-badge ${
                        v.status === "Checked-In" ? "badge-active" : "badge-closed"
                      }`}
                    >
                      {v.status}
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

export default VisitorAccessManagement;

