import React, { useState, useEffect } from "react";
import {
  AlertTriangle,
  Search,
  Filter,
  Plus,
  Download,
  ShieldAlert,
  Flame,
  Clock,
  CheckCircle2,
  AlertCircle,
  TrendingDown,
  DollarSign,
  Building,
  Edit2,
  Trash2,
  X,
  Check,
  ArrowRight,
  Bell,
  ArrowLeft,
  Save
} from "lucide-react";
import { getExecutiveAlerts, saveExecutiveAlert, resolveExecutiveAlert, deleteExecutiveAlert } from "./executiveApi";

const INITIAL_ALERTS = [];

const CATEGORIES = [
  "All Categories",
  "Project Budget Variance",
  "Regulatory Expiry",
  "Fund Burn Rate",
  "Safety / ESG"
];

const ExecutiveAlertFeed = () => {
  const [alerts, setAlerts] = useState(INITIAL_ALERTS);

  useEffect(() => {
    getExecutiveAlerts().then(data => {
      if (Array.isArray(data) && data.length > 0) setAlerts(data);
    }).catch(err => console.warn("Failed to load executive alerts:", err));
  }, []);
  const [searchQuery, setSearchQuery] = useState("");
  const [catFilter, setCatFilter] = useState("All Categories");
  const [severityFilter, setSeverityFilter] = useState("All");
  const [statusFilter, setStatusFilter] = useState("All");
  const [isModalOpen, setIsModalOpen] = useState(false);

  const [formData, setFormData] = useState({
    id: "",
    title: "",
    category: "Project Budget Variance",
    severity: "Critical",
    plant: "Plant 1 - Hyderabad East CBG",
    triggerDetail: "",
    metric: "",
    action: "",
    timestamp: new Date().toLocaleString(),
    status: "Active"
  });

  const filteredAlerts = alerts.filter((a) => {
    const matchesSearch =
      a.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      a.triggerDetail.toLowerCase().includes(searchQuery.toLowerCase()) ||
      a.plant.toLowerCase().includes(searchQuery.toLowerCase()) ||
      a.id.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCat = catFilter === "All Categories" || a.category === catFilter;
    const matchesSev = severityFilter === "All" || a.severity === severityFilter;
    const matchesStatus = statusFilter === "All" || a.status === statusFilter;
    return matchesSearch && matchesCat && matchesSev && matchesStatus;
  });

  const activeCritical = alerts.filter((a) => a.severity === "Critical" && a.status === "Active").length;
  const budgetAlerts = alerts.filter((a) => a.category.includes("Budget")).length;
  const regulatoryAlerts = alerts.filter((a) => a.category.includes("Regulatory")).length;
  const resolvedCount = alerts.filter((a) => a.status === "Resolved").length;

  const handleOpenModal = () => {
    const nextId = `ALT-INC-0${alerts.length + 1}`;
    setFormData({
      id: nextId,
      title: "",
      category: "Project Budget Variance",
      severity: "Critical",
      plant: "Plant 1 - Hyderabad East CBG",
      triggerDetail: "",
      metric: "",
      action: "",
      timestamp: new Date().toLocaleString(),
      status: "Active"
    });
    setIsModalOpen(true);
  };

  const handleSave = (e) => {
    e.preventDefault();
    if (!formData.title || !formData.triggerDetail) {
      alert("Please provide Title and Trigger Detail.");
      return;
    }
    setAlerts((prev) => [formData, ...prev]);
    setIsModalOpen(false);
  };

  const handleStatusChange = (id, newStatus) => {
    setAlerts((prev) =>
      prev.map((a) => (a.id === id ? { ...a, status: newStatus } : a))
    );
  };

  const handleDelete = (id) => {
    if (window.confirm(`Delete alert notice ${id}?`)) {
      setAlerts((prev) => prev.filter((a) => a.id !== id));
    }
  };

  const handleExportCSV = () => {
    const headers = "Alert ID,Title,Category,Severity,Plant,Metric,Trigger Detail,Action,Timestamp,Status\n";
    const rows = filteredAlerts
      .map(
        (a) =>
          `"${a.id}","${a.title}","${a.category}","${a.severity}","${a.plant}","${a.metric}","${a.triggerDetail}","${a.action}","${a.timestamp}","${a.status}"`
      )
      .join("\n");
    const blob = new Blob([headers + rows], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `BioNova_Executive_Alerts_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
  };

  return (
    <div style={{ paddingBottom: "30px" }}>
      {/* Title & Banner */}
      <div className="exec-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="exec-subtitle" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Dynamic high-priority warning telemetry across project budget overruns (&gt;5%), regulatory license expiries, safety incidents, and cash burn rate.
        </p>

        <div className="exec-controls" style={{ display: "flex", gap: "12px", alignItems: "center", flexShrink: 0, marginLeft: "auto" }}>
          <button className="exec-btn-print" onClick={handleExportCSV} style={{ background: "#059669" }}>
            <Download size={15} /> Export Alerts CSV
          </button>
          <button className="exec-btn-print" onClick={handleOpenModal} style={{ background: "#dc2626" }}>
            <Plus size={16} /> Broadcast Custom Alert
          </button>
        </div>
      </div>

      {/* If isModalOpen is true, render the Full-Page Form Card. Otherwise, render the Feed & KPIs */}
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
                <AlertTriangle size={22} color="#dc2626" />
                Broadcast Executive Critical Alert
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Broadcast urgent executive notices across budget tolerances, license renewals, burn velocity, or plant safety events.
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
              <ArrowLeft size={16} /> Back to Alert Center
            </button>
          </div>

          <form onSubmit={handleSave} style={{ padding: "28px" }}>
            {/* Section 1: Alert Classification & Impacted Plant */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <ShieldAlert size={18} color="#dc2626" /> 1. Alert Classification & Facility
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Alert Category *
                  </label>
                  <select
                    value={formData.category}
                    onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Project Budget Variance">Project Budget Variance</option>
                    <option value="Regulatory Expiry">Regulatory Expiry</option>
                    <option value="Fund Burn Rate">Fund Burn Rate</option>
                    <option value="Safety / ESG">Safety / ESG</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Severity *
                  </label>
                  <select
                    value={formData.severity}
                    onChange={(e) => setFormData({ ...formData, severity: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Critical">Critical (Immediate C-Suite)</option>
                    <option value="Warning">Warning (48-Hr Action)</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Impacted Plant Facility *
                  </label>
                  <input
                    type="text"
                    required
                    value={formData.plant}
                    onChange={(e) => setFormData({ ...formData, plant: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Metric / Threshold Triggered
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. +6.2% Overrun"
                    value={formData.metric}
                    onChange={(e) => setFormData({ ...formData, metric: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Alert Headline *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Budget Overrun Threshold Exceeded on Civil Package-2 (+6.2%)"
                    value={formData.title}
                    onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>
              </div>
            </div>

            {/* Section 2: Details & Recommended Action */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Bell size={18} color="#ea580c" /> 2. Trigger Telemetry & Recommended Action
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "1fr", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Trigger Details & Context *
                  </label>
                  <textarea
                    rows={3}
                    required
                    placeholder="Explain the background telemetry, sensor readings, or expense spikes..."
                    value={formData.triggerDetail}
                    onChange={(e) => setFormData({ ...formData, triggerDetail: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box", resize: "vertical" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Executive Action Item Recommended
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. Schedule emergency steering committee audit review"
                    value={formData.action}
                    onChange={(e) => setFormData({ ...formData, action: e.target.value })}
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
                  backgroundColor: "#dc2626",
                  color: "#ffffff",
                  fontWeight: "600",
                  fontSize: "13.5px",
                  cursor: "pointer",
                  boxShadow: "0 2px 4px rgba(220, 38, 38, 0.25)"
                }}
              >
                <Save size={16} /> Broadcast Executive Notice
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* KPI Stats */}
      <div className="exec-fin-metrics" style={{ gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))", marginBottom: "24px" }}>
        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">ACTIVE CRITICAL INCIDENTS</div>
          <div className="exec-fin-tile-val" style={{ color: activeCritical > 0 ? "#dc2626" : "#059669" }}>
            {activeCritical} Incidents
          </div>
          <div className="exec-fin-tile-sub" style={{ color: activeCritical > 0 ? "#dc2626" : "#64748b" }}>
            {activeCritical > 0 ? "Requires C-Suite Intervention" : "All Systems Nominal"}
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">BUDGET OVERRUN TRIGGERS (&gt;5%)</div>
          <div className="exec-fin-tile-val" style={{ color: budgetAlerts > 0 ? "#ea580c" : "#64748b" }}>{budgetAlerts} Triggers</div>
          <div className="exec-fin-tile-sub" style={{ color: "#64748b" }}>
            {budgetAlerts > 0 ? "Cost-Center Tolerance Limit Exceeded" : "Zero Overruns Detected"}
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">REGULATORY EXPIRY WARNINGS</div>
          <div className="exec-fin-tile-val" style={{ color: regulatoryAlerts > 0 ? "#d97706" : "#64748b" }}>{regulatoryAlerts} Permits</div>
          <div className="exec-fin-tile-sub" style={{ color: regulatoryAlerts > 0 ? "#059669" : "#64748b" }}>
            {regulatoryAlerts > 0 ? "Filing Packets Underway" : "Zero Pending Filings"}
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">RESOLVED / MITIGATED</div>
          <div className="exec-fin-tile-val" style={{ color: resolvedCount > 0 ? "#059669" : "#64748b" }}>{resolvedCount} Closed</div>
          <div className="exec-fin-tile-sub" style={{ color: resolvedCount > 0 ? "#059669" : "#64748b" }}>
            {resolvedCount > 0 ? "Action Items Completed" : "No Prior Incidents"}
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
              placeholder="Search alerts by title, details, or facility..."
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
            value={catFilter}
            onChange={(e) => setCatFilter(e.target.value)}
          >
            {CATEGORIES.map((c, idx) => (
              <option key={idx} value={c}>{c}</option>
            ))}
          </select>

          <select
            className="exec-select"
            value={severityFilter}
            onChange={(e) => setSeverityFilter(e.target.value)}
          >
            <option value="All">All Severities</option>
            <option value="Critical">Critical</option>
            <option value="Warning">Warning</option>
          </select>

          <select
            className="exec-select"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="All">All Statuses</option>
            <option value="Active">Active</option>
            <option value="In Review">In Review</option>
            <option value="Acknowledged">Acknowledged</option>
            <option value="Resolved">Resolved</option>
          </select>
        </div>
      </div>

      {/* Alert Feed Banners List */}
      <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
        {filteredAlerts.length === 0 ? (
          <div style={{
            background: "#ffffff",
            padding: "40px",
            borderRadius: "12px",
            textAlign: "center",
            color: "#64748b",
            border: "1px solid #e2e8f0"
          }}>
            No executive alerts found for the selected criteria.
          </div>
        ) : (
          filteredAlerts.map((a) => {
            const isCritical = a.severity === "Critical";
            const isResolved = a.status === "Resolved";
            return (
              <div
                key={a.id}
                style={{
                  backgroundColor: isResolved ? "#f8fafc" : isCritical ? "#fff5f5" : "#fffbeb",
                  border: `1px solid ${isResolved ? "#e2e8f0" : isCritical ? "#fecaca" : "#fef3c7"}`,
                  borderLeft: `6px solid ${isResolved ? "#94a3b8" : isCritical ? "#dc2626" : "#d97706"}`,
                  borderRadius: "12px",
                  padding: "20px 24px",
                  boxShadow: "0 1px 3px rgba(0,0,0,0.05)",
                  transition: "all 0.2s ease"
                }}
              >
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", flexWrap: "wrap", gap: "10px", marginBottom: "10px" }}>
                  <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                    <span style={{
                      padding: "3px 8px",
                      borderRadius: "6px",
                      fontSize: "11px",
                      fontWeight: "800",
                      textTransform: "uppercase",
                      backgroundColor: isCritical ? "#dc2626" : "#d97706",
                      color: "#ffffff"
                    }}>
                      {a.severity}
                    </span>
                    <span style={{
                      padding: "3px 8px",
                      borderRadius: "6px",
                      fontSize: "11px",
                      fontWeight: "700",
                      backgroundColor: "#ffffff",
                      border: "1px solid #cbd5e1",
                      color: "#334155"
                    }}>
                      {a.category}
                    </span>
                    <span style={{ fontSize: "12px", color: "#64748b" }}>
                      {a.plant} • {a.timestamp}
                    </span>
                  </div>

                  <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                    <span style={{
                      padding: "3px 10px",
                      borderRadius: "6px",
                      fontSize: "11px",
                      fontWeight: "700",
                      backgroundColor: a.status === "Resolved" ? "#dcfce7" : a.status === "Active" ? "#fee2e2" : "#e0e7ff",
                      color: a.status === "Resolved" ? "#166534" : a.status === "Active" ? "#991b1b" : "#3730a3"
                    }}>
                      Status: {a.status}
                    </span>
                    <button
                      onClick={() => handleDelete(a.id)}
                      title="Dismiss Alert"
                      style={{ border: "none", background: "transparent", cursor: "pointer", color: "#94a3b8" }}
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                </div>

                <h3 style={{ margin: "0 0 6px 0", fontSize: "16px", fontWeight: "800", color: "#0f172a" }}>
                  {a.title}
                </h3>

                <p style={{ margin: "0 0 12px 0", fontSize: "13px", color: "#334155", lineHeight: "1.5" }}>
                  {a.triggerDetail}
                </p>

                <div style={{
                  background: "#ffffff",
                  padding: "10px 14px",
                  borderRadius: "8px",
                  border: "1px solid #e2e8f0",
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  flexWrap: "wrap",
                  gap: "10px"
                }}>
                  <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                    <span style={{ fontSize: "11px", fontWeight: "700", color: "#64748b" }}>RECOMMENDED ACTION:</span>
                    <span style={{ fontSize: "12px", fontWeight: "600", color: "#0f172a" }}>{a.action}</span>
                  </div>

                  <div style={{ display: "flex", gap: "8px" }}>
                    {a.status !== "Resolved" && (
                      <button
                        onClick={() => handleStatusChange(a.id, "Resolved")}
                        style={{
                          backgroundColor: "#059669",
                          color: "#ffffff",
                          border: "none",
                          borderRadius: "6px",
                          padding: "6px 12px",
                          fontSize: "12px",
                          fontWeight: "600",
                          cursor: "pointer",
                          display: "flex",
                          alignItems: "center",
                          gap: "4px"
                        }}
                      >
                        <Check size={14} /> Resolve Incident
                      </button>
                    )}
                    {a.status === "Active" && (
                      <button
                        onClick={() => handleStatusChange(a.id, "Acknowledged")}
                        style={{
                          backgroundColor: "#1677ff",
                          color: "#ffffff",
                          border: "none",
                          borderRadius: "6px",
                          padding: "6px 12px",
                          fontSize: "12px",
                          fontWeight: "600",
                          cursor: "pointer"
                        }}
                      >
                        Acknowledge
                      </button>
                    )}
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>
      </>
      )}
    </div>
  );
};

export default ExecutiveAlertFeed;

