import React, { useState, useEffect } from "react";
import {
  ShieldCheck,
  Search,
  Filter,
  Plus,
  Download,
  AlertTriangle,
  CheckCircle2,
  Clock,
  Edit2,
  Trash2,
  FileCheck,
  Building,
  Calendar,
  X,
  Award,
  Globe2,
  Flame,
  Leaf,
  ArrowLeft,
  Save
} from "lucide-react";
import { getComplianceRecords, saveComplianceRecord, deleteComplianceRecord } from "./executiveApi";

const INITIAL_RECORDS = [];

const CATEGORIES = [
  "All Categories",
  "Safety & Explosives",
  "Environmental & Pollution",
  "Carbon Verification",
  "Health, Safety & Environment"
];

const ComplianceEsgRegistry = () => {
  const [records, setRecords] = useState(INITIAL_RECORDS);

  useEffect(() => {
    getComplianceRecords().then(data => {
      if (Array.isArray(data) && data.length > 0) setRecords(data);
    }).catch(err => console.warn("Failed to load compliance records:", err));
  }, []);
  const [searchQuery, setSearchQuery] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("All Categories");
  const [statusFilter, setStatusFilter] = useState("All");
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState(null);

  const [formData, setFormData] = useState({
    id: "",
    title: "",
    authority: "",
    plant: "Plant 1 - Hyderabad East CBG",
    category: "Environmental & Pollution",
    licenseNo: "",
    issueDate: "",
    expiryDate: "",
    esgPillar: "Environmental",
    riskLevel: "Low",
    status: "Valid & Compliant",
    officer: "",
    auditScore: "95/100"
  });

  const getDaysLeft = (expiryStr) => {
    if (!expiryStr) return 999;
    const diff = new Date(expiryStr) - new Date();
    return Math.ceil(diff / (1000 * 60 * 60 * 24));
  };

  const filteredRecords = records.filter((r) => {
    const matchesSearch =
      r.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.authority.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.licenseNo.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.officer.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCat = categoryFilter === "All Categories" || r.category === categoryFilter;
    const days = getDaysLeft(r.expiryDate);
    let matchesStatus = true;
    if (statusFilter === "Expiring") matchesStatus = days <= 45;
    if (statusFilter === "Valid") matchesStatus = days > 45;

    return matchesSearch && matchesCat && matchesStatus;
  });

  const expiringCount = records.filter((r) => getDaysLeft(r.expiryDate) <= 45).length;
  const compliantCount = records.filter((r) => r.status.includes("Valid")).length;

  const handleOpenModal = (item = null) => {
    if (item) {
      setEditingItem(item);
      setFormData(item);
    } else {
      setEditingItem(null);
      const nextId = `COMP-REG-0${records.length + 1}`;
      setFormData({
        id: nextId,
        title: "",
        authority: "",
        plant: "Plant 1 - Hyderabad East CBG",
        category: "Environmental & Pollution",
        licenseNo: "",
        issueDate: new Date().toISOString().split("T")[0],
        expiryDate: "2027-12-31",
        esgPillar: "Environmental",
        riskLevel: "Low",
        status: "Valid & Compliant",
        officer: "",
        auditScore: "95/100"
      });
    }
    setIsModalOpen(true);
  };

  const handleSave = (e) => {
    e.preventDefault();
    if (!formData.title || !formData.licenseNo) {
      alert("Please provide Title and License Number.");
      return;
    }

    if (editingItem) {
      setRecords((prev) =>
        prev.map((r) => (r.id === editingItem.id ? { ...formData } : r))
      );
    } else {
      saveComplianceRecord(formData).then(res => {
        setRecords(prev => [res || formData, ...prev.filter(r => r.id !== formData.id)]);
      }).catch(err => console.warn(err));
      setRecords((prev) => [formData, ...prev]);
    }
    setIsModalOpen(false);
  };

  const handleDelete = (id) => {
    if (window.confirm(`Delete compliance record ${id}?`)) {
      deleteComplianceRecord(id).catch(err => console.warn(err));
      setRecords((prev) => prev.filter((r) => r.id !== id));
    }
  };

  const handleExportCSV = () => {
    const headers = "Compliance ID,License Title,Authority,Plant,Category,License No,Issue Date,Expiry Date,Days Left,ESG Pillar,Risk,Status,Officer,Score\n";
    const rows = filteredRecords
      .map((r) => {
        const days = getDaysLeft(r.expiryDate);
        return `"${r.id}","${r.title}","${r.authority}","${r.plant}","${r.category}","${r.licenseNo}","${r.issueDate}","${r.expiryDate}","${days}","${r.esgPillar}","${r.riskLevel}","${r.status}","${r.officer}","${r.auditScore}"`;
      })
      .join("\n");
    const blob = new Blob([headers + rows], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `BioNova_Compliance_ESG_Registry_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
  };

  return (
    <div style={{ paddingBottom: "30px" }}>
      {/* Title & Banner */}
      <div className="exec-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="exec-subtitle" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Centralized registry for PESO explosive licenses, SPCB consent orders, carbon verifications, and sustainability risk indicators.
        </p>

        <div className="exec-controls" style={{ display: "flex", gap: "12px", alignItems: "center", flexShrink: 0, marginLeft: "auto" }}>
          <button className="exec-btn-print" onClick={handleExportCSV} style={{ background: "#059669" }}>
            <Download size={15} /> Export Registry CSV
          </button>
          <button className="exec-btn-print" onClick={() => handleOpenModal()}>
            <Plus size={16} /> Add Regulatory License
          </button>
        </div>
      </div>

      {/* Expiry Warning Notice if any <45 days */}
      {expiringCount > 0 && (
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
                Regulatory Renewal Notice ({expiringCount} Clearances Approaching Expiry within 45 Days)
              </div>
              <div style={{ fontSize: "12px", color: "#7c2d12" }}>
                TSPCB Consent to Operate (CTO) and CGWA Ground Water NOC are due for statutory renewal filings. Renewal dossiers are under legal review.
              </div>
            </div>
          </div>
          <button
            onClick={() => setStatusFilter("Expiring")}
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
            Review Renewals
          </button>
        </div>
      )}

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
                <ShieldCheck size={22} color="#059669" />
                {editingItem ? "Edit Statutory Compliance Record" : "Add Statutory License / Clearance"}
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Record environmental clearances, explosive licenses, carbon certifications, and ESG compliance filings.
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
              <ArrowLeft size={16} /> Back to Compliance Registry
            </button>
          </div>

          <form onSubmit={handleSave} style={{ padding: "28px" }}>
            {/* Section 1: License & Authority Identification */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Building size={18} color="#2563eb" /> 1. Statutory Clearance & Issuing Body
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Filing ID *
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
                    Compliance Category *
                  </label>
                  <select
                    value={formData.category}
                    onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Safety & Explosives">Safety & Explosives</option>
                    <option value="Environmental & Pollution">Environmental & Pollution</option>
                    <option value="Carbon Verification">Carbon Verification</option>
                    <option value="Health, Safety & Environment">Health, Safety & Environment</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Certificate / License Number *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. PESO/SC/2026/88"
                    value={formData.licenseNo}
                    onChange={(e) => setFormData({ ...formData, licenseNo: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Target Plant Facility *
                  </label>
                  <input
                    type="text"
                    required
                    value={formData.plant}
                    onChange={(e) => setFormData({ ...formData, plant: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    License / Clearance Title *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. PESO Gas Storage & Cascade Dispensing License"
                    value={formData.title}
                    onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Issuing Authority / Regulatory Body *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Petroleum and Explosives Safety Organisation (PESO)"
                    value={formData.authority}
                    onChange={(e) => setFormData({ ...formData, authority: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>
              </div>
            </div>

            {/* Section 2: Validity, ESG & Officer In-Charge */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Award size={18} color="#059669" /> 2. Validity, ESG Governance & Compliance Officer
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Issuance Date
                  </label>
                  <input
                    type="date"
                    value={formData.issueDate}
                    onChange={(e) => setFormData({ ...formData, issueDate: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Expiry / Renewal Date *
                  </label>
                  <input
                    type="date"
                    required
                    value={formData.expiryDate}
                    onChange={(e) => setFormData({ ...formData, expiryDate: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    ESG Dimension
                  </label>
                  <select
                    value={formData.esgPillar}
                    onChange={(e) => setFormData({ ...formData, esgPillar: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Environmental">Environmental</option>
                    <option value="Social">Social</option>
                    <option value="Governance">Governance</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    ESG Risk Rating
                  </label>
                  <select
                    value={formData.riskLevel}
                    onChange={(e) => setFormData({ ...formData, riskLevel: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Low">Low Risk</option>
                    <option value="Medium">Medium Watch</option>
                    <option value="High">High Urgency</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Compliance Officer In-Charge
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. S. Venkat Raman"
                    value={formData.officer}
                    onChange={(e) => setFormData({ ...formData, officer: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Audit Score
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. 98/100"
                    value={formData.auditScore}
                    onChange={(e) => setFormData({ ...formData, auditScore: e.target.value })}
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
                  backgroundColor: "#059669",
                  color: "#ffffff",
                  fontWeight: "600",
                  fontSize: "13.5px",
                  cursor: "pointer",
                  boxShadow: "0 2px 4px rgba(5, 150, 105, 0.25)"
                }}
              >
                <Save size={16} /> {editingItem ? "Update Statutory Record" : "Save Clearance"}
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* KPI Cards */}
      <div className="exec-fin-metrics" style={{ gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))", marginBottom: "24px" }}>
        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">STATUTORY CLEARANCES</div>
          <div className="exec-fin-tile-val">{records.length} Licenses</div>
          <div className="exec-fin-tile-sub" style={{ color: "#059669" }}>
            <CheckCircle2 size={14} /> {compliantCount} Fully Compliant & Active
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">ESG GOVERNANCE INDEX</div>
          <div className="exec-fin-tile-val" style={{ color: records.length > 0 ? "#059669" : "#64748b" }}>
            {records.length > 0 ? "96.8%" : "--"}
          </div>
          <div className="exec-fin-tile-sub" style={{ color: records.length > 0 ? "#059669" : "#64748b" }}>
            {records.length > 0 ? "Top Quartile Bio-Energy Benchmark" : "Awaiting Audit Baseline"}
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">RENEWALS DUE (&lt;45 DAYS)</div>
          <div className="exec-fin-tile-val" style={{ color: expiringCount > 0 ? "#ea580c" : "#059669" }}>
            {expiringCount} Filings
          </div>
          <div className="exec-fin-tile-sub" style={{ color: "#64748b" }}>
            {expiringCount > 0 ? "Renewal Dossiers Prepared" : "Zero Pending Filings"}
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">SAFETY & EMISSIONS AUDIT</div>
          <div className="exec-fin-tile-val" style={{ color: records.length > 0 ? "#0f172a" : "#64748b" }}>
            {records.length > 0 ? "Zero Violations" : "--"}
          </div>
          <div className="exec-fin-tile-sub" style={{ color: records.length > 0 ? "#2563eb" : "#64748b" }}>
            {records.length > 0 ? "OSHA & PCB Zero Deviations" : "No Audits Logged"}
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
              placeholder="Search by license title, authority, certificate no, or officer..."
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
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
          >
            {CATEGORIES.map((c, idx) => (
              <option key={idx} value={c}>{c}</option>
            ))}
          </select>

          <select
            className="exec-select"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="All">All Statuses</option>
            <option value="Expiring">Expiring Soon (&lt; 45 Days)</option>
            <option value="Valid">Valid & Compliant</option>
          </select>
        </div>
      </div>

      {/* Registry Table */}
      <div className="exec-card" style={{ padding: "0", overflow: "hidden" }}>
        <div style={{ padding: "16px 20px", borderBottom: "1px solid #f1f5f9", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <h3 style={{ margin: 0, fontSize: "15px", fontWeight: "700", color: "#0f172a" }}>
            Statutory Clearances & ESG Scorecard ({filteredRecords.length})
          </h3>
          <span style={{ fontSize: "12px", color: "#64748b" }}>
            PESO, SPCB CTO, Verra Carbon and CGWA Clearances
          </span>
        </div>

        <div style={{ overflowX: "auto" }}>
          <table className="exec-dept-table" style={{ margin: 0 }}>
            <thead>
              <tr>
                <th>License & Regulatory Authority</th>
                <th>Target Plant & Officer</th>
                <th>Certificate Number</th>
                <th>Validity & Days Left</th>
                <th>ESG Risk Rating</th>
                <th>Status</th>
                <th style={{ textAlign: "right" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredRecords.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                    No statutory compliance records match the search criteria.
                  </td>
                </tr>
              ) : (
                filteredRecords.map((r) => {
                  const daysLeft = getDaysLeft(r.expiryDate);
                  const isUrgent = daysLeft <= 45;
                  return (
                    <tr key={r.id}>
                      <td>
                        <div style={{ fontWeight: "700", color: "#0f172a", fontSize: "13px" }}>{r.title}</div>
                        <div style={{ fontSize: "11px", color: "#64748b" }}>{r.authority}</div>
                        <div style={{
                          display: "inline-block",
                          marginTop: "3px",
                          fontSize: "10px",
                          fontWeight: "700",
                          padding: "1px 6px",
                          borderRadius: "4px",
                          backgroundColor: "#f1f5f9",
                          color: "#475569"
                        }}>
                          {r.category}
                        </div>
                      </td>
                      <td>
                        <div style={{ fontWeight: "600", color: "#0f172a", fontSize: "13px" }}>{r.plant}</div>
                        <div style={{ fontSize: "11px", color: "#2563eb" }}>Lead: {r.officer}</div>
                        <div style={{ fontSize: "10px", color: "#059669" }}>Audit Score: {r.auditScore}</div>
                      </td>
                      <td>
                        <div style={{ fontWeight: "600", color: "#0f172a", fontSize: "12px", fontFamily: "monospace" }}>
                          {r.licenseNo}
                        </div>
                        <div style={{ fontSize: "10px", color: "#64748b" }}>ID: {r.id}</div>
                      </td>
                      <td>
                        <div style={{ fontSize: "12px", color: "#0f172a" }}>Exp: {r.expiryDate}</div>
                        <div style={{
                          fontSize: "11px",
                          fontWeight: "700",
                          color: isUrgent ? "#ea580c" : "#059669"
                        }}>
                          {daysLeft > 0 ? `${daysLeft} Days Remaining` : "Expired"}
                        </div>
                      </td>
                      <td>
                        <span style={{
                          display: "inline-block",
                          padding: "2px 8px",
                          borderRadius: "4px",
                          fontSize: "11px",
                          fontWeight: "700",
                          backgroundColor: r.riskLevel === "Low" ? "#dcfce7" : r.riskLevel === "Medium" ? "#fef3c7" : "#fee2e2",
                          color: r.riskLevel === "Low" ? "#166534" : r.riskLevel === "Medium" ? "#92400e" : "#991b1b"
                        }}>
                          {r.esgPillar}: {r.riskLevel} Risk
                        </span>
                      </td>
                      <td>
                        <span className={`exec-tag ${
                          !isUrgent ? "exec-tag-green" : "exec-tag-amber"
                        }`}>
                          {isUrgent ? "Renewal Due Soon" : "Valid & Active"}
                        </span>
                      </td>
                      <td style={{ textAlign: "right" }}>
                        <div style={{ display: "flex", justifyContent: "flex-end", gap: "6px" }}>
                          <button
                            onClick={() => handleOpenModal(r)}
                            title="Edit Record"
                            style={{ border: "none", background: "#f1f5f9", borderRadius: "6px", padding: "6px", cursor: "pointer", color: "#059669" }}
                          >
                            <Edit2 size={15} />
                          </button>
                          <button
                            onClick={() => handleDelete(r.id)}
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

export default ComplianceEsgRegistry;

