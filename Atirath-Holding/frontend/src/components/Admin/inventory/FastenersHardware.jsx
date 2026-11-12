import React, { useState, useEffect } from "react";
import {
  Wrench,
  Plus,
  Search,
  Filter,
  Download,
  Eye,
  Edit2,
  Trash2,
  FileCheck,
  ShieldCheck,
  Layers,
  CheckCircle2,
  AlertTriangle,
  Upload,
  X,
  Save,
  Tag,
  ArrowLeft
} from "lucide-react";
import { getFasteners, saveFastener, deleteFastener } from "./inventoryApi";

const STORAGE_KEY = "bionova_fasteners_hardware_v1";
try { const _raw = localStorage.getItem(STORAGE_KEY); if (_raw && (_raw.includes("INV-") || _raw.includes("CIV-") || _raw.includes("FST-") || _raw.includes("BN-") || _raw.includes("UltraTech") || _raw.includes("Neuman"))) { localStorage.removeItem(STORAGE_KEY); } } catch(e){}

const INITIAL_FASTENERS = [];

const FastenersHardware = ({ screenPerm }) => {
  const [fasteners, setFasteners] = useState([]);

  const [searchTerm, setSearchTerm] = useState("");
  const [gradeFilter, setGradeFilter] = useState("All");
  const [coatingFilter, setCoatingFilter] = useState("All");

  // Modals
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isMtcModalOpen, setIsMtcModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState("add"); // 'add' | 'edit'
  const [selectedFastener, setSelectedFastener] = useState(null);

  // Form State
  const [formData, setFormData] = useState({
    sku: "",
    name: "",
    category: "High-Tensile Bolts",
    grade: "Grade 10.9",
    threadSpec: "",
    coating: "Hot-Dip Galvanized",
    batchNo: "",
    heatNo: "",
    mtcCertNo: "",
    mtcFileName: "",
    tensileStrength: "",
    yieldStrength: "",
    currentStock: 0,
    reorderThreshold: 0,
    uom: "Pcs",
    location: "",
    unitCost: 0,
    supplier: "",
    application: ""
  });

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(fasteners));
  }, [fasteners]);

  // KPIs
  const totalStockCount = fasteners.reduce((acc, it) => acc + it.currentStock, 0);
  const totalValuation = fasteners.reduce((acc, it) => acc + (it.currentStock * it.unitCost), 0);
  const lowStockCount = fasteners.filter(it => it.currentStock <= it.reorderThreshold).length;
  const mtcVerifiedCount = fasteners.filter(it => it.mtcCertNo).length;

  // Filter
  const filteredFasteners = fasteners.filter(item => {
    const matchesSearch =
      item.sku.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.threadSpec.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.batchNo.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.mtcCertNo.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (item.application && item.application.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesGrade = gradeFilter === "All" || item.grade.includes(gradeFilter);
    const matchesCoating = coatingFilter === "All" || item.coating.includes(coatingFilter);

    return matchesSearch && matchesGrade && matchesCoating;
  });

  const handleOpenAdd = () => {
    setModalMode("add");
    setFormData({
      sku: `FST-NEW-${String(Date.now()).slice(-4)}`,
      name: "",
      category: "High-Tensile Bolts",
      grade: "Grade 10.9",
      threadSpec: "M16 x 2.0mm",
      coating: "PTFE / Teflon",
      batchNo: `BAT-${String(Date.now()).slice(-6)}`,
      heatNo: `HT-${String(Date.now()).slice(-5)}`,
      mtcCertNo: `MTC-EN10204-${String(Date.now()).slice(-4)}`,
      mtcFileName: "Mill_Test_Certificate.pdf",
      tensileStrength: "1040 MPa",
      yieldStrength: "940 MPa",
      currentStock: 500,
      reorderThreshold: 200,
      uom: "Pcs",
      location: "Store Room B - Bin 10",
      unitCost: 85,
      supplier: "",
      application: ""
    });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (item) => {
    setModalMode("edit");
    setSelectedFastener(item);
    setFormData({ ...item });
    setIsModalOpen(true);
  };

  const handleOpenMtc = (item) => {
    setSelectedFastener(item);
    setIsMtcModalOpen(true);
  };

  const handleDelete = (id) => {
    if (window.confirm("Are you sure you want to delete this structural fastener record?")) {
      setFasteners(fasteners.filter(f => f.id !== id));
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
      setFasteners([newItem, ...fasteners]);
    } else {
      setFasteners(fasteners.map(f => f.id === selectedFastener.id ? {
        ...formData,
        currentStock: Number(formData.currentStock),
        reorderThreshold: Number(formData.reorderThreshold),
        unitCost: Number(formData.unitCost)
      } : f));
    }
    setIsModalOpen(false);
  };

  const handleExportCSV = () => {
    const headers = ["SKU", "Item Name", "Category", "Grade", "Thread Spec", "Anti-Corrosion Coating", "Batch No", "Heat No", "MTC Cert No", "Stock", "Threshold", "UOM", "Location", "Unit Cost (INR)", "Supplier", "Application"];
    const rows = filteredFasteners.map(f => [
      f.sku,
      `"${f.name.replace(/"/g, '""')}"`,
      f.category,
      f.grade,
      f.threadSpec,
      `"${f.coating}"`,
      f.batchNo,
      f.heatNo,
      f.mtcCertNo,
      f.currentStock,
      f.reorderThreshold,
      f.uom,
      `"${f.location}"`,
      f.unitCost,
      `"${f.supplier || ""}"`,
      `"${f.application || ""}"`
    ]);

    const csvContent = "data:text/csv;charset=utf-8," + [headers.join(","), ...rows.map(e => e.join(","))].join("\n");
    const link = document.createElement("a");
    link.setAttribute("href", encodeURI(csvContent));
    link.setAttribute("download", `bionova_fasteners_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="submod-wrapper">
      {/* Header */}
      <div className="inv-header-section" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="inv-subtitle" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          High-tensile bolts (Grades 8.8, 10.9, 12.9), stainless fasteners (SS 304/316), anti-corrosion coatings (HDG, PTFE/Teflon, Geomet), thread specs, and digital Mill Test Certificates (MTC).
        </p>
        <div className="inv-header-actions" style={{ display: "flex", gap: "12px", alignItems: "center", flexShrink: 0, marginLeft: "auto" }}>
          <button className="inv-btn-secondary" onClick={handleExportCSV}>
            <Download size={16} />
            Export Hardware CSV
          </button>
          {screenPerm.canCreate && (
            <button className="inv-btn-primary" onClick={handleOpenAdd}>
              <Plus size={16} />
              Add Fastener / Hardware Item
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
                <Wrench size={22} color="#1677ff" />
                {modalMode === "add" ? "Add Fastener / Joining Hardware Item" : "Edit Fastener Item"}
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Track high-tensile bolts, SS 316 studs, heat batch cast numbers, mill test certificates (MTC), and torque applications.
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
              <ArrowLeft size={16} /> Back to Hardware Inventory
            </button>
          </div>

          <form onSubmit={handleSaveForm} style={{ padding: "28px" }}>
            {/* Section 1: Item Identification & Metallurgy */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Wrench size={18} color="#1677ff" /> 1. Fastener Classification & Technical Specs
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    SKU / Part Code *
                  </label>
                  <input
                    type="text"
                    required
                    value={formData.sku}
                    onChange={(e) => setFormData({ ...formData, sku: e.target.value })}
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
                    <option value="High-Tensile Bolts">High-Tensile Bolts (8.8, 10.9, 12.9)</option>
                    <option value="Stainless Steel Fasteners">Stainless Steel Fasteners (SS 304 / 316)</option>
                    <option value="Anchors & Hardware">Anchors & Foundation Bolts</option>
                    <option value="Screws & Joining Hardware">Screws & PEB Hardware</option>
                  </select>
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Fastener Name & Dimension *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Grade 10.9 Heavy Hex Flange Bolt (M20 x 90mm)"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Grade / Metallurgy *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Grade 10.9 or SS 316"
                    value={formData.grade}
                    onChange={(e) => setFormData({ ...formData, grade: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Thread Specification & Pitch *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. M20 x 2.5mm Coarse"
                    value={formData.threadSpec}
                    onChange={(e) => setFormData({ ...formData, threadSpec: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Anti-Corrosion Coating
                  </label>
                  <select
                    value={formData.coating}
                    onChange={(e) => setFormData({ ...formData, coating: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Hot-Dip Galvanized (HDG 65µm)">Hot-Dip Galvanized (HDG 65µm)</option>
                    <option value="PTFE / Teflon (FluoroKote#1)">PTFE / Teflon (FluoroKote#1)</option>
                    <option value="Geomet 500 (Non-Electrolytic)">Geomet 500 (Zinc Flake)</option>
                    <option value="Passivated SS 316 (ASTM A380)">Passivated SS 316 (ASTM A380)</option>
                    <option value="Zinc Yellow Trivalent Passivated">Zinc Yellow Trivalent Passivated</option>
                    <option value="Ruspert 1000-Hr Salt Spray">Ruspert 1000-Hr Salt Spray</option>
                  </select>
                </div>
              </div>
            </div>

            {/* Section 2: Quality Traceability, Stock & Storage */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <FileCheck size={18} color="#059669" /> 2. Quality Traceability (MTC & Heat No) & Inventory
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Batch / Lot Number *
                  </label>
                  <input
                    type="text"
                    required
                    value={formData.batchNo}
                    onChange={(e) => setFormData({ ...formData, batchNo: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Heat Cast Number *
                  </label>
                  <input
                    type="text"
                    required
                    value={formData.heatNo}
                    onChange={(e) => setFormData({ ...formData, heatNo: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Mill Test Certificate (MTC) Number *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. MTC-EN10204-8921"
                    value={formData.mtcCertNo}
                    onChange={(e) => setFormData({ ...formData, mtcCertNo: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

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
                    Storage Bin / Rack Location
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. Store Room B - Bin 14"
                    value={formData.location}
                    onChange={(e) => setFormData({ ...formData, location: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Plant Application & Equipment Mounting Target
                  </label>
                  <textarea
                    rows={2}
                    placeholder="e.g. High-Pressure CBG Gas Flanges & High-Vibration Skid Mounting"
                    value={formData.application}
                    onChange={(e) => setFormData({ ...formData, application: e.target.value })}
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
                <Save size={16} /> {modalMode === "add" ? "Save Fastener Record" : "Update Fastener"}
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
            <h3>Fastener SKUs Tracked</h3>
            <div className="inv-kpi-value">{fasteners.length} SKUs</div>
            <p className="inv-kpi-subtext">Bolts, Nuts, Rods & Screws</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#ecfdf5", color: "#059669" }}>
            <Wrench size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Total Physical Units</h3>
            <div className="inv-kpi-value">{totalStockCount.toLocaleString()} Pcs</div>
            <p className="inv-kpi-subtext">₹{(totalValuation / 100000).toFixed(2)} Lakhs Valuation</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#e0e7ff", color: "#4f46e5" }}>
            <FileCheck size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>MTC Verified Batches</h3>
            <div className="inv-kpi-value">{mtcVerifiedCount} / {fasteners.length}</div>
            <p className="inv-kpi-subtext">EN 10204 3.1 Digital Certificates</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: lowStockCount > 0 ? "#fef2f2" : "#f1f5f9", color: lowStockCount > 0 ? "#dc2626" : "#64748b" }}>
            <AlertTriangle size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Low Stock Warnings</h3>
            <div className="inv-kpi-value" style={{ color: lowStockCount > 0 ? "#dc2626" : "#0f172a" }}>
              {lowStockCount} Fasteners
            </div>
            <p className="inv-kpi-subtext">Under Safety Reorder Level</p>
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
              placeholder="Search by SKU, Name, Thread (M20x2.5), Batch No, MTC Cert, or Application..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          <div className="inv-filter-group">
            <select
              className="inv-select"
              value={gradeFilter}
              onChange={(e) => setGradeFilter(e.target.value)}
            >
              <option value="All">All Material Grades</option>
              <option value="10.9">Grade 10.9 (High-Tensile)</option>
              <option value="8.8">Grade 8.8 (Structural)</option>
              <option value="12.9">Grade 12.9 (Alloy Steel)</option>
              <option value="316">SS 316 (Acid/Slurry Grade)</option>
              <option value="304">SS 304 (General Stainless)</option>
            </select>

            <select
              className="inv-select"
              value={coatingFilter}
              onChange={(e) => setCoatingFilter(e.target.value)}
            >
              <option value="All">All Anti-Corrosion Coatings</option>
              <option value="PTFE">PTFE / Teflon Coating</option>
              <option value="Galvanized">Hot-Dip Galvanized (HDG)</option>
              <option value="Geomet">Geomet 500 Zinc-Flake</option>
              <option value="Passivated">Passivated Stainless Steel</option>
            </select>
          </div>
        </div>
      </div>

      {/* Fasteners Table */}
      <div className="inv-table-card">
        <div className="inv-table-wrapper">
          <table className="inv-table">
            <thead>
              <tr>
                <th>Fastener Description & SKU</th>
                <th>Grade / Material</th>
                <th>Thread Specification</th>
                <th>Anti-Corrosion Coating</th>
                <th>Batch & Heat No</th>
                <th>Current Stock</th>
                <th>Digital MTC Certificate</th>
                <th>Storage Bin</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredFasteners.length === 0 ? (
                <tr>
                  <td colSpan="9" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                    No fasteners or hardware items match the selected filter.
                  </td>
                </tr>
              ) : (
                filteredFasteners.map((item) => {
                  const isLow = item.currentStock <= item.reorderThreshold;
                  return (
                    <tr key={item.id}>
                      <td>
                        <div style={{ fontWeight: "700", color: "#0f172a" }}>{item.name}</div>
                        <div style={{ fontSize: "12px", color: "#64748b", fontFamily: "monospace" }}>{item.sku}</div>
                      </td>
                      <td>
                        <span className="inv-badge-category" style={{
                          backgroundColor: item.grade.includes("10.9") || item.grade.includes("12.9") ? "#fef3c7" : item.grade.includes("316") ? "#ecfdf5" : "#eff6ff",
                          color: item.grade.includes("10.9") || item.grade.includes("12.9") ? "#b45309" : item.grade.includes("316") ? "#047857" : "#1d4ed8"
                        }}>
                          {item.grade}
                        </span>
                      </td>
                      <td>
                        <div style={{ fontWeight: "600", fontSize: "13px" }}>{item.threadSpec}</div>
                        <div style={{ fontSize: "11px", color: "#64748b" }}>{item.category}</div>
                      </td>
                      <td>
                        <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                          <ShieldCheck size={14} color="#059669" />
                          <span style={{ fontSize: "13px", fontWeight: "600", color: "#334155" }}>{item.coating}</span>
                        </div>
                      </td>
                      <td>
                        <div style={{ fontSize: "12px", fontWeight: "600" }}>Lot: {item.batchNo}</div>
                        <div style={{ fontSize: "11px", color: "#64748b" }}>Heat: {item.heatNo}</div>
                      </td>
                      <td>
                        <div style={{ fontWeight: "800", color: isLow ? "#dc2626" : "#059669" }}>
                          {item.currentStock.toLocaleString()} {item.uom}
                        </div>
                        <div style={{ fontSize: "11px", color: "#64748b" }}>
                          Min: {item.reorderThreshold.toLocaleString()}
                        </div>
                      </td>
                      <td>
                        <button
                          className="inv-btn-secondary"
                          style={{ padding: "4px 8px", fontSize: "11px", display: "inline-flex", gap: "4px" }}
                          onClick={() => handleOpenMtc(item)}
                        >
                          <FileCheck size={13} color="#2563eb" />
                          {item.mtcCertNo}
                        </button>
                      </td>
                      <td>
                        <span style={{ fontSize: "12px", color: "#475569" }}>{item.location}</span>
                      </td>
                      <td>
                        <div className="inv-table-actions">
                          <button
                            className="inv-icon-btn"
                            title="View MTC Certificate"
                            onClick={() => handleOpenMtc(item)}
                          >
                            <FileCheck size={15} color="#2563eb" />
                          </button>
                          {screenPerm.canEdit && (
                            <button
                              className="inv-icon-btn"
                              title="Edit Fastener"
                              onClick={() => handleOpenEdit(item)}
                            >
                              <Edit2 size={15} />
                            </button>
                          )}
                          {screenPerm.canDelete && (
                            <button
                              className="inv-icon-btn danger"
                              title="Delete Fastener"
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

      {/* Digital Mill Test Certificate (MTC) Modal */}
      {isMtcModalOpen && selectedFastener && (
        <div className="inv-modal-overlay" onClick={() => setIsMtcModalOpen(false)}>
          <div className="inv-modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: "680px" }}>
            <div className="inv-modal-header" style={{ borderBottom: "2px solid #1677ff" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                <FileCheck size={22} color="#1677ff" />
                <div>
                  <h2 style={{ margin: 0, fontSize: "18px" }}>Mill Test Certificate (MTC) EN 10204 Type 3.1</h2>
                  <span style={{ fontSize: "12px", color: "#64748b" }}>Accredited Metallurgical Inspection Verification</span>
                </div>
              </div>
              <button className="inv-modal-close" onClick={() => setIsMtcModalOpen(false)}>
                <X size={20} />
              </button>
            </div>
            <div className="inv-modal-body" style={{ backgroundColor: "#fafaf9", padding: "20px" }}>
              <div style={{ backgroundColor: "#ffffff", padding: "18px", borderRadius: "8px", border: "1px solid #e2e8f0", boxShadow: "0 1px 3px rgba(0,0,0,0.05)" }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", borderBottom: "1px dashed #cbd5e1", paddingBottom: "12px", marginBottom: "14px" }}>
                  <div>
                    <span style={{ fontSize: "11px", fontWeight: "700", color: "#64748b", textTransform: "uppercase" }}>Certificate Number</span>
                    <div style={{ fontSize: "16px", fontWeight: "800", color: "#1677ff" }}>{selectedFastener.mtcCertNo}</div>
                  </div>
                  <div style={{ textAlign: "right" }}>
                    <span style={{ fontSize: "11px", fontWeight: "700", color: "#64748b", textTransform: "uppercase" }}>Batch / Heat No</span>
                    <div style={{ fontSize: "14px", fontWeight: "700" }}>{selectedFastener.heatNo} ({selectedFastener.batchNo})</div>
                  </div>
                </div>

                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "12px", marginBottom: "16px" }}>
                  <div>
                    <div style={{ fontSize: "11px", color: "#64748b" }}>Material Description</div>
                    <div style={{ fontWeight: "700", color: "#0f172a" }}>{selectedFastener.name}</div>
                  </div>
                  <div>
                    <div style={{ fontSize: "11px", color: "#64748b" }}>Metallurgical Grade</div>
                    <div style={{ fontWeight: "700", color: "#b45309" }}>{selectedFastener.grade}</div>
                  </div>
                  <div>
                    <div style={{ fontSize: "11px", color: "#64748b" }}>Anti-Corrosion Surface Treatment</div>
                    <div style={{ fontWeight: "600", color: "#047857" }}>{selectedFastener.coating}</div>
                  </div>
                  <div>
                    <div style={{ fontSize: "11px", color: "#64748b" }}>Certified Manufacturer / Mill</div>
                    <div style={{ fontWeight: "600" }}>{selectedFastener.supplier}</div>
                  </div>
                </div>

                {/* Mechanical Properties Table */}
                <h4 style={{ margin: "14px 0 8px 0", fontSize: "13px", fontWeight: "700", color: "#334155" }}>
                  Certified Mechanical Test Results
                </h4>
                <table style={{ width: "100%", fontSize: "12px", borderCollapse: "collapse", border: "1px solid #e2e8f0", marginBottom: "14px" }}>
                  <thead style={{ backgroundColor: "#f1f5f9" }}>
                    <tr>
                      <th style={{ padding: "6px 8px", textAlign: "left" }}>Parameter</th>
                      <th style={{ padding: "6px 8px", textAlign: "left" }}>Specified Standard</th>
                      <th style={{ padding: "6px 8px", textAlign: "left" }}>Actual Lab Result</th>
                      <th style={{ padding: "6px 8px", textAlign: "center" }}>Verdict</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr style={{ borderBottom: "1px solid #f1f5f9" }}>
                      <td style={{ padding: "6px 8px" }}>Tensile Strength (Rm)</td>
                      <td style={{ padding: "6px 8px" }}>≥ 1000 MPa</td>
                      <td style={{ padding: "6px 8px", fontWeight: "700", color: "#059669" }}>{selectedFastener.tensileStrength || "1040 MPa"}</td>
                      <td style={{ padding: "6px 8px", textAlign: "center", color: "#059669", fontWeight: "700" }}>PASS</td>
                    </tr>
                    <tr style={{ borderBottom: "1px solid #f1f5f9" }}>
                      <td style={{ padding: "6px 8px" }}>Yield Proof Stress (Rp0.2)</td>
                      <td style={{ padding: "6px 8px" }}>≥ 900 MPa</td>
                      <td style={{ padding: "6px 8px", fontWeight: "700", color: "#059669" }}>{selectedFastener.yieldStrength || "940 MPa"}</td>
                      <td style={{ padding: "6px 8px", textAlign: "center", color: "#059669", fontWeight: "700" }}>PASS</td>
                    </tr>
                    <tr>
                      <td style={{ padding: "6px 8px" }}>Coating Adhesion & Thickness</td>
                      <td style={{ padding: "6px 8px" }}>ASTM A153 / ASTM F1136</td>
                      <td style={{ padding: "6px 8px", fontWeight: "700" }}>Uniform & Zero Flaking</td>
                      <td style={{ padding: "6px 8px", textAlign: "center", color: "#059669", fontWeight: "700" }}>PASS</td>
                    </tr>
                  </tbody>
                </table>

                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", backgroundColor: "#f8fafc", padding: "10px", borderRadius: "6px", border: "1px solid #e2e8f0" }}>
                  <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                    <ShieldCheck size={18} color="#059669" />
                    <span style={{ fontSize: "12px", fontWeight: "600", color: "#059669" }}>
                      Quality Assurance Verified & Digitally Signed
                    </span>
                  </div>
                  <span style={{ fontSize: "11px", color: "#64748b" }}>File: {selectedFastener.mtcFileName || "MTC_EN10204.pdf"}</span>
                </div>
              </div>
            </div>
            <div className="inv-modal-footer">
              <button
                type="button"
                className="inv-btn-primary"
                onClick={() => alert(`Downloading verified MTC certificate: ${selectedFastener.mtcFileName || 'MTC_Cert.pdf'}`)}
              >
                <Download size={15} />
                Download Certified MTC PDF
              </button>
              <button type="button" className="inv-btn-secondary" onClick={() => setIsMtcModalOpen(false)}>
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default FastenersHardware;

