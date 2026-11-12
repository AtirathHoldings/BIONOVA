import React, { useState, useEffect } from "react";
import {
  Package,
  Plus,
  Search,
  CheckCircle2,
  FileText,
  Truck,
  Building,
  UserCheck,
  ShieldCheck,
  X,
  ArrowLeft,
  Save
} from "lucide-react";
import {
  STORAGE_KEYS,
  INITIAL_INWARD,
  getStoredData,
  saveStoredData
} from "./visitorData";

const MaterialInward = ({ onNavigate }) => {
  const [inwardLogs, setInwardLogs] = useState(() =>
    getStoredData(STORAGE_KEYS.MATERIAL_INWARD, INITIAL_INWARD)
  );

  useEffect(() => {
    const handleUpdate = () => {
      setInwardLogs(getStoredData(STORAGE_KEYS.MATERIAL_INWARD, INITIAL_INWARD));
    };
    window.addEventListener("bionova_visitor_updated", handleUpdate);
    return () => window.removeEventListener("bionova_visitor_updated", handleUpdate);
  }, []);

  const [searchTerm, setSearchTerm] = useState("");
  const [isModalOpen, setIsModalOpen] = useState(false);

  const [formData, setFormData] = useState({
    itemDescription: "",
    quantity: "",
    poChallanNo: "",
    vendorName: "",
    deliveryCarrier: "",
    receivingDepartment: "Operations & Maintenance",
    type: "Non-Returnable (Raw Material)",
    inspectorName: "Gate Security Officer"
  });

  const handleCreateInward = (e) => {
    e.preventDefault();
    if (!formData.itemDescription.trim() || !formData.vendorName.trim()) return;

    const newRec = {
      id: `MI-2026-${String(inwardLogs.length + 44).padStart(3, "0")}`,
      date: new Date().toISOString().slice(0, 10),
      time: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
      ...formData,
      status: "Approved & Inwarded"
    };

    const updated = [newRec, ...inwardLogs];
    setInwardLogs(updated);
    saveStoredData(STORAGE_KEYS.MATERIAL_INWARD, updated);
    setIsModalOpen(false);
  };

  const filtered = inwardLogs.filter(
    (item) =>
      item.itemDescription.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.vendorName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.poChallanNo.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.id.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="vm-submodule-container">
      {/* Header */}
      <div className="vm-section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="vm-section-desc" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Track all incoming feedstock consignments, calibration kits, maintenance spares, and PO challans.
        </p>
        <button onClick={() => setIsModalOpen(true)} className="vm-btn-primary text-xs" style={{ flexShrink: 0, marginLeft: "auto" }}>
          <Plus size={16} /> Log Inward Material
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
                <Package size={22} color="#2563eb" />
                Record Gate Material Inward
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Track incoming feedstock consignments, calibration kits, maintenance spares, and PO challans.
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
              <ArrowLeft size={16} /> Back to Material Inward
            </button>
          </div>

          {/* Form Body */}
          <form onSubmit={handleCreateInward} style={{ padding: "28px" }}>
            <div style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))",
              gap: "20px",
              marginBottom: "24px"
            }}>
              <div style={{ gridColumn: "1 / -1" }}>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Item Description *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.itemDescription}
                  onChange={(e) => setFormData({ ...formData, itemDescription: e.target.value })}
                  placeholder="e.g. Scrubber Column Flanged Ball Valves (Class 300)"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Quantity / Unit *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.quantity}
                  onChange={(e) => setFormData({ ...formData, quantity: e.target.value })}
                  placeholder="e.g. 4 Units / 25 MT"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  PO / Delivery Challan No *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.poChallanNo}
                  onChange={(e) => setFormData({ ...formData, poChallanNo: e.target.value })}
                  placeholder="e.g. PO-BN-2026-9021"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Supplier / Vendor Name *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.vendorName}
                  onChange={(e) => setFormData({ ...formData, vendorName: e.target.value })}
                  placeholder="e.g. L&T Heavy Engineering"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Carrier / Vehicle No
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.deliveryCarrier}
                  onChange={(e) => setFormData({ ...formData, deliveryCarrier: e.target.value })}
                  placeholder="e.g. TS 08 HK 9081"
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Material Classification
                </label>
                <select
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.type}
                  onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                >
                  <option value="Non-Returnable (Raw Material)">Non-Returnable (Raw Material)</option>
                  <option value="Non-Returnable (Consumable Spares)">Non-Returnable (Consumable Spares)</option>
                  <option value="Returnable (Vendor Tools)">Returnable (Vendor Tools)</option>
                  <option value="Returnable (Demo Unit)">Returnable (Demo Unit)</option>
                </select>
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Receiving Department
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.receivingDepartment}
                  onChange={(e) => setFormData({ ...formData, receivingDepartment: e.target.value })}
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Inspector Officer
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.inspectorName}
                  onChange={(e) => setFormData({ ...formData, inspectorName: e.target.value })}
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
                  backgroundColor: "#2563eb",
                  color: "#ffffff",
                  fontWeight: "600",
                  cursor: "pointer",
                  fontSize: "13.5px",
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "8px",
                  boxShadow: "0 2px 6px rgba(37, 99, 235, 0.3)"
                }}
              >
                <Save size={16} />
                Authorize & Inward Goods
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* KPI Cards */}
          <div className="vm-kpi-grid">
        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#dbeafe", color: "#2563eb" }}>
            <Package size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Total Inward Consignments</h3>
            <span className="vm-kpi-value text-blue-700">{inwardLogs.length}</span>
          </div>
        </div>
        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#d1fae5", color: "#059669" }}>
            <ShieldCheck size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Gate Inspected & Cleared</h3>
            <span className="vm-kpi-value text-emerald-600">
              {inwardLogs.length > 0 ? "100%" : "--"}
            </span>
          </div>
        </div>
        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#fef3c7", color: "#d97706" }}>
            <FileText size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Returnable Toolkits Inward</h3>
            <span className="vm-kpi-value text-amber-600">
              {inwardLogs.filter((i) => i.type.includes("Returnable")).length}
            </span>
          </div>
        </div>
      </div>

      {/* Search Bar */}
      <div className="vm-controls-card mb-4">
        <input
          type="text"
          placeholder="Search consignment description, vendor, delivery challan, or PO..."
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
                <th>Entry ID & Date</th>
                <th>Item & Description</th>
                <th>Quantity</th>
                <th>PO / Challan No</th>
                <th>Vendor / Supplier</th>
                <th>Carrier / Person</th>
                <th>Classification</th>
                <th>Receiving Dept</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan="9" className="text-center py-6 text-slate-500">
                    <div className="d-flex flex-column align-items-center justify-content-center py-4">
                      <Package size={36} className="text-slate-300 mb-2" />
                      <div className="font-semibold text-slate-700">No inward material consignments logged</div>
                      <p className="text-xs text-slate-400 mt-1 mb-0">Click "Log Inward Material" above to record incoming feedstock or goods.</p>
                    </div>
                  </td>
                </tr>
              ) : (
                filtered.map((item) => (
                <tr key={item.id}>
                  <td>
                    <span className="font-mono font-bold text-blue-700 text-xs">{item.id}</span>
                    <div className="text-xs text-slate-500">{item.date} {item.time}</div>
                  </td>
                  <td>
                    <div className="font-bold text-slate-900 text-xs">{item.itemDescription}</div>
                  </td>
                  <td>
                    <span className="font-mono font-bold text-slate-800 text-xs">{item.quantity}</span>
                  </td>
                  <td>
                    <span className="font-mono text-xs font-semibold text-slate-700">{item.poChallanNo}</span>
                  </td>
                  <td>
                    <div className="text-xs font-semibold text-slate-800">{item.vendorName}</div>
                  </td>
                  <td>
                    <div className="text-xs text-slate-700 font-mono">{item.deliveryCarrier}</div>
                  </td>
                  <td>
                    <span
                      className={`vm-status-badge ${
                        item.type.includes("Returnable") ? "badge-pending" : "badge-cleared"
                      }`}
                    >
                      {item.type}
                    </span>
                  </td>
                  <td>
                    <div className="text-xs text-slate-600">{item.receivingDepartment}</div>
                  </td>
                  <td>
                    <span className="vm-status-badge badge-active text-xs">
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

export default MaterialInward;

