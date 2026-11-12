import React, { useState, useEffect } from "react";
import {
  Scale,
  Truck,
  Plus,
  Search,
  Filter,
  Download,
  Printer,
  Eye,
  Trash2,
  Barcode,
  QrCode,
  Layers,
  CheckCircle2,
  AlertTriangle,
  Clock,
  Building,
  X,
  Save,
  Check,
  RefreshCw,
  ArrowRight,
  ArrowLeft,
  ShieldCheck
} from "lucide-react";
import { getWeighbridgeSlips, saveWeighbridgeSlip, deleteWeighbridgeSlip } from "./inventoryApi";

const STORAGE_KEY = "bionova_weightbridge_portal_v1";
try { const _raw = localStorage.getItem(STORAGE_KEY); if (_raw && (_raw.includes("INV-") || _raw.includes("CIV-") || _raw.includes("FST-") || _raw.includes("BN-") || _raw.includes("UltraTech") || _raw.includes("Neuman"))) { localStorage.removeItem(STORAGE_KEY); } } catch(e){}

const INITIAL_TRUCK_SLIPS = [];

const WAREHOUSE_ZONES = [
  { name: "Zone 1: Raw Biomass Silo Yard", capacityMT: 8000, currentStockMT: 0, occupancyPct: 0, color: "#1677ff" },
  { name: "Zone 2: Chemical & Enzyme Additives Warehouse", capacityMT: 500, currentStockMT: 0, occupancyPct: 0, color: "#059669" },
  { name: "Zone 3: Mechanical & P&ID Spares Store", capacityMT: 1200, currentStockMT: 0, occupancyPct: 0, color: "#d97706" },
  { name: "Zone 4: High-Pressure CBG Cascade Yard", capacityMT: 40, currentStockMT: 0, occupancyPct: 0, color: "#7c3aed" }
];

const SAMPLE_SCAN_TAGS = [];

