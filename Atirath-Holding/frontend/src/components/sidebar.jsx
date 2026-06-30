import React, { useState, useEffect } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { House, Building, Flag, Users, Calendar, Settings, Factory, MapPinned, FolderPlus, ChevronDown, ChevronRight, ChevronLeft, LogOut, ClipboardCheck, User, X, PanelLeftOpen, PanelLeftClose } from "lucide-react";
import "../styles/sidebar.css";

const Sidebar = ({ onLogout }) => {
  const navigate = useNavigate();
  const location = useLocation();
  const [isMobileOpen, setIsMobileOpen] = useState(false);
  const [isCollapsed, setIsCollapsed] = useState(
    localStorage.getItem("sidebarCollapsed") === "true"
  );

  // Active path highlight logic
  const isCompanyActive = [
    "/dashboard",
    "/company-creation",
    "/plant-creation",
    "/agriland-allocation",
    "/employee-creation",
    "/department-creation",
    "/department-mapping"
  ].includes(location.pathname);
  const isProjectActive = [
    "/project-creation",
    "/milestone-creation",
    "/pm-dashboard",
    "/project-list",
    "/individual-task",
    "/task-board"
  ].includes(location.pathname);
  const isUserMasterActive = [
    "/user-dashboard",
    "/my-tasks",
    "/calendar",
    "/projects"
  ].includes(location.pathname);

  // Initialize dropdowns open/closed based on current active paths
  const [openDropdowns, setOpenDropdowns] = useState({
    company: isCompanyActive,
    project: isProjectActive,
    userMaster: isUserMasterActive
  });

  // Update dropdown state when navigating to match current active paths and collapse inactive ones
  useEffect(() => {
    setOpenDropdowns({
      company: isCompanyActive,
      project: isProjectActive,
      userMaster: isUserMasterActive
    });
  }, [location.pathname, isCompanyActive, isProjectActive, isUserMasterActive]);

  // Track collapse state and set body class
  useEffect(() => {
    if (isCollapsed) {
      document.body.classList.add("sidebar-collapsed");
      localStorage.setItem("sidebarCollapsed", "true");
    } else {
      document.body.classList.remove("sidebar-collapsed");
      localStorage.setItem("sidebarCollapsed", "false");
    }
  }, [isCollapsed]);

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

  const toggleDropdown = (key) => {
    if (isCollapsed) {
      setIsCollapsed(false);
      setOpenDropdowns(prev => ({ ...prev, [key]: true }));
    } else {
      setOpenDropdowns(prev => ({
        ...prev,
        [key]: !prev[key]
      }));
    }
  };

  const handleCollapseToggle = () => {
    if (window.innerWidth <= 768) {
      setIsMobileOpen(false);
    } else {
      setIsCollapsed(prev => !prev);
    }
  };

  const menuConfig = [
    {
      key: "company",
      name: "Company Master",
      icon: Building,
      isActive: isCompanyActive,
      subItems: [
        { name: "Admin Dashboard", path: "/dashboard" },
        { name: "Company Creation", path: "/company-creation" },
        { name: "Plant Creation", path: "/plant-creation" },
        { name: "Land Creation", path: "/agriland-allocation" },
        { name: "Employee Creation", path: "/employee-creation" },
        { name: "Department Creation", path: "/department-creation" },
        { name: "Department Mapping", path: "/department-mapping" }
      ]
    },
    {
      key: "project",
      name: "Project",
      icon: FolderPlus,
      isActive: isProjectActive,
      subItems: [
        { name: "Project Creation", path: "/project-creation" },
        { name: "Milestone Creation", path: "/milestone-creation" },
        { name: "Project Dashboard", path: "/pm-dashboard" },
        { name: "Project List", path: "/project-list" },
        { name: "Individual Task", path: "/individual-task" },
        { name: "Task Board", path: "/task-board" }
      ]
    },
    {
      key: "userMaster",
      name: "User",
      icon: Users,
      isActive: isUserMasterActive,
      subItems: [
        { name: "User Dashboard", path: "/user-dashboard" },
        { name: "My Task", path: "/my-tasks" },
        { name: "Calendar", path: "/calendar" },
        { name: "My Project", path: "/projects" }
      ]
    }
  ];

  const singleMenus = [
    { name: "Public Holidays", icon: Calendar, path: "/public-holidays" },
    { name: "Assign Access", icon: ClipboardCheck, path: "/assign-access" },
    { name: "Profile", icon: User, path: "/profile" },
    { name: "Settings", icon: Settings, path: "/settings" }
  ];

  return (
    <>
      {isMobileOpen && <div className="sidebar-overlay" onClick={closeMobileSidebar}></div>}

      <div className={`sidebar ${isMobileOpen ? 'mobile-open' : ''} ${isCollapsed ? 'collapsed' : ''}`}>
        {/* Logo Section */}
        <div className="logo-section" style={{ 
          display: "flex", 
          flexDirection: isCollapsed ? "column" : "row",
          alignItems: "center", 
          justifyContent: isCollapsed ? "center" : "space-between", 
          gap: isCollapsed ? "20px" : "10px", 
          width: "100%",
          padding: isCollapsed ? "8px 0" : "0 4px",
          marginBottom: isCollapsed ? "20px" : "35px"
        }}>
          
          {isCollapsed ? (
            /* ChatGPT Style Combined Toggle & Logo */
            <button
              className="chatgpt-style-btn"
              onClick={handleCollapseToggle}
              data-tooltip="Open sidebar"
            >
              <div className="chatgpt-btn-logo">
                <img src="/sidebar_icon.svg" alt="Logo Icon" />
              </div>
              <div className="chatgpt-btn-icon">
                <PanelLeftOpen size={20} strokeWidth={1.5} color="#ffffff" />
              </div>
            </button>
          ) : (
            <div style={{ display: 'flex', alignItems: 'center', width: '100%', gap: '10px', padding: '0 4px' }}>
              {/* Desktop Logo when open */}
              <div className="logo-details" 
                style={{ 
                  display: "flex", 
                  flex: 1, 
                  minWidth: 0, 
                  justifyContent: "center", 
                  alignItems: "center",
                  background: "#ffffff",
                  borderRadius: "14px",
                  padding: "2px",
                  boxShadow: "0 2px 10px rgba(0, 0, 0, 0.15)",
                  overflow: "hidden"
                }}>
                <img
                  src="/sidebar_logo.svg"
                  alt="Logo Banner"
                  style={{
                    width: "100%",
                    maxHeight: "54px",
                    objectFit: "contain",
                    padding: "2px 8px"
                  }}
                />
              </div>
              <button
                onClick={handleCollapseToggle}
                style={{
                  background: 'rgba(255, 255, 255, 0.1)',
                  border: '1px solid rgba(255,255,255,0.2)',
                  color: 'white',
                  padding: '10px',
                  borderRadius: '12px',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  transition: 'background 0.2s'
                }}
                onMouseEnter={(e) => e.currentTarget.style.background = 'rgba(255, 255, 255, 0.2)'}
                onMouseLeave={(e) => e.currentTarget.style.background = 'rgba(255, 255, 255, 0.1)'}
                title="Close sidebar"
              >
                <PanelLeftClose size={20} strokeWidth={1.5} />
              </button>
            </div>
          )}

          {/* Mobile close button - only visible on mobile via CSS */}
          <button
            className="sidebar-mobile-close-btn"
            onClick={closeMobileSidebar}
            title="Close Menu"
            aria-label="Close sidebar"
          >
            <X size={20} />
          </button>
        </div>

        {/* Menu List */}
        <ul className="menu-list">
          {/* Dropdown Menus */}
          {menuConfig.map((item) => (
            <li
              key={item.key}
              className={`dropdown-container ${(item.isActive || openDropdowns[item.key]) ? "active-dropdown" : ""}`}
            >
              <div
                className="dropdown-header"
                onClick={() => toggleDropdown(item.key)}
              >
                <div className="d-flex align-items-center gap-2">
                  <item.icon size={20} /> <span className="m-0">{item.name}</span>
                </div>
                {openDropdowns[item.key] ? <ChevronDown size={18} /> : <ChevronRight size={18} />}
              </div>

              {/* Submenu */}
              {!isCollapsed && openDropdowns[item.key] && (
                <ul className="submenu-list">
                  {item.subItems.map((sub, sIdx) => (
                    <li
                      key={sIdx}
                      onClick={() => handleNavigate(sub.path)}
                      className={location.pathname === sub.path ? "submenu-active" : ""}
                    >
                      {sub.name}
                    </li>
                  ))}
                </ul>
              )}
            </li>
          ))}

          {/* Single Menus */}
          {singleMenus.map((m, i) => (
            <li
              key={i}
              onClick={() => handleNavigate(m.path)}
              className={location.pathname === m.path ? "active-single" : ""}
            >
              <m.icon size={20} /> <span>{m.name}</span>
            </li>
          ))}
        </ul>

        {/* Logout Button */}
        <div className="logout-button" onClick={() => { onLogout(); closeMobileSidebar(); }}>
          <LogOut size={20} /> <span>Logout</span>
        </div>

        {/* Sidebar Bottom Logo */}
        <div className="sidebar-bottom-logo" style={{
          display: "flex",
          justifyContent: isCollapsed ? "center" : "flex-start",
          alignItems: "center",
          padding: isCollapsed ? "16px 0 0 0" : "16px 12px 0 12px",
          marginTop: "auto",
          borderTop: "1px solid rgba(255, 255, 255, 0.1)",
          gap: "12px",
          width: "100%"
        }}>
          <img src="/logoat.png" alt="Bottom Logo" style={{ width: "40px", height: "40px", objectFit: "contain", opacity: 0.95 }} />
          {!isCollapsed && (
            <div className="bottom-logo-text-container" style={{ display: "flex", flexDirection: "column", minWidth: 0 }}>
              <span style={{
                fontSize: "14px",
                fontWeight: "700",
                color: "#ffffff",
                letterSpacing: "0.5px",
                lineHeight: "1.3"
              }}>
                Athirath Holding
              </span>
              <span style={{
                fontSize: "11px",
                fontWeight: "500",
                color: "rgba(255, 255, 255, 0.6)",
                letterSpacing: "0.3px",
                lineHeight: "1.2"
              }}>
                India Limited
              </span>
            </div>
          )}
        </div>
      </div>
    </>
  );
};

export default Sidebar;