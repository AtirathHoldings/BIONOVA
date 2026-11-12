import React, { useState, useEffect } from "react";
import {
  Users,
  Building,
  Plus,
  Search,
  Filter,
  Download,
  Eye,
  Edit2,
  Trash2,
  CheckCircle2,
  AlertTriangle,
  Clock,
  Star,
  FileText,
  CreditCard,
  ShieldCheck,
  Phone,
  Mail,
  MapPin,
  X,
  Save,
  Award,
  Sparkles,
  TrendingUp,
  Percent,
  Layers,
  ChevronRight,
  ExternalLink,
  RotateCcw,
  ArrowLeft
} from "lucide-react";
import { getInventoryVendors, saveInventoryVendor, deleteInventoryVendor } from "./inventoryApi";
import "../../../styles/InventoryManagement.css";
import { getScreenPermission } from "../../../utils/permissions";

const STORAGE_KEY = "bionova_vendor_management_v1";
try {
  localStorage.removeItem(STORAGE_KEY);
} catch (e) {}

const INITIAL_VENDORS = [];

const TIERS = [
  "All Tiers",
  "Tier 1 - Strategic EPC / OEM",
  "Tier 2 - Equipment / Fabricator",
  "Tier 3 - Feedstock & Consumables"
];

const CATEGORIES = [
  "All Categories",
  "Plant Construction & Civil",
  "Piping & Valves",
  "Gas Upgradation & Compressors",
  "Biomass Feedstock & Silage",
  "Structural Hardware & Fasteners"
];

const MSME_CLASSES = [
  "All MSME Classes",
  "Micro Enterprise",
  "Small Enterprise",
  "Medium Enterprise",
  "Large / Non-MSME"
];

const GRADES = [
  "All Grades",
  "Grade A+ (Preferred Partner)",
  "Grade A (Qualified)",
  "Grade B (Monitored)"
];

