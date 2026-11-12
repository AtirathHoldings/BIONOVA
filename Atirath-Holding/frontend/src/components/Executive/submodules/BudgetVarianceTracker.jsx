import React, { useState, useEffect } from "react";
import {
  DollarSign,
  Search,
  Filter,
  Plus,
  Download,
  AlertTriangle,
  TrendingDown,
  TrendingUp,
  CheckCircle2,
  Edit2,
  Trash2,
  Building,
  PieChart,
  X,
  Activity,
  ArrowUpRight,
  ArrowDownRight,
  ArrowLeft,
  Save
} from "lucide-react";
import { getBudgetItems, saveBudgetItem, deleteBudgetItem } from "./executiveApi";

const INITIAL_COST_CENTERS = [];

const BudgetVarianceTracker = () => {
  const [costCenters, setCostCenters] = useState(INITIAL_COST_CENTERS);

  useEffect(() => {
    getBudgetItems().then(data => {
      if (Array.isArray(data) && data.length > 0) setCostCenters(data);
    }).catch(err => console.warn("Failed to load budget items:", err));
  }, []);
  const [searchQuery, setSearchQuery] = useState("");
  const [natureFilter, setNatureFilter] = useState("All");
  const [plantFilter, setPlantFilter] = useState("All");
  const [varianceFilter, setVarianceFilter] = useState("All");
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState(null);

  const [formData, setFormData] = useState({
    id: "",
    name: "",
    nature: "CapEx",
    plant: "Plant 1 - Hyderabad East CBG",
    baselineBudget: "",
    actualIncurred: "",
    committedPO: "",
    leadDept: "Civil Engineering",
    notes: ""
  });

  const getVarianceDetails = (baseline, actual) => {
    const diff = actual - baseline;
    const pct = baseline > 0 ? (diff / baseline) * 100 : 0;
    const isOverrun = pct > 5.0; // > 5% overrun threshold
    const isUnder = pct < -1.0;
    return {
      diff,
      pct,
      isOverrun,
      isUnder,
      status: isOverrun
        ? "Cost Overrun (>5%)"
        : pct > 0
        ? "Mild Overrun (1-5%)"
        : isUnder
        ? "Favorable / Under Budget"
        : "On Track"
    };
  };

  const filteredItems = costCenters.filter((item) => {
    const matchesSearch =
      item.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.leadDept.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesNature = natureFilter === "All" || item.nature === natureFilter;
    const matchesPlant = plantFilter === "All" || item.plant.includes(plantFilter);

    const { isOverrun, isUnder } = getVarianceDetails(item.baselineBudget, item.actualIncurred);
    let matchesVariance = true;
    if (varianceFilter === "Overrun") matchesVariance = isOverrun;
    if (varianceFilter === "Under") matchesVariance = isUnder;

    return matchesSearch && matchesNature && matchesPlant && matchesVariance;
  });

  const totalBaseline = costCenters.reduce((sum, c) => sum + Number(c.baselineBudget || 0), 0);
  const totalActual = costCenters.reduce((sum, c) => sum + Number(c.actualIncurred || 0), 0);
  const netVariance = totalActual - totalBaseline;
  const netVariancePct = totalBaseline > 0 ? (netVariance / totalBaseline) * 100 : 0;

  const overrunAlertCount = costCenters.filter((c) => {
    const { isOverrun } = getVarianceDetails(c.baselineBudget, c.actualIncurred);
    return isOverrun;
  }).length;

  const handleOpenModal = (item = null) => {
    if (item) {
      setEditingItem(item);
      setFormData(item);
    } else {
      setEditingItem(null);
      const nextId = `CC-NEW-0${costCenters.length + 1}`;
      setFormData({
        id: nextId,
        name: "",
        nature: "CapEx",
        plant: "Plant 1 - Hyderabad East CBG",
        baselineBudget: "5.0",
        actualIncurred: "3.2",
        committedPO: "0.5",
        leadDept: "Plant Engineering",
        notes: ""
      });
    }
    setIsModalOpen(true);
  };

  const handleSave = (e) => {
    e.preventDefault();
    if (!formData.name) {
      alert("Please provide Cost Center Name.");
      return;
    }
    const cleanItem = {
      ...formData,
      baselineBudget: Number(formData.baselineBudget),
      actualIncurred: Number(formData.actualIncurred),
      committedPO: Number(formData.committedPO || 0)
    };

    if (editingItem) {
      setCostCenters((prev) =>
        prev.map((c) => (c.id === editingItem.id ? cleanItem : c))
      );
    } else {
      setCostCenters((prev) => [cleanItem, ...prev]);
    }
    setIsModalOpen(false);
  };

  const handleDelete = (id) => {
    if (window.confirm(`Delete cost center record ${id}?`)) {
      deleteBudgetItem(id).catch(err => console.warn(err));
      setCostCenters((prev) => prev.filter((c) => c.id !== id));
    }
  };

  const handleExportCSV = () => {
    const headers = "Cost Center ID,Name,Nature,Plant Project,Baseline Budget (Cr),Actual Incurred (Cr),Committed PO (Cr),Variance (Cr),Variance %,Status,Notes\n";
    const rows = filteredItems
      .map((c) => {
        const { diff, pct, status } = getVarianceDetails(c.baselineBudget, c.actualIncurred);
        return `"${c.id}","${c.name}","${c.nature}","${c.plant}","${c.baselineBudget}","${c.actualIncurred}","${c.committedPO}","${diff.toFixed(2)}","${pct.toFixed(1)}%","${status}","${c.notes}"`;
      })
      .join("\n");
    const blob = new Blob([headers + rows], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `BioNova_Budget_Variance_Matrix_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
  };

  return (
    <div style={{ paddingBottom: "30px" }}>
      {/* Header & Controls */}
      <div className="exec-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="exec-subtitle" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Granular cost-center tracking comparing baseline approved budgets against actual expenditures and encumbrances.
        </p>

        <div className="exec-controls" style={{ display: "flex", gap: "12px", alignItems: "center", flexShrink: 0, marginLeft: "auto" }}>
          <button className="exec-btn-print" onClick={handleExportCSV} style={{ background: "#059669" }}>
            <Download size={15} /> Export Variance CSV
          </button>
          <button className="exec-btn-print" onClick={() => handleOpenModal()}>
            <Plus size={16} /> Add Cost Center Record
          </button>
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
                <DollarSign size={22} color="#059669" />
                {editingItem ? "Edit Cost Center Budget" : "Add Cost Center Record"}
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Configure baseline allocations, actual incurred costs, committed purchase orders, and variance thresholds.
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
              <ArrowLeft size={16} /> Back to Budget Tracker
            </button>
          </div>

          <form onSubmit={handleSave} style={{ padding: "28px" }}>
            {/* Section 1: Cost Center Identification */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Building size={18} color="#059669" /> 1. Cost Center & Department Mapping
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Cost Center Code *
                  </label>
                  <input
                    type="text"
                    required
                    value={formData.id}
                    onChange={(e) => setFormData({ ...formData, id: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Expense Nature
                  </label>
                  <select
                    value={formData.nature}
                    onChange={(e) => setFormData({ ...formData, nature: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="CapEx">CapEx (Capital Expenditure)</option>
                    <option value="OpEx">OpEx (Operational Expenditure)</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Plant Facility
                  </label>
                  <select
                    value={formData.plant}
                    onChange={(e) => setFormData({ ...formData, plant: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Plant 1 - Hyderabad East CBG">Plant 1 - Hyderabad East CBG</option>
                    <option value="Plant 2 - Medak Agri Hub">Plant 2 - Medak Agri Hub</option>
                    <option value="Plant 3 - Nalgonda Facility">Plant 3 - Nalgonda Facility</option>
                    <option value="All Operations">All Operations / Corporate</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Lead Department
                  </label>
                  <input
                    type="text"
                    value={formData.leadDept}
                    onChange={(e) => setFormData({ ...formData, leadDept: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Cost Center Name / Description *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Gas Purification Membranes & Booster Trains"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>
              </div>
            </div>

            {/* Section 2: Financial Metrics */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <PieChart size={18} color="#2563eb" /> 2. Budget Allocations & Commitments
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Baseline Approved Budget (₹ Cr) *
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    required
                    value={formData.baselineBudget}
                    onChange={(e) => setFormData({ ...formData, baselineBudget: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Actual Incurred (₹ Cr) *
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    required
                    value={formData.actualIncurred}
                    onChange={(e) => setFormData({ ...formData, actualIncurred: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Committed / Encumbered PO (₹ Cr)
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    value={formData.committedPO}
                    onChange={(e) => setFormData({ ...formData, committedPO: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Variance Justification / Audit Notes
                  </label>
                  <textarea
                    rows={3}
                    placeholder="Provide justification if cost variance deviates beyond 5%..."
                    value={formData.notes}
                    onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box", resize: "vertical" }}
                  />
                </div>
              </div>
            </div>

            {/* Bottom Action Bar */}
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
                  padding: "10px 22px",
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
                  backgroundColor: "#059669",
                  color: "#ffffff",
                  fontWeight: "600",
                  cursor: "pointer",
                  fontSize: "13.5px",
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "8px",
                  boxShadow: "0 2px 6px rgba(5, 150, 105, 0.3)"
                }}
              >
                <Save size={16} />
                {editingItem ? "Update Cost Center" : "Save Record"}
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
      {overrunAlertCount > 0 && (
        <div style={{
          backgroundColor: "#fff7ed",
          border: "1px solid #fed7aa",
          borderLeft: "5px solid #ea580c",
          borderRadius: "10px",
          padding: "14px 18px",
          marginBottom: "20px",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          boxShadow: "0 1px 3px rgba(0,0,0,0.05)"
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
            <div style={{
              width: "36px",
              height: "36px",
              borderRadius: "50%",
              backgroundColor: "#ffedd5",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: "#c2410c"
            }}>
              <AlertTriangle size={20} />
            </div>
            <div>
              <div style={{ fontWeight: "700", color: "#9a3412", fontSize: "14px" }}>
                Executive Budget Overrun Threshold Trigger ({overrunAlertCount} Cost Centers &gt; 5% Overrun)
              </div>
              <div style={{ fontSize: "12px", color: "#7c2d12" }}>
                {overrunAlertCount} cost center records have exceeded approved tolerance limits.
              </div>
            </div>
          </div>
          <button
            onClick={() => setVarianceFilter("Overrun")}
            style={{
              backgroundColor: "#ea580c",
              color: "#ffffff",
              border: "none",
              padding: "6px 14px",
              borderRadius: "6px",
              fontSize: "12px",
              fontWeight: "600",
              cursor: "pointer"
            }}
          >
            Filter Overruns
          </button>
        </div>
      )}

      {/* KPI Stats */}
      <div className="exec-fin-metrics" style={{ gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))", marginBottom: "24px" }}>
        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">APPROVED BASELINE BUDGET</div>
          <div className="exec-fin-tile-val">₹{totalBaseline.toFixed(1)} Cr</div>
          <div className="exec-fin-tile-sub" style={{ color: "#2563eb" }}>
            CapEx: ₹{costCenters.filter(c => c.nature === 'CapEx').reduce((s, c) => s + Number(c.baselineBudget || 0), 0).toFixed(1)} Cr • OpEx: ₹{costCenters.filter(c => c.nature === 'OpEx').reduce((s, c) => s + Number(c.baselineBudget || 0), 0).toFixed(1)} Cr
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">ACTUAL CAPITAL INCURRED</div>
          <div className="exec-fin-tile-val">₹{totalActual.toFixed(1)} Cr</div>
          <div className="exec-fin-tile-sub" style={{ color: totalActual <= totalBaseline ? "#059669" : "#dc2626" }}>
            Utilization Rate: {totalBaseline > 0 ? `${Math.round((totalActual / totalBaseline) * 100)}%` : "0%"}
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">NET PORTFOLIO VARIANCE</div>
          <div className="exec-fin-tile-val" style={{ color: netVariance <= 0 ? "#059669" : "#dc2626" }}>
            {totalBaseline > 0 ? `${netVariance <= 0 ? "-" : "+"}₹${Math.abs(netVariance).toFixed(2)} Cr` : "₹0.00 Cr"}
          </div>
          <div className="exec-fin-tile-sub" style={{ color: netVariance <= 0 ? "#059669" : "#dc2626" }}>
            {totalBaseline > 0 ? (
              <>
                {netVariancePct <= 0 ? <TrendingDown size={14} /> : <TrendingUp size={14} />} {Math.abs(netVariancePct).toFixed(1)}% {netVariance <= 0 ? "Favorable Savings" : "Over Budget"}
              </>
            ) : (
              "No Active Variances"
            )}
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">CRITICAL OVERRUN WATCH (&gt;5%)</div>
          <div className="exec-fin-tile-val" style={{ color: overrunAlertCount > 0 ? "#ea580c" : "#059669" }}>
            {overrunAlertCount} Centers
          </div>
          <div className="exec-fin-tile-sub" style={{ color: "#64748b" }}>
            {overrunAlertCount > 0 ? "Requires Audit Approval" : "Zero Cost Overruns"}
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div style={{
        background: "#ffffff",
        borderRadius: "12px",
        padding: "16px 20px",
        border: "1px solid #e2e8f0",
        marginBottom: "20px",
        display: "flex",
        flexWrap: "wrap",
        gap: "14px",
        alignItems: "center",
        justifyContent: "space-between"
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: "10px", flex: 1, minWidth: "260px" }}>
          <div style={{
            display: "flex",
            alignItems: "center",
            background: "#f1f5f9",
            borderRadius: "8px",
            padding: "8px 12px",
            flex: 1,
            gap: "8px"
          }}>
            <Search size={16} color="#64748b" />
            <input
              type="text"
              placeholder="Search by cost center name, code, or department..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{
                border: "none",
                background: "transparent",
                outline: "none",
                fontSize: "13px",
                width: "100%",
                color: "#0f172a"
              }}
            />
          </div>
        </div>

        <div style={{ display: "flex", gap: "10px", flexWrap: "wrap" }}>
          <select
            className="exec-select"
            value={natureFilter}
            onChange={(e) => setNatureFilter(e.target.value)}
          >
            <option value="All">All Expenses (CapEx & OpEx)</option>
            <option value="CapEx">CapEx Only</option>
            <option value="OpEx">OpEx Only</option>
          </select>

          <select
            className="exec-select"
            value={plantFilter}
            onChange={(e) => setPlantFilter(e.target.value)}
          >
            <option value="All">All Plants & Facilities</option>
            <option value="Hyderabad">Hyderabad East</option>
            <option value="Medak">Medak Hub</option>
            <option value="Nalgonda">Nalgonda Facility</option>
          </select>

          <select
            className="exec-select"
            value={varianceFilter}
            onChange={(e) => setVarianceFilter(e.target.value)}
          >
            <option value="All">All Variances</option>
            <option value="Overrun">Overruns (&gt; 5%)</option>
            <option value="Under">Under Budget (Savings)</option>
          </select>
        </div>
      </div>

      {/* Ledger Table */}
      <div className="exec-card" style={{ padding: "0", overflow: "hidden" }}>
        <div style={{ padding: "16px 20px", borderBottom: "1px solid #f1f5f9", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <h3 style={{ margin: 0, fontSize: "15px", fontWeight: "700", color: "#0f172a" }}>
            Cost-Center Variance Matrix ({filteredItems.length})
          </h3>
          <span style={{ fontSize: "12px", color: "#64748b" }}>
            Threshold: Overrun flagged when variance exceeds +5.0%
          </span>
        </div>

        <div style={{ overflowX: "auto" }}>
          <table className="exec-dept-table" style={{ margin: 0 }}>
            <thead>
              <tr>
                <th>Cost Center & Department</th>
                <th>Classification</th>
                <th>Baseline Budget</th>
                <th>Actual Incurred</th>
                <th>Committed PO</th>
                <th>Variance (₹ & %)</th>
                <th>Variance Health</th>
                <th style={{ textAlign: "right" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredItems.length === 0 ? (
                <tr>
                  <td colSpan="8" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                    No cost center records match the current filters.
                  </td>
                </tr>
              ) : (
                filteredItems.map((c) => {
                  const { diff, pct, isOverrun, isUnder, status } = getVarianceDetails(c.baselineBudget, c.actualIncurred);
                  return (
                    <tr key={c.id}>
                      <td>
                        <div style={{ fontWeight: "700", color: "#0f172a", fontSize: "13px" }}>{c.name}</div>
                        <div style={{ fontSize: "11px", color: "#64748b", fontFamily: "monospace" }}>{c.id} • {c.leadDept}</div>
                        <div style={{ fontSize: "11px", color: "#2563eb", marginTop: "2px" }}>{c.plant}</div>
                      </td>
                      <td>
                        <span style={{
                          display: "inline-block",
                          padding: "2px 8px",
                          borderRadius: "4px",
                          fontSize: "11px",
                          fontWeight: "700",
                          backgroundColor: c.nature === "CapEx" ? "#eff6ff" : "#f0fdf4",
                          color: c.nature === "CapEx" ? "#1e40af" : "#15803d"
                        }}>
                          {c.nature}
                        </span>
                      </td>
                      <td>
                        <div style={{ fontWeight: "700", color: "#0f172a", fontSize: "13px" }}>₹{c.baselineBudget.toFixed(2)} Cr</div>
                      </td>
                      <td>
                        <div style={{ fontWeight: "700", color: "#0f172a", fontSize: "13px" }}>₹{c.actualIncurred.toFixed(2)} Cr</div>
                        <div style={{ fontSize: "11px", color: "#64748b" }}>
                          {Math.round((c.actualIncurred / c.baselineBudget) * 100)}% utilized
                        </div>
                      </td>
                      <td>
                        <div style={{ fontSize: "13px", color: "#475569" }}>₹{c.committedPO.toFixed(2)} Cr</div>
                      </td>
                      <td>
                        <div style={{
                          fontWeight: "700",
                          fontSize: "13px",
                          color: isOverrun ? "#ea580c" : isUnder ? "#059669" : "#0f172a"
                        }}>
                          {diff > 0 ? `+₹${diff.toFixed(2)} Cr` : diff < 0 ? `-₹${Math.abs(diff).toFixed(2)} Cr` : "₹0.00 Cr"}
                        </div>
                        <div style={{
                          fontSize: "11px",
                          fontWeight: "600",
                          color: isOverrun ? "#ea580c" : isUnder ? "#059669" : "#64748b"
                        }}>
                          {pct > 0 ? `+${pct.toFixed(1)}%` : `${pct.toFixed(1)}%`}
                        </div>
                      </td>
                      <td>
                        <span style={{
                          display: "inline-block",
                          padding: "3px 8px",
                          borderRadius: "6px",
                          fontSize: "11px",
                          fontWeight: "700",
                          backgroundColor: isOverrun ? "#fee2e2" : isUnder ? "#dcfce7" : "#f1f5f9",
                          color: isOverrun ? "#991b1b" : isUnder ? "#166534" : "#475569"
                        }}>
                          {status}
                        </span>
                      </td>
                      <td style={{ textAlign: "right" }}>
                        <div style={{ display: "flex", justifyContent: "flex-end", gap: "6px" }}>
                          <button
                            onClick={() => handleOpenModal(c)}
                            title="Edit Record"
                            style={{ border: "none", background: "#f1f5f9", borderRadius: "6px", padding: "6px", cursor: "pointer", color: "#059669" }}
                          >
                            <Edit2 size={15} />
                          </button>
                          <button
                            onClick={() => handleDelete(c.id)}
                            title="Delete Record"
                            style={{ border: "none", background: "#f1f5f9", borderRadius: "6px", padding: "6px", cursor: "pointer", color: "#dc2626" }}
                          >
                            <Trash2 size={15} />
                          </button>
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
    </div>
  );
};

export default BudgetVarianceTracker;
