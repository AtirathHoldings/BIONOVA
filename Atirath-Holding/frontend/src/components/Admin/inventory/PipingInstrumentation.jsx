import React, { useState, useEffect } from "react";
import {
  Layers,
  Plus,
  Search,
  Filter,
  Download,
  Eye,
  Edit2,
  Trash2,
  Activity,
  Flame,
  ShieldCheck,
  CheckCircle2,
  AlertTriangle,
  X,
  Save,
  Tag,
  Gauge,
  ArrowLeft
} from "lucide-react";
import { getPipingSpares, savePipingSpare, deletePipingSpare } from "./inventoryApi";

const STORAGE_KEY = "bionova_piping_instrumentation_v1";
try { const _raw = localStorage.getItem(STORAGE_KEY); if (_raw && (_raw.includes("INV-") || _raw.includes("CIV-") || _raw.includes("FST-") || _raw.includes("BN-") || _raw.includes("UltraTech") || _raw.includes("Neuman"))) { localStorage.removeItem(STORAGE_KEY); } } catch(e){}

const INITIAL_PID_SPARES = [];

const PipingInstrumentation = ({ screenPerm }) => {
  const [spares, setSpares] = useState([]);

  const [searchTerm, setSearchTerm] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("All");

  // Modals
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDetailModalOpen, setIsDetailModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState("add"); // 'add' | 'edit'
  const [selectedSpare, setSelectedSpare] = useState(null);

  // Form State
  const [formData, setFormData] = useState({
    tagNo: "",
    name: "",
    category: "Manual Valves",
    material: "",
    sizeRating: "",
    endConnection: "",
    operatingTemp: "",
    currentStock: 0,
    reorderThreshold: 0,
    uom: "Units",
    location: "",
    unitCost: 0,
    supplier: "",
    pidLineRef: "",
    notes: ""
  });

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(spares));
  }, [spares]);

  // KPIs
  const totalValuation = spares.reduce((acc, it) => acc + (it.currentStock * it.unitCost), 0);
  const lowStockCount = spares.filter(it => it.currentStock <= it.reorderThreshold).length;
  const safetyCriticalCount = spares.filter(it => it.category === "Flame Arrestors & PRVs" || it.category === "Pneumatic Valves").length;

  // Filter
  const filteredSpares = spares.filter(item => {
    const matchesSearch =
      item.tagNo.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.material.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.sizeRating.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.pidLineRef.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (item.supplier && item.supplier.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesCategory = categoryFilter === "All" || item.category === categoryFilter;

    return matchesSearch && matchesCategory;
  });

  const handleOpenAdd = () => {
    setModalMode("add");
    setFormData({
      tagNo: `PID-VLV-${String(Date.now()).slice(-4)}`,
      name: "",
      category: "Manual Valves",
      material: "Forged Steel A105 / SS316",
      sizeRating: "2-Inch Class 300 (50 Bar)",
      endConnection: "Flanged ANSI 300# RF",
      operatingTemp: "-20°C to +120°C",
      currentStock: 5,
      reorderThreshold: 2,
      uom: "Units",
      location: "Instrument Store Room",
      unitCost: 25000,
      supplier: "",
      pidLineRef: "",
      notes: ""
    });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (item) => {
    setModalMode("edit");
    setSelectedSpare(item);
    setFormData({ ...item });
    setIsModalOpen(true);
  };

  const handleOpenDetail = (item) => {
    setSelectedSpare(item);
    setIsDetailModalOpen(true);
  };

  const handleDelete = (id) => {
    if (window.confirm("Are you sure you want to delete this P&ID hardware record?")) {
      setSpares(spares.filter(s => s.id !== id));
    }
  };

  const handleSaveForm = (e) => {
    e.preventDefault();
    if (modalMode === "add") {
      const newItem = {
        ...formData,
        id: Date.now(),
        currentStock: Number(formData.currentStock),
        reorderThreshold: Number(formData.reorderThreshold),
        unitCost: Number(formData.unitCost)
      };
      setSpares([newItem, ...spares]);
    } else {
      setSpares(spares.map(s => s.id === selectedSpare.id ? {
        ...formData,
        currentStock: Number(formData.currentStock),
        reorderThreshold: Number(formData.reorderThreshold),
        unitCost: Number(formData.unitCost)
      } : s));
    }
    setIsModalOpen(false);
  };

  const handleExportCSV = () => {
    const headers = ["P&ID Tag", "Description", "Category", "Material", "Size / Pressure Rating", "End Connection", "Operating Temp", "Stock", "Threshold", "UOM", "Location", "Unit Cost (INR)", "P&ID Line Ref", "Supplier"];
    const rows = filteredSpares.map(s => [
      s.tagNo,
      `"${s.name.replace(/"/g, '""')}"`,
      s.category,
      `"${s.material}"`,
      `"${s.sizeRating}"`,
      `"${s.endConnection}"`,
      `"${s.operatingTemp}"`,
      s.currentStock,
      s.reorderThreshold,
      s.uom,
      `"${s.location}"`,
      s.unitCost,
      `"${s.pidLineRef}"`,
      `"${s.supplier || ""}"`
    ]);

    const csvContent = "data:text/csv;charset=utf-8," + [headers.join(","), ...rows.map(e => e.join(","))].join("\n");
    const link = document.createElement("a");
    link.setAttribute("href", encodeURI(csvContent));
    link.setAttribute("download", `bionova_pid_spares_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="submod-wrapper">
      {/* Header */}
      <div className="inv-header-section" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="inv-subtitle" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Manage HDPE PE100 slurry pipes, carbon/stainless steel high-pressure gas pipes, ball/butterfly/pneumatic valves, flame arrestors, PRVs, and thermal mass flow meters.
        </p>
        <div className="inv-header-actions" style={{ display: "flex", gap: "12px", alignItems: "center", flexShrink: 0, marginLeft: "auto" }}>
          <button className="inv-btn-secondary" onClick={handleExportCSV}>
            <Download size={16} />
            Export P&ID CSV
          </button>
          {screenPerm.canCreate && (
            <button className="inv-btn-primary" onClick={handleOpenAdd}>
              <Plus size={16} />
              Add P&ID Hardware / Valve
            </button>
          )}
        </div>
      </div>

      {/* If isModalOpen is true, render the Full-Page Form Card. Otherwise, render the List & KPIs */}
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
                <Layers size={22} color="#1677ff" />
                {modalMode === "add" ? "Add P&ID Hardware / Valve / Instrument" : "Edit P&ID Hardware"}
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Configure piping specifications, valve pressure ratings, end connections, temperature ranges, and inventory levels.
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
              <ArrowLeft size={16} /> Back to P&ID Spares
            </button>
          </div>

          <form onSubmit={handleSaveForm} style={{ padding: "28px" }}>
            {/* Section 1: Item Identification & Technical Specs */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Layers size={18} color="#1677ff" /> 1. P&ID Tag & Technical Specifications
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    P&ID Tag Number *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. BV-601-DISPENSE"
                    value={formData.tagNo}
                    onChange={(e) => setFormData({ ...formData, tagNo: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Category *
                  </label>
                  <select
                    value={formData.category}
                    onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Pipes & Tubing">Pipes & Tubing</option>
                    <option value="Manual Valves">Manual Valves (Ball / Butterfly)</option>
                    <option value="Pneumatic Valves">Pneumatic Actuated Valves</option>
                    <option value="Flame Arrestors & PRVs">Flame Arrestors & PRVs</option>
                    <option value="Flow Meters & Instrumentation">Flow Meters & Instrumentation</option>
                  </select>
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Item Name & Technical Description *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Trunnion-Mounted High-Pressure Ball Valve (2-Inch Class 600)"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Material / Metallurgy *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. HDPE PE100 / Forged A105 / SS 316L"
                    value={formData.material}
                    onChange={(e) => setFormData({ ...formData, material: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Size & Pressure Rating *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. 2-Inch Class 600 (100 Bar)"
                    value={formData.sizeRating}
                    onChange={(e) => setFormData({ ...formData, sizeRating: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    End Connection Type *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Flanged ANSI 600# RTJ or Butt Fusion"
                    value={formData.endConnection}
                    onChange={(e) => setFormData({ ...formData, endConnection: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Operating Temperature Range
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. -20°C to +120°C"
                    value={formData.operatingTemp}
                    onChange={(e) => setFormData({ ...formData, operatingTemp: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>
              </div>
            </div>

            {/* Section 2: Stock, Valuation & Process Unit */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Gauge size={18} color="#059669" /> 2. Inventory Quantities, Reorder Threshold & Line Reference
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Current Stock Quantity *
                  </label>
                  <input
                    type="number"
                    min="0"
                    required
                    value={formData.currentStock}
                    onChange={(e) => setFormData({ ...formData, currentStock: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Reorder Safety Threshold *
                  </label>
                  <input
                    type="number"
                    min="0"
                    required
                    value={formData.reorderThreshold}
                    onChange={(e) => setFormData({ ...formData, reorderThreshold: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Unit Cost (₹ INR) *
                  </label>
                  <input
                    type="number"
                    min="0"
                    required
                    value={formData.unitCost}
                    onChange={(e) => setFormData({ ...formData, unitCost: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Unit of Measurement *
                  </label>
                  <select
                    value={formData.uom}
                    onChange={(e) => setFormData({ ...formData, uom: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Units">Units</option>
                    <option value="Meters">Meters</option>
                    <option value="Lengths">Lengths</option>
                  </select>
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    P&ID Line / Process Unit Reference
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. Slurry Line 101 to CSTR Digester"
                    value={formData.pidLineRef}
                    onChange={(e) => setFormData({ ...formData, pidLineRef: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Warehouse Storage Location
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. Instrument Store Room - Rack V1"
                    value={formData.location}
                    onChange={(e) => setFormData({ ...formData, location: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Approved Manufacturer / OEM
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. L&T Valves / Endress+Hauser"
                    value={formData.supplier}
                    onChange={(e) => setFormData({ ...formData, supplier: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Engineering & Operating Notes
                  </label>
                  <textarea
                    rows={2}
                    value={formData.notes}
                    onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box", resize: "vertical" }}
                  />
                </div>
              </div>
            </div>

            {/* Bottom Form Actions */}
            <div style={{
              display: "flex",
              justifyContent: "flex-end",
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
                  fontSize: "13.5px",
                  cursor: "pointer",
                  transition: "all 0.2s ease"
                }}
              >
                Cancel
              </button>
              <button
                type="submit"
                style={{
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "8px",
                  padding: "10px 24px",
                  borderRadius: "8px",
                  border: "none",
                  backgroundColor: "#1677ff",
                  color: "#ffffff",
                  fontWeight: "600",
                  fontSize: "13.5px",
                  cursor: "pointer",
                  boxShadow: "0 2px 4px rgba(22, 119, 255, 0.25)"
                }}
              >
                <Save size={16} /> {modalMode === "add" ? "Save P&ID Hardware" : "Update Hardware"}
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* KPI Stats Grid */}
      <div className="inv-kpi-grid">
        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#eff6ff", color: "#2563eb" }}>
            <Layers size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Total P&ID Line Items</h3>
            <div className="inv-kpi-value">{spares.length} Spares</div>
            <p className="inv-kpi-subtext">Pipes, Valves, PRVs & Sensors</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#ecfdf5", color: "#059669" }}>
            <Gauge size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Inventory Valuation</h3>
            <div className="inv-kpi-value">₹{(totalValuation / 100000).toFixed(2)} Lakhs</div>
            <p className="inv-kpi-subtext">Capital Mechanical Assets</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#fef3c7", color: "#d97706" }}>
            <Flame size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Safety Critical Units</h3>
            <div className="inv-kpi-value">{safetyCriticalCount} Items</div>
            <p className="inv-kpi-subtext">ATEX Flame Arrestors & PRVs</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: lowStockCount > 0 ? "#fef2f2" : "#f1f5f9", color: lowStockCount > 0 ? "#dc2626" : "#64748b" }}>
            <AlertTriangle size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Low Stock Warnings</h3>
            <div className="inv-kpi-value" style={{ color: lowStockCount > 0 ? "#dc2626" : "#0f172a" }}>
              {lowStockCount} Spares
            </div>
            <p className="inv-kpi-subtext">Below Minimum Stock Level</p>
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
              placeholder="Search by P&ID Tag (P-101, BV-601, PRV), Material, Size, Line Ref, or Supplier..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          <div className="inv-filter-group">
            <select
              className="inv-select"
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
            >
              <option value="All">All P&ID Categories</option>
              <option value="Pipes & Tubing">🚰 Pipes & Tubing (HDPE / Carbon / SS316)</option>
              <option value="Manual Valves">🔘 Manual Valves (Ball / Butterfly)</option>
              <option value="Pneumatic Valves">⚡ Pneumatic Actuated ESD Valves</option>
              <option value="Flame Arrestors & PRVs">🔥 Flame Arrestors & Relief Valves</option>
              <option value="Flow Meters & Instrumentation">📊 Thermal & Coriolis Flow Meters</option>
            </select>
          </div>
        </div>
      </div>

      {/* P&ID Spares Table */}
      <div className="inv-table-card">
        <div className="inv-table-wrapper">
          <table className="inv-table">
            <thead>
              <tr>
                <th>P&ID Tag & Description</th>
                <th>Category</th>
                <th>Material Metallurgy</th>
                <th>Size & Pressure Rating</th>
                <th>End Connection</th>
                <th>Current Stock</th>
                <th>P&ID Line Reference</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredSpares.length === 0 ? (
                <tr>
                  <td colSpan="8" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                    No piping, valves, or instrumentation hardware match your filters.
                  </td>
                </tr>
              ) : (
                filteredSpares.map((item) => {
                  const isLow = item.currentStock <= item.reorderThreshold;
                  return (
                    <tr key={item.id}>
                      <td>
                        <div style={{ fontWeight: "700", color: "#0f172a" }}>{item.name}</div>
                        <div style={{ fontSize: "12px", color: "#1d4ed8", fontWeight: "700", fontFamily: "monospace" }}>{item.tagNo}</div>
                      </td>
                      <td>
                        <span className="inv-badge-category" style={{
                          backgroundColor: item.category.includes("Flame") ? "#fee2e2" : item.category.includes("Pneumatic") ? "#fef3c7" : item.category.includes("Flow") ? "#e0e7ff" : "#f1f5f9",
                          color: item.category.includes("Flame") ? "#b91c1c" : item.category.includes("Pneumatic") ? "#b45309" : item.category.includes("Flow") ? "#4338ca" : "#334155"
                        }}>
                          {item.category}
                        </span>
                      </td>
                      <td>
                        <div style={{ fontWeight: "600", fontSize: "13px", color: "#334155" }}>{item.material}</div>
                        <div style={{ fontSize: "11px", color: "#64748b" }}>Temp: {item.operatingTemp}</div>
                      </td>
                      <td>
                        <span style={{ fontWeight: "700", fontSize: "13px", color: "#0f172a" }}>
                          {item.sizeRating}
                        </span>
                      </td>
                      <td>
                        <span style={{ fontSize: "12px", color: "#475569" }}>{item.endConnection}</span>
                      </td>
                      <td>
                        <div style={{ fontWeight: "800", color: isLow ? "#dc2626" : "#059669" }}>
                          {item.currentStock} {item.uom}
                        </div>
                        <div style={{ fontSize: "11px", color: "#64748b" }}>
                          Min: {item.reorderThreshold} {item.uom}
                        </div>
                      </td>
                      <td>
                        <div style={{ fontSize: "12px", fontWeight: "600", color: "#1e293b" }}>{item.pidLineRef}</div>
                        <div style={{ fontSize: "11px", color: "#64748b" }}>Loc: {item.location}</div>
                      </td>
                      <td>
                        <div className="inv-table-actions">
                          <button
                            className="inv-icon-btn"
                            title="View Engineering Datasheet"
                            onClick={() => handleOpenDetail(item)}
                          >
                            <Eye size={15} />
                          </button>
                          {screenPerm.canEdit && (
                            <button
                              className="inv-icon-btn"
                              title="Edit Item"
                              onClick={() => handleOpenEdit(item)}
                            >
                              <Edit2 size={15} />
                            </button>
                          )}
                          {screenPerm.canDelete && (
                            <button
                              className="inv-icon-btn danger"
                              title="Delete Item"
                              onClick={() => handleDelete(item.id)}
                            >
                              <Trash2 size={15} />
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
      </>
      )}

      {/* Engineering Datasheet Modal */}
      {isDetailModalOpen && selectedSpare && (
        <div className="inv-modal-overlay" onClick={() => setIsDetailModalOpen(false)}>
          <div className="inv-modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: "680px" }}>
            <div className="inv-modal-header" style={{ borderBottom: "2px solid #2563eb" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                <Gauge size={22} color="#2563eb" />
                <div>
                  <h2 style={{ margin: 0, fontSize: "18px" }}>P&ID Engineering Datasheet</h2>
                  <span style={{ fontSize: "12px", color: "#64748b" }}>Tag: {selectedSpare.tagNo}</span>
                </div>
              </div>
              <button className="inv-modal-close" onClick={() => setIsDetailModalOpen(false)}>
                <X size={20} />
              </button>
            </div>
            <div className="inv-modal-body">
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "14px", marginBottom: "16px" }}>
                <div style={{ gridColumn: "span 2" }}>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>Equipment Description</div>
                  <div style={{ fontWeight: "700", fontSize: "16px", color: "#0f172a" }}>{selectedSpare.name}</div>
                </div>
                <div>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>Category</div>
                  <div style={{ fontWeight: "600", color: "#2563eb" }}>{selectedSpare.category}</div>
                </div>
                <div>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>Size & Pressure Rating</div>
                  <div style={{ fontWeight: "700" }}>{selectedSpare.sizeRating}</div>
                </div>
                <div>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>Material Metallurgy</div>
                  <div style={{ fontWeight: "600" }}>{selectedSpare.material}</div>
                </div>
                <div>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>End Connection</div>
                  <div style={{ fontWeight: "600" }}>{selectedSpare.endConnection}</div>
                </div>
                <div>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>Operating Temperature</div>
                  <div style={{ fontWeight: "600" }}>{selectedSpare.operatingTemp}</div>
                </div>
                <div>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>Target Process Line</div>
                  <div style={{ fontWeight: "700", color: "#0f172a" }}>{selectedSpare.pidLineRef}</div>
                </div>
                <div>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>Stock on Hand</div>
                  <div style={{ fontWeight: "800", color: "#059669" }}>{selectedSpare.currentStock} {selectedSpare.uom}</div>
                </div>
                <div>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>Unit Replacement Cost</div>
                  <div style={{ fontWeight: "600" }}>₹{selectedSpare.unitCost.toLocaleString()}</div>
                </div>
                <div style={{ gridColumn: "span 2" }}>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>Manufacturer / Supplier</div>
                  <div style={{ fontWeight: "600" }}>{selectedSpare.supplier}</div>
                </div>
                <div style={{ gridColumn: "span 2", backgroundColor: "#f8fafc", padding: "12px", borderRadius: "6px", border: "1px solid #e2e8f0" }}>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>Quality / Testing Compliance</div>
                  <div style={{ fontSize: "13px", color: "#334155", marginTop: "4px" }}>{selectedSpare.notes || "Standard API / IS compliant."}</div>
                </div>
              </div>
            </div>
            <div className="inv-modal-footer">
              <button type="button" className="inv-btn-secondary" onClick={() => setIsDetailModalOpen(false)}>
                Close Datasheet
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default PipingInstrumentation;

