import React, { useState, useEffect } from "react";
import {
  Layers,
  Search,
  Filter,
  Plus,
  Download,
  Eye,
  Edit2,
  Trash2,
  MapPin,
  Calendar,
  CheckCircle2,
  AlertCircle,
  Clock,
  Building,
  TrendingUp,
  X,
  Sparkles,
  ArrowRight,
  ArrowLeft,
  Save
} from "lucide-react";
import { getPipelineProjects, savePipelineProject, deletePipelineProject } from "./executiveApi";

const INITIAL_PROJECTS = [];

const STAGES = [
  "All Stages",
  "Land Acquisition",
  "Civil Foundation",
  "Mechanical Erection",
  "E&I Installation",
  "Cold/Hot Commissioning"
];

const ExpansionPipeline = () => {
  const [projects, setProjects] = useState(INITIAL_PROJECTS);

  useEffect(() => {
    getPipelineProjects().then(data => {
      if (Array.isArray(data) && data.length > 0) setProjects(data);
    }).catch(err => console.warn("Failed to load pipeline projects:", err));
  }, []);
  const [searchQuery, setSearchQuery] = useState("");
  const [stageFilter, setStageFilter] = useState("All Stages");
  const [typeFilter, setTypeFilter] = useState("All Types");
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [viewProject, setViewProject] = useState(null);
  const [editingProject, setEditingProject] = useState(null);

  const [formData, setFormData] = useState({
    id: "",
    name: "",
    type: "Greenfield",
    location: "",
    capacity: "",
    stage: "Civil Foundation",
    startDate: "",
    targetCommissioning: "",
    completionPct: 0,
    capexApproved: "",
    capexSpent: "",
    leadPM: "",
    status: "On Track",
    upcomingMilestone: ""
  });

  const filteredProjects = projects.filter((p) => {
    const matchesSearch =
      p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.location.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.leadPM.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStage = stageFilter === "All Stages" || p.stage === stageFilter;
    const matchesType = typeFilter === "All Types" || p.type === typeFilter;
    return matchesSearch && matchesStage && matchesType;
  });

  const totalCapex = projects.reduce((acc, p) => acc + Number(p.capexApproved || 0), 0);
  const totalSpent = projects.reduce((acc, p) => acc + Number(p.capexSpent || 0), 0);
  const avgCompletion = Math.round(
    projects.reduce((acc, p) => acc + Number(p.completionPct || 0), 0) / (projects.length || 1)
  );

  const handleOpenModal = (project = null) => {
    if (project) {
      setEditingProject(project);
      setFormData(project);
    } else {
      setEditingProject(null);
      const nextId = `EXP-PLANT-0${projects.length + 1}`;
      setFormData({
        id: nextId,
        name: "",
        type: "Greenfield",
        location: "",
        capacity: "",
        stage: "Civil Foundation",
        startDate: new Date().toISOString().split("T")[0],
        targetCommissioning: "",
        completionPct: 0,
        capexApproved: "",
        capexSpent: "",
        leadPM: "",
        status: "On Track",
        upcomingMilestone: ""
      });
    }
    setIsModalOpen(true);
  };

  const handleSaveProject = (e) => {
    e.preventDefault();
    if (!formData.name || !formData.location) {
      alert("Please provide Project Name and Location.");
      return;
    }

    if (editingProject) {
      setProjects((prev) =>
        prev.map((p) => (p.id === editingProject.id ? { ...formData } : p))
      );
    } else {
      savePipelineProject(formData).then(res => {
        setProjects(prev => [res || formData, ...prev.filter(p => p.id !== formData.id)]);
      }).catch(err => console.warn(err));
      setProjects((prev) => [formData, ...prev]);
    }
    setIsModalOpen(false);
  };

  const handleDelete = (id) => {
    if (window.confirm(`Are you sure you want to remove project ${id} from pipeline?`)) {
      deletePipelineProject(id).catch(err => console.warn(err));
      setProjects((prev) => prev.filter((p) => p.id !== id));
    }
  };

  const handleExportCSV = () => {
    const headers = "ID,Name,Type,Location,Stage,Completion %,Capex Approved (Cr),Capex Spent (Cr),Lead PM,Status,Milestone\n";
    const rows = filteredProjects
      .map(
        (p) =>
          `"${p.id}","${p.name}","${p.type}","${p.location}","${p.stage}","${p.completionPct}%","${p.capexApproved}","${p.capexSpent}","${p.leadPM}","${p.status}","${p.upcomingMilestone}"`
      )
      .join("\n");
    const blob = new Blob([headers + rows], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `BioNova_Expansion_Pipeline_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
  };

  return (
    <div style={{ paddingBottom: "30px" }}>
      {/* Title & Banner */}
      <div className="exec-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="exec-subtitle" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Executive monitoring of Greenfield and Brownfield bio-refinery capital projects across regional growth corridors.
        </p>

        <div className="exec-controls" style={{ display: "flex", gap: "12px", alignItems: "center", flexShrink: 0, marginLeft: "auto" }}>
          <button className="exec-btn-print" onClick={handleExportCSV} style={{ background: "#059669" }}>
            <Download size={15} /> Export Pipeline CSV
          </button>
          <button className="exec-btn-print" onClick={() => handleOpenModal()}>
            <Plus size={16} /> Add Pipeline Project
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
                <Layers size={22} color="#2563eb" />
                {editingProject ? "Edit Expansion Pipeline Project" : "Add New Expansion Pipeline Project"}
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Enter project specifications, engineering timeline, and CapEx budget allocations in the full form below.
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
              <ArrowLeft size={16} /> Back to Project Pipeline
            </button>
          </div>

          <form onSubmit={handleSaveProject} style={{ padding: "28px" }}>
            {/* Section 1: Project Identity & Location */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Building size={18} color="#2563eb" /> 1. Project Identification & Location
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Project Code *
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
                    Project Type
                  </label>
                  <select
                    value={formData.type}
                    onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Greenfield">Greenfield</option>
                    <option value="Brownfield">Brownfield</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Plant Production Capacity
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. 20 TPD CBG / 60 TPD FOM"
                    value={formData.capacity}
                    onChange={(e) => setFormData({ ...formData, capacity: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Project Facility Name *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Warangal Bio-Energy & Fertilizer Hub"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Location / Regional Site *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Kazipet Industrial Area, Warangal, Telangana"
                    value={formData.location}
                    onChange={(e) => setFormData({ ...formData, location: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>
              </div>
            </div>

            {/* Section 2: Execution Stage & Operations */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <TrendingUp size={18} color="#10b981" /> 2. Operational Stage & Milestone Progress
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Current Execution Stage
                  </label>
                  <select
                    value={formData.stage}
                    onChange={(e) => setFormData({ ...formData, stage: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Land Acquisition">Land Acquisition</option>
                    <option value="Civil Foundation">Civil Foundation</option>
                    <option value="Mechanical Erection">Mechanical Erection</option>
                    <option value="E&I Installation">E&I Installation</option>
                    <option value="Cold/Hot Commissioning">Cold/Hot Commissioning</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Operational Status
                  </label>
                  <select
                    value={formData.status}
                    onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Ahead of Schedule">Ahead of Schedule</option>
                    <option value="On Track">On Track</option>
                    <option value="Hot Commissioning">Hot Commissioning</option>
                    <option value="Permit Review">Permit Review</option>
                    <option value="Delay Mitigation">Delay Mitigation</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Completion Percentage (%)
                  </label>
                  <input
                    type="number"
                    min="0"
                    max="100"
                    value={formData.completionPct}
                    onChange={(e) => setFormData({ ...formData, completionPct: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Immediate Milestone / Next Critical Step
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. Digester Gas Dome Pressure Test & Purge"
                    value={formData.upcomingMilestone}
                    onChange={(e) => setFormData({ ...formData, upcomingMilestone: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>
              </div>
            </div>

            {/* Section 3: Financials & Project Lead */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Clock size={18} color="#d97706" /> 3. CapEx Budget & Schedule
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
                    value={formData.capexApproved}
                    onChange={(e) => setFormData({ ...formData, capexApproved: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Actual CapEx Incurred (₹ Cr)
                  </label>
                  <input
                    type="number"
                    step="0.1"
                    value={formData.capexSpent}
                    onChange={(e) => setFormData({ ...formData, capexSpent: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Target Commissioning Date
                  </label>
                  <input
                    type="date"
                    value={formData.targetCommissioning}
                    onChange={(e) => setFormData({ ...formData, targetCommissioning: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Lead Project Manager
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. Er. Rajeshwar Rao"
                    value={formData.leadPM}
                    onChange={(e) => setFormData({ ...formData, leadPM: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
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
                {editingProject ? "Update Pipeline Project" : "Save Pipeline Project"}
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* KPI Stats Grid */}
          <div className="exec-fin-metrics" style={{ gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))", marginBottom: "24px" }}>
            <div className="exec-fin-tile">
              <div className="exec-fin-tile-label">TOTAL EXPANSION CAPEX</div>
              <div className="exec-fin-tile-val">₹{totalCapex.toFixed(1)} Cr</div>
              <div className="exec-fin-tile-sub" style={{ color: "#059669" }}>
                ₹{totalSpent.toFixed(1)} Cr Deployed ({totalCapex > 0 ? `${Math.round((totalSpent / totalCapex) * 100)}%` : "0%"})
              </div>
            </div>

            <div className="exec-fin-tile">
              <div className="exec-fin-tile-label">ACTIVE CAPITAL PROJECTS</div>
              <div className="exec-fin-tile-val">{projects.length} Facilities</div>
              <div className="exec-fin-tile-sub" style={{ color: "#2563eb" }}>
                {projects.filter((p) => p.type === "Greenfield").length} Greenfield • {projects.filter((p) => p.type === "Brownfield").length} Brownfield
              </div>
            </div>

            <div className="exec-fin-tile">
              <div className="exec-fin-tile-label">AVERAGE PIPELINE VELOCITY</div>
              <div className="exec-fin-tile-val">{projects.length > 0 ? `${avgCompletion}%` : "--"}</div>
              <div className="exec-fin-tile-sub" style={{ color: projects.length > 0 ? "#059669" : "#64748b" }}>
                {projects.length > 0 ? (
                  <>
                    <TrendingUp size={14} /> +3.4% Milestone Pace
                  </>
                ) : (
                  "No Active Projects"
                )}
              </div>
            </div>

            <div className="exec-fin-tile">
              <div className="exec-fin-tile-label">NEAREST COMMISSIONING</div>
              <div className="exec-fin-tile-val" style={{ fontSize: "18px", color: projects.length > 0 ? "#d97706" : "#64748b" }}>
                {projects.length > 0 ? (projects[0]?.name || "Upcoming Unit") : "--"}
              </div>
              <div className="exec-fin-tile-sub" style={{ color: "#64748b" }}>
                {projects.length > 0 ? `${projects[0]?.completionPct || 0}% Execution Complete` : "No Scheduled Commissioning"}
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
                  placeholder="Search by project name, ID, location, or lead PM..."
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
                value={typeFilter}
                onChange={(e) => setTypeFilter(e.target.value)}
              >
                <option value="All Types">All Project Types</option>
                <option value="Greenfield">Greenfield</option>
                <option value="Brownfield">Brownfield</option>
              </select>

              <select
                className="exec-select"
                value={stageFilter}
                onChange={(e) => setStageFilter(e.target.value)}
              >
                {STAGES.map((s, idx) => (
                  <option key={idx} value={s}>{s}</option>
                ))}
              </select>
            </div>
          </div>

          {/* Table Card */}
          <div className="exec-card" style={{ padding: "0", overflow: "hidden" }}>
            <div style={{ padding: "16px 20px", borderBottom: "1px solid #f1f5f9", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <h3 style={{ margin: 0, fontSize: "15px", fontWeight: "700", color: "#0f172a" }}>
                Expansion Projects Master Ledger ({filteredProjects.length})
              </h3>
              <span style={{ fontSize: "12px", color: "#64748b" }}>
                Showing stages from Land Acquisition to Live Commissioning
              </span>
            </div>

            <div style={{ overflowX: "auto" }}>
              <table className="exec-dept-table" style={{ margin: 0 }}>
                <thead>
                  <tr>
                    <th>Project Code & Name</th>
                    <th>Type & Location</th>
                    <th>Current Stage</th>
                    <th>Capex (Approved / Spent)</th>
                    <th>Timeline & Progress</th>
                    <th>Status</th>
                    <th style={{ textAlign: "right" }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredProjects.length === 0 ? (
                    <tr>
                      <td colSpan="7" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                        No expansion projects match the selected criteria.
                      </td>
                    </tr>
                  ) : (
                    filteredProjects.map((p) => (
                      <tr key={p.id}>
                        <td>
                          <div style={{ fontWeight: "700", color: "#0f172a", fontSize: "14px" }}>{p.name}</div>
                          <div style={{ fontSize: "11px", color: "#64748b", fontFamily: "monospace" }}>{p.id} • {p.capacity}</div>
                          <div style={{ fontSize: "11px", color: "#2563eb", marginTop: "2px" }}>PM: {p.leadPM}</div>
                        </td>
                        <td>
                          <span style={{
                            display: "inline-block",
                            padding: "2px 8px",
                            borderRadius: "4px",
                            fontSize: "11px",
                            fontWeight: "600",
                            marginBottom: "4px",
                            backgroundColor: p.type === "Greenfield" ? "#e0e7ff" : "#fef3c7",
                            color: p.type === "Greenfield" ? "#3730a3" : "#92400e"
                          }}>
                            {p.type}
                          </span>
                          <div style={{ fontSize: "12px", color: "#475569", display: "flex", alignItems: "center", gap: "4px" }}>
                            <MapPin size={12} color="#64748b" /> {p.location}
                          </div>
                        </td>
                        <td>
                          <div style={{ fontWeight: "600", fontSize: "13px", color: "#0f172a" }}>{p.stage}</div>
                          <div style={{ fontSize: "11px", color: "#64748b" }}>Next: {p.upcomingMilestone}</div>
                        </td>
                        <td>
                          <div style={{ fontWeight: "700", color: "#0f172a", fontSize: "13px" }}>₹{p.capexApproved} Cr</div>
                          <div style={{ fontSize: "11px", color: "#059669" }}>
                            Spent: ₹{p.capexSpent} Cr ({Math.round((p.capexSpent / p.capexApproved) * 100)}%)
                          </div>
                        </td>
                        <td style={{ minWidth: "150px" }}>
                          <div style={{ display: "flex", justifyContent: "space-between", fontSize: "11px", marginBottom: "4px" }}>
                            <span style={{ fontWeight: "600", color: "#0f172a" }}>{p.completionPct}%</span>
                            <span style={{ color: "#64748b" }}>Target: {p.targetCommissioning}</span>
                          </div>
                          <div style={{ width: "100%", height: "6px", backgroundColor: "#e2e8f0", borderRadius: "999px", overflow: "hidden" }}>
                            <div
                              style={{
                                width: `${p.completionPct}%`,
                                height: "100%",
                                backgroundColor: p.completionPct > 80 ? "#10b981" : p.completionPct > 50 ? "#3b82f6" : "#f59e0b"
                              }}
                            />
                          </div>
                        </td>
                        <td>
                          <span className={`exec-tag ${
                            p.status.includes("Ahead") || p.status.includes("Commissioning")
                              ? "exec-tag-green"
                              : p.status.includes("Track")
                              ? "exec-tag-blue"
                              : "exec-tag-amber"
                          }`}>
                            {p.status}
                          </span>
                        </td>
                        <td style={{ textAlign: "right" }}>
                          <div style={{ display: "flex", justifyContent: "flex-end", gap: "6px" }}>
                            <button
                              onClick={() => setViewProject(p)}
                              title="View Details"
                              style={{ border: "none", background: "#f1f5f9", borderRadius: "6px", padding: "6px", cursor: "pointer", color: "#1677ff" }}
                            >
                              <Eye size={15} />
                            </button>
                            <button
                              onClick={() => handleOpenModal(p)}
                              title="Edit Project"
                              style={{ border: "none", background: "#f1f5f9", borderRadius: "6px", padding: "6px", cursor: "pointer", color: "#059669" }}
                            >
                              <Edit2 size={15} />
                            </button>
                            <button
                              onClick={() => handleDelete(p.id)}
                              title="Delete Project"
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

      {/* View Details Modal */}
      {viewProject && (
        <div style={{
          position: "fixed",
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: "rgba(15, 23, 42, 0.6)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          zIndex: 9999,
          padding: "20px"
        }}>
          <div style={{
            backgroundColor: "#ffffff",
            borderRadius: "14px",
            width: "100%",
            maxWidth: "600px",
            padding: "24px",
            boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.25)"
          }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "16px" }}>
              <div>
                <span style={{ fontSize: "11px", fontWeight: "700", color: "#2563eb", textTransform: "uppercase" }}>
                  {viewProject.id} • {viewProject.type}
                </span>
                <h3 style={{ margin: "4px 0", fontSize: "18px", fontWeight: "800", color: "#0f172a" }}>
                  {viewProject.name}
                </h3>
                <div style={{ fontSize: "12px", color: "#64748b", display: "flex", alignItems: "center", gap: "4px" }}>
                  <MapPin size={12} /> {viewProject.location}
                </div>
              </div>
              <button
                onClick={() => setViewProject(null)}
                style={{ border: "none", background: "transparent", cursor: "pointer", color: "#64748b" }}
              >
                <X size={20} />
              </button>
            </div>

            <div style={{
              background: "#f8fafc",
              borderRadius: "10px",
              padding: "16px",
              display: "grid",
              gridTemplateColumns: "1fr 1fr",
              gap: "14px",
              marginBottom: "16px"
            }}>
              <div>
                <div style={{ fontSize: "11px", color: "#64748b" }}>CURRENT STAGE</div>
                <div style={{ fontSize: "14px", fontWeight: "700", color: "#0f172a" }}>{viewProject.stage}</div>
              </div>
              <div>
                <div style={{ fontSize: "11px", color: "#64748b" }}>PLANT CAPACITY</div>
                <div style={{ fontSize: "14px", fontWeight: "700", color: "#0f172a" }}>{viewProject.capacity}</div>
              </div>
              <div>
                <div style={{ fontSize: "11px", color: "#64748b" }}>CAPEX BUDGET</div>
                <div style={{ fontSize: "14px", fontWeight: "700", color: "#0f172a" }}>₹{viewProject.capexApproved} Cr Approved</div>
                <div style={{ fontSize: "11px", color: "#059669" }}>₹{viewProject.capexSpent} Cr Deployed</div>
              </div>
              <div>
                <div style={{ fontSize: "11px", color: "#64748b" }}>LEAD PM</div>
                <div style={{ fontSize: "14px", fontWeight: "700", color: "#0f172a" }}>{viewProject.leadPM}</div>
              </div>
              <div>
                <div style={{ fontSize: "11px", color: "#64748b" }}>TARGET COMMISSIONING</div>
                <div style={{ fontSize: "14px", fontWeight: "700", color: "#0f172a" }}>{viewProject.targetCommissioning}</div>
              </div>
              <div>
                <div style={{ fontSize: "11px", color: "#64748b" }}>OVERALL VELOCITY</div>
                <div style={{ fontSize: "14px", fontWeight: "700", color: "#2563eb" }}>{viewProject.completionPct}% Complete</div>
              </div>
            </div>

            <div style={{ background: "#eff6ff", padding: "12px 14px", borderRadius: "8px", borderLeft: "4px solid #2563eb", marginBottom: "16px" }}>
              <div style={{ fontSize: "11px", fontWeight: "700", color: "#1e40af", marginBottom: "2px" }}>
                UPCOMING MILESTONE
              </div>
              <div style={{ fontSize: "13px", color: "#1e3a8a", fontWeight: "500" }}>
                {viewProject.upcomingMilestone}
              </div>
            </div>

            <div style={{ display: "flex", justifyContent: "flex-end" }}>
              <button
                onClick={() => setViewProject(null)}
                style={{
                  padding: "8px 18px",
                  borderRadius: "8px",
                  background: "#0f172a",
                  color: "#ffffff",
                  border: "none",
                  fontWeight: "600",
                  cursor: "pointer"
                }}
              >
                Close Brief
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ExpansionPipeline;

