import React from "react";
import { useParams, useNavigate, useLocation } from "react-router-dom";
import Sidebar from "../Sidebar.jsx";
import Header from "../Header.jsx";
import {
  ShieldCheck,
  UserCheck,
  FileBadge,
  Clock,
  Car,
  Package,
  HardHat,
  Lock,
  Radio,
  QrCode,
  Settings,
  AlertTriangle,
  ChevronRight
} from "lucide-react";
import "../../styles/VisitorManagement.css";
import { getScreenPermission } from "../../utils/permissions";

// Submodules
import VisitorDashboard from "./visitors/VisitorDashboard.jsx";
import VisitorRegistration from "./visitors/VisitorRegistration.jsx";
import VisitorList from "./visitors/VisitorList.jsx";
import VisitRequest from "./visitors/VisitRequest.jsx";
import AppointmentManagement from "./visitors/AppointmentManagement.jsx";
import VisitorApproval from "./visitors/VisitorApproval.jsx";

import GateCheckIn from "./visitors/GateCheckIn.jsx";
import GateCheckOut from "./visitors/GateCheckOut.jsx";
import GatePassManagement from "./visitors/GatePassManagement.jsx";
import QRCodeVerification from "./visitors/QRCodeVerification.jsx";

import VehicleManagement from "./visitors/VehicleManagement.jsx";
import MaterialInward from "./visitors/MaterialInward.jsx";
import MaterialOutward from "./visitors/MaterialOutward.jsx";
import SafetyClearance from "./visitors/SafetyClearance.jsx";
import VisitorAccessManagement from "./visitors/VisitorAccessManagement.jsx";

import LiveInsideTracking from "./visitors/LiveInsideTracking.jsx";
import VisitorHistory from "./visitors/VisitorHistory.jsx";
import OverdueTracking from "./visitors/OverdueTracking.jsx";
import VisitorConfiguration from "./visitors/VisitorConfiguration.jsx";

const SUBMODULE_CONFIG = {
  // 1. Direct Items under Visitor Management
  "dashboard": {
    title: "Visitor & Security Dashboard",
    Component: VisitorDashboard,
    category: null,
    icon: ShieldCheck
  },
  "registration": {
    title: "Visitor Registration & Intake",
    Component: VisitorRegistration,
    category: null,
    icon: UserCheck
  },
  "list": {
    title: "Master Visitor Directory",
    Component: VisitorList,
    category: null,
    icon: FileBadge
  },
  "request": {
    title: "Pre-Visit Request Portal",
    Component: VisitRequest,
    category: null,
    icon: Clock
  },
  "appointments": {
    title: "Appointment Management",
    Component: AppointmentManagement,
    category: null,
    icon: Clock
  },
  "approvals": {
    title: "Visitor Security Approval Desk",
    Component: VisitorApproval,
    category: null,
    icon: ShieldCheck
  },

  // 2. Gate Management Folder
  "gate-checkin": {
    title: "Gate Check-In Terminal",
    Component: GateCheckIn,
    category: "Gate Management",
    icon: UserCheck
  },
  "gate-checkout": {
    title: "Gate Perimeter Check-Out",
    Component: GateCheckOut,
    category: "Gate Management",
    icon: Clock
  },
  "gate-pass": {
    title: "Gate Pass Management",
    Component: GatePassManagement,
    category: "Gate Management",
    icon: FileBadge
  },
  "qr-verification": {
    title: "QR Code Turnstile Verification",
    Component: QRCodeVerification,
    category: "Gate Management",
    icon: QrCode,
    isComingSoon: true
  },

  // 3. Security Management Folder
  "security-vehicles": {
    title: "Vehicle Perimeter Security",
    Component: VehicleManagement,
    category: "Security Management",
    icon: Car
  },
  "material-inward": {
    title: "Security Material Inward Register",
    Component: MaterialInward,
    category: "Security Management",
    icon: Package
  },
  "material-outward": {
    title: "Material Outward Gate Pass Control",
    Component: MaterialOutward,
    category: "Security Management",
    icon: Package
  },
  "safety-clearance": {
    title: "HSE Safety Induction & PPE Desk",
    Component: SafetyClearance,
    category: "Security Management",
    icon: HardHat
  },
  "access-management": {
    title: "Plant Zone Access Management",
    Component: VisitorAccessManagement,
    category: "Security Management",
    icon: ShieldCheck
  },

  // 4. Visitor Tracking Folder
  "live-tracking": {
    title: "Currently Inside Plant — Live Tracking",
    Component: LiveInsideTracking,
    category: "Visitor Tracking",
    icon: Radio
  },
  "history": {
    title: "Historical Visitor Audit Archive",
    Component: VisitorHistory,
    category: "Visitor Tracking",
    icon: Clock
  },
  "overdue-tracking": {
    title: "Overdue Visitor Tracking",
    Component: OverdueTracking,
    category: "Visitor Tracking",
    icon: AlertTriangle
  },
  "configuration": {
    title: "Visitor Security Configuration",
    Component: VisitorConfiguration,
    category: "Visitor Tracking",
    icon: Settings
  }
};