const MultiTierVendorDatabase = ({ screenPerm: propPerm }) => {
  const perm = propPerm || getScreenPermission("INVENTORY_MANAGEMENT");

  const [vendors, setVendors] = useState([]);

  useEffect(() => {
    getInventoryVendors()
      .then((data) => {
        if (Array.isArray(data)) setVendors(data);
      })
      .catch((err) => console.warn("Failed to load inventory vendors:", err));
  }, []);

  const [searchTerm, setSearchTerm] = useState("");
  const [tierFilter, setTierFilter] = useState("All Tiers");
  const [categoryFilter, setCategoryFilter] = useState("All Categories");
  const [msmeFilter, setMsmeFilter] = useState("All MSME Classes");
  const [gradeFilter, setGradeFilter] = useState("All Grades");

  // Modal States
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDetailModalOpen, setIsDetailModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState("add"); // 'add' | 'edit'
  const [selectedVendor, setSelectedVendor] = useState(null);

  // Form State
  const [formData, setFormData] = useState({
    vendorCode: "",
    name: "",
    tier: "Tier 1 - Strategic EPC / OEM",
    category: "Plant Construction & Civil",
    gstin: "",
    panNo: "",
    msmeStatus: "Medium Enterprise",
    udyamRegNo: "",
    contactPerson: "",
    phone: "",
    email: "",
    address: "",
    plantLocation: "Plant 1 - Hyderabad East CBG",
    ratingStars: 4.8,
    onTimeDeliveryRate: 95.0,
    qualityAcceptanceRate: 99.0,
    performanceGrade: "Grade A+ (Preferred Partner)",
    paymentTerms: "Net 30 Days",
    creditLimit: 5.0,
    activeContractRef: "",
    contractStartDate: "2026-01-01",
    contractEndDate: "2027-12-31",
    slaResponseHours: 24,
    slaStatus: "100% Compliant",
    notes: ""
  });

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(vendors));
  }, [vendors]);

  // KPIs
  const totalCount = vendors.length;
  const tier1Count = vendors.filter(v => v.tier.includes("Tier 1")).length;
  const tier2Count = vendors.filter(v => v.tier.includes("Tier 2")).length;
  const tier3Count = vendors.filter(v => v.tier.includes("Tier 3")).length;
  const msmeCount = vendors.filter(v => v.msmeStatus !== "Large / Non-MSME").length;
  const msmePercent = totalCount > 0 ? Math.round((msmeCount / totalCount) * 100) : 0;
  const totalCreditExposure = vendors.reduce((sum, v) => sum + Number(v.creditLimit || 0), 0);
  const avgOnTime = totalCount > 0 ? (vendors.reduce((s, v) => s + Number(v.onTimeDeliveryRate || 0), 0) / totalCount).toFixed(1) : "0.0";
  const avgQuality = totalCount > 0 ? (vendors.reduce((s, v) => s + Number(v.qualityAcceptanceRate || 0), 0) / totalCount).toFixed(1) : "0.0";

  // Filter Logic
  const filteredVendors = vendors.filter(item => {
    const term = searchTerm.toLowerCase();
    const matchesSearch =
      item.vendorCode.toLowerCase().includes(term) ||
      item.name.toLowerCase().includes(term) ||
      item.gstin.toLowerCase().includes(term) ||
      item.contactPerson.toLowerCase().includes(term) ||
      item.category.toLowerCase().includes(term) ||
      (item.udyamRegNo && item.udyamRegNo.toLowerCase().includes(term));

    const matchesTier = tierFilter === "All Tiers" || item.tier === tierFilter;
    const matchesCategory = categoryFilter === "All Categories" || item.category === categoryFilter;
    const matchesMsme = msmeFilter === "All MSME Classes" || item.msmeStatus === msmeFilter;
    const matchesGrade = gradeFilter === "All Grades" || item.performanceGrade === gradeFilter;

    return matchesSearch && matchesTier && matchesCategory && matchesMsme && matchesGrade;
  });

  const handleOpenAdd = () => {
    setModalMode("add");
    setFormData({
      vendorCode: `VND-T${Math.floor(Math.random() * 2) + 1}-0${vendors.length + 1}`,
      name: "",
      tier: "Tier 1 - Strategic EPC / OEM",
      category: "Plant Construction & Civil",
      gstin: "36AAACB" + Math.floor(1000 + Math.random() * 9000) + "F1Z5",
      panNo: "AAACB" + Math.floor(1000 + Math.random() * 9000) + "F",
      msmeStatus: "Small Enterprise",
      udyamRegNo: `UDYAM-TS-02-00${Math.floor(1000 + Math.random() * 9000)}`,
      contactPerson: "",
      phone: "+91 98490 ",
      email: "",
      address: "Industrial Growth Corridor, Telangana",
      plantLocation: "Plant 1 - Hyderabad East CBG",
      ratingStars: 4.8,
      onTimeDeliveryRate: 96.0,
      qualityAcceptanceRate: 98.8,
      performanceGrade: "Grade A+ (Preferred Partner)",
      paymentTerms: "Net 30 Days",
      creditLimit: 5.0,
      activeContractRef: `VND-BN-SLA-${new Date().getFullYear()}-0${vendors.length + 1}`,
      contractStartDate: new Date().toISOString().slice(0, 10),
      contractEndDate: "2027-12-31",
      slaResponseHours: 24,
      slaStatus: "100% Compliant",
      notes: "Registered vendor for BioNova industrial supply chain and plant fabrication."
    });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (item) => {
    setModalMode("edit");
    setSelectedVendor(item);
    setFormData({ ...item });
    setIsModalOpen(true);
  };

  const handleOpenDetail = (item) => {
    setSelectedVendor(item);
    setIsDetailModalOpen(true);
  };

  const handleDelete = (id) => {
    if (!window.confirm("Are you sure you want to remove this vendor from the database?")) return;
    setVendors(vendors.filter(v => v.id !== id));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!formData.name.trim() || !formData.gstin.trim()) {
      alert("Please provide Vendor Name and GSTIN.");
      return;
    }

    if (modalMode === "add") {
      const newItem = {
        ...formData,
        id: Date.now(),
        ratingStars: Number(formData.ratingStars),
        onTimeDeliveryRate: Number(formData.onTimeDeliveryRate),
        qualityAcceptanceRate: Number(formData.qualityAcceptanceRate),
        creditLimit: Number(formData.creditLimit)
      };
      setVendors([newItem, ...vendors]);
    } else {
      setVendors(vendors.map(v => v.id === selectedVendor.id ? {
        ...formData,
        id: selectedVendor.id,
        ratingStars: Number(formData.ratingStars),
        onTimeDeliveryRate: Number(formData.onTimeDeliveryRate),
        qualityAcceptanceRate: Number(formData.qualityAcceptanceRate),
        creditLimit: Number(formData.creditLimit)
      } : v));
    }
    setIsModalOpen(false);
  };

  const handleExportCSV = () => {
    const headers = [
      "Vendor Code",
      "Company Name",
      "Supplier Tier",
      "Category",
      "GSTIN",
      "PAN Number",
      "MSME Status",
      "Udyam Reg No",
      "Contact Person",
      "Phone",
      "Email",
      "Star Rating",
      "On-Time Delivery %",
      "Quality Acceptance %",
      "Performance Grade",
      "Payment Terms",
      "Credit Limit (Cr)",
      "Contract Reference",
      "SLA Response Hours",
      "SLA Status",
      "Plant Site"
    ];

    const rows = filteredVendors.map(v => [
      v.vendorCode,
      `"${v.name.replace(/"/g, '""')}"`,
      `"${v.tier}"`,
      `"${v.category}"`,
      v.gstin,
      v.panNo,
      `"${v.msmeStatus}"`,
      `"${v.udyamRegNo || "N/A"}"`,
      `"${v.contactPerson}"`,
      `"${v.phone}"`,
      v.email,
      v.ratingStars,
      `${v.onTimeDeliveryRate}%`,
      `${v.qualityAcceptanceRate}%`,
      `"${v.performanceGrade}"`,
      `"${v.paymentTerms}"`,
      `₹${v.creditLimit} Cr`,
      `"${v.activeContractRef}"`,
      `${v.slaResponseHours} Hrs`,
      `"${v.slaStatus}"`,
      `"${v.plantLocation}"`
    ]);

    const csvContent = "data:text/csv;charset=utf-8," + [headers.join(","), ...rows.map(e => e.join(","))].join("\n");
    const link = document.createElement("a");
    link.setAttribute("href", encodeURI(csvContent));
    link.setAttribute("download", `bionova_vendor_performance_ledger_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="submod-wrapper">
      {/* Title & Action Header */}
      <div className="inv-header-section" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="inv-subtitle" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Multi-Tier supplier database tracking validated GSTIN/PAN tax credentials, MSME Udyam status, star quality ratings, payment terms, and active SLA contract compliance.
        </p>
        <div className="inv-header-actions" style={{ display: "flex", gap: "12px", alignItems: "center", flexShrink: 0, marginLeft: "auto" }}>
          <button className="inv-btn-secondary" onClick={handleExportCSV}>
            <Download size={16} />
            Export Ledger CSV
          </button>
          <button className="inv-btn-primary" onClick={handleOpenAdd}>
            <Plus size={16} />
            Register New Vendor
          </button>
        </div>
      </div>

      {/* If isModalOpen is true, render the Full-Page Form Card. Otherwise, render the List & Ribbon */}
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
                <Users size={22} color="#1677ff" />
                {modalMode === "add" ? "Register New Supplier Profile" : "Edit Vendor Profile & Terms"}
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Register verified suppliers, GSTIN credentials, MSME classification, star performance ratings, and payment terms.
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
              <ArrowLeft size={16} /> Back to Vendor Database
            </button>
          </div>

          <form onSubmit={handleSubmit} style={{ padding: "28px" }}>
            {/* Section 1: Vendor Legal Identity & Tax Profiles */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <Building size={18} color="#1677ff" /> 1. Vendor Identity & Tax Credentials
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Vendor Code *
                  </label>
                  <input
                    type="text"
                    required
                    value={formData.vendorCode}
                    onChange={(e) => setFormData({ ...formData, vendorCode: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Supplier Tier *
                  </label>
                  <select
                    value={formData.tier}
                    onChange={(e) => setFormData({ ...formData, tier: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Tier 1 - Strategic EPC / OEM">Tier 1 - Strategic EPC / OEM</option>
                    <option value="Tier 2 - Equipment / Fabricator">Tier 2 - Equipment / Fabricator</option>
                    <option value="Tier 3 - Feedstock & Consumables">Tier 3 - Feedstock & Consumables</option>
                  </select>
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Company Legal Name *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Larsen & Toubro Heavy Engineering Ltd"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Procurement Category *
                  </label>
                  <select
                    value={formData.category}
                    onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Plant Construction & Civil">Plant Construction & Civil</option>
                    <option value="Piping & Valves">Piping & Valves</option>
                    <option value="Gas Upgradation & Compressors">Gas Upgradation & Compressors</option>
                    <option value="Biomass Feedstock & Silage">Biomass Feedstock & Silage</option>
                    <option value="Structural Hardware & Fasteners">Structural Hardware & Fasteners</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Target Plant Facility
                  </label>
                  <input
                    type="text"
                    value={formData.plantLocation}
                    onChange={(e) => setFormData({ ...formData, plantLocation: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    GSTIN (15 Digits) *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. 36AAACB1234F1Z5"
                    value={formData.gstin}
                    onChange={(e) => setFormData({ ...formData, gstin: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    PAN Number
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. AAACB1234F"
                    value={formData.panNo}
                    onChange={(e) => setFormData({ ...formData, panNo: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    MSME Classification
                  </label>
                  <select
                    value={formData.msmeStatus}
                    onChange={(e) => setFormData({ ...formData, msmeStatus: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Micro Enterprise">Micro Enterprise</option>
                    <option value="Small Enterprise">Small Enterprise</option>
                    <option value="Medium Enterprise">Medium Enterprise</option>
                    <option value="Large / Non-MSME">Large / Non-MSME</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Udyam Registration Number
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. UDYAM-TS-02-004821"
                    value={formData.udyamRegNo}
                    onChange={(e) => setFormData({ ...formData, udyamRegNo: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>
              </div>
            </div>

            {/* Section 2: Contact, Commercials & SLA */}
            <div style={{
              marginBottom: "28px",
              padding: "22px 24px",
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              boxShadow: "0 1px 2px rgba(0,0,0,0.03)"
            }}>
              <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", textTransform: "uppercase", letterSpacing: "0.5px", margin: "0 0 18px 0", display: "flex", alignItems: "center", gap: "8px" }}>
                <CreditCard size={18} color="#059669" /> 2. Commercials, Contact Details & SLA Terms
              </h4>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "18px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Contact Person & Designation
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. Rajesh Sharma (Head of Sales)"
                    value={formData.contactPerson}
                    onChange={(e) => setFormData({ ...formData, contactPerson: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Phone Number
                  </label>
                  <input
                    type="text"
                    placeholder="+91 98490 12345"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Official Email Address
                  </label>
                  <input
                    type="email"
                    placeholder="sales@vendor.com"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Payment Terms
                  </label>
                  <select
                    value={formData.paymentTerms}
                    onChange={(e) => setFormData({ ...formData, paymentTerms: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Net 30 Days">Net 30 Days</option>
                    <option value="Net 45 Days">Net 45 Days</option>
                    <option value="Net 15 Days">Net 15 Days</option>
                    <option value="20% Advance + 80% on Dispatch">20% Advance + 80% on Dispatch</option>
                    <option value="Milestone Progress Billing">Milestone Progress Billing</option>
                    <option value="100% LC at Sight">100% LC at Sight</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Approved Credit Limit (₹ Cr)
                  </label>
                  <input
                    type="number"
                    step="0.1"
                    value={formData.creditLimit}
                    onChange={(e) => setFormData({ ...formData, creditLimit: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Star Quality Rating (1.0 to 5.0)
                  </label>
                  <input
                    type="number"
                    step="0.1"
                    min="1"
                    max="5"
                    value={formData.ratingStars}
                    onChange={(e) => setFormData({ ...formData, ratingStars: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    On-Time Delivery Rate (%)
                  </label>
                  <input
                    type="number"
                    min="0"
                    max="100"
                    value={formData.onTimeDeliveryRate}
                    onChange={(e) => setFormData({ ...formData, onTimeDeliveryRate: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Performance Grade
                  </label>
                  <select
                    value={formData.performanceGrade}
                    onChange={(e) => setFormData({ ...formData, performanceGrade: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="Grade A+ (Preferred Partner)">Grade A+ (Preferred Partner)</option>
                    <option value="Grade A (Qualified)">Grade A (Qualified)</option>
                    <option value="Grade B (Monitored)">Grade B (Monitored)</option>
                    <option value="Grade C (Probation)">Grade C (Probation)</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    SLA Health Status
                  </label>
                  <select
                    value={formData.slaStatus}
                    onChange={(e) => setFormData({ ...formData, slaStatus: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  >
                    <option value="100% Compliant">100% Compliant</option>
                    <option value="Satisfactory">Satisfactory</option>
                    <option value="Review Required">Review Required</option>
                    <option value="Breach Penalty">Breach Penalty</option>
                  </select>
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Active Contract Reference & PO Details
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. LNT-BN-EPC-2025-09 (Valid till 2027)"
                    value={formData.activeContractRef}
                    onChange={(e) => setFormData({ ...formData, activeContractRef: e.target.value })}
                    style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  />
                </div>

                <div style={{ gridColumn: "1 / -1" }}>
                  <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                    Vendor Audit Notes & Capabilities
                  </label>
                  <textarea
                    rows={2}
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
                <Save size={16} /> {modalMode === "add" ? "Save Vendor Record" : "Update Profile"}
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* MSME & SLA Statutory Compliance Ribbon */}
      <div style={{
        background: "linear-gradient(135deg, #02153f 0%, #002b80 60%, #1e40af 100%)",
        color: "#ffffff",
        borderRadius: "14px",
        padding: "18px 24px",
        marginBottom: "24px",
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        flexWrap: "wrap",
        gap: "16px",
        boxShadow: "0 4px 16px -2px rgba(2, 21, 63, 0.28)"
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
          <div style={{
            width: "46px",
            height: "46px",
            borderRadius: "12px",
            backgroundColor: "rgba(255, 255, 255, 0.15)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "#38bdf8",
            flexShrink: 0
          }}>
            <ShieldCheck size={26} />
          </div>
          <div>
            <div style={{ fontSize: "15px", fontWeight: "800", letterSpacing: "-0.2px", display: "flex", alignItems: "center", gap: "8px" }}>
              <span>MSME Priority Procurement & SLA Compliance Directive</span>
              <span style={{
                background: "#059669",
                color: "#ffffff",
                padding: "2px 8px",
                borderRadius: "6px",
                fontSize: "11px",
                fontWeight: "700"
              }}>
                Active Target Met
              </span>
            </div>
            <div style={{ fontSize: "13px", color: "#bfdbfe", marginTop: "4px", lineHeight: "1.4" }}>
              <strong>{msmePercent}% of active vendor base</strong> is verified Micro, Small & Medium Enterprises (Udyam Verified). Average SLA specification adherence is operating at <strong>{avgQuality}%</strong> across all plant sites.
            </div>
          </div>
        </div>
        <div style={{ display: "flex", gap: "10px", alignItems: "center", flexWrap: "wrap" }}>
          <span style={{
            background: "rgba(16, 185, 129, 0.22)",
            border: "1px solid rgba(16, 185, 129, 0.6)",
            color: "#6ee7b7",
            padding: "6px 14px",
            borderRadius: "8px",
            fontSize: "12px",
            fontWeight: "700",
            display: "inline-flex",
            alignItems: "center",
            gap: "6px"
          }}>
            <CheckCircle2 size={14} /> 100% Tax Compliant (GSTIN Validated)
          </span>
        </div>
      </div>

      {/* 4 Gorgeous KPI Summary Cards */}
      <div className="inv-kpi-grid">
        {/* Card 1 */}
        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#eff6ff", color: "#2563eb" }}>
            <Building size={24} />
          </div>
          <div className="inv-kpi-info">
            <h3>Registered Suppliers</h3>
            <div className="inv-kpi-value">{totalCount} Vendors</div>
            <p className="inv-kpi-subtext">
              {tier1Count} Tier-1 Strategic • {tier2Count} Tier-2 • {tier3Count} Tier-3
            </p>
          </div>
        </div>

        {/* Card 2 */}
        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#ecfdf5", color: "#059669" }}>
            <Award size={24} />
          </div>
          <div className="inv-kpi-info">
            <h3>MSME Udyam Certified</h3>
            <div className="inv-kpi-value" style={{ color: "#15803d" }}>
              {msmeCount} Enterprises ({msmePercent}%)
            </div>
            <p className="inv-kpi-subtext" style={{ color: "#059669" }}>
              Micro, Small & Medium Accredited
            </p>
          </div>
        </div>

        {/* Card 3 */}
        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#fffbeb", color: "#d97706" }}>
            <Star size={24} />
          </div>
          <div className="inv-kpi-info">
            <h3>Performance Scorecard</h3>
            <div className="inv-kpi-value" style={{ color: "#d97706" }}>
              {avgOnTime}% On-Time
            </div>
            <p className="inv-kpi-subtext" style={{ color: "#059669" }}>
              {avgQuality}% Quality Acceptance Rate
            </p>
          </div>
        </div>

        {/* Card 4 */}
        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#f5f3ff", color: "#7c3aed" }}>
            <CreditCard size={24} />
          </div>
          <div className="inv-kpi-info">
            <h3>Credit & Contract Facility</h3>
            <div className="inv-kpi-value">₹{totalCreditExposure.toFixed(1)} Cr</div>
            <p className="inv-kpi-subtext">Active Disbursed PO Lines</p>
          </div>
        </div>
      </div>

      {/* Search and Filters Card */}
      <div className="inv-controls-card">
        <div className="inv-controls-row">
          <div className="inv-search-box">
            <Search className="inv-search-icon" size={16} />
            <input
              type="text"
              className="inv-search-input"
              placeholder="Search by vendor name, code, GSTIN, contact person, or category..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          <div className="inv-filter-group">
            <select
              className="inv-select"
              value={tierFilter}
              onChange={(e) => setTierFilter(e.target.value)}
            >
              <option value="All Tiers">All Supplier Tiers</option>
              <option value="Tier 1 - Strategic EPC / OEM">Tier 1 (Strategic EPC)</option>
              <option value="Tier 2 - Equipment / Fabricator">Tier 2 (Fabricator)</option>
              <option value="Tier 3 - Feedstock & Consumables">Tier 3 (Consumables)</option>
            </select>

            <select
              className="inv-select"
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
            >
              <option value="All Categories">All Categories</option>
              <option value="Plant Construction & Civil">Civil & Construction</option>
              <option value="Piping & Valves">Piping & Valves</option>
              <option value="Gas Upgradation & Compressors">Gas Upgradation</option>
              <option value="Biomass Feedstock & Silage">Biomass Feedstock</option>
              <option value="Structural Hardware & Fasteners">Hardware & Fasteners</option>
            </select>

            <select
              className="inv-select"
              value={msmeFilter}
              onChange={(e) => setMsmeFilter(e.target.value)}
            >
              {MSME_CLASSES.map((m, idx) => (
                <option key={idx} value={m}>{m}</option>
              ))}
            </select>

            <select
              className="inv-select"
              value={gradeFilter}
              onChange={(e) => setGradeFilter(e.target.value)}
            >
              <option value="All Grades">All Grades</option>
              <option value="Grade A+ (Preferred Partner)">Grade A+ (Preferred)</option>
              <option value="Grade A (Qualified)">Grade A (Qualified)</option>
              <option value="Grade B (Monitored)">Grade B (Monitored)</option>
              <option value="Grade C (Probation)">Grade C (Probation)</option>
            </select>

            {(searchTerm || tierFilter !== "All Tiers" || categoryFilter !== "All Categories" || msmeFilter !== "All MSME Classes" || gradeFilter !== "All Grades") && (
              <button
                type="button"
                className="inv-btn-secondary"
                style={{ padding: "8px 12px", fontSize: "12.5px", gap: "6px" }}
                onClick={() => {
                  setSearchTerm("");
                  setTierFilter("All Tiers");
                  setCategoryFilter("All Categories");
                  setMsmeFilter("All MSME Classes");
                  setGradeFilter("All Grades");
                }}
              >
                <RotateCcw size={13} /> Reset
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Master Vendor Table Card */}
      <div className="inv-table-card">
        <div style={{ padding: "16px 20px", borderBottom: "1px solid #e2e8f0", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div>
            <h3 style={{ margin: 0, fontSize: "15px", fontWeight: "700", color: "#0f172a" }}>
              Multi-Tier Vendor Master & Performance Ledger ({filteredVendors.length})
            </h3>
            <p style={{ margin: "2px 0 0 0", fontSize: "12px", color: "#64748b" }}>
              Verified GSTIN tax IDs, MSME Udyam status, on-time delivery ratings, and payment term matrices.
            </p>
          </div>
          <span style={{ fontSize: "12px", color: "#2563eb", fontWeight: "600" }}>
            Showing {filteredVendors.length} of {totalCount} Suppliers
          </span>
        </div>

        <div className="inv-table-wrapper">
          <table className="inv-table">
            <thead>
              <tr>
                <th>Vendor Code & Legal Name</th>
                <th>Supplier Tier & Category</th>
                <th>Tax Credentials & MSME</th>
                <th>Performance Ratings</th>
                <th>Commercial Payment Terms</th>
                <th>SLA Contract Health</th>
                <th style={{ textAlign: "right" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredVendors.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                    No vendor profiles match the selected filters.
                  </td>
                </tr>
              ) : (
                filteredVendors.map((vendor) => {
                  const isMsme = vendor.msmeStatus !== "Large / Non-MSME";
                  const tierClass = vendor.tier.includes("Tier 1") ? "tier-1" : vendor.tier.includes("Tier 2") ? "tier-2" : "tier-3";
                  const slaClass = vendor.slaStatus.includes("100%") ? "compliant" : vendor.slaStatus.includes("Satisfactory") ? "satisfactory" : "warning";

                  return (
                    <tr key={vendor.id} className="vnd-vendor-row">
                      {/* Name & Contact */}
                      <td>
                        <div style={{ fontWeight: "700", color: "#0f172a", fontSize: "13.5px" }}>
                          {vendor.name}
                        </div>
                        <div style={{ fontSize: "11px", color: "#2563eb", fontWeight: "600", fontFamily: "monospace", marginTop: "1px" }}>
                          {vendor.vendorCode} • {vendor.plantLocation}
                        </div>
                        <div style={{ fontSize: "11.5px", color: "#64748b", display: "flex", alignItems: "center", gap: "4px", marginTop: "3px" }}>
                          <Phone size={12} color="#64748b" /> {vendor.contactPerson} ({vendor.phone})
                        </div>
                      </td>

                      {/* Tier & Category */}
                      <td>
                        <span className={`vnd-tier-pill ${tierClass}`}>
                          {vendor.tier.split(" - ")[0]}
                        </span>
                        <div style={{ fontSize: "12.5px", fontWeight: "600", color: "#334155", marginTop: "4px" }}>
                          {vendor.category}
                        </div>
                      </td>

                      {/* Tax Credentials & MSME */}
                      <td>
                        <div className="vnd-tax-id">
                          GST: {vendor.gstin}
                        </div>
                        <div style={{ fontSize: "11px", color: "#64748b", fontFamily: "monospace", marginTop: "1px" }}>
                          PAN: {vendor.panNo}
                        </div>
                        <div style={{ marginTop: "4px" }}>
                          <span className={`vnd-msme-pill ${!isMsme ? "non-msme" : ""}`}>
                            {isMsme ? <ShieldCheck size={11} /> : null}
                            {isMsme ? `MSME: ${vendor.msmeStatus}` : "Non-MSME (Large)"}
                          </span>
                        </div>
                      </td>

                      {/* Ratings */}
                      <td style={{ minWidth: "160px" }}>
                        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                          <div className="vnd-rating-pill">
                            <Star size={13} fill="#b45309" color="#b45309" />
                            <span>{vendor.ratingStars} / 5.0</span>
                          </div>
                          <span style={{
                            fontSize: "10.5px",
                            fontWeight: "700",
                            color: vendor.performanceGrade.includes("A+") ? "#15803d" : vendor.performanceGrade.includes("A") ? "#2563eb" : "#d97706"
                          }}>
                            {vendor.performanceGrade.split(" ")[0]} {vendor.performanceGrade.split(" ")[1]}
                          </span>
                        </div>

                        <div style={{ fontSize: "11px", color: "#475569", marginTop: "4px", display: "flex", justifyContent: "space-between" }}>
                          <span>On-Time: <strong>{vendor.onTimeDeliveryRate}%</strong></span>
                          <span>Quality: <strong>{vendor.qualityAcceptanceRate}%</strong></span>
                        </div>
                        <div className="vnd-progress-bar-mini">
                          <div
                            className="vnd-progress-fill"
                            style={{
                              width: `${vendor.onTimeDeliveryRate}%`,
                              backgroundColor: vendor.onTimeDeliveryRate > 95 ? "#10b981" : vendor.onTimeDeliveryRate > 90 ? "#3b82f6" : "#f59e0b"
                            }}
                          />
                        </div>
                      </td>

                      {/* Payment Terms & Credit */}
                      <td>
                        <div style={{ fontWeight: "700", color: "#0f172a", fontSize: "12.5px" }}>
                          {vendor.paymentTerms}
                        </div>
                        <div style={{ fontSize: "12px", color: "#2563eb", fontWeight: "600", marginTop: "2px" }}>
                          Credit Line: <strong>₹{vendor.creditLimit} Cr</strong>
                        </div>
                        <div style={{ fontSize: "10.5px", color: "#64748b", fontFamily: "monospace", marginTop: "1px" }}>
                          PO: {vendor.activeContractRef}
                        </div>
                      </td>

                      {/* SLA Health */}
                      <td>
                        <span className={`vnd-sla-badge ${slaClass}`}>
                          <CheckCircle2 size={12} />
                          {vendor.slaStatus}
                        </span>
                        <div style={{ fontSize: "11px", color: "#64748b", marginTop: "3px" }}>
                          Response: &lt; {vendor.slaResponseHours}h
                        </div>
                      </td>

                      {/* Actions */}
                      <td style={{ textAlign: "right" }}>
                        <div className="inv-action-btn-group" style={{ justifyContent: "flex-end" }}>
                          <button
                            className="inv-action-btn view"
                            onClick={() => handleOpenDetail(vendor)}
                            title="View Complete Vendor Dossier"
                          >
                            <Eye size={15} />
                          </button>
                          <button
                            className="inv-action-btn edit"
                            onClick={() => handleOpenEdit(vendor)}
                            title="Edit Vendor Details"
                          >
                            <Edit2 size={15} />
                          </button>
                          <button
                            className="inv-action-btn delete"
                            onClick={() => handleDelete(vendor.id)}
                            title="Delete Vendor Profile"
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

      {/* Detailed Dossier Modal */}
      {isDetailModalOpen && selectedVendor && (
        <div className="inv-modal-overlay">
          <div className="inv-modal" style={{ maxWidth: "680px" }}>
            <div className="inv-modal-header">
              <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                <div style={{
                  width: "40px",
                  height: "40px",
                  borderRadius: "10px",
                  backgroundColor: "#eff6ff",
                  color: "#2563eb",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  border: "1px solid #bfdbfe"
                }}>
                  <Building size={22} />
                </div>
                <div>
                  <h2 style={{ fontSize: "16px", margin: 0, color: "#0f172a" }}>{selectedVendor.name}</h2>
                  <span style={{ fontSize: "12px", color: "#64748b" }}>
                    Dossier Code: <strong>{selectedVendor.vendorCode}</strong> • {selectedVendor.tier}
                  </span>
                </div>
              </div>
              <button className="inv-modal-close" onClick={() => setIsDetailModalOpen(false)}>
                <X size={20} />
              </button>
            </div>

            <div className="inv-modal-body" style={{ padding: "20px 24px" }}>
              {/* Profile Card Header */}
              <div className="vnd-dossier-hero">
                <div>
                  <div style={{ fontSize: "11px", fontWeight: "700", color: "#64748b" }}>PRIMARY CATEGORY</div>
                  <div style={{ fontSize: "13.5px", fontWeight: "700", color: "#0f172a", marginTop: "2px" }}>
                    {selectedVendor.category}
                  </div>
                </div>

                <div>
                  <div style={{ fontSize: "11px", fontWeight: "700", color: "#64748b" }}>TARGET PLANT SITE</div>
                  <div style={{ fontSize: "13.5px", fontWeight: "700", color: "#2563eb", marginTop: "2px" }}>
                    {selectedVendor.plantLocation}
                  </div>
                </div>

                <div>
                  <div style={{ fontSize: "11px", fontWeight: "700", color: "#64748b" }}>CONTACT EXECUTIVE</div>
                  <div style={{ fontSize: "13px", fontWeight: "600", color: "#0f172a", marginTop: "2px" }}>
                    {selectedVendor.contactPerson}
                  </div>
                  <div style={{ fontSize: "11.5px", color: "#64748b" }}>{selectedVendor.phone}</div>
                </div>

                <div>
                  <div style={{ fontSize: "11px", fontWeight: "700", color: "#64748b" }}>OFFICIAL EMAIL & HQ</div>
                  <div style={{ fontSize: "12px", color: "#2563eb", marginTop: "2px" }}>{selectedVendor.email}</div>
                  <div style={{ fontSize: "11px", color: "#64748b" }}>{selectedVendor.address}</div>
                </div>
              </div>

              {/* Statutory Tax IDs & MSME Accreditation */}
              <div style={{
                background: "#ffffff",
                border: "1px solid #e2e8f0",
                borderRadius: "10px",
                padding: "16px",
                marginBottom: "18px"
              }}>
                <h4 style={{ margin: "0 0 12px 0", fontSize: "13px", fontWeight: "700", color: "#0f172a", display: "flex", alignItems: "center", gap: "6px" }}>
                  <ShieldCheck size={16} color="#059669" /> Statutory Tax Credentials & MSME Accreditation
                </h4>
                <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(190px, 1fr))", gap: "12px" }}>
                  <div style={{ background: "#f8fafc", padding: "10px 12px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                    <div style={{ fontSize: "11px", color: "#64748b" }}>GSTIN (Verified)</div>
                    <div style={{ fontSize: "13px", fontWeight: "700", color: "#0f172a", fontFamily: "monospace", marginTop: "2px" }}>
                      {selectedVendor.gstin}
                    </div>
                  </div>
                  <div style={{ background: "#f8fafc", padding: "10px 12px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                    <div style={{ fontSize: "11px", color: "#64748b" }}>PAN Identification</div>
                    <div style={{ fontSize: "13px", fontWeight: "700", color: "#0f172a", fontFamily: "monospace", marginTop: "2px" }}>
                      {selectedVendor.panNo}
                    </div>
                  </div>
                  <div style={{ background: "#f0fdf4", padding: "10px 12px", borderRadius: "8px", border: "1px solid #bbf7d0" }}>
                    <div style={{ fontSize: "11px", color: "#166534", fontWeight: "700" }}>MSME STATUS</div>
                    <div style={{ fontSize: "13px", fontWeight: "700", color: "#15803d", marginTop: "2px" }}>
                      {selectedVendor.msmeStatus}
                    </div>
                    <div style={{ fontSize: "10.5px", color: "#166534", fontFamily: "monospace" }}>
                      Udyam: {selectedVendor.udyamRegNo || "N/A"}
                    </div>
                  </div>
                </div>
              </div>

              {/* Historical Performance Ratings & SLA Scorecard */}
              <div style={{
                background: "#ffffff",
                border: "1px solid #e2e8f0",
                borderRadius: "10px",
                padding: "16px",
                marginBottom: "18px"
              }}>
                <h4 style={{ margin: "0 0 12px 0", fontSize: "13px", fontWeight: "700", color: "#0f172a", display: "flex", alignItems: "center", gap: "6px" }}>
                  <Award size={16} color="#d97706" /> Historical Performance & SLA Scorecard
                </h4>
                <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(130px, 1fr))", gap: "12px" }}>
                  <div style={{ textAlign: "center", background: "#fffbeb", padding: "12px 8px", borderRadius: "8px", border: "1px solid #fef3c7" }}>
                    <div style={{ fontSize: "20px", fontWeight: "800", color: "#d97706" }}>
                      ★ {selectedVendor.ratingStars}
                    </div>
                    <div style={{ fontSize: "11px", color: "#92400e", fontWeight: "600" }}>Quality Score (5.0)</div>
                  </div>

                  <div style={{ textAlign: "center", background: "#eff6ff", padding: "12px 8px", borderRadius: "8px", border: "1px solid #bfdbfe" }}>
                    <div style={{ fontSize: "20px", fontWeight: "800", color: "#2563eb" }}>
                      {selectedVendor.onTimeDeliveryRate}%
                    </div>
                    <div style={{ fontSize: "11px", color: "#1e40af", fontWeight: "600" }}>On-Time Delivery</div>
                  </div>

                  <div style={{ textAlign: "center", background: "#f0fdf4", padding: "12px 8px", borderRadius: "8px", border: "1px solid #bbf7d0" }}>
                    <div style={{ fontSize: "20px", fontWeight: "800", color: "#16a34a" }}>
                      {selectedVendor.qualityAcceptanceRate}%
                    </div>
                    <div style={{ fontSize: "11px", color: "#166534", fontWeight: "600" }}>Quality Acceptance</div>
                  </div>

                  <div style={{ textAlign: "center", background: "#f8fafc", padding: "12px 8px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                    <div style={{ fontSize: "16px", fontWeight: "800", color: "#0f172a" }}>
                      &lt; {selectedVendor.slaResponseHours}h
                    </div>
                    <div style={{ fontSize: "11px", color: "#64748b", fontWeight: "600" }}>SLA Response Time</div>
                  </div>
                </div>
              </div>

              {/* Commercial Terms & Credit Ledger */}
              <div style={{
                background: "#f8fafc",
                borderRadius: "10px",
                padding: "16px",
                border: "1px solid #e2e8f0"
              }}>
                <h4 style={{ margin: "0 0 10px 0", fontSize: "13px", fontWeight: "700", color: "#0f172a", display: "flex", alignItems: "center", gap: "6px" }}>
                  <CreditCard size={16} color="#2563eb" /> Commercial Terms & Active Contract Details
                </h4>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "12px", fontSize: "12.5px" }}>
                  <div>
                    <span style={{ color: "#64748b" }}>Payment Terms:</span> <strong>{selectedVendor.paymentTerms}</strong>
                  </div>
                  <div>
                    <span style={{ color: "#64748b" }}>Credit Exposure:</span> <strong style={{ color: "#2563eb" }}>₹{selectedVendor.creditLimit} Cr</strong>
                  </div>
                  <div>
                    <span style={{ color: "#64748b" }}>Agreement Ref:</span> <strong>{selectedVendor.activeContractRef}</strong>
                  </div>
                  <div>
                    <span style={{ color: "#64748b" }}>SLA Compliance:</span> <strong style={{ color: "#059669" }}>{selectedVendor.slaStatus}</strong>
                  </div>
                  <div style={{ gridColumn: "span 2", marginTop: "4px" }}>
                    <span style={{ color: "#64748b" }}>Procurement Notes:</span> <span>{selectedVendor.notes}</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="inv-modal-footer">
              <button className="inv-btn-primary" onClick={() => setIsDetailModalOpen(false)}>
                Close Dossier
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default MultiTierVendorDatabase;
