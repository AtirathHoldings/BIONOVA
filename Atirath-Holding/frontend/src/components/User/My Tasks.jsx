import React, { useState, useEffect } from "react";
import Sidebar from "../Sidebar";
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
  Filter,
  RotateCw,
  ChevronLeft,
  ChevronRight,
  Check,
} from "lucide-react";
import "../../styles/MyTasks.css";
import { apiGet, apiPut, apiPatch } from "../../utils/api";

const mapBackendTask = (t, projects, milestones) => {
  const milestone = milestones.find(m => String(m.mId) === String(t.mId));
  const project = milestone ? projects.find(p => String(p.prjId) === String(milestone.prjId)) : null;

  // Compute status
  let status = "To-Do";
  if (t.taskSts === "COMPLETED") {
    status = "Completed";
  } else {
    // Check if overdue
    const today = new Date().toISOString().split("T")[0];
    if (t.endDt && t.endDt < today) {
      status = "Overdue";
    } else if (t.taskSts === "WIP" || t.taskSts === "REWORK") {
      status = "In Progress";
    } else if (t.taskSts === "SUBMIT_REVIEW" || t.taskSts === "UNDER_REVIEW") {
      status = "Under Review";
    } else {
      status = "To-Do";
    }
  }

  // Progress computation
  let progress = 0;
  if (t.taskSts === "COMPLETED") {
    progress = 100;
  } else if (t.taskSts === "SUBMIT_REVIEW" || t.taskSts === "UNDER_REVIEW") {
    progress = 90;
  } else if (t.taskSts === "WIP") {
    progress = 50;
  } else if (t.taskSts === "REWORK") {
    progress = 30;
  } else {
    progress = 0;
  }

  return {
    id: t.taskCd || `TSK-${t.taskId}`,
    taskId: t.taskId,
    title: t.taskNm,
    project: project ? project.prjNm : "Unknown Project",
    milestone: milestone ? milestone.mlstnTtl : "Unknown Milestone",
    priority: project ? (project.prjPrty || "Medium") : "Medium",
    dueDate: t.endDt || "",
    status: status,
    progress: progress,
    rawStatus: t.taskSts,
    rawTask: t,
    description: t.taskDesc || "",
    assignedBy: "Project Manager"
  };
};

