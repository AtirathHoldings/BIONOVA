import React from "react";
import { useParams, useLocation } from "react-router-dom";
import Sidebar from "../Sidebar.jsx";
import Header from "../Header.jsx";
import { Lock } from "lucide-react";
import "../../styles/ExecutiveModule.css";
import { getScreenPermission } from "../../utils/permissions";

// Submodules
import ExecutiveCockpitOverview from "./submodules/ExecutiveCockpitOverview.jsx";
import ExpansionPipeline from "./submodules/ExpansionPipeline.jsx";
import BudgetVarianceTracker from "./submodules/BudgetVarianceTracker.jsx";
import MultiStreamRevenue from "./submodules/MultiStreamRevenue.jsx";
import ComplianceEsgRegistry from "./submodules/ComplianceEsgRegistry.jsx";
import TreasurySourcing from "./submodules/TreasurySourcing.jsx";
import EscrowFinancing from "./submodules/EscrowFinancing.jsx";
import ExecutiveAlertFeed from "./submodules/ExecutiveAlertFeed.jsx";
import CapexAnalyticsDashboard from "./submodules/CapexAnalyticsDashboard.jsx";

const ExecutiveModule = ({ onLogout }) => {
  const { submodule } = useParams();
  const location = useLocation();
  const screenPerm = getScreenPermission("EXECUTIVE_MODULE");

  if (!screenPerm.canView) {
    return (
      <div className="exec-container">
        <Sidebar onLogout={onLogout} />
        <div className="exec-main" style={{ display: "flex", flexDirection: "column", minHeight: "100vh" }}>
          <Header title="Executive C-Suite Overview" onLogout={onLogout} />
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
              You do not have permission to view the Executive Overview. Please contact your administrator to request access.
            </p>
          </div>
        </div>
      </div>
    );
  }

  // Determine active view from URL params or path
  const currentPath = location.pathname.toLowerCase();
  let activeKey = submodule ? submodule.toLowerCase() : "";

  if (!activeKey) {
    if (currentPath.includes("pipeline")) activeKey = "pipeline";
    else if (currentPath.includes("budget-variance")) activeKey = "budget-variance";
    else if (currentPath.includes("revenue")) activeKey = "revenue";
    else if (currentPath.includes("compliance-esg")) activeKey = "compliance-esg";
    else if (currentPath.includes("treasury")) activeKey = "treasury";
    else if (currentPath.includes("escrow")) activeKey = "escrow";
    else if (currentPath.includes("alerts")) activeKey = "alerts";
    else if (currentPath.includes("capex-analytics")) activeKey = "capex-analytics";
  }

  let ActiveComponent = ExecutiveCockpitOverview;
  let headerTitle = "Executive C-Suite Overview";

  switch (activeKey) {
    case "pipeline":
      ActiveComponent = ExpansionPipeline;
      headerTitle = "Expansion Pipeline Tracker";
      break;
    case "budget-variance":
      ActiveComponent = BudgetVarianceTracker;
      headerTitle = "CapEx & OpEx Cost Variance Matrix";
      break;
    case "revenue":
      ActiveComponent = MultiStreamRevenue;
      headerTitle = "Consolidated Enterprise Revenue Ledger";
      break;
    case "compliance-esg":
      ActiveComponent = ComplianceEsgRegistry;
      headerTitle = "Regulatory Compliance & ESG Scorecard";
      break;
    case "treasury":
      ActiveComponent = TreasurySourcing;
      headerTitle = "Capital Sourcing & Treasury Ledger";
      break;
    case "escrow":
      ActiveComponent = EscrowFinancing;
      headerTitle = "Escrow & Project Financing Monitor";
      break;
    case "alerts":
      ActiveComponent = ExecutiveAlertFeed;
      headerTitle = "Executive Critical Notification Feed";
      break;
    case "capex-analytics":
      ActiveComponent = CapexAnalyticsDashboard;
      headerTitle = "Project Engineering & CapEx Analytics";
      break;
    default:
      ActiveComponent = ExecutiveCockpitOverview;
      headerTitle = "Executive C-Suite Overview";
      break;
  }

  return (
    <div className="exec-container">
      <Sidebar onLogout={onLogout} />
      <div className="exec-main">
        <Header title={headerTitle} onLogout={onLogout} />
        <div className="exec-content">
          <ActiveComponent />
        </div>
      </div>
    </div>
  );
};

export default ExecutiveModule;
