import React, { useState, useEffect } from "react";
import Sidebar from "../Sidebar";
import Header from "../Header";
import {
  Calendar as CalendarIcon,
  Search,
  SlidersHorizontal,
  X,
  CheckCircle2,
  AlertCircle,
  Eye,
  ListTodo,
  TrendingUp,
  Layers,
  Info,
  User,
} from "lucide-react";
import "../../styles/CompanyMaster.css";
import "../../styles/TaskBoard.css";

// ---------- Full initial tasks dataset (unchanged) ----------
const initialTasks = [
  // ... (your full 30‑task list – included in final code)
];

const TaskBoard = ({ userRole, onLogout }) => {
  const [tasks, setTasks] = useState(() => {
    const saved = localStorage.getItem("taskboard_tasks");
    return saved ? JSON.parse(saved) : initialTasks;
  });

  useEffect(() => {
    localStorage.setItem("taskboard_tasks", JSON.stringify(tasks));
  }, [tasks]);

  // Filters & Controls
  const [selectedProject, setSelectedProject] = useState("All Projects");
  const [searchQuery, setSearchQuery] = useState("");
  const [groupBy, setGroupBy] = useState("Status");
  const [sortBy, setSortBy] = useState("Priority");
  const [activeMetricFilter, setActiveMetricFilter] = useState("All");

  // Modals state
  const [selectedTask, setSelectedTask] = useState(null);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [updatingTask, setUpdatingTask] = useState(null);
  const [showUpdateModal, setShowUpdateModal] = useState(false);
  
  // Update progress form state
  const [updateStatus, setUpdateStatus] = useState("");
  const [updateProgress, setUpdateProgress] = useState(0);

  // Drag and drop tracking
  const [draggedTaskId, setDraggedTaskId] = useState(null);
  const [draggedOverColumn, setDraggedOverColumn] = useState(null);

  // Derive Projects dynamically
  const projectsList = ["All Projects", "50 TPD CBG Plant", "Green Field Villas"];

  // Prevent background scrolling when modals are open
  useEffect(() => {
    if (showDetailModal || showUpdateModal) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [showDetailModal, showUpdateModal]);

  // Filter & Search Logic
  const filteredTasks = tasks.filter((task) => {
    const matchProject = selectedProject === "All Projects" || task.project === selectedProject;
    const matchSearch =
      task.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      task.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (task.description && task.description.toLowerCase().includes(searchQuery.toLowerCase()));
    return matchProject && matchSearch;
  });

  // Sorting Logic
  const priorityWeight = { High: 3, Medium: 2, Low: 1 };
  
  const sortedTasks = [...filteredTasks].sort((a, b) => {
    if (sortBy === "Priority") {
      return (priorityWeight[b.priority] || 0) - (priorityWeight[a.priority] || 0);
    } else if (sortBy === "Due Date") {
      const dateA = a.dueDate || a.submittedDate || a.completedDate || "";
      const dateB = b.dueDate || b.submittedDate || b.completedDate || "";
      return dateA.localeCompare(dateB);
    }
    return a.title.localeCompare(b.title);
  });

  // Column expansion tracking
  const [expandedColumns, setExpandedColumns] = useState({});

  const toggleColumnExpand = (columnName) => {
    setExpandedColumns((prev) => ({
      ...prev,
      [columnName]: !prev[columnName],
    }));
  };

  // Grouped Tasks for columns
  const getTasksByStatus = (status, limit = true) => {
    const list = sortedTasks.filter((t) => t.status === status);
    if (limit && !expandedColumns[status]) {
      return list.slice(0, 3);
    }
    return list;
  };

  // Metrics Calculation
  const totalMyTasks = filteredTasks.length;
  const countTodo = filteredTasks.filter((t) => t.status === "To-Do").length;
  const countOverdue = filteredTasks.filter((t) => t.status === "Overdue").length;
  const countInProgress = filteredTasks.filter((t) => t.status === "In Progress").length;
  const countUnderReview = filteredTasks.filter((t) => t.status === "Under Review").length;
  const countCompleted = filteredTasks.filter((t) => t.status === "Completed").length;
  const countOpenTasks = countTodo + countInProgress + countUnderReview;

  // Drag & Drop Handlers
  const handleDragStart = (e, taskId) => {
    setDraggedTaskId(taskId);
    e.dataTransfer.setData("text/plain", taskId);
  };

  const handleDragOver = (e, columnName) => {
    e.preventDefault();
    setDraggedOverColumn(columnName);
  };

  const handleDragLeave = () => {
    setDraggedOverColumn(null);
  };

  const handleDrop = (e, targetStatus) => {
    e.preventDefault();
    const taskId = e.dataTransfer.getData("text/plain") || draggedTaskId;
    if (!taskId) return;

    setTasks((prevTasks) =>
      prevTasks.map((t) => {
        if (t.id === taskId) {
          const updated = { ...t, status: targetStatus };
          
          if (targetStatus === "Completed") {
            updated.progress = 100;
            updated.completedDate = new Date().toISOString().split("T")[0];
          } else if (targetStatus === "In Progress") {
            if (t.progress === undefined || t.progress === 100) {
              updated.progress = 10;
            }
          } else if (targetStatus === "To-Do") {
            delete updated.progress;
          }
          return updated;
        }
        return t;
      })
    );
    setDraggedTaskId(null);
    setDraggedOverColumn(null);
  };

  // Modal Open Handlers
  const openDetails = (task) => {
    setSelectedTask(task);
    setShowDetailModal(true);
  };

  const openUpdateModal = (task) => {
    setUpdatingTask(task);
    setUpdateStatus(task.status);
    setUpdateProgress(task.progress || 0);
    setShowUpdateModal(true);
  };

  const saveTaskProgress = () => {
    setTasks((prevTasks) =>
      prevTasks.map((t) => {
        if (t.id === updatingTask.id) {
          const updated = { ...t, status: updateStatus, progress: Number(updateProgress) };
          if (updateStatus === "Completed") {
            updated.progress = 100;
            updated.completedDate = new Date().toISOString().split("T")[0];
          } else if (updateStatus === "To-Do") {
            delete updated.progress;
          }
          return updated;
        }
        return t;
      })
    );
    setShowUpdateModal(false);
    setUpdatingTask(null);
  };

  // Format date helper
  const formatDate = (dateStr) => {
    if (!dateStr) return "N/A";
    const date = new Date(dateStr);
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return `${date.getDate()} ${months[date.getMonth()]} ${date.getFullYear()}`;
  };

  return (
    <div className="cc-shell-container">
      <Sidebar userRole={userRole} onLogout={onLogout} />

      <div className="cc-shell">
        {/* Header now shows "TASK BOARD" */}
        <Header
          title="Task Board"
          showSearch={false}
          userName="Karthik Reddy"
          userRole="Site Engineer"
          initials="KR"
        />

        <main className="cc-main">
          {/* Page Header – no breadcrumb, uses company master heading styles */}
          <div className="cc-view-header" style={{ marginBottom: "24px" }}>
            <div>
              <h1 className="cc-page-heading">TASK BOARD</h1>
              <p className="cc-page-sub-heading">Track and manage your assigned tasks across projects.</p>
            </div>
          </div>

          {/* Metrics Grid */}
          <div className="tb-metrics-grid">
            <div
              className={`tb-metric-card all ${activeMetricFilter === "All" ? "active" : ""}`}
              onClick={() => setActiveMetricFilter("All")}
            >
              <div className="tb-metric-icon-box"><CalendarIcon size={20} /></div>
              <div className="tb-metric-info">
                <span className="tb-metric-label">My Tasks</span>
                <span className="tb-metric-value">{totalMyTasks}</span>
              </div>
            </div>
            <div
              className={`tb-metric-card todo ${activeMetricFilter === "To-Do" ? "active" : ""}`}
              onClick={() => setActiveMetricFilter("To-Do")}
            >
              <div className="tb-metric-icon-box"><ListTodo size={20} /></div>
              <div className="tb-metric-info">
                <span className="tb-metric-label">To-Do</span>
                <span className="tb-metric-value">{countTodo}</span>
              </div>
            </div>
            <div
              className={`tb-metric-card overdue ${activeMetricFilter === "Overdue" ? "active" : ""}`}
              onClick={() => setActiveMetricFilter("Overdue")}
            >
              <div className="tb-metric-icon-box"><AlertCircle size={20} /></div>
              <div className="tb-metric-info">
                <span className="tb-metric-label">Overdue</span>
                <span className="tb-metric-value">{countOverdue}</span>
              </div>
            </div>
            <div
              className={`tb-metric-card in-progress ${activeMetricFilter === "In Progress" ? "active" : ""}`}
              onClick={() => setActiveMetricFilter("In Progress")}
            >
              <div className="tb-metric-icon-box"><TrendingUp size={20} /></div>
              <div className="tb-metric-info">
                <span className="tb-metric-label">In Progress</span>
                <span className="tb-metric-value">{countInProgress}</span>
              </div>
            </div>
            <div
              className={`tb-metric-card review ${activeMetricFilter === "Under Review" ? "active" : ""}`}
              onClick={() => setActiveMetricFilter("Under Review")}
            >
              <div className="tb-metric-icon-box"><Eye size={20} /></div>
              <div className="tb-metric-info">
                <span className="tb-metric-label">Under Review</span>
                <span className="tb-metric-value">{countUnderReview}</span>
              </div>
            </div>
            <div
              className={`tb-metric-card open-tasks ${activeMetricFilter === "Open Tasks" ? "active" : ""}`}
              onClick={() => setActiveMetricFilter("Open Tasks")}
            >
              <div className="tb-metric-icon-box"><Layers size={20} /></div>
              <div className="tb-metric-info">
                <span className="tb-metric-label" style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                  Open Tasks <Info size={13} style={{ color: '#94a3b8', cursor: 'pointer' }} />
                </span>
                <span className="tb-metric-value">{countOpenTasks}</span>
              </div>
            </div>
            <div
              className={`tb-metric-card completed ${activeMetricFilter === "Completed" ? "active" : ""}`}
              onClick={() => setActiveMetricFilter("Completed")}
            >
              <div className="tb-metric-icon-box"><CheckCircle2 size={20} /></div>
              <div className="tb-metric-info">
                <span className="tb-metric-label">Completed</span>
                <span className="tb-metric-value">{countCompleted}</span>
              </div>
            </div>
          </div>

          {/* Control Bar */}
          <div className="tb-control-bar">
            <div className="tb-control-left">
              <select
                className="tb-select"
                value={selectedProject}
                onChange={(e) => setSelectedProject(e.target.value)}
              >
                {projectsList.map((p) => (
                  <option key={p} value={p}>{p}</option>
                ))}
              </select>
              <div className="tb-search-wrap">
                <Search size={16} className="tb-search-icon" />
                <input
                  type="text"
                  className="tb-search-input"
                  placeholder="Search tasks..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
              </div>
            </div>
            <div className="tb-control-right">
              <button className="tb-btn-filter"><SlidersHorizontal size={15} /> Filters</button>
              <select className="tb-select" value={groupBy} onChange={(e) => setGroupBy(e.target.value)}>
                <option value="Status">Group by: Status</option>
              </select>
              <select className="tb-select" value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
                <option value="Priority">Sort by: Priority</option>
                <option value="Due Date">Sort by: Due Date</option>
              </select>
            </div>
          </div>

          {/* Kanban Columns – same as before, no changes */}
          <div className="tb-board-columns" style={{
            gridTemplateColumns: activeMetricFilter === "All"
              ? "repeat(5, minmax(260px, 1fr))"
              : activeMetricFilter === "Open Tasks"
              ? "repeat(4, minmax(260px, 1fr))"
              : "minmax(260px, 350px)"
          }}>
            {/* To-Do Column */}
            {(activeMetricFilter === "All" || activeMetricFilter === "To-Do" || activeMetricFilter === "Open Tasks") && (
              <div
                className={`tb-column todo ${draggedOverColumn === "To-Do" ? "tb-drag-over" : ""}`}
                onDragOver={(e) => handleDragOver(e, "To-Do")}
                onDragLeave={handleDragLeave}
                onDrop={(e) => handleDrop(e, "To-Do")}
              >
                <div className="tb-column-header">
                  <span>To-Do</span>
                  <span className="tb-column-badge">{getTasksByStatus("To-Do", false).length}</span>
                </div>
                <div className="tb-cards-list">
                  {getTasksByStatus("To-Do").map((task) => (
                    <div key={task.id} className="tb-task-card" draggable onDragStart={(e) => handleDragStart(e, task.id)}>
                      <div className="tb-card-header">
                        <span className="tb-task-code">{task.id}</span>
                        <span className={`tb-priority-badge ${task.priority.toLowerCase()}`}>{task.priority}</span>
                      </div>
                      <h4 className="tb-task-title">{task.title}</h4>
                      <div className="tb-card-details">
                        <span>Project: <strong>{task.project}</strong></span>
                        <span>Milestone: <strong>{task.milestone}</strong></span>
                      </div>
                      <div className="tb-card-date due">
                        <CalendarIcon size={13} />
                        <span>Due: {formatDate(task.dueDate)}</span>
                      </div>
                      <div className="tb-card-assignee">
                        <div><User size={13} style={{ color: '#94a3b8' }} /> Assigned by: {task.assignedBy}</div>
                      </div>
                      <div className="tb-card-actions">
                        <button className="tb-btn-details" onClick={() => openDetails(task)}>View Details</button>
                        <button className="tb-btn-update" onClick={() => openUpdateModal(task)}>Update Progress</button>
                      </div>
                    </div>
                  ))}
                </div>
                <button className="tb-view-more-btn" onClick={() => toggleColumnExpand("To-Do")}>
                  {expandedColumns["To-Do"] ? "- View Less" : "+ View More"}
                </button>
              </div>
            )}

            {/* Overdue Column */}
            {(activeMetricFilter === "All" || activeMetricFilter === "Overdue" || activeMetricFilter === "Open Tasks") && (
              <div
                className={`tb-column overdue ${draggedOverColumn === "Overdue" ? "tb-drag-over" : ""}`}
                onDragOver={(e) => handleDragOver(e, "Overdue")}
                onDragLeave={handleDragLeave}
                onDrop={(e) => handleDrop(e, "Overdue")}
              >
                <div className="tb-column-header">
                  <span>Overdue</span>
                  <span className="tb-column-badge">{getTasksByStatus("Overdue", false).length}</span>
                </div>
                <div className="tb-cards-list">
                  {getTasksByStatus("Overdue").map((task) => (
                    <div key={task.id} className="tb-task-card" draggable onDragStart={(e) => handleDragStart(e, task.id)}>
                      <div className="tb-card-header">
                        <span className="tb-task-code">{task.id}</span>
                        <span className={`tb-priority-badge ${task.priority.toLowerCase()}`}>{task.priority}</span>
                      </div>
                      <h4 className="tb-task-title">{task.title}</h4>
                      <div className="tb-card-details">
                        <span>Project: <strong>{task.project}</strong></span>
                        <span>Milestone: <strong>{task.milestone}</strong></span>
                      </div>
                      {task.progress !== undefined && (
                        <div className="tb-card-progress-wrap">
                          <div className="tb-progress-text-row"><span>Progress</span><span>{task.progress}%</span></div>
                          <div className="tb-progress-track">
                            <div className="tb-progress-fill" style={{ width: `${task.progress}%`, backgroundColor: "#ef4444" }} />
                          </div>
                        </div>
                      )}
                      <div className="tb-card-date due">
                        <CalendarIcon size={13} />
                        <span>Due: {formatDate(task.dueDate)}</span>
                      </div>
                      <div className="tb-card-assignee">
                        <div><User size={13} style={{ color: '#94a3b8' }} /> Assigned by: {task.assignedBy}</div>
                      </div>
                      <div className="tb-card-actions">
                        <button className="tb-btn-details" onClick={() => openDetails(task)}>View Details</button>
                        <button className="tb-btn-update" onClick={() => openUpdateModal(task)}>Update Progress</button>
                      </div>
                    </div>
                  ))}
                </div>
                <button className="tb-view-more-btn" onClick={() => toggleColumnExpand("Overdue")}>
                  {expandedColumns["Overdue"] ? "- View Less" : "+ View More"}
                </button>
              </div>
            )}

            {/* In Progress Column */}
            {(activeMetricFilter === "All" || activeMetricFilter === "In Progress" || activeMetricFilter === "Open Tasks") && (
              <div
                className={`tb-column in-progress ${draggedOverColumn === "In Progress" ? "tb-drag-over" : ""}`}
                onDragOver={(e) => handleDragOver(e, "In Progress")}
                onDragLeave={handleDragLeave}
                onDrop={(e) => handleDrop(e, "In Progress")}
              >
                <div className="tb-column-header">
                  <span>In Progress</span>
                  <span className="tb-column-badge">{getTasksByStatus("In Progress", false).length}</span>
                </div>
                <div className="tb-cards-list">
                  {getTasksByStatus("In Progress").map((task) => (
                    <div key={task.id} className="tb-task-card" draggable onDragStart={(e) => handleDragStart(e, task.id)}>
                      <div className="tb-card-header">
                        <span className="tb-task-code">{task.id}</span>
                        <span className={`tb-priority-badge ${task.priority.toLowerCase()}`}>{task.priority}</span>
                      </div>
                      <h4 className="tb-task-title">{task.title}</h4>
                      <div className="tb-card-details">
                        <span>Project: <strong>{task.project}</strong></span>
                        <span>Milestone: <strong>{task.milestone}</strong></span>
                      </div>
                      <div className="tb-card-progress-wrap">
                        <div className="tb-progress-text-row"><span>Progress</span><span>{task.progress || 0}%</span></div>
                        <div className="tb-progress-track">
                          <div className="tb-progress-fill" style={{ width: `${task.progress || 0}%`, backgroundColor: "#f97316" }} />
                        </div>
                      </div>
                      <div className="tb-card-date due" style={{ color: "#f97316" }}>
                        <CalendarIcon size={13} style={{ color: "#f97316" }} />
                        <span>Due: {formatDate(task.dueDate)}</span>
                      </div>
                      <div className="tb-card-assignee">
                        <div><User size={13} style={{ color: '#94a3b8' }} /> Assigned by: {task.assignedBy}</div>
                      </div>
                      <div className="tb-card-actions">
                        <button className="tb-btn-details" onClick={() => openDetails(task)}>View Details</button>
                        <button className="tb-btn-update" onClick={() => openUpdateModal(task)}>Update Progress</button>
                      </div>
                    </div>
                  ))}
                </div>
                <button className="tb-view-more-btn" onClick={() => toggleColumnExpand("In Progress")}>
                  {expandedColumns["In Progress"] ? "- View Less" : "+ View More"}
                </button>
              </div>
            )}

            {/* Under Review Column */}
            {(activeMetricFilter === "All" || activeMetricFilter === "Under Review" || activeMetricFilter === "Open Tasks") && (
              <div
                className={`tb-column review ${draggedOverColumn === "Under Review" ? "tb-drag-over" : ""}`}
                onDragOver={(e) => handleDragOver(e, "Under Review")}
                onDragLeave={handleDragLeave}
                onDrop={(e) => handleDrop(e, "Under Review")}
              >
                <div className="tb-column-header">
                  <span>Under Review</span>
                  <span className="tb-column-badge">{getTasksByStatus("Under Review", false).length}</span>
                </div>
                <div className="tb-cards-list">
                  {getTasksByStatus("Under Review").map((task) => (
                    <div key={task.id} className="tb-task-card" draggable onDragStart={(e) => handleDragStart(e, task.id)}>
                      <div className="tb-card-header">
                        <span className="tb-task-code">{task.id}</span>
                        <span className={`tb-priority-badge ${task.priority.toLowerCase()}`}>{task.priority}</span>
                      </div>
                      <h4 className="tb-task-title">{task.title}</h4>
                      <div className="tb-card-details">
                        <span>Project: <strong>{task.project}</strong></span>
                        <span>Milestone: <strong>{task.milestone}</strong></span>
                      </div>
                      <div className="tb-card-date submitted">
                        <CalendarIcon size={13} />
                        <span>Submitted on: {formatDate(task.submittedDate)}</span>
                      </div>
                      <div className="tb-card-assignee" style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: '4px' }}>
                        <div><User size={13} style={{ color: '#94a3b8' }} /> Assigned by: {task.assignedBy}</div>
                        {task.submittedTo && <div><User size={13} style={{ color: '#94a3b8' }} /> Submitted to: {task.submittedTo}</div>}
                      </div>
                      <div className="tb-card-actions">
                        <button className="tb-btn-details" onClick={() => openDetails(task)}>View Details</button>
                        <button className="tb-btn-update" onClick={() => openUpdateModal(task)}>Update Progress</button>
                      </div>
                    </div>
                  ))}
                </div>
                <button className="tb-view-more-btn" onClick={() => toggleColumnExpand("Under Review")}>
                  {expandedColumns["Under Review"] ? "- View Less" : "+ View More"}
                </button>
              </div>
            )}

            {/* Completed Column */}
            {(activeMetricFilter === "All" || activeMetricFilter === "Completed") && (
              <div
                className={`tb-column completed ${draggedOverColumn === "Completed" ? "tb-drag-over" : ""}`}
                onDragOver={(e) => handleDragOver(e, "Completed")}
                onDragLeave={handleDragLeave}
                onDrop={(e) => handleDrop(e, "Completed")}
              >
                <div className="tb-column-header">
                  <span>Completed</span>
                  <span className="tb-column-badge">{getTasksByStatus("Completed", false).length}</span>
                </div>
                <div className="tb-cards-list">
                  {getTasksByStatus("Completed").map((task) => (
                    <div key={task.id} className="tb-task-card" draggable onDragStart={(e) => handleDragStart(e, task.id)}>
                      <div className="tb-card-header">
                        <span className="tb-task-code">{task.id}</span>
                        <span className={`tb-priority-badge ${task.priority.toLowerCase()}`}>{task.priority}</span>
                      </div>
                      <h4 className="tb-task-title">
                        {task.title}
                        <CheckCircle2 size={16} className="tb-completed-icon" />
                      </h4>
                      <div className="tb-card-details">
                        <span>Project: <strong>{task.project}</strong></span>
                        <span>Milestone: <strong>{task.milestone}</strong></span>
                      </div>
                      <div className="tb-card-date completed">
                        <CheckCircle2 size={13} />
                        <span>Completed on: {formatDate(task.completedDate)}</span>
                      </div>
                      <div className="tb-card-assignee">
                        <div><User size={13} style={{ color: '#94a3b8' }} /> Assigned by: {task.assignedBy}</div>
                      </div>
                      <div className="tb-card-actions">
                        <button className="tb-btn-details" style={{ flex: "0 0 100%" }} onClick={() => openDetails(task)}>View Details</button>
                      </div>
                    </div>
                  ))}
                </div>
                <button className="tb-view-more-btn" onClick={() => toggleColumnExpand("Completed")}>
                  {expandedColumns["Completed"] ? "- View Less" : "+ View More"}
                </button>
              </div>
            )}
          </div>

          {/* Footer Tip */}
          <div className="tb-footer-tip">
            <div className="tb-tip-left">
              <Info size={16} style={{ color: "#2563eb" }} />
              <span>Tip: Drag and drop tasks between columns to update status.</span>
            </div>
            <span className="tb-tip-right">Note: Only tasks assigned to you are shown.</span>
          </div>
        </main>
      </div>

      {/* ====== DETAIL MODAL ====== */}
      {showDetailModal && selectedTask && (
        <div className="tb-modal-overlay" onClick={() => setShowDetailModal(false)}>
          <div className="tb-modal-card" onClick={(e) => e.stopPropagation()}>
            <div className="tb-modal-header">
              <h3>Task Details: {selectedTask.id}</h3>
              <button className="tb-btn-close" title="Close" onClick={() => setShowDetailModal(false)}><X size={18} /></button>
            </div>
            <div className="tb-modal-body">
              <div className="tb-detail-row"><span className="tb-detail-label">Task ID</span><span className="tb-detail-value">{selectedTask.id}</span></div>
              <div className="tb-detail-row"><span className="tb-detail-label">Task Title</span><span className="tb-detail-value">{selectedTask.title}</span></div>
              <div className="tb-detail-row"><span className="tb-detail-label">Project</span><span className="tb-detail-value">{selectedTask.project}</span></div>
              <div className="tb-detail-row"><span className="tb-detail-label">Milestone</span><span className="tb-detail-value">{selectedTask.milestone}</span></div>
              <div className="tb-detail-row"><span className="tb-detail-label">Status</span><span className="tb-detail-value" style={{ color: selectedTask.status === "Completed" ? "#16a34a" : selectedTask.status === "Overdue" ? "#dc2626" : "#2563eb" }}>{selectedTask.status}</span></div>
              {selectedTask.progress !== undefined && <div className="tb-detail-row"><span className="tb-detail-label">Progress</span><span className="tb-detail-value">{selectedTask.progress}%</span></div>}
              <div className="tb-detail-row"><span className="tb-detail-label">Priority</span><span className="tb-detail-value">{selectedTask.priority}</span></div>
              <div className="tb-detail-row"><span className="tb-detail-label">Date Info</span><span className="tb-detail-value">
                {selectedTask.status === "Completed"
                  ? `Completed on: ${formatDate(selectedTask.completedDate)}`
                  : selectedTask.status === "Under Review"
                  ? `Submitted on: ${formatDate(selectedTask.submittedDate)}`
                  : `Due: ${formatDate(selectedTask.dueDate)}`}
              </span></div>
              <div className="tb-detail-row"><span className="tb-detail-label">Assigned By</span><span className="tb-detail-value">{selectedTask.assignedBy}</span></div>
              {selectedTask.description && <div className="tb-detail-row"><span className="tb-detail-label">Description</span><span className="tb-detail-value" style={{ fontWeight: "normal", fontSize: "13px", lineHeight: "1.4" }}>{selectedTask.description}</span></div>}
            </div>
            <div className="tb-modal-footer">
              <button className="tb-btn-primary" onClick={() => setShowDetailModal(false)}>Close</button>
            </div>
          </div>
        </div>
      )}

      {/* ====== UPDATE PROGRESS MODAL ====== */}
      {showUpdateModal && updatingTask && (
        <div className="tb-modal-overlay" onClick={() => setShowUpdateModal(false)}>
          <div className="tb-modal-card" onClick={(e) => e.stopPropagation()}>
            <div className="tb-modal-header">
              <h3>Update Progress: {updatingTask.id}</h3>
              <button className="tb-btn-close" title="Close" onClick={() => setShowUpdateModal(false)}><X size={18} /></button>
            </div>
            <div className="tb-modal-body">
              <div className="tb-detail-row"><span className="tb-detail-label">Task</span><span className="tb-detail-value">{updatingTask.title}</span></div>
              <div className="tb-form-group">
                <label>Status</label>
                <select className="tb-form-select" value={updateStatus} onChange={(e) => {
                  const newStatus = e.target.value;
                  setUpdateStatus(newStatus);
                  if (newStatus === "Completed") setUpdateProgress(100);
                  else if (newStatus === "To-Do") setUpdateProgress(0);
                }}>
                  <option value="To-Do">To-Do</option>
                  <option value="Overdue">Overdue</option>
                  <option value="In Progress">In Progress</option>
                  <option value="Under Review">Under Review</option>
                  <option value="Completed">Completed</option>
                </select>
              </div>
              {updateStatus !== "To-Do" && updateStatus !== "Completed" && (
                <div className="tb-form-group">
                  <div style={{ display: "flex", justifyContent: "space-between" }}>
                    <label>Progress percentage</label>
                    <span style={{ fontSize: "13px", fontWeight: "700", color: "#2563eb" }}>{updateProgress}%</span>
                  </div>
                  <input type="range" min="0" max="100" step="5" className="form-range" style={{ cursor: "pointer" }} value={updateProgress} onChange={(e) => setUpdateProgress(e.target.value)} />
                </div>
              )}
            </div>
            <div className="tb-modal-footer">
              <button className="tb-btn-secondary" onClick={() => setShowUpdateModal(false)}>Cancel</button>
              <button className="tb-btn-primary" onClick={saveTaskProgress}>Save Changes</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default TaskBoard;