const VisitorManagement = ({ onLogout }) => {
  const screenPerm = getScreenPermission("VISITOR_MANAGEMENT");
  const { submodule } = useParams();
  const navigate = useNavigate();
  const location = useLocation();

  // If unauthorized
  if (!screenPerm.canView) {
    return (
      <div className="vm-container">
        <Sidebar onLogout={onLogout} />
        <div className="vm-main" style={{ display: "flex", flexDirection: "column", minHeight: "100vh" }}>
          <Header title="Visitor Management" onLogout={onLogout} />
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
              You do not have permission to view Visitor Management. Please contact your administrator to request access.
            </p>
          </div>
        </div>
      </div>
    );
  }

  // Determine active key
  let activeKey = submodule || "dashboard";
  if (!SUBMODULE_CONFIG[activeKey]) {
    activeKey = "dashboard";
  }

  const activeConfig = SUBMODULE_CONFIG[activeKey];
  const ActiveComponent = activeConfig.Component;

  const handleSubmoduleChange = (key) => {
    navigate(`/visitor-management/${key}`);
  };

  return (
    <div className="vm-container">
      <Sidebar onLogout={onLogout} />
      <div className="vm-main">
        <Header title="Visitor Management & Plant Perimeter Security" onLogout={onLogout} />

        <div className="vm-content">
          {/* Clean, Elegant Header Breadcrumb Bar */}
          <div className="vm-nav-bar mb-4">
            <div className="d-flex justify-content-between align-items-center flex-wrap gap-2">
              <div className="vm-breadcrumb m-0 border-0 p-0">
                <span
                  className="cursor-pointer hover:underline text-slate-500 font-medium"
                  onClick={() => handleSubmoduleChange("dashboard")}
                >
                  Visitor Management
                </span>
                {activeConfig?.category ? (
                  <>
                    <ChevronRight size={14} className="text-slate-400" />
                    <span className="text-slate-500 font-medium">{activeConfig.category}</span>
                    <ChevronRight size={14} className="text-slate-400" />
                    <span className="font-bold text-blue-700">{activeConfig.title}</span>
                  </>
                ) : (
                  <>
                    <ChevronRight size={14} className="text-slate-400" />
                    <span className="font-bold text-blue-700">{activeConfig?.title}</span>
                  </>
                )}
              </div>

              <div className="d-flex align-items-center gap-2">
                {Boolean(activeConfig?.category) && (
                  <span className="vm-category-badge">{activeConfig.category}</span>
                )}
                {activeConfig?.isComingSoon && (
                  <span className="badge-soon">Coming Soon</span>
                )}
              </div>
            </div>
          </div>

          {/* Active Submodule Component */}
          <ActiveComponent onNavigate={handleSubmoduleChange} />
        </div>
      </div>
    </div>
  );
};

export default VisitorManagement;
