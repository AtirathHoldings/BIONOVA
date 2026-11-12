import React, { useState, useEffect } from "react";
import {
  Landmark,
  Search,
  Filter,
  Plus,
  Download,
  DollarSign,
  TrendingUp,
  Percent,
  CheckCircle2,
  Clock,
  Edit2,
  Trash2,
  X,
  CreditCard,
  Building,
  PiggyBank,
  PieChart,
  ShieldCheck,
  ArrowLeft,
  Save
} from "lucide-react";
import { getFundingSources, saveFundingSource, deleteFundingSource } from "./executiveApi";

const INITIAL_FACILITIES = [];

const CAPITAL_TYPES = [
  "All Classes",
  "Commercial Debt",
  "Concessional Green Debt",
  "Institutional Equity",
  "Promoter Capital",
  "Government Subsidy",
  "Green Bonds"
];

const TreasurySourcing = () => {
  const [facilities, setFacilities] = useState(INITIAL_FACILITIES);

  useEffect(() => {
    getFundingSources().then(data => {
      if (Array.isArray(data) && data.length > 0) setFacilities(data);
    }).catch(err => console.warn("Failed to load funding sources:", err));
  }, []);
  const [searchQuery, setSearchQuery] = useState("");
  const [typeFilter, setTypeFilter] = useState("All Classes");
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState(null);

  const [formData, setFormData] = useState({
    id: "",
    name: "",
    type: "Commercial Debt",
    institution: "",
    sanctioned: "",
    received: "",
    outstanding: "",
    interestRate: "8.50% p.a.",
    tenor: "10 Years",
    target: "",
    status: "Active & Disbursing"
  });

  const filteredFacilities = facilities.filter((f) => {
    const matchesSearch =
      f.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      f.institution.toLowerCase().includes(searchQuery.toLowerCase()) ||
      f.target.toLowerCase().includes(searchQuery.toLowerCase()) ||
      f.id.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesType = typeFilter === "All Classes" || f.type === typeFilter;
    return matchesSearch && matchesType;
  });

  const totalSanctioned = facilities.reduce((sum, f) => sum + Number(f.sanctioned || 0), 0);
  const totalReceived = facilities.reduce((sum, f) => sum + Number(f.received || 0), 0);
  const totalOutstanding = facilities.reduce((sum, f) => sum + Number(f.outstanding || 0), 0);
  const treasuryBuffer = totalSanctioned - totalReceived;

  // Breakdown metrics
  const totalDebt = facilities
    .filter((f) => f.type.includes("Debt") || f.type.includes("Bond"))
    .reduce((sum, f) => sum + f.sanctioned, 0);
  const totalEquity = facilities
    .filter((f) => f.type.includes("Equity") || f.type.includes("Promoter"))
    .reduce((sum, f) => sum + f.sanctioned, 0);
  const totalSubsidy = facilities
    .filter((f) => f.type.includes("Subsidy"))
    .reduce((sum, f) => sum + f.sanctioned, 0);

  const handleOpenModal = (item = null) => {
    if (item) {
      setEditingItem(item);
      setFormData(item);
    } else {
      setEditingItem(null);
      const nextId = `TR-FACILITY-0${facilities.length + 1}`;
      setFormData({
        id: nextId,
        name: "",
        type: "Commercial Debt",
        institution: "",
        sanctioned: "",
        received: "",
        outstanding: "",
        interestRate: "",
        tenor: "",
        target: "",
        status: "Active & Disbursing"
      });
    }
    setIsModalOpen(true);
  };

  const handleSave = (e) => {
    e.preventDefault();
    if (!formData.name || !formData.institution) {
      alert("Please provide Facility Name and Institution.");
      return;
    }
    const cleanItem = {
      ...formData,
      sanctioned: Number(formData.sanctioned),
      received: Number(formData.received),
      outstanding: Number(formData.outstanding || 0)
    };

    if (editingItem) {
      setFacilities((prev) =>
        prev.map((f) => (f.id === editingItem.id ? cleanItem : f))
      );
    } else {
      setFacilities((prev) => [cleanItem, ...prev]);
    }
    setIsModalOpen(false);
  };

  const handleDelete = (id) => {
    if (window.confirm(`Delete treasury facility ${id}?`)) {
      deleteFundingSource(id).catch(err => console.warn(err));
      setFacilities((prev) => prev.filter((f) => f.id !== id));
    }
  };

  const handleExportCSV = () => {
    const headers = "Facility ID,Name,Type,Institution,Sanctioned (Cr),Received (Cr),Outstanding (Cr),Interest Rate,Tenor,Target,Status\n";
    const rows = filteredFacilities
      .map(
        (f) =>
          `"${f.id}","${f.name}","${f.type}","${f.institution}","${f.sanctioned}","${f.received}","${f.outstanding}","${f.interestRate}","${f.tenor}","${f.target}","${f.status}"`
      )
      .join("\n");
    const blob = new Blob([headers + rows], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `BioNova_Treasury_Sourcing_Ledger_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
  };

  return (
    <div style={{ paddingBottom: "30px" }}>
      {/* Title & Banner */}
      <div className="exec-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="exec-subtitle" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Consolidated enterprise capital structure tracking institutional equity, term debt consortiums, green bonds, and SATAT subsidies.
        </p>

        <div className="exec-controls" style={{ display: "flex", gap: "12px", alignItems: "center", flexShrink: 0, marginLeft: "auto" }}>
          <button className="exec-btn-print" onClick={handleExportCSV} style={{ background: "#059669" }}>
            <Download size={15} /> Export Sourcing CSV
          </button>
          <button className="exec-btn-print" onClick={() => handleOpenModal()}>
            <Plus size={16} /> Add Capital Facility
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
                <Landmark size={22} color="#7c3aed" />
                {editingItem ? "Edit Capital Facility" : "Add Capital Facility / Tranche"}
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Structure debt tranches, institutional equity, concessional green loans, and capital allocation schedules.
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
              <ArrowLeft size={16} /> Back to Treasury Management
            </button>
          </div>

          <form onSubmit={handleSave} style={{ padding: "28px" }}>
            {/* Section 1: Facility Identification & Lending Institution */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Building size={18} color="#7c3aed" /> 1. Facility Identification & Financing Partner
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Facility ID *
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
                    Capital Class *
                  </label>
                  <select
                    value={formData.type}
                    onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Commercial Debt">Commercial Debt</option>
                    <option value="Concessional Green Debt">Concessional Green Debt</option>
                    <option value="Institutional Equity">Institutional Equity</option>
                    <option value="Promoter Capital">Promoter Capital</option>
                    <option value="Government Subsidy">Government Subsidy</option>
                    <option value="Green Bonds">Green Bonds</option>
                  </select>
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Facility / Instrument Name *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. IREDA Green Term Loan Facility"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Lending Institution / Investor Name *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. State Bank of India & IREDA"
                    value={formData.institution}
                    onChange={(e) => setFormData({ ...formData, institution: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>
              </div>
            </div>

            {/* Section 2: Financial Terms & Allocation */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <DollarSign size={18} color="#059669" /> 2. Financial Sizing, Rates & Tenor
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Sanctioned Amount (₹ Cr) *
                  </label>
                  <input
                    type="number"
                    step="0.1"
                    required
                    value={formData.sanctioned}
                    onChange={(e) => setFormData({ ...formData, sanctioned: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Disbursed / Received (₹ Cr) *
                  </label>
                  <input
                    type="number"
                    step="0.1"
                    required
                    value={formData.received}
                    onChange={(e) => setFormData({ ...formData, received: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Interest Rate / Coupon
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. 8.25% p.a."
                    value={formData.interestRate}
                    onChange={(e) => setFormData({ ...formData, interestRate: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Tenor / Repayment Schedule
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. 12 Years"
                    value={formData.tenor}
                    onChange={(e) => setFormData({ ...formData, tenor: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Target Project Allocation
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. Plant 2 & 3 EPC Construction and Digester Erection"
                    value={formData.target}
                    onChange={(e) => setFormData({ ...formData, target: e.target.value })}
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
                  backgroundColor: "#7c3aed",
                  color: "#ffffff",
                  fontWeight: "600",
                  fontSize: "13.5px",
                  cursor: "pointer",
                  boxShadow: "0 2px 4px rgba(124, 58, 237, 0.25)"
                }}
              >
                <Save size={16} /> {editingItem ? "Update Facility" : "Save Facility"}
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* KPI Stats */}
      <div className="exec-fin-metrics" style={{ gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))", marginBottom: "24px" }}>
        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">TOTAL CAPITAL SANCTIONED</div>
          <div className="exec-fin-tile-val">₹{totalSanctioned.toFixed(1)} Cr</div>
          <div className="exec-fin-tile-sub" style={{ color: "#2563eb" }}>
            Debt: ₹{totalDebt.toFixed(1)} Cr • Equity: ₹{totalEquity.toFixed(1)} Cr
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">CUMULATIVE FUNDS RECEIVED</div>
          <div className="exec-fin-tile-val">₹{totalReceived.toFixed(1)} Cr</div>
          <div className="exec-fin-tile-sub" style={{ color: "#059669" }}>
            {totalSanctioned > 0 ? `${Math.round((totalReceived / totalSanctioned) * 100)}%` : "0%"} Disbursed into Operations
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">AVAILABLE TREASURY BUFFER</div>
          <div className="exec-fin-tile-val" style={{ color: "#059669" }}>
            ₹{treasuryBuffer.toFixed(1)} Cr
          </div>
          <div className="exec-fin-tile-sub" style={{ color: "#059669" }}>
            Undrawn Sanctioned Lines Intact
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">BLENDED COST OF DEBT</div>
          <div className="exec-fin-tile-val" style={{ color: totalDebt > 0 ? "#2563eb" : "#64748b" }}>
            {totalDebt > 0 ? "8.12%" : "--"}
          </div>
          <div className="exec-fin-tile-sub" style={{ color: "#64748b" }}>
            {totalDebt > 0 ? "Weighted Average Sovereign & Green Rate" : "No Active Debt Facilities"}
          </div>
        </div>
      </div>

      {/* Capital Structure Breakdown Card */}
      <div style={{
        background: "#ffffff",
        borderRadius: "12px",
        padding: "18px 24px",
        border: "1px solid #e2e8f0",
        marginBottom: "20px"
      }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "14px" }}>
          <h3 style={{ margin: 0, fontSize: "14px", fontWeight: "700", color: "#0f172a" }}>
            Enterprise Capital Structure Distribution (Total ₹{totalSanctioned.toFixed(1)} Cr)
          </h3>
          <span style={{ fontSize: "12px", color: "#64748b" }}>
            Debt-to-Equity Ratio: {totalDebt > 0 ? (totalDebt / (totalEquity || 1)).toFixed(2) : "0.00"}x (Conservative Target &lt; 2.5x)
          </span>
        </div>

        <div style={{ display: "flex", height: "12px", borderRadius: "999px", overflow: "hidden", marginBottom: "12px", backgroundColor: "#f1f5f9" }}>
          <div style={{ width: totalSanctioned > 0 ? `${(totalDebt / totalSanctioned) * 100}%` : "0%", backgroundColor: "#2563eb" }} title="Debt Facilities" />
          <div style={{ width: totalSanctioned > 0 ? `${(totalEquity / totalSanctioned) * 100}%` : "0%", backgroundColor: "#059669" }} title="Equity & Promoter" />
          <div style={{ width: totalSanctioned > 0 ? `${(totalSubsidy / totalSanctioned) * 100}%` : "0%", backgroundColor: "#f59e0b" }} title="Government Subsidies" />
        </div>

        <div style={{ display: "flex", gap: "24px", flexWrap: "wrap", fontSize: "12px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
            <div style={{ width: "10px", height: "10px", borderRadius: "2px", backgroundColor: "#2563eb" }} />
            <span><strong>Term Debt & Green Bonds:</strong> ₹{totalDebt.toFixed(1)} Cr ({totalSanctioned > 0 ? Math.round((totalDebt / totalSanctioned) * 100) : 0}%)</span>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
            <div style={{ width: "10px", height: "10px", borderRadius: "2px", backgroundColor: "#059669" }} />
            <span><strong>Institutional & Promoter Equity:</strong> ₹{totalEquity.toFixed(1)} Cr ({totalSanctioned > 0 ? Math.round((totalEquity / totalSanctioned) * 100) : 0}%)</span>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
            <div style={{ width: "10px", height: "10px", borderRadius: "2px", backgroundColor: "#f59e0b" }} />
            <span><strong>MNRE SATAT Subsidies:</strong> ₹{totalSubsidy.toFixed(1)} Cr ({totalSanctioned > 0 ? Math.round((totalSubsidy / totalSanctioned) * 100) : 0}%)</span>
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
              placeholder="Search by facility name, lender, ID, or purpose..."
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
            {CAPITAL_TYPES.map((c, idx) => (
              <option key={idx} value={c}>{c}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Facilities Table */}
      <div className="exec-card" style={{ padding: "0", overflow: "hidden" }}>
        <div style={{ padding: "16px 20px", borderBottom: "1px solid #f1f5f9", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <h3 style={{ margin: 0, fontSize: "15px", fontWeight: "700", color: "#0f172a" }}>
            Funding Sources & Treasury Registry ({filteredFacilities.length})
          </h3>
          <span style={{ fontSize: "12px", color: "#64748b" }}>
            Real-time balance synchronization with corporate banking & escrow accounts
          </span>
        </div>

        <div style={{ overflowX: "auto" }}>
          <table className="exec-dept-table" style={{ margin: 0 }}>
            <thead>
              <tr>
                <th>Facility & Institution</th>
                <th>Capital Class</th>
                <th>Sanctioned Amount</th>
                <th>Disbursed / Received</th>
                <th>Interest & Tenor</th>
                <th>Status</th>
                <th style={{ textAlign: "right" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredFacilities.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                    No capital facilities found matching search criteria.
                  </td>
                </tr>
              ) : (
                filteredFacilities.map((f) => (
                  <tr key={f.id}>
                    <td>
                      <div style={{ fontWeight: "700", color: "#0f172a", fontSize: "13px" }}>{f.name}</div>
                      <div style={{ fontSize: "11px", color: "#64748b" }}>{f.institution}</div>
                      <div style={{ fontSize: "10px", color: "#2563eb", marginTop: "2px" }}>Target: {f.target}</div>
                    </td>
                    <td>
                      <span style={{
                        display: "inline-block",
                        padding: "2px 8px",
                        borderRadius: "4px",
                        fontSize: "11px",
                        fontWeight: "600",
                        backgroundColor: f.type.includes("Debt") ? "#eff6ff" : f.type.includes("Equity") ? "#f0fdf4" : "#fef3c7",
                        color: f.type.includes("Debt") ? "#1e40af" : f.type.includes("Equity") ? "#15803d" : "#92400e"
                      }}>
                        {f.type}
                      </span>
                    </td>
                    <td>
                      <div style={{ fontWeight: "800", color: "#0f172a", fontSize: "13px" }}>₹{f.sanctioned.toFixed(1)} Cr</div>
                      <div style={{ fontSize: "10px", color: "#64748b" }}>ID: {f.id}</div>
                    </td>
                    <td>
                      <div style={{ fontWeight: "700", color: "#059669", fontSize: "13px" }}>₹{f.received.toFixed(1)} Cr</div>
                      <div style={{ fontSize: "11px", color: "#64748b" }}>
                        {Math.round((f.received / f.sanctioned) * 100)}% drawn
                      </div>
                    </td>
                    <td>
                      <div style={{ fontWeight: "600", color: "#0f172a", fontSize: "12px" }}>{f.interestRate}</div>
                      <div style={{ fontSize: "11px", color: "#64748b" }}>{f.tenor}</div>
                    </td>
                    <td>
                      <span className={`exec-tag ${
                        f.status.includes("Active") ? "exec-tag-green" : "exec-tag-blue"
                      }`}>
                        {f.status}
                      </span>
                    </td>
                    <td style={{ textAlign: "right" }}>
                      <div style={{ display: "flex", justifyContent: "flex-end", gap: "6px" }}>
                        <button
                          onClick={() => handleOpenModal(f)}
                          title="Edit Facility"
                          style={{ border: "none", background: "#f1f5f9", borderRadius: "6px", padding: "6px", cursor: "pointer", color: "#059669" }}
                        >
                          <Edit2 size={15} />
                        </button>
                        <button
                          onClick={() => handleDelete(f.id)}
                          title="Delete Facility"
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

export default TreasurySourcing;

