import React, { useState, useEffect } from "react";
import {
  Car,
  Search,
  Plus,
  ShieldCheck,
  CheckCircle2,
  AlertTriangle,
  Clock,
  LogOut,
  Truck,
  Building,
  X,
  ArrowLeft,
  Save
} from "lucide-react";
import {
  STORAGE_KEYS,
  INITIAL_VEHICLES,
  getStoredData,
  saveStoredData
} from "./visitorData";

const VehicleManagement = ({ onNavigate }) => {
  const [vehicles, setVehicles] = useState(() =>
    getStoredData(STORAGE_KEYS.VEHICLES, INITIAL_VEHICLES)
  );

  useEffect(() => {
    const handleUpdate = () => {
      setVehicles(getStoredData(STORAGE_KEYS.VEHICLES, INITIAL_VEHICLES));
    };
    window.addEventListener("bionova_visitor_updated", handleUpdate);
    return () => window.removeEventListener("bionova_visitor_updated", handleUpdate);
  }, []);

  const [searchTerm, setSearchTerm] = useState("");
  const [filterType, setFilterType] = useState("All");
  const [isModalOpen, setIsModalOpen] = useState(false);

  const [formData, setFormData] = useState({
    vehicleNo: "",
    type: "Heavy Commercial Tipper",
    driverName: "",
    phone: "",
    licenseNo: "",
    purpose: "",
    consignmentWeight: "",
    sparkArrestorVerified: true,
    gateInTime: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
    parkingBay: "",
    weighbridgeSlipNo: ""
  });

  const handleCreateVehicle = (e) => {
    e.preventDefault();
    if (!formData.vehicleNo.trim() || !formData.driverName.trim()) return;

    const newRec = {
      id: Date.now(),
      ...formData,
      status: "Inside Plant",
      gateOutTime: null
    };

    const updated = [newRec, ...vehicles];
    setVehicles(updated);
    saveStoredData(STORAGE_KEYS.VEHICLES, updated);
    setIsModalOpen(false);
  };

  const handleMarkExit = (id) => {
    const outTime = new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    const updated = vehicles.map((v) => (v.id === id ? { ...v, status: "Exited", gateOutTime: outTime } : v));
    setVehicles(updated);
    saveStoredData(STORAGE_KEYS.VEHICLES, updated);
  };

  const filtered = vehicles.filter((v) => {
    const matchSearch =
      v.vehicleNo.toLowerCase().includes(searchTerm.toLowerCase()) ||
      v.driverName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      v.purpose.toLowerCase().includes(searchTerm.toLowerCase());
    const matchType = filterType === "All" || (filterType === "Inside" ? v.status === "Inside Plant" : v.status === "Exited");
    return matchSearch && matchType;
  });

  const insideCount = vehicles.filter((v) => v.status === "Inside Plant").length;

  return (
    <div className="vm-submodule-container">
      {/* Header */}
      <div className="vm-section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="vm-section-desc" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Monitor feedstock trailers, CBG cascade carriers, visitor sedans, spark arrestor compliance, and parking bays.
        </p>
        <button onClick={() => setIsModalOpen(true)} className="vm-btn-primary text-xs" style={{ flexShrink: 0, marginLeft: "auto" }}>
          <Plus size={16} /> Register Vehicle Entry
        </button>
      </div>

      {/* If isModalOpen is true, render Full-Page Form Card. Otherwise, render KPIs and Table */}
      {isModalOpen ? (
        <div style={{
          backgroundColor: "#ffffff",
          borderRadius: "14px",
          border: "1px solid #e2e8f0",
          boxShadow: "0 1px 3px rgba(0, 0, 0, 0.05)",
          overflow: "hidden",
          marginTop: "10px"
        }}>
          {/* Form Header with Back Button */}
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
                <Truck size={22} color="#7c3aed" />
                Register Vehicle Gate Entry
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Monitor feedstock trailers, CBG cascade carriers, visitor sedans, spark arrestor compliance, and parking bays.
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
              <ArrowLeft size={16} /> Back to Vehicle Management
            </button>
          </div>

          {/* Form Body */}
          <form onSubmit={handleCreateVehicle} style={{ padding: "28px" }}>
            <div style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))",
              gap: "20px",
              marginBottom: "24px"
            }}>
              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Vehicle Plate Registration No *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.vehicleNo}
                  onChange={(e) => setFormData({ ...formData, vehicleNo: e.target.value })}
                  placeholder="e.g. TS 08 UB 7712"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Vehicle Category
                </label>
                <select
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.type}
                  onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                >
                  <option value="Heavy Commercial Tipper">Heavy Commercial Tipper</option>
                  <option value="CBG Cascade Transport Trailer">CBG Cascade Transport Trailer</option>
                  <option value="Maintenance Van / SUV">Maintenance Van / SUV</option>
                  <option value="Official Passenger Car">Official Passenger Car</option>
                </select>
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Driver Full Name *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.driverName}
                  onChange={(e) => setFormData({ ...formData, driverName: e.target.value })}
                  placeholder="e.g. Ramesh Kumar"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Driver License Number
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.licenseNo}
                  onChange={(e) => setFormData({ ...formData, licenseNo: e.target.value })}
                  placeholder="e.g. DL: TS092015099812"
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Assigned Parking Bay
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.parkingBay}
                  onChange={(e) => setFormData({ ...formData, parkingBay: e.target.value })}
                  placeholder="e.g. Bay-4 (Feedstock Yard)"
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Weighbridge Gross Slip No
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.weighbridgeSlipNo}
                  onChange={(e) => setFormData({ ...formData, weighbridgeSlipNo: e.target.value })}
                  placeholder="e.g. WB-2026-10492"
                />
              </div>

              <div style={{ gridColumn: "1 / -1" }}>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Purpose of Vehicle Movement
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.purpose}
                  onChange={(e) => setFormData({ ...formData, purpose: e.target.value })}
                  placeholder="e.g. Biomass Pressmud Delivery / Gas Bottle Dispatch"
                />
              </div>
            </div>

            {/* Spark Arrestor Verification */}
            <div style={{
              padding: "16px 20px",
              backgroundColor: "#f5f3ff",
              border: "1px solid #ddd6fe",
              borderRadius: "10px",
              marginBottom: "24px"
            }}>
              <label style={{ display: "flex", alignItems: "center", gap: "10px", cursor: "pointer", fontSize: "13.5px", fontWeight: "600", color: "#5b21b6" }}>
                <input
                  type="checkbox"
                  checked={formData.sparkArrestorVerified}
                  onChange={(e) => setFormData({ ...formData, sparkArrestorVerified: e.target.checked })}
                />
                <span>Exhaust Spark Arrestor Device physically inspected and certified for explosive ATEX zone</span>
              </label>
            </div>

            {/* Bottom Form Actions */}
            <div style={{
              display: "flex",
              justifyContent: "flex-end",
              alignItems: "center",
              gap: "12px",
              paddingTop: "20px",
              borderTop: "1px solid #e2e8f0"
            }}>
              <button
                type="button"
                onClick={() => setIsModalOpen(false)}
                style={{
                  padding: "10px 20px",
                  borderRadius: "8px",
                  border: "1px solid #cbd5e1",
                  backgroundColor: "#ffffff",
                  color: "#475569",
                  fontWeight: "600",
                  cursor: "pointer",
                  fontSize: "13.5px"
                }}
              >
                Cancel
              </button>
              <button
                type="submit"
                style={{
                  padding: "10px 24px",
                  borderRadius: "8px",
                  border: "none",
                  backgroundColor: "#7c3aed",
                  color: "#ffffff",
                  fontWeight: "600",
                  cursor: "pointer",
                  fontSize: "13.5px",
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "8px",
                  boxShadow: "0 2px 6px rgba(124, 58, 237, 0.3)"
                }}
              >
                <Save size={16} />
                Authorize Vehicle Entry
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* KPI Cards */}
          <div className="vm-kpi-grid">
        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#f3e8ff", color: "#7c3aed" }}>
            <Car size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Vehicles Inside Plant</h3>
            <span className="vm-kpi-value text-purple-700">{insideCount}</span>
          </div>
        </div>

        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#d1fae5", color: "#059669" }}>
            <ShieldCheck size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Spark Arrestor Tested</h3>
            <span className="vm-kpi-value text-emerald-600">
              {vehicles.length > 0
                ? `${Math.round((vehicles.filter((v) => v.sparkArrestorVerified).length / vehicles.length) * 100)}%`
                : "--"}
            </span>
          </div>
        </div>

        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#e0e7ff", color: "#3730a3" }}>
            <Truck size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Total Vehicle Movements</h3>
            <span className="vm-kpi-value">{vehicles.length}</span>
          </div>
        </div>
      </div>

      {/* Search & Filter */}
      <div className="vm-controls-card mb-4">
        <div className="d-flex justify-content-between align-items-center flex-wrap gap-2">
          <input
            type="text"
            placeholder="Search vehicle plate number, driver, or purpose..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="vm-input-text flex-1"
            style={{ maxWidth: "380px" }}
          />
          <div className="d-flex gap-2">
            {["All", "Inside", "Exited"].map((tab) => (
              <button
                key={tab}
                onClick={() => setFilterType(tab)}
                className={`vm-filter-pill ${filterType === tab ? "active" : ""}`}
              >
                {tab === "Inside" ? `Inside (${insideCount})` : tab}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="vm-table-card">
        <div className="vm-table-responsive">
          <table className="vm-data-table">
            <thead>
              <tr>
                <th>Vehicle Plate No</th>
                <th>Type & Category</th>
                <th>Driver & Contact</th>
                <th>Purpose & Cargo</th>
                <th>Bay & Weighbridge</th>
                <th>Spark Arrestor</th>
                <th>Timings</th>
                <th>Status</th>
                <th style={{ textAlign: "right" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan="9" className="text-center py-6 text-slate-500">
                    <div className="d-flex flex-column align-items-center justify-content-center py-4">
                      <Truck size={36} className="text-slate-300 mb-2" />
                      <div className="font-semibold text-slate-700">No vehicles currently registered or inside plant</div>
                      <p className="text-xs text-slate-400 mt-1 mb-0">Click "Register Vehicle Entry" above to log a vehicle.</p>
                    </div>
                  </td>
                </tr>
              ) : (
                filtered.map((v) => (
                <tr key={v.id}>
                  <td>
                    <span className="font-mono font-bold text-slate-900 text-sm">{v.vehicleNo}</span>
                  </td>
                  <td>
                    <span className="text-xs font-semibold text-slate-700">{v.type}</span>
                  </td>
                  <td>
                    <div className="text-xs font-bold text-slate-800">{v.driverName}</div>
                    <div className="text-xs text-slate-500 font-mono">{v.licenseNo}</div>
                  </td>
                  <td>
                    <div className="text-xs font-medium text-slate-900">{v.purpose}</div>
                    <div className="text-xs text-slate-500">{v.consignmentWeight}</div>
                  </td>
                  <td>
                    <div className="text-xs font-semibold text-indigo-700">{v.parkingBay}</div>
                    <div className="text-xs text-slate-400 font-mono">{v.weighbridgeSlipNo || "N/A"}</div>
                  </td>
                  <td>
                    {v.sparkArrestorVerified ? (
                      <span className="vm-status-badge badge-cleared">
                        <CheckCircle2 size={11} /> Fitted & Passed
                      </span>
                    ) : (
                      <span className="vm-status-badge badge-danger">
                        <AlertTriangle size={11} /> Missing
                      </span>
                    )}
                  </td>
                  <td>
                    <div className="text-xs font-mono">
                      In: <span className="font-semibold text-slate-800">{v.gateInTime}</span>
                    </div>
                    {v.gateOutTime && (
                      <div className="text-xs font-mono text-slate-500">
                        Out: <span className="font-semibold text-emerald-700">{v.gateOutTime}</span>
                      </div>
                    )}
                  </td>
                  <td>
                    <span
                      className={`vm-status-badge ${
                        v.status === "Inside Plant" ? "badge-active" : "badge-closed"
                      }`}
                    >
                      {v.status}
                    </span>
                  </td>
                  <td style={{ textAlign: "right" }}>
                    {v.status === "Inside Plant" && (
                      <button
                        onClick={() => handleMarkExit(v.id)}
                        className="vm-btn-secondary text-xs"
                        style={{ padding: "4px 8px", color: "#d97706" }}
                        title="Mark Gate Out"
                      >
                        <LogOut size={13} /> Exit
                      </button>
                    )}
                  </td>
                </tr>
              )))}
            </tbody>
          </table>
        </div>
      </div>
        </>
      )}
    </div>
  );
};

export default VehicleManagement;