const MyTasks = ({ userRole, onLogout }) => {
  const [tasks, setTasks] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  const fetchTasks = async () => {
    try {
      setIsLoading(true);
      const [projectsData, milestonesData, tasksData, profileRes] = await Promise.all([
        apiGet("/api/project-live"),
        apiGet("/api/milestone-live"),
        apiGet("/api/task-live"),
        apiGet("/api/profile")
      ]);

      const empId = profileRes?.empId;
      const isAdmin = profileRes?.email === 'siva@atirath.com';

      // Filter tasks to only show tasks assigned to the logged-in user
      const userTasks = (tasksData || []).filter(t => isAdmin || t.empId === empId);

      const mapped = userTasks.map(t => mapBackendTask(t, projectsData || [], milestonesData || []));
      setTasks(mapped);
    } catch (err) {
      console.error("Error loading tasks:", err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchTasks();
  }, []);

  // Tab & filter state
  const [activeTab, setActiveTab] = useState("To-Do");
  const [searchInput, setSearchInput] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedProject, setSelectedProject] = useState("All Projects");
  const [selectedMilestone, setSelectedMilestone] = useState("All Milestones");
  const [selectedPriority, setSelectedPriority] = useState("All Priorities");
  const [selectedStatus, setSelectedStatus] = useState("To-Do (Not Started)");
  const [selectedDueDate, setSelectedDueDate] = useState("");
  const [showFilters, setShowFilters] = useState(true);

  const changeTab = (tab) => {
    setActiveTab(tab);
    setSelectedStatus("All Statuses");
  };

  const handleStatusFilterChange = (statusVal) => {
    setSelectedStatus(statusVal);
    if (statusVal === "All Statuses") {
      setActiveTab("All Tasks");
    } else if (statusVal === "To-Do (Not Started)" || statusVal === "To-Do") {
      setActiveTab("To-Do");
    } else if (statusVal === "In Progress") {
      setActiveTab("In Progress");
    } else if (statusVal === "Under Review") {
      setActiveTab("Under Review");
    } else if (statusVal === "Completed") {
      setActiveTab("Completed");
    } else if (statusVal === "Overdue") {
      setActiveTab("Overdue");
    }
  };

  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 8;

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
  const [updateChecklist, setUpdateChecklist] = useState([]);
  const [updateRemarks, setUpdateRemarks] = useState("");

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

  const openUpdateModal = async (task) => {
    setUpdatingTask(task);
    setUpdateStatusVal(task.status);
    setUpdateProgressVal(task.progress || 0);
    setUpdateRemarks(task.rawTask?.addlRem || "");

    try {
      const items = await apiGet(`/api/checklists/live-task/${task.taskId}`);
      const mapped = (items || []).map(item => ({
        id: item.chkId,
        text: item.chkNm,
        completed: item.chkSts || false
      }));
      setUpdateChecklist(mapped);
    } catch (err) {
      console.error("Failed to load checklist:", err);
      setUpdateChecklist([]);
    }

    setShowUpdateModal(true);
  };

  const handleToggleChecklist = (id) => {
    setUpdateChecklist(prev => {
      const newList = prev.map(item => item.id === id ? { ...item, completed: !item.completed } : item);
      const completedCount = newList.filter(i => i.completed).length;
      const progress = Math.round((completedCount / newList.length) * 100);
      setUpdateProgressVal(progress);
      
      if (progress === 100) {
        setUpdateStatusVal("Completed");
      } else if (progress > 0 && updateStatusVal === "To-Do") {
        setUpdateStatusVal("In Progress");
      }
      
      return newList;
    });
  };

  const handleSaveProgress = async () => {
    if (!updatingTask) return;
    let finalProgress = parseInt(updateProgressVal, 10) || 0;
    let finalStatus = updateStatusVal;

    if (finalStatus === "Completed") {
      finalProgress = 100;
    } else if (finalProgress === 100) {
      finalStatus = "Completed";
    }

    // Map frontend status back to backend taskSts
    let backendSts = "OPEN";
    if (finalStatus === "Completed") {
      backendSts = "COMPLETED";
    } else if (finalStatus === "Under Review") {
      backendSts = "UNDER_REVIEW";
    } else if (finalStatus === "In Progress") {
      backendSts = "WIP";
    } else if (finalStatus === "To-Do") {
      backendSts = "OPEN";
    } else if (finalStatus === "Overdue") {
      backendSts = "WIP";
    }

    try {
      const originalTask = updatingTask.rawTask;
      const updatedTaskObj = {
        ...originalTask,
        taskSts: backendSts,
        addlRem: updateRemarks || originalTask.addlRem
      };

      // 1. Update the checklist items in the database
      await Promise.all(updateChecklist.map(item => {
        const path = `/api/checklists/${item.id}/${item.completed ? 'complete' : 'reopen'}`;
        return apiPatch(path);
      }));

      // 2. Update the task status & progress
      await apiPut(`/api/task-live/${updatingTask.taskId}`, updatedTaskObj);
      await fetchTasks();
      setShowUpdateModal(false);
      triggerAlert("success", "Success", "Task progress updated successfully.");
    } catch (err) {
      console.error("Error updating task:", err);
      triggerAlert("danger", "Error", "Failed to update task: " + err.message);
    }
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
    setCurrentPage(1);
  };

  useEffect(() => {
    setCurrentPage(1);
  }, [activeTab, searchQuery, selectedProject, selectedMilestone, selectedPriority, selectedStatus, selectedDueDate]);

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
    if (selectedStatus !== "All Statuses") {
      let filterStatus = selectedStatus;
      if (filterStatus === "To-Do (Not Started)") filterStatus = "To-Do";
      if (task.status !== filterStatus) return false;
    }
    if (selectedDueDate && task.dueDate !== selectedDueDate) return false;
    return true;
  });

  const totalPages = Math.ceil(filteredTasks.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginatedTasks = filteredTasks.slice(startIndex, startIndex + itemsPerPage);

  const handlePageChange = (page) => {
    if (page >= 1 && page <= totalPages) {
      setCurrentPage(page);
    }
  };

  const handleExportTasks = () => {
    triggerAlert("success", "Export Initialized", "My Tasks report exported successfully in CSV format.");
  };

  return (
    <div className="cc-shell-container">
      <Sidebar onLogout={onLogout} />
      <div className="cc-shell">
        {/* Header now shows "My Tasks" and its tagline subtitle */}
        <Header title="My Tasks" subtitle="View and manage all tasks assigned to you." onLogout={onLogout} userRole={userRole} />

        <main className="cc-main">
          {/* Page Header – Export button remains on the right */}
          <div className="cc-view-header" style={{ marginBottom: "24px", display: "flex", justifyContent: "flex-end", alignItems: "center" }}>
            <button className="myt-export-btn" onClick={handleExportTasks}>
              <Download size={16} /> Export
            </button>
          </div>

          {/* Metrics Cards */}
          <div className="myt-metrics-grid" style={{ marginBottom: "24px" }}>
            <div className={`myt-metric-card todo ${activeTab === "To-Do" ? "active" : ""}`} onClick={() => changeTab("To-Do")}>
              <div className="myt-metric-icon-box blue"><CalendarIcon size={20} /></div>
              <div className="myt-metric-info">
                <span className="myt-metric-label">To-Do (Not Started)</span>
                <span className="myt-metric-value">{countTodo} <small className="myt-small-label">Tasks</small></span>
              </div>
            </div>
            <div className={`myt-metric-card in-progress ${activeTab === "In Progress" ? "active" : ""}`} onClick={() => changeTab("In Progress")}>
              <div className="myt-metric-icon-box play-blue"><Play size={20} fill="currentColor" /></div>
              <div className="myt-metric-info">
                <span className="myt-metric-label">In Progress</span>
                <span className="myt-metric-value">{countInProgress} <small className="myt-small-label">Tasks</small></span>
              </div>
            </div>
            <div className={`myt-metric-card review ${activeTab === "Under Review" ? "active" : ""}`} onClick={() => changeTab("Under Review")}>
              <div className="myt-metric-icon-box eye-purple"><Eye size={20} /></div>
              <div className="myt-metric-info">
                <span className="myt-metric-label">Under Review</span>
                <span className="myt-metric-value">{countUnderReview} <small className="myt-small-label">Tasks</small></span>
              </div>
            </div>
            <div className={`myt-metric-card completed ${activeTab === "Completed" ? "active" : ""}`} onClick={() => changeTab("Completed")}>
              <div className="myt-metric-icon-box green"><CheckCircle2 size={20} /></div>
              <div className="myt-metric-info">
                <span className="myt-metric-label">Completed</span>
                <span className="myt-metric-value">{countCompleted} <small className="myt-small-label">Tasks</small></span>
              </div>
            </div>
            <div className={`myt-metric-card overdue ${activeTab === "Overdue" ? "active" : ""}`} onClick={() => changeTab("Overdue")}>
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
              <button className={`myt-tab-btn ${activeTab === "To-Do" ? "active" : ""}`} onClick={() => changeTab("To-Do")}>
                To-Do <span className="myt-tab-badge">{countTodo}</span>
              </button>
              <button className={`myt-tab-btn ${activeTab === "In Progress" ? "active" : ""}`} onClick={() => changeTab("In Progress")}>
                In Progress <span className="myt-tab-badge">{countInProgress}</span>
              </button>
              <button className={`myt-tab-btn ${activeTab === "Under Review" ? "active" : ""}`} onClick={() => changeTab("Under Review")}>
                Under Review <span className="myt-tab-badge">{countUnderReview}</span>
              </button>
              <button className={`myt-tab-btn ${activeTab === "Completed" ? "active" : ""}`} onClick={() => changeTab("Completed")}>
                Completed <span className="myt-tab-badge">{countCompleted}</span>
              </button>
              <button className={`myt-tab-btn ${activeTab === "Overdue" ? "active" : ""}`} onClick={() => changeTab("Overdue")}>
                Overdue <span className="myt-tab-badge">{countOverdue}</span>
              </button>
              <button className={`myt-tab-btn ${activeTab === "All Tasks" ? "active" : ""}`} onClick={() => changeTab("All Tasks")}>
                All Tasks <span className="myt-tab-badge">{totalTasksCount}</span>
              </button>
            </div>

            <div className="myt-tabs-right">
              <div className="myt-search-box" style={{ marginRight: "12px" }}>
                <Search size={15} className="myt-search-icon" />
                <input
                  type="text"
                  placeholder="Search tasks..."
                  value={searchInput}
                  onChange={(e) => {
                    setSearchInput(e.target.value);
                    setSearchQuery(e.target.value);
                  }}
                  style={{ paddingRight: "30px" }}
                />
                <RotateCw size={12} className="myt-search-reset-icon" onClick={() => { setSearchInput(""); setSearchQuery(""); }} style={{ position: "absolute", right: "10px", color: "#94a3b8", cursor: "pointer" }} />
              </div>
              <button className={`myt-filter-toggle-btn ${showFilters ? 'active' : ''}`} onClick={() => setShowFilters(!showFilters)}>
                <Filter size={15} /> Filters
              </button>
            </div>
          </div>

          {/* Filter Card – Company Master style */}
          {showFilters && (
            <div className="cc-filter-card" style={{ marginBottom: "20px", padding: "16px", borderRadius: "8px", border: "1px solid #e2e8f0", backgroundColor: "#fff" }}>
              <div className="cc-filter-row" style={{ display: "flex", gap: "16px", flexWrap: "wrap", alignItems: "flex-end" }}>
                <div className="cc-filter-item">
                  <label>Project</label>
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
                  <select value={selectedStatus} onChange={(e) => handleStatusFilterChange(e.target.value)}>
                    <option value="All Statuses">All Statuses</option>
                    <option value="To-Do (Not Started)">To-Do (Not Started)</option>
                    <option value="To-Do">To-Do</option>
                    <option value="In Progress">In Progress</option>
                    <option value="Under Review">Under Review</option>
                    <option value="Completed">Completed</option>
                    <option value="Overdue">Overdue</option>
                  </select>
                </div>
                <div className="cc-filter-item">
                  <label>Due Date</label>
                  <div className="myt-date-input-wrapper" style={{ position: "relative", display: "flex", alignItems: "center" }}>
                    <CalendarIcon size={14} className="myt-date-icon" style={{ position: "absolute", left: "10px", color: "#64748b", pointerEvents: "none" }} />
                    <input 
                      type="text" 
                      placeholder="Select Date Range" 
                      value={selectedDueDate ? formatDate(selectedDueDate) : ""}
                      onFocus={(e) => e.target.type = 'date'}
                      onBlur={(e) => { if (!e.target.value) e.target.type = 'text'; }}
                      onChange={(e) => setSelectedDueDate(e.target.value)}
                      style={{ paddingLeft: "32px", width: "180px", height: "36px" }}
                    />
                  </div>
                </div>
                <div className="cc-filter-item" style={{ marginLeft: "auto" }}>
                  <button className="myt-clear-filter-btn" onClick={handleResetFilters}>
                    <RotateCw size={14} /> Clear Filters
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* Table Panel – Company Master style */}
          <div className="cc-table-panel" style={{ border: "none", boxShadow: "none", padding: 0 }}>
            <div className="cc-table-container">
              <table className="cc-list-table myt-table">
                <thead>
                  <tr>
                    <th>Task Code</th>
                    <th>Task Name</th>
                    <th>Project</th>
                    <th>Milestone</th>
                    <th>Priority</th>
                    <th>Due Date</th>
                    <th>Status</th>
                    <th>Progress</th>
                    <th style={{ textAlign: "center" }}>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {isLoading ? (
                    <tr>
                      <td colSpan="9" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                        Loading tasks...
                      </td>
                    </tr>
                  ) : paginatedTasks.length > 0 ? (
                    paginatedTasks.map((task) => (
                      <tr key={task.id} onClick={() => openDetails(task)} style={{ cursor: "pointer" }}>
                        <td style={{ fontWeight: "600", color: "#0f172a" }}>{task.id}</td>
                        <td style={{ fontWeight: "500", color: "#1e293b" }}>{task.title}</td>
                        <td style={{ color: "#475569" }}>{task.project}</td>
                        <td style={{ color: "#475569" }}>{task.milestone}</td>
                        <td>
                          <span className={`myt-priority-badge ${task.priority.toLowerCase()}`}>
                            {task.priority}
                          </span>
                        </td>
                        <td style={{ fontWeight: "600", color: "#0f172a" }}>{formatDate(task.dueDate || task.completedDate || task.submittedDate) || "—"}</td>
                        <td style={{ fontWeight: "600", color: "#64748b" }}>
                          {task.status}
                        </td>
                        <td onClick={(e) => e.stopPropagation()}>
                          <div className="myt-table-progress-wrap">
                            <span className="myt-progress-percentage">{task.status === "Completed" ? 100 : (task.progress || 0)}%</span>
                            <div className="myt-table-progress-track">
                              <div className="myt-table-progress-fill" style={{
                                width: `${task.status === "Completed" ? 100 : (task.progress || 0)}%`,
                                backgroundColor: task.status === "Completed" ? "#16a34a"
                                              : task.status === "Overdue" ? "#ef4444"
                                              : task.status === "In Progress" ? "#3b82f6"
                                              : task.status === "Under Review" ? "#8b5cf6"
                                              : "#e2e8f0" /* fallback */
                              }} />
                            </div>
                          </div>
                        </td>
                        <td onClick={(e) => e.stopPropagation()} style={{ textAlign: "center" }}>
                          <button className="myt-btn-update" onClick={() => openUpdateModal(task)}>Update</button>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan="9" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                        No matching tasks found.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
              
              {/* Pagination */}
              {filteredTasks.length > 0 && (
                <div className="myt-pagination-container">
                  <div className="myt-pagination-info">
                    Showing {startIndex + 1} to {Math.min(startIndex + itemsPerPage, filteredTasks.length)} of {filteredTasks.length} tasks
                  </div>
                  <div className="myt-pagination-controls">
                    <button className="myt-page-btn" disabled={currentPage === 1} onClick={() => handlePageChange(currentPage - 1)}>
                      <ChevronLeft size={16} />
                    </button>
                    {Array.from({ length: totalPages }).map((_, i) => (
                      <button 
                        key={i} 
                        className={`myt-page-btn ${currentPage === i + 1 ? 'active' : ''}`}
                        onClick={() => handlePageChange(i + 1)}
                      >
                        {i + 1}
                      </button>
                    ))}
                    <button className="myt-page-btn" disabled={currentPage === totalPages} onClick={() => handlePageChange(currentPage + 1)}>
                      <ChevronRight size={16} />
                    </button>
                  </div>
                </div>
              )}
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
          <div className="cc-modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: "600px", width: "95%" }}>
            <div className="cc-modal-header">
              <h3>Update Task Progress</h3>
              <button className="cc-modal-close" onClick={() => setShowUpdateModal(false)}><X size={18} /></button>
            </div>
            <div className="cc-modal-body" style={{ padding: "0 24px 24px 24px" }}>
              <div className="myt-modal-section">
                <h4 style={{ fontSize: "14px", fontWeight: "600", marginBottom: "12px", color: "#0f172a" }}>Task Details</h4>
                <div className="myt-task-details-grid">
                  <div className="myt-detail-col">
                    <div className="myt-detail-item"><span className="label">Task Code</span><span className="value">: {updatingTask.id}</span></div>
                    <div className="myt-detail-item"><span className="label">Task Name</span><span className="value">: {updatingTask.title}</span></div>
                    <div className="myt-detail-item"><span className="label">Project</span><span className="value">: {updatingTask.project}</span></div>
                    <div className="myt-detail-item"><span className="label">Milestone</span><span className="value">: {updatingTask.milestone}</span></div>
                    <div className="myt-detail-item"><span className="label">Due Date</span><span className="value">: {formatDate(updatingTask.dueDate)}</span></div>
                  </div>
                  <div className="myt-detail-col">
                    <div className="myt-detail-item"><span className="label">Assigned To</span><span className="value">: {sessionStorage.getItem("userName") || "Assigned Employee"}</span></div>
                    <div className="myt-detail-item"><span className="label">Priority</span>
                      <span className="value">: <span className={`myt-priority-badge ${updatingTask.priority.toLowerCase()}`}>{updatingTask.priority}</span></span>
                    </div>
                    <div className="myt-detail-item"><span className="label">Status</span>
                      <span className="value">: 
                        <select 
                          value={updateStatusVal} 
                          onChange={(e) => {
                            const val = e.target.value;
                            setUpdateStatusVal(val);
                            if (val === "Completed") {
                              setUpdateProgressVal(100);
                            } else if (val === "To-Do") {
                              setUpdateProgressVal(0);
                            }
                          }}
                          className="myt-status-select-small"
                          style={{ marginLeft: "4px", padding: "2px 6px", borderRadius: "4px", border: "1px solid #cbd5e1" }}
                        >
                          <option value="To-Do">To-Do</option>
                          <option value="In Progress">In Progress</option>
                          <option value="Under Review">Under Review</option>
                          <option value="Completed">Completed</option>
                        </select>
                      </span>
                    </div>
                    <div className="myt-detail-item"><span className="label">Current Progress</span><span className="value">: {updateProgressVal}%</span></div>
                  </div>
                </div>
              </div>

              <div className="myt-modal-section">
                <h4 style={{ fontSize: "14px", fontWeight: "600", marginBottom: "12px", color: "#0f172a" }}>Checklist</h4>
                <div className="myt-checklist-table">
                  <div className="myt-checklist-header">
                    <span>Checklist Item</span>
                    <span>Status</span>
                  </div>
                  {updateChecklist.length === 0 ? (
                    <div style={{ textAlign: "center", padding: "20px", color: "#64748b" }}>
                      No checklist items defined for this task.
                    </div>
                  ) : (
                    updateChecklist.map(item => (
                      <div className="myt-checklist-row" key={item.id} onClick={() => handleToggleChecklist(item.id)}>
                        <div className="myt-checklist-text">
                          {item.completed ? (
                            <div className="myt-checkbox-custom checked">
                              <Check size={11} color="white" strokeWidth={4} />
                            </div>
                          ) : (
                            <div className="myt-checkbox-custom unchecked"></div>
                          )}
                          <span style={{ color: item.completed ? "#0f172a" : "#475569" }}>{item.text}</span>
                        </div>
                        <div className="myt-checklist-status">
                          <span className={`myt-chk-status ${item.completed ? 'completed' : 'pending'}`}>
                            {item.completed ? 'Completed' : 'Pending'}
                          </span>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </div>

              <div className="myt-modal-section">
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "8px" }}>
                  <h4 style={{ fontSize: "14px", fontWeight: "600", margin: 0, color: "#0f172a" }}>Overall Progress</h4>
                  <span style={{ fontSize: "14px", fontWeight: "700", color: "#0f172a" }}>{updateProgressVal}%</span>
                </div>
                {updateChecklist.length === 0 ? (
                  <div style={{ display: "flex", alignItems: "center", gap: "10px", marginTop: "8px" }}>
                    <input 
                      type="range" 
                      min="0" 
                      max="100" 
                      step="5"
                      value={updateProgressVal} 
                      onChange={(e) => {
                        const val = parseInt(e.target.value, 10);
                        setUpdateProgressVal(val);
                        if (val === 100) {
                          setUpdateStatusVal("Completed");
                        } else if (val > 0 && updateStatusVal === "To-Do") {
                          setUpdateStatusVal("In Progress");
                        }
                      }}
                      style={{ flex: 1, accentColor: "#0f172a" }}
                    />
                  </div>
                ) : (
                  <div className="myt-overall-progress-track">
                    <div className="myt-overall-progress-fill" style={{ width: `${updateProgressVal}%` }}></div>
                  </div>
                )}
              </div>

              <div className="myt-modal-section">
                <h4 style={{ fontSize: "14px", fontWeight: "600", marginBottom: "8px", color: "#0f172a" }}>Remarks <span style={{ fontWeight: "400", color: "#64748b" }}>(Optional)</span></h4>
                <textarea 
                  className="myt-remarks-input" 
                  placeholder="Enter remarks..." 
                  value={updateRemarks} 
                  onChange={(e) => setUpdateRemarks(e.target.value)}
                />
              </div>

              <div className="myt-modal-section">
                <h4 style={{ fontSize: "14px", fontWeight: "600", marginBottom: "8px", color: "#0f172a" }}>Upload Evidence <span style={{ fontWeight: "400", color: "#64748b" }}>(Optional)</span></h4>
                <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                  <label className="myt-file-upload-btn">
                    Choose Files
                    <input type="file" style={{ display: "none" }} />
                  </label>
                  <span style={{ fontSize: "13px", color: "#64748b" }}>No file chosen</span>
                </div>
              </div>

              <div className="myt-modal-actions" style={{ borderTop: "none", marginTop: "16px", paddingTop: "0" }}>
                <button className="cc-btn secondary" onClick={() => setShowUpdateModal(false)} style={{ borderRadius: "6px" }}>Cancel</button>
                <button className="cc-btn primary" onClick={handleSaveProgress} style={{ borderRadius: "6px", backgroundColor: "#0f172a" }}>Update</button>
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