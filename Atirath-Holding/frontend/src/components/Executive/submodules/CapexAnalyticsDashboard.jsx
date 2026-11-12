import React, { useState, useEffect } from "react";
import {
  Gauge,
  Search,
  Filter,
  Plus,
  Download,
  DollarSign,
  TrendingUp,
  Activity,
  Layers,
  CheckCircle2,
  Clock,
  AlertTriangle,
  Edit2,
  Trash2,
  X,
  Building,
  Flame,
  Zap,
  ArrowUpRight,
  Printer,
  ArrowLeft,
  Save
} from "lucide-react";
import { getPipelineProjects } from "./executiveApi";

const INITIAL_ANALYTICS = [];

const CapexAnalyticsDashboard = () => {
  const [data, setData] = useState([]);

  useEffect(() => {
    getPipelineProjects().then((projects) => {
      if (Array.isArray(projects) && projects.length > 0) {
        setData(projects.map(p => ({
          id: p.projectCode || p.id,
          project: p.name,
          engineeringPackage: p.upcomingMilestone || p.stage || "Civil Works",
          approvedCapex: Number(p.capexApproved || 0),
          actualSpent: Number(p.capexSpent || 0),
          plannedProgress: Number(p.completionPct || 0),
          actualProgress: Number(p.completionPct || 0),
          monthlyBurn: 0,
          digesterCapacity: p.capacity || "",
          gasCompressionSkid: "",
          plannedFinish: p.targetCommissioning || "",
          health: p.status || "On Track",
          leadEngineer: p.leadPM || ""
        })));
      }
    }).catch(err => console.warn("Failed to load capex projects:", err));
  }, []);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("All");
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState(null);

  const [formData, setFormData] = useState({
    id: "",
    project: "Plant 1 - Hyderabad East CBG",
    engineeringPackage: "",
    approvedCapex: "",
    actualSpent: "",
    plannedProgress: 80,
    actualProgress: 80,
    monthlyBurn: "1.5",
    digesterCapacity: "",
    gasCompressionSkid: "",
    plannedFinish: "",
    health: "On Schedule",
    leadEngineer: ""
  });

  const filteredData = data.filter((item) => {
    const matchesSearch =
      item.project.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.engineeringPackage.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.leadEngineer.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.id.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStatus = statusFilter === "All" || item.health === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const totalCapex = data.reduce((s, i) => s + Number(i.approvedCapex || 0), 0);
  const totalSpent = data.reduce((s, i) => s + Number(i.actualSpent || 0), 0);
  const totalBurn = data.reduce((s, i) => s + Number(i.monthlyBurn || 0), 0);
  const avgActualProgress = Math.round(
    data.reduce((s, i) => s + Number(i.actualProgress || 0), 0) / (data.length || 1)
  );

  const handleOpenModal = (item = null) => {
    if (item) {
      setEditingItem(item);
      setFormData(item);
    } else {
      setEditingItem(null);
      const nextId = `ENG-PLANT-0${data.length + 1}`;
      setFormData({
        id: nextId,
        project: "Plant 1 - Hyderabad East CBG",
        engineeringPackage: "",
        approvedCapex: "",
        actualSpent: "",
        plannedProgress: 0,
        actualProgress: 0,
        monthlyBurn: "",
        digesterCapacity: "",
        gasCompressionSkid: "",
        plannedFinish: "",
        health: "On Schedule",
        leadEngineer: ""
      });
    }
    setIsModalOpen(true);
  };

  const handleSave = (e) => {
    e.preventDefault();
    if (!formData.engineeringPackage || !formData.project) {
      alert("Please provide Engineering Package and Project.");
      return;
    }
    const cleanItem = {
      ...formData,
      approvedCapex: Number(formData.approvedCapex),
      actualSpent: Number(formData.actualSpent),
      plannedProgress: Number(formData.plannedProgress),
      actualProgress: Number(formData.actualProgress),
      monthlyBurn: Number(formData.monthlyBurn)
    };

    if (editingItem) {
      setData((prev) =>
        prev.map((i) => (i.id === editingItem.id ? cleanItem : i))
      );
    } else {
      setData((prev) => [cleanItem, ...prev]);
    }
    setIsModalOpen(false);
  };

  const handleDelete = (id) => {
    if (window.confirm(`Delete engineering analytics record ${id}?`)) {
      setData((prev) => prev.filter((i) => i.id !== id));
    }
  };

  const handleExportCSV = () => {
    const headers = "ID,Project,Engineering Package,Approved Capex (Cr),Actual Spent (Cr),Planned %,Actual %,Monthly Burn (Cr/mo),Digester Capacity,Gas Skid,Target Date,Status,Lead Engineer\n";
    const rows = filteredData
      .map(
        (i) =>
          `"${i.id}","${i.project}","${i.engineeringPackage}","${i.approvedCapex}","${i.actualSpent}","${i.plannedProgress}%","${i.actualProgress}%","${i.monthlyBurn}","${i.digesterCapacity}","${i.gasCompressionSkid}","${i.plannedFinish}","${i.health}","${i.leadEngineer}"`
      )
      .join("\n");
    const blob = new Blob([headers + rows], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `BioNova_Capex_Engineering_Analytics_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
  };

  return (
    <div style={{ paddingBottom: "30px" }}>
      {/* Title & Banner */}
      <div className="exec-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="exec-subtitle" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Consolidated project engineering telemetry, milestone burn velocity, digester capacity progression, and CapEx execution analytics.
        </p>

        <div className="exec-controls" style={{ display: "flex", gap: "12px", alignItems: "center", flexShrink: 0, marginLeft: "auto" }}>
          <button className="exec-btn-print" onClick={handleExportCSV} style={{ background: "#059669" }}>
            <Download size={15} /> Export Analytics CSV
          </button>
          <button className="exec-btn-print" onClick={() => handleOpenModal()}>
            <Plus size={16} /> Update Telemetry Package
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
                <Gauge size={22} color="#d97706" />
                {editingItem ? "Edit Engineering Telemetry" : "Add Project Telemetry Package"}
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Update engineering specifications, equipment packages, burn velocity, and execution milestones.
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
              <ArrowLeft size={16} /> Back to CapEx Analytics
            </button>
          </div>

          <form onSubmit={handleSave} style={{ padding: "28px" }}>
            {/* Section 1: Facility & Package Specifications */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Building size={18} color="#2563eb" /> 1. Facility & Package Specifications
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Telemetry ID *
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
                    Plant Facility *
                  </label>
                  <select
                    value={formData.project}
                    onChange={(e) => setFormData({ ...formData, project: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Plant 1 - Hyderabad East CBG">Plant 1 - Hyderabad East CBG</option>
                    <option value="Plant 2 - Medak Agri Hub">Plant 2 - Medak Agri Hub</option>
                    <option value="Plant 3 - Nalgonda Biomass Facility">Plant 3 - Nalgonda Facility</option>
                    <option value="Plant 4 - Bidar Agro Conversion Unit">Plant 4 - Bidar Facility</option>
                  </select>
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Engineering Package Description *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Anaerobic Digester Dome & Agitator Drive Train"
                    value={formData.engineeringPackage}
                    onChange={(e) => setFormData({ ...formData, engineeringPackage: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>
              </div>
            </div>

            {/* Section 2: Financial Metrics & Progress */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <DollarSign size={18} color="#059669" /> 2. CapEx Deployment & Milestone Progress
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Approved CapEx Budget (₹ Cr) *
                  </label>
                  <input
                    type="number"
                    step="0.1"
                    required
                    value={formData.approvedCapex}
                    onChange={(e) => setFormData({ ...formData, approvedCapex: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Actual CapEx Incurred (₹ Cr) *
                  </label>
                  <input
                    type="number"
                    step="0.1"
                    required
                    value={formData.actualSpent}
                    onChange={(e) => setFormData({ ...formData, actualSpent: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Monthly Cash Burn (₹ Cr/mo)
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    value={formData.monthlyBurn}
                    onChange={(e) => setFormData({ ...formData, monthlyBurn: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Actual Progress (%)
                  </label>
                  <input
                    type="number"
                    min="0"
                    max="100"
                    value={formData.actualProgress}
                    onChange={(e) => setFormData({ ...formData, actualProgress: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>
              </div>
            </div>

            {/* Section 3: Technical Specs & Engineering Delivery */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Activity size={18} color="#d97706" /> 3. Technical Specs & Delivery Timeline
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Digester Capacity Spec
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. 12,000 m³"
                    value={formData.digesterCapacity}
                    onChange={(e) => setFormData({ ...formData, digesterCapacity: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Gas Compression Skid Spec
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. 1,200 Nm³/hr Skid"
                    value={formData.gasCompressionSkid}
                    onChange={(e) => setFormData({ ...formData, gasCompressionSkid: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Target Completion Date
                  </label>
                  <input
                    type="date"
                    value={formData.plannedFinish}
                    onChange={(e) => setFormData({ ...formData, plannedFinish: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Lead Engineer
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. Er. Rajesh Varma"
                    value={formData.leadEngineer}
                    onChange={(e) => setFormData({ ...formData, leadEngineer: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
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
                  backgroundColor: "#d97706",
                  color: "#ffffff",
                  fontWeight: "600",
                  fontSize: "13.5px",
                  cursor: "pointer",
                  boxShadow: "0 2px 4px rgba(217, 119, 6, 0.25)"
                }}
              >
                <Save size={16} /> {editingItem ? "Update Telemetry Record" : "Save Telemetry Record"}
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* KPI Stats */}
      <div className="exec-fin-metrics" style={{ gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))", marginBottom: "24px" }}>
        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">CAPEX DEPLOYED IN ENGINEERING</div>
          <div className="exec-fin-tile-val">₹{totalSpent.toFixed(1)} Cr</div>
          <div className="exec-fin-tile-sub" style={{ color: "#059669" }}>
            {totalCapex > 0 ? `${Math.round((totalSpent / totalCapex) * 100)}%` : "0%"} of ₹{totalCapex.toFixed(1)} Cr Approved Portfolio
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">CASH BURN VELOCITY</div>
          <div className="exec-fin-tile-val" style={{ color: totalBurn > 0 ? "#2563eb" : "#64748b" }}>
            ₹{totalBurn.toFixed(2)} Cr/mo
          </div>
          <div className="exec-fin-tile-sub" style={{ color: data.length > 0 ? "#059669" : "#64748b" }}>
            {data.length > 0 ? "Healthy Runway: 14+ Months Buffer" : "No Active Burn Logged"}
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">AVERAGE MILESTONE PACE</div>
          <div className="exec-fin-tile-val" style={{ color: data.length > 0 ? "#0f172a" : "#64748b" }}>
            {data.length > 0 ? `${avgActualProgress}%` : "--"}
          </div>
          <div className="exec-fin-tile-sub" style={{ color: data.length > 0 ? "#059669" : "#64748b" }}>
            {data.length > 0 ? (
              <>
                <TrendingUp size={14} /> +2.8% Ahead of Baseline
              </>
            ) : (
              "No Active Milestones"
            )}
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">DIGESTER CAPACITY DEPLOYED</div>
          <div className="exec-fin-tile-val" style={{ color: data.length > 0 ? "#059669" : "#64748b", fontSize: "20px" }}>
            {data.length > 0 ? "30,500 m³ Total" : "--"}
          </div>
          <div className="exec-fin-tile-sub" style={{ color: "#64748b" }}>
            {data.length > 0 ? "3,000 Nm³/hr Gas Scrubbing Train" : "Awaiting Commissioning"}
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
              placeholder="Search by project, engineering package, or lead engineer..."
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
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="All">All Health Statuses</option>
            <option value="Ahead of Schedule">Ahead of Schedule</option>
            <option value="On Schedule">On Schedule</option>
            <option value="Permit Sync In Progress">Permit Sync In Progress</option>
          </select>
        </div>
      </div>

      {/* Engineering Analytics Table */}
      <div className="exec-card" style={{ padding: "0", overflow: "hidden" }}>
        <div style={{ padding: "16px 20px", borderBottom: "1px solid #f1f5f9", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <h3 style={{ margin: 0, fontSize: "15px", fontWeight: "700", color: "#0f172a" }}>
            Plant Engineering & CapEx Velocity Matrix ({filteredData.length})
          </h3>
          <span style={{ fontSize: "12px", color: "#64748b" }}>
            Telemetry synced with Site EPC daily logs & SCADA commissioning tests
          </span>
        </div>

        <div style={{ overflowX: "auto" }}>
          <table className="exec-dept-table" style={{ margin: 0 }}>
            <thead>
              <tr>
                <th>Project & Package</th>
                <th>CapEx Budget vs Spent</th>
                <th>Burn Telemetry</th>
                <th>Milestone Progress</th>
                <th>Equipment Telemetry</th>
                <th>Status</th>
                <th style={{ textAlign: "right" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredData.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                    No engineering analytics records found.
                  </td>
                </tr>
              ) : (
                filteredData.map((item) => (
                  <tr key={item.id}>
                    <td>
                      <div style={{ fontWeight: "700", color: "#0f172a", fontSize: "13px" }}>{item.project}</div>
                      <div style={{ fontSize: "11px", color: "#2563eb", fontWeight: "600" }}>{item.engineeringPackage}</div>
                      <div style={{ fontSize: "10px", color: "#64748b" }}>Lead: {item.leadEngineer} • Finish: {item.plannedFinish}</div>
                    </td>
                    <td>
                      <div style={{ fontWeight: "800", color: "#0f172a", fontSize: "13px" }}>
                        ₹{item.actualSpent.toFixed(1)} / ₹{item.approvedCapex.toFixed(1)} Cr
                      </div>
                      <div style={{ fontSize: "11px", color: "#059669" }}>
                        {Math.round((item.actualSpent / item.approvedCapex) * 100)}% Deployed
                      </div>
                    </td>
                    <td>
                      <div style={{ fontWeight: "700", color: "#2563eb", fontSize: "13px" }}>
                        ₹{item.monthlyBurn.toFixed(2)} Cr/mo
                      </div>
                      <div style={{ fontSize: "10px", color: "#64748b" }}>
                        Est. Completion: {Math.ceil((item.approvedCapex - item.actualSpent) / (item.monthlyBurn || 1))} Months
                      </div>
                    </td>
                    <td style={{ minWidth: "160px" }}>
                      <div style={{ display: "flex", justifyContent: "space-between", fontSize: "11px", marginBottom: "4px" }}>
                        <span style={{ fontWeight: "700", color: "#0f172a" }}>Actual: {item.actualProgress}%</span>
                        <span style={{ color: "#64748b" }}>Planned: {item.plannedProgress}%</span>
                      </div>
                      <div style={{ width: "100%", height: "6px", backgroundColor: "#e2e8f0", borderRadius: "999px", overflow: "hidden" }}>
                        <div
                          style={{
                            width: `${item.actualProgress}%`,
                            height: "100%",
                            backgroundColor: item.actualProgress >= item.plannedProgress ? "#10b981" : "#f59e0b"
                          }}
                        />
                      </div>
                    </td>
                    <td>
                      <div style={{ fontSize: "12px", fontWeight: "600", color: "#0f172a" }}>
                        {item.digesterCapacity}
                      </div>
                      <div style={{ fontSize: "11px", color: "#64748b" }}>
                        {item.gasCompressionSkid}
                      </div>
                    </td>
                    <td>
                      <span className={`exec-tag ${
                        item.health.includes("Ahead") ? "exec-tag-green" : item.health.includes("On") ? "exec-tag-blue" : "exec-tag-amber"
                      }`}>
                        {item.health}
                      </span>
                    </td>
                    <td style={{ textAlign: "right" }}>
                      <div style={{ display: "flex", justifyContent: "flex-end", gap: "6px" }}>
                        <button
                          onClick={() => handleOpenModal(item)}
                          title="Edit Telemetry"
                          style={{ border: "none", background: "#f1f5f9", borderRadius: "6px", padding: "6px", cursor: "pointer", color: "#059669" }}
                        >
                          <Edit2 size={15} />
                        </button>
                        <button
                          onClick={() => handleDelete(item.id)}
                          title="Delete Telemetry"
                          style={{ border: "none", background: "#f1f5f9", borderRadius: "6px", padding: "6px", cursor: "pointer", color: "#dc2626" }}
                        >
                          <Trash2 size={15} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
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

export default CapexAnalyticsDashboard;

