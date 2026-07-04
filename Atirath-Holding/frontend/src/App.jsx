import React, { useState, useEffect } from "react";
import { BrowserRouter, Routes, Route, Navigate, useNavigate } from "react-router-dom";
import "bootstrap/dist/css/bootstrap.min.css";
import "./styles/colors.css";
import "./styles/mobile-responsive.css"; // Added global mobile responsive styles

import Login from "./components/Login";
import AdminDashboard from "./components/Projectmanager/AdminDashboard";
import UserDashboard from "./components/Projectmanager/UserDashboard"; // New User Dashboard
import CompanyCreation from "./components/Admin/CompanyMaster";
import PlantCreation from "./components/Admin/PlantMaster";
import AgriLandAllocation from "./components/Admin/LandMaster";
import Projects from "./components/User/Projects";
import Calendar from "./components/User/Calendar";
import ProjectCreation from "./components/Projectmanager/ProjectCreation";
import MilestoneCreation from "./components/Projectmanager/MilestoneCreation";
import EmployeeCreation from "./components/Projectmanager/EmployeeMaster";
import DepartmentCreation from "./components/Projectmanager/DepartmentMaster";
import TaskBoard from "./components/User/TaskBoard";
import MyTasks from "./components/User/My Tasks";
import Profile from "./components/User/Profile";

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
      <Route path="/" element={!isLoggedIn ? <Login onLogin={handleLogin} /> : <Navigate to="/dashboard" replace />} />
      
      {/* Dashboards */}
      <Route path="/dashboard" element={isLoggedIn ? <AdminDashboard userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/user-dashboard" element={isLoggedIn ? <UserDashboard userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />

      {/* Common Routes */}
      <Route path="/projects" element={isLoggedIn ? <Projects userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/calendar" element={isLoggedIn ? <Calendar userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />

      {/* Admin Features */}
      <Route path="/company-creation" element={isLoggedIn ? <CompanyCreation onLogout={handleLogout} userRole={userRole} /> : <Navigate to="/" replace />} />
      <Route path="/plant-creation" element={isLoggedIn ? <PlantCreation userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/agriland-allocation" element={isLoggedIn ? <AgriLandAllocation userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />

      {/* Project Manager Features */}
      <Route path="/project-creation" element={isLoggedIn ? <ProjectCreation userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/milestone-creation" element={isLoggedIn ? <MilestoneCreation userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/task-board" element={isLoggedIn ? <TaskBoard userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/my-tasks" element={isLoggedIn ? <MyTasks userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/employee-creation" element={isLoggedIn ? <EmployeeCreation userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/department-creation" element={isLoggedIn ? <DepartmentCreation userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/profile" element={isLoggedIn ? <Profile userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
};

function App() {
  return <BrowserRouter><AppContent /></BrowserRouter>;
}
export default App;