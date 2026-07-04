import React, { useState, useEffect } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { House, Building, Flag, Users, Calendar, Settings, Factory, MapPinned, FolderPlus, ChevronDown, ChevronRight, LogOut, ClipboardCheck, User } from "lucide-react";
import "../styles/sidebar.css";

const Sidebar = ({ onLogout }) => {
  const navigate = useNavigate();
  const location = useLocation();
  const [isDashboardOpen, setIsDashboardOpen] = useState(false);
  const [isMobileOpen, setIsMobileOpen] = useState(false);

  useEffect(() => {
    const handleToggle = () => setIsMobileOpen(prev => !prev);
    window.addEventListener('toggleSidebar', handleToggle);
    return () => window.removeEventListener('toggleSidebar', handleToggle);
  }, []);

  const closeMobileSidebar = () => setIsMobileOpen(false);

  const handleNavigate = (path) => {
    navigate(path);
    closeMobileSidebar();
  };

  // డాష్‌బోర్డ్ ఆక్టివ్ గా ఉంటే హైలైట్ చేయడానికి లాజిక్
  const isDashboardActive = location.pathname.includes('dashboard');

  const otherMenus = [
    { name: "My Projects", icon: Building, path: "/projects" },
    { name: "My Tasks", icon: ClipboardCheck, path: "/my-tasks" },
    { name: "Calendar", icon: Calendar, path: "/calendar" },
    { name: "Task Board", icon: ClipboardCheck, path: "/task-board" },
    { name: "Company Master", icon: Building, path: "/company-creation" },
    { name: "Plant Master", icon: Factory, path: "/plant-creation" },
    { name: "Land Master", icon: MapPinned, path: "/agriland-allocation" },
    { name: "Project Creation", icon: FolderPlus, path: "/project-creation" },
    { name: "Milestone Creation", icon: Flag, path: "/milestone-creation" },
    { name: "Employee Master", icon: Users, path: "/employee-creation" },
    { name: "Department Master", icon: Building, path: "/department-creation" },
    { name: "Profile", icon: User, path: "/profile" },
    { name: "Settings", icon: Settings, path: "/settings" }
  ];

  return (
    <>
      {isMobileOpen && <div className="sidebar-overlay" onClick={closeMobileSidebar}></div>}
      <div className={`sidebar ${isMobileOpen ? 'mobile-open' : ''}`}>
        {/* Logo Section */}
        <div className="logo-section">
          <img src="/icon2.png" alt="Logo" className="company-logo" />
          <div className="company-text">
            <h3>Atirath</h3>
            <span>Holdings India Limited</span>
          </div>
        </div>
        
        {/* Menu List */}
        <ul className="menu-list">
          {/* Dashboard Dropdown Menu */}
          <li className={`dropdown-container ${isDashboardActive ? "active-dropdown" : ""}`}>
            <div className="dropdown-header" onClick={() => setIsDashboardOpen(!isDashboardOpen)}>
              <div className="d-flex align-items-center gap-2">
                <House size={20} /> <span className="m-0">Dashboard</span>
              </div>
              {isDashboardOpen ? <ChevronDown size={18} /> : <ChevronRight size={18} />}
            </div>
            
            {/* Submenu for Dashboard */}
            {isDashboardOpen && (
              <ul className="submenu-list">
                <li 
                  onClick={() => handleNavigate("/dashboard")}
                  className={location.pathname === "/dashboard" ? "submenu-active" : ""}
                >
                  Admin Dashboard
                </li>
                <li 
                  onClick={() => handleNavigate("/user-dashboard")}
                  className={location.pathname === "/user-dashboard" ? "submenu-active" : ""}
                >
                  User Dashboard
                </li>
              </ul>
            )}
          </li>

          {/* Other Menus */}
          {otherMenus.map((m, i) => (
            <li 
              key={i} 
              onClick={() => handleNavigate(m.path)} 
              className={location.pathname === m.path ? "active" : ""}
            >
              <m.icon size={20} /> <span>{m.name}</span>
            </li>
          ))}
        </ul>
        
        {/* Logout Button */}
        <div className="logout-button" onClick={() => { onLogout(); closeMobileSidebar(); }}>
          <LogOut size={20} /> <span>Logout</span>
        </div>
      </div>
    </>
  );
};

export default Sidebar;