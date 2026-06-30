import React, { useState, useEffect, useRef } from "react";
import Sidebar from "../Sidebar";
import Header from "../Header";
import { safeFetch, apiPatch, apiPost, apiPut, apiDelete } from "../../utils/api";
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
  Plus,
  Grid,
  CheckSquare,
  Trash2,
  Bell,
  Check,
  ChevronRight,
  Hand,
  Menu
} from "lucide-react";
import "../../styles/TaskBoard.css";
import plantImage from "../../assets/cbg_plant_construction.png";

// Preset assignees with corresponding styling colors
const ASSIGNEES = [
  { name: "Mahesh", bg: "#e0f2fe", color: "#0369a1" },
  { name: "Suresh Babu", bg: "#fee2e2", color: "#b91c1c" },
  { name: "Srikanth", bg: "#dcfce7", color: "#15803d" },
  { name: "Chandu", bg: "#fef9c3", color: "#a16207" },
  { name: "Ravi Kumar", bg: "#f3e8ff", color: "#6b21a8" }
];

const MILESTONES = [
  "ML-001 Project Initiation",
  "ML-002 Civil Construction",
  "ML-003 Mechanical Installation",
  "ML-004 E & I Installation"
];

// Map backend task status to board column names
const mapTaskStatus = (taskSts) => {
  if (!taskSts) return "Not Started";
  const s = taskSts.toUpperCase();
  if (s === "OPEN") return "Not Started";
  if (s === "WIP") return "In Progress";
  if (s === "SUBMIT_REVIEW" || s === "UNDER_REVIEW") return "Under Review";
  if (s === "COMPLETED") return "Completed";
  if (s === "REWORK") return "In Progress";
  return "Not Started";
};

// Map board column name back to backend status
const mapStatusToApi = (uiStatus) => {
  if (uiStatus === "Not Started") return "OPEN";
  if (uiStatus === "In Progress") return "WIP";
  if (uiStatus === "Under Review") return "SUBMIT_REVIEW";
  if (uiStatus === "Completed") return "COMPLETED";
  if (uiStatus === "Overdue") return "OPEN";
  return "OPEN";
};

const mapPriorityFromApi = (prjPrty) => {
  if (!prjPrty) return "Medium";
  const p = prjPrty.toUpperCase();
  if (p === "HIGH") return "High";
  if (p === "LOW") return "Low";
  return "Medium";
};

const mapBackendTask = (t, projects, milestones, employees) => {
  const milestone = (milestones || []).find(m => String(m.mId) === String(t.mId));
  const project = milestone ? (projects || []).find(p => String(p.prjId) === String(milestone.prjId)) : null;
  const employee = (employees || []).find(e => String(e.empId) === String(t.empId));

  let status = "Not Started";
  if (t.taskSts === "COMPLETED") {
    status = "Completed";
  } else {
    const today = new Date().toISOString().split("T")[0];
    if (t.endDt && t.endDt < today) {
      status = "Overdue";
    } else if (t.taskSts === "WIP" || t.taskSts === "REWORK") {
      status = "In Progress";
    } else if (t.taskSts === "SUBMIT_REVIEW" || t.taskSts === "UNDER_REVIEW") {
      status = "Under Review";
    } else {
      status = "Not Started";
    }
  }

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

  const assigneeName = employee ? `${employee.firstName} ${employee.lastName}` : "Unassigned";

  return {
    id: t.taskCd || `TSK-${t.taskId}`,
    taskId: t.taskId,
    title: t.taskNm,
    project: project ? project.prjNm : "Unknown Project",
    milestone: milestone ? `${milestone.mlstnCd || "ML-???"} ${milestone.mlstnTtl || ""}` : "Unknown Milestone",
    milestoneId: t.mId,
    assignee: assigneeName,
    empId: t.empId,
    progress: progress,
    dueDate: t.endDt || "",
    startDate: t.stDt || "",
    subtasksCount: t.wrkDays || 3,
    subtasksCompleted: status === "Completed" ? (t.wrkDays || 3) : 0,
    priority: status === "Completed" ? "Completed" : status === "Overdue" ? "Overdue" : mapPriorityFromApi(project ? project.prjPrty : "Medium"),
    taskType: t.taskAsgnTo === "EXTERNAL" ? "External" : "Internal",
    status: status,
    description: t.taskDesc || "",
    rawTask: t
  };
};

