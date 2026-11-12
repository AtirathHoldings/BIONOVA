import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import Sidebar from "../Sidebar.jsx";
import Header from "../Header.jsx";
import {
  ShoppingCart,
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
  Building,
  DollarSign,
  FileText,
  FileCheck,
  PackageCheck,
  Truck,
  X,
  Save,
  Printer,
  ChevronRight,
  ArrowLeft,
  Lock,
  Layers
} from "lucide-react";
import "../../styles/SupplyChainOperations.css";
import { getScreenPermission } from "../../utils/permissions";
import {
  getProcurementSuppliers,
  saveProcurementSupplier,
  deleteProcurementSupplier,
  getPurchaseRequisitions,
  savePurchaseRequisition,
  deletePurchaseRequisition,
  getPurchaseOrders,
  savePurchaseOrder,
  deletePurchaseOrder,
  getDeliveryNotes,
  saveDeliveryNote,
  deleteDeliveryNote
} from "../../utils/supplyChainApi";

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

const ProcurementManagement = ({ onLogout, userRole }) => {
  const screenPerm = getScreenPermission("PROCUREMENT_MANAGEMENT");
  const { tab } = useParams();
  const navigate = useNavigate();

  const [activeTab, setActiveTab] = useState(tab || "pos");
  const [plants, setPlants] = useState([]);

  // Data states
  const [suppliers, setSuppliers] = useState([]);
  const [requisitions, setRequisitions] = useState([]);
  const [purchaseOrders, setPurchaseOrders] = useState([]);
  const [deliveryNotes, setDeliveryNotes] = useState([]);

  // Filter / Search states
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("All");

  // Form View States (Full Page Form)
  const [formMode, setFormMode] = useState(null); // 'create_po' | 'create_pr' | 'create_supplier' | 'create_grn' | null
  const [editingItem, setEditingItem] = useState(null);
  const [viewingItem, setViewingItem] = useState(null);

  // Form States
  const [poForm, setPoForm] = useState({
    poNumber: "",
    supplierName: "",
    plantFacility: "",
    orderDate: new Date().toISOString().split("T")[0],
    deliveryDate: "",
    paymentTerms: "Net 30 Days",
    deliveryTerms: "FOR Destination Plant Site",
    shippingAddress: "",
    items: [{ description: "", sku: "", qty: 1, unit: "MT", unitPrice: 0, taxRate: 18, lineTotal: 0 }],
    status: "Issued"
  });

  const [prForm, setPrForm] = useState({
    prNumber: "",
    department: "Biogas Operations",
    plantFacility: "",
    priority: "Normal",
    requiredDate: "",
    justification: "",
    items: [{ itemName: "", qty: 1, uom: "MT", estCost: 0 }],
    status: "Pending Approval"
  });

  const [supplierForm, setSupplierForm] = useState({
    name: "",
    tier: "Tier 1 - Strategic EPC / OEM",
    category: "Biomass Feedstock & Silage",
    gstin: "",
    pan: "",
    contactPerson: "",
    phone: "",
    email: "",
    address: "",
    paymentTerms: "Net 30 Days",
    rating: 5,
    status: "Active"
  });

  const [grnForm, setGrnForm] = useState({
    grnNumber: "",
    poNumber: "",
    supplierName: "",
    transporter: "",
    vehicleNo: "",
    eWayBill: "",
    receivedDate: new Date().toISOString().split("T")[0],
    receivingZone: "Raw Feedstock Silo Yard",
    orderedQty: 0,
    dispatchedQty: 0,
    receivedQty: 0,
    acceptedQty: 0,
    rejectedQty: 0,
    inspectionStatus: "Passed QC - Stock Updated",
    remarks: ""
  });

  // Load Initial Data
  useEffect(() => {
    loadAllData();
    fetchPlants();
  }, []);

  useEffect(() => {
    if (tab && ["pos", "requisitions", "vendors", "deliveries"].includes(tab)) {
      setActiveTab(tab);
      setFormMode(null);
      setViewingItem(null);
    }
  }, [tab]);

  const fetchPlants = async () => {
    try {
      const res = await fetch(`${apiBaseUrl}/api/plants`, {
        headers: {
          "Authorization": `Bearer ${sessionStorage.getItem("authToken") || ""}`
        }
      });
      if (res.ok) {
        const data = await res.json();
        setPlants(data || []);
      }
    } catch (e) {}
  };

  const loadAllData = async () => {
    const [sups, prs, pos, grns] = await Promise.all([
      getProcurementSuppliers(),
      getPurchaseRequisitions(),
      getPurchaseOrders(),
      getDeliveryNotes()
    ]);
    setSuppliers(sups);
    setRequisitions(prs);
    setPurchaseOrders(pos);
    setDeliveryNotes(grns);
  };

  // Switch Tab Handler
  const handleTabChange = (newTab) => {
    setActiveTab(newTab);
    setFormMode(null);
    setEditingItem(null);
    setViewingItem(null);
    setSearchQuery("");
    setStatusFilter("All");
    navigate(`/procurement/${newTab}`);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // --- Purchase Order Form Operations ---
  const handleOpenCreatePO = () => {
    const nextSeq = String(purchaseOrders.length + 1).padStart(4, "0");
    setPoForm({
      poNumber: `PO-2026-${nextSeq}`,
      supplierName: suppliers[0]?.name || "",
      plantFacility: plants[0]?.plantNm || "Hyderabad East CBG Plant",
      orderDate: new Date().toISOString().split("T")[0],
      deliveryDate: new Date(Date.now() + 14 * 86400000).toISOString().split("T")[0],
      paymentTerms: "Net 30 Days",
      deliveryTerms: "FOR Destination Plant Site",
      shippingAddress: "BioNova Industrial Bio-Energy Complex, Site Bay 4",
      items: [{ description: "Energy Napier Grass Feedstock Consignment", sku: "SKU-AGRI-01", qty: 100, unit: "MT", unitPrice: 2200, taxRate: 5, lineTotal: 231000 }],
      status: "Issued"
    });
    setEditingItem(null);
    setFormMode("create_po");
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handlePoItemChange = (index, field, value) => {
    const updatedItems = [...poForm.items];
    updatedItems[index][field] = value;
    const qty = parseFloat(updatedItems[index].qty) || 0;
    const price = parseFloat(updatedItems[index].unitPrice) || 0;
    const taxRate = parseFloat(updatedItems[index].taxRate) || 0;
    const sub = qty * price;
    updatedItems[index].lineTotal = Math.round(sub + (sub * taxRate) / 100);
    setPoForm({ ...poForm, items: updatedItems });
  };

  const handleAddPoItem = () => {
    setPoForm({
      ...poForm,
      items: [
        ...poForm.items,
        { description: "", sku: "", qty: 1, unit: "MT", unitPrice: 0, taxRate: 18, lineTotal: 0 }
      ]
    });
  };

  const handleRemovePoItem = (index) => {
    if (poForm.items.length <= 1) return;
    setPoForm({ ...poForm, items: poForm.items.filter((_, i) => i !== index) });
  };

  const handleSavePO = async (e) => {
    e.preventDefault();
    const subtotal = poForm.items.reduce((acc, it) => acc + (it.qty * it.unitPrice), 0);
    const taxTotal = poForm.items.reduce((acc, it) => acc + (it.qty * it.unitPrice * (it.taxRate / 100)), 0);
    const totalAmount = Math.round(subtotal + taxTotal);

    const payload = {
      ...poForm,
      id: editingItem ? editingItem.id : undefined,
      subtotal,
      taxTotal,
      totalAmount
    };

    await savePurchaseOrder(payload);
    await loadAllData();
    setFormMode(null);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // --- Purchase Requisition Operations ---
  const handleOpenCreatePR = () => {
    const nextSeq = String(requisitions.length + 1).padStart(4, "0");
    setPrForm({
      prNumber: `PR-2026-${nextSeq}`,
      department: "Biogas Operations",
      plantFacility: plants[0]?.plantNm || "Hyderabad East CBG Plant",
      priority: "Normal",
      requiredDate: new Date(Date.now() + 7 * 86400000).toISOString().split("T")[0],
      justification: "Critical raw substrate procurement for anaerobic digester continuous feeding.",
      items: [{ itemName: "Silage Bacterial Inoculant Enzyme", qty: 25, uom: "Kg", estCost: 45000 }],
      status: "Pending Approval"
    });
    setEditingItem(null);
    setFormMode("create_pr");
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handlePrItemChange = (index, field, value) => {
    const updated = [...prForm.items];
    updated[index][field] = value;
    setPrForm({ ...prForm, items: updated });
  };

  const handleAddPrItem = () => {
    setPrForm({
      ...prForm,
      items: [...prForm.items, { itemName: "", qty: 1, uom: "MT", estCost: 0 }]
    });
  };

  const handleRemovePrItem = (index) => {
    if (prForm.items.length <= 1) return;
    setPrForm({ ...prForm, items: prForm.items.filter((_, i) => i !== index) });
  };

  const handleSavePR = async (e) => {
    e.preventDefault();
    const estTotal = prForm.items.reduce((acc, it) => acc + Number(it.estCost || 0), 0);
    const payload = {
      ...prForm,
      id: editingItem ? editingItem.id : undefined,
      totalEstCost: estTotal
    };
    await savePurchaseRequisition(payload);
    await loadAllData();
    setFormMode(null);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleApprovePR = async (pr, newStatus) => {
    await savePurchaseRequisition({ ...pr, status: newStatus });
    await loadAllData();
  };

  // --- Vendor Form Operations ---
  const handleOpenCreateSupplier = () => {
    setSupplierForm({
      name: "",
      tier: "Tier 1 - Strategic EPC / OEM",
      category: "Biomass Feedstock & Silage",
      gstin: "",
      pan: "",
      contactPerson: "",
      phone: "",
      email: "",
      address: "",
      paymentTerms: "Net 30 Days",
      rating: 5,
      status: "Active"
    });
    setEditingItem(null);
    setFormMode("create_supplier");
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleSaveSupplier = async (e) => {
    e.preventDefault();
    const payload = {
      ...supplierForm,
      id: editingItem ? editingItem.id : undefined
    };
    await saveProcurementSupplier(payload);
    await loadAllData();
    setFormMode(null);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // --- Delivery Note Operations ---
  const handleOpenCreateGRN = () => {
    const nextSeq = String(deliveryNotes.length + 1).padStart(4, "0");
    setGrnForm({
      grnNumber: `GRN-2026-${nextSeq}`,
      poNumber: purchaseOrders[0]?.poNumber || "PO-2026-0001",
      supplierName: suppliers[0]?.name || "Agritech Agro Bio Solutions Ltd",
      transporter: "Gati-KWE Logistics Fleet",
      vehicleNo: "TS 08 UB 7712",
      eWayBill: "2418-9921-0842",
      receivedDate: new Date().toISOString().split("T")[0],
      receivingZone: "Raw Feedstock Silo Yard",
      orderedQty: 100,
      dispatchedQty: 100,
      receivedQty: 98.5,
      acceptedQty: 98.5,
      rejectedQty: 0,
      inspectionStatus: "Passed QC - Stock Updated",
      remarks: "Material verified and cleared for silage yard un-loading."
    });
    setEditingItem(null);
    setFormMode("create_grn");
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleSaveGRN = async (e) => {
    e.preventDefault();
    const payload = {
      ...grnForm,
      id: editingItem ? editingItem.id : undefined
    };
    await saveDeliveryNote(payload);
    await loadAllData();
    setFormMode(null);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // Export to CSV
  const exportToCSV = (data, filename) => {
    if (!data.length) return;
    const headers = Object.keys(data[0]).filter(k => typeof data[0][k] !== "object").join(",");
    const rows = data.map(obj =>
      Object.keys(obj)
        .filter(k => typeof obj[k] !== "object")
        .map(k => `"${String(obj[k] || "").replace(/"/g, '""')}"`)
        .join(",")
    );
    const csvContent = "data:text/csv;charset=utf-8," + [headers, ...rows].join("\n");
    const link = document.createElement("a");
    link.href = encodeURI(csvContent);
    link.download = `${filename}_${Date.now()}.csv`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  // KPI Computations
  const totalPoSpend = purchaseOrders.reduce((sum, p) => sum + Number(p.totalAmount || 0), 0);
  const pendingPrCount = requisitions.filter(r => r.status === "Pending Approval").length;
  const activeSuppliersCount = suppliers.filter(s => s.status === "Active").length;
  const totalDeliveriesCount = deliveryNotes.length;

  if (!screenPerm.canView) {
    return (
      <div className="sco-container">
        <Sidebar onLogout={onLogout} />
        <div className="sco-main" style={{ display: "flex", flexDirection: "column", minHeight: "100vh" }}>
          <Header title="Procurement & Purchase Order Management" onLogout={onLogout} />
          <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "40px", textAlign: "center" }}>
            <div style={{ width: "80px", height: "80px", borderRadius: "50%", background: "#fee2e2", display: "flex", alignItems: "center", justifyContent: "center", marginBottom: "20px" }}>
              <Lock size={36} color="#dc2626" />
            </div>
            <h2 style={{ fontSize: "22px", fontWeight: "700", color: "#1e293b", marginBottom: "8px" }}>Access Restricted</h2>
            <p style={{ fontSize: "14px", color: "#64748b", maxWidth: "420px", margin: "0 auto" }}>
              You do not have view permissions for the Procurement & PO Management module. Please contact your system administrator.
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="sco-container">
      <Sidebar onLogout={onLogout} />
      <div className="sco-main">
        <Header title="Procurement & Purchase Order Management" onLogout={onLogout} />

        <div className="sco-content">
          {/* Header Row: Tagline on Left, Buttons on Right Edge */}
          <div className="sco-header-row">
            <p className="sco-tagline">
              Manage multi-tier supplier contracts, purchase requisition approval pipelines, automated purchase order generation, and delivery note receipts.
            </p>
            <div className="d-flex align-items-center gap-2" style={{ flexShrink: 0, marginLeft: "auto" }}>
              {activeTab === "pos" && (
                <button onClick={handleOpenCreatePO} className="sco-btn-primary">
                  <Plus size={16} /> Generate Purchase Order
                </button>
              )}
              {activeTab === "requisitions" && (
                <button onClick={handleOpenCreatePR} className="sco-btn-primary">
                  <Plus size={16} /> Raise Requisition (PR)
                </button>
              )}
              {activeTab === "vendors" && (
                <button onClick={handleOpenCreateSupplier} className="sco-btn-primary">
                  <Plus size={16} /> Onboard New Supplier
                </button>
              )}
              {activeTab === "deliveries" && (
                <button onClick={handleOpenCreateGRN} className="sco-btn-primary">
                  <Plus size={16} /> Log Inward Delivery Note
                </button>
              )}
            </div>
          </div>

          {/* KPI Summary Cards */}
          <div className="sco-kpi-grid">
            <div className="sco-kpi-card">
              <div className="sco-kpi-icon" style={{ backgroundColor: "#eff6ff", color: "#2563eb" }}>
                <DollarSign size={24} />
              </div>
              <div className="sco-kpi-info">
                <span className="sco-kpi-val">₹{totalPoSpend.toLocaleString("en-IN")}</span>
                <span className="sco-kpi-label">Total Active PO Value</span>
              </div>
            </div>

            <div className="sco-kpi-card">
              <div className="sco-kpi-icon" style={{ backgroundColor: "#f0fdf4", color: "#16a34a" }}>
                <Building size={24} />
              </div>
              <div className="sco-kpi-info">
                <span className="sco-kpi-val">{activeSuppliersCount}</span>
                <span className="sco-kpi-label">Active Approved Vendors</span>
              </div>
            </div>

            <div className="sco-kpi-card">
              <div className="sco-kpi-icon" style={{ backgroundColor: "#fef3c7", color: "#d97706" }}>
                <Clock size={24} />
              </div>
              <div className="sco-kpi-info">
                <span className="sco-kpi-val">{pendingPrCount}</span>
                <span className="sco-kpi-label">Pending PR Approvals</span>
              </div>
            </div>

            <div className="sco-kpi-card">
              <div className="sco-kpi-icon" style={{ backgroundColor: "#f3e8ff", color: "#9333ea" }}>
                <PackageCheck size={24} />
              </div>
              <div className="sco-kpi-info">
                <span className="sco-kpi-val">{totalDeliveriesCount}</span>
                <span className="sco-kpi-label">Inbound GRN Receipts</span>
              </div>
            </div>
          </div>

          {/* Submodule Navigation Tabs */}
          <div className="sco-tabs-nav">
            <button
              className={`sco-tab-btn ${activeTab === "pos" ? "active" : ""}`}
              onClick={() => handleTabChange("pos")}
            >
              <ShoppingCart size={16} /> Purchase Orders (PO)
              <span className="badge-count">{purchaseOrders.length}</span>
            </button>

            <button
              className={`sco-tab-btn ${activeTab === "requisitions" ? "active" : ""}`}
              onClick={() => handleTabChange("requisitions")}
            >
              <FileCheck size={16} /> Purchase Requisitions (PR)
              <span className="badge-count">{requisitions.length}</span>
            </button>

            <button
              className={`sco-tab-btn ${activeTab === "vendors" ? "active" : ""}`}
              onClick={() => handleTabChange("vendors")}
            >
              <Building size={16} /> Vendor & Supplier Directory
              <span className="badge-count">{suppliers.length}</span>
            </button>

            <button
              className={`sco-tab-btn ${activeTab === "deliveries" ? "active" : ""}`}
              onClick={() => handleTabChange("deliveries")}
            >
              <Truck size={16} /> Delivery Notes & GRN Tracking
              <span className="badge-count">{deliveryNotes.length}</span>
            </button>
          </div>

          {/* ────────────────────────────────────────────────────────────── */}
          {/* FULL PAGE FORM: CREATE / EDIT PURCHASE ORDER                   */}
          {/* ────────────────────────────────────────────────────────────── */}
          {formMode === "create_po" && (
            <div className="sco-form-card">
              <div className="sco-form-title">
                <span>{editingItem ? "Edit Purchase Order" : "Generate Enterprise Purchase Order (PO)"}</span>
                <button onClick={() => setFormMode(null)} className="sco-btn-icon"><X size={18} /></button>
              </div>

              <form onSubmit={handleSavePO}>
                <div className="sco-form-grid">
                  <div className="sco-form-group">
                    <label>PO Number <span className="required">*</span></label>
                    <input
                      type="text"
                      required
                      value={poForm.poNumber}
                      onChange={(e) => setPoForm({ ...poForm, poNumber: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Select Supplier / Vendor <span className="required">*</span></label>
                    <select
                      required
                      value={poForm.supplierName}
                      onChange={(e) => setPoForm({ ...poForm, supplierName: e.target.value })}
                    >
                      <option value="">-- Choose Vendor --</option>
                      {suppliers.map(s => <option key={s.id} value={s.name}>{s.name} ({s.tier})</option>)}
                      {!suppliers.length && <option value="Agritech Agro Bio Solutions Ltd">Agritech Agro Bio Solutions Ltd</option>}
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Receiving Plant Facility <span className="required">*</span></label>
                    <select
                      required
                      value={poForm.plantFacility}
                      onChange={(e) => setPoForm({ ...poForm, plantFacility: e.target.value })}
                    >
                      {plants.map(p => <option key={p.plantId} value={p.plantNm}>{p.plantNm}</option>)}
                      {!plants.length && <option value="Plant 1 - Hyderabad East CBG">Plant 1 - Hyderabad East CBG</option>}
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>PO Order Date</label>
                    <input
                      type="date"
                      value={poForm.orderDate}
                      onChange={(e) => setPoForm({ ...poForm, orderDate: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Expected Delivery Date <span className="required">*</span></label>
                    <input
                      type="date"
                      required
                      value={poForm.deliveryDate}
                      onChange={(e) => setPoForm({ ...poForm, deliveryDate: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Payment Terms</label>
                    <select
                      value={poForm.paymentTerms}
                      onChange={(e) => setPoForm({ ...poForm, paymentTerms: e.target.value })}
                    >
                      <option value="Immediate on Delivery">Immediate on Delivery</option>
                      <option value="Net 15 Days">Net 15 Days</option>
                      <option value="Net 30 Days">Net 30 Days</option>
                      <option value="Net 45 Days">Net 45 Days</option>
                      <option value="Advance 20% + Balance on GRN">Advance 20% + Balance on GRN</option>
                    </select>
                  </div>

                  <div className="sco-form-group col-span-full">
                    <label>Delivery Terms & Shipping Address</label>
                    <input
                      type="text"
                      value={poForm.shippingAddress}
                      onChange={(e) => setPoForm({ ...poForm, shippingAddress: e.target.value })}
                      placeholder="e.g. BioNova Plant 1, Inward Bay #3, Hyderabad East"
                    />
                  </div>
                </div>

                {/* Line Items Section */}
                <div style={{ marginBottom: "20px" }}>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "12px" }}>
                    <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#334155", margin: 0 }}>PO Line Items & Schedule of Quantities</h4>
                    <button type="button" onClick={handleAddPoItem} className="sco-btn-secondary" style={{ fontSize: "12px", padding: "4px 10px" }}>
                      + Add Item Row
                    </button>
                  </div>

                  <div className="sco-table-wrapper">
                    <table className="sco-table">
                      <thead>
                        <tr>
                          <th>Item Description</th>
                          <th style={{ width: "120px" }}>SKU / Code</th>
                          <th style={{ width: "90px" }}>Qty</th>
                          <th style={{ width: "90px" }}>Unit</th>
                          <th style={{ width: "120px" }}>Unit Price (₹)</th>
                          <th style={{ width: "90px" }}>GST %</th>
                          <th style={{ width: "130px" }}>Line Total (₹)</th>
                          <th style={{ width: "60px" }}></th>
                        </tr>
                      </thead>
                      <tbody>
                        {poForm.items.map((it, idx) => (
                          <tr key={idx}>
                            <td>
                              <input
                                type="text"
                                required
                                value={it.description}
                                placeholder="Item name / specification"
                                onChange={(e) => handlePoItemChange(idx, "description", e.target.value)}
                                style={{ width: "100%", padding: "6px 8px", border: "1px solid #cbd5e1", borderRadius: "6px" }}
                              />
                            </td>
                            <td>
                              <input
                                type="text"
                                value={it.sku}
                                placeholder="e.g. SKU-01"
                                onChange={(e) => handlePoItemChange(idx, "sku", e.target.value)}
                                style={{ width: "100%", padding: "6px 8px", border: "1px solid #cbd5e1", borderRadius: "6px" }}
                              />
                            </td>
                            <td>
                              <input
                                type="number"
                                min="0.1"
                                step="any"
                                required
                                value={it.qty}
                                onChange={(e) => handlePoItemChange(idx, "qty", e.target.value)}
                                style={{ width: "100%", padding: "6px 8px", border: "1px solid #cbd5e1", borderRadius: "6px" }}
                              />
                            </td>
                            <td>
                              <select
                                value={it.unit}
                                onChange={(e) => handlePoItemChange(idx, "unit", e.target.value)}
                                style={{ width: "100%", padding: "6px 8px", border: "1px solid #cbd5e1", borderRadius: "6px" }}
                              >
                                <option value="MT">MT</option>
                                <option value="Kg">Kg</option>
                                <option value="Ltr">Ltr</option>
                                <option value="Nos">Nos</option>
                                <option value="Meters">Meters</option>
                                <option value="Sets">Sets</option>
                              </select>
                            </td>
                            <td>
                              <input
                                type="number"
                                min="0"
                                required
                                value={it.unitPrice}
                                onChange={(e) => handlePoItemChange(idx, "unitPrice", e.target.value)}
                                style={{ width: "100%", padding: "6px 8px", border: "1px solid #cbd5e1", borderRadius: "6px" }}
                              />
                            </td>
                            <td>
                              <select
                                value={it.taxRate}
                                onChange={(e) => handlePoItemChange(idx, "taxRate", e.target.value)}
                                style={{ width: "100%", padding: "6px 8px", border: "1px solid #cbd5e1", borderRadius: "6px" }}
                              >
                                <option value="0">0%</option>
                                <option value="5">5%</option>
                                <option value="12">12%</option>
                                <option value="18">18%</option>
                                <option value="28">28%</option>
                              </select>
                            </td>
                            <td style={{ fontWeight: "700", color: "#0f172a" }}>
                              ₹{it.lineTotal.toLocaleString("en-IN")}
                            </td>
                            <td>
                              <button
                                type="button"
                                onClick={() => handleRemovePoItem(idx)}
                                className="sco-btn-icon danger"
                                title="Remove Item"
                              >
                                <Trash2 size={15} />
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>

                <div className="sco-form-actions">
                  <button type="button" onClick={() => setFormMode(null)} className="sco-btn-secondary">
                    Cancel
                  </button>
                  <button type="submit" className="sco-btn-primary">
                    <Save size={16} /> Save & Issue Purchase Order
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* FULL PAGE FORM: CREATE REQUISITION (PR)                        */}
          {/* ────────────────────────────────────────────────────────────── */}
          {formMode === "create_pr" && (
            <div className="sco-form-card">
              <div className="sco-form-title">
                <span>Raise Purchase Requisition (PR)</span>
                <button onClick={() => setFormMode(null)} className="sco-btn-icon"><X size={18} /></button>
              </div>

              <form onSubmit={handleSavePR}>
                <div className="sco-form-grid">
                  <div className="sco-form-group">
                    <label>PR Requisition # <span className="required">*</span></label>
                    <input
                      type="text"
                      required
                      value={prForm.prNumber}
                      onChange={(e) => setPrForm({ ...prForm, prNumber: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Requesting Department <span className="required">*</span></label>
                    <select
                      value={prForm.department}
                      onChange={(e) => setPrForm({ ...prForm, department: e.target.value })}
                    >
                      <option value="Biogas Operations">Biogas Operations</option>
                      <option value="Mechanical Maintenance">Mechanical Maintenance</option>
                      <option value="Agri Logistics">Agri Logistics</option>
                      <option value="Civil Infrastructure">Civil Infrastructure</option>
                      <option value="Quality Assurance & Lab">Quality Assurance & Lab</option>
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Target Facility</label>
                    <select
                      value={prForm.plantFacility}
                      onChange={(e) => setPrForm({ ...prForm, plantFacility: e.target.value })}
                    >
                      {plants.map(p => <option key={p.plantId} value={p.plantNm}>{p.plantNm}</option>)}
                      {!plants.length && <option value="Plant 1 - Hyderabad East CBG">Plant 1 - Hyderabad East CBG</option>}
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Urgency / Priority</label>
                    <select
                      value={prForm.priority}
                      onChange={(e) => setPrForm({ ...prForm, priority: e.target.value })}
                    >
                      <option value="Low">Low - Planned Buffer</option>
                      <option value="Normal">Normal - Standard Cycle</option>
                      <option value="Urgent">Urgent - Imminent Plant Downtime</option>
                    </select>
                  </div>

                  <div className="sco-form-group col-span-full">
                    <label>Business Justification & Operational Context</label>
                    <textarea
                      rows="2"
                      required
                      value={prForm.justification}
                      onChange={(e) => setPrForm({ ...prForm, justification: e.target.value })}
                      placeholder="Explain why these items are required and consequence of delay..."
                    ></textarea>
                  </div>
                </div>

                {/* PR Line Items */}
                <div style={{ marginBottom: "20px" }}>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "12px" }}>
                    <h4 style={{ fontSize: "14px", fontWeight: "700", color: "#334155", margin: 0 }}>Required Materials & Estimated Budget</h4>
                    <button type="button" onClick={handleAddPrItem} className="sco-btn-secondary" style={{ fontSize: "12px", padding: "4px 10px" }}>
                      + Add Item Row
                    </button>
                  </div>

                  <div className="sco-table-wrapper">
                    <table className="sco-table">
                      <thead>
                        <tr>
                          <th>Item Name & Specification</th>
                          <th style={{ width: "120px" }}>Quantity</th>
                          <th style={{ width: "120px" }}>UOM</th>
                          <th style={{ width: "160px" }}>Est. Total Cost (₹)</th>
                          <th style={{ width: "60px" }}></th>
                        </tr>
                      </thead>
                      <tbody>
                        {prForm.items.map((it, idx) => (
                          <tr key={idx}>
                            <td>
                              <input
                                type="text"
                                required
                                value={it.itemName}
                                placeholder="e.g. Napier Stems / High-Pressure Seals"
                                onChange={(e) => handlePrItemChange(idx, "itemName", e.target.value)}
                                style={{ width: "100%", padding: "6px 8px", border: "1px solid #cbd5e1", borderRadius: "6px" }}
                              />
                            </td>
                            <td>
                              <input
                                type="number"
                                min="1"
                                required
                                value={it.qty}
                                onChange={(e) => handlePrItemChange(idx, "qty", e.target.value)}
                                style={{ width: "100%", padding: "6px 8px", border: "1px solid #cbd5e1", borderRadius: "6px" }}
                              />
                            </td>
                            <td>
                              <input
                                type="text"
                                required
                                value={it.uom}
                                placeholder="MT / Nos"
                                onChange={(e) => handlePrItemChange(idx, "uom", e.target.value)}
                                style={{ width: "100%", padding: "6px 8px", border: "1px solid #cbd5e1", borderRadius: "6px" }}
                              />
                            </td>
                            <td>
                              <input
                                type="number"
                                min="0"
                                required
                                value={it.estCost}
                                onChange={(e) => handlePrItemChange(idx, "estCost", e.target.value)}
                                style={{ width: "100%", padding: "6px 8px", border: "1px solid #cbd5e1", borderRadius: "6px" }}
                              />
                            </td>
                            <td>
                              <button
                                type="button"
                                onClick={() => handleRemovePrItem(idx)}
                                className="sco-btn-icon danger"
                              >
                                <Trash2 size={15} />
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>

                <div className="sco-form-actions">
                  <button type="button" onClick={() => setFormMode(null)} className="sco-btn-secondary">
                    Cancel
                  </button>
                  <button type="submit" className="sco-btn-primary">
                    <Save size={16} /> Submit Requisition for Approval
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* FULL PAGE FORM: ONBOARD SUPPLIER                               */}
          {/* ────────────────────────────────────────────────────────────── */}
          {formMode === "create_supplier" && (
            <div className="sco-form-card">
              <div className="sco-form-title">
                <span>Onboard Vendor / Supplier</span>
                <button onClick={() => setFormMode(null)} className="sco-btn-icon"><X size={18} /></button>
              </div>

              <form onSubmit={handleSaveSupplier}>
                <div className="sco-form-grid">
                  <div className="sco-form-group">
                    <label>Vendor / Legal Entity Name <span className="required">*</span></label>
                    <input
                      type="text"
                      required
                      value={supplierForm.name}
                      onChange={(e) => setSupplierForm({ ...supplierForm, name: e.target.value })}
                      placeholder="e.g. Deccan Biomass & Agritech Pvt Ltd"
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Vendor Strategic Tier</label>
                    <select
                      value={supplierForm.tier}
                      onChange={(e) => setSupplierForm({ ...supplierForm, tier: e.target.value })}
                    >
                      <option value="Tier 1 - Strategic EPC / OEM">Tier 1 - Strategic EPC / OEM</option>
                      <option value="Tier 2 - Equipment & Spares">Tier 2 - Equipment & Spares</option>
                      <option value="Tier 3 - Feedstock & Consumables">Tier 3 - Feedstock & Consumables</option>
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Supply Category</label>
                    <select
                      value={supplierForm.category}
                      onChange={(e) => setSupplierForm({ ...supplierForm, category: e.target.value })}
                    >
                      <option value="Biomass Feedstock & Silage">Biomass Feedstock & Silage</option>
                      <option value="Plant Construction & Civil">Plant Construction & Civil</option>
                      <option value="Piping & Valves (P&ID)">Piping & Valves (P&ID)</option>
                      <option value="Gas Upgradation & Compressors">Gas Upgradation & Compressors</option>
                      <option value="Chemicals, Enzymes & Consumables">Chemicals, Enzymes & Consumables</option>
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>GSTIN Number <span className="required">*</span></label>
                    <input
                      type="text"
                      required
                      value={supplierForm.gstin}
                      onChange={(e) => setSupplierForm({ ...supplierForm, gstin: e.target.value })}
                      placeholder="e.g. 36AABCB1234F1Z8"
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Contact Person</label>
                    <input
                      type="text"
                      value={supplierForm.contactPerson}
                      onChange={(e) => setSupplierForm({ ...supplierForm, contactPerson: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Phone Number</label>
                    <input
                      type="text"
                      value={supplierForm.phone}
                      onChange={(e) => setSupplierForm({ ...supplierForm, phone: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Email Address</label>
                    <input
                      type="email"
                      value={supplierForm.email}
                      onChange={(e) => setSupplierForm({ ...supplierForm, email: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Default Payment Terms</label>
                    <select
                      value={supplierForm.paymentTerms}
                      onChange={(e) => setSupplierForm({ ...supplierForm, paymentTerms: e.target.value })}
                    >
                      <option value="Net 30 Days">Net 30 Days</option>
                      <option value="Net 45 Days">Net 45 Days</option>
                      <option value="Advance 10% + Net 30">Advance 10% + Net 30</option>
                    </select>
                  </div>
                </div>

                <div className="sco-form-actions">
                  <button type="button" onClick={() => setFormMode(null)} className="sco-btn-secondary">
                    Cancel
                  </button>
                  <button type="submit" className="sco-btn-primary">
                    <Save size={16} /> Save Supplier Record
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* FULL PAGE FORM: CREATE DELIVERY NOTE (GRN)                     */}
          {/* ────────────────────────────────────────────────────────────── */}
          {formMode === "create_grn" && (
            <div className="sco-form-card">
              <div className="sco-form-title">
                <span>Record Inward Delivery Note (GRN)</span>
                <button onClick={() => setFormMode(null)} className="sco-btn-icon"><X size={18} /></button>
              </div>

              <form onSubmit={handleSaveGRN}>
                <div className="sco-form-grid">
                  <div className="sco-form-group">
                    <label>GRN Note # <span className="required">*</span></label>
                    <input
                      type="text"
                      required
                      value={grnForm.grnNumber}
                      onChange={(e) => setGrnForm({ ...grnForm, grnNumber: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Reference Purchase Order (PO) <span className="required">*</span></label>
                    <select
                      value={grnForm.poNumber}
                      onChange={(e) => setGrnForm({ ...grnForm, poNumber: e.target.value })}
                    >
                      {purchaseOrders.map(p => <option key={p.id} value={p.poNumber}>{p.poNumber} — {p.supplierName}</option>)}
                      {!purchaseOrders.length && <option value="PO-2026-0001">PO-2026-0001 (Direct PO)</option>}
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Supplier / Vendor Name</label>
                    <input
                      type="text"
                      value={grnForm.supplierName}
                      onChange={(e) => setGrnForm({ ...grnForm, supplierName: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Carrier / Logistics Transporter</label>
                    <input
                      type="text"
                      value={grnForm.transporter}
                      onChange={(e) => setGrnForm({ ...grnForm, transporter: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Delivery Truck / Vehicle Reg No</label>
                    <input
                      type="text"
                      value={grnForm.vehicleNo}
                      onChange={(e) => setGrnForm({ ...grnForm, vehicleNo: e.target.value })}
                      placeholder="e.g. TS 08 UB 7712"
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>E-Way Bill Number</label>
                    <input
                      type="text"
                      value={grnForm.eWayBill}
                      onChange={(e) => setGrnForm({ ...grnForm, eWayBill: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Ordered Qty (MT)</label>
                    <input
                      type="number"
                      step="any"
                      value={grnForm.orderedQty}
                      onChange={(e) => setGrnForm({ ...grnForm, orderedQty: parseFloat(e.target.value) || 0 })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Dispatched Qty (Challan MT)</label>
                    <input
                      type="number"
                      step="any"
                      value={grnForm.dispatchedQty}
                      onChange={(e) => setGrnForm({ ...grnForm, dispatchedQty: parseFloat(e.target.value) || 0 })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Actual Inward Weight Received (MT) <span className="required">*</span></label>
                    <input
                      type="number"
                      step="any"
                      required
                      value={grnForm.receivedQty}
                      onChange={(e) => {
                        const val = parseFloat(e.target.value) || 0;
                        setGrnForm({ ...grnForm, receivedQty: val, acceptedQty: val });
                      }}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Inspection Quality Status</label>
                    <select
                      value={grnForm.inspectionStatus}
                      onChange={(e) => setGrnForm({ ...grnForm, inspectionStatus: e.target.value })}
                    >
                      <option value="Passed QC - Stock Updated">Passed QC - Stock Updated</option>
                      <option value="Under Inspection">Under Inspection</option>
                      <option value="Discrepancy / Weight Shortage Flagged">Discrepancy / Weight Shortage Flagged</option>
                      <option value="Rejected Off-Spec">Rejected Off-Spec</option>
                    </select>
                  </div>
                </div>

                <div className="sco-form-actions">
                  <button type="button" onClick={() => setFormMode(null)} className="sco-btn-secondary">
                    Cancel
                  </button>
                  <button type="submit" className="sco-btn-primary">
                    <Save size={16} /> Confirm Receipt & Update Inventory
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* TAB 1: PURCHASE ORDERS (PO) TABLE                              */}
          {/* ────────────────────────────────────────────────────────────── */}
          {activeTab === "pos" && !formMode && (
            <div className="sco-card">
              <div className="sco-card-header">
                <h3 className="sco-card-title">
                  <ShoppingCart size={18} className="text-blue-600" />
                  Active Purchase Orders & Commitments
                </h3>
                <div className="d-flex align-items-center gap-2">
                  <button
                    onClick={() => exportToCSV(purchaseOrders, "Purchase_Orders")}
                    className="sco-btn-secondary"
                  >
                    <Download size={14} /> Export CSV
                  </button>
                </div>
              </div>

              <div className="sco-card-body">
                <div className="sco-toolbar">
                  <div className="sco-search-box">
                    <Search size={16} className="search-icon" />
                    <input
                      type="text"
                      placeholder="Search by PO #, supplier, or facility..."
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                    />
                  </div>

                  <div className="sco-filter-group">
                    <select
                      className="sco-select"
                      value={statusFilter}
                      onChange={(e) => setStatusFilter(e.target.value)}
                    >
                      <option value="All">All Statuses</option>
                      <option value="Issued">Issued / Sent</option>
                      <option value="Partially Delivered">Partially Delivered</option>
                      <option value="Fully Delivered">Fully Delivered</option>
                      <option value="Draft">Draft</option>
                    </select>
                  </div>
                </div>

                {purchaseOrders.length === 0 ? (
                  <div className="sco-empty-state">
                    <div className="icon"><ShoppingCart size={40} /></div>
                    <h3>No Purchase Orders Found</h3>
                    <p>There are currently no purchase orders issued. Click below to generate your first PO.</p>
                    <button onClick={handleOpenCreatePO} className="sco-btn-primary">
                      <Plus size={16} /> Generate First PO
                    </button>
                  </div>
                ) : (
                  <div className="sco-table-wrapper">
                    <table className="sco-table">
                      <thead>
                        <tr>
                          <th>PO Number</th>
                          <th>Supplier Name</th>
                          <th>Delivery Plant</th>
                          <th>PO Date</th>
                          <th>Expected Delivery</th>
                          <th>Line Items</th>
                          <th>Total Value (₹)</th>
                          <th>Status</th>
                          <th style={{ textAlign: "right" }}>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {purchaseOrders
                          .filter(po => {
                            const matchSearch =
                              po.poNumber?.toLowerCase().includes(searchQuery.toLowerCase()) ||
                              po.supplierName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
                              po.plantFacility?.toLowerCase().includes(searchQuery.toLowerCase());
                            const matchStatus = statusFilter === "All" || po.status === statusFilter;
                            return matchSearch && matchStatus;
                          })
                          .map((po) => (
                            <tr key={po.id}>
                              <td style={{ fontWeight: "700", color: "#1e293b" }}>{po.poNumber}</td>
                              <td>{po.supplierName}</td>
                              <td>{po.plantFacility}</td>
                              <td>{po.orderDate}</td>
                              <td>{po.deliveryDate}</td>
                              <td>{po.items?.length || 1} items</td>
                              <td style={{ fontWeight: "700", color: "#0f172a" }}>
                                ₹{Number(po.totalAmount || 0).toLocaleString("en-IN")}
                              </td>
                              <td>
                                <span className={`sco-badge ${po.status === "Fully Delivered" ? "badge-green" : po.status === "Issued" ? "badge-blue" : "badge-amber"}`}>
                                  {po.status}
                                </span>
                              </td>
                              <td style={{ textAlign: "right" }}>
                                <button
                                  onClick={() => setViewingItem({ type: "po", data: po })}
                                  className="sco-btn-icon"
                                  title="View / Print PO Voucher"
                                >
                                  <Printer size={15} />
                                </button>
                                <button
                                  onClick={async () => {
                                    if (window.confirm(`Delete ${po.poNumber}?`)) {
                                      await deletePurchaseOrder(po.id);
                                      await loadAllData();
                                    }
                                  }}
                                  className="sco-btn-icon danger"
                                  title="Delete PO"
                                >
                                  <Trash2 size={15} />
                                </button>
                              </td>
                            </tr>
                          ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* TAB 2: PURCHASE REQUISITIONS (PR) TABLE                        */}
          {/* ────────────────────────────────────────────────────────────── */}
          {activeTab === "requisitions" && !formMode && (
            <div className="sco-card">
              <div className="sco-card-header">
                <h3 className="sco-card-title">
                  <FileCheck size={18} className="text-emerald-600" />
                  Departmental Purchase Requisitions & Approvals Pipeline
                </h3>
                <div className="d-flex align-items-center gap-2">
                  <button
                    onClick={() => exportToCSV(requisitions, "Purchase_Requisitions")}
                    className="sco-btn-secondary"
                  >
                    <Download size={14} /> Export CSV
                  </button>
                </div>
              </div>

              <div className="sco-card-body">
                {requisitions.length === 0 ? (
                  <div className="sco-empty-state">
                    <div className="icon"><FileCheck size={40} /></div>
                    <h3>No Requisitions Found</h3>
                    <p>No purchase requisitions have been raised yet. Raise a PR to initiate the approval cycle.</p>
                    <button onClick={handleOpenCreatePR} className="sco-btn-primary">
                      <Plus size={16} /> Raise Requisition
                    </button>
                  </div>
                ) : (
                  <div className="sco-table-wrapper">
                    <table className="sco-table">
                      <thead>
                        <tr>
                          <th>PR Number</th>
                          <th>Department</th>
                          <th>Plant Facility</th>
                          <th>Priority</th>
                          <th>Items</th>
                          <th>Est. Budget (₹)</th>
                          <th>Approval Status</th>
                          <th style={{ textAlign: "right" }}>Workflow Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {requisitions.map((pr) => (
                          <tr key={pr.id}>
                            <td style={{ fontWeight: "700" }}>{pr.prNumber}</td>
                            <td>{pr.department}</td>
                            <td>{pr.plantFacility}</td>
                            <td>
                              <span className={`sco-badge ${pr.priority === "Urgent" ? "badge-red" : pr.priority === "High" ? "badge-amber" : "badge-slate"}`}>
                                {pr.priority}
                              </span>
                            </td>
                            <td>{pr.items?.length || 1} items</td>
                            <td style={{ fontWeight: "700" }}>₹{Number(pr.totalEstCost || 0).toLocaleString("en-IN")}</td>
                            <td>
                              <span className={`sco-badge ${pr.status === "Approved" ? "badge-green" : pr.status === "Rejected" ? "badge-red" : "badge-amber"}`}>
                                {pr.status}
                              </span>
                            </td>
                            <td style={{ textAlign: "right" }}>
                              {pr.status === "Pending Approval" ? (
                                <div className="d-flex justify-content-end gap-1">
                                  <button
                                    onClick={() => handleApprovePR(pr, "Approved")}
                                    className="sco-btn-primary"
                                    style={{ padding: "4px 8px", fontSize: "12px", background: "#16a34a" }}
                                    title="Approve Requisition"
                                  >
                                    Approve
                                  </button>
                                  <button
                                    onClick={() => handleApprovePR(pr, "Rejected")}
                                    className="sco-btn-secondary"
                                    style={{ padding: "4px 8px", fontSize: "12px", color: "#dc2626" }}
                                    title="Reject Requisition"
                                  >
                                    Reject
                                  </button>
                                </div>
                              ) : (
                                <button
                                  onClick={async () => {
                                    if (window.confirm(`Delete ${pr.prNumber}?`)) {
                                      await deletePurchaseRequisition(pr.id);
                                      await loadAllData();
                                    }
                                  }}
                                  className="sco-btn-icon danger"
                                >
                                  <Trash2 size={15} />
                                </button>
                              )}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* TAB 3: VENDOR / SUPPLIER DATABASE TABLE                        */}
          {/* ────────────────────────────────────────────────────────────── */}
          {activeTab === "vendors" && !formMode && (
            <div className="sco-card">
              <div className="sco-card-header">
                <h3 className="sco-card-title">
                  <Building size={18} className="text-purple-600" />
                  Supplier Directory & Strategic Tiering
                </h3>
                <div className="d-flex align-items-center gap-2">
                  <button
                    onClick={() => exportToCSV(suppliers, "Suppliers_Directory")}
                    className="sco-btn-secondary"
                  >
                    <Download size={14} /> Export CSV
                  </button>
                </div>
              </div>

              <div className="sco-card-body">
                {suppliers.length === 0 ? (
                  <div className="sco-empty-state">
                    <div className="icon"><Building size={40} /></div>
                    <h3>No Suppliers Registered</h3>
                    <p>Build your multi-tier supply network by onboarding your first vendor.</p>
                    <button onClick={handleOpenCreateSupplier} className="sco-btn-primary">
                      <Plus size={16} /> Onboard Supplier
                    </button>
                  </div>
                ) : (
                  <div className="sco-table-wrapper">
                    <table className="sco-table">
                      <thead>
                        <tr>
                          <th>Vendor Name</th>
                          <th>Tier</th>
                          <th>Category</th>
                          <th>GSTIN</th>
                          <th>Contact Person</th>
                          <th>Phone</th>
                          <th>Payment Terms</th>
                          <th>Status</th>
                          <th style={{ textAlign: "right" }}>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {suppliers.map((s) => (
                          <tr key={s.id}>
                            <td style={{ fontWeight: "700" }}>{s.name}</td>
                            <td><span className="sco-badge badge-purple">{s.tier}</span></td>
                            <td>{s.category}</td>
                            <td style={{ fontFamily: "monospace", fontSize: "12px" }}>{s.gstin}</td>
                            <td>{s.contactPerson || "—"}</td>
                            <td>{s.phone || "—"}</td>
                            <td>{s.paymentTerms}</td>
                            <td><span className="sco-badge badge-green">{s.status}</span></td>
                            <td style={{ textAlign: "right" }}>
                              <button
                                onClick={async () => {
                                  if (window.confirm(`Delete ${s.name}?`)) {
                                    await deleteProcurementSupplier(s.id);
                                    await loadAllData();
                                  }
                                }}
                                className="sco-btn-icon danger"
                              >
                                <Trash2 size={15} />
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* TAB 4: DELIVERY NOTES & GRN TRACKING TABLE                     */}
          {/* ────────────────────────────────────────────────────────────── */}
          {activeTab === "deliveries" && !formMode && (
            <div className="sco-card">
              <div className="sco-card-header">
                <h3 className="sco-card-title">
                  <Truck size={18} className="text-amber-600" />
                  Inward Delivery Notes & Goods Receipt Notes (GRN)
                </h3>
                <div className="d-flex align-items-center gap-2">
                  <button
                    onClick={() => exportToCSV(deliveryNotes, "Delivery_Notes_GRN")}
                    className="sco-btn-secondary"
                  >
                    <Download size={14} /> Export CSV
                  </button>
                </div>
              </div>

              <div className="sco-card-body">
                {deliveryNotes.length === 0 ? (
                  <div className="sco-empty-state">
                    <div className="icon"><Truck size={40} /></div>
                    <h3>No Delivery Notes Logged</h3>
                    <p>Track incoming consignments and auto-reconcile delivered weights against purchase orders.</p>
                    <button onClick={handleOpenCreateGRN} className="sco-btn-primary">
                      <Plus size={16} /> Log Inward Delivery
                    </button>
                  </div>
                ) : (
                  <div className="sco-table-wrapper">
                    <table className="sco-table">
                      <thead>
                        <tr>
                          <th>GRN Number</th>
                          <th>PO Reference</th>
                          <th>Supplier Name</th>
                          <th>Vehicle Reg No</th>
                          <th>Received Date</th>
                          <th>Inward Qty (MT)</th>
                          <th>QC Inspection Status</th>
                          <th style={{ textAlign: "right" }}>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {deliveryNotes.map((g) => (
                          <tr key={g.id}>
                            <td style={{ fontWeight: "700" }}>{g.grnNumber}</td>
                            <td style={{ color: "#2563eb", fontWeight: "600" }}>{g.poNumber}</td>
                            <td>{g.supplierName}</td>
                            <td style={{ fontWeight: "600" }}>{g.vehicleNo}</td>
                            <td>{g.receivedDate}</td>
                            <td style={{ fontWeight: "700" }}>{g.receivedQty} MT</td>
                            <td>
                              <span className={`sco-badge ${g.inspectionStatus?.includes("Passed") ? "badge-green" : "badge-amber"}`}>
                                {g.inspectionStatus}
                              </span>
                            </td>
                            <td style={{ textAlign: "right" }}>
                              <button
                                onClick={async () => {
                                  if (window.confirm(`Delete ${g.grnNumber}?`)) {
                                    await deleteDeliveryNote(g.id);
                                    await loadAllData();
                                  }
                                }}
                                className="sco-btn-icon danger"
                              >
                                <Trash2 size={15} />
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* PO PRINT / VIEW MODAL                                          */}
          {/* ────────────────────────────────────────────────────────────── */}
          {viewingItem?.type === "po" && (
            <div style={{
              position: "fixed",
              top: 0, left: 0, right: 0, bottom: 0,
              backgroundColor: "rgba(15, 23, 42, 0.6)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              zIndex: 1050,
              padding: "20px"
            }}>
              <div style={{
                background: "#ffffff",
                borderRadius: "14px",
                width: "100%",
                maxWidth: "750px",
                maxHeight: "90vh",
                overflowY: "auto",
                padding: "32px",
                boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)"
              }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", borderBottom: "2px solid #e2e8f0", paddingBottom: "16px", marginBottom: "20px" }}>
                  <div>
                    <h2 style={{ fontSize: "22px", fontWeight: "800", color: "#0f172a", margin: "0 0 4px 0" }}>BIONOVA ENERGY PRIVATE LIMITED</h2>
                    <p style={{ fontSize: "13px", color: "#64748b", margin: 0 }}>Corporate Procurement & Materials Management Division</p>
                  </div>
                  <button onClick={() => setViewingItem(null)} className="sco-btn-icon"><X size={20} /></button>
                </div>

                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "20px", marginBottom: "24px", fontSize: "13.5px" }}>
                  <div>
                    <p style={{ margin: "0 0 4px 0", color: "#64748b" }}>PO Reference:</p>
                    <p style={{ fontSize: "16px", fontWeight: "700", color: "#2563eb", margin: 0 }}>{viewingItem.data.poNumber}</p>
                    <p style={{ margin: "8px 0 4px 0", color: "#64748b" }}>Order Date:</p>
                    <p style={{ fontWeight: "600", margin: 0 }}>{viewingItem.data.orderDate}</p>
                    <p style={{ margin: "8px 0 4px 0", color: "#64748b" }}>Payment Terms:</p>
                    <p style={{ fontWeight: "600", margin: 0 }}>{viewingItem.data.paymentTerms}</p>
                  </div>

                  <div>
                    <p style={{ margin: "0 0 4px 0", color: "#64748b" }}>Vendor / Consignee:</p>
                    <p style={{ fontSize: "15px", fontWeight: "700", color: "#0f172a", margin: 0 }}>{viewingItem.data.supplierName}</p>
                    <p style={{ margin: "8px 0 4px 0", color: "#64748b" }}>Delivery Destination:</p>
                    <p style={{ fontWeight: "600", margin: 0 }}>{viewingItem.data.plantFacility}</p>
                    <p style={{ margin: "8px 0 4px 0", color: "#64748b" }}>Delivery Terms:</p>
                    <p style={{ fontWeight: "600", margin: 0 }}>{viewingItem.data.deliveryTerms}</p>
                  </div>
                </div>

                <div className="sco-table-wrapper" style={{ marginBottom: "20px" }}>
                  <table className="sco-table">
                    <thead>
                      <tr>
                        <th>Item Description</th>
                        <th>Qty</th>
                        <th>Unit Rate (₹)</th>
                        <th>GST</th>
                        <th style={{ textAlign: "right" }}>Total (₹)</th>
                      </tr>
                    </thead>
                    <tbody>
                      {viewingItem.data.items?.map((it, idx) => (
                        <tr key={idx}>
                          <td style={{ fontWeight: "600" }}>{it.description}</td>
                          <td>{it.qty} {it.unit}</td>
                          <td>₹{Number(it.unitPrice).toLocaleString("en-IN")}</td>
                          <td>{it.taxRate}%</td>
                          <td style={{ textAlign: "right", fontWeight: "700" }}>₹{Number(it.lineTotal).toLocaleString("en-IN")}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                <div style={{ display: "flex", justifyContent: "flex-end", marginBottom: "24px" }}>
                  <div style={{ width: "260px", background: "#f8fafc", padding: "16px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                    <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "6px", fontSize: "13px" }}>
                      <span>Subtotal:</span>
                      <span>₹{Number(viewingItem.data.subtotal || viewingItem.data.totalAmount).toLocaleString("en-IN")}</span>
                    </div>
                    <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "8px", fontSize: "13px" }}>
                      <span>Estimated Taxes:</span>
                      <span>₹{Number(viewingItem.data.taxTotal || 0).toLocaleString("en-IN")}</span>
                    </div>
                    <div style={{ display: "flex", justifyContent: "space-between", borderTop: "1px solid #cbd5e1", paddingTop: "8px", fontWeight: "800", fontSize: "15px", color: "#0f172a" }}>
                      <span>Grand Total:</span>
                      <span>₹{Number(viewingItem.data.totalAmount).toLocaleString("en-IN")}</span>
                    </div>
                  </div>
                </div>

                <div style={{ display: "flex", justifyContent: "flex-end", gap: "10px" }}>
                  <button onClick={() => window.print()} className="sco-btn-secondary">
                    <Printer size={16} /> Print Voucher
                  </button>
                  <button onClick={() => setViewingItem(null)} className="sco-btn-primary">
                    Close
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default ProcurementManagement;

