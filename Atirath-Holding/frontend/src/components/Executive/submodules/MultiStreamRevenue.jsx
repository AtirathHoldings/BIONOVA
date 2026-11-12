import React, { useState, useEffect } from "react";
import {
  TrendingUp,
  Search,
  Filter,
  Plus,
  Download,
  DollarSign,
  CheckCircle2,
  Clock,
  AlertCircle,
  Edit2,
  Trash2,
  FileText,
  X,
  CreditCard,
  Building,
  Flame,
  Sprout,
  Wind,
  Truck,
  ArrowLeft,
  Save
} from "lucide-react";
import { getRevenueRecords, saveRevenueRecord, deleteRevenueRecord } from "./executiveApi";

const INITIAL_TRANSACTIONS = [];

const STREAMS = [
  "All Streams",
  "Compressed Biogas (CBG)",
  "Fermented Organic Manure (FOM)",
  "Carbon Offset Credits (CERs)",
  "Municipal Tipping Fees"
];

const MultiStreamRevenue = () => {
  const [transactions, setTransactions] = useState(INITIAL_TRANSACTIONS);

  useEffect(() => {
    getRevenueRecords().then(data => {
      if (Array.isArray(data) && data.length > 0) setTransactions(data);
    }).catch(err => console.warn("Failed to load revenue records:", err));
  }, []);
  const [searchQuery, setSearchQuery] = useState("");
  const [streamFilter, setStreamFilter] = useState("All Streams");
  const [statusFilter, setStatusFilter] = useState("All");
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState(null);

  const [formData, setFormData] = useState({
    id: "",
    stream: "Compressed Biogas (CBG)",
    offtaker: "",
    volume: "",
    unitRate: "",
    amount: "",
    invoiceDate: "",
    dueDate: "",
    paymentStatus: "Pending",
    utr: "-",
    plant: "Plant 1 - Hyderabad East"
  });

  const filteredTransactions = transactions.filter((t) => {
    const matchesSearch =
      t.offtaker.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.plant.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStream = streamFilter === "All Streams" || t.stream === streamFilter;
    const matchesStatus = statusFilter === "All" || t.paymentStatus === statusFilter;
    return matchesSearch && matchesStream && matchesStatus;
  });

  const totalRevenue = transactions.reduce((sum, t) => sum + Number(t.amount || 0), 0);
  const settledRevenue = transactions
    .filter((t) => t.paymentStatus === "Settled")
    .reduce((sum, t) => sum + Number(t.amount || 0), 0);
  const pendingRevenue = transactions
    .filter((t) => t.paymentStatus === "Pending")
    .reduce((sum, t) => sum + Number(t.amount || 0), 0);
  const overdueRevenue = transactions
    .filter((t) => t.paymentStatus === "Overdue")
    .reduce((sum, t) => sum + Number(t.amount || 0), 0);

  // Breakdown by stream
  const cbgTotal = transactions.filter((t) => t.stream.includes("Biogas")).reduce((s, t) => s + t.amount, 0);
  const fomTotal = transactions.filter((t) => t.stream.includes("Manure")).reduce((s, t) => s + t.amount, 0);
  const cerTotal = transactions.filter((t) => t.stream.includes("Carbon")).reduce((s, t) => s + t.amount, 0);
  const tipTotal = transactions.filter((t) => t.stream.includes("Tipping")).reduce((s, t) => s + t.amount, 0);

  const handleOpenModal = (item = null) => {
    if (item) {
      setEditingItem(item);
      setFormData(item);
    } else {
      setEditingItem(null);
      const nextId = `REV-INV-2026-${transactions.length + 120}`;
      setFormData({
        id: nextId,
        stream: "Compressed Biogas (CBG)",
        offtaker: "",
        volume: "100.0 MT",
        unitRate: "₹76.00 / kg",
        amount: 7600000,
        invoiceDate: new Date().toISOString().split("T")[0],
        dueDate: "2026-12-15",
        paymentStatus: "Pending",
        utr: "-",
        plant: "Plant 1 - Hyderabad East"
      });
    }
    setIsModalOpen(true);
  };

  const handleSave = (e) => {
    e.preventDefault();
    if (!formData.offtaker || !formData.amount) {
      alert("Please provide Offtaker and Amount.");
      return;
    }
    const cleanItem = {
      ...formData,
      amount: Number(formData.amount)
    };

    if (editingItem) {
      setTransactions((prev) =>
        prev.map((t) => (t.id === editingItem.id ? cleanItem : t))
      );
    } else {
      setTransactions((prev) => [cleanItem, ...prev]);
    }
    setIsModalOpen(false);
  };

  const handleDelete = (id) => {
    if (window.confirm(`Delete revenue invoice ${id}?`)) {
      deleteRevenueRecord(id).catch(err => console.warn(err));
      setTransactions((prev) => prev.filter((t) => t.id !== id));
    }
  };

  const handleExportCSV = () => {
    const headers = "Invoice ID,Stream,Offtaker,Volume,Unit Rate,Amount (INR),Invoice Date,Due Date,Status,UTR Ref,Plant Site\n";
    const rows = filteredTransactions
      .map(
        (t) =>
          `"${t.id}","${t.stream}","${t.offtaker}","${t.volume}","${t.unitRate}","${t.amount}","${t.invoiceDate}","${t.dueDate}","${t.paymentStatus}","${t.utr}","${t.plant}"`
      )
      .join("\n");
    const blob = new Blob([headers + rows], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `BioNova_MultiStream_Revenue_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
  };

  const formatINR = (val) => {
    if (val >= 10000000) {
      return `₹${(val / 10000000).toFixed(2)} Cr`;
    }
    if (val >= 100000) {
      return `₹${(val / 100000).toFixed(2)} Lac`;
    }
    return `₹${val.toLocaleString()}`;
  };

  return (
    <div style={{ paddingBottom: "30px" }}>
      {/* Title & Banner */}
      <div className="exec-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="exec-subtitle" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Multi-stream revenue telemetry aggregating CBG cascade off-takes, organic manure sales, carbon credits (CERs), and municipal tipping fees.
        </p>

        <div className="exec-controls" style={{ display: "flex", gap: "12px", alignItems: "center", flexShrink: 0, marginLeft: "auto" }}>
          <button className="exec-btn-print" onClick={handleExportCSV} style={{ background: "#059669" }}>
            <Download size={15} /> Export Revenue CSV
          </button>
          <button className="exec-btn-print" onClick={() => handleOpenModal()}>
            <Plus size={16} /> Record Revenue Invoice
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
                <TrendingUp size={22} color="#1677ff" />
                {editingItem ? "Edit Revenue Invoice" : "Record Revenue Invoice"}
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Record enterprise off-take invoices across CBG volumes, organic fertilizer, carbon offsets, and tipping tariffs.
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
              <ArrowLeft size={16} /> Back to Revenue Sourcing
            </button>
          </div>

          <form onSubmit={handleSave} style={{ padding: "28px" }}>
            {/* Section 1: Invoice & Offtaker Details */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Building size={18} color="#1677ff" /> 1. Invoice Identification & Offtaker
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Invoice ID *
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
                    Revenue Stream *
                  </label>
                  <select
                    value={formData.stream}
                    onChange={(e) => setFormData({ ...formData, stream: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Compressed Biogas (CBG)">Compressed Biogas (CBG)</option>
                    <option value="Fermented Organic Manure (FOM)">Fermented Organic Manure (FOM)</option>
                    <option value="Carbon Offset Credits (CERs)">Carbon Offset Credits (CERs)</option>
                    <option value="Municipal Tipping Fees">Municipal Tipping Fees</option>
                  </select>
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Offtaker / Buyer / Municipal Corporation *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Indian Oil Corporation Ltd (IOCL)"
                    value={formData.offtaker}
                    onChange={(e) => setFormData({ ...formData, offtaker: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Plant Site
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
                    Offtake Volume & Unit
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. 150 MT or 5,000 Credits"
                    value={formData.volume}
                    onChange={(e) => setFormData({ ...formData, volume: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>
              </div>
            </div>

            {/* Section 2: Financial Valuation & Settlement */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <DollarSign size={18} color="#059669" /> 2. Invoice Financials & Settlement Status
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Unit Rate
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. ₹76.00 / kg"
                    value={formData.unitRate}
                    onChange={(e) => setFormData({ ...formData, unitRate: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Total Invoice Amount (₹ INR) *
                  </label>
                  <input
                    type="number"
                    required
                    value={formData.amount}
                    onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Invoice Date
                  </label>
                  <input
                    type="date"
                    value={formData.invoiceDate}
                    onChange={(e) => setFormData({ ...formData, invoiceDate: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Due Date
                  </label>
                  <input
                    type="date"
                    value={formData.dueDate}
                    onChange={(e) => setFormData({ ...formData, dueDate: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Payment Status
                  </label>
                  <select
                    value={formData.paymentStatus}
                    onChange={(e) => setFormData({ ...formData, paymentStatus: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Pending">Pending</option>
                    <option value="Settled">Settled (Received)</option>
                    <option value="Overdue">Overdue</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Bank UTR Reference
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. IOCL/RTGS/992144"
                    value={formData.utr}
                    onChange={(e) => setFormData({ ...formData, utr: e.target.value })}
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
                  backgroundColor: "#1677ff",
                  color: "#ffffff",
                  fontWeight: "600",
                  fontSize: "13.5px",
                  cursor: "pointer",
                  boxShadow: "0 2px 4px rgba(22, 119, 255, 0.25)"
                }}
              >
                <Save size={16} /> {editingItem ? "Update Invoice" : "Save Invoice"}
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* KPI Cards */}
      <div className="exec-fin-metrics" style={{ gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))", marginBottom: "24px" }}>
        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">TOTAL BOOKED REVENUE</div>
          <div className="exec-fin-tile-val">{formatINR(totalRevenue)}</div>
          <div className="exec-fin-tile-sub" style={{ color: "#059669" }}>
            Settled: {formatINR(settledRevenue)} ({totalRevenue > 0 ? Math.round((settledRevenue / totalRevenue) * 100) : 0}%)
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">CBG SALES REALIZATION</div>
          <div className="exec-fin-tile-val">{formatINR(cbgTotal)}</div>
          <div className="exec-fin-tile-sub" style={{ color: "#2563eb" }}>
            {totalRevenue > 0 ? Math.round((cbgTotal / totalRevenue) * 100) : 0}% of Total Revenue Portfolio
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">CARBON CREDIT MONETIZATION</div>
          <div className="exec-fin-tile-val">{formatINR(cerTotal)}</div>
          <div className="exec-fin-tile-sub" style={{ color: cerTotal > 0 ? "#059669" : "#64748b" }}>
            {cerTotal > 0 ? "Verified Carbon Credits Active" : "No Active Carbon Credits"}
          </div>
        </div>

        <div className="exec-fin-tile">
          <div className="exec-fin-tile-label">RECEIVABLES & OVERDUE</div>
          <div className="exec-fin-tile-val" style={{ color: overdueRevenue > 0 ? "#dc2626" : "#f59e0b" }}>
            {formatINR(pendingRevenue + overdueRevenue)}
          </div>
          <div className="exec-fin-tile-sub" style={{ color: overdueRevenue > 0 ? "#dc2626" : "#64748b" }}>
            Overdue: {formatINR(overdueRevenue)}
          </div>
        </div>
      </div>

      {/* Revenue Stream Contributions Matrix */}
      <div style={{
        background: "#ffffff",
        borderRadius: "12px",
        padding: "18px 24px",
        border: "1px solid #e2e8f0",
        marginBottom: "20px"
      }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "14px" }}>
          <h3 style={{ margin: 0, fontSize: "14px", fontWeight: "700", color: "#0f172a" }}>
            Revenue Stream Distribution Portfolio
          </h3>
          <span style={{ fontSize: "12px", color: "#64748b" }}>
            Target: 60% CBG, 20% FOM, 15% CERs, 5% Municipal
          </span>
        </div>

        <div style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
          gap: "14px"
        }}>
          <div style={{ background: "#eff6ff", padding: "12px 14px", borderRadius: "8px", borderLeft: "4px solid #2563eb" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "12px", fontWeight: "700", color: "#1e40af" }}>
              <Flame size={14} /> CBG Cascade Offtakes
            </div>
            <div style={{ fontSize: "18px", fontWeight: "800", color: "#0f172a", marginTop: "4px" }}>
              {formatINR(cbgTotal)}
            </div>
            <div style={{ fontSize: "11px", color: "#64748b" }}>
              {totalRevenue > 0 ? Math.round((cbgTotal / totalRevenue) * 100) : 0}% share
            </div>
          </div>

          <div style={{ background: "#f0fdf4", padding: "12px 14px", borderRadius: "8px", borderLeft: "4px solid #10b981" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "12px", fontWeight: "700", color: "#166534" }}>
              <Sprout size={14} /> Organic Fertilizer (FOM)
            </div>
            <div style={{ fontSize: "18px", fontWeight: "800", color: "#0f172a", marginTop: "4px" }}>
              {formatINR(fomTotal)}
            </div>
            <div style={{ fontSize: "11px", color: "#64748b" }}>
              {totalRevenue > 0 ? Math.round((fomTotal / totalRevenue) * 100) : 0}% share
            </div>
          </div>

          <div style={{ background: "#f5f3ff", padding: "12px 14px", borderRadius: "8px", borderLeft: "4px solid #7c3aed" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "12px", fontWeight: "700", color: "#5b21b6" }}>
              <Wind size={14} /> Carbon Credits (CERs)
            </div>
            <div style={{ fontSize: "18px", fontWeight: "800", color: "#0f172a", marginTop: "4px" }}>
              {formatINR(cerTotal)}
            </div>
            <div style={{ fontSize: "11px", color: "#64748b" }}>
              {totalRevenue > 0 ? Math.round((cerTotal / totalRevenue) * 100) : 0}% share
            </div>
          </div>

          <div style={{ background: "#fffbeb", padding: "12px 14px", borderRadius: "8px", borderLeft: "4px solid #f59e0b" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "12px", fontWeight: "700", color: "#92400e" }}>
              <Truck size={14} /> Municipal Tipping Fees
            </div>
            <div style={{ fontSize: "18px", fontWeight: "800", color: "#0f172a", marginTop: "4px" }}>
              {formatINR(tipTotal)}
            </div>
            <div style={{ fontSize: "11px", color: "#64748b" }}>
              {Math.round((tipTotal / (totalRevenue || 1)) * 100)}% share
            </div>
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
              placeholder="Search by offtaker, invoice ID, or plant..."
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
            value={streamFilter}
            onChange={(e) => setStreamFilter(e.target.value)}
          >
            {STREAMS.map((s, idx) => (
              <option key={idx} value={s}>{s}</option>
            ))}
          </select>

          <select
            className="exec-select"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="All">All Payment Statuses</option>
            <option value="Settled">Settled (Received)</option>
            <option value="Pending">Pending</option>
            <option value="Overdue">Overdue</option>
          </select>
        </div>
      </div>

      {/* Table Card */}
      <div className="exec-card" style={{ padding: "0", overflow: "hidden" }}>
        <div style={{ padding: "16px 20px", borderBottom: "1px solid #f1f5f9", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <h3 style={{ margin: 0, fontSize: "15px", fontWeight: "700", color: "#0f172a" }}>
            Enterprise Invoices & Revenue Telemetry ({filteredTransactions.length})
          </h3>
          <span style={{ fontSize: "12px", color: "#64748b" }}>
            Real-time synchronization with SATAT & Bio-Fertilizer Offtake agreements
          </span>
        </div>

        <div style={{ overflowX: "auto" }}>
          <table className="exec-dept-table" style={{ margin: 0 }}>
            <thead>
              <tr>
                <th>Invoice & Stream</th>
                <th>Offtaker & Facility</th>
                <th>Offtake Volume & Rate</th>
                <th>Invoice Amount</th>
                <th>Billing Dates</th>
                <th>Status</th>
                <th style={{ textAlign: "right" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredTransactions.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                    No revenue transactions found matching filters.
                  </td>
                </tr>
              ) : (
                filteredTransactions.map((t) => (
                  <tr key={t.id}>
                    <td>
                      <div style={{ fontWeight: "700", color: "#0f172a", fontSize: "13px" }}>{t.id}</div>
                      <div style={{ fontSize: "11px", color: "#2563eb", fontWeight: "600" }}>{t.stream}</div>
                      <div style={{ fontSize: "10px", color: "#64748b" }}>UTR: {t.utr}</div>
                    </td>
                    <td>
                      <div style={{ fontWeight: "700", color: "#0f172a", fontSize: "13px" }}>{t.offtaker}</div>
                      <div style={{ fontSize: "11px", color: "#64748b" }}>{t.plant}</div>
                    </td>
                    <td>
                      <div style={{ fontWeight: "600", color: "#0f172a", fontSize: "13px" }}>{t.volume}</div>
                      <div style={{ fontSize: "11px", color: "#64748b" }}>{t.unitRate}</div>
                    </td>
                    <td>
                      <div style={{ fontWeight: "800", color: "#0f172a", fontSize: "14px" }}>
                        {formatINR(t.amount)}
                      </div>
                      <div style={{ fontSize: "10px", color: "#64748b" }}>
                        ₹{t.amount.toLocaleString()}
                      </div>
                    </td>
                    <td>
                      <div style={{ fontSize: "12px", color: "#0f172a" }}>Inv: {t.invoiceDate}</div>
                      <div style={{ fontSize: "11px", color: t.paymentStatus === "Overdue" ? "#dc2626" : "#64748b" }}>
                        Due: {t.dueDate}
                      </div>
                    </td>
                    <td>
                      <span className={`exec-tag ${
                        t.paymentStatus === "Settled"
                          ? "exec-tag-green"
                          : t.paymentStatus === "Pending"
                          ? "exec-tag-blue"
                          : "exec-tag-amber"
                      }`}>
                        {t.paymentStatus}
                      </span>
                    </td>
                    <td style={{ textAlign: "right" }}>
                      <div style={{ display: "flex", justifyContent: "flex-end", gap: "6px" }}>
                        <button
                          onClick={() => handleOpenModal(t)}
                          title="Edit Transaction"
                          style={{ border: "none", background: "#f1f5f9", borderRadius: "6px", padding: "6px", cursor: "pointer", color: "#059669" }}
                        >
                          <Edit2 size={15} />
                        </button>
                        <button
                          onClick={() => handleDelete(t.id)}
                          title="Delete Record"
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

export default MultiStreamRevenue;

