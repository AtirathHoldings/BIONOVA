import React, { useState, useEffect } from "react";
import { BrowserRouter, Routes, Route, Navigate, useNavigate } from "react-router-dom";
import "bootstrap/dist/css/bootstrap.min.css";
import "./styles/colors.css";
import "./styles/mobile-responsive.css"; // Added global mobile responsive styles

import Login from "./components/Login.jsx";
import AdminDashboard from "./components/Projectmanager/AdminDashboard.jsx";
import UserDashboard from "./components/Projectmanager/UserDashboard.jsx"; // New User Dashboard
import ProjectManagerDashboard from "./components/Projectmanager/ProjectManagerDashboard.jsx";
import CompanyCreation from "./components/Admin/CompanyMaster.jsx";
import PlantCreation from "./components/Admin/PlantMaster.jsx";
import AgriLandAllocation from "./components/Admin/LandMaster.jsx";
import DepartmentMapping from "./components/Admin/DepartmentMapping.jsx";
import Projects from "./components/User/Projects.jsx";
import Calendar from "./components/User/Calendar.jsx";
import ProjectCreation from "./components/Projectmanager/ProjectCreation.jsx";
import MilestoneCreation from "./components/Projectmanager/MilestoneCreation.jsx";
import EmployeeCreation from "./components/Projectmanager/EmployeeMaster.jsx";
import DepartmentCreation from "./components/Projectmanager/DepartmentMaster.jsx";
import TaskBoard from "./components/Projectmanager/TaskBoard.jsx";
import MyTasks from "./components/User/My Tasks.jsx";
import Profile from "./components/User/Profile.jsx";
import PublicHoliday from "./components/User/PublicHoliday.jsx";
import ProjectDetails from "./components/User/ProjectDetails.jsx";
import ProjectList from "./components/Projectmanager/ProjectList.jsx";
import AssignAccess from "./components/Projectmanager/AssignAccess.jsx";
import ProjectAccess from "./components/Projectmanager/ProjectAccess.jsx";
import Assignment from "./components/Assignment.jsx";
import ResetPassword from "./components/ResetPassword.jsx";
import AllProjectGanttChart from "./components/Projectmanager/AllProjectGanttChart.jsx";

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
      <Route path="/pm-dashboard" element={isLoggedIn ? <ProjectManagerDashboard userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />

      {/* Common Routes */}
      <Route path="/projects" element={isLoggedIn ? <Projects userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/project-list" element={isLoggedIn ? <ProjectList userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/project-details/:id" element={isLoggedIn ? <ProjectDetails userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/calendar" element={isLoggedIn ? <Calendar userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />

      {/* Admin Features */}
      <Route path="/company-creation" element={isLoggedIn ? <CompanyCreation onLogout={handleLogout} userRole={userRole} /> : <Navigate to="/" replace />} />
      <Route path="/plant-creation" element={isLoggedIn ? <PlantCreation userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/agriland-allocation" element={isLoggedIn ? <AgriLandAllocation userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/department-mapping" element={isLoggedIn ? <DepartmentMapping userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />

      {/* Project Manager Features */}
      <Route path="/project-creation" element={isLoggedIn ? <ProjectCreation userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/milestone-creation" element={isLoggedIn ? <MilestoneCreation userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/task-board" element={isLoggedIn ? <TaskBoard userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/my-tasks" element={isLoggedIn ? <MyTasks userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/all-project-gantt-chart" element={isLoggedIn ? <AllProjectGanttChart userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/employee-creation" element={isLoggedIn ? <EmployeeCreation userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/department-creation" element={isLoggedIn ? <DepartmentCreation userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/profile" element={isLoggedIn ? <Profile userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/public-holidays" element={isLoggedIn ? <PublicHoliday userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/assign-access" element={isLoggedIn ? <AssignAccess userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route
        path="/project-access"
        element={
          isLoggedIn
            ? <ProjectAccess userRole={userRole} onLogout={handleLogout} />
            : <Navigate to="/" replace />
        }
      />
      <Route path="/assignment" element={isLoggedIn ? <Assignment userRole={userRole} onLogout={handleLogout} /> : <Navigate to="/" replace />} />
      <Route path="/reset-password" element={<ResetPassword />} />

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
};

function App() {
  return <BrowserRouter><AppContent /></BrowserRouter>;
}
export default App;