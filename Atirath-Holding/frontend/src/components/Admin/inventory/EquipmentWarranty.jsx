import React, { useState, useEffect } from "react";
import {
  ShieldCheck,
  Plus,
  Search,
  Filter,
  Download,
  Eye,
  Edit2,
  Trash2,
  Clock,
  AlertTriangle,
  CheckCircle2,
  PackageX,
  X,
  Save,
  Phone,
  Building,
  Calendar,
  FileText,
  AlertCircle,
  ArrowLeft
} from "lucide-react";
import { getEquipmentWarranties, saveEquipmentWarranty, deleteEquipmentWarranty } from "./inventoryApi";

const STORAGE_KEY = "bionova_equipment_warranty_v1";
try { const _raw = localStorage.getItem(STORAGE_KEY); if (_raw && (_raw.includes("INV-") || _raw.includes("CIV-") || _raw.includes("FST-") || _raw.includes("BN-") || _raw.includes("UltraTech") || _raw.includes("Neuman"))) { localStorage.removeItem(STORAGE_KEY); } } catch(e){}

const INITIAL_EQUIPMENT_WARRANTIES = [];

const EquipmentWarranty = ({ screenPerm }) => {
  const [warranties, setWarranties] = useState([]);

  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("All");
  const [oemFilter, setOemFilter] = useState("All");

  // Modals
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDetailModalOpen, setIsDetailModalOpen] = useState(false);
  const [isClaimModalOpen, setIsClaimModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState("add"); // 'add' | 'edit'
  const [selectedMachine, setSelectedMachine] = useState(null);

  // Form State
  const [formData, setFormData] = useState({
    assetTag: "",
    machineName: "",
    serialNo: "",
    oem: "",
    plantLocation: "Plant 1 - Hyderabad East CBG",
    purchaseDate: "",
    commissionDate: "",
    warrantyStartDate: "",
    warrantyEndDate: "",
    contractType: "Comprehensive OEM AMC",
    slaResponseHours: 24,
    serviceContact: "",
    serviceEmail: "",
    status: "Active",
    nextServiceDate: "",
    claimHistory: "None"
  });

  // Claim Form State
  const [claimSubject, setClaimSubject] = useState("");
  const [claimSeverity, setClaimSeverity] = useState("Major");

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(warranties));
  }, [warranties]);

  // Compute days remaining helper
  const getDaysRemaining = (endDateStr) => {
    if (!endDateStr) return 0;
    const today = new Date("2026-11-02"); // Consistent current date
    const target = new Date(endDateStr);
    const diffTime = target - today;
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  };

  // KPIs
  const totalCount = warranties.length;
  const activeCount = warranties.filter(w => w.status === "Active").length;
  const expiringSoonCount = warranties.filter(w => w.status === "Expiring Soon").length;
  const expiredCount = warranties.filter(w => w.status === "Expired").length;

  // Filter
  const filteredWarranties = warranties.filter(item => {
    const matchesSearch =
      item.assetTag.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.machineName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.serialNo.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.oem.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.contractType.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (item.plantLocation && item.plantLocation.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesStatus = statusFilter === "All" || item.status === statusFilter;
    const matchesOem = oemFilter === "All" || item.oem.includes(oemFilter);

    return matchesSearch && matchesStatus && matchesOem;
  });

  const handleOpenAdd = () => {
    setModalMode("add");
    setFormData({
      assetTag: `EQ-NEW-${String(Date.now()).slice(-3)}`,
      machineName: "",
      serialNo: "",
      oem: "",
      plantLocation: "Plant 1 - Hyderabad East CBG",
      purchaseDate: "2025-01-01",
      commissionDate: "2025-03-01",
      warrantyStartDate: "2025-03-01",
      warrantyEndDate: "2027-03-01",
      contractType: "Comprehensive OEM AMC",
      slaResponseHours: 24,
      serviceContact: "",
      serviceEmail: "",
      status: "Active",
      nextServiceDate: "2026-12-01",
      claimHistory: "0 Claims Filed"
    });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (item) => {
    setModalMode("edit");
    setSelectedMachine(item);
    setFormData({ ...item });
    setIsModalOpen(true);
  };

  const handleOpenDetail = (item) => {
    setSelectedMachine(item);
    setIsDetailModalOpen(true);
  };

  const handleOpenClaim = (item) => {
    setSelectedMachine(item);
    setClaimSubject("");
    setClaimSeverity("Major");
    setIsClaimModalOpen(true);
  };

  const handleDelete = (id) => {
    if (window.confirm("Are you sure you want to remove this equipment warranty registry entry?")) {
      setWarranties(warranties.filter(w => w.id !== id));
    }
  };

  const handleSaveForm = (e) => {
    e.preventDefault();
    const days = getDaysRemaining(formData.warrantyEndDate);
    let computedStatus = formData.status;
    if (days <= 0) computedStatus = "Expired";
    else if (days <= 60) computedStatus = "Expiring Soon";
    else computedStatus = "Active";

    if (modalMode === "add") {
      const newItem = {
        ...formData,
        id: Date.now(),
        status: computedStatus,
        slaResponseHours: Number(formData.slaResponseHours)
      };
      setWarranties([newItem, ...warranties]);
    } else {
      setWarranties(warranties.map(w => w.id === selectedMachine.id ? {
        ...formData,
        status: computedStatus,
        slaResponseHours: Number(formData.slaResponseHours)
      } : w));
    }
    setIsModalOpen(false);
  };

  const handleSaveClaim = (e) => {
    e.preventDefault();
    if (!claimSubject.trim()) return;

    setWarranties(warranties.map(w => {
      if (w.id === selectedMachine.id) {
        return {
          ...w,
          status: "Claim in Progress",
          claimHistory: `Active Claim Filed (${claimSeverity}): ${claimSubject} [Logged ${new Date().toISOString().slice(0, 10)}]`
        };
      }
      return w;
    }));
    alert(`Warranty Claim officially lodged with OEM (${selectedMachine.oem})! Ticket #CLM-${Date.now().toString().slice(-6)} created.`);
    setIsClaimModalOpen(false);
  };

  const handleExportCSV = () => {
    const headers = ["Asset Tag", "Machine Name", "Serial No", "OEM Manufacturer", "Plant Site", "Commission Date", "Warranty Start", "Warranty End", "Contract Type", "SLA Hours", "Service Contact", "Status", "Claim History"];
    const rows = filteredWarranties.map(w => [
      w.assetTag,
      `"${w.machineName.replace(/"/g, '""')}"`,
      w.serialNo,
      `"${w.oem}"`,
      `"${w.plantLocation}"`,
      w.commissionDate,
      w.warrantyStartDate,
      w.warrantyEndDate,
      `"${w.contractType}"`,
      w.slaResponseHours,
      `"${w.serviceContact}"`,
      w.status,
      `"${w.claimHistory || ""}"`
    ]);

    const csvContent = "data:text/csv;charset=utf-8," + [headers.join(","), ...rows.map(e => e.join(","))].join("\n");
    const link = document.createElement("a");
    link.setAttribute("href", encodeURI(csvContent));
    link.setAttribute("download", `bionova_equipment_warranties_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="submod-wrapper">
      {/* Header */}
      <div className="inv-header-section" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="inv-subtitle" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Serial-number-level tracking for heavy plant machinery, OEM details, expiration countdowns, automated lapse alerts, and active service contracts.
        </p>
        <div className="inv-header-actions" style={{ display: "flex", gap: "12px", alignItems: "center", flexShrink: 0, marginLeft: "auto" }}>
          <button className="inv-btn-secondary" onClick={handleExportCSV}>
            <Download size={16} />
            Export Registry CSV
          </button>
          {screenPerm.canCreate && (
            <button className="inv-btn-primary" onClick={handleOpenAdd}>
              <Plus size={16} />
              Register Heavy Machinery
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
                <ShieldCheck size={22} color="#1677ff" />
                {modalMode === "add" ? "Register Machinery in Warranty Registry" : "Edit Machinery Warranty Details"}
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Register critical plant machinery, serial numbers, OEM contacts, coverage expiry dates, and active AMC agreements.
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
              <ArrowLeft size={16} /> Back to Equipment Registry
            </button>
          </div>

          <form onSubmit={handleSaveForm} style={{ padding: "28px" }}>
            {/* Section 1: Machinery Identity & Manufacturer */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Building size={18} color="#1677ff" /> 1. Asset Identity & OEM Manufacturer
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Asset Tag Code *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. EQ-CMP-01"
                    value={formData.assetTag}
                    onChange={(e) => setFormData({ ...formData, assetTag: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Serial Number (Permanent Nameplate) *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. BAUER-CBG-2025-0811"
                    value={formData.serialNo}
                    onChange={(e) => setFormData({ ...formData, serialNo: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Machine / Heavy Equipment Name *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Multistage High-Pressure CBG Compressor (250 Bar)"
                    value={formData.machineName}
                    onChange={(e) => setFormData({ ...formData, machineName: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Original Equipment Manufacturer (OEM) *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Bauer Kompressoren India"
                    value={formData.oem}
                    onChange={(e) => setFormData({ ...formData, oem: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Plant Installation Site *
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

            {/* Section 2: Warranty Lifespan, AMC & OEM Contacts */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Clock size={18} color="#059669" /> 2. Warranty Lifespan, AMC Contract & Service Schedule
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Commissioning Date *
                  </label>
                  <input
                    type="date"
                    required
                    value={formData.commissionDate}
                    onChange={(e) => setFormData({ ...formData, commissionDate: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Warranty Start Date *
                  </label>
                  <input
                    type="date"
                    required
                    value={formData.warrantyStartDate}
                    onChange={(e) => setFormData({ ...formData, warrantyStartDate: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Warranty Expiration Date *
                  </label>
                  <input
                    type="date"
                    required
                    value={formData.warrantyEndDate}
                    onChange={(e) => setFormData({ ...formData, warrantyEndDate: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Service Contract Type
                  </label>
                  <select
                    value={formData.contractType}
                    onChange={(e) => setFormData({ ...formData, contractType: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Comprehensive OEM AMC">Comprehensive OEM AMC</option>
                    <option value="Non-Comprehensive AMC">Non-Comprehensive AMC</option>
                    <option value="Standard 2-Year OEM Warranty">Standard 2-Year OEM Warranty</option>
                    <option value="Full Lifecycle Care Program">Full Lifecycle Care Program</option>
                    <option value="Hydro-Testing & Structural Warranty">Hydro-Testing & Structural Warranty</option>
                    <option value="Direct OEM Warranty">Direct OEM Warranty</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    SLA Response Time (Hours) *
                  </label>
                  <input
                    type="number"
                    min="1"
                    required
                    value={formData.slaResponseHours}
                    onChange={(e) => setFormData({ ...formData, slaResponseHours: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    OEM Support Contact Person / Phone *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Rameshwar Patil (+91 98220 11982)"
                    value={formData.serviceContact}
                    onChange={(e) => setFormData({ ...formData, serviceContact: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    OEM Service Support Email
                  </label>
                  <input
                    type="email"
                    placeholder="service@oem.com"
                    value={formData.serviceEmail}
                    onChange={(e) => setFormData({ ...formData, serviceEmail: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Next Scheduled Maintenance Date
                  </label>
                  <input
                    type="date"
                    value={formData.nextServiceDate}
                    onChange={(e) => setFormData({ ...formData, nextServiceDate: e.target.value })}
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
                <Save size={16} /> {modalMode === "add" ? "Register Machinery" : "Update Details"}
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* Prominent Machinery Warranty Lapse Tracker Banner */}
      {expiringSoonCount > 0 && (
        <div style={{
          background: "linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%)",
          border: "1.5px solid #fde68a",
          borderRadius: "12px",
          padding: "16px 20px",
          marginBottom: "24px",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          flexWrap: "wrap",
          gap: "14px",
          boxShadow: "0 2px 8px rgba(217, 119, 6, 0.1)"
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: "14px" }}>
            <div style={{
              width: "44px",
              height: "44px",
              borderRadius: "50%",
              backgroundColor: "#fef3c7",
              color: "#d97706",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              border: "2px solid #f59e0b"
            }}>
              <Clock size={24} />
            </div>
            <div>
              <div style={{ fontSize: "16px", fontWeight: "800", color: "#92400e" }}>
                Machinery Warranty Lapse Alert: {expiringSoonCount} Critical Plant Units Expiring Within 60 Days!
              </div>
              <div style={{ fontSize: "13px", color: "#b45309", marginTop: "2px" }}>
                Primary CSTR Agitator Set-A (18 days remaining) and PSA Biomethane Skid (33 days remaining) require urgent OEM AMC renewal or inspection sign-off.
              </div>
            </div>
          </div>
          <button
            className="inv-btn-primary"
            style={{ backgroundColor: "#d97706", borderColor: "#b45309" }}
            onClick={() => setStatusFilter("Expiring Soon")}
          >
            Review Expiring Equipment
          </button>
        </div>
      )}

      {/* KPI Stats Grid */}
      <div className="inv-kpi-grid">
        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#eff6ff", color: "#2563eb" }}>
            <Building size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Registered Machinery</h3>
            <div className="inv-kpi-value">{totalCount} Heavy Assets</div>
            <p className="inv-kpi-subtext">Across 3 Operating Plant Sites</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#ecfdf5", color: "#059669" }}>
            <ShieldCheck size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Active OEM Warranties</h3>
            <div className="inv-kpi-value">{activeCount} Units</div>
            <p className="inv-kpi-subtext">Comprehensive Protection</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#fef3c7", color: "#d97706" }}>
            <Clock size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Expiring in &lt;60 Days</h3>
            <div className="inv-kpi-value" style={{ color: "#d97706" }}>{expiringSoonCount} Units</div>
            <p className="inv-kpi-subtext">Action Required: Initiate AMC</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#fee2e2", color: "#dc2626" }}>
            <AlertCircle size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Lapsed / Expired AMC</h3>
            <div className="inv-kpi-value" style={{ color: "#dc2626" }}>{expiredCount} Units</div>
            <p className="inv-kpi-subtext">Unprotected Machinery Risk</p>
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
              placeholder="Search by Asset Tag (EQ-CMP-01), Machine Name, Serial Number, OEM, or Service Contact..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          <div className="inv-filter-group">
            <select
              className="inv-select"
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
            >
              <option value="All">All Warranty Statuses</option>
              <option value="Active">Active (Protected)</option>
              <option value="Expiring Soon">Expiring Soon (&lt;60 Days)</option>
              <option value="Claim in Progress">Claim in Progress</option>
              <option value="Expired">Expired / Lapsed</option>
            </select>

            <select
              className="inv-select"
              value={oemFilter}
              onChange={(e) => setOemFilter(e.target.value)}
            >
              <option value="All">All OEM Manufacturers</option>
              <option value="Bauer">Bauer Kompressoren</option>
              <option value="Sulzer">Sulzer Pumps</option>
              <option value="Thermax">Thermax CleanTech</option>
              <option value="Cummins">Cummins Power</option>
              <option value="Alfa Laval">Alfa Laval</option>
              <option value="Aerzen">Aerzen Blower</option>
            </select>
          </div>
        </div>
      </div>

      {/* Equipment Warranty Table */}
      <div className="inv-table-card">
        <div className="inv-table-wrapper">
          <table className="inv-table">
            <thead>
              <tr>
                <th>Machine Name & Asset Tag</th>
                <th>Serial Number</th>
                <th>OEM Manufacturer</th>
                <th>Warranty Expiry Date</th>
                <th>Days Remaining</th>
                <th>Service Contract Type</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredWarranties.length === 0 ? (
                <tr>
                  <td colSpan="8" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                    No machinery matches the selected warranty filters.
                  </td>
                </tr>
              ) : (
                filteredWarranties.map((item) => {
                  const days = getDaysRemaining(item.warrantyEndDate);
                  return (
                    <tr key={item.id}>
                      <td>
                        <div style={{ fontWeight: "700", color: "#0f172a" }}>{item.machineName}</div>
                        <div style={{ fontSize: "12px", color: "#2563eb", fontWeight: "700", fontFamily: "monospace" }}>{item.assetTag}</div>
                      </td>
                      <td>
                        <span style={{ fontFamily: "monospace", fontSize: "13px", fontWeight: "600", color: "#334155" }}>
                          {item.serialNo}
                        </span>
                      </td>
                      <td>
                        <div style={{ fontWeight: "600", color: "#1e293b", fontSize: "13px" }}>{item.oem}</div>
                        <div style={{ fontSize: "11px", color: "#64748b" }}>{item.plantLocation}</div>
                      </td>
                      <td>
                        <div style={{ fontWeight: "700", fontSize: "13px" }}>{item.warrantyEndDate}</div>
                        <div style={{ fontSize: "11px", color: "#64748b" }}>Commissioned: {item.commissionDate}</div>
                      </td>
                      <td>
                        <span style={{
                          fontWeight: "800",
                          fontSize: "13px",
                          color: days <= 0 ? "#dc2626" : days <= 60 ? "#d97706" : "#059669"
                        }}>
                          {days <= 0 ? "Lapsed (0 Days)" : `${days} Days Left`}
                        </span>
                      </td>
                      <td>
                        <div style={{ fontSize: "13px", fontWeight: "600", color: "#334155" }}>{item.contractType}</div>
                        <div style={{ fontSize: "11px", color: "#64748b" }}>SLA: {item.slaResponseHours}h response</div>
                      </td>
                      <td>
                        <span className={`inv-status-pill ${
                          item.status === "Active" ? "inv-status-in" :
                          item.status === "Expiring Soon" ? "inv-status-low" :
                          item.status === "Claim in Progress" ? "inv-badge-agro" : "inv-status-out"
                        }`}>
                          {item.status}
                        </span>
                      </td>
                      <td>
                        <div className="inv-table-actions">
                          {screenPerm.canEdit && item.status !== "Expired" && (
                            <button
                              className="inv-icon-btn"
                              title="Log OEM Warranty Claim"
                              onClick={() => handleOpenClaim(item)}
                            >
                              <AlertCircle size={15} color="#d97706" />
                            </button>
                          )}
                          <button
                            className="inv-icon-btn"
                            title="View Full Warranty Certificate"
                            onClick={() => handleOpenDetail(item)}
                          >
                            <Eye size={15} />
                          </button>
                          {screenPerm.canEdit && (
                            <button
                              className="inv-icon-btn"
                              title="Edit Registry Entry"
                              onClick={() => handleOpenEdit(item)}
                            >
                              <Edit2 size={15} />
                            </button>
                          )}
                          {screenPerm.canDelete && (
                            <button
                              className="inv-icon-btn danger"
                              title="Delete Registry"
                              onClick={() => handleDelete(item.id)}
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

      {/* Log Warranty Claim Modal */}
      {isClaimModalOpen && selectedMachine && (
        <div className="inv-modal-overlay" onClick={() => setIsClaimModalOpen(false)}>
          <div className="inv-modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: "600px" }}>
            <div className="inv-modal-header" style={{ borderBottom: "2px solid #d97706" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                <AlertCircle size={22} color="#d97706" />
                <h2 style={{ margin: 0, fontSize: "18px" }}>Log Official Warranty Claim</h2>
              </div>
              <button className="inv-modal-close" onClick={() => setIsClaimModalOpen(false)}>
                <X size={20} />
              </button>
            </div>
            <form onSubmit={handleSaveClaim}>
              <div className="inv-modal-body">
                <div style={{ backgroundColor: "#fffbeb", padding: "14px", borderRadius: "8px", border: "1px solid #fde68a", marginBottom: "16px" }}>
                  <div style={{ fontWeight: "700", color: "#92400e" }}>{selectedMachine.machineName}</div>
                  <div style={{ fontSize: "13px", color: "#b45309", marginTop: "4px" }}>
                    Serial No: <strong>{selectedMachine.serialNo}</strong> | OEM: <strong>{selectedMachine.oem}</strong>
                  </div>
                  <div style={{ fontSize: "12px", color: "#78350f", marginTop: "4px" }}>
                    Contract SLA: <strong>{selectedMachine.slaResponseHours} Hours</strong> | Contact: {selectedMachine.serviceContact}
                  </div>
                </div>

                <div className="inv-form-group" style={{ marginBottom: "14px" }}>
                  <label>Claim Breakdown Severity</label>
                  <select
                    className="inv-select"
                    value={claimSeverity}
                    onChange={(e) => setClaimSeverity(e.target.value)}
                  >
                    <option value="Critical (Plant Stopped)">Critical (Plant Stopped / Gas Line Isolated)</option>
                    <option value="Major (Performance Degraded)">Major (Performance Degraded / High Vibration)</option>
                    <option value="Minor (Preventive Part Wear)">Minor (Preventive Part Wear / Leakage)</option>
                  </select>
                </div>

                <div className="inv-form-group">
                  <label>Defect Description & Incident Context</label>
                  <textarea
                    className="inv-textarea"
                    rows="4"
                    value={claimSubject}
                    onChange={(e) => setClaimSubject(e.target.value)}
                    placeholder="Describe specific component breakdown (e.g. 3rd-stage piston ring failure, high bearing temperature 94°C, seal rupture, etc.)"
                    required
                  />
                </div>
              </div>
              <div className="inv-modal-footer">
                <button type="button" className="inv-btn-secondary" onClick={() => setIsClaimModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="inv-btn-primary" style={{ backgroundColor: "#d97706" }}>
                  <AlertCircle size={16} />
                  Submit Official Claim to OEM
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* View Full Warranty Certificate Sheet */}
      {isDetailModalOpen && selectedMachine && (
        <div className="inv-modal-overlay" onClick={() => setIsDetailModalOpen(false)}>
          <div className="inv-modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: "680px" }}>
            <div className="inv-modal-header" style={{ borderBottom: "2px solid #059669" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                <ShieldCheck size={22} color="#059669" />
                <div>
                  <h2 style={{ margin: 0, fontSize: "18px" }}>Heavy Machinery Warranty Dossier</h2>
                  <span style={{ fontSize: "12px", color: "#64748b" }}>Asset: {selectedMachine.assetTag}</span>
                </div>
              </div>
              <button className="inv-modal-close" onClick={() => setIsDetailModalOpen(false)}>
                <X size={20} />
              </button>
            </div>
            <div className="inv-modal-body">
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "14px", marginBottom: "16px" }}>
                <div style={{ gridColumn: "span 2" }}>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>Equipment Description</div>
                  <div style={{ fontWeight: "700", fontSize: "16px", color: "#0f172a" }}>{selectedMachine.machineName}</div>
                </div>
                <div>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>Serial Number</div>
                  <div style={{ fontWeight: "700", fontFamily: "monospace", color: "#1e40af" }}>{selectedMachine.serialNo}</div>
                </div>
                <div>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>OEM Manufacturer</div>
                  <div style={{ fontWeight: "700" }}>{selectedMachine.oem}</div>
                </div>
                <div>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>Operating Plant Site</div>
                  <div style={{ fontWeight: "600" }}>{selectedMachine.plantLocation}</div>
                </div>
                <div>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>Warranty Validity Period</div>
                  <div style={{ fontWeight: "700", color: "#059669" }}>{selectedMachine.warrantyStartDate} to {selectedMachine.warrantyEndDate}</div>
                </div>
                <div>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>Contract Agreement Type</div>
                  <div style={{ fontWeight: "600" }}>{selectedMachine.contractType}</div>
                </div>
                <div>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>Emergency SLA</div>
                  <div style={{ fontWeight: "700", color: "#b45309" }}>{selectedMachine.slaResponseHours} Hours Guaranteed</div>
                </div>
                <div style={{ gridColumn: "span 2" }}>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>OEM Support Contact Desk</div>
                  <div style={{ fontWeight: "600" }}>{selectedMachine.serviceContact} | {selectedMachine.serviceEmail}</div>
                </div>
                <div style={{ gridColumn: "span 2", backgroundColor: "#f8fafc", padding: "12px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>Lifecycle Service & Claim History</div>
                  <div style={{ fontSize: "13px", color: "#334155", marginTop: "4px" }}>{selectedMachine.claimHistory || "None"}</div>
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

export default EquipmentWarranty;

