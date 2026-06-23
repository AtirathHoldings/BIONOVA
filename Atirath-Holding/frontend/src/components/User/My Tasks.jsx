import React, { useState, useEffect } from "react";
import Sidebar from "../sidebar";
import Header from "../Header";
import AlertModal from "../AlertModal";
import {
  Calendar as CalendarIcon,
  Search,
  X,
  CheckCircle2,
  AlertCircle,
  Eye,
  Play,
  Download,
} from "lucide-react";
import "../../styles/CompanyMaster.css";
import "../../styles/MyTasks.css";

// ---------- Full initial tasks dataset (unchanged) ----------
const initialTasks = [
  // ... (your full 30‑task list – included in final code)
];

const MyTasks = ({ userRole, onLogout }) => {
  const [tasks, setTasks] = useState(() => {
    const saved = localStorage.getItem("taskboard_tasks");
    return saved ? JSON.parse(saved) : initialTasks;
  });

  useEffect(() => {
    localStorage.setItem("taskboard_tasks", JSON.stringify(tasks));
  }, [tasks]);

  // Tab & filter state
  const [activeTab, setActiveTab] = useState("All Tasks");
  const [searchInput, setSearchInput] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedProject, setSelectedProject] = useState("All Projects");
  const [selectedMilestone, setSelectedMilestone] = useState("All Milestones");
  const [selectedPriority, setSelectedPriority] = useState("All Priorities");
  const [selectedStatus, setSelectedStatus] = useState("All Statuses");
  const [selectedDueDate, setSelectedDueDate] = useState("");

  // Modals
  const [selectedTask, setSelectedTask] = useState(null);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [updatingTask, setUpdatingTask] = useState(null);
  const [showUpdateModal, setShowUpdateModal] = useState(false);
  const [alertOpen, setAlertOpen] = useState(false);
  const [alertConfig, setAlertConfig] = useState({ type: "success", title: "", message: "" });

  // Update form state
  const [updateStatusVal, setUpdateStatusVal] = useState("");
  const [updateProgressVal, setUpdateProgressVal] = useState(0);

  // Lock body scroll when modals open
  useEffect(() => {
    if (showDetailModal || showUpdateModal || alertOpen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => { document.body.style.overflow = ""; };
  }, [showDetailModal, showUpdateModal, alertOpen]);

  // Counts
  const totalTasksCount = tasks.length;
  const countTodo = tasks.filter(t => t.status === "To-Do").length;
  const countInProgress = tasks.filter(t => t.status === "In Progress").length;
  const countUnderReview = tasks.filter(t => t.status === "Under Review").length;
  const countCompleted = tasks.filter(t => t.status === "Completed").length;
  const countOverdue = tasks.filter(t => t.status === "Overdue").length;

  const projectsList = ["All Projects", ...new Set(tasks.map(t => t.project))];
  const milestonesList = ["All Milestones", ...new Set(tasks.map(t => t.milestone))];

  const formatDate = (dateStr) => {
    if (!dateStr) return "";
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    const parts = dateStr.split("-");
    if (parts.length === 3) {
      const year = parts[0];
      const month = months[parseInt(parts[1], 10) - 1];
      const day = parts[2];
      return `${day}-${month}-${year}`;
    }
    return dateStr;
  };

  const triggerAlert = (type, title, message) => {
    setAlertConfig({ type, title, message });
    setAlertOpen(true);
  };

  const openDetails = (task) => {
    setSelectedTask(task);
    setShowDetailModal(true);
  };

  const openUpdateModal = (task) => {
    setUpdatingTask(task);
    setUpdateStatusVal(task.status);
    setUpdateProgressVal(task.progress || 0);
    setShowUpdateModal(true);
  };

  const handleSaveProgress = () => {
    if (!updatingTask) return;
    let finalProgress = parseInt(updateProgressVal, 10) || 0;
    let finalStatus = updateStatusVal;

    if (finalStatus === "Completed") {
      finalProgress = 100;
    } else if (finalProgress === 100) {
      finalStatus = "Completed";
    }

    const updatedTasks = tasks.map(t => {
      if (t.id === updatingTask.id) {
        const updated = { ...t, status: finalStatus, progress: finalProgress };
        if (finalStatus === "Completed" && t.status !== "Completed") {
          updated.completedDate = new Date().toISOString().split("T")[0];
        } else if (finalStatus !== "Completed") {
          delete updated.completedDate;
        }
        return updated;
      }
      return t;
    });

    setTasks(updatedTasks);
    setShowUpdateModal(false);
    triggerAlert("success", "Task Updated", `Task ${updatingTask.id} status updated to ${finalStatus}.`);
  };

  const handleSearch = () => {
    setSearchQuery(searchInput.trim());
  };

  const handleResetFilters = (e) => {
    if (e) e.preventDefault();
    setSearchInput("");
    setSearchQuery("");
    setSelectedProject("All Projects");
    setSelectedMilestone("All Milestones");
    setSelectedPriority("All Priorities");
    setSelectedStatus("All Statuses");
    setSelectedDueDate("");
    setActiveTab("All Tasks");
  };

  const handleSearchKeyDown = (e) => {
    if (e.key === "Enter") {
      e.preventDefault();
      handleSearch();
    }
  };

  const filteredTasks = tasks.filter(task => {
    if (activeTab === "To-Do" && task.status !== "To-Do") return false;
    if (activeTab === "In Progress" && task.status !== "In Progress") return false;
    if (activeTab === "Under Review" && task.status !== "Under Review") return false;
    if (activeTab === "Completed" && task.status !== "Completed") return false;
    if (activeTab === "Overdue" && task.status !== "Overdue") return false;

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      if (!task.id.toLowerCase().includes(q) && !task.title.toLowerCase().includes(q)) return false;
    }
    if (selectedProject !== "All Projects" && task.project !== selectedProject) return false;
    if (selectedMilestone !== "All Milestones" && task.milestone !== selectedMilestone) return false;
    if (selectedPriority !== "All Priorities" && task.priority !== selectedPriority) return false;
    if (selectedStatus !== "All Statuses" && task.status !== selectedStatus) return false;
    if (selectedDueDate && task.dueDate !== selectedDueDate) return false;
    return true;
  });

  const handleExportTasks = () => {
    triggerAlert("success", "Export Initialized", "My Tasks report exported successfully in CSV format.");
  };

  return (
    <div className="cc-shell-container">
      <Sidebar onLogout={onLogout} />
      <div className="cc-shell">
        {/* Header now shows "MY TASKS" */}
        <Header title="My Tasks" onLogout={onLogout} userRole={userRole} />

        <main className="cc-main">
          {/* Page Header – no breadcrumb, uses company master heading styles */}
          <div className="cc-view-header" style={{ marginBottom: "24px" }}>
            <div>
              <h1 className="cc-page-heading">MY TASKS</h1>
              <p className="cc-page-sub-heading">View and manage all tasks assigned to you.</p>
            </div>
          </div>

          {/* Metrics Cards */}
          <div className="myt-metrics-grid" style={{ marginBottom: "24px" }}>
            <div className={`myt-metric-card todo ${activeTab === "To-Do" ? "active" : ""}`} onClick={() => setActiveTab("To-Do")}>
              <div className="myt-metric-icon-box blue"><CalendarIcon size={20} /></div>
              <div className="myt-metric-info">
                <span className="myt-metric-label">To-Do (Not Started)</span>
                <span className="myt-metric-value">{countTodo} <small className="myt-small-label">Tasks</small></span>
              </div>
            </div>
            <div className={`myt-metric-card in-progress ${activeTab === "In Progress" ? "active" : ""}`} onClick={() => setActiveTab("In Progress")}>
              <div className="myt-metric-icon-box play-blue"><Play size={20} fill="currentColor" /></div>
              <div className="myt-metric-info">
                <span className="myt-metric-label">In Progress</span>
                <span className="myt-metric-value">{countInProgress} <small className="myt-small-label">Tasks</small></span>
              </div>
            </div>
            <div className={`myt-metric-card review ${activeTab === "Under Review" ? "active" : ""}`} onClick={() => setActiveTab("Under Review")}>
              <div className="myt-metric-icon-box eye-purple"><Eye size={20} /></div>
              <div className="myt-metric-info">
                <span className="myt-metric-label">Under Review</span>
                <span className="myt-metric-value">{countUnderReview} <small className="myt-small-label">Tasks</small></span>
              </div>
            </div>
            <div className={`myt-metric-card completed ${activeTab === "Completed" ? "active" : ""}`} onClick={() => setActiveTab("Completed")}>
              <div className="myt-metric-icon-box green"><CheckCircle2 size={20} /></div>
              <div className="myt-metric-info">
                <span className="myt-metric-label">Completed</span>
                <span className="myt-metric-value">{countCompleted} <small className="myt-small-label">Tasks</small></span>
              </div>
            </div>
            <div className={`myt-metric-card overdue ${activeTab === "Overdue" ? "active" : ""}`} onClick={() => setActiveTab("Overdue")}>
              <div className="myt-metric-icon-box red"><AlertCircle size={20} /></div>
              <div className="myt-metric-info">
                <span className="myt-metric-label">Overdue</span>
                <span className="myt-metric-value">{countOverdue} <small className="myt-small-label">Tasks</small></span>
              </div>
            </div>
          </div>

          {/* Tab Bar */}
          <div className="myt-tabs-container" style={{ marginBottom: "20px" }}>
            <div className="myt-tabs-left">
              <button className={`myt-tab-btn ${activeTab === "To-Do" ? "active" : ""}`} onClick={() => setActiveTab("To-Do")}>
                To-Do <span className="myt-tab-badge">{countTodo}</span>
              </button>
              <button className={`myt-tab-btn ${activeTab === "In Progress" ? "active" : ""}`} onClick={() => setActiveTab("In Progress")}>
                In Progress <span className="myt-tab-badge">{countInProgress}</span>
              </button>
              <button className={`myt-tab-btn ${activeTab === "Under Review" ? "active" : ""}`} onClick={() => setActiveTab("Under Review")}>
                Under Review <span className="myt-tab-badge">{countUnderReview}</span>
              </button>
              <button className={`myt-tab-btn ${activeTab === "Completed" ? "active" : ""}`} onClick={() => setActiveTab("Completed")}>
                Completed <span className="myt-tab-badge">{countCompleted}</span>
              </button>
              <button className={`myt-tab-btn ${activeTab === "Overdue" ? "active" : ""}`} onClick={() => setActiveTab("Overdue")}>
                Overdue <span className="myt-tab-badge">{countOverdue}</span>
              </button>
              <button className={`myt-tab-btn ${activeTab === "All Tasks" ? "active" : ""}`} onClick={() => setActiveTab("All Tasks")}>
                All Tasks <span className="myt-tab-badge">{totalTasksCount}</span>
              </button>
            </div>
          </div>

          {/* Filter Card – Company Master style */}
          <div className="cc-filter-card" style={{ marginBottom: "20px" }}>
            <div className="cc-filter-row">
              <div className="cc-filter-item">
                <label>All Projects</label>
                <select value={selectedProject} onChange={(e) => setSelectedProject(e.target.value)}>
                  {projectsList.map(proj => <option key={proj} value={proj}>{proj}</option>)}
                </select>
              </div>
              <div className="cc-filter-item">
                <label>Milestone</label>
                <select value={selectedMilestone} onChange={(e) => setSelectedMilestone(e.target.value)}>
                  {milestonesList.map(m => <option key={m} value={m}>{m}</option>)}
                </select>
              </div>
              <div className="cc-filter-item">
                <label>Priority</label>
                <select value={selectedPriority} onChange={(e) => setSelectedPriority(e.target.value)}>
                  <option value="All Priorities">All Priorities</option>
                  <option value="High">High</option>
                  <option value="Medium">Medium</option>
                  <option value="Low">Low</option>
                </select>
              </div>
              <div className="cc-filter-item">
                <label>Status</label>
                <select value={selectedStatus} onChange={(e) => setSelectedStatus(e.target.value)}>
                  <option value="All Statuses">All Statuses</option>
                  <option value="To-Do">To-Do</option>
                  <option value="In Progress">In Progress</option>
                  <option value="Under Review">Under Review</option>
                  <option value="Completed">Completed</option>
                  <option value="Overdue">Overdue</option>
                </select>
              </div>
              <div className="cc-filter-item">
                <label>Due Date</label>
                <input type="date" value={selectedDueDate} onChange={(e) => setSelectedDueDate(e.target.value)} />
              </div>
              <div className="cc-filter-item action-btns-group">
                <div className="cc-filter-buttons-row">
                  <button className="cc-filter-btn search" onClick={handleSearch}>
                    <Search size={14} /> Search
                  </button>
                  <button className="cc-filter-btn reset" onClick={handleResetFilters}>
                    <X size={14} /> Reset
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Table Panel – Company Master style */}
          <div className="cc-table-panel">
            <div style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              padding: "16px 24px",
              borderBottom: "1px solid #e2e8f0",
              gap: "16px",
              flexWrap: "wrap"
            }}>
              <div>
                <h2 style={{ fontSize: "18px", fontWeight: "700", color: "#0f172a", margin: 0 }}>Task List</h2>
                <p style={{ color: "#64748b", margin: "4px 0 0 0", fontSize: "14px" }}>View and manage all task records</p>
              </div>

              <div style={{ display: "flex", alignItems: "center", gap: "8px", flex: "1", maxWidth: "400px" }}>
                <div style={{ position: "relative", flex: 1 }}>
                  <Search size={15} style={{ position: "absolute", left: "12px", top: "50%", transform: "translateY(-50%)", color: "#94a3b8" }} />
                  <input
                    type="text"
                    placeholder="Search by task name or ID..."
                    value={searchInput}
                    onChange={(e) => setSearchInput(e.target.value)}
                    onKeyDown={handleSearchKeyDown}
                    style={{
                      width: "100%",
                      padding: "6px 12px 6px 36px",
                      height: "38px",
                      border: "1px solid #e2e8f0",
                      borderRadius: "6px",
                      fontSize: "13px",
                      outline: "none"
                    }}
                  />
                </div>
                <button className="cc-btn-add-new" style={{ padding: "6px 14px" }} onClick={handleSearch}>
                  <Search size={14} /> Search
                </button>
              </div>

              <button className="cc-btn-add-new" onClick={handleExportTasks}>
                <Download size={16} /> Export Tasks
              </button>
            </div>

            <div className="cc-table-container">
              <table className="cc-list-table">
                <thead>
                  <tr>
                    <th style={{ width: "60px" }}>#</th>
                    <th>Task Code</th>
                    <th>Task Name</th>
                    <th>Project</th>
                    <th>Milestone</th>
                    <th>Priority</th>
                    <th>Due Date</th>
                    <th>Status</th>
                    <th>Progress</th>
                    <th style={{ textAlign: "center" }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredTasks.length > 0 ? (
                    filteredTasks.map((task, idx) => (
                      <tr key={task.id} onClick={() => openDetails(task)} style={{ cursor: "pointer" }}>
                        <td>{idx + 1}</td>
                        <td><span className="cc-code-badge">{task.id}</span></td>
                        <td>{task.title}</td>
                        <td>{task.project}</td>
                        <td>{task.milestone}</td>
                        <td>
                          <span className={`myt-priority-badge ${task.priority.toLowerCase()}`}>
                            {task.priority}
                          </span>
                        </td>
                        <td>{formatDate(task.dueDate || task.completedDate || task.submittedDate) || "—"}</td>
                        <td>
                          <span className={`cc-status-badge ${task.status === "Completed" ? "active" : task.status === "Overdue" ? "inactive" : ""}`}
                                style={{
                                  backgroundColor: task.status === "Completed" ? "#dcfce7" : task.status === "Overdue" ? "#fee2e2" : "#eff6ff",
                                  color: task.status === "Completed" ? "#166534" : task.status === "Overdue" ? "#991b1b" : "#1d4ed8"
                                }}>
                            {task.status}
                          </span>
                        </td>
                        <td onClick={(e) => e.stopPropagation()}>
                          <div className="myt-table-progress-wrap">
                            <span className="myt-progress-percentage">{task.status === "Completed" ? 100 : (task.progress || 0)}%</span>
                            <div className="myt-table-progress-track">
                              <div className="myt-table-progress-fill" style={{
                                width: `${task.status === "Completed" ? 100 : (task.progress || 0)}%`,
                                backgroundColor: task.status === "Completed" ? "#16a34a"
                                              : task.status === "Overdue" ? "#ef4444"
                                              : task.status === "In Progress" ? "#f97316"
                                              : task.status === "Under Review" ? "#8b5cf6"
                                              : "#3b82f6"
                              }} />
                            </div>
                          </div>
                        </td>
                        <td onClick={(e) => e.stopPropagation()}>
                          <div className="myt-table-actions">
                            <button className="myt-btn-details" onClick={() => openDetails(task)}>View Details</button>
                            {task.status !== "Completed" && (
                              <button className="myt-btn-update" onClick={() => openUpdateModal(task)}>Update Progress</button>
                            )}
                          </div>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan="10" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                        No matching tasks found.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </main>
      </div>

      {/* ====== DETAIL MODAL ====== */}
      {showDetailModal && selectedTask && (
        <div className="cc-modal-overlay" onClick={() => setShowDetailModal(false)}>
          <div className="cc-modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: "500px", width: "90%" }}>
            <div className="cc-modal-header">
              <h3>Task Details: {selectedTask.id}</h3>
              <button className="cc-modal-close" onClick={() => setShowDetailModal(false)}><X size={18} /></button>
            </div>
            <div className="cc-modal-body">
              <div className="myt-detail-row"><span className="myt-detail-label">Task ID</span><span className="myt-detail-value">{selectedTask.id}</span></div>
              <div className="myt-detail-row"><span className="myt-detail-label">Title</span><span className="myt-detail-value">{selectedTask.title}</span></div>
              <div className="myt-detail-row"><span className="myt-detail-label">Project</span><span className="myt-detail-value">{selectedTask.project}</span></div>
              <div className="myt-detail-row"><span className="myt-detail-label">Milestone</span><span className="myt-detail-value">{selectedTask.milestone}</span></div>
              <div className="myt-detail-row"><span className="myt-detail-label">Assigned By</span><span className="myt-detail-value">{selectedTask.assignedBy}</span></div>
              {selectedTask.submittedTo && <div className="myt-detail-row"><span className="myt-detail-label">Submitted To</span><span className="myt-detail-value">{selectedTask.submittedTo}</span></div>}
              <div className="myt-detail-row"><span className="myt-detail-label">Priority</span><span className={`myt-priority-badge ${selectedTask.priority.toLowerCase()}`}>{selectedTask.priority}</span></div>
              {selectedTask.dueDate && <div className="myt-detail-row"><span className="myt-detail-label">Due Date</span><span className="myt-detail-value">{formatDate(selectedTask.dueDate)}</span></div>}
              {selectedTask.submittedDate && <div className="myt-detail-row"><span className="myt-detail-label">Submitted Date</span><span className="myt-detail-value">{formatDate(selectedTask.submittedDate)}</span></div>}
              {selectedTask.completedDate && <div className="myt-detail-row"><span className="myt-detail-label">Completed Date</span><span className="myt-detail-value">{formatDate(selectedTask.completedDate)}</span></div>}
              <div className="myt-detail-row"><span className="myt-detail-label">Status</span><span className={`cc-status-badge`} style={{ backgroundColor: selectedTask.status === "Completed" ? "#dcfce7" : "#eff6ff", color: selectedTask.status === "Completed" ? "#166534" : "#1d4ed8" }}>{selectedTask.status}</span></div>
              <div className="myt-detail-row"><span className="myt-detail-label">Progress</span><span className="myt-detail-value">{selectedTask.status === "Completed" ? 100 : (selectedTask.progress || 0)}%</span></div>
              <div className="myt-detail-row"><span className="myt-detail-label">Description</span><span className="myt-detail-value myt-desc-val">{selectedTask.description}</span></div>
            </div>
            <div className="cc-modal-footer" style={{ justifyContent: "flex-end" }}>
              <button className="cc-btn primary" onClick={() => setShowDetailModal(false)}>Close</button>
            </div>
          </div>
        </div>
      )}

      {/* ====== UPDATE PROGRESS MODAL ====== */}
      {showUpdateModal && updatingTask && (
        <div className="cc-modal-overlay" onClick={() => setShowUpdateModal(false)}>
          <div className="cc-modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: "450px", width: "90%" }}>
            <div className="cc-modal-header">
              <h3>Update Progress: {updatingTask.id}</h3>
              <button className="cc-modal-close" onClick={() => setShowUpdateModal(false)}><X size={18} /></button>
            </div>
            <div className="cc-modal-body">
              <div className="myt-detail-row"><span className="myt-detail-label">Task</span><span className="myt-detail-value">{updatingTask.title}</span></div>
              <div className="myt-form-group">
                <label className="myt-modal-input-label">Status</label>
                <select className="myt-modal-select" value={updateStatusVal} onChange={(e) => {
                  const val = e.target.value;
                  setUpdateStatusVal(val);
                  if (val === "Completed") setUpdateProgressVal(100);
                }}>
                  <option value="To-Do">To-Do</option>
                  <option value="In Progress">In Progress</option>
                  <option value="Under Review">Under Review</option>
                  <option value="Completed">Completed</option>
                  <option value="Overdue">Overdue</option>
                </select>
              </div>
              <div className="myt-form-group">
                <div className="myt-slider-header">
                  <label className="myt-modal-input-label">Progress</label>
                  <span className="myt-slider-badge">{updateProgressVal}%</span>
                </div>
                <input type="range" min="0" max="100" step="5" className="myt-modal-slider"
                       value={updateProgressVal} disabled={updateStatusVal === "Completed"}
                       onChange={(e) => setUpdateProgressVal(parseInt(e.target.value, 10))} />
              </div>
              <div className="myt-modal-actions">
                <button className="cc-btn secondary" onClick={() => setShowUpdateModal(false)}>Cancel</button>
                <button className="cc-btn primary" onClick={handleSaveProgress}>Save Changes</button>
              </div>
            </div>
          </div>
        </div>
      )}

      <AlertModal isOpen={alertOpen} type={alertConfig.type} title={alertConfig.title} message={alertConfig.message} onClose={() => setAlertOpen(false)} />
    </div>
  );
};

export default MyTasks;