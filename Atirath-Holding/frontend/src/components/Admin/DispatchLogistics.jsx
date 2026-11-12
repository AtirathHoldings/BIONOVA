import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import Sidebar from "../Sidebar.jsx";
import Header from "../Header.jsx";
import {
  Truck,
  Plus,
  Search,
  Filter,
  Download,
  Eye,
  Trash2,
  CheckCircle2,
  AlertTriangle,
  Clock,
  Building,
  Scale,
  MapPin,
  Thermometer,
  Compass,
  User,
  Phone,
  FileText,
  Printer,
  X,
  Save,
  Radio,
  Navigation,
  Lock,
  ChevronRight,
  TrendingUp,
  RotateCcw
} from "lucide-react";
import "../../styles/SupplyChainOperations.css";
import { getScreenPermission } from "../../utils/permissions";
import {
  getVehicleTripSheets,
  saveVehicleTripSheet,
  deleteVehicleTripSheet,
  getDrivers,
  saveDriver,
  deleteDriver,
  getLogisticsWeighbridgeSlips,
  saveLogisticsWeighbridgeSlip,
  deleteLogisticsWeighbridgeSlip,
  getTransitTemperatureLogs,
  saveTransitTemperatureLog,
  deleteTransitTemperatureLog
} from "../../utils/supplyChainApi";

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