const WarehouseWeightbridge = ({ screenPerm }) => {
  const [slips, setSlips] = useState([]);

  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("All");

  // Barcode / RFID Scanner Simulator State
  const [scannedCode, setScannedCode] = useState("");
  const [scanResult, setScanResult] = useState(null);

  // Modals
  const [isInwardModalOpen, setIsInwardModalOpen] = useState(false);
  const [isTareModalOpen, setIsTareModalOpen] = useState(false);
  const [isSlipModalOpen, setIsSlipModalOpen] = useState(false);
  const [selectedSlip, setSelectedSlip] = useState(null);

  // New Inward Form State
  const [formData, setFormData] = useState({
    vehicleNo: "",
    transporter: "",
    driverName: "",
    driverPhone: "",
    supplier: "",
    materialName: "Napier Grass Stems (Fresh Harvest Feedstock)",
    warehouseZone: "Zone 1 - Raw Biomass Silo Yard",
    grossWeightKg: 25000,
    moisturePercent: 65,
    weighbridgeOperator: "M. Ramesh (Gate Scale 1)",
    notes: ""
  });

  // Second Tare Weight State
  const [tareInputKg, setTareInputKg] = useState("");

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(slips));
  }, [slips]);

  // KPIs
  const totalBiomassMT = slips
    .filter(s => s.status === "Completed")
    .reduce((acc, s) => acc + (s.netWeightKg / 1000), 0);

  const totalTrucksToday = slips.length;
  const activeOnScale = slips.filter(s => s.status.includes("Pending")).length;
  const rejectedCount = slips.filter(s => s.status === "Quality Rejected").length;

  // Filter
  const filteredSlips = slips.filter(item => {
    const matchesSearch =
      item.slipNo.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.vehicleNo.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.supplier.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.materialName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.driverName.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus = statusFilter === "All" || item.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

  // Scanner Simulator Handler
  const handleScanTrigger = (codeToScan) => {
    const code = codeToScan || scannedCode;
    if (!code) return;
    const match = SAMPLE_SCAN_TAGS.find(t => t.code.toLowerCase() === code.toLowerCase().trim());
    if (match) {
      setScanResult(match);
    } else {
      setScanResult({
        code: code,
        name: `Scanned Material Asset #${code}`,
        zone: "Zone 1 - Primary Reception",
        stock: "1,200 Units Verified",
        status: "Active"
      });
    }
  };

  const handleOpenNewInward = () => {
    setFormData({
      vehicleNo: "",
      transporter: "",
      driverName: "",
      driverPhone: "",
      supplier: "",
      materialName: "",
      warehouseZone: "Zone 1 - Raw Biomass Silo Yard",
      grossWeightKg: "",
      moisturePercent: "",
      weighbridgeOperator: "",
      notes: ""
    });
    setIsInwardModalOpen(true);
  };

  const handleSaveInward = (e) => {
    e.preventDefault();
    const newSlip = {
      id: Date.now(),
      slipNo: `WB-2026-${String(Date.now()).slice(-4)}`,
      vehicleNo: formData.vehicleNo,
      transporter: formData.transporter,
      driverName: formData.driverName,
      driverPhone: formData.driverPhone,
      supplier: formData.supplier,
      materialName: formData.materialName,
      warehouseZone: formData.warehouseZone,
      grossWeightKg: Number(formData.grossWeightKg),
      tareWeightKg: 0,
      netWeightKg: 0,
      moisturePercent: Number(formData.moisturePercent),
      netDryWeightKg: 0,
      status: "Weighed-In (Gross Pending Tare)",
      inTime: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      outTime: "In Unloading Process",
      date: new Date().toISOString().slice(0, 10),
      weighbridgeOperator: formData.weighbridgeOperator,
      notes: formData.notes
    };
    setSlips([newSlip, ...slips]);
    setIsInwardModalOpen(false);
  };

  const handleOpenTare = (slip) => {
    setSelectedSlip(slip);
    setTareInputKg(String(Math.round(slip.grossWeightKg * 0.35))); // sensible estimate
    setIsTareModalOpen(true);
  };

  const handleSaveTare = (e) => {
    e.preventDefault();
    const tare = Number(tareInputKg);
    if (!tare || tare >= selectedSlip.grossWeightKg) {
      alert("Error: Empty truck Tare Weight must be less than Gross Weight!");
      return;
    }

    const net = selectedSlip.grossWeightKg - tare;
    const dry = Math.round(net * (1 - (selectedSlip.moisturePercent / 100)));

    setSlips(slips.map(s => {
      if (s.id === selectedSlip.id) {
        return {
          ...s,
          tareWeightKg: tare,
          netWeightKg: net,
          netDryWeightKg: dry,
          status: "Completed",
          outTime: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        };
      }
      return s;
    }));
    setIsTareModalOpen(false);
  };

  const handleOpenSlipModal = (slip) => {
    setSelectedSlip(slip);
    setIsSlipModalOpen(true);
  };

  const handleDelete = (id) => {
    if (window.confirm("Are you sure you want to delete this weightbridge record?")) {
      setSlips(slips.filter(s => s.id !== id));
    }
  };

  const handleExportCSV = () => {
    const headers = ["Slip No", "Vehicle No", "Transporter", "Driver", "Supplier", "Material", "Warehouse Zone", "Gross (Kg)", "Tare (Kg)", "Net (Kg)", "Moisture %", "Net Dry Weight (Kg)", "Status", "Date", "In Time", "Out Time", "Operator"];
    const rows = filteredSlips.map(s => [
      s.slipNo,
      s.vehicleNo,
      `"${s.transporter}"`,
      `"${s.driverName}"`,
      `"${s.supplier}"`,
      `"${s.materialName}"`,
      `"${s.warehouseZone}"`,
      s.grossWeightKg,
      s.tareWeightKg,
      s.netWeightKg,
      s.moisturePercent,
      s.netDryWeightKg,
      s.status,
      s.date,
      s.inTime,
      s.outTime,
      `"${s.weighbridgeOperator}"`
    ]);

    const csvContent = "data:text/csv;charset=utf-8," + [headers.join(","), ...rows.map(e => e.join(","))].join("\n");
    const link = document.createElement("a");
    link.setAttribute("href", encodeURI(csvContent));
    link.setAttribute("download", `bionova_weightbridge_slips_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="submod-wrapper">
      {/* Header */}
      <div className="inv-header-section" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="inv-subtitle" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Real-time warehouse zone tracking, barcode/RFID scanner input integration, and automated digital weightbridge scale logistics for biomass trucks.
        </p>
        <div className="inv-header-actions" style={{ display: "flex", gap: "12px", alignItems: "center", flexShrink: 0, marginLeft: "auto" }}>
          <button className="inv-btn-secondary" onClick={handleExportCSV}>
            <Download size={16} />
            Export Weighbridge CSV
          </button>
          {screenPerm.canCreate && (
            <button className="inv-btn-primary" onClick={handleOpenNewInward}>
              <Plus size={16} />
              New Truck Weigh-In (Gross)
            </button>
          )}
        </div>
      </div>

      {/* If isInwardModalOpen is true, render the Full-Page Form Card. Otherwise, render the List & KPIs */}
      {isInwardModalOpen ? (
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
                <Scale size={22} color="#1677ff" />
                New Truck Inward Weigh-In (Gross Weight)
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Register inbound biomass truck consignments, record primary scale gross tonnage, and assign warehouse unloading zones.
              </p>
            </div>
            <button
              type="button"
              onClick={() => setIsInwardModalOpen(false)}
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
              <ArrowLeft size={16} /> Back to Weighbridge Portal
            </button>
          </div>

          {/* Form Body */}
          <form onSubmit={handleSaveInward} style={{ padding: "28px" }}>
            <div style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))",
              gap: "20px",
              marginBottom: "24px"
            }}>
              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Truck Vehicle Registration No *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.vehicleNo}
                  onChange={(e) => setFormData({ ...formData, vehicleNo: e.target.value })}
                  placeholder="e.g. TS 08 UB 7712"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Transporter Fleet Name *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.transporter}
                  onChange={(e) => setFormData({ ...formData, transporter: e.target.value })}
                  placeholder="e.g. Balaji Agro Logistics"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Driver Full Name *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.driverName}
                  onChange={(e) => setFormData({ ...formData, driverName: e.target.value })}
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Driver Phone Number *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.driverPhone}
                  onChange={(e) => setFormData({ ...formData, driverPhone: e.target.value })}
                  required
                />
              </div>

              <div style={{ gridColumn: "1 / -1" }}>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Supplier / Farm Source Cooperative *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.supplier}
                  onChange={(e) => setFormData({ ...formData, supplier: e.target.value })}
                  placeholder="e.g. Medak Biomass Farmer Cooperative - Zone 4"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Material Feedstock Type
                </label>
                <select
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.materialName}
                  onChange={(e) => setFormData({ ...formData, materialName: e.target.value })}
                >
                  <option value="Napier Grass Stems (Fresh Harvest Feedstock)">Napier Grass Stems (Fresh Harvest)</option>
                  <option value="Press Mud / Organic Filter Cake">Press Mud / Filter Cake</option>
                  <option value="Raw Cattle Dung Inoculum Slurry">Raw Cattle Dung Inoculum Slurry</option>
                  <option value="Paddy Straw Bales (High Density)">Paddy Straw Bales</option>
                  <option value="Sweet Sorghum Bagasse">Sweet Sorghum Bagasse</option>
                </select>
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Unloading Destination Zone
                </label>
                <select
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.warehouseZone}
                  onChange={(e) => setFormData({ ...formData, warehouseZone: e.target.value })}
                >
                  <option value="Zone 1 - Raw Biomass Silo Yard">Zone 1 - Raw Biomass Silo Yard</option>
                  <option value="Pre-treatment Bunker Pit A">Pre-treatment Bunker Pit A</option>
                  <option value="Covered Straw Storage Shed 2">Covered Straw Storage Shed 2</option>
                </select>
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Gross Weight on Scale (Kg) *
                </label>
                <input
                  type="number"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.grossWeightKg}
                  onChange={(e) => setFormData({ ...formData, grossWeightKg: e.target.value })}
                  required
                  min="1000"
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Laboratory Moisture Content (%) *
                </label>
                <input
                  type="number"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.moisturePercent}
                  onChange={(e) => setFormData({ ...formData, moisturePercent: e.target.value })}
                  required
                  min="0"
                  max="100"
                  step="0.1"
                />
              </div>

              <div style={{ gridColumn: "1 / -1" }}>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Gate Scale Operator *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.weighbridgeOperator}
                  onChange={(e) => setFormData({ ...formData, weighbridgeOperator: e.target.value })}
                  required
                />
              </div>
            </div>

            {/* Bottom Form Actions */}
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
                onClick={() => setIsInwardModalOpen(false)}
                style={{
                  padding: "10px 20px",
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
                  backgroundColor: "#1677ff",
                  color: "#ffffff",
                  fontWeight: "600",
                  cursor: "pointer",
                  fontSize: "13.5px",
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "8px",
                  boxShadow: "0 2px 6px rgba(22, 119, 255, 0.3)"
                }}
              >
                <Save size={16} />
                Record Gross Weight & Print Entry Pass
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* KPI Stats Grid */}
          <div className="inv-kpi-grid">
        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#ecfdf5", color: "#059669" }}>
            <Scale size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Net Biomass Today</h3>
            <div className="inv-kpi-value">{totalBiomassMT.toFixed(2)} MT</div>
            <p className="inv-kpi-subtext">Received & Passed QA</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: "#eff6ff", color: "#2563eb" }}>
            <Truck size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Trucks Processed</h3>
            <div className="inv-kpi-value">{totalTrucksToday} Vehicles</div>
            <p className="inv-kpi-subtext">Across 2 Gate Scales</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: activeOnScale > 0 ? "#fef3c7" : "#f1f5f9", color: activeOnScale > 0 ? "#d97706" : "#64748b" }}>
            <Clock size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Pending Tare Weigh-Out</h3>
            <div className="inv-kpi-value" style={{ color: activeOnScale > 0 ? "#d97706" : "#0f172a" }}>
              {activeOnScale} Trucks
            </div>
            <p className="inv-kpi-subtext">Currently Unloading in Bays</p>
          </div>
        </div>

        <div className="inv-kpi-card">
          <div className="inv-kpi-icon" style={{ backgroundColor: rejectedCount > 0 ? "#fee2e2" : "#f1f5f9", color: rejectedCount > 0 ? "#dc2626" : "#64748b" }}>
            <AlertTriangle size={22} />
          </div>
          <div className="inv-kpi-info">
            <h3>Quality Rejections</h3>
            <div className="inv-kpi-value" style={{ color: rejectedCount > 0 ? "#dc2626" : "#0f172a" }}>
              {rejectedCount} Consignments
            </div>
            <p className="inv-kpi-subtext">Contaminated Biomass Rejected</p>
          </div>
        </div>
      </div>

      {/* Two Column Layout: Barcode/RFID Scanner Terminal + Warehouse Storage Zones */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(360px, 1fr))", gap: "20px", marginBottom: "24px" }}>
        {/* Barcode & RFID Scanner Simulator Card */}
        <div style={{ backgroundColor: "#ffffff", borderRadius: "12px", padding: "20px", border: "1px solid #e2e8f0", boxShadow: "0 1px 3px rgba(0,0,0,0.05)" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "12px" }}>
            <Barcode size={22} color="#1677ff" />
            <h3 style={{ margin: 0, fontSize: "16px", fontWeight: "700" }}>Barcode & RFID Scanner Terminal</h3>
          </div>
          <p style={{ fontSize: "13px", color: "#64748b", margin: "0 0 14px 0" }}>
            Simulate or scan handheld RFID pallet tags or material barcodes for instant warehouse location verification and stock updates.
          </p>

          <div style={{ display: "flex", gap: "8px", marginBottom: "12px" }}>
            <input
              type="text"
              className="inv-input"
              placeholder="Scan or enter barcode / RFID tag..."
              value={scannedCode}
              onChange={(e) => setScannedCode(e.target.value)}
              onKeyDown={(e) => { if (e.key === "Enter") handleScanTrigger(); }}
            />
            <button className="inv-btn-primary" style={{ padding: "8px 16px" }} onClick={() => handleScanTrigger()}>
              Scan
            </button>
          </div>

          {SAMPLE_SCAN_TAGS.length > 0 && (
            <div style={{ display: "flex", gap: "6px", flexWrap: "wrap", marginBottom: "14px" }}>
              <span style={{ fontSize: "11px", color: "#64748b", fontWeight: "600", alignSelf: "center" }}>Quick Test Tags:</span>
              {SAMPLE_SCAN_TAGS.map(t => (
                <button
                  key={t.code}
                  type="button"
                  className="inv-btn-secondary"
                  style={{ padding: "3px 8px", fontSize: "11px" }}
                  onClick={() => { setScannedCode(t.code); handleScanTrigger(t.code); }}
                >
                  {t.code}
                </button>
              ))}
            </div>
          )}

          {scanResult && (
            <div style={{ backgroundColor: "#f0fdf4", border: "1px solid #bbf7d0", borderRadius: "8px", padding: "12px" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                <div>
                  <div style={{ fontWeight: "700", color: "#166534", fontSize: "14px" }}>{scanResult.name}</div>
                  <div style={{ fontSize: "12px", color: "#15803d", marginTop: "2px" }}>
                    Warehouse Location: <strong>{scanResult.zone}</strong>
                  </div>
                  <div style={{ fontSize: "12px", color: "#15803d" }}>
                    Verified Stock: <strong>{scanResult.stock}</strong> ({scanResult.status})
                  </div>
                </div>
                <QrCode size={32} color="#15803d" />
              </div>
              <div style={{ display: "flex", gap: "8px", marginTop: "10px" }}>
                <button
                  type="button"
                  className="inv-btn-primary"
                  style={{ padding: "4px 10px", fontSize: "11px", backgroundColor: "#059669" }}
                  onClick={() => alert(`Material ${scanResult.name} checked in successfully!`)}
                >
                  Quick Check-In (+)
                </button>
                <button
                  type="button"
                  className="inv-btn-secondary"
                  style={{ padding: "4px 10px", fontSize: "11px" }}
                  onClick={() => alert(`Material ${scanResult.name} checked out for production!`)}
                >
                  Quick Check-Out (-)
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Warehouse Storage Zones Capacity Card */}
        <div style={{ backgroundColor: "#ffffff", borderRadius: "12px", padding: "20px", border: "1px solid #e2e8f0", boxShadow: "0 1px 3px rgba(0,0,0,0.05)" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "12px" }}>
            <Building size={22} color="#1677ff" />
            <h3 style={{ margin: 0, fontSize: "16px", fontWeight: "700" }}>Warehouse Storage Zones & Silo Capacities</h3>
          </div>
          <p style={{ fontSize: "13px", color: "#64748b", margin: "0 0 14px 0" }}>
            Live volumetric utilization across plant feedstock yards, chemical storage bays, and pressurized cylinder banks.
          </p>

          <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
            {WAREHOUSE_ZONES.map((zone, idx) => (
              <div key={idx} style={{ backgroundColor: "#f8fafc", padding: "10px 14px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                <div style={{ display: "flex", justifyContent: "space-between", fontSize: "13px", fontWeight: "600", marginBottom: "4px" }}>
                  <span>{zone.name}</span>
                  <span style={{ color: zone.occupancyPct >= 80 ? "#dc2626" : zone.color }}>
                    {zone.currentStockMT.toLocaleString()} / {zone.capacityMT.toLocaleString()} {zone.name.includes("Cascade") ? "Cascades" : zone.name.includes("P&ID") ? "Bins" : "MT"} ({zone.occupancyPct}%)
                  </span>
                </div>
                <div style={{ backgroundColor: "#e2e8f0", height: "6px", borderRadius: "3px", overflow: "hidden" }}>
                  <div style={{ width: `${zone.occupancyPct}%`, backgroundColor: zone.occupancyPct >= 80 ? "#dc2626" : zone.color, height: "100%" }} />
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Filter and Search Bar for Weightbridge Ledger */}
      <div className="inv-controls-card">
        <div className="inv-controls-row">
          <div className="inv-search-box">
            <Search size={18} className="inv-search-icon" />
            <input
              type="text"
              className="inv-search-input"
              placeholder="Search by slip number, vehicle plate, driver, supplier, or material..."
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
              <option value="All">All Weighbridge Statuses</option>
              <option value="Completed">Completed (Tare & Gross Verified)</option>
              <option value="Weighed-In (Gross Pending Tare)">Weighed-In (Pending Unloading)</option>
              <option value="Quality Rejected">Quality Rejected at Gate</option>
            </select>
          </div>
        </div>
      </div>

      {/* Main Weightbridge Log Table */}
      <div className="inv-table-card">
        <div className="inv-table-wrapper">
          <table className="inv-table">
            <thead>
              <tr>
                <th>Slip No & Vehicle Plate</th>
                <th>Supplier & Farm Source</th>
                <th>Material Feedstock</th>
                <th>Gross Weight (Kg)</th>
                <th>Tare Weight (Kg)</th>
                <th>Net Biomass (Kg / MT)</th>
                <th>Moisture %</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredSlips.length === 0 ? (
                <tr>
                  <td colSpan="9" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                    No truck weighbridge records match your search criteria.
                  </td>
                </tr>
              ) : (
                filteredSlips.map((item) => (
                  <tr key={item.id}>
                    <td>
                      <div style={{ fontWeight: "700", color: "#0f172a" }}>{item.slipNo}</div>
                      <div style={{ fontSize: "12px", color: "#2563eb", fontWeight: "700", fontFamily: "monospace" }}>{item.vehicleNo}</div>
                    </td>
                    <td>
                      <div style={{ fontWeight: "600", fontSize: "13px", color: "#1e293b" }}>{item.supplier}</div>
                      <div style={{ fontSize: "11px", color: "#64748b" }}>Driver: {item.driverName} ({item.driverPhone})</div>
                    </td>
                    <td>
                      <span style={{ fontSize: "13px", fontWeight: "600", color: "#334155" }}>
                        {item.materialName}
                      </span>
                    </td>
                    <td>
                      <span style={{ fontWeight: "700" }}>{item.grossWeightKg.toLocaleString()} Kg</span>
                      <div style={{ fontSize: "11px", color: "#64748b" }}>In: {item.inTime}</div>
                    </td>
                    <td>
                      {item.tareWeightKg > 0 ? (
                        <div>
                          <span style={{ fontWeight: "600" }}>{item.tareWeightKg.toLocaleString()} Kg</span>
                          <div style={{ fontSize: "11px", color: "#64748b" }}>Out: {item.outTime}</div>
                        </div>
                      ) : (
                        <span style={{ color: "#d97706", fontWeight: "600", fontSize: "12px" }}>Pending Weigh-Out</span>
                      )}
                    </td>
                    <td>
                      {item.netWeightKg > 0 ? (
                        <div>
                          <div style={{ fontWeight: "800", color: "#059669", fontSize: "14px" }}>
                            {item.netWeightKg.toLocaleString()} Kg
                          </div>
                          <div style={{ fontSize: "11px", color: "#64748b" }}>
                            ({(item.netWeightKg / 1000).toFixed(2)} MT)
                          </div>
                        </div>
                      ) : (
                        <span style={{ color: "#94a3b8" }}>—</span>
                      )}
                    </td>
                    <td>
                      <span style={{ fontWeight: "600" }}>{item.moisturePercent}%</span>
                      {item.netDryWeightKg > 0 && (
                        <div style={{ fontSize: "11px", color: "#64748b" }}>
                          Dry: {item.netDryWeightKg.toLocaleString()} Kg
                        </div>
                      )}
                    </td>
                    <td>
                      <span className={`inv-status-pill ${
                        item.status === "Completed" ? "inv-status-in" :
                        item.status.includes("Pending") ? "inv-status-low" : "inv-status-out"
                      }`}>
                        {item.status}
                      </span>
                    </td>
                    <td>
                      <div className="inv-table-actions">
                        {item.status.includes("Pending") && screenPerm.canEdit && (
                          <button
                            className="inv-icon-btn"
                            title="Record Second Tare Weight (Weigh-Out)"
                            style={{ backgroundColor: "#fef3c7", color: "#d97706", borderColor: "#fde68a" }}
                            onClick={() => handleOpenTare(item)}
                          >
                            <Scale size={15} />
                          </button>
                        )}
                        <button
                          className="inv-icon-btn"
                          title="View / Print Digital Weighbridge Slip"
                          onClick={() => handleOpenSlipModal(item)}
                        >
                          <Printer size={15} />
                        </button>
                        {screenPerm.canDelete && (
                          <button
                            className="inv-icon-btn danger"
                            title="Delete Slip Record"
                            onClick={() => handleDelete(item.id)}
                          >
                            <Trash2 size={15} />
                          </button>
                        )}
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

      {/* Record Tare Weight Modal */}
      {isTareModalOpen && selectedSlip && (
        <div className="inv-modal-overlay" onClick={() => setIsTareModalOpen(false)}>
          <div className="inv-modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: "550px" }}>
            <div className="inv-modal-header" style={{ borderBottom: "2px solid #2563eb" }}>
              <h2>Record Empty Truck Tare Weight (Weigh-Out)</h2>
              <button className="inv-modal-close" onClick={() => setIsTareModalOpen(false)}>
                <X size={20} />
              </button>
            </div>
            <form onSubmit={handleSaveTare}>
              <div className="inv-modal-body">
                <div style={{ backgroundColor: "#f8fafc", padding: "14px", borderRadius: "8px", border: "1px solid #e2e8f0", marginBottom: "16px" }}>
                  <div style={{ fontWeight: "700", color: "#0f172a", fontSize: "15px" }}>{selectedSlip.vehicleNo} ({selectedSlip.slipNo})</div>
                  <div style={{ fontSize: "13px", color: "#64748b", marginTop: "4px" }}>
                    Supplier: {selectedSlip.supplier} | Material: {selectedSlip.materialName}
                  </div>
                  <div style={{ fontSize: "14px", fontWeight: "700", color: "#1677ff", marginTop: "6px" }}>
                    Recorded Gross Weight: {selectedSlip.grossWeightKg.toLocaleString()} Kg
                  </div>
                </div>

                <div className="inv-form-group" style={{ marginBottom: "16px" }}>
                  <label>Tare Weight (Empty Truck on Scale in Kg)</label>
                  <input
                    type="number"
                    className="inv-input"
                    value={tareInputKg}
                    onChange={(e) => setTareInputKg(e.target.value)}
                    max={selectedSlip.grossWeightKg - 100}
                    required
                  />
                </div>

                {tareInputKg && Number(tareInputKg) < selectedSlip.grossWeightKg && (
                  <div style={{ backgroundColor: "#ecfdf5", border: "1px solid #a7f3d0", padding: "12px", borderRadius: "8px" }}>
                    <div style={{ fontSize: "12px", color: "#047857" }}>Automatically Calculated Net Biomass:</div>
                    <div style={{ fontSize: "18px", fontWeight: "800", color: "#065f46" }}>
                      {(selectedSlip.grossWeightKg - Number(tareInputKg)).toLocaleString()} Kg
                      ({((selectedSlip.grossWeightKg - Number(tareInputKg)) / 1000).toFixed(2)} MT)
                    </div>
                  </div>
                )}
              </div>
              <div className="inv-modal-footer">
                <button type="button" className="inv-btn-secondary" onClick={() => setIsTareModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="inv-btn-primary">
                  <Check size={16} />
                  Confirm Tare & Complete Transaction
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Official Weightbridge Inward Slip Modal (Print Ready) */}
      {isSlipModalOpen && selectedSlip && (
        <div className="inv-modal-overlay" onClick={() => setIsSlipModalOpen(false)}>
          <div className="inv-modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: "650px" }}>
            <div className="inv-modal-header" style={{ borderBottom: "2px solid #0f172a" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                <Scale size={24} color="#1677ff" />
                <div>
                  <h2 style={{ margin: 0, fontSize: "18px" }}>Official Digital Weightbridge Inward Slip</h2>
                  <span style={{ fontSize: "12px", color: "#64748b" }}>BioNova Clean Energy Plant Logistics</span>
                </div>
              </div>
              <button className="inv-modal-close" onClick={() => setIsSlipModalOpen(false)}>
                <X size={20} />
              </button>
            </div>
            <div className="inv-modal-body" style={{ backgroundColor: "#fafaf9", padding: "20px" }}>
              <div style={{ backgroundColor: "#ffffff", padding: "20px", borderRadius: "8px", border: "1.5px solid #0f172a", boxShadow: "0 2px 6px rgba(0,0,0,0.06)" }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", borderBottom: "1px dashed #cbd5e1", paddingBottom: "12px", marginBottom: "16px" }}>
                  <div>
                    <h3 style={{ margin: 0, fontSize: "16px", fontWeight: "800", color: "#02153f" }}>BIONOVA ENERGY & AGRITECH</h3>
                    <span style={{ fontSize: "11px", color: "#64748b" }}>Plant Scale Terminal 1 • Weights & Measures Act Certified</span>
                  </div>
                  <div style={{ textAlign: "right" }}>
                    <div style={{ fontSize: "14px", fontWeight: "800", color: "#1677ff" }}>{selectedSlip.slipNo}</div>
                    <div style={{ fontSize: "11px", color: "#64748b" }}>Date: {selectedSlip.date}</div>
                  </div>
                </div>

                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "12px", marginBottom: "16px", fontSize: "13px" }}>
                  <div>
                    <span style={{ color: "#64748b", fontSize: "11px" }}>Vehicle Registration No:</span>
                    <div style={{ fontWeight: "800", fontSize: "15px", color: "#0f172a" }}>{selectedSlip.vehicleNo}</div>
                  </div>
                  <div>
                    <span style={{ color: "#64748b", fontSize: "11px" }}>Transporter:</span>
                    <div style={{ fontWeight: "600" }}>{selectedSlip.transporter}</div>
                  </div>
                  <div>
                    <span style={{ color: "#64748b", fontSize: "11px" }}>Driver Name & Contact:</span>
                    <div style={{ fontWeight: "600" }}>{selectedSlip.driverName} ({selectedSlip.driverPhone})</div>
                  </div>
                  <div>
                    <span style={{ color: "#64748b", fontSize: "11px" }}>Supplier / Farm Source:</span>
                    <div style={{ fontWeight: "700", color: "#1e40af" }}>{selectedSlip.supplier}</div>
                  </div>
                  <div style={{ gridColumn: "span 2" }}>
                    <span style={{ color: "#64748b", fontSize: "11px" }}>Material Description:</span>
                    <div style={{ fontWeight: "700" }}>{selectedSlip.materialName}</div>
                  </div>
                </div>

                {/* Weights Breakdown Card */}
                <div style={{ backgroundColor: "#f8fafc", padding: "14px", borderRadius: "8px", border: "1px solid #e2e8f0", marginBottom: "16px" }}>
                  <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "8px" }}>
                    <span style={{ fontSize: "13px", color: "#475569" }}>1. Gross Weight (Loaded Inward):</span>
                    <strong style={{ fontSize: "14px" }}>{selectedSlip.grossWeightKg.toLocaleString()} Kg</strong>
                  </div>
                  <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "8px" }}>
                    <span style={{ fontSize: "13px", color: "#475569" }}>2. Tare Weight (Empty Outward):</span>
                    <strong style={{ fontSize: "14px" }}>
                      {selectedSlip.tareWeightKg > 0 ? `${selectedSlip.tareWeightKg.toLocaleString()} Kg` : "Pending"}
                    </strong>
                  </div>
                  <div style={{ display: "flex", justifyContent: "space-between", borderTop: "2px solid #0f172a", paddingTop: "8px", marginTop: "8px" }}>
                    <span style={{ fontSize: "15px", fontWeight: "800", color: "#0f172a" }}>NET BIOMASS WEIGHT:</span>
                    <span style={{ fontSize: "18px", fontWeight: "900", color: "#059669" }}>
                      {selectedSlip.netWeightKg > 0 ? `${selectedSlip.netWeightKg.toLocaleString()} Kg (${(selectedSlip.netWeightKg / 1000).toFixed(2)} MT)` : "Pending"}
                    </span>
                  </div>
                  <div style={{ display: "flex", justifyContent: "space-between", marginTop: "6px", fontSize: "12px", color: "#64748b" }}>
                    <span>Moisture Content: {selectedSlip.moisturePercent}%</span>
                    <span>Net Dry Biomass Equivalent: {selectedSlip.netDryWeightKg > 0 ? `${selectedSlip.netDryWeightKg.toLocaleString()} Kg` : "N/A"}</span>
                  </div>
                </div>

                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", marginTop: "24px" }}>
                  <div>
                    <QrCode size={48} color="#0f172a" />
                    <div style={{ fontSize: "10px", color: "#64748b", marginTop: "2px" }}>Digital Seal #{selectedSlip.slipNo}</div>
                  </div>
                  <div style={{ textAlign: "right" }}>
                    <div style={{ fontSize: "12px", color: "#334155", fontWeight: "600" }}>{selectedSlip.weighbridgeOperator}</div>
                    <div style={{ fontSize: "11px", color: "#64748b" }}>Authorized Scale In-Charge Signature</div>
                  </div>
                </div>
              </div>
            </div>
            <div className="inv-modal-footer">
              <button
                type="button"
                className="inv-btn-primary"
                onClick={() => window.print()}
              >
                <Printer size={15} />
                Print Weighbridge Slip
              </button>
              <button type="button" className="inv-btn-secondary" onClick={() => setIsSlipModalOpen(false)}>
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default WarehouseWeightbridge;

