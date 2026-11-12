import React, { useState, useEffect } from "react";
import {
  LogOut,
  Plus,
  Search,
  CheckCircle2,
  FileBadge,
  Truck,
  ShieldAlert,
  AlertTriangle,
  X,
  ArrowLeft,
  Save
} from "lucide-react";
import {
  STORAGE_KEYS,
  INITIAL_OUTWARD,
  getStoredData,
  saveStoredData
} from "./visitorData";

const MaterialOutward = ({ onNavigate }) => {
  const [outwardLogs, setOutwardLogs] = useState(() =>
    getStoredData(STORAGE_KEYS.MATERIAL_OUTWARD, INITIAL_OUTWARD)
  );

  useEffect(() => {
    const handleUpdate = () => {
      setOutwardLogs(getStoredData(STORAGE_KEYS.MATERIAL_OUTWARD, INITIAL_OUTWARD));
    };
    window.addEventListener("bionova_visitor_updated", handleUpdate);
    return () => window.removeEventListener("bionova_visitor_updated", handleUpdate);
  }, []);

  const [searchTerm, setSearchTerm] = useState("");
  const [isModalOpen, setIsModalOpen] = useState(false);

  const [formData, setFormData] = useState({
    itemDescription: "",
    quantity: "",
    dispatchChallanNo: "",
    recipient: "",
    vehicleNo: "",
    type: "Non-Returnable (Finished Goods)",
    authorizedBy: "Rajesh Kumar (Plant Operations Head)"
  });

  const handleCreateOutward = (e) => {
    e.preventDefault();
    if (!formData.itemDescription.trim() || !formData.recipient.trim()) return;

    const newRec = {
      id: `MO-2026-${String(outwardLogs.length + 22).padStart(3, "0")}`,
      date: new Date().toISOString().slice(0, 10),
      ...formData,
      gateSignOffTime: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
      status: "Dispatched"
    };

    const updated = [newRec, ...outwardLogs];
    setOutwardLogs(updated);
    saveStoredData(STORAGE_KEYS.MATERIAL_OUTWARD, updated);
    setIsModalOpen(false);
  };

  const filtered = outwardLogs.filter(
    (item) =>
      item.itemDescription.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.recipient.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.dispatchChallanNo.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.id.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="vm-submodule-container">
      {/* Header */}
      <div className="vm-section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="vm-section-desc" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Enforce strict gate pass control for finished CBG cascades, returnable tools, scrap consignments, and laboratory samples.
        </p>
        <button onClick={() => setIsModalOpen(true)} className="vm-btn-primary text-xs" style={{ flexShrink: 0, marginLeft: "auto" }}>
          <Plus size={16} /> Issue Outward Gate Pass
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
                <LogOut size={22} color="#d97706" />
                Generate Material Outward Gate Pass
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Enforce gate pass control for finished CBG cascades, returnable tools, scrap consignments, and laboratory samples.
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
              <ArrowLeft size={16} /> Back to Material Outward
            </button>
          </div>

          {/* Form Body */}
          <form onSubmit={handleCreateOutward} style={{ padding: "28px" }}>
            <div style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))",
              gap: "20px",
              marginBottom: "24px"
            }}>
              <div style={{ gridColumn: "1 / -1" }}>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Cargo / Material Description *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.itemDescription}
                  onChange={(e) => setFormData({ ...formData, itemDescription: e.target.value })}
                  placeholder="e.g. Compressed Biogas Cascade Trailer (3,200 kg @ 200 bar)"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Quantity / Units *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.quantity}
                  onChange={(e) => setFormData({ ...formData, quantity: e.target.value })}
                  placeholder="e.g. 1 Trailer / 5 Nos"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Outward Challan No *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.dispatchChallanNo}
                  onChange={(e) => setFormData({ ...formData, dispatchChallanNo: e.target.value })}
                  placeholder="e.g. DC-OUT-2026-1105"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Destination / Recipient *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.recipient}
                  onChange={(e) => setFormData({ ...formData, recipient: e.target.value })}
                  placeholder="e.g. BPCL Retail Dispensing Station"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Carrier / Vehicle Plate No
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.vehicleNo}
                  onChange={(e) => setFormData({ ...formData, vehicleNo: e.target.value })}
                  placeholder="e.g. TS 09 UB 9100"
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Outward Classification
                </label>
                <select
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.type}
                  onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                >
                  <option value="Non-Returnable (Finished Goods)">Non-Returnable (Finished Goods)</option>
                  <option value="Returnable for Recalibration / Warranty">Returnable for Recalibration / Warranty</option>
                  <option value="Non-Returnable (Scrap)">Non-Returnable (Scrap)</option>
                </select>
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Plant Authority Approval Sign-Off
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.authorizedBy}
                  onChange={(e) => setFormData({ ...formData, authorizedBy: e.target.value })}
                />
              </div>
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
                  backgroundColor: "#d97706",
                  color: "#ffffff",
                  fontWeight: "600",
                  cursor: "pointer",
                  fontSize: "13.5px",
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "8px",
                  boxShadow: "0 2px 6px rgba(217, 119, 6, 0.3)"
                }}
              >
                <Save size={16} />
                Sign & Issue Outward Pass
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* KPI Cards */}
          <div className="vm-kpi-grid">
        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#fef3c7", color: "#d97706" }}>
            <FileBadge size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Total Outward Passes</h3>
            <span className="vm-kpi-value text-amber-700">{outwardLogs.length}</span>
          </div>
        </div>
        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#d1fae5", color: "#059669" }}>
            <Truck size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Dispatched Consignments</h3>
            <span className="vm-kpi-value text-emerald-600">
              {outwardLogs.filter((o) => o.status === "Dispatched").length}
            </span>
          </div>
        </div>
        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#fee2e2", color: "#dc2626" }}>
            <ShieldAlert size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Pending Loading Clearance</h3>
            <span className="vm-kpi-value text-red-600">
              {outwardLogs.filter((o) => o.status.includes("Loading")).length}
            </span>
          </div>
        </div>
      </div>

      {/* Search Bar */}
      <div className="vm-controls-card mb-4">
        <input
          type="text"
          placeholder="Search outward items, recipient company, vehicle plate, or dispatch challan..."
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
                <th>Gate Pass ID & Date</th>
                <th>Cargo / Item Description</th>
                <th>Quantity</th>
                <th>Challan Reference</th>
                <th>Recipient Entity</th>
                <th>Dispatch Carrier</th>
                <th>Category</th>
                <th>Authorized By</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan="9" className="text-center py-6 text-slate-500">
                    <div className="d-flex flex-column align-items-center justify-content-center py-4">
                      <Truck size={36} className="text-slate-300 mb-2" />
                      <div className="font-semibold text-slate-700">No outward material passes logged</div>
                      <p className="text-xs text-slate-400 mt-1 mb-0">Click "Issue Outward Gate Pass" to record outgoing goods or trailers.</p>
                    </div>
                  </td>
                </tr>
              ) : (
                filtered.map((item) => (
                <tr key={item.id}>
                  <td>
                    <span className="font-mono font-bold text-amber-800 text-xs">{item.id}</span>
                    <div className="text-xs text-slate-500">{item.date}</div>
                  </td>
                  <td>
                    <div className="font-bold text-slate-900 text-xs">{item.itemDescription}</div>
                  </td>
                  <td>
                    <span className="font-mono font-bold text-slate-800 text-xs">{item.quantity}</span>
                  </td>
                  <td>
                    <span className="font-mono text-xs font-semibold text-slate-700">{item.dispatchChallanNo}</span>
                  </td>
                  <td>
                    <div className="text-xs font-semibold text-slate-800">{item.recipient}</div>
                  </td>
                  <td>
                    <div className="text-xs text-slate-700 font-mono">{item.vehicleNo}</div>
                  </td>
                  <td>
                    <span className="vm-status-badge badge-pending text-xs">
                      {item.type}
                    </span>
                  </td>
                  <td>
                    <div className="text-xs text-slate-600">{item.authorizedBy}</div>
                  </td>
                  <td>
                    <span
                      className={`vm-status-badge ${
                        item.status === "Dispatched" ? "badge-cleared" : "badge-active"
                      }`}
                    >
                      {item.status}
                    </span>
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

export default MaterialOutward;

