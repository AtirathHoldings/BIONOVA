import { useNavigate, useLocation } from "react-router-dom";
import { House, Building, Flag, Users, Calendar, Settings, Factory, MapPinned, FolderPlus } from "lucide-react";
import "../styles/sidebar.css";

const Sidebar = ({ onLogout }) => {
  const navigate = useNavigate();
  const location = useLocation();

  // Combined all menus into one array for complete access
  const allMenus = [
    { name: "Dashboard", icon: House, path: "/dashboard" },
    { name: "Company Creation", icon: Building, path: "/company-creation" },
    { name: "Plant Creation", icon: Factory, path: "/plant-creation" },
    { name: "Land Allocation", icon: MapPinned, path: "/agriland-allocation" },
    { name: "Project Creation", icon: FolderPlus, path: "/project-creation" },
    { name: "Milestone Creation", icon: Flag, path: "/milestone-creation" },
    { name: "Employee Creation", icon: Users, path: "/employee-creation" },
    { name: "Department Creation", icon: Building, path: "/department-creation" },
    { name: "All Projects", icon: Building, path: "/projects" },
    { name: "Calendar", icon: Calendar, path: "/calendar" },
    { name: "Settings", icon: Settings, path: "/settings" }
  ];

  return (
    <div className="sidebar">
      {/* Logo Section */}
      <div className="logo-section">
        <img src="/icon2.png" alt="Logo" className="company-logo" />
        <div className="company-text">
          <h3>Atirath</h3>
          <span>Holdings India Limited</span>
        </div>
      </div>
      
      {/* Consolidated Menu List */}
      <ul className="menu-list">
        {allMenus.map((m, i) => (
          <li 
            key={i} 
            onClick={() => navigate(m.path)} 
            className={location.pathname === m.path ? "active" : ""}
          >
            <m.icon size={20} /> <span>{m.name}</span>
          </li>
        ))}
      </ul>
      
      {/* Logout Button */}
      <div className="logout-button" onClick={onLogout}>
        Logout
      </div>
    </div>
  );
};

export default Sidebar;