const TaskBoard = ({ userRole, onLogout }) => {
  const [tasks, setTasks] = useState([]);
  const [apiLoaded, setApiLoaded] = useState(false);
  const [employeesList, setEmployeesList] = useState([]);
  const [milestonesRaw, setMilestonesRaw] = useState([]);
  const [projectsRaw, setProjectsRaw] = useState([]);
  const [companiesList, setCompaniesList] = useState([]);
  const [plantsList, setPlantsList] = useState([]);
  const [departmentsList, setDepartmentsList] = useState([]);
  const [selectedProjectId, setSelectedProjectId] = useState("All");

  const fetchLiveTasks = async () => {
    try {
      const [liveProjects, liveMilestones, liveTasks, liveEmployees, profileRes, companies, plants, departments] = await Promise.all([
        safeFetch("/api/project-live", []),
        safeFetch("/api/milestone-live", []),
        safeFetch("/api/task-live", []),
        safeFetch("/api/employees", []),
        safeFetch("/api/profile"),
        safeFetch("/api/companies", []),
        safeFetch("/api/plants", []),
        safeFetch("/api/departments", [])
      ]);

      setProjectsRaw(liveProjects);
      setMilestonesRaw(liveMilestones);
      setEmployeesList(liveEmployees);
      setCompaniesList(companies);
      setPlantsList(plants);
      setDepartmentsList(departments);

      const empId = profileRes?.empId;
      const isAdmin = profileRes?.email === 'siva@atirath.com';

      // Filter tasks to only show tasks assigned to the logged-in user
      const userTasks = (liveTasks || []).filter(t => isAdmin || t.empId === empId);

      const mapped = userTasks.map(t => mapBackendTask(t, liveProjects, liveMilestones, liveEmployees));
      setTasks(mapped);
      setApiLoaded(true);

      const loadedMilestones = liveMilestones.map(m => `${m.mlstnCd || "ML-???"} ${m.mlstnTtl || ""}`).filter(Boolean);
      if (loadedMilestones.length > 0) {
        setNewMilestone(loadedMilestones[0]);
      }
    } catch (err) {
      console.error("Failed to load tasks from API:", err);
    }
  };

  useEffect(() => {
    fetchLiveTasks();
  }, []);

  useEffect(() => {
    if (employeesList.length > 0) {
      setNewAssignee(`${employeesList[0].firstName} ${employeesList[0].lastName}`);
    }
  }, [employeesList]);
  const [selectedMilestone, setSelectedMilestone] = useState("All Milestones");
  const [selectedAssignee, setSelectedAssignee] = useState("All Employees");
  const [selectedTaskType, setSelectedTaskType] = useState("All");
  const [selectedPriority, setSelectedPriority] = useState("All");
  const [selectedStatus, setSelectedStatus] = useState("All Statuses");
  const [searchQuery, setSearchQuery] = useState("");

  // Modals state
  const [showAddModal, setShowAddModal] = useState(false);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [selectedTask, setSelectedTask] = useState(null);
  
  // Add task form state
  const [newTitle, setNewTitle] = useState("");
  const [newMilestone, setNewMilestone] = useState(MILESTONES[0]);
  const [newAssignee, setNewAssignee] = useState(ASSIGNEES[0].name);
  const [newPriority, setNewPriority] = useState("Medium");
  const [newTaskType, setNewTaskType] = useState("Internal");
  const [newDueDate, setNewDueDate] = useState("");
  const [newSubtasksCount, setNewSubtasksCount] = useState(3);
  const [newDescription, setNewDescription] = useState("");
  const [targetColumn, setTargetColumn] = useState("Not Started");

  // Edit/Update progress form state
  const [editStatus, setEditStatus] = useState("");
  const [editProgress, setEditProgress] = useState(0);
  const [editPriority, setEditPriority] = useState("Medium");

  // Drag and drop states
  const [draggedTaskId, setDraggedTaskId] = useState(null);
  const [draggedOverCol, setDraggedOverCol] = useState(null);

  // Board scroll refs
  const boardRef = useRef(null);
  const colRefs = {
    "Not Started":  useRef(null),
    "In Progress":  useRef(null),
    "Under Review": useRef(null),
    "Completed":    useRef(null),
    "Overdue":      useRef(null),
  };

  // Scroll board to a specific column
  const scrollToCol = (status) => {
    if (status === "All Statuses") {
      boardRef.current?.scrollTo({ left: 0, behavior: "smooth" });
      return;
    }
    const colEl = colRefs[status]?.current;
    if (colEl && boardRef.current) {
      const boardLeft = boardRef.current.getBoundingClientRect().left;
      const colLeft   = colEl.getBoundingClientRect().left;
      boardRef.current.scrollBy({ left: colLeft - boardLeft - 12, behavior: "smooth" });
    }
  };

  // Prevent background scrolling on modals open
  useEffect(() => {
    if (showAddModal || showDetailModal || showEditModal) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [showAddModal, showDetailModal, showEditModal]);

  // Filter Tasks
  const filteredTasks = tasks.filter((task) => {
    const matchProject = selectedProjectId === "All" || String(task.projectId) === String(selectedProjectId);
    const matchMilestone = selectedMilestone === "All Milestones" || task.milestone === selectedMilestone;
    const matchAssignee = selectedAssignee === "All Employees" || task.assignee === selectedAssignee;
    const matchTaskType = selectedTaskType === "All" || task.taskType === selectedTaskType;
    const matchPriority = selectedPriority === "All" || task.priority === selectedPriority;
    const matchStatus = selectedStatus === "All Statuses" || task.status === selectedStatus;
    const matchSearch =
      task.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      task.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (task.description && task.description.toLowerCase().includes(searchQuery.toLowerCase()));

    return matchProject && matchMilestone && matchAssignee && matchTaskType && matchPriority && matchStatus && matchSearch;
  });

  const derivedMilestones = milestonesRaw
    .filter(m => selectedProjectId === "All" || String(m.prjId || m.prj_id || m.drftPrjId || m.id) === String(selectedProjectId))
    .map(m => `${m.mlstnCd || "ML-???"} ${m.mlstnTtl || ""}`)
    .filter(Boolean);

  const activeProject = projectsRaw.find(p => selectedProjectId !== "All" ? String(p.prjId) === String(selectedProjectId) : true) || projectsRaw[0];
  const activePlant = activeProject ? plantsList.find(pl => pl.pltId === activeProject.pltId)?.pltNm : null;
  const activeDept = activeProject ? departmentsList.find(d => d.deptId === activeProject.deptId)?.deptNm : null;

  // Calculate Metrics based on ALL tasks of selected project (ignoring other filters to match mockup initial visual state,
  // but let them update dynamically when tasks are dragged/added/deleted)
  const projectTasks = tasks.filter(task => selectedProjectId === "All" || String(task.projectId) === String(selectedProjectId));
  const totalTasksCount = projectTasks.filter(t => t.status !== "Under Review").length; // Completed + In Progress + Not Started + Overdue
  const notStartedCount = projectTasks.filter(t => t.status === "Not Started").length;
  const inProgressCount = projectTasks.filter(t => t.status === "In Progress" || t.status === "Under Review").length;
  const completedCount = projectTasks.filter(t => t.status === "Completed").length;
  const overdueCount = projectTasks.filter(t => t.status === "Overdue").length;

  const notStartedPct = totalTasksCount > 0 ? ((notStartedCount / totalTasksCount) * 100).toFixed(2) : "0.00";
  const inProgressPct = totalTasksCount > 0 ? ((inProgressCount / totalTasksCount) * 100).toFixed(2) : "0.00";
  const completedPct = totalTasksCount > 0 ? ((completedCount / totalTasksCount) * 100).toFixed(2) : "0.00";
  const overduePct = totalTasksCount > 0 ? ((overdueCount / totalTasksCount) * 100).toFixed(2) : "0.00";

  // Drag & Drop
  const handleDragStart = (e, taskId) => {
    e.dataTransfer.setData("text/plain", taskId);
    setDraggedTaskId(taskId);
  };

  const handleDragOver = (e, status) => {
    e.preventDefault();
    setDraggedOverCol(status);
  };

  const handleDragLeave = () => {
    setDraggedOverCol(null);
  };

  const handleDrop = async (e, targetStatus) => {
    e.preventDefault();
    const taskIdVal = e.dataTransfer.getData("text/plain") || draggedTaskId;
    if (!taskIdVal) return;

    const taskObj = tasks.find(t => t.id === taskIdVal);
    if (!taskObj || !taskObj.taskId) return;

    const backendSts = mapStatusToApi(targetStatus);

    try {
      setTasks(prev => prev.map(t => t.id === taskIdVal ? { ...t, status: targetStatus } : t));
      await apiPatch(`/api/task-live/${taskObj.taskId}/status`, { taskSts: backendSts });
      await fetchLiveTasks();
    } catch (err) {
      console.error("Failed to update status on drag drop:", err);
    }

    setDraggedTaskId(null);
    setDraggedOverCol(null);
  };

  // Add Task
  const openAddTaskModal = (colStatus) => {
    setTargetColumn(colStatus);
    setNewTitle("");
    setNewDueDate("");
    setNewDescription("");
    setNewSubtasksCount(3);
    setShowAddModal(true);
  };

  const handleCreateTask = async (e) => {
    e.preventDefault();
    if (!newTitle.trim()) return;

    const msObj = milestonesRaw.find(m => `${m.mlstnCd || "ML-???"} ${m.mlstnTtl || ""}` === newMilestone);
    const mId = msObj ? msObj.mId : (milestonesRaw[0]?.mId || 1);

    const empObj = employeesList.find(emp => `${emp.firstName} ${emp.lastName}` === newAssignee);
    const empId = empObj ? empObj.empId : null;

    const backendSts = mapStatusToApi(targetColumn);

    const taskObj = {
      taskNm: newTitle,
      mId: mId,
      empId: empId,
      taskAsgnTo: newTaskType === "External" ? "EXTERNAL" : "INTERNAL",
      taskSts: backendSts,
      taskDesc: newDescription || "",
      stDt: new Date().toISOString().split("T")[0],
      endDt: newDueDate || new Date().toISOString().split("T")[0],
      noOfDays: 5,
      wrkDays: Number(newSubtasksCount) || 5
    };

    try {
      await apiPost("/api/task-live", taskObj);
      await fetchLiveTasks();
      setShowAddModal(false);
    } catch (err) {
      console.error("Error creating task:", err);
    }
  };

  // View Details
  const handleCardClick = (task) => {
    setSelectedTask(task);
    setShowDetailModal(true);
  };

  const toggleSubtask = async () => {
    if (!selectedTask || !selectedTask.taskId) return;
    const completed = selectedTask.subtasksCompleted;
    const total = selectedTask.subtasksCount;
    let nextCompleted = completed;

    if (completed < total) {
      nextCompleted = completed + 1;
    } else {
      nextCompleted = 0;
    }

    const newProgress = Math.round((nextCompleted / total) * 100);
    const updatedStatus = newProgress === 100 ? "Completed" : selectedTask.status;
    const backendSts = mapStatusToApi(updatedStatus);

    try {
      const updatedDetails = {
        ...selectedTask.rawTask,
        taskSts: backendSts,
        wrkDays: total
      };

      await apiPut(`/api/task-live/${selectedTask.taskId}`, updatedDetails);
      await fetchLiveTasks();

      const freshTask = tasks.find(t => t.taskId === selectedTask.taskId);
      if (freshTask) {
        setSelectedTask(freshTask);
      } else {
        setShowDetailModal(false);
      }
    } catch (err) {
      console.error("Failed to toggle subtask:", err);
    }
  };

  // Open Edit progress Modal
  const openEditProgressModal = (task, e) => {
    e.stopPropagation();
    setSelectedTask(task);
    setEditStatus(task.status);
    setEditProgress(task.progress || 0);
    setEditPriority(task.priority === "Completed" || task.priority === "Overdue" ? "Medium" : task.priority);
    setShowEditModal(true);
  };

  const handleSaveProgress = async (e) => {
    e.preventDefault();
    if (!selectedTask || !selectedTask.taskId) return;

    const backendSts = mapStatusToApi(editStatus);

    try {
      const updatedDetails = {
        ...selectedTask.rawTask,
        taskSts: backendSts,
        wrkDays: selectedTask.subtasksCount
      };

      await apiPut(`/api/task-live/${selectedTask.taskId}`, updatedDetails);
      await fetchLiveTasks();
      setShowEditModal(false);
      setShowDetailModal(false);
    } catch (err) {
      console.error("Failed to save progress:", err);
    }
  };

  // Delete Task
  const handleDeleteTask = async (taskIdVal) => {
    const taskObj = tasks.find(t => t.id === taskIdVal || String(t.taskId) === String(taskIdVal));
    if (!taskObj || !taskObj.taskId) return;

    try {
      await apiDelete(`/api/task-live/${taskObj.taskId}`);
      await fetchLiveTasks();
      setShowDetailModal(false);
    } catch (err) {
      console.error("Failed to delete task:", err);
    }
  };

  // Format date helper
  const formatDate = (dateStr) => {
    if (!dateStr) return "";
    const parts = dateStr.split("-");
    if (parts.length !== 3) return dateStr;
    const day = parts[2];
    const monthIndex = parseInt(parts[1], 10) - 1;
    const year = parts[0];
    const months = ["Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar", "Apr", "May"];
    // Simply map index
    const monthsFull = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return `${parseInt(day, 10)}-${monthsFull[monthIndex]}-${year}`;
  };

  const getAssigneeInfo = (name) => {
    return ASSIGNEES.find(a => a.name === name) || { name: name, bg: "#e2e8f0", color: "#475569" };
  };

  const getInitials = (name) => {
    if (!name) return "";
    const parts = name.split(" ");
    if (parts.length >= 2) return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    return name[0].toUpperCase();
  };

  const getTasksByStatus = (status) => {
    return filteredTasks.filter(t => t.status === status);
  };

  return (
    <div className="tb-shell-container">
      {/* Sidebar Component */}
      <Sidebar onLogout={onLogout} />

      <div className="tb-shell">
        <Header title="Task Board" subtitle="Visualize and manage tasks across all milestones" />

        {/* Main Content */}
        <main className="tb-main">

          {/* Project Summary Card */}
          <div className="tb-proj-summary-card">
            <div className="tb-proj-left">
              <img src={plantImage} alt="Plant Construction" className="tb-proj-thumbnail" />
              <div className="tb-proj-info">
                <div className="tb-proj-title-row">
                  <h2 className="tb-proj-title">{activeProject ? activeProject.prjNm : "No Projects Found"}</h2>
                  <span className="tb-badge live">{activeProject ? (activeProject.prjSts || "LIVE") : "N/A"}</span>
                  <span className="tb-badge proj-code">{activeProject ? activeProject.prjCd : "N/A"}</span>
                </div>
                <div className="tb-proj-meta-row">
                  <div className="tb-proj-meta-item">
                    <User size={13} />
                    <span>{activePlant || "N/A"}</span>
                  </div>
                  <div className="tb-proj-meta-item">
                    <Layers size={13} />
                    <span>Department: {activeDept || "Projects"}</span>
                  </div>
                  <div className="tb-proj-meta-item">
                    <CalendarIcon size={13} />
                    <span>{activeProject ? `${activeProject.stDt || "N/A"} to ${activeProject.endDt || "N/A"}` : "N/A"}</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Metrics */}
            <div className="tb-proj-metrics">
              <div className="tb-proj-metric-item" onClick={() => setSelectedStatus("All Statuses")} style={{ cursor: "pointer" }}>
                <span className="tb-proj-metric-label">Total Tasks</span>
                <span className="tb-proj-metric-val">{totalTasksCount}</span>
              </div>
              <div className="tb-proj-metric-item completed" onClick={() => setSelectedStatus("Completed")} style={{ cursor: "pointer" }}>
                <span className="tb-proj-metric-label">Completed</span>
                <span className="tb-proj-metric-val">
                  {completedCount} <span>({completedPct}%)</span>
                </span>
              </div>
              <div className="tb-proj-metric-item in-progress" onClick={() => setSelectedStatus("In Progress")} style={{ cursor: "pointer" }}>
                <span className="tb-proj-metric-label">In Progress</span>
                <span className="tb-proj-metric-val">
                  {inProgressCount} <span>({inProgressPct}%)</span>
                </span>
              </div>
              <div className="tb-proj-metric-item not-started" onClick={() => setSelectedStatus("Not Started")} style={{ cursor: "pointer" }}>
                <span className="tb-proj-metric-label">Not Started</span>
                <span className="tb-proj-metric-val">
                  {notStartedCount} <span>({notStartedPct}%)</span>
                </span>
              </div>
              <div className="tb-proj-metric-item overdue" onClick={() => setSelectedStatus("Overdue")} style={{ cursor: "pointer" }}>
                <span className="tb-proj-metric-label">Overdue</span>
                <span className="tb-proj-metric-val">
                  {overdueCount} <span>({overduePct}%)</span>
                </span>
              </div>
            </div>
          </div>

          {/* ===== ROW 1: Filter Dropdowns + Search ===== */}
          <div className="tb-filter-toolbar">
            <div className="tb-filters-group">
              <div className="tb-filter-field">
                <label>Project</label>
                <select className="tb-select-input" value={selectedProjectId} onChange={e => {
                  setSelectedProjectId(e.target.value);
                  setSelectedMilestone("All Milestones");
                }}>
                  <option value="All">All Projects</option>
                  {projectsRaw.map(p => (
                    <option key={p.prjId} value={p.prjId}>{p.prjCd} - {p.prjNm}</option>
                  ))}
                </select>
              </div>
              <div className="tb-filter-field">
                <label>Milestone</label>
                <select className="tb-select-input" value={selectedMilestone} onChange={e => setSelectedMilestone(e.target.value)}>
                  <option value="All Milestones">All Milestones</option>
                  {derivedMilestones.map(m => (
                    <option key={m} value={m}>{m}</option>
                  ))}
                </select>
              </div>
              <div className="tb-filter-field">
                <label>Assignee</label>
                <select className="tb-select-input" value={selectedAssignee} onChange={e => setSelectedAssignee(e.target.value)}>
                  <option value="All Employees">All Employees</option>
                  {ASSIGNEES.map(a => (
                    <option key={a.name} value={a.name}>{a.name}</option>
                  ))}
                </select>
              </div>
              <div className="tb-filter-field">
                <label>Task Type</label>
                <select className="tb-select-input" value={selectedTaskType} onChange={e => setSelectedTaskType(e.target.value)}>
                  <option value="All">All</option>
                  <option value="Internal">Internal</option>
                  <option value="External">External</option>
                </select>
              </div>
              <div className="tb-filter-field">
                <label>Priority</label>
                <select className="tb-select-input" value={selectedPriority} onChange={e => setSelectedPriority(e.target.value)}>
                  <option value="All">All</option>
                  <option value="High">High</option>
                  <option value="Medium">Medium</option>
                  <option value="Low">Low</option>
                  <option value="Completed">Completed</option>
                  <option value="Overdue">Overdue</option>
                </select>
              </div>
              <div className="tb-filter-field">
                <label>Status</label>
                <select className="tb-select-input" value={selectedStatus} onChange={e => setSelectedStatus(e.target.value)}>
                  <option value="All Statuses">All Statuses</option>
                  <option value="Not Started">Not Started</option>
                  <option value="In Progress">In Progress</option>
                  <option value="Under Review">Under Review</option>
                  <option value="Completed">Completed</option>
                  <option value="Overdue">Overdue</option>
                </select>
              </div>

              {/* Search bar */}
              <div className="tb-filter-field" style={{ minWidth: "180px", flex: "1.5" }}>
                <label style={{ opacity: 0 }}>Search</label>
                <div className="tb-search-box-wrap" style={{ width: "100%" }}>
                  <Search size={15} className="tb-search-box-icon" />
                  <input
                    type="text"
                    placeholder="Search Task..."
                    value={searchQuery}
                    onChange={e => setSearchQuery(e.target.value)}
                  />
                </div>
              </div>
            </div>

            <div className="tb-toolbar-actions" style={{ alignSelf: "flex-end", height: "38px", display: "flex", alignItems: "center" }}>
              <button className="tb-btn-white"><SlidersHorizontal size={14} /> Filters</button>
              <button className="tb-btn-white"><Grid size={14} /> View</button>
            </div>
          </div>

          {/* ===== ROW 2: Status Tab Pills ===== */}
          <div className="tb-status-tabs">
            {[
              { label: "All",          value: "All Statuses",   color: "#64748b" },
              { label: "Not Started",  value: "Not Started",    color: "#2563eb" },
              { label: "In Progress",  value: "In Progress",    color: "#f97316" },
              { label: "Under Review", value: "Under Review",   color: "#a855f7" },
              { label: "Completed",    value: "Completed",      color: "#16a34a" },
              { label: "Overdue",      value: "Overdue",        color: "#ef4444" },
            ].map(tab => (
              <button
                key={tab.value}
                className={`tb-status-tab ${selectedStatus === tab.value ? "active" : ""}`}
                style={selectedStatus === tab.value ? { borderColor: tab.color, color: tab.color, background: tab.color + "12" } : {}}
                onClick={() => {
                  setSelectedStatus(tab.value);
                  setTimeout(() => scrollToCol(tab.value), 30);
                }}
              >
                <span
                  className="tb-status-tab-dot"
                  style={{ background: tab.color }}
                />
                {tab.label}
                <span
                  className="tb-status-tab-count"
                  style={selectedStatus === tab.value ? { background: tab.color, color: "#fff" } : {}}
                >
                  {tab.value === "All Statuses"
                    ? tasks.length
                    : tasks.filter(t => t.status === tab.value).length}
                </span>
              </button>
            ))}
          </div>

          {/* Kanban Columns Board */}
          <div
            className={`tb-board${selectedStatus !== "All Statuses" ? " tb-board-single" : ""}`}
            ref={boardRef}
          >
            {/* Column 1: Not Started */}
            {(selectedStatus === "All Statuses" || selectedStatus === "Not Started") && (
            <div
              ref={colRefs["Not Started"]}
              className={`tb-col not-started ${draggedOverCol === "Not Started" ? "drag-over" : ""}`}
              onDragOver={e => handleDragOver(e, "Not Started")}
              onDragLeave={handleDragLeave}
              onDrop={e => handleDrop(e, "Not Started")}
            >
              <div className="tb-col-header">
                <div className="tb-col-title-wrap">
                  <h3 className="tb-col-title">Not Started</h3>
                  <span className="tb-col-badge">{getTasksByStatus("Not Started").length}</span>
                </div>
                <button className="tb-btn-add-circle" title="Add Task" onClick={() => openAddTaskModal("Not Started")}>
                  <Plus size={16} />
                </button>
              </div>
              <div className="tb-cards-container">
                {getTasksByStatus("Not Started").map(task => (
                  <div
                    key={task.id}
                    className="tb-card"
                    draggable
                    onDragStart={e => handleDragStart(e, task.id)}
                    onClick={() => handleCardClick(task)}
                  >
                    <div className="tb-card-header">
                      <span className="tb-card-id">{task.id}</span>
                      <span className={`tb-card-prio ${task.priority.toLowerCase()}`}>{task.priority}</span>
                    </div>
                    <h4 className="tb-card-title">{task.title}</h4>
                    <p className="tb-card-subtitle">{task.milestone}</p>
                    <div className="tb-card-footer">
                      <div className="tb-card-assignee">
                        <div
                          className="tb-card-avatar"
                          style={{
                            backgroundColor: getAssigneeInfo(task.assignee).bg,
                            color: getAssigneeInfo(task.assignee).color
                          }}
                        >
                          {getInitials(task.assignee)}
                        </div>
                        <span className="tb-card-name">{task.assignee}</span>
                      </div>
                      <div className="tb-card-date-info">
                        <CalendarIcon size={12} />
                        <span>{formatDate(task.dueDate)}</span>
                      </div>
                      {task.subtasksCount > 0 && (
                        <div className="tb-card-subtasks-count">
                          <CheckSquare size={11} />
                          <span>{task.subtasksCompleted}/{task.subtasksCount}</span>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
              <button className="tb-btn-add-task-col" onClick={() => openAddTaskModal("Not Started")}>
                + Add Task
              </button>
            </div>
            )}

            {/* Column 2: In Progress */}
            {(selectedStatus === "All Statuses" || selectedStatus === "In Progress") && (
            <div
              ref={colRefs["In Progress"]}
              className={`tb-col in-progress ${draggedOverCol === "In Progress" ? "drag-over" : ""}`}
              onDragOver={e => handleDragOver(e, "In Progress")}
              onDragLeave={handleDragLeave}
              onDrop={e => handleDrop(e, "In Progress")}
            >
              <div className="tb-col-header">
                <div className="tb-col-title-wrap">
                  <h3 className="tb-col-title">In Progress</h3>
                  <span className="tb-col-badge">{getTasksByStatus("In Progress").length}</span>
                </div>
                <button className="tb-btn-add-circle" title="Add Task" onClick={() => openAddTaskModal("In Progress")}>
                  <Plus size={16} />
                </button>
              </div>
              <div className="tb-cards-container">
                {getTasksByStatus("In Progress").map(task => (
                  <div
                    key={task.id}
                    className="tb-card"
                    draggable
                    onDragStart={e => handleDragStart(e, task.id)}
                    onClick={() => handleCardClick(task)}
                  >
                    <div className="tb-card-header">
                      <span className="tb-card-id">{task.id}</span>
                      <span className={`tb-card-prio ${task.priority.toLowerCase()}`}>{task.priority}</span>
                    </div>
                    <h4 className="tb-card-title">{task.title}</h4>
                    <p className="tb-card-subtitle">{task.milestone}</p>
                    {task.progress !== undefined && (
                      <div className="tb-card-progress">
                        <div className="tb-card-progress-header">
                          <span style={{ fontSize: '10px', color: '#64748b' }}>Progress</span>
                          <span style={{ fontSize: '11px', fontWeight: '700' }}>{task.progress}%</span>
                        </div>
                        <div className="tb-card-progress-bar">
                          <div className="tb-card-progress-fill in-progress" style={{ width: `${task.progress}%` }}></div>
                        </div>
                      </div>
                    )}
                    <div className="tb-card-footer">
                      <div className="tb-card-assignee">
                        <div
                          className="tb-card-avatar"
                          style={{
                            backgroundColor: getAssigneeInfo(task.assignee).bg,
                            color: getAssigneeInfo(task.assignee).color
                          }}
                        >
                          {getInitials(task.assignee)}
                        </div>
                        <span className="tb-card-name">{task.assignee}</span>
                      </div>
                      <div className="tb-card-date-info">
                        <CalendarIcon size={12} />
                        <span>{formatDate(task.dueDate)}</span>
                      </div>
                      {task.subtasksCount > 0 && (
                        <div className="tb-card-subtasks-count">
                          <CheckSquare size={11} />
                          <span>{task.subtasksCompleted}/{task.subtasksCount}</span>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
              <button className="tb-btn-add-task-col" onClick={() => openAddTaskModal("In Progress")}>
                + Add Task
              </button>
            </div>
            )}

            {/* Column 3: Under Review */}
            {(selectedStatus === "All Statuses" || selectedStatus === "Under Review") && (
            <div
              ref={colRefs["Under Review"]}
              className={`tb-col under-review ${draggedOverCol === "Under Review" ? "drag-over" : ""}`}
              onDragOver={e => handleDragOver(e, "Under Review")}
              onDragLeave={handleDragLeave}
              onDrop={e => handleDrop(e, "Under Review")}
            >
              <div className="tb-col-header">
                <div className="tb-col-title-wrap">
                  <h3 className="tb-col-title">Under Review</h3>
                  <span className="tb-col-badge">{getTasksByStatus("Under Review").length}</span>
                </div>
                <button className="tb-btn-add-circle" title="Add Task" onClick={() => openAddTaskModal("Under Review")}>
                  <Plus size={16} />
                </button>
              </div>
              <div className="tb-cards-container">
                {getTasksByStatus("Under Review").map(task => (
                  <div
                    key={task.id}
                    className="tb-card"
                    draggable
                    onDragStart={e => handleDragStart(e, task.id)}
                    onClick={() => handleCardClick(task)}
                  >
                    <div className="tb-card-header">
                      <span className="tb-card-id">{task.id}</span>
                      <span className={`tb-card-prio ${task.priority.toLowerCase()}`}>{task.priority}</span>
                    </div>
                    <h4 className="tb-card-title">{task.title}</h4>
                    <p className="tb-card-subtitle">{task.milestone}</p>
                    {task.progress !== undefined && (
                      <div className="tb-card-progress">
                        <div className="tb-card-progress-header">
                          <span style={{ fontSize: '10px', color: '#64748b' }}>Progress</span>
                          <span style={{ fontSize: '11px', fontWeight: '700' }}>{task.progress}%</span>
                        </div>
                        <div className="tb-card-progress-bar">
                          <div className="tb-card-progress-fill under-review" style={{ width: `${task.progress}%`, backgroundColor: '#a855f7' }}></div>
                        </div>
                      </div>
                    )}
                    <div className="tb-card-footer">
                      <div className="tb-card-assignee">
                        <div
                          className="tb-card-avatar"
                          style={{
                            backgroundColor: getAssigneeInfo(task.assignee).bg,
                            color: getAssigneeInfo(task.assignee).color
                          }}
                        >
                          {getInitials(task.assignee)}
                        </div>
                        <span className="tb-card-name">{task.assignee}</span>
                      </div>
                      <div className="tb-card-date-info">
                        <CalendarIcon size={12} />
                        <span>{formatDate(task.dueDate)}</span>
                      </div>
                      {task.subtasksCount > 0 && (
                        <div className="tb-card-subtasks-count">
                          <CheckSquare size={11} />
                          <span>{task.subtasksCompleted}/{task.subtasksCount}</span>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
              <button className="tb-btn-add-task-col" onClick={() => openAddTaskModal("Under Review")}>
                + Add Task
              </button>
            </div>
            )}

            {/* Column 4: Completed */}
            {(selectedStatus === "All Statuses" || selectedStatus === "Completed") && (
            <div
              ref={colRefs["Completed"]}
              className={`tb-col completed ${draggedOverCol === "Completed" ? "drag-over" : ""}`}
              onDragOver={e => handleDragOver(e, "Completed")}
              onDragLeave={handleDragLeave}
              onDrop={e => handleDrop(e, "Completed")}
            >
              <div className="tb-col-header">
                <div className="tb-col-title-wrap">
                  <h3 className="tb-col-title">Completed</h3>
                  <span className="tb-col-badge">{getTasksByStatus("Completed").length}</span>
                </div>
                <button className="tb-btn-add-circle" title="Add Task" onClick={() => openAddTaskModal("Completed")}>
                  <Plus size={16} />
                </button>
              </div>
              <div className="tb-cards-container">
                {getTasksByStatus("Completed").map(task => (
                  <div
                    key={task.id}
                    className="tb-card"
                    draggable
                    onDragStart={e => handleDragStart(e, task.id)}
                    onClick={() => handleCardClick(task)}
                  >
                    <div className="tb-card-header">
                      <span className="tb-card-id completed">{task.id}</span>
                      <span className="tb-card-prio completed">COMPLETED</span>
                    </div>
                    <h4 className="tb-card-title">{task.title}</h4>
                    <p className="tb-card-subtitle">{task.milestone}</p>
                    {task.progress !== undefined && (
                      <div className="tb-card-progress">
                        <div className="tb-card-progress-header">
                          <span style={{ fontSize: '10px', color: '#64748b' }}>Progress</span>
                          <span style={{ fontSize: '11px', fontWeight: '700', color: '#16a34a' }}>100%</span>
                        </div>
                        <div className="tb-card-progress-bar">
                          <div className="tb-card-progress-fill completed" style={{ width: `100%`, backgroundColor: '#16a34a' }}></div>
                        </div>
                      </div>
                    )}
                    <div className="tb-card-footer">
                      <div className="tb-card-assignee">
                        <div
                          className="tb-card-avatar"
                          style={{
                            backgroundColor: getAssigneeInfo(task.assignee).bg,
                            color: getAssigneeInfo(task.assignee).color
                          }}
                        >
                          {getInitials(task.assignee)}
                        </div>
                        <span className="tb-card-name">{task.assignee}</span>
                      </div>
                      <div className="tb-card-date-info">
                        <CalendarIcon size={12} />
                        <span>{formatDate(task.dueDate)}</span>
                      </div>
                      {task.subtasksCount > 0 && (
                        <div className="tb-card-subtasks-count">
                          <CheckSquare size={11} />
                          <span>{task.subtasksCompleted}/{task.subtasksCount}</span>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
              <button className="tb-btn-add-task-col" onClick={() => openAddTaskModal("Completed")}>
                + Add Task
              </button>
            </div>
            )}

            {/* Column 5: Overdue */}
            {(selectedStatus === "All Statuses" || selectedStatus === "Overdue") && (
            <div
              ref={colRefs["Overdue"]}
              className={`tb-col overdue ${draggedOverCol === "Overdue" ? "drag-over" : ""}`}
              onDragOver={e => handleDragOver(e, "Overdue")}
              onDragLeave={handleDragLeave}
              onDrop={e => handleDrop(e, "Overdue")}
            >
              <div className="tb-col-header">
                <div className="tb-col-title-wrap">
                  <h3 className="tb-col-title">Overdue</h3>
                  <span className="tb-col-badge">{getTasksByStatus("Overdue").length}</span>
                </div>
                <button className="tb-btn-add-circle" title="Add Task" onClick={() => openAddTaskModal("Overdue")}>
                  <Plus size={16} />
                </button>
              </div>
              <div className="tb-cards-container">
                {getTasksByStatus("Overdue").map(task => (
                  <div
                    key={task.id}
                    className="tb-card"
                    draggable
                    onDragStart={e => handleDragStart(e, task.id)}
                    onClick={() => handleCardClick(task)}
                  >
                    <div className="tb-card-header">
                      <span className="tb-card-id overdue">{task.id}</span>
                      <span className="tb-card-prio overdue">OVERDUE</span>
                    </div>
                    <h4 className="tb-card-title">{task.title}</h4>
                    <p className="tb-card-subtitle">{task.milestone}</p>
                    {task.progress !== undefined && (
                      <div className="tb-card-progress">
                        <div className="tb-card-progress-header">
                          <span style={{ fontSize: '10px', color: '#64748b' }}>Progress</span>
                          <span style={{ fontSize: '11px', fontWeight: '700', color: '#ef4444' }}>{task.progress}%</span>
                        </div>
                        <div className="tb-card-progress-bar">
                          <div className="tb-card-progress-fill overdue" style={{ width: `${task.progress}%`, backgroundColor: '#ef4444' }}></div>
                        </div>
                      </div>
                    )}
                    <div className="tb-card-footer">
                      <div className="tb-card-assignee">
                        <div
                          className="tb-card-avatar"
                          style={{
                            backgroundColor: getAssigneeInfo(task.assignee).bg,
                            color: getAssigneeInfo(task.assignee).color
                          }}
                        >
                          {getInitials(task.assignee)}
                        </div>
                        <span className="tb-card-name">{task.assignee}</span>
                      </div>
                      <div className="tb-card-date-info urgent">
                        <CalendarIcon size={12} />
                        <span>{formatDate(task.dueDate)}</span>
                      </div>
                      {task.subtasksCount > 0 && (
                        <div className="tb-card-subtasks-count">
                          <CheckSquare size={11} />
                          <span>{task.subtasksCompleted}/{task.subtasksCount}</span>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
              <button className="tb-btn-add-task-col" onClick={() => openAddTaskModal("Overdue")}>
                + Add Task
              </button>
            </div>
            )}
          </div>

          {/* Bottom Legend */}
          <div className="tb-legend-bar">
            <div className="tb-legend-left">
              <div className="tb-legend-section">
                <span className="tb-legend-section-title">Priority:</span>
                <div className="tb-legend-item">
                  <span className="tb-dot high"></span>
                  <span>High</span>
                </div>
                <div className="tb-legend-item">
                  <span className="tb-dot medium"></span>
                  <span>Medium</span>
                </div>
                <div className="tb-legend-item">
                  <span className="tb-dot low"></span>
                  <span>Low</span>
                </div>
              </div>

              <div style={{ width: '1px', height: '16px', backgroundColor: '#e2e8f0' }}></div>

              <div className="tb-legend-section">
                <span className="tb-legend-section-title">Task Type:</span>
                <div className="tb-legend-item">
                  <span className="tb-dot internal"></span>
                  <span>Internal</span>
                </div>
                <div className="tb-legend-item">
                  <span className="tb-dot external"></span>
                  <span>External</span>
                </div>
              </div>
            </div>

            <div className="tb-legend-right">
              <Hand size={15} />
              <span>Drag and drop tasks to update status</span>
            </div>
          </div>
        </main>
      </div>

      {/* ====== ADD TASK MODAL ====== */}
      {showAddModal && (
        <div className="tb-modal-overlay" onClick={() => setShowAddModal(false)}>
          <form className="tb-modal" onClick={e => e.stopPropagation()} onSubmit={handleCreateTask}>
            <div className="tb-modal-header">
              <h3>Create Task in: {targetColumn}</h3>
              <button type="button" className="tb-modal-close-btn" onClick={() => setShowAddModal(false)}><X size={18} /></button>
            </div>
            <div className="tb-modal-body">
              <div className="tb-form-group">
                <label>Task Title *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Foundation Grouting"
                  value={newTitle}
                  onChange={e => setNewTitle(e.target.value)}
                />
              </div>

              <div className="tb-form-group">
                <label>Milestone</label>
                <select value={newMilestone} onChange={e => setNewMilestone(e.target.value)}>
                  {milestonesList.map(m => (
                    <option key={m} value={m}>{m}</option>
                  ))}
                </select>
              </div>

              <div className="tb-form-row">
                <div className="tb-form-group">
                  <label>Assignee</label>
                  <select value={newAssignee} onChange={e => setNewAssignee(e.target.value)}>
                    {employeesList.length > 0 ? (
                      employeesList.map(emp => {
                        const fullName = `${emp.firstName} ${emp.lastName}`;
                        return <option key={emp.empId} value={fullName}>{fullName}</option>;
                      })
                    ) : (
                      ASSIGNEES.map(a => (
                        <option key={a.name} value={a.name}>{a.name}</option>
                      ))
                    )}
                  </select>
                </div>
                <div className="tb-form-group">
                  <label>Task Type</label>
                  <select value={newTaskType} onChange={e => setNewTaskType(e.target.value)}>
                    <option value="Internal">Internal</option>
                    <option value="External">External</option>
                  </select>
                </div>
              </div>

              <div className="tb-form-row">
                <div className="tb-form-group">
                  <label>Priority</label>
                  <select value={newPriority} onChange={e => setNewPriority(e.target.value)} disabled={targetColumn === "Completed" || targetColumn === "Overdue"}>
                    <option value="High">High</option>
                    <option value="Medium">Medium</option>
                    <option value="Low">Low</option>
                  </select>
                </div>
                <div className="tb-form-group">
                  <label>Status</label>
                  <select value={targetColumn} onChange={e => setTargetColumn(e.target.value)}>
                    <option value="Not Started">Not Started</option>
                    <option value="In Progress">In Progress</option>
                    <option value="Under Review">Under Review</option>
                    <option value="Completed">Completed</option>
                    <option value="Overdue">Overdue</option>
                  </select>
                </div>
              </div>

              <div className="tb-form-row">
                <div className="tb-form-group">
                  <label>Subtasks Count</label>
                  <input
                    type="number"
                    min="0"
                    max="10"
                    value={newSubtasksCount}
                    onChange={e => setNewSubtasksCount(e.target.value)}
                  />
                </div>
                <div className="tb-form-group">
                  <label>Due Date *</label>
                  <input
                    type="date"
                    required
                    value={newDueDate}
                    onChange={e => setNewDueDate(e.target.value)}
                  />
                </div>
              </div>

              <div className="tb-form-group">
                <label>Description</label>
                <input
                  type="text"
                  placeholder="Task scope details..."
                  value={newDescription}
                  onChange={e => setNewDescription(e.target.value)}
                />
              </div>
            </div>
            <div className="tb-modal-footer">
              <button type="button" className="tb-btn-secondary" onClick={() => setShowAddModal(false)}>Cancel</button>
              <button type="submit" className="tb-btn-primary">Create Task</button>
            </div>
          </form>
        </div>
      )}

      {/* ====== DETAIL MODAL ====== */}
      {showDetailModal && selectedTask && (
        <div className="tb-modal-overlay" onClick={() => setShowDetailModal(false)}>
          <div className="tb-modal" onClick={e => e.stopPropagation()}>
            <div className="tb-modal-header">
              <h3>Task Details: {selectedTask.id}</h3>
              <button className="tb-modal-close-btn" onClick={() => setShowDetailModal(false)}><X size={18} /></button>
            </div>
            <div className="tb-modal-body">
              <div className="tb-modal-detail-row">
                <span className="tb-modal-detail-label">Title</span>
                <span className="tb-modal-detail-value">{selectedTask.title}</span>
              </div>
              <div className="tb-modal-detail-row">
                <span className="tb-modal-detail-label">Milestone</span>
                <span className="tb-modal-detail-value">{selectedTask.milestone}</span>
              </div>
              <div className="tb-form-row">
                <div className="tb-modal-detail-row">
                  <span className="tb-modal-detail-label">Assignee</span>
                  <span className="tb-modal-detail-value">{selectedTask.assignee}</span>
                </div>
                <div className="tb-modal-detail-row">
                  <span className="tb-modal-detail-label">Status</span>
                  <span className="tb-modal-detail-value" style={{
                    color: selectedTask.status === "Completed" ? "#16a34a" : selectedTask.status === "Overdue" ? "#dc2626" : "#2563eb",
                    textTransform: "uppercase"
                  }}>{selectedTask.status}</span>
                </div>
              </div>

              <div className="tb-form-row">
                <div className="tb-modal-detail-row">
                  <span className="tb-modal-detail-label">Priority</span>
                  <span className="tb-modal-detail-value">{selectedTask.priority}</span>
                </div>
                <div className="tb-modal-detail-row">
                  <span className="tb-modal-detail-label">Type</span>
                  <span className="tb-modal-detail-value">{selectedTask.taskType}</span>
                </div>
              </div>

              <div className="tb-modal-detail-row">
                <span className="tb-modal-detail-label">Due Date</span>
                <span className="tb-modal-detail-value">{formatDate(selectedTask.dueDate)}</span>
              </div>

              {selectedTask.description && (
                <div className="tb-modal-detail-row">
                  <span className="tb-modal-detail-label">Description</span>
                  <span className="tb-modal-detail-value" style={{ fontWeight: "normal", fontSize: "13px", color: "#475569" }}>
                    {selectedTask.description}
                  </span>
                </div>
              )}

              {selectedTask.subtasksCount > 0 && (
                <div className="tb-modal-detail-row">
                  <span className="tb-modal-detail-label">Subtasks Progress</span>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '8px', cursor: 'pointer' }} onClick={() => toggleSubtask()}>
                    <div style={{
                      width: "16px",
                      height: "16px",
                      border: "2px solid #cbd5e1",
                      borderRadius: "4px",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      backgroundColor: selectedTask.subtasksCompleted === selectedTask.subtasksCount ? "#10b981" : "transparent"
                    }}>
                      {selectedTask.subtasksCompleted === selectedTask.subtasksCount && <Check size={12} color="white" />}
                    </div>
                    <span style={{ fontSize: '13px', fontWeight: '600' }}>
                      Completed {selectedTask.subtasksCompleted} of {selectedTask.subtasksCount} (Click to toggle)
                    </span>
                  </div>
                </div>
              )}
            </div>
            <div className="tb-modal-footer" style={{ justifyContent: "space-between" }}>
              <button className="tb-btn-danger" style={{ display: 'flex', alignItems: 'center', gap: '6px' }} onClick={() => handleDeleteTask(selectedTask.id)}>
                <Trash2 size={14} /> Delete
              </button>
              <div style={{ display: 'flex', gap: '10px' }}>
                <button className="tb-btn-secondary" onClick={(e) => openEditProgressModal(selectedTask, e)}>Update Progress</button>
                <button className="tb-btn-primary" onClick={() => setShowDetailModal(false)}>Close</button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ====== UPDATE PROGRESS MODAL ====== */}
      {showEditModal && selectedTask && (
        <div className="tb-modal-overlay" onClick={() => setShowEditModal(false)}>
          <form className="tb-modal" onClick={e => e.stopPropagation()} onSubmit={handleSaveProgress}>
            <div className="tb-modal-header">
              <h3>Update Task: {selectedTask.id}</h3>
              <button type="button" className="tb-modal-close-btn" onClick={() => setShowEditModal(false)}><X size={18} /></button>
            </div>
            <div className="tb-modal-body">
              <div className="tb-form-row">
                <div className="tb-form-group">
                  <label>Priority</label>
                  <select value={editPriority} onChange={e => setEditPriority(e.target.value)} disabled={editStatus === "Completed" || editStatus === "Overdue"}>
                    <option value="High">High</option>
                    <option value="Medium">Medium</option>
                    <option value="Low">Low</option>
                  </select>
                </div>
                <div className="tb-form-group">
                  <label>Status</label>
                  <select value={editStatus} onChange={e => {
                    setEditStatus(e.target.value);
                    if (e.target.value === "Completed") setEditProgress(100);
                    else if (e.target.value === "Not Started") setEditProgress(0);
                  }}>
                    <option value="Not Started">Not Started</option>
                    <option value="In Progress">In Progress</option>
                    <option value="Under Review">Under Review</option>
                    <option value="Completed">Completed</option>
                    <option value="Overdue">Overdue</option>
                  </select>
                </div>
              </div>

              {editStatus !== "Completed" && editStatus !== "Not Started" && (
                <div className="tb-form-group" style={{ marginTop: "12px" }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', fontWeight: '600' }}>
                    <label>Progress</label>
                    <span>{editProgress}%</span>
                  </div>
                  <input
                    type="range"
                    min="0"
                    max="100"
                    step="5"
                    value={editProgress}
                    onChange={e => setEditProgress(e.target.value)}
                    style={{ cursor: "pointer", width: "100%" }}
                  />
                </div>
              )}
            </div>
            <div className="tb-modal-footer">
              <button type="button" className="tb-btn-secondary" onClick={() => setShowEditModal(false)}>Cancel</button>
              <button type="submit" className="tb-btn-primary">Save Changes</button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
};

export default TaskBoard;
