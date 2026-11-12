import React, { useState, useEffect } from "react";
import {
  AlertTriangle,
  Plus,
  Search,
  Filter,
  Download,
  CheckCircle2,
  AlertCircle,
  PackageX,
  Clock,
  ShieldAlert,
  Layers,
  X,
  Save,
  Check,
  RefreshCw,
  Flame,
  ArrowRight,
  ArrowLeft
} from "lucide-react";
import { getStockAlerts, saveStockAlert, deleteStockAlert } from "./inventoryApi";

const STORAGE_KEY = "bionova_inventory_alerts_v1";
try { const _raw = localStorage.getItem(STORAGE_KEY); if (_raw && (_raw.includes("INV-") || _raw.includes("CIV-") || _raw.includes("FST-") || _raw.includes("BN-") || _raw.includes("UltraTech") || _raw.includes("Neuman"))) { localStorage.removeItem(STORAGE_KEY); } } catch(e){}

const INITIAL_ALERTS = [];

const StockExpiryAlerts = ({ screenPerm }) => {
  const [alerts, setAlerts] = useState([]);

  const [searchTerm, setSearchTerm] = useState("");
  const [typeFilter, setTypeFilter] = useState("All");
  const [severityFilter, setSeverityFilter] = useState("All");

  // Modals
  const [isResolveModalOpen, setIsResolveModalOpen] = useState(false);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [selectedAlert, setSelectedAlert] = useState(null);
  const [resolutionText, setResolutionText] = useState("");

  // Add Alert Form
  const [formData, setFormData] = useState({
    type: "Low Stock Alert",
    severity: "Critical",
    title: "",
    materialName: "",
    batchNo: "",
    plantLocation: "Plant 1 - Hyderabad East CBG",
    currentVal: "",
    thresholdVal: "",
    actionRequired: ""
  });

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(alerts));
  }, [alerts]);

  // KPIs
  const criticalCount = alerts.filter(a => a.severity === "Critical" && a.status === "Active").length;
  const lowStockCount = alerts.filter(a => a.type === "Low Stock Alert" && a.status === "Active").length;
  const expiryCount = alerts.filter(a => a.type === "Batch Expiry Alert" && a.status === "Active").length;
  const rejectionCount = alerts.filter(a => a.type === "Quality Rejection Alert").length;

  // Filter
  const filteredAlerts = alerts.filter(item => {
    const matchesSearch =
      item.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.materialName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.batchNo.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (item.plantLocation && item.plantLocation.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (item.actionRequired && item.actionRequired.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesType = typeFilter === "All" || item.type === typeFilter;
    const matchesSeverity = severityFilter === "All" || item.severity === severityFilter;

    return matchesSearch && matchesType && matchesSeverity;
  });

  const handleOpenResolve = (alert) => {
    setSelectedAlert(alert);
    setResolutionText(alert.resolutionNotes || "");
    setIsResolveModalOpen(true);
  };

  const handleConfirmResolve = (e) => {
    e.preventDefault();
    if (!resolutionText.trim()) return;

    setAlerts(alerts.map(a => {
      if (a.id === selectedAlert.id) {
        return {
          ...a,
          status: "Resolved",
          resolutionNotes: resolutionText.trim()
        };
      }
      return m;
    }));
    setIsResolveModalOpen(false);
  };

  const handleQuarantine = (id) => {
    setAlerts(alerts.map(a => a.id === id ? { ...a, status: "Quarantined" } : a));
    alert("Batch / Material has been officially moved to the Quarantine Zone and isolated from production!");
  };

  const handleOpenAdd = () => {
    setFormData({
      type: "Quality Rejection Alert",
      severity: "Quality Rejection",
      title: "",
      materialName: "",
      batchNo: `LOT-${String(Date.now()).slice(-4)}`,
      plantLocation: "Plant 1 - Hyderabad East CBG",
      currentVal: "Contaminated Spec",
      thresholdVal: "Standard Standard",
      actionRequired: ""
    });
    setIsAddModalOpen(true);
  };

  const handleSaveAddAlert = (e) => {
    e.preventDefault();
    const newAlert = {
      ...formData,
      id: Date.now(),
      timestamp: new Date().toLocaleString(),
      status: "Active",
      resolutionNotes: ""
    };
    setAlerts([newAlert, ...alerts]);
    setIsAddModalOpen(false);
  };

  const handleExportCSV = () => {
    const headers = ["Alert ID", "Type", "Severity", "Incident Title", "Material Name", "Batch / Tag", "Plant Location", "Current Value", "Threshold Value", "Timestamp", "Status", "Action Required", "Resolution Notes"];
    const rows = filteredAlerts.map(a => [
      a.id,
      a.type,
      a.severity,
      `"${a.title.replace(/"/g, '""')}"`,
      `"${a.materialName}"`,
      a.batchNo,
      `"${a.plantLocation}"`,
      `"${a.currentVal}"`,
      `"${a.thresholdVal}"`,
      a.timestamp,
      a.status,
      `"${a.actionRequired || ""}"`,
      `"${a.resolutionNotes || ""}"`
    ]);

    const csvContent = "data:text/csv;charset=utf-8," + [headers.join(","), ...rows.map(e => e.join(","))].join("\n");
    const link = document.createElement("a");
    link.setAttribute("href", encodeURI(csvContent));
    link.setAttribute("download", `bionova_inventory_alerts_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="submod-wrapper">
      {/* Header */}
      <div className="inv-header-section" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="inv-subtitle" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Live multi-tier inventory intelligence monitoring low stock safety thresholds, approaching batch expirations (&lt;30 days), and gate quality rejections.
        </p>
        <div className="inv-header-actions" style={{ display: "flex", gap: "12px", alignItems: "center", flexShrink: 0, marginLeft: "auto" }}>
          <button className="inv-btn-secondary" onClick={handleExportCSV}>
            <Download size={16} />
            Export Alert Log
          </button>
          {screenPerm.canCreate && (
            <button className="inv-btn-primary" onClick={handleOpenAdd}>
              <Plus size={16} />
              Log Manual Quality / Safety Alert
            </button>
          )}
        </div>
      </div>

      {/* If isAddModalOpen is true, render the Full-Page Form Card. Otherwise, render the List & KPIs */}
      {isAddModalOpen ? (
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
                <AlertTriangle size={22} color="#dc2626" />
                Log Manual Quality / Stock Alert Incident
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Broadcast operational alerts for low inventory thresholds, batch expirations, or gate quality rejections across the plant network.
              </p>
            </div>
            <button
              type="button"
              onClick={() => setIsAddModalOpen(false)}
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
              <ArrowLeft size={16} /> Back to Expiry Alerts
            </button>
          </div>

          {/* Form Body */}
          <form onSubmit={handleSaveAddAlert} style={{ padding: "28px" }}>
            <div style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))",
              gap: "20px",
              marginBottom: "24px"
            }}>
              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Alert Category
                </label>
                <select
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.type}
                  onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                >
                  <option value="Quality Rejection Alert">Quality Rejection Alert</option>
                  <option value="Low Stock Alert">Low Stock Alert</option>
                  <option value="Batch Expiry Alert">Batch Expiry Alert</option>
                </select>
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Severity Level
                </label>
                <select
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.severity}
                  onChange={(e) => setFormData({ ...formData, severity: e.target.value })}
                >
                  <option value="Critical">Critical (Immediate Stop)</option>
                  <option value="Warning">Warning (Action in 24h)</option>
                  <option value="Quality Rejection">Quality Rejection</option>
                </select>
              </div>

              <div style={{ gridColumn: "1 / -1" }}>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Incident Summary Title *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  placeholder="e.g. Consignment Moisture Exceeds Permissible Limit (>75%)"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Affected Material *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.materialName}
                  onChange={(e) => setFormData({ ...formData, materialName: e.target.value })}
                  placeholder="e.g. Napier Grass Feedstock"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Batch / Consignment / Truck No *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.batchNo}
                  onChange={(e) => setFormData({ ...formData, batchNo: e.target.value })}
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Plant Installation Site
                </label>
                <select
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.plantLocation}
                  onChange={(e) => setFormData({ ...formData, plantLocation: e.target.value })}
                >
                  <option value="Plant 1 - Hyderabad East CBG">Plant 1 - Hyderabad East CBG</option>
                  <option value="Plant 2 - Medak Agri Hub">Plant 2 - Medak Agri Hub</option>
                  <option value="Plant 3 - Nalgonda Biomass Facility">Plant 3 - Nalgonda Biomass Facility</option>
                </select>
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Current / Measured Value *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.currentVal}
                  onChange={(e) => setFormData({ ...formData, currentVal: e.target.value })}
                  placeholder="e.g. Moisture 78.4%"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Threshold / Permissible Limit *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.thresholdVal}
                  onChange={(e) => setFormData({ ...formData, thresholdVal: e.target.value })}
                  placeholder="e.g. Max 68%"
                  required
                />
              </div>

              <div style={{ gridColumn: "1 / -1" }}>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Recommended Immediate Action *
                </label>
                <textarea
                  rows="3"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.actionRequired}
                  onChange={(e) => setFormData({ ...formData, actionRequired: e.target.value })}
                  placeholder="Describe immediate containment or vendor NCR steps..."
                  required
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
                onClick={() => setIsAddModalOpen(false)}
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
                  backgroundColor: "#dc2626",
                  color: "#ffffff",
                  fontWeight: "600",
                  cursor: "pointer",
                  fontSize: "13.5px",
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "8px",
                  boxShadow: "0 2px 6px rgba(220, 38, 38, 0.3)"
                }}
              >
                <Save size={16} />
                Broadcast Alert
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* Top Real-Time Notification Banners */}
          <div style={{ display: "flex", flexDirection: "column", gap: "12px", marginBottom: "24px" }}>
        {/* Low Stock Alert Banner */}
        {lowStockCount > 0 && (
          <div style={{
            background: "linear-gradient(135deg, #fef2f2 0%, #fee2e2 100%)",
            border: "1.5px solid #fca5a5",
            borderRadius: "10px",
            padding: "14px 18px",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            flexWrap: "wrap",
            gap: "12px"
          }}>
            <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
              <div style={{
                width: "36px",
                height: "36px",
                borderRadius: "50%",
                backgroundColor: "#fee2e2",
                color: "#dc2626",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                border: "2px solid #ef4444"
              }}>
                <PackageX size={20} />
              </div>
              <div>
                <div style={{ fontSize: "14px", fontWeight: "800", color: "#991b1b" }}>
                  CRITICAL LOW STOCK ALERT: {lowStockCount} Items Below Safety Buffer!
                </div>
                <div style={{ fontSize: "12px", color: "#b91c1c" }}>
                  Hydrogen Sulfide Scavenger Media is OUT OF STOCK (0 Kg). Sweet Sorghum Seeds is below safety threshold (850 Kg / Min 1,200 Kg).
                </div>
              </div>
            </div>
            <button
              className="inv-btn-primary"
              style={{ padding: "6px 12px", fontSize: "12px", backgroundColor: "#dc2626" }}
              onClick={() => setTypeFilter("Low Stock Alert")}
            >
              Filter Low Stock
            </button>
          </div>
        )}

        {/* Batch Expiry Warning Banner */}
        {expiryCount > 0 && (
          <div style={{
            background: "linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%)",
            border: "1.5px solid #fde68a",
            borderRadius: "10px",
            padding: "14px 18px",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            flexWrap: "wrap",
            gap: "12px"
          }}>
            <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
              <div style={{
                width: "36px",
                height: "36px",
                borderRadius: "50%",
                backgroundColor: "#fef3c7",
                color: "#d97706",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                border: "2px solid #f59e0b"
              }}>
                <Clock size={20} />
              </div>
              <div>
                <div style={{ fontSize: "14px", fontWeight: "800", color: "#92400e" }}>
                  BATCH EXPIRY WARNING: {expiryCount} Chemical & Biological Batches Expiring in &lt;30 Days!
                </div>
                <div style={{ fontSize: "12px", color: "#b45309" }}>
                  BioZyme-X Anaerobic Booster (Batch CHM-EZ-9942) expires on 2026-11-20 (18 days left). EPDM Sealing Gaskets expire on 2026-11-28.
                </div>
              </div>
            </div>
            <button
              className="inv-btn-primary"
              style={{ padding: "6px 12px", fontSize: "12px", backgroundColor: "#d97706" }}
              onClick={() => setTypeFilter("Batch Expiry Alert")}
            >
              Filter Expiry Alerts
            </button>
          </div>
        )}

        {/* Quality Rejection Alert Banner */}
        {rejectionCount > 0 && (
          <div style={{
            background: "linear-gradient(135deg, #f5f3ff 0%, #ede9fe 100%)",
            border: "1.5px solid #ddd6fe",
            borderRadius: "10px",
            padding: "14px 18px",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            flexWrap: "wrap",
            gap: "12px"
          }}>
            <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
              <div style={{
                width: "36px",
                height: "36px",
                borderRadius: "50%",
                backgroundColor: "#ede9fe",
                color: "#7c3aed",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                border: "2px solid #8b5cf6"
              }}>
                <ShieldAlert size={20} />
              </div>
              <div>
                <div style={{ fontSize: "14px", fontWeight: "800", color: "#5b21b6" }}>
                  GATE QUALITY REJECTIONS: {rejectionCount} Contaminated Consignments Quarantined
                </div>
                <div style={{ fontSize: "12px", color: "#6d28d9" }}>
                  Truck TS 08 UB 6610 rejected for 9.4% silica sand contamination; Press Mud Lot PM-NL-8820 isolated due to plastic debris.
                </div>
              </div>
            </div>
            <button
              className="inv-btn-primary"
              style={{ padding: "6px 12px", fontSize: "12px", backgroundColor: "#7c3aed" }}
              onClick={() => setTypeFilter("Quality Rejection Alert")}
            >
              Filter Rejections
            </button>
          </div>
        )}
      </div>

      {/* KPI Stats Grid */}
      <div className="inv-kpi-grid">
        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#fee2e2", color: "#dc2626" }}>
            <AlertCircle size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Active Critical Alerts</h3>
            <div className="inv-kpi-value" style={{ color: "#dc2626" }}>{criticalCount} Incidents</div>
            <p className="inv-kpi-subtext">Immediate Operational Action</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#ffedd5", color: "#ea580c" }}>
            <PackageX size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Low Stock Warnings</h3>
            <div className="inv-kpi-value" style={{ color: "#ea580c" }}>{lowStockCount} Materials</div>
            <p className="inv-kpi-subtext">Below Minimum Safety Buffer</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#fef3c7", color: "#d97706" }}>
            <Clock size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Expiring in &lt;30 Days</h3>
            <div className="inv-kpi-value" style={{ color: "#d97706" }}>{expiryCount} Batches</div>
            <p className="inv-kpi-subtext">Chemicals & Biomass Boosters</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#ede9fe", color: "#7c3aed" }}>
            <ShieldAlert size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Quality Rejections</h3>
            <div className="inv-kpi-value" style={{ color: "#7c3aed" }}>{rejectionCount} Lots</div>
            <p className="inv-kpi-subtext">Quarantined from Digesters</p>
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="inv-controls-card">
        <div className="inv-controls-row">
          <div className="inv-search-box">
            <Search size={18} className="inv-search-icon" />
            <input
              type="text"
              className="inv-search-input"
              placeholder="Search by Title, Material Name, Batch No, Plant Site or Action..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          <div className="inv-filter-group">
            <select
              className="inv-select"
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
            >
              <option value="All">All Alert Types</option>
              <option value="Low Stock Alert">📦 Low Stock Alerts</option>
              <option value="Batch Expiry Alert">⏳ Batch Expiry Alerts</option>
              <option value="Quality Rejection Alert">🚫 Quality Rejection Alerts</option>
            </select>

            <select
              className="inv-select"
              value={severityFilter}
              onChange={(e) => setSeverityFilter(e.target.value)}
            >
              <option value="All">All Severities</option>
              <option value="Critical">Critical (Red)</option>
              <option value="Warning">Warning (Amber)</option>
              <option value="Quality Rejection">Quality Rejection (Purple)</option>
            </select>
          </div>
        </div>
      </div>

      {/* Main Alert Center Table */}
      <div className="inv-table-card">
        <div className="inv-table-wrapper">
          <table className="inv-table">
            <thead>
              <tr>
                <th>Alert Type & Title</th>
                <th>Severity</th>
                <th>Material / Asset</th>
                <th>Batch / Ref</th>
                <th>Plant Location</th>
                <th>Variance / Current</th>
                <th>Status</th>
                <th>Action Taken</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredAlerts.length === 0 ? (
                <tr>
                  <td colSpan="9" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                    No alerts match the current filter criteria.
                  </td>
                </tr>
              ) : (
                filteredAlerts.map((item) => (
                  <tr key={item.id}>
                    <td>
                      <div style={{ fontWeight: "700", color: "#0f172a" }}>{item.title}</div>
                      <div style={{ fontSize: "11px", color: "#64748b" }}>{item.timestamp}</div>
                    </td>
                    <td>
                      <span className="inv-badge-category" style={{
                        backgroundColor: item.severity === "Critical" ? "#fee2e2" : item.severity === "Warning" ? "#fef3c7" : "#ede9fe",
                        color: item.severity === "Critical" ? "#dc2626" : item.severity === "Warning" ? "#d97706" : "#6d28d9"
                      }}>
                        {item.severity}
                      </span>
                    </td>
                    <td>
                      <span style={{ fontSize: "13px", fontWeight: "600", color: "#334155" }}>
                        {item.materialName}
                      </span>
                    </td>
                    <td>
                      <span style={{ fontFamily: "monospace", fontSize: "12px", fontWeight: "600" }}>
                        {item.batchNo}
                      </span>
                    </td>
                    <td>
                      <span style={{ fontSize: "12px", color: "#475569" }}>{item.plantLocation}</span>
                    </td>
                    <td>
                      <div style={{ fontWeight: "700", fontSize: "12px", color: "#0f172a" }}>{item.currentVal}</div>
                      <div style={{ fontSize: "11px", color: "#64748b" }}>Target: {item.thresholdVal}</div>
                    </td>
                    <td>
                      <span className={`inv-status-pill ${
                        item.status === "Resolved" ? "inv-status-in" :
                        item.status === "Quarantined" ? "inv-badge-agro" : "inv-status-out"
                      }`}>
                        {item.status}
                      </span>
                    </td>
                    <td style={{ maxWidth: "220px" }}>
                      <div style={{ fontSize: "12px", color: "#334155", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }} title={item.actionRequired}>
                        {item.actionRequired}
                      </div>
                      {item.resolutionNotes && (
                        <div style={{ fontSize: "11px", color: "#059669", fontWeight: "600" }}>
                          ✓ {item.resolutionNotes}
                        </div>
                      )}
                    </td>
                    <td>
                      <div className="inv-table-actions">
                        {item.status !== "Resolved" && screenPerm.canEdit && (
                          <button
                            className="inv-icon-btn"
                            title="Resolve Alert / Record Action"
                            style={{ backgroundColor: "#dcfce7", color: "#15803d", borderColor: "#86efac" }}
                            onClick={() => handleOpenResolve(item)}
                          >
                            <Check size={15} />
                          </button>
                        )}
                        {item.type === "Quality Rejection Alert" && item.status !== "Quarantined" && screenPerm.canEdit && (
                          <button
                            className="inv-icon-btn"
                            title="Quarantine Material"
                            style={{ backgroundColor: "#ede9fe", color: "#7c3aed", borderColor: "#c4b5fd" }}
                            onClick={() => handleQuarantine(item.id)}
                          >
                            <ShieldAlert size={15} />
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

      {/* Resolve Alert Modal */}
      {isResolveModalOpen && selectedAlert && (
        <div className="inv-modal-overlay" onClick={() => setIsResolveModalOpen(false)}>
          <div className="inv-modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: "600px" }}>
            <div className="inv-modal-header" style={{ borderBottom: "2px solid #059669" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                <CheckCircle2 size={22} color="#059669" />
                <h2 style={{ margin: 0, fontSize: "18px" }}>Resolve Inventory Incident Alert</h2>
              </div>
              <button className="inv-modal-close" onClick={() => setIsResolveModalOpen(false)}>
                <X size={20} />
              </button>
            </div>
            <form onSubmit={handleConfirmResolve}>
              <div className="inv-modal-body">
                <div style={{ backgroundColor: "#f8fafc", padding: "14px", borderRadius: "8px", border: "1px solid #e2e8f0", marginBottom: "16px" }}>
                  <div style={{ fontWeight: "700", color: "#0f172a" }}>{selectedAlert.title}</div>
                  <div style={{ fontSize: "12px", color: "#64748b", marginTop: "4px" }}>
                    Location: {selectedAlert.plantLocation} | Material: {selectedAlert.materialName}
                  </div>
                  <div style={{ fontSize: "12px", color: "#b91c1c", marginTop: "4px" }}>
                    Standard Variance: {selectedAlert.currentVal} vs {selectedAlert.thresholdVal}
                  </div>
                </div>

                <div className="inv-form-group">
                  <label>Resolution Action Taken & Verification Notes</label>
                  <textarea
                    className="inv-textarea"
                    rows="4"
                    value={resolutionText}
                    onChange={(e) => setResolutionText(e.target.value)}
                    placeholder="e.g. Emergency PO #PO-2026-991 issued for 1000 Kg; batch quarantined and diverted from main line; QA inspected and signed off."
                    required
                  />
                </div>
              </div>
              <div className="inv-modal-footer">
                <button type="button" className="inv-btn-secondary" onClick={() => setIsResolveModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="inv-btn-primary">
                  <Check size={16} />
                  Mark Alert as Resolved
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
        </>
      )}
    </div>
  );
};

export default StockExpiryAlerts;

