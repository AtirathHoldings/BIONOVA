import React, { useState, useEffect } from "react";
import {
  Briefcase,
  Search,
  Filter,
  Plus,
  Download,
  DollarSign,
  ShieldCheck,
  CheckCircle2,
  Clock,
  Edit2,
  Trash2,
  X,
  CreditCard,
  Building,
  Landmark,
  ArrowUpRight,
  ArrowDownRight,
  Lock,
  Layers,
  ArrowLeft,
  Save
} from "lucide-react";
import { getEscrowAccounts, saveEscrowAccount, deleteEscrowAccount } from "./executiveApi";

const INITIAL_ESCROWS = [];

const CATEGORIES = [
  "All Types",
  "Disbursement Escrow",
  "DSRA Reserve Account",
  "Retention Escrow"
];

const EscrowFinancing = () => {
  const [escrows, setEscrows] = useState(INITIAL_ESCROWS);

  useEffect(() => {
    getEscrowAccounts().then(data => {
      if (Array.isArray(data) && data.length > 0) setEscrows(data);
    }).catch(err => console.warn("Failed to load escrow accounts:", err));
  }, []);
  const [searchQuery, setSearchQuery] = useState("");
  const [catFilter, setCatFilter] = useState("All Types");
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState(null);

  const [formData, setFormData] = useState({
    id: "",
    accountNo: "",
    title: "",
    custodian: "",
    plant: "Plant 1 - Hyderabad East CBG",
    category: "Disbursement Escrow",
    inflow: "",
    outflow: "",
    balance: "",
    dsraRequirement: "",
    covenantStatus: "Compliant",
    lastAuditDate: "",
    signatory: ""
  });

  const filteredEscrows = escrows.filter((e) => {
    const matchesSearch =
      e.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      e.accountNo.toLowerCase().includes(searchQuery.toLowerCase()) ||
      e.custodian.toLowerCase().includes(searchQuery.toLowerCase()) ||
      e.plant.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCat = catFilter === "All Types" || e.category === catFilter;
    return matchesSearch && matchesCat;
  });

  const totalBalance = escrows.reduce((sum, e) => sum + Number(e.balance || 0), 0);
  const totalInflows = escrows.reduce((sum, e) => sum + Number(e.inflow || 0), 0);
  const totalOutflows = escrows.reduce((sum, e) => sum + Number(e.outflow || 0), 0);
  const totalDsra = escrows
    .filter((e) => e.category.includes("DSRA"))
    .reduce((sum, e) => sum + Number(e.balance || 0), 0);

  const handleOpenModal = (item = null) => {
    if (item) {
      setEditingItem(item);
      setFormData(item);
    } else {
      setEditingItem(null);
      const nextId = `ESC-ACC-0${escrows.length + 1}`;
      setFormData({
        id: nextId,
        accountNo: "",
        title: "",
        custodian: "",
        plant: "Plant 1 - Hyderabad East CBG",
        category: "Disbursement Escrow",
        inflow: "",
        outflow: "",
        balance: "",
        dsraRequirement: "",
        covenantStatus: "Compliant",
        lastAuditDate: new Date().toISOString().split("T")[0],
        signatory: ""
      });
    }
    setIsModalOpen(true);
  };

  const handleSave = (e) => {
    e.preventDefault();
    if (!formData.title || !formData.accountNo) {
      alert("Please provide Escrow Title and Account Number.");
      return;
    }
    const cleanItem = {
      ...formData,
      inflow: Number(formData.inflow),
      outflow: Number(formData.outflow),
      balance: Number(formData.balance),
      dsraRequirement: Number(formData.dsraRequirement || 0)
    };

    if (editingItem) {
      setEscrows((prev) =>
        prev.map((e) => (e.id === editingItem.id ? cleanItem : e))
      );
    } else {
      setEscrows((prev) => [cleanItem, ...prev]);
    }
    setIsModalOpen(false);
  };

  const handleDelete = (id) => {
    if (window.confirm(`Delete escrow record ${id}?`)) {
      deleteEscrowAccount(id).catch(err => console.warn(err));
      setEscrows((prev) => prev.filter((e) => e.id !== id));
    }
  };

  const handleExportCSV = () => {
    const headers = "Escrow ID,Account No,Title,Custodian Bank,Plant,Category,Inflow (Cr),Outflow (Cr),Balance (Cr),DSRA Requirement (Cr),Covenant,Audit Date,Signatory\n";
    const rows = filteredEscrows
      .map(
        (e) =>
          `"${e.id}","${e.accountNo}","${e.title}","${e.custodian}","${e.plant}","${e.category}","${e.inflow}","${e.outflow}","${e.balance}","${e.dsraRequirement}","${e.covenantStatus}","${e.lastAuditDate}","${e.signatory}"`
      )
      .join("\n");
    const blob = new Blob([headers + rows], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `BioNova_Escrow_Financing_Monitor_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
  };

  return (
    <div style={{ paddingBottom: "30px" }}>
      {/* Title & Banner */}
      <div className="exec-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="exec-subtitle" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Dedicated escrow account ledgers, Debt Service Reserve Accounts (DSRA), and institutional lender milestone drawdowns.
        </p>

        <div className="exec-controls" style={{ display: "flex", gap: "12px", alignItems: "center", flexShrink: 0, marginLeft: "auto" }}>
          <button className="exec-btn-print" onClick={handleExportCSV} style={{ background: "#059669" }}>
            <Download size={15} /> Export Escrow CSV
          </button>
          <button className="exec-btn-print" onClick={() => handleOpenModal()}>
            <Plus size={16} /> Add Escrow Account
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
                <Briefcase size={22} color="#0284c7" />
                {editingItem ? "Edit Dedicated Escrow Account" : "Add Dedicated Escrow Account"}
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Configure custodian bank trustees, project facilities, DSRA covenant thresholds, and authorized signatories.
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
              <ArrowLeft size={16} /> Back to Escrow Financing
            </button>
          </div>

          <form onSubmit={handleSave} style={{ padding: "28px" }}>
            {/* Section 1: Escrow Identification & Trustee */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Landmark size={18} color="#0284c7" /> 1. Escrow Account & Custodian Trustee
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Escrow ID *
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
                    Bank Account Number *
                  </label>
                  <input
                    type="text"
                    required
                    value={formData.accountNo}
                    onChange={(e) => setFormData({ ...formData, accountNo: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Custodian Bank / Trustee *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. SBI Infra Trustee Company Ltd"
                    value={formData.custodian}
                    onChange={(e) => setFormData({ ...formData, custodian: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Account Category
                  </label>
                  <select
                    value={formData.category}
                    onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Disbursement Escrow">Disbursement Escrow</option>
                    <option value="DSRA Reserve Account">DSRA Reserve Account</option>
                    <option value="Retention Escrow">Retention Escrow</option>
                  </select>
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Escrow Account Title *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Medak Plant EPC Construction Escrow"
                    value={formData.title}
                    onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Plant Facility
                  </label>
                  <input
                    type="text"
                    value={formData.plant}
                    onChange={(e) => setFormData({ ...formData, plant: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Signatory Authority
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. Joint Signatory (CEO + Lender Nominee)"
                    value={formData.signatory}
                    onChange={(e) => setFormData({ ...formData, signatory: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>
              </div>
            </div>

            {/* Section 2: Balances, Inflows & DSRA Covenants */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <DollarSign size={18} color="#059669" /> 2. Liquidity, Disbursal Balances & DSRA Reserve
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Available Balance (₹ Cr) *
                  </label>
                  <input
                    type="number"
                    step="0.1"
                    required
                    value={formData.balance}
                    onChange={(e) => setFormData({ ...formData, balance: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Total Cumulative Inflows (₹ Cr) *
                  </label>
                  <input
                    type="number"
                    step="0.1"
                    required
                    value={formData.inflow}
                    onChange={(e) => setFormData({ ...formData, inflow: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Total Cumulative Outflows (₹ Cr) *
                  </label>
                  <input
                    type="number"
                    step="0.1"
                    required
                    value={formData.outflow}
                    onChange={(e) => setFormData({ ...formData, outflow: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Min DSRA Requirement (₹ Cr)
                  </label>
                  <input
                    type="number"
                    step="0.1"
                    value={formData.dsraRequirement}
                    onChange={(e) => setFormData({ ...formData, dsraRequirement: e.target.value })}
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
                  backgroundColor: "#0284c7",
                  color: "#ffffff",
                  fontWeight: "600",
                  fontSize: "13.5px",
                  cursor: "pointer",
                  boxShadow: "0 2px 4px rgba(2, 132, 199, 0.25)"
                }}
              >
                <Save size={16} /> {editingItem ? "Update Escrow Account" : "Save Escrow Account"}
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* KPI Stats */}
      <div className="exec-fin-metrics" style={{ gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))", marginBottom: "24px" }}>
        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">TOTAL ESCROW BALANCE</div>
          <div className="exec-fin-tile-val">₹{totalBalance.toFixed(1)} Cr</div>
          <div className="exec-fin-tile-sub" style={{ color: "#059669" }}>
            Liquid in Scheduled Bank Accounts
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">DSRA RESERVE COVERAGE</div>
          <div className="exec-fin-tile-val" style={{ color: totalDsra > 0 ? "#059669" : "#64748b" }}>₹{totalDsra.toFixed(1)} Cr</div>
          <div className="exec-fin-tile-sub" style={{ color: totalDsra > 0 ? "#059669" : "#64748b" }}>
            {totalDsra > 0 ? (
              <>
                <CheckCircle2 size={14} /> 100% Covenant Compliant (6 Mo Interest)
              </>
            ) : (
              "No Active DSRA Accounts"
            )}
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">CUMULATIVE INFLOWS DEPOSITED</div>
          <div className="exec-fin-tile-val">₹{totalInflows.toFixed(1)} Cr</div>
          <div className="exec-fin-tile-sub" style={{ color: "#2563eb" }}>
            Disbursements & SATAT Subsidies
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">TOTAL CAPITAL EXPENDED / DRAWN</div>
          <div className="exec-fin-tile-val">₹{totalOutflows.toFixed(1)} Cr</div>
          <div className="exec-fin-tile-sub" style={{ color: "#64748b" }}>
            Certified by Independent Engineers
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
              placeholder="Search by escrow title, account no, custodian bank, or plant..."
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
        </div>
      </div>

      {/* Escrow Accounts Table */}
      <div className="exec-card" style={{ padding: "0", overflow: "hidden" }}>
        <div style={{ padding: "16px 20px", borderBottom: "1px solid #f1f5f9", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <h3 style={{ margin: 0, fontSize: "15px", fontWeight: "700", color: "#0f172a" }}>
            Dedicated Project Escrow Accounts ({filteredEscrows.length})
          </h3>
          <span style={{ fontSize: "12px", color: "#64748b" }}>
            Strictly governed by Tripartite Escrow Agreements & Lender Agent terms
          </span>
        </div>

        <div style={{ overflowX: "auto" }}>
          <table className="exec-dept-table" style={{ margin: 0 }}>
            <thead>
              <tr>
                <th>Account Title & Custodian</th>
                <th>Account Type & Plant</th>
                <th>Cumulative Inflow</th>
                <th>Cumulative Outflow</th>
                <th>Available Balance</th>
                <th>Covenant Adherence</th>
                <th style={{ textAlign: "right" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredEscrows.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                    No escrow accounts match current search.
                  </td>
                </tr>
              ) : (
                filteredEscrows.map((e) => (
                  <tr key={e.id}>
                    <td>
                      <div style={{ fontWeight: "700", color: "#0f172a", fontSize: "13px" }}>{e.title}</div>
                      <div style={{ fontSize: "11px", color: "#64748b" }}>{e.custodian}</div>
                      <div style={{ fontSize: "10px", color: "#2563eb", fontFamily: "monospace" }}>A/C: {e.accountNo}</div>
                    </td>
                    <td>
                      <span style={{
                        display: "inline-block",
                        padding: "2px 8px",
                        borderRadius: "4px",
                        fontSize: "11px",
                        fontWeight: "600",
                        backgroundColor: e.category.includes("DSRA") ? "#eff6ff" : "#f0fdf4",
                        color: e.category.includes("DSRA") ? "#1e40af" : "#15803d"
                      }}>
                        {e.category}
                      </span>
                      <div style={{ fontSize: "11px", color: "#475569", marginTop: "3px" }}>{e.plant}</div>
                    </td>
                    <td>
                      <div style={{ fontWeight: "700", color: "#0f172a", fontSize: "13px" }}>₹{e.inflow.toFixed(1)} Cr</div>
                    </td>
                    <td>
                      <div style={{ fontWeight: "700", color: "#64748b", fontSize: "13px" }}>₹{e.outflow.toFixed(1)} Cr</div>
                    </td>
                    <td>
                      <div style={{ fontWeight: "800", color: "#059669", fontSize: "14px" }}>₹{e.balance.toFixed(1)} Cr</div>
                      {e.dsraRequirement > 0 && (
                        <div style={{ fontSize: "10px", color: "#64748b" }}>
                          Min DSRA: ₹{e.dsraRequirement.toFixed(1)} Cr
                        </div>
                      )}
                    </td>
                    <td>
                      <span className="exec-tag exec-tag-green">
                        {e.covenantStatus}
                      </span>
                      <div style={{ fontSize: "10px", color: "#64748b", marginTop: "2px" }}>
                        Audited: {e.lastAuditDate}
                      </div>
                    </td>
                    <td style={{ textAlign: "right" }}>
                      <div style={{ display: "flex", justifyContent: "flex-end", gap: "6px" }}>
                        <button
                          onClick={() => handleOpenModal(e)}
                          title="Edit Account"
                          style={{ border: "none", background: "#f1f5f9", borderRadius: "6px", padding: "6px", cursor: "pointer", color: "#059669" }}
                        >
                          <Edit2 size={15} />
                        </button>
                        <button
                          onClick={() => handleDelete(e.id)}
                          title="Delete Account"
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

export default EscrowFinancing;

