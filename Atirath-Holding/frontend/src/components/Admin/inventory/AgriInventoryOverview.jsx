import React, { useState, useEffect } from "react";
import {
  Boxes,
  Plus,
  Search,
  Filter,
  Download,
  AlertTriangle,
  CheckCircle2,
  PackageX,
  TrendingDown,
  Edit2,
  Trash2,
  Eye,
  RefreshCw,
  Calendar,
  Layers,
  Sprout,
  FlaskConical,
  Wrench,
  X,
  Save,
  ArrowUpDown,
  ArrowLeft
} from "lucide-react";
import { getInventoryItems, saveInventoryItem, deleteInventoryItem } from "./inventoryApi";

const STORAGE_KEY = "bionova_inventory_items_v1";
try { const _raw = localStorage.getItem(STORAGE_KEY); if (_raw && (_raw.includes("INV-") || _raw.includes("CIV-") || _raw.includes("FST-") || _raw.includes("BN-") || _raw.includes("UltraTech") || _raw.includes("Neuman"))) { localStorage.removeItem(STORAGE_KEY); } } catch(e){}

const INITIAL_ITEMS = [];

const AgriInventoryOverview = ({ screenPerm }) => {
  // Inventory state
  const [items, setItems] = useState([]);

  // Filter & Search states
  const [searchTerm, setSearchTerm] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("All");
  const [statusFilter, setStatusFilter] = useState("All");
  const [plantFilter, setPlantFilter] = useState("All");

  // Modal states
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDetailModalOpen, setIsDetailModalOpen] = useState(false);
  const [isAdjustModalOpen, setIsAdjustModalOpen] = useState(false);
  const [selectedItem, setSelectedItem] = useState(null);
  const [modalMode, setModalMode] = useState("add"); // 'add' or 'edit'

  // Adjustment form state
  const [adjustmentQty, setAdjustmentQty] = useState("");
  const [adjustmentType, setAdjustmentType] = useState("add"); // 'add' or 'subtract'
  const [adjustmentReason, setAdjustmentReason] = useState("Received Shipment");

  // Add/Edit Form State
  const [formData, setFormData] = useState({
    sku: "",
    name: "",
    category: "Seeds",
    batchNo: "",
    currentStock: 0,
    reorderThreshold: 10,
    uom: "Kg",
    plantLocation: "Plant 1 - Hyderabad East CBG",
    unitCost: 0,
    expiryDate: "",
    supplier: "",
    notes: ""
  });

  // Persist items
  useEffect(() => {
    getInventoryItems().then(data => {
      if (Array.isArray(data) && data.length > 0) setItems(data);
    }).catch(err => console.warn("Failed to load inventory items:", err));
  }, []);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
    } catch (e) {
      console.warn("Failed to save inventory to storage", e);
    }
  }, [items]);

  // Status helper
  const getStockStatus = (current, threshold) => {
    if (Number(current) <= 0) return { label: "Out of Stock", class: "inv-status-outstock" };
    if (Number(current) <= Number(threshold)) return { label: "Low Stock", class: "inv-status-lowstock" };
    return { label: "In Stock", class: "inv-status-instock" };
  };

  // KPIs
  const totalItemsCount = items.length;
  const totalAssetVal = items.reduce((sum, item) => sum + (Number(item.currentStock) * Number(item.unitCost || 0)), 0);
  const lowStockCount = items.filter(i => Number(i.currentStock) > 0 && Number(i.currentStock) <= Number(i.reorderThreshold)).length;
  const outOfStockCount = items.filter(i => Number(i.currentStock) <= 0).length;

  // Filtered List
  const filteredItems = items.filter(item => {
    const matchesSearch =
      item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.sku.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.batchNo.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.supplier.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesCategory = categoryFilter === "All" || item.category === categoryFilter;
    const matchesPlant = plantFilter === "All" || item.plantLocation === plantFilter;

    let matchesStatus = true;
    const status = getStockStatus(item.currentStock, item.reorderThreshold).label;
    if (statusFilter !== "All") {
      matchesStatus = status === statusFilter;
    }

    return matchesSearch && matchesCategory && matchesPlant && matchesStatus;
  });

  // Open Add Modal
  const handleOpenAddModal = () => {
    setModalMode("add");
    setFormData({
      sku: `INV-${Date.now().toString().slice(-6)}`,
      name: "",
      category: "Seeds",
      batchNo: `BN-LOT-${new Date().getFullYear()}-${Math.floor(100 + Math.random() * 900)}`,
      currentStock: 100,
      reorderThreshold: 20,
      uom: "Kg",
      plantLocation: "Plant 1 - Hyderabad East CBG",
      unitCost: 50,
      expiryDate: "",
      supplier: "",
      notes: ""
    });
    setIsModalOpen(true);
  };

  // Open Edit Modal
  const handleOpenEditModal = (item) => {
    setModalMode("edit");
    setSelectedItem(item);
    setFormData({ ...item });
    setIsModalOpen(true);
  };

  // Open Details Modal
  const handleOpenDetailModal = (item) => {
    setSelectedItem(item);
    setIsDetailModalOpen(true);
  };

  // Open Adjust Modal
  const handleOpenAdjustModal = (item) => {
    setSelectedItem(item);
    setAdjustmentQty("");
    setAdjustmentType("add");
    setAdjustmentReason("Received Shipment");
    setIsAdjustModalOpen(true);
  };

  // Save Item (Add or Edit)
  const handleSaveItem = (e) => {
    e.preventDefault();
    if (!formData.name.trim()) {
      alert("Please enter an item name.");
      return;
    }

    if (modalMode === "add") {
      const newItem = {
        ...formData,
        id: Date.now(),
        currentStock: Number(formData.currentStock),
        reorderThreshold: Number(formData.reorderThreshold),
        unitCost: Number(formData.unitCost)
      };
      saveInventoryItem(newItem).then(res => {
        setItems(prev => [res || newItem, ...prev.filter(i => i.id !== newItem.id)]);
      }).catch(err => console.warn(err));
      setItems([newItem, ...items]);
    } else {
      setItems(items.map(it => it.id === selectedItem.id ? {
        ...formData,
        currentStock: Number(formData.currentStock),
        reorderThreshold: Number(formData.reorderThreshold),
        unitCost: Number(formData.unitCost)
      } : it));
    }
    setIsModalOpen(false);
  };

  // Apply Quick Stock Adjustment
  const handleApplyAdjustment = (e) => {
    e.preventDefault();
    const qty = Number(adjustmentQty);
    if (isNaN(qty) || qty <= 0) {
      alert("Please enter a valid positive quantity.");
      return;
    }

    setItems(items.map(it => {
      if (it.id === selectedItem.id) {
        const updatedStock = adjustmentType === "add"
          ? it.currentStock + qty
          : Math.max(0, it.currentStock - qty);
        return { ...it, currentStock: updatedStock };
      }
      return it;
    }));
    setIsAdjustModalOpen(false);
  };

  // Delete Item
  const handleDeleteItem = (id) => {
    if (window.confirm("Are you sure you want to delete this inventory item?")) {
      deleteInventoryItem(id).catch(err => console.warn(err));
      setItems(items.filter(it => it.id !== id));
    }
  };

  // Export CSV
  const handleExportCSV = () => {
    const headers = ["SKU", "Item Name", "Category", "Batch No", "Stock", "UOM", "Threshold", "Plant Location", "Unit Cost (INR)", "Total Value (INR)", "Expiry Date", "Supplier"];
    const rows = filteredItems.map(it => [
      it.sku,
      `"${it.name.replace(/"/g, '""')}"`,
      it.category,
      it.batchNo,
      it.currentStock,
      it.uom,
      it.reorderThreshold,
      `"${it.plantLocation}"`,
      it.unitCost,
      it.currentStock * it.unitCost,
      it.expiryDate || "N/A",
      `"${it.supplier || ""}"`
    ]);

    const csvContent = "data:text/csv;charset=utf-8," + [headers.join(","), ...rows.map(e => e.join(","))].join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `bionova_inventory_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const getCategoryIcon = (cat) => {
    if (cat === "Seeds") return <Sprout size={14} />;
    if (cat === "Agrochemicals") return <FlaskConical size={14} />;
    return <Wrench size={14} />;
  };

  const getCategoryBadgeClass = (cat) => {
    if (cat === "Seeds") return "inv-badge-category inv-badge-seeds";
    if (cat === "Agrochemicals") return "inv-badge-category inv-badge-agro";
    return "inv-badge-category inv-badge-equipment";
  };

  return (
    <div className="submod-wrapper">
      {/* Header Title Section */}
      <div className="inv-header-section" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="inv-subtitle" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Track seeds, agrochemicals, processing equipment, batch numbers, stock levels, and automated reorder alerts.
        </p>
        <div className="inv-header-actions" style={{ display: "flex", gap: "12px", alignItems: "center", flexShrink: 0, marginLeft: "auto" }}>
          <button className="inv-btn-secondary" onClick={handleExportCSV}>
            <Download size={16} />
            Export CSV
          </button>
          {screenPerm.canCreate && (
            <button className="inv-btn-primary" onClick={handleOpenAddModal}>
              <Plus size={16} />
              Add New Inventory Item
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
                <Boxes size={22} color="#1677ff" />
                {modalMode === "add" ? "Add New Inventory Item" : "Edit Inventory Item"}
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Enter feedstock details, SKU code, batch numbers, plant location, and inventory thresholds below.
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
              <ArrowLeft size={16} /> Back to Agri Inventory
            </button>
          </div>

          <form onSubmit={handleSaveItem} style={{ padding: "28px" }}>
            {/* Section 1: Item Identification & Category */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Boxes size={18} color="#1677ff" /> 1. Item Identification & SKU Classification
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    SKU Code *
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
                    <option value="Seeds">Seeds</option>
                    <option value="Agrochemicals">Agrochemicals</option>
                    <option value="Equipment">Equipment</option>
                  </select>
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Item Name *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Napier Grass Hybrid Stems"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Batch / Lot Number *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. BN-NPR-2026-B1"
                    value={formData.batchNo}
                    onChange={(e) => setFormData({ ...formData, batchNo: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Plant Location *
                  </label>
                  <select
                    value={formData.plantLocation}
                    onChange={(e) => setFormData({ ...formData, plantLocation: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Plant 1 - Hyderabad East CBG">Plant 1 - Hyderabad East CBG</option>
                    <option value="Plant 2 - Medak Agri Hub">Plant 2 - Medak Agri Hub</option>
                    <option value="Plant 3 - Nalgonda Biomass Facility">Plant 3 - Nalgonda Biomass Facility</option>
                  </select>
                </div>
              </div>
            </div>

            {/* Section 2: Stock Levels & Valuation */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Layers size={18} color="#059669" /> 2. Inventory Quantities, Reorder Threshold & Unit Economics
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
                    Reorder Minimum Threshold *
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
                    Unit of Measure (UOM) *
                  </label>
                  <select
                    value={formData.uom}
                    onChange={(e) => setFormData({ ...formData, uom: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Kg">Kg</option>
                    <option value="Liters">Liters</option>
                    <option value="Units">Units</option>
                    <option value="Stems">Stems</option>
                    <option value="Meters">Meters</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Unit Cost (INR ₹)
                  </label>
                  <input
                    type="number"
                    min="0"
                    value={formData.unitCost}
                    onChange={(e) => setFormData({ ...formData, unitCost: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Expiry Date
                  </label>
                  <input
                    type="date"
                    value={formData.expiryDate}
                    onChange={(e) => setFormData({ ...formData, expiryDate: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Supplier / Manufacturer
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. Agritech Agro Seeds Ltd"
                    value={formData.supplier}
                    onChange={(e) => setFormData({ ...formData, supplier: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Operational & Storage Notes
                  </label>
                  <textarea
                    rows={3}
                    placeholder="Usage context, safety notes, storage instructions..."
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
                <Save size={16} /> {modalMode === "add" ? "Create Inventory Item" : "Save Changes"}
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* KPI Summary Cards */}
      <div className="inv-kpi-grid">
        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#ecfdf5", color: "#059669" }}>
            <Boxes size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Total Tracked Items</h3>
            <div className="inv-kpi-value">{totalItemsCount} SKUs</div>
            <p className="inv-kpi-subtext">Across 3 Plant Sites</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#eff6ff", color: "#2563eb" }}>
            <Layers size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Total Valuation</h3>
            <div className="inv-kpi-value">₹{totalAssetVal.toLocaleString("en-IN")}</div>
            <p className="inv-kpi-subtext">Current Stock Asset Value</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#fef3c7", color: "#d97706" }}>
            <AlertTriangle size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Low Stock Warnings</h3>
            <div className="inv-kpi-value">{lowStockCount} Items</div>
            <p className="inv-kpi-subtext">Below Reorder Threshold</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#fee2e2", color: "#dc2626" }}>
            <PackageX size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Depleted Stock</h3>
            <div className="inv-kpi-value">{outOfStockCount} Items</div>
            <p className="inv-kpi-subtext">Requires immediate restock</p>
          </div>
        </div>
      </div>

      {/* Search & Filter Controls */}
      <div className="inv-controls-card">
        <div className="inv-controls-row">
          <div className="inv-search-box">
            <Search size={18} className="inv-search-icon" />
            <input
              type="text"
              className="inv-search-input"
              placeholder="Search by SKU, item name, batch number, or supplier..."
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
              <option value="Seeds">🌱 Seeds & Propagation</option>
              <option value="Agrochemicals">🧪 Agrochemicals & Nutrients</option>
              <option value="Equipment">⚙️ Equipment & Spares</option>
            </select>

            <select
              className="inv-select"
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
            >
              <option value="All">All Stock Levels</option>
              <option value="In Stock">In Stock (Healthy)</option>
              <option value="Low Stock">Low Stock Alert</option>
              <option value="Out of Stock">Out of Stock</option>
            </select>

            <select
              className="inv-select"
              value={plantFilter}
              onChange={(e) => setPlantFilter(e.target.value)}
            >
              <option value="All">All Plant Locations</option>
              <option value="Plant 1 - Hyderabad East CBG">Plant 1 - Hyderabad East CBG</option>
              <option value="Plant 2 - Medak Agri Hub">Plant 2 - Medak Agri Hub</option>
              <option value="Plant 3 - Nalgonda Biomass Facility">Plant 3 - Nalgonda Biomass Facility</option>
            </select>
          </div>
        </div>
      </div>

      {/* Inventory Table */}
      <div className="inv-table-card">
        <div className="inv-table-wrapper">
          <table className="inv-table">
            <thead>
              <tr>
                <th>Item & SKU</th>
                <th>Category</th>
                <th>Batch / Lot No</th>
                <th>Current Stock</th>
                <th>Reorder Threshold</th>
                <th>Location</th>
                <th>Expiry Date</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredItems.length === 0 ? (
                <tr>
                  <td colSpan="9" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                    No inventory records match the selected filters.
                  </td>
                </tr>
              ) : (
                filteredItems.map((item) => {
                  const statusInfo = getStockStatus(item.currentStock, item.reorderThreshold);
                  return (
                    <tr key={item.id}>
                      <td>
                        <div className="inv-item-name">{item.name}</div>
                        <div className="inv-item-sku">{item.sku}</div>
                      </td>
                      <td>
                        <span className={getCategoryBadgeClass(item.category)}>
                          {getCategoryIcon(item.category)}
                          {item.category}
                        </span>
                      </td>
                      <td>
                        <span className="inv-batch-text">{item.batchNo}</span>
                      </td>
                      <td>
                        <span className="inv-stock-qty">{item.currentStock.toLocaleString()}</span>{" "}
                        <span className="inv-stock-uom">{item.uom}</span>
                      </td>
                      <td>
                        <span className="inv-threshold-text">
                          {item.reorderThreshold.toLocaleString()} {item.uom}
                        </span>
                      </td>
                      <td>
                        <span className="inv-location-text">{item.plantLocation}</span>
                      </td>
                      <td>
                        <span className="inv-date-text">{item.expiryDate || "N/A"}</span>
                      </td>
                      <td>
                        <span className={`inv-status-pill ${
                          statusInfo.label === "In Stock" ? "inv-status-in" :
                          statusInfo.label === "Low Stock" ? "inv-status-low" : "inv-status-out"
                        }`}>
                          {statusInfo.label}
                        </span>
                      </td>
                      <td>
                        <div className="inv-table-actions">
                          {screenPerm.canEdit && (
                            <button
                              className="inv-icon-btn"
                              title="Quick Stock Adjustment (+/-)"
                              onClick={() => handleOpenAdjustModal(item)}
                            >
                              <ArrowUpDown size={15} color="#3b82f6" />
                            </button>
                          )}
                          <button
                            className="inv-icon-btn"
                            title="View Details"
                            onClick={() => handleOpenDetailModal(item)}
                          >
                            <Eye size={15} />
                          </button>
                          {screenPerm.canEdit && (
                            <button
                              className="inv-icon-btn"
                              title="Edit Item"
                              onClick={() => handleOpenEditModal(item)}
                            >
                              <Edit2 size={15} />
                            </button>
                          )}
                          {screenPerm.canDelete && (
                            <button
                              className="inv-icon-btn danger"
                              title="Delete Item"
                              onClick={() => handleDeleteItem(item.id)}
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

      {/* Quick Adjustment Modal */}
      {isAdjustModalOpen && selectedItem && (
        <div className="inv-modal-overlay" onClick={() => setIsAdjustModalOpen(false)}>
          <div className="inv-modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: "500px" }}>
            <div className="inv-modal-header">
              <h2>Quick Stock Adjustment</h2>
              <button className="inv-modal-close" onClick={() => setIsAdjustModalOpen(false)}>
                <X size={20} />
              </button>
            </div>
            <form onSubmit={handleApplyAdjustment}>
              <div className="inv-modal-body">
                <div style={{ backgroundColor: "#f8fafc", padding: "14px", borderRadius: "8px", marginBottom: "16px", border: "1px solid #e2e8f0" }}>
                  <div style={{ fontWeight: "700", color: "#0f172a" }}>{selectedItem.name}</div>
                  <div style={{ fontSize: "13px", color: "#64748b", marginTop: "4px" }}>
                    Current Stock: <strong style={{ color: "#1677ff" }}>{selectedItem.currentStock} {selectedItem.uom}</strong>
                  </div>
                </div>

                <div className="inv-form-group" style={{ marginBottom: "16px" }}>
                  <label>Adjustment Type</label>
                  <div style={{ display: "flex", gap: "12px", marginTop: "6px" }}>
                    <label style={{ display: "flex", alignItems: "center", gap: "6px", cursor: "pointer", fontWeight: "600", fontSize: "14px" }}>
                      <input
                        type="radio"
                        name="adjType"
                        value="add"
                        checked={adjustmentType === "add"}
                        onChange={() => setAdjustmentType("add")}
                      />
                      Add Inward Stock (+)
                    </label>
                    <label style={{ display: "flex", alignItems: "center", gap: "6px", cursor: "pointer", fontWeight: "600", fontSize: "14px" }}>
                      <input
                        type="radio"
                        name="adjType"
                        value="subtract"
                        checked={adjustmentType === "subtract"}
                        onChange={() => setAdjustmentType("subtract")}
                      />
                      Deduct Outward Usage (-)
                    </label>
                  </div>
                </div>

                <div className="inv-form-group" style={{ marginBottom: "16px" }}>
                  <label>Quantity to {adjustmentType === "add" ? "Add" : "Deduct"} ({selectedItem.uom})</label>
                  <input
                    type="number"
                    className="inv-input"
                    value={adjustmentQty}
                    onChange={(e) => setAdjustmentQty(e.target.value)}
                    placeholder="Enter quantity"
                    min="1"
                    required
                  />
                </div>

                <div className="inv-form-group">
                  <label>Reason for Adjustment</label>
                  <select
                    className="inv-select"
                    value={adjustmentReason}
                    onChange={(e) => setAdjustmentReason(e.target.value)}
                  >
                    <option value="Received Shipment">Received Shipment from Vendor</option>
                    <option value="Transferred to Field">Dispatched to Farmland / Digester</option>
                    <option value="Cycle Count Variance">Audit / Physical Count Variance</option>
                    <option value="Damaged / Spoiled">Damaged or Expired Stock Write-off</option>
                  </select>
                </div>
              </div>
              <div className="inv-modal-footer">
                <button type="button" className="inv-btn-secondary" onClick={() => setIsAdjustModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="inv-btn-primary">
                  <CheckCircle2 size={16} />
                  Apply Adjustment
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Details View Modal */}
      {isDetailModalOpen && selectedItem && (
        <div className="inv-modal-overlay" onClick={() => setIsDetailModalOpen(false)}>
          <div className="inv-modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: "600px" }}>
            <div className="inv-modal-header">
              <h2>Inventory Item Details</h2>
              <button className="inv-modal-close" onClick={() => setIsDetailModalOpen(false)}>
                <X size={20} />
              </button>
            </div>
            <div className="inv-modal-body">
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px", marginBottom: "16px" }}>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>SKU Code</div>
                  <div style={{ fontWeight: "700", color: "#0f172a" }}>{selectedItem.sku}</div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Category</div>
                  <div style={{ fontWeight: "600", color: "#1677ff" }}>{selectedItem.category}</div>
                </div>
                <div style={{ gridColumn: "span 2" }}>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Item Name</div>
                  <div style={{ fontWeight: "700", fontSize: "16px", color: "#0f172a" }}>{selectedItem.name}</div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Batch / Lot Number</div>
                  <div style={{ fontWeight: "600" }}>{selectedItem.batchNo}</div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Plant Facility</div>
                  <div style={{ fontWeight: "600" }}>{selectedItem.plantLocation}</div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Current On-Hand Stock</div>
                  <div style={{ fontWeight: "800", fontSize: "16px", color: "#059669" }}>
                    {selectedItem.currentStock} {selectedItem.uom}
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Minimum Threshold</div>
                  <div style={{ fontWeight: "600" }}>{selectedItem.reorderThreshold} {selectedItem.uom}</div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Unit Cost</div>
                  <div style={{ fontWeight: "600" }}>₹{selectedItem.unitCost || 0}</div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Total Valuation</div>
                  <div style={{ fontWeight: "700", color: "#0f172a" }}>
                    ₹{((selectedItem.currentStock || 0) * (selectedItem.unitCost || 0)).toLocaleString("en-IN")}
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Expiry Date</div>
                  <div style={{ fontWeight: "600" }}>{selectedItem.expiryDate || "N/A"}</div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Supplier</div>
                  <div style={{ fontWeight: "600" }}>{selectedItem.supplier || "N/A"}</div>
                </div>
                <div style={{ gridColumn: "span 2", backgroundColor: "#f8fafc", padding: "12px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>Notes</div>
                  <div style={{ fontSize: "13px", color: "#334155", marginTop: "4px" }}>{selectedItem.notes || "None."}</div>
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

export default AgriInventoryOverview;

