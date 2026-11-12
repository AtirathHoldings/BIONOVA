import React, { useState, useEffect } from "react";
import {
  Building2,
  Plus,
  Search,
  Filter,
  Download,
  Eye,
  Edit2,
  Trash2,
  HardHat,
  Layers,
  CheckCircle2,
  AlertTriangle,
  PackageX,
  X,
  Save,
  ArrowUpDown,
  Calendar,
  Building,
  ArrowLeft
} from "lucide-react";
import { getCivilMaterials, saveCivilMaterial, deleteCivilMaterial } from "./inventoryApi";

const STORAGE_KEY = "bionova_civil_materials_bom_v1";
try { const _raw = localStorage.getItem(STORAGE_KEY); if (_raw && (_raw.includes("INV-") || _raw.includes("CIV-") || _raw.includes("FST-") || _raw.includes("BN-") || _raw.includes("UltraTech") || _raw.includes("Neuman"))) { localStorage.removeItem(STORAGE_KEY); } } catch(e){}

const INITIAL_CIVIL_MATERIALS = [];

const CivilMaterialsBOM = ({ screenPerm }) => {
  const [materials, setMaterials] = useState([]);

  const [searchTerm, setSearchTerm] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("All");
  const [statusFilter, setStatusFilter] = useState("All");

  // Modals
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDetailModalOpen, setIsDetailModalOpen] = useState(false);
  const [isUsageModalOpen, setIsUsageModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState("add"); // 'add' | 'edit'
  const [selectedMaterial, setSelectedMaterial] = useState(null);

  // Form State
  const [formData, setFormData] = useState({
    code: "",
    name: "",
    category: "Concrete Grades",
    gradeSpec: "",
    uom: "MT",
    bomRequiredQty: 0,
    procuredQty: 0,
    currentStock: 0,
    allocatedQty: 0,
    allocatedStructure: "",
    yardLocation: "",
    unitCost: 0,
    supplier: "",
    status: "Adequate",
    notes: ""
  });

  // Usage allocation state
  const [usageQty, setUsageQty] = useState("");
  const [usageStructure, setUsageStructure] = useState("");

  // Save to localStorage
  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(materials));
  }, [materials]);

  // KPIs
  const totalBOMValue = materials.reduce((acc, it) => acc + (it.procuredQty * it.unitCost), 0);
  const totalStockValue = materials.reduce((acc, it) => acc + (it.currentStock * it.unitCost), 0);
  const criticalCount = materials.filter(it => it.status === "Critical Shortage").length;
  const reorderCount = materials.filter(it => it.status === "Reorder Needed").length;

  // Filter
  const filteredMaterials = materials.filter(item => {
    const matchesSearch =
      item.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.gradeSpec.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (item.allocatedStructure && item.allocatedStructure.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (item.supplier && item.supplier.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesCategory = categoryFilter === "All" || item.category === categoryFilter;
    const matchesStatus = statusFilter === "All" || item.status === statusFilter;

    return matchesSearch && matchesCategory && matchesStatus;
  });

  const handleOpenAddModal = () => {
    setModalMode("add");
    setFormData({
      code: `CIV-MAT-${String(Date.now()).slice(-4)}`,
      name: "",
      category: "Concrete Grades",
      gradeSpec: "",
      uom: "MT",
      bomRequiredQty: 100,
      procuredQty: 80,
      currentStock: 20,
      allocatedQty: 60,
      allocatedStructure: "Plant Foundation",
      yardLocation: "Main Yard Area",
      unitCost: 5000,
      supplier: "",
      status: "Adequate",
      notes: ""
    });
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (item) => {
    setModalMode("edit");
    setSelectedMaterial(item);
    setFormData({ ...item });
    setIsModalOpen(true);
  };

  const handleOpenDetailModal = (item) => {
    setSelectedMaterial(item);
    setIsDetailModalOpen(true);
  };

  const handleOpenUsageModal = (item) => {
    setSelectedMaterial(item);
    setUsageQty("");
    setUsageStructure(item.allocatedStructure || "CSTR Digester 1 Foundation");
    setIsUsageModalOpen(true);
  };

  const handleDelete = (id) => {
    if (window.confirm("Are you sure you want to delete this civil material BOM record?")) {
      setMaterials(materials.filter(m => m.id !== id));
    }
  };

  const handleSaveForm = (e) => {
    e.preventDefault();
    if (modalMode === "add") {
      const newItem = {
        ...formData,
        id: Date.now(),
        bomRequiredQty: Number(formData.bomRequiredQty),
        procuredQty: Number(formData.procuredQty),
        currentStock: Number(formData.currentStock),
        allocatedQty: Number(formData.allocatedQty),
        unitCost: Number(formData.unitCost)
      };
      setMaterials([newItem, ...materials]);
    } else {
      setMaterials(materials.map(m => m.id === selectedMaterial.id ? {
        ...formData,
        bomRequiredQty: Number(formData.bomRequiredQty),
        procuredQty: Number(formData.procuredQty),
        currentStock: Number(formData.currentStock),
        allocatedQty: Number(formData.allocatedQty),
        unitCost: Number(formData.unitCost)
      } : m));
    }
    setIsModalOpen(false);
  };

  const handleSaveUsage = (e) => {
    e.preventDefault();
    const qty = Number(usageQty);
    if (!qty || qty <= 0) return;

    if (qty > selectedMaterial.currentStock) {
      alert(`Error: Allocation quantity (${qty} ${selectedMaterial.uom}) exceeds current yard stock (${selectedMaterial.currentStock} ${selectedMaterial.uom}).`);
      return;
    }

    setMaterials(materials.map(m => {
      if (m.id === selectedMaterial.id) {
        const newStock = m.currentStock - qty;
        const newAllocated = m.allocatedQty + qty;
        const newStatus = newStock <= 0 ? "Critical Shortage" : newStock < (m.bomRequiredQty * 0.15) ? "Reorder Needed" : "Adequate";
        return {
          ...m,
          currentStock: newStock,
          allocatedQty: newAllocated,
          allocatedStructure: usageStructure,
          status: newStatus
        };
      }
      return m;
    }));
    setIsUsageModalOpen(false);
  };

  const handleExportCSV = () => {
    const headers = ["Material Code", "Name", "Category", "Grade / Standard", "Unit", "BOM Required", "Procured", "Current Stock", "Allocated Qty", "Allocated Structure", "Yard Location", "Unit Cost (INR)", "Status", "Supplier"];
    const rows = filteredMaterials.map(m => [
      m.code,
      `"${m.name.replace(/"/g, '""')}"`,
      m.category,
      `"${m.gradeSpec}"`,
      m.uom,
      m.bomRequiredQty,
      m.procuredQty,
      m.currentStock,
      m.allocatedQty,
      `"${m.allocatedStructure || ""}"`,
      `"${m.yardLocation || ""}"`,
      m.unitCost,
      m.status,
      `"${m.supplier || ""}"`
    ]);

    const csvContent = "data:text/csv;charset=utf-8," + [headers.join(","), ...rows.map(e => e.join(","))].join("\n");
    const link = document.createElement("a");
    link.setAttribute("href", encodeURI(csvContent));
    link.setAttribute("download", `bionova_civil_bom_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="submod-wrapper">
      {/* Submodule Hero Header */}
      <div className="inv-header-section" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="inv-subtitle" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Repository of civil construction materials: concrete grades (M25–M50), reinforcement TMT rebars (Fe 500D/550D), structural beams, channels, and columns with site structure allocation.
        </p>
        <div className="inv-header-actions" style={{ display: "flex", gap: "12px", alignItems: "center", flexShrink: 0, marginLeft: "auto" }}>
          <button className="inv-btn-secondary" onClick={handleExportCSV}>
            <Download size={16} />
            Export BOM CSV
          </button>
          {screenPerm.canCreate && (
            <button className="inv-btn-primary" onClick={handleOpenAddModal}>
              <Plus size={16} />
              Add Civil Material / BOM Item
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
                <HardHat size={22} color="#1677ff" />
                {modalMode === "add" ? "Add Civil Construction Material to BOM" : "Edit Civil Material"}
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Specify structural materials, standard grades, BOM requirements, yard locations, and allocated plant foundations.
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
              <ArrowLeft size={16} /> Back to Civil BOM Ledger
            </button>
          </div>

          <form onSubmit={handleSaveForm} style={{ padding: "28px" }}>
            {/* Section 1: Material Identification & Engineering Grade */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <HardHat size={18} color="#1677ff" /> 1. Material Identification & Technical Specifications
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Material Code *
                  </label>
                  <input
                    type="text"
                    required
                    value={formData.code}
                    onChange={(e) => setFormData({ ...formData, code: e.target.value })}
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
                    <option value="Concrete Grades">Concrete Grades</option>
                    <option value="TMT Rebars">TMT Rebars</option>
                    <option value="Structural Steel">Structural Steel</option>
                    <option value="Cement & Aggregates">Cement & Aggregates</option>
                  </select>
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Material Name & Description *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Ready-Mix Concrete M30 Grade (Pumpable)"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Specification / Standard Grade *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. M30 / IS 456 or Fe 500D / IS 1786"
                    value={formData.gradeSpec}
                    onChange={(e) => setFormData({ ...formData, gradeSpec: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Unit of Measurement (UOM) *
                  </label>
                  <select
                    value={formData.uom}
                    onChange={(e) => setFormData({ ...formData, uom: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="MT">MT (Metric Ton)</option>
                    <option value="Cu.m">Cu.m (Cubic Meter)</option>
                    <option value="Bags (50Kg)">Bags (50Kg)</option>
                    <option value="Lengths">Lengths (12m Standard)</option>
                    <option value="Kg">Kg</option>
                  </select>
                </div>
              </div>
            </div>

            {/* Section 2: Quantities, Cost & Site Allocation */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Layers size={18} color="#059669" /> 2. BOM Quantities, Yard Storage & Foundation Allocation
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Total BOM Required Qty *
                  </label>
                  <input
                    type="number"
                    min="0"
                    required
                    value={formData.bomRequiredQty}
                    onChange={(e) => setFormData({ ...formData, bomRequiredQty: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Total Procured / Received Qty *
                  </label>
                  <input
                    type="number"
                    min="0"
                    required
                    value={formData.procuredQty}
                    onChange={(e) => setFormData({ ...formData, procuredQty: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Current Available Yard Stock *
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
                    Primary Allocated Structure
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. CSTR Digester 1 Raft Foundation"
                    value={formData.allocatedStructure}
                    onChange={(e) => setFormData({ ...formData, allocatedStructure: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Yard / Storage Location
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. Rebar Fabrication Yard - Bay 1"
                    value={formData.yardLocation}
                    onChange={(e) => setFormData({ ...formData, yardLocation: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Manufacturer / Supplier Mill
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. Tata Steel / UltraTech / JSW / SAIL"
                    value={formData.supplier}
                    onChange={(e) => setFormData({ ...formData, supplier: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Engineering & Quality Notes
                  </label>
                  <textarea
                    rows={3}
                    placeholder="MTC mill test certificates, cube strength testing specs, bend test results..."
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
                <Save size={16} /> {modalMode === "add" ? "Save BOM Item" : "Update Material"}
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
            <h3>Total BOM Civil Items</h3>
            <div className="inv-kpi-value">{materials.length} Materials</div>
            <p className="inv-kpi-subtext">Across Concrete, Steel & Rebars</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#ecfdf5", color: "#059669" }}>
            <Building2 size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Procured Capital Value</h3>
            <div className="inv-kpi-value">₹{(totalBOMValue / 100000).toFixed(2)} Lakhs</div>
            <p className="inv-kpi-subtext">Cumulative Civil Procurement</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#fef3c7", color: "#d97706" }}>
            <ArrowUpDown size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Yard Stock Available</h3>
            <div className="inv-kpi-value">₹{(totalStockValue / 100000).toFixed(2)} Lakhs</div>
            <p className="inv-kpi-subtext">Unallocated Material on Site</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: criticalCount > 0 ? "#fee2e2" : "#f1f5f9", color: criticalCount > 0 ? "#dc2626" : "#64748b" }}>
            <AlertTriangle size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Critical / Low Alerts</h3>
            <div className="inv-kpi-value" style={{ color: criticalCount > 0 ? "#dc2626" : "#0f172a" }}>
              {criticalCount + reorderCount} Items
            </div>
            <p className="inv-kpi-subtext">{criticalCount} Critical Shortage, {reorderCount} Reorder</p>
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
              placeholder="Search by Code, Material Name, Spec (IS 456, Fe 500D), Structure or Supplier..."
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
              <option value="All">All Categories</option>
              <option value="Concrete Grades">🧱 Concrete Grades (M25 to M50)</option>
              <option value="TMT Rebars">🔩 TMT Rebars (Fe 500D / 550D)</option>
              <option value="Structural Steel">🏗️ Structural Steel (Beams / Channels / Columns)</option>
              <option value="Cement & Aggregates">🧪 Cement & Aggregates</option>
            </select>

            <select
              className="inv-select"
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
            >
              <option value="All">All Stock Statuses</option>
              <option value="Adequate">Adequate Stock</option>
              <option value="Reorder Needed">Reorder Needed</option>
              <option value="Critical Shortage">Critical Shortage</option>
            </select>
          </div>
        </div>
      </div>

      {/* Main BOM Ledger Table */}
      <div className="inv-table-card">
        <div className="inv-table-wrapper">
          <table className="inv-table">
            <thead>
              <tr>
                <th>Code & Material Description</th>
                <th>Category</th>
                <th>Specification / Grade</th>
                <th>BOM Required</th>
                <th>Procured / Received</th>
                <th>Available Yard Stock</th>
                <th>Allocated Structure</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredMaterials.length === 0 ? (
                <tr>
                  <td colSpan="9" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                    No civil construction materials match your filter criteria.
                  </td>
                </tr>
              ) : (
                filteredMaterials.map((mat) => {
                  const percentUsed = mat.bomRequiredQty > 0 ? Math.min(100, Math.round((mat.allocatedQty / mat.bomRequiredQty) * 100)) : 0;
                  return (
                    <tr key={mat.id}>
                      <td>
                        <div style={{ fontWeight: "700", color: "#0f172a" }}>{mat.name}</div>
                        <div style={{ fontSize: "12px", color: "#64748b", fontFamily: "monospace" }}>{mat.code}</div>
                      </td>
                      <td>
                        <span className="inv-badge-category inv-badge-seeds" style={{ backgroundColor: "#eff6ff", color: "#1d4ed8" }}>
                          {mat.category}
                        </span>
                      </td>
                      <td>
                        <span style={{ fontSize: "13px", fontWeight: "600", color: "#334155" }}>
                          {mat.gradeSpec}
                        </span>
                      </td>
                      <td>
                        <span style={{ fontWeight: "700" }}>{mat.bomRequiredQty.toLocaleString()}</span> {mat.uom}
                      </td>
                      <td>
                        <div style={{ fontWeight: "600", color: "#0f172a" }}>
                          {mat.procuredQty.toLocaleString()} {mat.uom}
                        </div>
                        <div style={{ fontSize: "11px", color: "#64748b" }}>
                          ₹{(mat.procuredQty * mat.unitCost).toLocaleString("en-IN")}
                        </div>
                      </td>
                      <td>
                        <div style={{
                          fontWeight: "800",
                          color: mat.currentStock <= 0 ? "#dc2626" : mat.currentStock < (mat.bomRequiredQty * 0.15) ? "#d97706" : "#059669"
                        }}>
                          {mat.currentStock.toLocaleString()} {mat.uom}
                        </div>
                        <div style={{ fontSize: "11px", color: "#64748b" }}>
                          {mat.yardLocation}
                        </div>
                      </td>
                      <td>
                        <div style={{ fontWeight: "600", color: "#1e293b", fontSize: "13px" }}>
                          {mat.allocatedStructure}
                        </div>
                        <div style={{ display: "flex", alignItems: "center", gap: "6px", marginTop: "4px" }}>
                          <div style={{ flex: 1, backgroundColor: "#e2e8f0", height: "5px", borderRadius: "3px", overflow: "hidden", minWidth: "60px" }}>
                            <div style={{ width: `${percentUsed}%`, backgroundColor: percentUsed >= 90 ? "#059669" : "#2563eb", height: "100%" }} />
                          </div>
                          <span style={{ fontSize: "11px", color: "#64748b", fontWeight: "600" }}>{percentUsed}%</span>
                        </div>
                      </td>
                      <td>
                        <span className={`inv-status-pill ${
                          mat.status === "Adequate" ? "inv-status-in" :
                          mat.status === "Reorder Needed" ? "inv-status-low" : "inv-status-out"
                        }`}>
                          {mat.status}
                        </span>
                      </td>
                      <td>
                        <div className="inv-table-actions">
                          {screenPerm.canEdit && (
                            <button
                              className="inv-icon-btn"
                              title="Record Structure Usage / Allocation (+/-)"
                              onClick={() => handleOpenUsageModal(mat)}
                            >
                              <ArrowUpDown size={15} color="#2563eb" />
                            </button>
                          )}
                          <button
                            className="inv-icon-btn"
                            title="View Material Specification & Ledger"
                            onClick={() => handleOpenDetailModal(mat)}
                          >
                            <Eye size={15} />
                          </button>
                          {screenPerm.canEdit && (
                            <button
                              className="inv-icon-btn"
                              title="Edit Material"
                              onClick={() => handleOpenEditModal(mat)}
                            >
                              <Edit2 size={15} />
                            </button>
                          )}
                          {screenPerm.canDelete && (
                            <button
                              className="inv-icon-btn danger"
                              title="Delete Material"
                              onClick={() => handleDelete(mat.id)}
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

      {/* Record Usage / Allocation Modal */}
      {isUsageModalOpen && selectedMaterial && (
        <div className="inv-modal-overlay" onClick={() => setIsUsageModalOpen(false)}>
          <div className="inv-modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: "550px" }}>
            <div className="inv-modal-header">
              <h2>Record Structure Material Usage</h2>
              <button className="inv-modal-close" onClick={() => setIsUsageModalOpen(false)}>
                <X size={20} />
              </button>
            </div>
            <form onSubmit={handleSaveUsage}>
              <div className="inv-modal-body">
                <div style={{ backgroundColor: "#f8fafc", padding: "14px", borderRadius: "8px", marginBottom: "16px", border: "1px solid #e2e8f0" }}>
                  <div style={{ fontWeight: "700", color: "#0f172a" }}>{selectedMaterial.name}</div>
                  <div style={{ fontSize: "13px", color: "#64748b", marginTop: "4px" }}>
                    Available Yard Stock: <strong style={{ color: "#059669" }}>{selectedMaterial.currentStock} {selectedMaterial.uom}</strong>
                  </div>
                </div>

                <div className="inv-form-group" style={{ marginBottom: "16px" }}>
                  <label>Quantity Consumed / Poured ({selectedMaterial.uom})</label>
                  <input
                    type="number"
                    className="inv-input"
                    value={usageQty}
                    onChange={(e) => setUsageQty(e.target.value)}
                    placeholder={`Max: ${selectedMaterial.currentStock}`}
                    max={selectedMaterial.currentStock}
                    min="1"
                    required
                  />
                </div>

                <div className="inv-form-group">
                  <label>Plant Structure / Pour Zone</label>
                  <select
                    className="inv-select"
                    value={usageStructure}
                    onChange={(e) => setUsageStructure(e.target.value)}
                  >
                    <option value="CSTR Digester 1 Raft Foundation">CSTR Digester 1 Raft Foundation</option>
                    <option value="CSTR Digester 2 Cylindrical Shell">CSTR Digester 2 Cylindrical Shell</option>
                    <option value="High-Pressure Gas Compressor Plinth">High-Pressure Gas Compressor Plinth</option>
                    <option value="PSA Gas Upgradation Skid Platform">PSA Gas Upgradation Skid Platform</option>
                    <option value="Biomass Bunker Storage Pit">Biomass Bunker Storage Pit</option>
                    <option value="Elevated Slurry Piperack Trestles">Elevated Slurry Piperack Trestles</option>
                    <option value="Admin & Substation Building">Admin & Substation Building</option>
                  </select>
                </div>
              </div>
              <div className="inv-modal-footer">
                <button type="button" className="inv-btn-secondary" onClick={() => setIsUsageModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="inv-btn-primary">
                  <Save size={16} />
                  Confirm Structure Allocation
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* View Material Details Modal */}
      {isDetailModalOpen && selectedMaterial && (
        <div className="inv-modal-overlay" onClick={() => setIsDetailModalOpen(false)}>
          <div className="inv-modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: "650px" }}>
            <div className="inv-modal-header">
              <h2>Civil Material BOM Specification Sheet</h2>
              <button className="inv-modal-close" onClick={() => setIsDetailModalOpen(false)}>
                <X size={20} />
              </button>
            </div>
            <div className="inv-modal-body">
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px", marginBottom: "16px" }}>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Material Code</div>
                  <div style={{ fontWeight: "700", color: "#0f172a" }}>{selectedMaterial.code}</div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Category</div>
                  <div style={{ fontWeight: "600", color: "#2563eb" }}>{selectedMaterial.category}</div>
                </div>
                <div style={{ gridColumn: "span 2" }}>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Material Description</div>
                  <div style={{ fontWeight: "700", fontSize: "16px", color: "#0f172a" }}>{selectedMaterial.name}</div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Engineering Spec / Standard</div>
                  <div style={{ fontWeight: "600" }}>{selectedMaterial.gradeSpec}</div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Storage Yard Location</div>
                  <div style={{ fontWeight: "600" }}>{selectedMaterial.yardLocation}</div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Total BOM Required</div>
                  <div style={{ fontWeight: "700" }}>{selectedMaterial.bomRequiredQty} {selectedMaterial.uom}</div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Total Procured</div>
                  <div style={{ fontWeight: "700" }}>{selectedMaterial.procuredQty} {selectedMaterial.uom}</div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Currently Available in Yard</div>
                  <div style={{ fontWeight: "800", color: "#059669" }}>{selectedMaterial.currentStock} {selectedMaterial.uom}</div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Allocated to Structure</div>
                  <div style={{ fontWeight: "700", color: "#1e40af" }}>{selectedMaterial.allocatedQty} {selectedMaterial.uom}</div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Target Structure</div>
                  <div style={{ fontWeight: "600" }}>{selectedMaterial.allocatedStructure}</div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Unit Procurement Rate</div>
                  <div style={{ fontWeight: "600" }}>₹{selectedMaterial.unitCost.toLocaleString()} / {selectedMaterial.uom}</div>
                </div>
                <div style={{ gridColumn: "span 2" }}>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Approved Supplier / Mill</div>
                  <div style={{ fontWeight: "600" }}>{selectedMaterial.supplier}</div>
                </div>
                <div style={{ gridColumn: "span 2", backgroundColor: "#f8fafc", padding: "12px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>QA / Structural Notes</div>
                  <div style={{ fontSize: "13px", color: "#334155", marginTop: "4px" }}>{selectedMaterial.notes || "No additional quality notes."}</div>
                </div>
              </div>
            </div>
            <div className="inv-modal-footer">
              <button type="button" className="inv-btn-secondary" onClick={() => setIsDetailModalOpen(false)}>
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default CivilMaterialsBOM;