const DispatchLogistics = ({ onLogout, userRole }) => {
  const screenPerm = getScreenPermission("FLEET_DISPATCH");
  const { tab } = useParams();
  const navigate = useNavigate();

  const [activeTab, setActiveTab] = useState(tab || "trips");
  const [plants, setPlants] = useState([]);
  const [lands, setLands] = useState([]);

  // Data states
  const [trips, setTrips] = useState([]);
  const [drivers, setDrivers] = useState([]);
  const [weighbridgeSlips, setWeighbridgeSlips] = useState([]);
  const [tempLogs, setTempLogs] = useState([]);

  // Filter / Search states
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("All");

  // Form View States (Full Page Form)
  const [formMode, setFormMode] = useState(null); // 'create_trip' | 'create_driver' | 'create_weighbridge' | 'create_temp' | null
  const [editingItem, setEditingItem] = useState(null);
  const [viewingSlip, setViewingSlip] = useState(null);

  // Form States
  const [tripForm, setTripForm] = useState({
    tripNumber: "",
    origin: "",
    destination: "",
    assignedVehicle: "TS 08 UB 7712 (10-Wheeler Tipper)",
    assignedDriver: "",
    cargoCategory: "Raw Agri Biomass / Napier Grass",
    dispatchQtyMT: 25.5,
    dispatchDateTime: new Date().toISOString().slice(0, 16),
    status: "Dispatched / En Route"
  });

  const [driverForm, setDriverForm] = useState({
    name: "",
    phone: "",
    licenseNumber: "",
    licenseExpiry: "",
    hazmatCertified: true,
    assignedVehicle: "TS 08 UB 7712",
    dutyStatus: "Available"
  });

  const [wbForm, setWbForm] = useState({
    slipNumber: "",
    tripNumber: "",
    vehicleNo: "",
    inboundGrossMT: 36.8,
    outboundTareMT: 11.2,
    netWeightMT: 25.6,
    expectedQtyMT: 25.5,
    operatorName: "Ramesh Goud",
    scaleTimestamp: new Date().toISOString().replace("T", " ").slice(0, 19),
    status: "Verified & Stamped"
  });

  const [tempForm, setTempForm] = useState({
    sensorTag: "",
    tripNumber: "",
    cargoType: "Silage Feedstock Substrate",
    currentTempC: 18.4,
    minThresholdC: 12.0,
    maxThresholdC: 28.0,
    ambientTempC: 32.5,
    logTimestamp: new Date().toISOString().slice(0, 16),
    status: "Optimal"
  });

  // Load Initial Data
  useEffect(() => {
    loadAllData();
    fetchPlantsAndLands();
  }, []);

  useEffect(() => {
    if (tab && ["trips", "drivers", "weighbridge", "routes", "temperature"].includes(tab)) {
      setActiveTab(tab);
      setFormMode(null);
      setViewingSlip(null);
    }
  }, [tab]);

  const fetchPlantsAndLands = async () => {
    try {
      const headers = { "Authorization": `Bearer ${sessionStorage.getItem("authToken") || ""}` };
      const [pRes, lRes] = await Promise.all([
        fetch(`${apiBaseUrl}/api/plants`, { headers }).catch(() => null),
        fetch(`${apiBaseUrl}/api/lands`, { headers }).catch(() => null)
      ]);
      if (pRes?.ok) {
        const pData = await pRes.json();
        setPlants(pData || []);
      }
      if (lRes?.ok) {
        const lData = await lRes.json();
        setLands(lData || []);
      }
    } catch (e) {}
  };

  const loadAllData = async () => {
    const [trps, drvs, wbs, temps] = await Promise.all([
      getVehicleTripSheets(),
      getDrivers(),
      getLogisticsWeighbridgeSlips(),
      getTransitTemperatureLogs()
    ]);
    setTrips(trps);
    setDrivers(drvs);
    setWeighbridgeSlips(wbs);
    setTempLogs(temps);
  };

  const handleTabChange = (newTab) => {
    setActiveTab(newTab);
    setFormMode(null);
    setEditingItem(null);
    setViewingSlip(null);
    setSearchQuery("");
    setStatusFilter("All");
    navigate(`/dispatch-logistics/${newTab}`);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // --- Trip Operations ---
  const handleOpenCreateTrip = () => {
    const nextSeq = String(trips.length + 1).padStart(4, "0");
    const defaultOrigin = lands[0] ? `${lands[0].landName || "Farm Lot A"} (${lands[0].district || "Warangal"})` : "Warangal Napier Feedstock Farm Hub (Lot 1)";
    const defaultDest = plants[0]?.plantNm || "Hyderabad East CBG Plant";

    setTripForm({
      tripNumber: `TRP-2026-${nextSeq}`,
      origin: defaultOrigin,
      destination: defaultDest,
      assignedVehicle: "TS 08 UB 7712 (10-Wheeler Tipper)",
      assignedDriver: drivers[0]?.name || "Nagaraju Rao",
      cargoCategory: "Raw Agri Biomass / Napier Grass",
      dispatchQtyMT: 25.5,
      dispatchDateTime: new Date().toISOString().slice(0, 16),
      status: "Dispatched / En Route"
    });
    setEditingItem(null);
    setFormMode("create_trip");
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleSaveTrip = async (e) => {
    e.preventDefault();
    const payload = {
      ...tripForm,
      id: editingItem ? editingItem.id : undefined
    };
    await saveVehicleTripSheet(payload);
    await loadAllData();
    setFormMode(null);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // --- Driver Operations ---
  const handleOpenCreateDriver = () => {
    setDriverForm({
      name: "",
      phone: "",
      licenseNumber: "",
      licenseExpiry: new Date(Date.now() + 365 * 86400000 * 2).toISOString().split("T")[0],
      hazmatCertified: true,
      assignedVehicle: "TS 08 UB 7712",
      dutyStatus: "Available"
    });
    setEditingItem(null);
    setFormMode("create_driver");
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleSaveDriver = async (e) => {
    e.preventDefault();
    const payload = {
      ...driverForm,
      id: editingItem ? editingItem.id : undefined
    };
    await saveDriver(payload);
    await loadAllData();
    setFormMode(null);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // --- Weighbridge Slip Operations ---
  const handleOpenCreateWeighbridge = () => {
    const nextSeq = String(weighbridgeSlips.length + 1).padStart(4, "0");
    setWbForm({
      slipNumber: `WBS-2026-${nextSeq}`,
      tripNumber: trips[0]?.tripNumber || "TRP-2026-0001",
      vehicleNo: "TS 08 UB 7712",
      inboundGrossMT: 36.8,
      outboundTareMT: 11.2,
      netWeightMT: 25.6,
      expectedQtyMT: 25.5,
      operatorName: "Ramesh Goud",
      scaleTimestamp: new Date().toISOString().replace("T", " ").slice(0, 19),
      status: "Verified & Stamped"
    });
    setEditingItem(null);
    setFormMode("create_weighbridge");
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleSaveWeighbridge = async (e) => {
    e.preventDefault();
    const net = Math.max(0, Number(wbForm.inboundGrossMT || 0) - Number(wbForm.outboundTareMT || 0));
    const payload = {
      ...wbForm,
      netWeightMT: Number(net.toFixed(2)),
      id: editingItem ? editingItem.id : undefined
    };
    await saveLogisticsWeighbridgeSlip(payload);
    await loadAllData();
    setFormMode(null);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // --- Temp Log Operations ---
  const handleOpenCreateTemp = () => {
    const nextSeq = String(tempLogs.length + 1).padStart(3, "0");
    setTempForm({
      sensorTag: `SNS-TMP-${nextSeq}`,
      tripNumber: trips[0]?.tripNumber || "TRP-2026-0001",
      cargoType: "Silage Feedstock Substrate",
      currentTempC: 18.4,
      minThresholdC: 12.0,
      maxThresholdC: 28.0,
      ambientTempC: 32.5,
      logTimestamp: new Date().toISOString().slice(0, 16),
      status: "Optimal"
    });
    setEditingItem(null);
    setFormMode("create_temp");
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleSaveTemp = async (e) => {
    e.preventDefault();
    const cur = Number(tempForm.currentTempC);
    const max = Number(tempForm.maxThresholdC);
    const status = cur > max ? "Critical Thermal Excursion!" : cur > max - 2 ? "Warning: Rising" : "Optimal";

    const payload = {
      ...tempForm,
      status,
      id: editingItem ? editingItem.id : undefined
    };
    await saveTransitTemperatureLog(payload);
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
  const activeTripsCount = trips.filter(t => t.status?.includes("En Route") || t.status?.includes("Dispatched")).length;
  const totalWeightDispatched = trips.reduce((acc, t) => acc + Number(t.dispatchQtyMT || 0), 0);
  const availableDriversCount = drivers.filter(d => d.dutyStatus === "Available").length;
  const tempAlertsCount = tempLogs.filter(t => t.status?.includes("Critical") || t.status?.includes("Warning")).length;

  if (!screenPerm.canView) {
    return (
      <div className="sco-container">
        <Sidebar onLogout={onLogout} />
        <div className="sco-main" style={{ display: "flex", flexDirection: "column", minHeight: "100vh" }}>
          <Header title="Fleet & Dispatch Logistics" onLogout={onLogout} />
          <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "40px", textAlign: "center" }}>
            <div style={{ width: "80px", height: "80px", borderRadius: "50%", background: "#fee2e2", display: "flex", alignItems: "center", justifyContent: "center", marginBottom: "20px" }}>
              <Lock size={36} color="#dc2626" />
            </div>
            <h2 style={{ fontSize: "22px", fontWeight: "700", color: "#1e293b", marginBottom: "8px" }}>Access Restricted</h2>
            <p style={{ fontSize: "14px", color: "#64748b", maxWidth: "420px", margin: "0 auto" }}>
              You do not have view permissions for the Fleet & Dispatch Logistics module. Please contact your system administrator.
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
        <Header title="Fleet & Dispatch Logistics" onLogout={onLogout} />

        <div className="sco-content">
          {/* Header Row: Tagline on Left, Buttons on Right Edge */}
          <div className="sco-header-row">
            <p className="sco-tagline">
              Bridge crop yields from agricultural farm lots to processing plants and customer distribution hubs through synchronized trip sheets, driver allocation, weighbridge reconciliation, and perishable cold-chain telematics.
            </p>
            <div className="d-flex align-items-center gap-2" style={{ flexShrink: 0, marginLeft: "auto" }}>
              {activeTab === "trips" && (
                <button onClick={handleOpenCreateTrip} className="sco-btn-primary">
                  <Plus size={16} /> Generate Trip Sheet
                </button>
              )}
              {activeTab === "drivers" && (
                <button onClick={handleOpenCreateDriver} className="sco-btn-primary">
                  <Plus size={16} /> Register Driver
                </button>
              )}
              {activeTab === "weighbridge" && (
                <button onClick={handleOpenCreateWeighbridge} className="sco-btn-primary">
                  <Plus size={16} /> Record Weighbridge Slip
                </button>
              )}
              {activeTab === "temperature" && (
                <button onClick={handleOpenCreateTemp} className="sco-btn-primary">
                  <Plus size={16} /> Log Temperature Sensor
                </button>
              )}
            </div>
          </div>

          {/* KPI Summary Cards */}
          <div className="sco-kpi-grid">
            <div className="sco-kpi-card">
              <div className="sco-kpi-icon" style={{ backgroundColor: "#eff6ff", color: "#2563eb" }}>
                <Truck size={24} />
              </div>
              <div className="sco-kpi-info">
                <span className="sco-kpi-val">{activeTripsCount}</span>
                <span className="sco-kpi-label">Active In-Transit Trips</span>
              </div>
            </div>

            <div className="sco-kpi-card">
              <div className="sco-kpi-icon" style={{ backgroundColor: "#f0fdf4", color: "#16a34a" }}>
                <Scale size={24} />
              </div>
              <div className="sco-kpi-info">
                <span className="sco-kpi-val">{totalWeightDispatched.toFixed(1)} MT</span>
                <span className="sco-kpi-label">Total Weight Dispatched</span>
              </div>
            </div>

            <div className="sco-kpi-card">
              <div className="sco-kpi-icon" style={{ backgroundColor: "#fef3c7", color: "#d97706" }}>
                <User size={24} />
              </div>
              <div className="sco-kpi-info">
                <span className="sco-kpi-val">{availableDriversCount}</span>
                <span className="sco-kpi-label">Drivers Available in Yard</span>
              </div>
            </div>

            <div className="sco-kpi-card">
              <div className="sco-kpi-icon" style={{ backgroundColor: "#fee2e2", color: "#dc2626" }}>
                <Thermometer size={24} />
              </div>
              <div className="sco-kpi-info">
                <span className="sco-kpi-val">{tempAlertsCount}</span>
                <span className="sco-kpi-label">Cold Chain Excursions</span>
              </div>
            </div>
          </div>

          {/* Submodule Navigation Tabs */}
          <div className="sco-tabs-nav">
            <button
              className={`sco-tab-btn ${activeTab === "trips" ? "active" : ""}`}
              onClick={() => handleTabChange("trips")}
            >
              <Truck size={16} /> Vehicle Trip Sheets
              <span className="badge-count">{trips.length}</span>
            </button>

            <button
              className={`sco-tab-btn ${activeTab === "drivers" ? "active" : ""}`}
              onClick={() => handleTabChange("drivers")}
            >
              <User size={16} /> Driver Roster & Allocation
              <span className="badge-count">{drivers.length}</span>
            </button>

            <button
              className={`sco-tab-btn ${activeTab === "weighbridge" ? "active" : ""}`}
              onClick={() => handleTabChange("weighbridge")}
            >
              <Scale size={16} /> Weighbridge Slip Logs
              <span className="badge-count">{weighbridgeSlips.length}</span>
            </button>

            <button
              className={`sco-tab-btn ${activeTab === "routes" ? "active" : ""}`}
              onClick={() => handleTabChange("routes")}
            >
              <Navigation size={16} /> Route Tracking & Transit Telemetry
            </button>

            <button
              className={`sco-tab-btn ${activeTab === "temperature" ? "active" : ""}`}
              onClick={() => handleTabChange("temperature")}
            >
              <Thermometer size={16} /> Perishables & Cold Chain Temp
              <span className="badge-count">{tempLogs.length}</span>
            </button>
          </div>

          {/* ────────────────────────────────────────────────────────────── */}
          {/* FULL PAGE FORM: CREATE TRIP SHEET                              */}
          {/* ────────────────────────────────────────────────────────────── */}
          {formMode === "create_trip" && (
            <div className="sco-form-card">
              <div className="sco-form-title">
                <span>Create Vehicle Dispatch Trip Sheet</span>
                <button onClick={() => setFormMode(null)} className="sco-btn-icon"><X size={18} /></button>
              </div>

              <form onSubmit={handleSaveTrip}>
                <div className="sco-form-grid">
                  <div className="sco-form-group">
                    <label>Trip Sheet # <span className="required">*</span></label>
                    <input
                      type="text"
                      required
                      value={tripForm.tripNumber}
                      onChange={(e) => setTripForm({ ...tripForm, tripNumber: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Origin (Farm Lot from LandMaster) <span className="required">*</span></label>
                    <select
                      required
                      value={tripForm.origin}
                      onChange={(e) => setTripForm({ ...tripForm, origin: e.target.value })}
                    >
                      <option value="">-- Choose Origin Farm Lot --</option>
                      {lands.map(l => (
                        <option key={l.landId || l.id} value={`${l.landName || l.surveyNo || "Lot"} (${l.district || "Farm Site"})`}>
                          {l.landName || l.surveyNo || "Agri Lot"} — {l.district || "Site"} ({l.totalAcres || l.acres || 50} Acres)
                        </option>
                      ))}
                      {!lands.length && (
                        <>
                          <option value="Warangal Napier Grass Hub (Lot A)">Warangal Napier Grass Hub (Lot A)</option>
                          <option value="Karimnagar Energy Maize Parcel (Lot B)">Karimnagar Energy Maize Parcel (Lot B)</option>
                        </>
                      )}
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Destination (Processing Plant / Hub) <span className="required">*</span></label>
                    <select
                      required
                      value={tripForm.destination}
                      onChange={(e) => setTripForm({ ...tripForm, destination: e.target.value })}
                    >
                      <option value="">-- Choose Destination --</option>
                      {plants.map(p => (
                        <option key={p.plantId} value={p.plantNm}>
                          {p.plantNm} ({p.location || "CBG Plant"})
                        </option>
                      ))}
                      {!plants.length && (
                        <>
                          <option value="Hyderabad East CBG Plant">Hyderabad East CBG Plant</option>
                          <option value="Warangal Bio-Energy & Fertilizer Hub">Warangal Bio-Energy & Fertilizer Hub</option>
                          <option value="IOCL CNG Retail Mother Station">IOCL CNG Retail Mother Station</option>
                        </>
                      )}
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Assigned Transport Vehicle</label>
                    <input
                      type="text"
                      required
                      value={tripForm.assignedVehicle}
                      onChange={(e) => setTripForm({ ...tripForm, assignedVehicle: e.target.value })}
                      placeholder="e.g. TS 08 UB 7712 (10-Wheeler Tipper)"
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Commercial Driver Allocated</label>
                    <select
                      value={tripForm.assignedDriver}
                      onChange={(e) => setTripForm({ ...tripForm, assignedDriver: e.target.value })}
                    >
                      {drivers.map(d => <option key={d.id} value={d.name}>{d.name} ({d.dutyStatus})</option>)}
                      {!drivers.length && <option value="Nagaraju Rao">Nagaraju Rao (Available)</option>}
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Cargo Classification</label>
                    <select
                      value={tripForm.cargoCategory}
                      onChange={(e) => setTripForm({ ...tripForm, cargoCategory: e.target.value })}
                    >
                      <option value="Raw Agri Biomass / Napier Grass">Raw Agri Biomass / Napier Grass</option>
                      <option value="Press Mud / Poultry Litter Substrate">Press Mud / Poultry Litter Substrate</option>
                      <option value="Compressed Bio-Gas (CBG) Cascades">Compressed Bio-Gas (CBG) Cascades</option>
                      <option value="Fermented Organic Manure (FOM) Bulk">Fermented Organic Manure (FOM) Bulk</option>
                      <option value="Liquid Bio-Fertilizer Tanker (LFOM)">Liquid Bio-Fertilizer Tanker (LFOM)</option>
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Dispatched Quantity (MT) <span className="required">*</span></label>
                    <input
                      type="number"
                      step="any"
                      required
                      value={tripForm.dispatchQtyMT}
                      onChange={(e) => setTripForm({ ...tripForm, dispatchQtyMT: parseFloat(e.target.value) || 0 })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Dispatch Departure Timestamp</label>
                    <input
                      type="datetime-local"
                      value={tripForm.dispatchDateTime}
                      onChange={(e) => setTripForm({ ...tripForm, dispatchDateTime: e.target.value })}
                    />
                  </div>
                </div>

                <div className="sco-form-actions">
                  <button type="button" onClick={() => setFormMode(null)} className="sco-btn-secondary">
                    Cancel
                  </button>
                  <button type="submit" className="sco-btn-primary">
                    <Save size={16} /> Dispatch Vehicle & Issue Trip Sheet
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* FULL PAGE FORM: REGISTER DRIVER                                */}
          {/* ────────────────────────────────────────────────────────────── */}
          {formMode === "create_driver" && (
            <div className="sco-form-card">
              <div className="sco-form-title">
                <span>Register Commercial Fleet Driver</span>
                <button onClick={() => setFormMode(null)} className="sco-btn-icon"><X size={18} /></button>
              </div>

              <form onSubmit={handleSaveDriver}>
                <div className="sco-form-grid">
                  <div className="sco-form-group">
                    <label>Driver Full Name <span className="required">*</span></label>
                    <input
                      type="text"
                      required
                      value={driverForm.name}
                      onChange={(e) => setDriverForm({ ...driverForm, name: e.target.value })}
                      placeholder="e.g. Ramesh Naidu"
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Contact Phone Number <span className="required">*</span></label>
                    <input
                      type="text"
                      required
                      value={driverForm.phone}
                      onChange={(e) => setDriverForm({ ...driverForm, phone: e.target.value })}
                      placeholder="e.g. +91 98480 12345"
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Heavy Commercial Vehicle (HCV) License # <span className="required">*</span></label>
                    <input
                      type="text"
                      required
                      value={driverForm.licenseNumber}
                      onChange={(e) => setDriverForm({ ...driverForm, licenseNumber: e.target.value })}
                      placeholder="e.g. TS09-2015-004812"
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>License Validity Expiry</label>
                    <input
                      type="date"
                      value={driverForm.licenseExpiry}
                      onChange={(e) => setDriverForm({ ...driverForm, licenseExpiry: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Default Assigned Vehicle</label>
                    <input
                      type="text"
                      value={driverForm.assignedVehicle}
                      onChange={(e) => setDriverForm({ ...driverForm, assignedVehicle: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Duty Status</label>
                    <select
                      value={driverForm.dutyStatus}
                      onChange={(e) => setDriverForm({ ...driverForm, dutyStatus: e.target.value })}
                    >
                      <option value="Available">Available in Fleet Yard</option>
                      <option value="On Active Trip">On Active Trip</option>
                      <option value="Resting / Off-Duty">Resting / Off-Duty</option>
                    </select>
                  </div>
                </div>

                <div className="sco-form-actions">
                  <button type="button" onClick={() => setFormMode(null)} className="sco-btn-secondary">
                    Cancel
                  </button>
                  <button type="submit" className="sco-btn-primary">
                    <Save size={16} /> Save Driver Record
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* FULL PAGE FORM: RECORD WEIGHBRIDGE SLIP                        */}
          {/* ────────────────────────────────────────────────────────────── */}
          {formMode === "create_weighbridge" && (
            <div className="sco-form-card">
              <div className="sco-form-title">
                <span>Record Plant Gate Weighbridge Slip</span>
                <button onClick={() => setFormMode(null)} className="sco-btn-icon"><X size={18} /></button>
              </div>

              <form onSubmit={handleSaveWeighbridge}>
                <div className="sco-form-grid">
                  <div className="sco-form-group">
                    <label>Weighbridge Slip # <span className="required">*</span></label>
                    <input
                      type="text"
                      required
                      value={wbForm.slipNumber}
                      onChange={(e) => setWbForm({ ...wbForm, slipNumber: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Linked Trip Sheet # <span className="required">*</span></label>
                    <select
                      value={wbForm.tripNumber}
                      onChange={(e) => setWbForm({ ...wbForm, tripNumber: e.target.value })}
                    >
                      {trips.map(t => <option key={t.id} value={t.tripNumber}>{t.tripNumber} ({t.origin})</option>)}
                      {!trips.length && <option value="TRP-2026-0001">TRP-2026-0001</option>}
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Vehicle Registration Number</label>
                    <input
                      type="text"
                      required
                      value={wbForm.vehicleNo}
                      onChange={(e) => setWbForm({ ...wbForm, vehicleNo: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Inbound Gross Weight (MT) <span className="required">*</span></label>
                    <input
                      type="number"
                      step="any"
                      required
                      value={wbForm.inboundGrossMT}
                      onChange={(e) => setWbForm({ ...wbForm, inboundGrossMT: parseFloat(e.target.value) || 0 })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Outbound Empty Tare Weight (MT) <span className="required">*</span></label>
                    <input
                      type="number"
                      step="any"
                      required
                      value={wbForm.outboundTareMT}
                      onChange={(e) => setWbForm({ ...wbForm, outboundTareMT: parseFloat(e.target.value) || 0 })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Net Payload (Auto-Computed MT)</label>
                    <input
                      type="number"
                      disabled
                      value={Math.max(0, wbForm.inboundGrossMT - wbForm.outboundTareMT).toFixed(2)}
                      style={{ background: "#f1f5f9", fontWeight: "700" }}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Scale Weighbridge Operator</label>
                    <input
                      type="text"
                      value={wbForm.operatorName}
                      onChange={(e) => setWbForm({ ...wbForm, operatorName: e.target.value })}
                    />
                  </div>
                </div>

                <div className="sco-form-actions">
                  <button type="button" onClick={() => setFormMode(null)} className="sco-btn-secondary">
                    Cancel
                  </button>
                  <button type="submit" className="sco-btn-primary">
                    <Save size={16} /> Certify & Save Weighbridge Slip
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* FULL PAGE FORM: LOG COLD CHAIN TEMPERATURE                     */}
          {/* ────────────────────────────────────────────────────────────── */}
          {formMode === "create_temp" && (
            <div className="sco-form-card">
              <div className="sco-form-title">
                <span>Record Transit Temperature Telematics</span>
                <button onClick={() => setFormMode(null)} className="sco-btn-icon"><X size={18} /></button>
              </div>

              <form onSubmit={handleSaveTemp}>
                <div className="sco-form-grid">
                  <div className="sco-form-group">
                    <label>Sensor Tag ID <span className="required">*</span></label>
                    <input
                      type="text"
                      required
                      value={tempForm.sensorTag}
                      onChange={(e) => setTempForm({ ...tempForm, sensorTag: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Linked Trip Sheet</label>
                    <select
                      value={tempForm.tripNumber}
                      onChange={(e) => setTempForm({ ...tempForm, tripNumber: e.target.value })}
                    >
                      {trips.map(t => <option key={t.id} value={t.tripNumber}>{t.tripNumber}</option>)}
                      {!trips.length && <option value="TRP-2026-0001">TRP-2026-0001</option>}
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Cargo Description</label>
                    <input
                      type="text"
                      value={tempForm.cargoType}
                      onChange={(e) => setTempForm({ ...tempForm, cargoType: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Current Sensor Reading (°C) <span className="required">*</span></label>
                    <input
                      type="number"
                      step="0.1"
                      required
                      value={tempForm.currentTempC}
                      onChange={(e) => setTempForm({ ...tempForm, currentTempC: parseFloat(e.target.value) || 0 })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Maximum Allowed Safe Temp (°C)</label>
                    <input
                      type="number"
                      step="0.1"
                      value={tempForm.maxThresholdC}
                      onChange={(e) => setTempForm({ ...tempForm, maxThresholdC: parseFloat(e.target.value) || 0 })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>External Ambient Temp (°C)</label>
                    <input
                      type="number"
                      step="0.1"
                      value={tempForm.ambientTempC}
                      onChange={(e) => setTempForm({ ...tempForm, ambientTempC: parseFloat(e.target.value) || 0 })}
                    />
                  </div>
                </div>

                <div className="sco-form-actions">
                  <button type="button" onClick={() => setFormMode(null)} className="sco-btn-secondary">
                    Cancel
                  </button>
                  <button type="submit" className="sco-btn-primary">
                    <Save size={16} /> Save Telemetry Record
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* TAB 1: VEHICLE TRIP SHEETS TABLE                               */}
          {/* ────────────────────────────────────────────────────────────── */}
          {activeTab === "trips" && !formMode && (
            <div className="sco-card">
              <div className="sco-card-header">
                <h3 className="sco-card-title">
                  <Truck size={18} className="text-blue-600" />
                  Farm-to-Plant Vehicle Trip Sheets
                </h3>
                <div className="d-flex align-items-center gap-2">
                  <button onClick={() => exportToCSV(trips, "Trip_Sheets")} className="sco-btn-secondary">
                    <Download size={14} /> Export CSV
                  </button>
                </div>
              </div>

              <div className="sco-card-body">
                {trips.length === 0 ? (
                  <div className="sco-empty-state">
                    <div className="icon"><Truck size={40} /></div>
                    <h3>No Trip Sheets Dispatched</h3>
                    <p>Bridge agricultural farm lots and processing facilities by generating your first trip sheet.</p>
                    <button onClick={handleOpenCreateTrip} className="sco-btn-primary">
                      <Plus size={16} /> Generate Trip Sheet
                    </button>
                  </div>
                ) : (
                  <div className="sco-table-wrapper">
                    <table className="sco-table">
                      <thead>
                        <tr>
                          <th>Trip Sheet #</th>
                          <th>Origin Farm Lot</th>
                          <th>Destination Plant</th>
                          <th>Cargo Type</th>
                          <th>Vehicle & Driver</th>
                          <th>Qty (MT)</th>
                          <th>Status</th>
                          <th style={{ textAlign: "right" }}>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {trips.map((t) => (
                          <tr key={t.id}>
                            <td style={{ fontWeight: "700" }}>{t.tripNumber}</td>
                            <td>{t.origin}</td>
                            <td>{t.destination}</td>
                            <td>{t.cargoCategory}</td>
                            <td>
                              <div style={{ fontWeight: "600" }}>{t.assignedVehicle}</div>
                              <div style={{ fontSize: "12px", color: "#64748b" }}>{t.assignedDriver}</div>
                            </td>
                            <td style={{ fontWeight: "700" }}>{t.dispatchQtyMT} MT</td>
                            <td>
                              <span className={`sco-badge ${t.status?.includes("Completed") ? "badge-green" : "badge-blue"}`}>
                                {t.status}
                              </span>
                            </td>
                            <td style={{ textAlign: "right" }}>
                              <button
                                onClick={async () => {
                                  if (window.confirm(`Delete ${t.tripNumber}?`)) {
                                    await deleteVehicleTripSheet(t.id);
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
          {/* TAB 2: DRIVER ALLOCATION & ROSTER TABLE                        */}
          {/* ────────────────────────────────────────────────────────────── */}
          {activeTab === "drivers" && !formMode && (
            <div className="sco-card">
              <div className="sco-card-header">
                <h3 className="sco-card-title">
                  <User size={18} className="text-emerald-600" />
                  Heavy Commercial Driver Roster & Allocation
                </h3>
                <div className="d-flex align-items-center gap-2">
                  <button onClick={() => exportToCSV(drivers, "Driver_Roster")} className="sco-btn-secondary">
                    <Download size={14} /> Export CSV
                  </button>
                </div>
              </div>

              <div className="sco-card-body">
                {drivers.length === 0 ? (
                  <div className="sco-empty-state">
                    <div className="icon"><User size={40} /></div>
                    <h3>No Commercial Drivers Registered</h3>
                    <p>Maintain heavy vehicle driver licenses, hazmat certifications, and availability status.</p>
                    <button onClick={handleOpenCreateDriver} className="sco-btn-primary">
                      <Plus size={16} /> Register Driver
                    </button>
                  </div>
                ) : (
                  <div className="sco-table-wrapper">
                    <table className="sco-table">
                      <thead>
                        <tr>
                          <th>Driver Name</th>
                          <th>Phone Contact</th>
                          <th>HCV Commercial License</th>
                          <th>License Expiry</th>
                          <th>Hazmat Certified</th>
                          <th>Assigned Truck</th>
                          <th>Duty Status</th>
                          <th style={{ textAlign: "right" }}>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {drivers.map((d) => (
                          <tr key={d.id}>
                            <td style={{ fontWeight: "700" }}>{d.name}</td>
                            <td>{d.phone}</td>
                            <td style={{ fontFamily: "monospace" }}>{d.licenseNumber}</td>
                            <td>{d.licenseExpiry}</td>
                            <td>
                              <span className={`sco-badge ${d.hazmatCertified ? "badge-green" : "badge-slate"}`}>
                                {d.hazmatCertified ? "Yes (CBG Hazmat)" : "Standard"}
                              </span>
                            </td>
                            <td>{d.assignedVehicle}</td>
                            <td>
                              <span className={`sco-badge ${d.dutyStatus === "Available" ? "badge-green" : d.dutyStatus === "On Active Trip" ? "badge-blue" : "badge-amber"}`}>
                                {d.dutyStatus}
                              </span>
                            </td>
                            <td style={{ textAlign: "right" }}>
                              <button
                                onClick={async () => {
                                  if (window.confirm(`Delete ${d.name}?`)) {
                                    await deleteDriver(d.id);
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
          {/* TAB 3: WEIGHBRIDGE SLIP LOGS TABLE                             */}
          {/* ────────────────────────────────────────────────────────────── */}
          {activeTab === "weighbridge" && !formMode && (
            <div className="sco-card">
              <div className="sco-card-header">
                <h3 className="sco-card-title">
                  <Scale size={18} className="text-purple-600" />
                  Electronic Weighbridge Slip Logs
                </h3>
                <div className="d-flex align-items-center gap-2">
                  <button onClick={() => exportToCSV(weighbridgeSlips, "Weighbridge_Slips")} className="sco-btn-secondary">
                    <Download size={14} /> Export CSV
                  </button>
                </div>
              </div>

              <div className="sco-card-body">
                {weighbridgeSlips.length === 0 ? (
                  <div className="sco-empty-state">
                    <div className="icon"><Scale size={40} /></div>
                    <h3>No Weighbridge Slips Recorded</h3>
                    <p>Reconcile gross, tare, and net tonnage for incoming feedstocks and outbound CBG.</p>
                    <button onClick={handleOpenCreateWeighbridge} className="sco-btn-primary">
                      <Plus size={16} /> Record Weighbridge Slip
                    </button>
                  </div>
                ) : (
                  <div className="sco-table-wrapper">
                    <table className="sco-table">
                      <thead>
                        <tr>
                          <th>Slip Number</th>
                          <th>Trip Ref #</th>
                          <th>Vehicle Reg No</th>
                          <th>Gross (MT)</th>
                          <th>Tare (MT)</th>
                          <th>Net Weight (MT)</th>
                          <th>Scale Timestamp</th>
                          <th>Status</th>
                          <th style={{ textAlign: "right" }}>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {weighbridgeSlips.map((w) => (
                          <tr key={w.id}>
                            <td style={{ fontWeight: "700" }}>{w.slipNumber}</td>
                            <td style={{ color: "#2563eb", fontWeight: "600" }}>{w.tripNumber}</td>
                            <td style={{ fontWeight: "600" }}>{w.vehicleNo}</td>
                            <td>{w.inboundGrossMT} MT</td>
                            <td>{w.outboundTareMT} MT</td>
                            <td style={{ fontWeight: "800", color: "#0f172a" }}>{w.netWeightMT} MT</td>
                            <td>{w.scaleTimestamp}</td>
                            <td><span className="sco-badge badge-green">{w.status}</span></td>
                            <td style={{ textAlign: "right" }}>
                              <button
                                onClick={() => setViewingSlip(w)}
                                className="sco-btn-icon"
                                title="Print Scale Slip"
                              >
                                <Printer size={15} />
                              </button>
                              <button
                                onClick={async () => {
                                  if (window.confirm(`Delete ${w.slipNumber}?`)) {
                                    await deleteLogisticsWeighbridgeSlip(w.id);
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
          {/* TAB 4: ROUTE TRACKING & TRANSIT TELEMETRY                      */}
          {/* ────────────────────────────────────────────────────────────── */}
          {activeTab === "routes" && (
            <div className="sco-card">
              <div className="sco-card-header">
                <h3 className="sco-card-title">
                  <Navigation size={18} className="text-blue-600" />
                  Live Fleet Dispatch Corridors & Route Telemetry
                </h3>
              </div>

              <div className="sco-card-body">
                <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(320px, 1fr))", gap: "20px" }}>
                  <div style={{ border: "1px solid #e2e8f0", borderRadius: "10px", padding: "18px", background: "#f8fafc" }}>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "12px" }}>
                      <span className="sco-badge badge-blue">Corridor 1: Agri Substrate</span>
                      <span style={{ fontSize: "12px", color: "#16a34a", fontWeight: "700" }}>● LIVE TRANSIT</span>
                    </div>
                    <h4 style={{ fontSize: "15px", fontWeight: "700", color: "#0f172a", margin: "0 0 6px 0" }}>
                      Warangal Napier Farms → Hyderabad East CBG
                    </h4>
                    <p style={{ fontSize: "13px", color: "#64748b", margin: "0 0 16px 0" }}>
                      Distance: 148 km | Est. Transit: 3h 45m | Highway: NH 163
                    </p>

                    <div style={{ background: "#ffffff", padding: "12px", borderRadius: "8px", border: "1px solid #e2e8f0", marginBottom: "12px" }}>
                      <div style={{ display: "flex", justifyContent: "space-between", fontSize: "12.5px", marginBottom: "6px" }}>
                        <span style={{ color: "#64748b" }}>Vehicle: TS 08 UB 7712</span>
                        <span style={{ fontWeight: "700" }}>Speed: 52 km/h</span>
                      </div>
                      <div style={{ display: "flex", justifyContent: "space-between", fontSize: "12.5px" }}>
                        <span style={{ color: "#64748b" }}>Driver: Nagaraju Rao</span>
                        <span style={{ color: "#2563eb", fontWeight: "700" }}>ETA: 1h 15m remaining</span>
                      </div>
                    </div>

                    <div style={{ height: "6px", background: "#e2e8f0", borderRadius: "9999px", overflow: "hidden" }}>
                      <div style={{ width: "68%", height: "100%", background: "#2563eb" }}></div>
                    </div>
                  </div>

                  <div style={{ border: "1px solid #e2e8f0", borderRadius: "10px", padding: "18px", background: "#f8fafc" }}>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "12px" }}>
                      <span className="sco-badge badge-green">Corridor 2: CBG Mother Cascade</span>
                      <span style={{ fontSize: "12px", color: "#16a34a", fontWeight: "700" }}>● LIVE TRANSIT</span>
                    </div>
                    <h4 style={{ fontSize: "15px", fontWeight: "700", color: "#0f172a", margin: "0 0 6px 0" }}>
                      Hyderabad East CBG → IOCL Retail Dispenser Station
                    </h4>
                    <p style={{ fontSize: "13px", color: "#64748b", margin: "0 0 16px 0" }}>
                      Distance: 42 km | Est. Transit: 1h 10m | Industrial Arterial
                    </p>

                    <div style={{ background: "#ffffff", padding: "12px", borderRadius: "8px", border: "1px solid #e2e8f0", marginBottom: "12px" }}>
                      <div style={{ display: "flex", justifyContent: "space-between", fontSize: "12.5px", marginBottom: "6px" }}>
                        <span style={{ color: "#64748b" }}>Vehicle: TS 07 UA 9901</span>
                        <span style={{ fontWeight: "700" }}>Speed: 40 km/h</span>
                      </div>
                      <div style={{ display: "flex", justifyContent: "space-between", fontSize: "12.5px" }}>
                        <span style={{ color: "#64748b" }}>Driver: B. Satyanarayana</span>
                        <span style={{ color: "#16a34a", fontWeight: "700" }}>ETA: 25 mins remaining</span>
                      </div>
                    </div>

                    <div style={{ height: "6px", background: "#e2e8f0", borderRadius: "9999px", overflow: "hidden" }}>
                      <div style={{ width: "45%", height: "100%", background: "#16a34a" }}></div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* TAB 5: PERISHABLES & COLD CHAIN TEMPERATURE LOGS               */}
          {/* ────────────────────────────────────────────────────────────── */}
          {activeTab === "temperature" && !formMode && (
            <div className="sco-card">
              <div className="sco-card-header">
                <h3 className="sco-card-title">
                  <Thermometer size={18} className="text-red-600" />
                  Perishables & Bio-Feedstock Transit Temperature Monitoring
                </h3>
                <div className="d-flex align-items-center gap-2">
                  <button onClick={() => exportToCSV(tempLogs, "Temperature_Logs")} className="sco-btn-secondary">
                    <Download size={14} /> Export CSV
                  </button>
                </div>
              </div>

              <div className="sco-card-body">
                {tempLogs.length === 0 ? (
                  <div className="sco-empty-state">
                    <div className="icon"><Thermometer size={40} /></div>
                    <h3>No Temperature Logs Recorded</h3>
                    <p>Prevent feedstock self-heating and silage rotting through continuous IoT sensor temperature logs.</p>
                    <button onClick={handleOpenCreateTemp} className="sco-btn-primary">
                      <Plus size={16} /> Log Temperature Reading
                    </button>
                  </div>
                ) : (
                  <div className="sco-table-wrapper">
                    <table className="sco-table">
                      <thead>
                        <tr>
                          <th>Sensor Tag</th>
                          <th>Trip Ref #</th>
                          <th>Cargo Type</th>
                          <th>Current Reading (°C)</th>
                          <th>Allowed Safe Max (°C)</th>
                          <th>Ambient (°C)</th>
                          <th>Status</th>
                          <th style={{ textAlign: "right" }}>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {tempLogs.map((l) => (
                          <tr key={l.id}>
                            <td style={{ fontWeight: "700" }}>{l.sensorTag}</td>
                            <td style={{ color: "#2563eb", fontWeight: "600" }}>{l.tripNumber}</td>
                            <td>{l.cargoType}</td>
                            <td style={{ fontWeight: "800", color: l.status?.includes("Critical") ? "#dc2626" : "#0f172a" }}>
                              {l.currentTempC}°C
                            </td>
                            <td>{l.maxThresholdC}°C</td>
                            <td>{l.ambientTempC}°C</td>
                            <td>
                              <span className={`sco-badge ${l.status?.includes("Critical") ? "badge-red" : l.status?.includes("Warning") ? "badge-amber" : "badge-green"}`}>
                                {l.status}
                              </span>
                            </td>
                            <td style={{ textAlign: "right" }}>
                              <button
                                onClick={async () => {
                                  if (window.confirm(`Delete ${l.sensorTag}?`)) {
                                    await deleteTransitTemperatureLog(l.id);
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
          {/* WEIGHBRIDGE SLIP PRINT MODAL                                   */}
          {/* ────────────────────────────────────────────────────────────── */}
          {viewingSlip && (
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
                maxWidth: "600px",
                padding: "28px",
                boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)"
              }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", borderBottom: "2px solid #e2e8f0", paddingBottom: "14px", marginBottom: "18px" }}>
                  <div>
                    <h3 style={{ fontSize: "18px", fontWeight: "800", color: "#0f172a", margin: 0 }}>OFFICIAL WEIGHBRIDGE CERTIFICATE</h3>
                    <p style={{ fontSize: "12px", color: "#64748b", margin: 0 }}>BioNova Industrial Weighbridge Station #1</p>
                  </div>
                  <button onClick={() => setViewingSlip(null)} className="sco-btn-icon"><X size={18} /></button>
                </div>

                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px", marginBottom: "20px", fontSize: "13.5px" }}>
                  <div>
                    <p style={{ margin: "0 0 2px 0", color: "#64748b" }}>Slip Reference:</p>
                    <p style={{ fontWeight: "700", color: "#2563eb", margin: 0 }}>{viewingSlip.slipNumber}</p>
                    <p style={{ margin: "8px 0 2px 0", color: "#64748b" }}>Vehicle Reg #:</p>
                    <p style={{ fontWeight: "700", margin: 0 }}>{viewingSlip.vehicleNo}</p>
                  </div>
                  <div>
                    <p style={{ margin: "0 0 2px 0", color: "#64748b" }}>Linked Trip:</p>
                    <p style={{ fontWeight: "700", margin: 0 }}>{viewingSlip.tripNumber}</p>
                    <p style={{ margin: "8px 0 2px 0", color: "#64748b" }}>Timestamp:</p>
                    <p style={{ fontWeight: "600", margin: 0 }}>{viewingSlip.scaleTimestamp}</p>
                  </div>
                </div>

                <div style={{ background: "#f8fafc", padding: "16px", borderRadius: "8px", border: "1px solid #e2e8f0", marginBottom: "20px" }}>
                  <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "8px" }}>
                    <span>Gross Inbound Weight:</span>
                    <span style={{ fontWeight: "700" }}>{viewingSlip.inboundGrossMT} MT</span>
                  </div>
                  <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "8px" }}>
                    <span>Empty Vehicle Tare:</span>
                    <span style={{ fontWeight: "700" }}>{viewingSlip.outboundTareMT} MT</span>
                  </div>
                  <div style={{ display: "flex", justifyContent: "space-between", borderTop: "2px solid #cbd5e1", paddingTop: "8px", fontSize: "16px", fontWeight: "800", color: "#16a34a" }}>
                    <span>NET CERTIFIED PAYLOAD:</span>
                    <span>{viewingSlip.netWeightMT} MT</span>
                  </div>
                </div>

                <div style={{ display: "flex", justifyContent: "flex-end", gap: "10px" }}>
                  <button onClick={() => window.print()} className="sco-btn-secondary">
                    <Printer size={16} /> Print Ticket
                  </button>
                  <button onClick={() => setViewingSlip(null)} className="sco-btn-primary">
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

export default DispatchLogistics;

