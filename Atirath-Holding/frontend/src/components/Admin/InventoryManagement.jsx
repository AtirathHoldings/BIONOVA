import React from "react";
import { useParams, useLocation } from "react-router-dom";
import Sidebar from "../Sidebar.jsx";
import Header from "../Header.jsx";
import { Lock } from "lucide-react";
import "../../styles/InventoryManagement.css";
import { getScreenPermission } from "../../utils/permissions";

// Submodules
import AgriInventoryOverview from "./inventory/AgriInventoryOverview.jsx";
import CivilMaterialsBOM from "./inventory/CivilMaterialsBOM.jsx";
import FastenersHardware from "./inventory/FastenersHardware.jsx";
import PipingInstrumentation from "./inventory/PipingInstrumentation.jsx";
import EquipmentWarranty from "./inventory/EquipmentWarranty.jsx";
import StockExpiryAlerts from "./inventory/StockExpiryAlerts.jsx";
import WarehouseWeightbridge from "./inventory/WarehouseWeightbridge.jsx";
import MultiTierVendorDatabase from "./inventory/MultiTierVendorDatabase.jsx";

const SUBMODULE_CONFIG = {
  "overview": {
    title: "Agri-Feedstock & Core Material Management",
    Component: AgriInventoryOverview
  },
  "civil-bom": {
    title: "Plant Construction & Civil Materials BOM Ledger",
    Component: CivilMaterialsBOM
  },
  "fasteners": {
    title: "Structural Hardware & Fastener Inventory Log",
    Component: FastenersHardware
  },
  "piping": {
    title: "Piping & Instrumentation (P&ID) Spares Control",
    Component: PipingInstrumentation
  },
  "warranty": {
    title: "Equipment Warranty Registry & Lapse Tracker",
    Component: EquipmentWarranty
  },
  "alerts": {
    title: "System Notification & Alert Center",
    Component: StockExpiryAlerts
  },
  "weightbridge": {
    title: "Warehouse Operations & Weightbridge Live Portal",
    Component: WarehouseWeightbridge
  },
  "vendors": {
    title: "Vendor Performance & Contract Ledger",
    Component: MultiTierVendorDatabase
  }
};

const InventoryManagement = ({ onLogout }) => {
  const screenPerm = getScreenPermission("INVENTORY_MANAGEMENT");
  const { submodule } = useParams();
  const location = useLocation();

  // Determine active submodule key based on URL path
  let activeKey = "overview";
  if (submodule && SUBMODULE_CONFIG[submodule]) {
    activeKey = submodule;
  } else if (location.pathname === "/inventory/civil-bom") {
    activeKey = "civil-bom";
  } else if (location.pathname === "/inventory/fasteners") {
    activeKey = "fasteners";
  } else if (location.pathname === "/inventory/piping") {
    activeKey = "piping";
  } else if (location.pathname === "/inventory/warranty") {
    activeKey = "warranty";
  } else if (location.pathname === "/inventory/alerts") {
    activeKey = "alerts";
  } else if (location.pathname === "/inventory/weightbridge") {
    activeKey = "weightbridge";
  } else if (location.pathname === "/inventory/vendors") {
    activeKey = "vendors";
  }

  const currentModule = SUBMODULE_CONFIG[activeKey] || SUBMODULE_CONFIG["overview"];
  const ActiveComponent = currentModule.Component;

  if (!screenPerm.canView) {
    return (
      <div className="inv-container">
        <Sidebar onLogout={onLogout} />
        <div className="inv-main" style={{ display: "flex", flexDirection: "column", minHeight: "100vh" }}>
          <Header title="Inventory Management" onLogout={onLogout} />
          <div style={{
            flex: 1,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            padding: "40px",
            textAlign: "center"
          }}>
            <div style={{
              width: "80px",
              height: "80px",
              borderRadius: "50%",
              backgroundColor: "#fee2e2",
              color: "#ef4444",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              marginBottom: "20px",
              boxShadow: "0 10px 15px -3px rgba(239, 68, 68, 0.2)",
              border: "2px solid #fca5a5"
            }}>
              <Lock size={40} />
            </div>
            <h2 style={{ fontSize: "24px", fontWeight: "800", color: "#0f172a", marginBottom: "8px" }}>
              Access Denied
            </h2>
            <p style={{ fontSize: "15px", color: "#64748b", maxWidth: "480px", lineHeight: "1.6" }}>
              You do not have permission to view Inventory Management. Please contact your administrator to request access.
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="inv-container">
      <Sidebar onLogout={onLogout} />
      <div className="inv-main">
        <Header title={currentModule.title} onLogout={onLogout} />

        <div className="inv-content">
          <ActiveComponent screenPerm={screenPerm} />
        </div>
      </div>
    </div>
  );
};

export default InventoryManagement;
