import React, { useState } from "react";
import {
  Search,
  Bell,
  Plus,
  Download,
  Filter,
  ArrowUpDown,
  Briefcase,
  CircleCheck,
  Clock3,
  FolderOpen,
  MoreVertical,
  X,
  Edit,
  Trash2,
  Copy,
  Archive,
  Menu,
  ChevronRight
} from "lucide-react";
import Sidebar from "../Sidebar";
import Header from "../Header"; // <--- Imported Header component
import AlertModal from "../AlertModal";
import "../../styles/projects.css";

const Projects = ({ userRole, onLogout }) => {
  const [activeTab, setActiveTab] = useState("All Projects");
  const [searchQuery, setSearchQuery] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [showModal, setShowModal] = useState(false);
  const [showFilterDropdown, setShowFilterDropdown] = useState(false);
  const [showSortDropdown, setShowSortDropdown] = useState(false);
  const [openMenuId, setOpenMenuId] = useState(null);
  const itemsPerPage = 5;

  const [alertConfig, setAlertConfig] = useState({
    isOpen: false,
    type: "info",
    title: "",
    message: ""
  });

  const triggerAlert = (type, title, message) => {
    setAlertConfig({ isOpen: true, type, title, message });
  };

  const projects = [
    { id: 1, name: "ERP Management System", client: "Infosys Technologies", status: "In Progress", progress: 72, startDate: "2026-06-02", dueDate: "2026-07-20", priority: "High", category: "My Projects", description: "Enterprise resource planning system integration" },
    { id: 2, name: "HR Portal Development", client: "TCS Global", status: "Completed", progress: 100, startDate: "2026-04-15", dueDate: "2026-06-10", priority: "Medium", category: "Completed", description: "Human resources management portal" },
    { id: 3, name: "E-Commerce Platform", client: "Amazon India", status: "Planning", progress: 25, startDate: "2026-07-01", dueDate: "2026-08-30", priority: "High", category: "My Projects", description: "Full-featured e-commerce website" },
    { id: 4, name: "CRM System Upgrade", client: "Wipro Solutions", status: "On Hold", progress: 45, startDate: "2026-05-18", dueDate: "2026-08-15", priority: "Low", category: "On Hold", description: "Customer relationship management upgrade" },
    { id: 5, name: "Cloud Migration", client: "AWS Cloud", status: "In Progress", progress: 67, startDate: "2026-06-15", dueDate: "2026-09-15", priority: "High", category: "My Projects", description: "Migrating infrastructure to cloud" }
  ];

  const stats = [
    { title: "Total Projects", value: projects.length, icon: FolderOpen, class: "total" },
    { title: "In Progress", value: projects.filter(p => p.status === "In Progress").length, icon: Clock3, class: "progress" },
    { title: "Completed", value: projects.filter(p => p.status === "Completed").length, icon: CircleCheck, class: "completed" },
    { title: "On Hold", value: projects.filter(p => p.status === "On Hold").length, icon: Briefcase, class: "hold" }
  ];

  const tabs = ["All Projects", "My Projects", "Participating", "Completed", "On Hold", "Planning"];

  const filteredProjects = projects.filter(project => {
    const matchesTab = activeTab === "All Projects" || project.category === activeTab || project.status === activeTab;
    const matchesSearch = project.name.toLowerCase().includes(searchQuery.toLowerCase()) || project.client.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesTab && matchesSearch;
  });

  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentProjects = filteredProjects.slice(indexOfFirstItem, indexOfLastItem);
  const totalPages = Math.ceil(filteredProjects.length / itemsPerPage);

  return (
    <div className="pjs-shell-container">
      {/* Sidebar Component */}
      <Sidebar userRole={userRole} onLogout={onLogout} />

      {/* Main Container Layout */}
      <div className="pjs-shell">
        
        {/* ======================= DYNAMIC HEADER ======================= */}
        <Header 
          title="All Projects" 
          showSearch={false} 
          userName="Syed Mohammad Johny Basha" 
          userRole="Web Developer" 
          initials="SB" 
        />

        <main className="pjs-main">
          <div className="pjs-breadcrumb">
            <span>Home</span> <ChevronRight size={12} />
            <span>Dashboard</span> <ChevronRight size={12} />
            <strong>Projects</strong>
          </div>

          <div className="pjs-content">
            {/* ===== SECTION 1: STATISTICS CARDS ===== */}
            <div className="pjs-stats-grid">
              {stats.map((item, index) => {
                const Icon = item.icon;
                return (
                  <div className={`pjs-stat-card ${item.class}`} key={index}>
                    <div className="stat-info">
                      <p>{item.title}</p>
                      <h3>{item.value}</h3>
                    </div>
                    <div className="stat-icon">
                      <Icon size={20} />
                    </div>
                  </div>
                );
              })}
            </div>

            {/* ===== SECTION 2: SINGLE-LINE INTEGRATED TOOLBAR PANEL ===== */}
            <div className="pjs-panel pjs-integrated-toolbar">
              <div className="pjs-toolbar-left-side">
                {/* Tabs Row */}
                <div className="pjs-tabs-group">
                  {tabs.map((tab) => (
                    <button
                      key={tab}
                      className={activeTab === tab ? "pjs-tab active" : "pjs-tab"}
                      onClick={() => { setActiveTab(tab); setCurrentPage(1); }}
                    >
                      {tab}
                    </button>
                  ))}
                </div>

                {/* Vertical Divider */}
                <div className="pjs-toolbar-divider"></div>

                {/* Filter Actions right after Planning tab */}
                <div className="pjs-actions-group">
                  <div className="pjs-dropdown-wrap">
                    <button className="pjs-action-btn-sm" onClick={() => setShowFilterDropdown(!showFilterDropdown)}>
                      <Filter size={14} /> Filter
                    </button>
                    {showFilterDropdown && (
                      <div className="pjs-dropdown-menu">
                        <button onClick={() => setShowFilterDropdown(false)}>High Priority</button>
                        <button onClick={() => setShowFilterDropdown(false)}>Medium Priority</button>
                        <button onClick={() => setShowFilterDropdown(false)}>Low Priority</button>
                      </div>
                    )}
                  </div>

                  <div className="pjs-dropdown-wrap">
                    <button className="pjs-action-btn-sm" onClick={() => setShowSortDropdown(!showSortDropdown)}>
                      <ArrowUpDown size={14} /> Sort
                    </button>
                    {showSortDropdown && (
                      <div className="pjs-dropdown-menu">
                        <button onClick={() => setShowSortDropdown(false)}>Name A-Z</button>
                        <button onClick={() => setShowSortDropdown(false)}>Date (Newest)</button>
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* Search Bar perfectly aligned on the right end */}
              <div className="pjs-search-box">
                <Search size={14} className="pjs-search-icon" />
                <input
                  type="text"
                  placeholder="Search project or client..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
                {searchQuery && <X size={14} className="pjs-search-clear" onClick={() => setSearchQuery("")} />}
              </div>
            </div>

            {/* ===== SECTION 3: DATA LIST TABLE ===== */}
            <section className="pjs-panel">
              <div className="pjs-table-wrap">
                <table className="pjs-data-table">
                  <thead>
                    <tr>
                      <th>Project Name</th>
                      <th>Client Name</th>
                      <th>Status</th>
                      <th>Progress</th>
                      <th>Start Date</th>
                      <th>Due Date</th>
                      <th>Priority</th>
                      <th style={{ width: "80px", textAlign: "center" }}>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {currentProjects.map((project) => (
                      <tr key={project.id}>
                        <td style={{ fontWeight: 600, color: "#1e293b" }}>{project.name}</td>
                        <td>{project.client}</td>
                        <td>
                          <span className={`pjs-status-badge status-${project.status.toLowerCase().replace(" ", "")}`}>
                            {project.status}
                          </span>
                        </td>
                        <td>
                          <div className="pjs-progress-wrapper">
                            <div className="pjs-progress-bar">
                              <div className="pjs-progress-fill" style={{ width: `${project.progress}%` }}></div>
                            </div>
                            <span className="pjs-progress-text">{project.progress}%</span>
                          </div>
                        </td>
                        <td>{project.startDate}</td>
                        <td>{project.dueDate}</td>
                        <td>
                          <span className={`pjs-status-badge prio-${project.priority.toLowerCase()}`}>
                            {project.priority}
                          </span>
                        </td>
                        <td>
                          <div className="pjs-action-menu-container">
                            <button className="pjs-dot-btn" onClick={() => setOpenMenuId(openMenuId === project.id ? null : project.id)}>
                              <MoreVertical size={14} />
                            </button>
                            {openMenuId === project.id && (
                              <div className="pjs-action-dropdown">
                                <button onClick={() => setOpenMenuId(null)}><Edit size={12} /> Edit</button>
                                <button onClick={() => setOpenMenuId(null)}><Copy size={12} /> Duplicate</button>
                                <button onClick={() => setOpenMenuId(null)}><Archive size={12} /> Archive</button>
                                <button className="delete" onClick={() => setOpenMenuId(null)}><Trash2 size={12} /> Delete</button>
                              </div>
                            )}
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Pagination controls */}
              {filteredProjects.length > 0 && (
                <div className="pjs-pagination">
                  <button onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))} disabled={currentPage === 1}>Previous</button>
                  <div className="pjs-page-numbers">
                    {[...Array(totalPages)].map((_, i) => (
                      <button key={i} className={currentPage === i + 1 ? "active" : ""} onClick={() => setCurrentPage(i + 1)}>{i + 1}</button>
                    ))}
                  </div>
                  <button onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))} disabled={currentPage === totalPages}>Next</button>
                </div>
              )}
            </section>
          </div>
        </main>

        {/* ===== FIXED FOOTER ACTIONS BAR ===== */}
        <div className="pjs-footer">
          <button type="button" className="pjs-btn secondary" onClick={() => setSearchQuery("")}>Clear Search</button>
          <button type="button" className="pjs-btn tertiary" onClick={() => triggerAlert("success", "Export Report", "Exporting report...")}><Download size={14} /> Export Report</button>
          <button type="button" className="pjs-btn primary" onClick={() => setShowModal(true)}><Plus size={14} /> Create New Project</button>
        </div>

        {/* Modal Window popup */}
        {showModal && (
          <div className="pjs-modal-overlay" onClick={() => setShowModal(false)}>
            <div className="pjs-modal" onClick={(e) => e.stopPropagation()}>
              <div className="pjs-modal-header">
                <h3>Create New Project</h3>
                <button className="pjs-modal-close" onClick={() => setShowModal(false)}><X size={18} /></button>
              </div>
              <div className="pjs-modal-body">
                <div className="pjs-form-group">
                  <label>Project Name *</label>
                  <input type="text" placeholder="Enter project name" />
                </div>
                <div className="pjs-form-group">
                  <label>Client Name *</label>
                  <input type="text" placeholder="Enter client name" />
                </div>
                <div className="pjs-form-row">
                  <div className="pjs-form-group">
                    <label>Start Date</label>
                    <input type="date" />
                  </div>
                  <div className="pjs-form-group">
                    <label>Due Date</label>
                    <input type="date" />
                  </div>
                </div>
              </div>
              <div className="pjs-modal-footer">
                <button className="pjs-btn secondary" onClick={() => setShowModal(false)}>Cancel</button>
                <button className="pjs-btn primary" onClick={() => setShowModal(false)}>Create Project</button>
              </div>
            </div>
          </div>
        )}

        <AlertModal
          isOpen={alertConfig.isOpen}
          type={alertConfig.type}
          title={alertConfig.title}
          message={alertConfig.message}
          onClose={() => setAlertConfig(prev => ({ ...prev, isOpen: false }))}
        />
      </div>
    </div>
  );
};

export default Projects;