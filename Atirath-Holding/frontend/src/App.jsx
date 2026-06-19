import React, { useState, useEffect } from "react";
import { BrowserRouter, Routes, Route, Navigate, useNavigate } from "react-router-dom";
import "bootstrap/dist/css/bootstrap.min.css";
import "./styles/colors.css";

import Login from "./components/Login";
import Dashboard from "./components/User/Dashboard";
import AdminDashboard from "./components/Projectmanager/AdminDashboard";
import CompanyCreation from "./components/Admin/CompanyCreation";
import PlantCreation from "./components/Admin/PlantCreation";
import AgriLandAllocation from "./components/Admin/AgriLandAllocation";
import Projects from "./components/User/Projects";
import Calendar from "./components/User/Calendar";
import ProjectCreation from "./components/Projectmanager/ProjectCreation";
import MilestoneCreation from "./components/Projectmanager/MilestoneCreation";
import EmployeeCreation from "./components/Projectmanager/EmployeeCreation";
import DepartmentCreation from "./components/Projectmanager/DepartmentCreation";

const AppContent = () => {
  const navigate = useNavigate();
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [loading, setLoading] = useState(true);
  const [userRole, setUserRole] = useState("user");

  useEffect(() => {
    const loggedIn = localStorage.getItem("isLoggedIn") === "true" || sessionStorage.getItem("isLoggedIn") === "true";
    const role = localStorage.getItem("userRole") || sessionStorage.getItem("userRole") || "user";
    setIsLoggedIn(loggedIn);
    setUserRole(role);
    setLoading(false);
  }, []);

  const handleLogin = (status, role) => {
    setIsLoggedIn(status);
    setUserRole(role);
    navigate("/dashboard", { replace: true });
  };

  const handleLogout = () => {
    localStorage.clear();
    sessionStorage.clear();
    setIsLoggedIn(false);
    navigate("/", { replace: true });
  };

  if (loading) return null;

  return (
    <Routes>
      {/* Login Route */}
      <Route path="/" element={!isLoggedIn ? <Login onLogin={handleLogin} /> : <Navigate to="/dashboard" replace />} />
      
      {/* Dashboard Route - అందరికీ ఒకటే డాష్ బోర్డు ఓపెన్ అవుతుంది */}
      <Route path="/dashboard" element={isLoggedIn ? <AdminDashboard userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />

      {/* Common Routes - No Role Restrictions */}
      <Route path="/projects" element={isLoggedIn ? <Projects userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/calendar" element={isLoggedIn ? <Calendar userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />

      {/* Admin Features - Now Accessible to Everyone */}
      <Route path="/company-creation" element={isLoggedIn ? <CompanyCreation onLogout={handleLogout} userRole={userRole} /> : <Navigate to="/" replace />} />
      <Route path="/plant-creation" element={isLoggedIn ? <PlantCreation userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/agriland-allocation" element={isLoggedIn ? <AgriLandAllocation userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />

      {/* Project Manager Features - Now Accessible to Everyone */}
      <Route path="/project-creation" element={isLoggedIn ? <ProjectCreation userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/milestone-creation" element={isLoggedIn ? <MilestoneCreation userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/employee-creation" element={isLoggedIn ? <EmployeeCreation userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/department-creation" element={isLoggedIn ? <DepartmentCreation userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      
      {/* Fallback Route */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
};

function App() {
  return <BrowserRouter><AppContent /></BrowserRouter>;
}
export default App;