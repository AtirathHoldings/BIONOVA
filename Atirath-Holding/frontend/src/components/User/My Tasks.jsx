import React, { useState, useEffect } from "react";
import { useLocation } from "react-router-dom";
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
  RotateCw,
  ChevronLeft,
  ChevronRight,
  Check,
  Undo,
  Undo2,
  Redo2,
  ClipboardList,
  Layers,
  Clock,
  RefreshCcw,
  RefreshCw,
  Loader2,
  Filter,
  User,
  Users,
  Calendar,
  Flag,
  FileText,
  CheckSquare,
  Clock as ClockIcon,
  AlertTriangle,
  ArrowLeft,
  UserCheck,
  UserX,
  UserPlus,
  Briefcase,
  ListChecks,
  MessageSquare,
  Paperclip,
  History,
  MoreVertical
} from "lucide-react";
import "../../styles/MyTasks.css";
import { apiGet, apiPut, apiPatch, apiPost } from "../../utils/api";

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || "";

// ============================================
// CONSTANTS - COLORS & STATUS
// ============================================

const ReassignIcon = ({ size = 16, color = "#4F46E5", className = "", style = {} }) => (
  <svg 
    width={size} 
    height={size} 
    viewBox="0 0 24 24" 
    fill="none" 
    stroke={color} 
    strokeWidth="2.5" 
    strokeLinecap="round" 
    strokeLinejoin="round" 
    className={className}
    style={{ display: "inline-block", verticalAlign: "middle", ...style }}
  >
    <polyline points="9 14 4 18 9 22" />
    <path d="M4 18h11a5 5 0 0 0 0-10H8" />
  </svg>
);

const PROGRESS_COLORS = {
  "OPEN": { bg: "#DBEAFE", color: "#2563EB", label: "OPEN" },
  "DRAFT": { bg: "#F3F4F6", color: "#9CA3AF", label: "DRAFT" },
  "WIP": { bg: "#FEF3C7", color: "#F59E0B", label: "WORK IN PROGRESS" },
  "HOLD": { bg: "#EDE9FE", color: "#7C3AED", label: "HOLD" },
  "COMPLETED": { bg: "#DCFCE7", color: "#16A34A", label: "CLOSED" },
  "CLOSED": { bg: "#DCFCE7", color: "#16A34A", label: "CLOSED" }
};

const PRIORITY_COLORS = {
  "Low": { bg: "#DCFCE7", color: "#22C55E" },
  "Normal": { bg: "#DBEAFE", color: "#3B82F6" },
  "Medium": { bg: "#FEF3C7", color: "#F59E0B" },
  "High": { bg: "#FEE2E2", color: "#EF4444" },
  "Critical": { bg: "#FEE2E2", color: "#B91C1C" },
  "Atmost Critical": { bg: "#FEE2E2", color: "#7F1D1D" },
  "Rework": { bg: "#FFF7ED", color: "#F97316" },
  "REWORK": { bg: "#FFF7ED", color: "#F97316" },
  "Reassigned": { bg: "#EEF2FF", color: "#4F46E5" },
  "REASSIGN": { bg: "#EEF2FF", color: "#4F46E5" }
};

const PROCESS_COLORS = {
  "PENDING_REVIEWER": { color: "#8B5CF6", icon: Eye, title: "Under Review" },
  "PENDING_APPROVER": { color: "#8B5CF6", icon: Eye, title: "Under Review" },
  "REWORK": { color: "#F97316", icon: RefreshCw, title: "Rework" },
  "REASSIGN": { color: "#4F46E5", icon: ReassignIcon, title: "Reassign" }
};

const TIME_COLORS = {
  "Lead": { color: "#22C55E", icon: Clock, title: "Lead" },
  "On Time": { color: "#3B82F6", icon: Clock, title: "On Time" },
  "Due Today": { color: "#F59E0B", icon: Clock, title: "Due Today" },
  "Overdue": { color: "#EF4444", icon: Clock, title: "Overdue" },
  "Lag": { color: "#DC2626", icon: Clock, title: "Lag" }
};

// ============================================
// HELPER FUNCTIONS
// ============================================

const calculateTimeStatus = (task) => {
  if (!task) return null;
  
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  const rawSts = (task.taskSts || task.status || task.rawStatus || "").toString().toUpperCase();
  const isClosed = rawSts === "COMPLETED" || rawSts === "CLOSED" || rawSts === "DONE" || task.progress === 100;
  
  const dueDateStr = task.endDt || task.dueDate || task.endDate || task.end_dt;
  const completedDateStr = task.actCmpDt || task.completedDate || task.act_cmp_dt;
  
  const dueDate = dueDateStr ? new Date(dueDateStr) : null;
  const completedDate = completedDateStr ? new Date(completedDateStr) : null;
  
  // ONLY for closed tasks — show Lead / Lag / On Time
  if (isClosed) {
    if (!dueDate) return { status: "On Time", color: "#3B82F6", icon: Clock, title: "On Time" };
    dueDate.setHours(0, 0, 0, 0);
    const refDate = completedDate ? new Date(completedDate) : today;
    refDate.setHours(0, 0, 0, 0);
    if (refDate < dueDate) return { status: "Lead", color: "#22C55E", icon: Clock, title: "Lead" };
    if (refDate.getTime() === dueDate.getTime()) return { status: "On Time", color: "#3B82F6", icon: Clock, title: "On Time" };
    return { status: "Lag", color: "#DC2626", icon: Clock, title: "Lag" };
  }
  
  // For open / non-closed tasks: ONLY show Due Today or Overdue. Do NOT show On Time / Lead / Lag!
  if (dueDate) {
    dueDate.setHours(0, 0, 0, 0);
    if (today.getTime() === dueDate.getTime()) return { status: "Due Today", color: "#F59E0B", icon: Clock, title: "Due Today" };
    if (today > dueDate) return { status: "Overdue", color: "#EF4444", icon: Clock, title: "Overdue" };
  }
  
  return null;
};

// ============================================
// GET EMPLOYEE DETAILS
// ============================================

const getEmployeeName = (empId, employeesList) => {
  if (!empId) return "Unknown";
  if (!employeesList || employeesList.length === 0) {
    return `User ${empId}`;
  }
  
  const emp = employeesList.find(e => {
    const target = String(empId).trim();
    return String(e.empId).trim() === target || 
           String(e.employeeId).trim() === target || 
           String(e.employeeCode).trim() === target || 
           String(e.id).trim() === target || 
           String(e._id).trim() === target || 
           String(e.employee_code).trim() === target || 
           String(e.empCode).trim() === target ||
           String(e.userId).trim() === target;
  });
  
  if (!emp) return `User ${empId}`;
  
  if (emp.employeeName) return emp.employeeName;
  if (emp.fullName) return emp.fullName;
  if (emp.name) return emp.name;
  if (emp.employee_name) return emp.employee_name;
  if (emp.empName) return emp.empName;
  if (emp.fstNm && emp.lstNm) return `${emp.fstNm} ${emp.lstNm}`.trim();
  if (emp.firstName && emp.lastName) return `${emp.firstName} ${emp.lastName}`.trim();
  if (emp.first_name && emp.last_name) return `${emp.first_name} ${emp.last_name}`.trim();
  if (emp.fstNm) return emp.fstNm;
  if (emp.firstName) return emp.firstName;
  if (emp.first_name) return emp.first_name;
  if (emp.displayName) return emp.displayName;
  if (emp.username) return emp.username;
  if (emp.email) return emp.email.split('@')[0];
  
  return emp.empCode || emp.employee_code || `User ${empId}`;
};

const getEmployeeInitials = (empId, employeesList) => {
  const name = getEmployeeName(empId, employeesList);
  if (!name || name === "Unknown" || name.startsWith('User ')) {
    const idStr = String(empId);
    return idStr.substring(0, 2).toUpperCase();
  }
  const parts = name.trim().split(" ");
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return parts[0].substring(0, 2).toUpperCase();
};

const getEmployeePhoto = (empId, employeesList) => {
  if (!empId) return null;
  if (!employeesList || employeesList.length === 0) return null;
  
  const emp = employeesList.find(e => {
    const target = String(empId).trim();
    return String(e.empId).trim() === target || 
           String(e.employeeId).trim() === target || 
           String(e.employeeCode).trim() === target || 
           String(e.id).trim() === target || 
           String(e._id).trim() === target || 
           String(e.employee_code).trim() === target || 
           String(e.empCode).trim() === target ||
           String(e.userId).trim() === target;
  });
  if (!emp) return null;
  
  if (emp.photoUrl) return emp.photoUrl;
  if (emp.profileImageBase64) return emp.profileImageBase64;
  if (emp.profileImage) return emp.profileImage;
  if (emp.photo) return emp.photo;
  if (emp.imageUrl) return emp.imageUrl;
  if (emp.avatar) return emp.avatar;
  if (emp.picture) return emp.picture;
  
  return null;
};

// ============================================
// FORMAT DATE FUNCTION
// ============================================
const formatDate = (dateStr) => {
  if (!dateStr) return "";
  try {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    const parts = dateStr.split("-");
    if (parts.length === 3) {
      return `${parts[2]}-${months[parseInt(parts[1], 10) - 1]}-${parts[0]}`;
    }
    return dateStr;
  } catch (e) {
    return dateStr;
  }
};

// ============================================
// ACTION BUTTON - DYNAMIC BASED ON PROGRESS, PROCESS, PRIORITY, TIME
// ============================================

const getActionButton = (task, currentUserEmpId) => {
  if (!task) return { label: "View", action: "view", variant: "secondary" };
  
  const rawTask = task.rawTask || task;
  
  // Get user roles
  const executorId = rawTask.empId || rawTask.assignedTo || rawTask.executorId || rawTask.doerId;
  const reviewerId = rawTask.reviewerId || rawTask.reviewer || rawTask.reviewerEmpId;
  const approverId = rawTask.approverId || rawTask.approver || rawTask.approverEmpId;
  
  const isDoer = String(executorId) === String(currentUserEmpId);
  const isReviewer = String(reviewerId) === String(currentUserEmpId);
  const isApprover = String(approverId) === String(currentUserEmpId);
  
  // Get progress (status)
  const progress = (rawTask.taskSts || rawTask.status || rawTask.taskStatus || task.status || "OPEN").toUpperCase();
  
  // Get process
  const process = (rawTask.prcsYesActn || rawTask.processAction || rawTask.process || "NONE").toUpperCase();
  
  // Calculate time status
  const timeStatus = calculateTimeStatus(rawTask);
  
  // Calculate priority
  let calculatedPriority = "Normal";
  const endDt = rawTask.endDt || rawTask.dueDate;
  if (progress === "REASSIGN" || progress === "REWORK") {
    calculatedPriority = progress;
  } else if (endDt) {
    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const dueDate = new Date(endDt);
      dueDate.setHours(0, 0, 0, 0);
      
      const diffTime = today.getTime() - dueDate.getTime();
      const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
      
      if (diffDays === 0) calculatedPriority = "High";
      else if (diffDays === 1) calculatedPriority = "Critical";
      else if (diffDays >= 2) calculatedPriority = "Atmost Critical";
    } catch (e) {}
  }
  
  // Normalize progress
  let normalizedProgress = progress;
  if (progress === "WIP" || progress === "IN_PROGRESS" || progress === "INPROGRESS") {
    normalizedProgress = "WORK_IN_PROGRESS";
  }
  if (progress === "OPEN") normalizedProgress = "OPEN";
  if (progress === "COMPLETED" || progress === "CLOSED") normalizedProgress = "COMPLETED";
  if (progress === "HOLD") normalizedProgress = "HOLD";
  if (progress === "DRAFT") normalizedProgress = "OPEN";
  
  // Normalize process
  let normalizedProcess = process;
  if (process === "NONE" || !process || process === "NULL") normalizedProcess = "NONE";
  if (process === "PENDING_REVIEWER" || process === "UNDER_REVIEW") normalizedProcess = "UNDER_REVIEW";
  if (process === "PENDING_APPROVER") normalizedProcess = "UNDER_REVIEW";
  if (process === "REWORK") normalizedProcess = "REWORK";
  if (process === "REASSIGN") normalizedProcess = "REASSIGN";
  
  // Log for debugging
  console.log(`🔍 Dynamic Action Check - Task: ${task.id || task.taskId}`);
  console.log(`   Progress: ${normalizedProgress}, Process: ${normalizedProcess}`);
  console.log(`   Time Status: ${timeStatus?.status || 'N/A'}, Priority: ${calculatedPriority}`);
  console.log(`   IsDoer: ${isDoer}, IsReviewer: ${isReviewer}, IsApprover: ${isApprover}`);
  
  // If user has no role in this task, show View
  if (!isDoer && !isReviewer && !isApprover) {
    return { label: "View", action: "view", variant: "secondary" };
  }
  
  // ============================================
  // EXECUTOR (DOER) ACTIONS - DYNAMIC
  // ============================================
  if (isDoer) {
    // OPEN / DRAFT -> Start
    if (normalizedProgress === "OPEN") {
      return { label: "Start", action: "start", variant: "primary" };
    }
    
    // WORK_IN_PROGRESS with NONE -> Update
    if (normalizedProgress === "WORK_IN_PROGRESS" && normalizedProcess === "NONE") {
      return { label: "Update", action: "update", variant: "warning" };
    }
    
    // WORK_IN_PROGRESS with UNDER_REVIEW -> View
    if (normalizedProgress === "WORK_IN_PROGRESS" && normalizedProcess === "UNDER_REVIEW") {
      return { label: "View", action: "view", variant: "secondary" };
    }
    
    // WORK_IN_PROGRESS with REWORK -> Update
    if (normalizedProgress === "WORK_IN_PROGRESS" && normalizedProcess === "REWORK") {
      return { label: "Update", action: "update", variant: "warning" };
    }
    
    // WORK_IN_PROGRESS with REASSIGN -> Update
    if (normalizedProgress === "WORK_IN_PROGRESS" && normalizedProcess === "REASSIGN") {
      return { label: "Update", action: "update", variant: "warning" };
    }
    
    // HOLD -> View
    if (normalizedProgress === "HOLD") {
      return { label: "View", action: "view", variant: "secondary" };
    }
    
    // COMPLETED -> View
    if (normalizedProgress === "COMPLETED") {
      return { label: "View", action: "view", variant: "secondary" };
    }
    
    // Default fallback for executor
    return { label: "Update", action: "update", variant: "warning" };
  }
  
  // ============================================
  // REVIEWER ACTIONS - DYNAMIC
  // ============================================
  if (isReviewer) {
    // WORK_IN_PROGRESS with UNDER_REVIEW -> Review
    if (normalizedProgress === "WORK_IN_PROGRESS" && normalizedProcess === "UNDER_REVIEW") {
      return { label: "Review", action: "review", variant: "review" };
    }
    
    // All other cases -> View
    return { label: "View", action: "view", variant: "secondary" };
  }
  
  // ============================================
  // APPROVER ACTIONS - DYNAMIC
  // ============================================
  if (isApprover) {
    // WORK_IN_PROGRESS with UNDER_REVIEW -> Approve
    if (normalizedProgress === "WORK_IN_PROGRESS" && normalizedProcess === "UNDER_REVIEW") {
      return { label: "Approve", action: "approve", variant: "success" };
    }
    
    // All other cases -> View
    return { label: "View", action: "view", variant: "secondary" };
  }
  
  return { label: "View", action: "view", variant: "secondary" };
};

const getProcessIcon = (process) => {
  if (!process || process === "NONE" || process === "REJECTED") return null;
  const processData = PROCESS_COLORS[process];
  if (!processData) return null;
  return {
    icon: processData.icon,
    color: processData.color,
    title: processData.title
  };
};

const getProgressBadge = (status) => {
  let normalizedStatus = "OPEN";
  if (typeof status === 'object' && status !== null) {
    normalizedStatus = String(status.statusNm || status.status_nm || status.statusId || "OPEN").toUpperCase();
    if (status.statusId === 4 || status.status_id === 4) normalizedStatus = "CLOSED";
  } else if (typeof status === 'string') {
    normalizedStatus = status.toUpperCase();
  } else if (typeof status === 'number') {
    if (status === 4) normalizedStatus = "CLOSED";
    if (status === 3) normalizedStatus = "WIP";
    if (status === 2) normalizedStatus = "OPEN";
    if (status === 1) normalizedStatus = "DRAFT";
  }
  const progressData = PROGRESS_COLORS[normalizedStatus] || PROGRESS_COLORS["OPEN"];
  return progressData;
};

const getPriorityBadge = (priority) => {
  const normalizedPriority = priority || "Normal";
  const priorityData = PRIORITY_COLORS[normalizedPriority];
  if (!priorityData) return { bg: "#F3F4F6", color: "#6B7280" };
  return priorityData;
};

// ============================================
// MAIN COMPONENT
// ============================================
const MyTasks = ({ userRole, onLogout }) => {
  const [tasks, setTasks] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [currentUserEmpId, setCurrentUserEmpId] = useState(null);
  const [currentUserEmail, setCurrentUserEmail] = useState(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [employeesList, setEmployeesList] = useState([]);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);
  const [apiError, setApiError] = useState(null);
  const [loadingAction, setLoadingAction] = useState(null);
  const [userName, setUserName] = useState("");
  const [showDetailView, setShowDetailView] = useState(false);
  const [selectedTask, setSelectedTask] = useState(null);
  const [updateProgressVal, setUpdateProgressVal] = useState(0);
  const [updateChecklist, setUpdateChecklist] = useState([]);
  const [updateRemarks, setUpdateRemarks] = useState("");
  const [showDenyForm, setShowDenyForm] = useState(false);
  const [isRaiseRequest, setIsRaiseRequest] = useState(false);
  const [denyData, setDenyData] = useState({ type: "", reason: "", milestone: "", deliverable: "", impact: "Medium" });

  // ============================================
  // FETCH TASKS
  // ============================================
  const fetchTasks = async () => {
    try {
      setIsLoading(true);
      setApiError(null);
      
      console.log("🔄 ===== FETCHING REAL TIME TASKS FROM BACKEND =====");
      const startTime = Date.now();
      
      let empId = null;
      let userEmail = null;
      let adminCheck = false;
      
      let employeesData = employeesList;
      let projectsData = [];
      let milestonesData = [];
      let tasksData = [];
      let indTasksData = [];

      // Always fetch fresh data but use parallel requests for maximum speed
      console.log("📡 Fetching bulk data in parallel (including profile and employees)...");
      const [profileRes, empRes, projRes, mileRes, mileDraftRes, taskRes, indTaskRes, dashRes, myTasksApiRes] = await Promise.allSettled([
        apiGet("/api/profile"),
        apiGet("/api/employees/directory").catch(() => apiGet("/api/employees")),
        apiGet("/api/project-live"),
        apiGet("/api/milestone-live"),
        apiGet("/api/milestone-drafts"),
        apiGet("/api/task-live"),
        apiGet("/api/assignments"),
        apiGet("/api/user-dashboard"),
        apiGet("/api/user-dashboard/my-tasks")
      ]);

      // Handle Profile
      if (profileRes.status === 'fulfilled' && profileRes.value) {
        empId = profileRes.value.empId;
        userEmail = profileRes.value.email;
        const profileName = profileRes.value.name || profileRes.value.employeeName || profileRes.value.fullName;
        if (profileName) {
          setUserName(profileName);
          sessionStorage.setItem("userName", profileName);
        }
        adminCheck = userEmail === 'vsv.vempati@gmail.com' || userEmail === 'admin@example.com' || userRole === 'admin';
      } else {
        empId = sessionStorage.getItem("empId");
        userEmail = sessionStorage.getItem("userEmail");
        const storedName = sessionStorage.getItem("userName");
        if (storedName) setUserName(storedName);
        adminCheck = userEmail === 'vsv.vempati@gmail.com' || userRole === 'admin';
      }
      
      setCurrentUserEmpId(empId);
      setCurrentUserEmail(userEmail);
      setIsAdmin(adminCheck);

      // Handle Employees
      if (empRes.status === 'fulfilled' && empRes.value) {
        employeesData = empRes.value;
        setEmployeesList(employeesData);
      }

      if (!empId && !adminCheck) {
        console.log("📱 No user logged in - showing demo tasks");
        const demoTasks = getDemoTasks(empId, employeesData);
        setTasks(demoTasks);
        setIsLoading(false);
        return;
      }

      projectsData = projRes.status === 'fulfilled' && projRes.value ? projRes.value : [];
      setProjectsList(projectsData);
      if (projRes.status === 'rejected') console.warn("⚠️ Projects API Error:", projRes.reason);
      else console.log("✅ Projects loaded:", projectsData.length);

      const liveMiles = mileRes.status === 'fulfilled' && mileRes.value ? mileRes.value : [];
      const draftMiles = mileDraftRes.status === 'fulfilled' && mileDraftRes.value ? mileDraftRes.value : [];
      milestonesData = [...liveMiles, ...draftMiles];
      setMilestonesList(milestonesData);
      console.log("✅ Milestones loaded:", milestonesData.length);

      tasksData = taskRes.status === 'fulfilled' && taskRes.value ? taskRes.value : [];
      if (taskRes.status === 'rejected') console.error("❌ Tasks API Error:", taskRes.reason);
      else console.log("✅ Tasks loaded:", tasksData.length);

      indTasksData = indTaskRes.status === 'fulfilled' && indTaskRes.value ? indTaskRes.value : [];
      if (indTaskRes.status === 'rejected') console.warn("⚠️ Assignments API Error:", indTaskRes.reason);
      else console.log("✅ Individual tasks loaded:", indTasksData.length);
      
      if (dashRes.status === 'fulfilled' && dashRes.value?.upcomingTasks) {
        setUpcomingTaskIds(dashRes.value.upcomingTasks.map(t => String(t.taskId || t.id)));
      } else {
        setUpcomingTaskIds([]);
      }

      // Extract employees from all tasks to populate missing profiles (for restricted users)
      try {
        const extractedEmployees = new Map();
        
        const allTasksSource = [
          ...(dashRes.status === 'fulfilled' && dashRes.value ? [
            ...(dashRes.value.todoList || []),
            ...(dashRes.value.upcomingTasks || []),
            ...(dashRes.value.completedTasks || []),
            ...(dashRes.value.closedTasks || [])
          ] : []),
          ...tasksData,
          ...indTasksData
        ];

        allTasksSource.forEach(t => {
          // Extract from embedded employees array
          if (t.employees && Array.isArray(t.employees)) {
            t.employees.forEach(e => {
              const id = String(e.empId || e.employeeId || e.id || "");
              if (id) {
                extractedEmployees.set(id, {
                  empId: id,
                  empNm: e.fullName || e.empName || e.name || e.employeeName,
                  profileImage: e.photoUrl || e.photo || e.profileImage || null
                });
              }
            });
          }
          // Extract from flat fields
          if (t.empId || t.assignedTo || t.executorId) {
            const id = String(t.empId || t.assignedTo || t.executorId);
            const name = t.executorName || t.empNm || t.empName || t.assignedToName || t.executorNm;
            if (name && !extractedEmployees.has(id)) {
              extractedEmployees.set(id, { empId: id, empNm: name, profileImage: t.executorPhoto || t.empPhoto });
            }
          }
          if (t.reviewerId || t.reviewer) {
            const id = String(t.reviewerId || t.reviewer);
            const name = t.reviewerName || t.reviewerNm || t.revNm || t.revName;
            if (name && !extractedEmployees.has(id)) {
              extractedEmployees.set(id, { empId: id, empNm: name, profileImage: t.reviewerPhoto || t.revPhoto });
            }
          }
          if (t.approverId || t.approver) {
            const id = String(t.approverId || t.approver);
            const name = t.approverName || t.approverNm || t.appNm || t.appName;
            if (name && !extractedEmployees.has(id)) {
              extractedEmployees.set(id, { empId: id, empNm: name, profileImage: t.approverPhoto || t.appPhoto });
            }
          }
        });

        const existingEmpIds = new Set(employeesData.map(e => String(e.empId)));
        const newEmployees = Array.from(extractedEmployees.values()).filter(e => !existingEmpIds.has(e.empId));
        
        if (newEmployees.length > 0) {
          console.log(`➕ Extracted ${newEmployees.length} employees from tasks (Fallback)`);
          employeesData = [...employeesData, ...newEmployees];
          setEmployeesList(employeesData);
        }
      } catch (e) {
        console.error("Error extracting employees", e);
      }

      if ((!tasksData || tasksData.length === 0) && (!indTasksData || indTasksData.length === 0)) {
        console.log("📡 No tasks found, trying alternative endpoint /api/tasks...");
        try {
          const altTasks = await apiGet("/api/tasks");
          if (altTasks && altTasks.length > 0) {
            tasksData = altTasks;
            console.log("✅ Found tasks from /api/tasks:", tasksData.length);
          }
        } catch (altErr) {
          console.warn("⚠️ Alternative tasks API also failed");
        }
        
        if ((!tasksData || tasksData.length === 0) && (!indTasksData || indTasksData.length === 0)) {
          console.log("📱 No tasks - showing demo tasks");
          const demo = getDemoTasks(empId, employeesData || []);
          setTasks(demo);
          setIsLoading(false);
          return;
        }
      }

      // Process config mapping from stored procedure get_my_tasks_data endpoint
      const liveTaskProcessMap = new Map();
      const indTaskProcessMap = new Map();

      let myTasksDataFromSp = [];
      if (myTasksApiRes.status === 'fulfilled' && Array.isArray(myTasksApiRes.value)) {
        myTasksDataFromSp = myTasksApiRes.value;
        myTasksDataFromSp.forEach(item => {
          const raw = item.rawTask || item;
          const tid = item.taskId || raw.taskId;
          if (tid) {
            if (item.isIndividual) {
              indTaskProcessMap.set(String(tid), {
                reviewerId: raw.reviewerId,
                approverId: raw.approverId,
                reviewerNm: raw.reviewerNm,
                approverNm: raw.approverNm
              });
            } else {
              liveTaskProcessMap.set(String(tid), {
                reviewerId: raw.reviewerId,
                approverId: raw.approverId,
                reviewerNm: raw.reviewerNm,
                approverNm: raw.approverNm
              });
            }
          }
        });
      }

      tasksData = tasksData.map(t => {
        const info = liveTaskProcessMap.get(String(t.taskId || t.id));
        if (info) {
          return {
            ...t,
            reviewerId: t.reviewerId || info.reviewerId,
            approverId: t.approverId || info.approverId,
            reviewerName: t.reviewerName || info.reviewerNm,
            approverName: t.approverName || info.approverNm
          };
        }
        return t;
      });

      indTasksData = indTasksData.map(t => {
        const info = indTaskProcessMap.get(String(t.empTaskId || t.taskId || t.id));
        if (info) {
          return {
            ...t,
            reviewerId: t.reviewerId || info.reviewerId,
            approverId: t.approverId || info.approverId,
            reviewerName: t.reviewerName || info.reviewerNm,
            approverName: t.approverName || info.approverNm
          };
        }
        return t;
      });

      let filteredLiveTasks = [];
      let filteredIndTasks = [];

      const userEmpId = String(empId);
      console.log(`🔍 Filtering tasks strictly for user ID: ${userEmpId}`);
      
      if (myTasksDataFromSp.length > 0) {
        const spProjectTaskIds = new Set();
        const spIndTaskIds = new Set();

        myTasksDataFromSp.forEach(item => {
          const raw = item.rawTask || item;
          const tid = String(item.taskId || raw.taskId || raw.empTaskId || item.id || '').trim();
          if (tid) {
            if (item.isIndividual || raw.isIndividual) {
              spIndTaskIds.add(tid);
            } else {
              spProjectTaskIds.add(tid);
            }
          }
        });

        filteredLiveTasks = (tasksData || []).filter(t => spProjectTaskIds.has(String(t.taskId || t.id || '').trim()));
        filteredIndTasks = (indTasksData || []).filter(t => spIndTaskIds.has(String(t.empTaskId || t.taskId || t.id || '').trim()));
      } else {
        const isUserInTask = (task) => {
          const taskEmpId = String(task.empId || task.assignedTo || task.executorId || '');
          const taskReviewerId = String(task.reviewerId || task.reviewer || '');
          const taskApproverId = String(task.approverId || task.approver || '');
          if (taskEmpId === userEmpId || taskReviewerId === userEmpId || taskApproverId === userEmpId) return true;
          if (Array.isArray(task.employees)) {
            return task.employees.some(e => String(e.empId || e.id || '') === userEmpId);
          }
          return false;
        };

        filteredLiveTasks = (tasksData || []).filter(isUserInTask);
        filteredIndTasks = (indTasksData || []).filter(isUserInTask);
      }

      console.log(`✅ User tasks (Live): ${filteredLiveTasks.length} (out of ${(tasksData || []).length})`);
      console.log(`✅ User tasks (Individual): ${filteredIndTasks.length} (out of ${(indTasksData || []).length})`);

      let mappedLive = filteredLiveTasks.map(t => {
        const prj = (projectsData || []).find(p => String(p.prjId || p.prjid || p.id) === String(t.prjId || t.prjid || t.projectId || t.prj_id));
        const ms = (milestonesData || []).find(m => String(m.mId || m.mid || m.id) === String(t.mId || t.mid || t.milestoneId || t.drftMId || t.drft_m_id));
        const tid = t.taskId || t.id;
        const code = t.taskCd || t.taskCode || `TSK-${tid}`;
        
        let emps = [];
        if (t.employees && Array.isArray(t.employees) && t.employees.length > 0) {
          emps = t.employees;
        } else {
          const exeId = t.empId || t.assignedTo || t.executorId;
          const revId = t.reviewerId || t.reviewer;
          const appId = t.approverId || t.approver;
          
          if (exeId) {
            const e = (employeesData || []).find(emp => String(emp.empId || emp.id) === String(exeId));
            emps.push({ name: e ? `${e.fstNm || e.firstName || ''} ${e.lstNm || e.lastName || ''}`.trim() : (t.executorNm || t.executorName || 'Executor'), photoUrl: e?.photoUrl || t.executorPhoto, role: 'Assignee', empId: exeId });
          }
          if (revId) {
            const e = (employeesData || []).find(emp => String(emp.empId || emp.id) === String(revId));
            emps.push({ name: e ? `${e.fstNm || e.firstName || ''} ${e.lstNm || e.lastName || ''}`.trim() : (t.reviewerNm || t.reviewerName || 'Reviewer'), photoUrl: e?.photoUrl || t.reviewerPhoto, role: 'Reviewer', empId: revId });
          }
          if (appId) {
            const e = (employeesData || []).find(emp => String(emp.empId || emp.id) === String(appId));
            emps.push({ name: e ? `${e.fstNm || e.firstName || ''} ${e.lstNm || e.lastName || ''}`.trim() : (t.approverNm || t.approverName || 'Approver'), photoUrl: e?.photoUrl || t.approverPhoto, role: 'Approver', empId: appId });
          }
        }

        return {
          id: code,
          code: code,
          taskId: tid,
          title: t.taskNm || t.title || t.name,
          name: t.taskNm || t.title || t.name,
          project: prj ? (prj.prjNm || prj.name) : (t.projectName || t.project || "Internal"),
          projectCode: prj ? (prj.prjCd || prj.code) : (t.projectCode || "Internal"),
          milestone: ms ? (ms.mlstnTtl || ms.title) : (t.milestoneTitle || t.milestone || ""),
          status: t.statusNm || t.status || t.taskSts,
          rawStatus: t.statusNm || t.taskSts || t.status,
          subStatus: t.subStatus,
          prcsYesActn: t.prcsYesActn,
          dueDate: t.endDt || t.dueDate || "",
          startDate: t.stDt || t.startDate || "",
          priority: t.priorityNm || t.priority || "Medium",
          isIndividual: false,
          employees: emps,
          rawTask: t
        };
      });

      let mappedInd = filteredIndTasks.map(t => {
        const tid = t.empTaskId || t.taskId || t.id;
        const code = t.taskCd || t.taskCode || `IND-${tid}`;
        
        let emps = [];
        if (t.employees && Array.isArray(t.employees) && t.employees.length > 0) {
          emps = t.employees;
        } else if (t.empId) {
          const e = (employeesData || []).find(emp => String(emp.empId || emp.id) === String(t.empId));
          emps.push({ name: e ? `${e.fstNm || e.firstName || ''} ${e.lstNm || e.lastName || ''}`.trim() : 'Executor', photoUrl: e?.photoUrl, role: 'Assignee', empId: t.empId });
        }

        return {
          id: code,
          code: code,
          taskId: tid,
          empTaskId: tid,
          title: t.taskNm || t.title || t.name,
          name: t.taskNm || t.title || t.name,
          project: t.taskAsgnTo || t.projectName || t.project || "Internal",
          projectCode: t.taskAsgnTo || t.projectCode || "Internal",
          milestone: "Individual Task",
          status: t.statusNm || t.status || t.taskSts,
          rawStatus: t.statusNm || t.taskSts || t.status,
          subStatus: t.subStatus,
          prcsYesActn: t.prcsYesActn,
          dueDate: t.endDt || t.dueDate || "",
          startDate: t.stDt || t.startDate || "",
          priority: t.priorityNm || t.priority || "Medium",
          isIndividual: true,
          employees: emps,
          rawTask: t
        };
      });

      let mapped = [...mappedLive, ...mappedInd];

      // Final strict deduplication by unique database primary ID
      const uniqueMapped = [];
      const seenKeys = new Set();
      mapped.forEach(t => {
        const idVal = t.taskId || t.id || t.empTaskId;
        const idKey = `${t.isIndividual ? 'IND' : 'LIVE'}_${idVal}`;
        if (idVal && !seenKeys.has(idKey)) {
          seenKeys.add(idKey);
          uniqueMapped.push(t);
        }
      });
      mapped = uniqueMapped;

      mapped = mapped.map(task => {
        let progress = 0;
        const taskSts = String(task.rawStatus || task.status || "").toUpperCase();
        
        if (taskSts === 'COMPLETED' || taskSts === 'CLOSED') {
          progress = 100;
        } else if (taskSts === 'WIP' || taskSts === 'IN_PROGRESS' || taskSts === 'UNDER_REVIEW') {
          progress = 50;
        } else if (taskSts === 'OPEN' || taskSts === 'DRAFT') {
          progress = 0;
        }
        
        return {
          ...task,
          progress: progress,
          status: getDisplayStatus(progress, task.status, false)
        };
      });

      mapped = mapped.filter(task => {
        const s = String(task.rawStatus || task.status || "").toUpperCase();
        return s !== "DRAFT";
      });

      console.log(`✅ Final tasks loaded: ${mapped.length} (Loaded in ${Date.now() - startTime}ms)`);
      setTasks(mapped);
      return mapped;
      
    } catch (err) {
      console.error("❌ Error loading tasks:", err);
      setApiError(err.message || "Failed to load tasks. Please try again.");
      return [];
    } finally {
      setIsLoading(false);
    }
  };

  const getDemoTasks = (empId, employees) => {
    const userId = empId || "1";
    return [
      {
        id: "DEMO-001",
        taskId: 1,
        title: "Design Homepage (Demo)",
        project: "Website Redesign",
        milestone: "Design Phase",
        priority: "High",
        dueDate: "2026-07-20",
        status: "WIP",
        progress: 50,
        rawStatus: "WIP",
        rawTask: {
          taskId: 1,
          taskNm: "Design Homepage",
          empId: userId,
          reviewerId: "2",
          approverId: "3",
          taskSts: "WIP",
          prcsYesActn: "NONE",
          endDt: "2026-07-20"
        },
        description: "Create the main homepage design with hero section"
      },
      {
        id: "DEMO-002",
        taskId: 2,
        title: "API Integration (Demo)",
        project: "Mobile App",
        milestone: "Backend",
        priority: "Critical",
        dueDate: "2026-07-15",
        status: "OPEN",
        progress: 0,
        rawStatus: "OPEN",
        rawTask: {
          taskId: 2,
          taskNm: "API Integration",
          empId: userId,
          reviewerId: "4",
          approverId: "5",
          taskSts: "OPEN",
          prcsYesActn: "NONE",
          endDt: "2026-07-15"
        },
        description: "Integrate REST APIs for mobile app"
      },
      {
        id: "DEMO-003",
        taskId: 3,
        title: "Testing and QA (Demo)",
        project: "Website Redesign",
        milestone: "Testing",
        priority: "Normal",
        dueDate: "2026-07-25",
        status: "COMPLETED",
        progress: 100,
        rawStatus: "COMPLETED",
        rawTask: {
          taskId: 3,
          taskNm: "Testing and QA",
          empId: userId,
          reviewerId: "2",
          approverId: "3",
          taskSts: "COMPLETED",
          prcsYesActn: "NONE",
          endDt: "2026-07-25",
          actCmpDt: "2026-07-24"
        },
        description: "Complete testing and quality assurance"
      }
    ];
  };

  const getDisplayStatus = (progress, originalStatus, prcsFlg) => {
    if (progress === 100) return "COMPLETED";
    if (progress > 0) return "WIP";
    return "OPEN";
  };

const formatTaskCode = (code, taskId, isIndividual) => {
  if (code && typeof code === 'string' && code.trim() !== '') {
    const raw = code.trim();
    const match = raw.match(/^(TSK|INDTSK|INDKTSK|IND|INDTASK|TST|T)-?(\d+)$/i);
    if (match) {
      const p = match[1].toUpperCase();
      const num = parseInt(match[2], 10);
      if (p.startsWith('IND')) {
        return `INDTSK-${String(num).padStart(3, '0')}`;
      } else {
        return `TSK-${String(num).padStart(3, '0')}`;
      }
    }
    return raw.toUpperCase();
  }
  const prefix = isIndividual ? 'INDTSK' : 'TSK';
  const num = parseInt(taskId, 10);
  return `${prefix}-${String(isNaN(num) ? 1 : num).padStart(3, '0')}`;
};

  const mapBackendTask = (t, projects, milestones, employees) => {
    const targetMId = t.mId || t.m_id || t.drftMId || t.milestoneId || t.mid;
    const milestoneObj = milestones?.find(m => 
      String(m.mId || m.id || m.m_id || m.milestoneId || '') === String(targetMId || '')
    );
    
    const targetPrjId = milestoneObj 
      ? (milestoneObj.prjId || milestoneObj.projectId || milestoneObj.prj_id) 
      : (t.prjId || t.projectId || t.prj_id);
    const projectObj = projects?.find(p => 
      String(p.prjId || p.id || p.prj_id || '') === String(targetPrjId || '')
    );

    const milestoneName = 
      (milestoneObj ? (milestoneObj.mlstnTtl || milestoneObj.title || milestoneObj.name || milestoneObj.mlstn_ttl || milestoneObj.mlstnNm) : null) ||
      t.milestoneName || t.mlstnTtl || t.milestoneTitle || t.milestone || t.mlstnNm || t.mlstn_ttl ||
      "—";

    const projectName =
      (projectObj ? (projectObj.prjNm || projectObj.name || projectObj.prj_nm) : null) ||
      t.projectName || t.projectCodeName || t.prjNm || t.project ||
      "Internal";

    const taskCodeFormatted = formatTaskCode(t.taskCd || t.taskCode || t.task_cd || t.code, t.taskId || t.id, false);

    let status = "OPEN";
    const taskSts = String(t.taskSts || t.status || "OPEN").toUpperCase();
    if (taskSts === "COMPLETED" || taskSts === "CLOSED") status = "COMPLETED";
    else if (taskSts === "WIP" || taskSts === "IN_PROGRESS") status = "WIP";
    else if (taskSts === "OPEN") status = "OPEN";
    else if (taskSts === "DRAFT") status = "DRAFT";
    else if (taskSts === "HOLD") status = "HOLD";
    else status = "WIP";

    let calculatedPriority = "Normal";
    const endDt = t.endDt || t.dueDate || t.endDate;
    if (taskSts === "REASSIGN" || taskSts === "REWORK") {
      calculatedPriority = taskSts;
    } else if (endDt) {
      try {
        const dateStr = endDt.split('T')[0];
        const [year, month, day] = dateStr.split('-');
        const endDtObj = new Date(year, month - 1, day);
        endDtObj.setHours(0, 0, 0, 0);

        let compareDateObj = new Date();
        compareDateObj.setHours(0, 0, 0, 0);

        const actCmpDt = t.actCmpDt || t.actualCompletionDate || t.completedDate;
        if (taskSts === "COMPLETED" || taskSts === "CLOSED" || taskSts === "UNDER_REVIEW") {
          if (actCmpDt) {
            const cmpDateStr = actCmpDt.split('T')[0];
            const [cYear, cMonth, cDay] = cmpDateStr.split('-');
            compareDateObj = new Date(cYear, cMonth - 1, cDay);
            compareDateObj.setHours(0,0,0,0);
          } else if (compareDateObj > endDtObj) {
            compareDateObj = endDtObj;
          }
        }

        const diffTime = compareDateObj.getTime() - endDtObj.getTime();
        const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));

        if (diffDays === 0) calculatedPriority = "High";
        else if (diffDays === 1) calculatedPriority = "Critical";
        else if (diffDays >= 2) calculatedPriority = "Atmost Critical";
      } catch (e) {}
    }

    return {
      id: taskCodeFormatted,
      taskCode: taskCodeFormatted,
      taskId: t.taskId || t.task_id || t.id,
      title: t.taskNm || t.taskName || t.name || "Untitled Task",
      project: projectName,
      milestone: milestoneName,
      priority: calculatedPriority,
      dueDate: endDt ? endDt.split('T')[0] : "",
      status: status,
      progress: 0,
      rawStatus: taskSts,
      rawTask: {
        ...t,
        empId: t.empId || t.assignedTo || t.executorId,
        assignedBy: t.assignedBy || t.assigned_by || t.createdBy || t.creBy,
        assignedByName: t.assignedByNm || t.assignedByName || t.createdByName,
        reviewerId: t.reviewerId || t.reviewer,
        approverId: t.approverId || t.approver,
      },
      description: t.taskDesc || t.description || ""
    };
  };

  const mapIndividualTask = (t, employees) => {
    const taskCodeFormatted = formatTaskCode(t.taskCd || t.taskCode || t.task_cd || t.code, t.empTaskId || t.id, true);

    let status = "OPEN";
    const taskSts = String(t.taskSts || t.status || "OPEN").toUpperCase();
    if (taskSts === "COMPLETED") status = "COMPLETED";
    else if (taskSts === "WIP" || taskSts === "IN_PROGRESS") status = "WIP";
    else if (taskSts === "OPEN") status = "OPEN";
    else if (taskSts === "DRAFT") status = "DRAFT";
    else if (taskSts === "HOLD") status = "HOLD";
    else status = "WIP";

    let calculatedPriority = "Normal";
    const endDt = t.endDt || t.dueDate || t.endDate;
    if (taskSts === "REASSIGN" || taskSts === "REWORK") {
      calculatedPriority = taskSts;
    } else if (endDt) {
      try {
        const dateStr = endDt.split('T')[0];
        const [year, month, day] = dateStr.split('-');
        const endDtObj = new Date(year, month - 1, day);
        endDtObj.setHours(0, 0, 0, 0);

        let compareDateObj = new Date();
        compareDateObj.setHours(0, 0, 0, 0);

        const actCmpDt = t.actCmpDt || t.actualCompletionDate || t.completedDate;
        if (taskSts === "COMPLETED" || taskSts === "UNDER_REVIEW") {
          if (actCmpDt) {
            const cmpDateStr = actCmpDt.split('T')[0];
            const [cYear, cMonth, cDay] = cmpDateStr.split('-');
            compareDateObj = new Date(cYear, cMonth - 1, cDay);
            compareDateObj.setHours(0,0,0,0);
          } else if (compareDateObj > endDtObj) {
            compareDateObj = endDtObj;
          }
        }

        const diffTime = compareDateObj.getTime() - endDtObj.getTime();
        const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));

        if (diffDays === 0) calculatedPriority = "High";
        else if (diffDays === 1) calculatedPriority = "Critical";
        else if (diffDays >= 2) calculatedPriority = "Atmost Critical";
      } catch (e) {}
    }

    return {
      id: taskCodeFormatted,
      taskCode: taskCodeFormatted,
      taskId: t.empTaskId || t.emp_task_id || t.taskId || t.task_id || t.id,
      isIndividual: true,
      title: t.taskNm || t.taskName || t.name || "Untitled Task",
      project: "Individual Task",
      milestone: "—",
      priority: calculatedPriority,
      dueDate: endDt ? endDt.split('T')[0] : "",
      status: status,
      progress: 0,
      rawStatus: taskSts,
      rawTask: {
        ...t,
        empId: t.empId || t.assignedTo || t.executorId,
        assignedBy: t.assignedBy || t.assigned_by || t.createdBy || t.creBy,
        assignedByName: t.assignedByNm || t.assignedByName || t.createdByName,
        reviewerId: t.reviewerId || t.reviewer,
        approverId: t.approverId || t.approver,
      },
      description: t.taskDesc || t.description || ""
    };
  };

  useEffect(() => {
    fetchTasks();
  }, []);

  // ============================================
  // SIDEBAR COLLAPSE LISTENER
  // ============================================
  useEffect(() => {
    const handleSidebarToggle = (event) => {
      const collapsed = event.detail?.collapsed || false;
      setIsSidebarCollapsed(collapsed);
      document.body.classList.toggle('sidebar-collapsed', collapsed);
    };
    
    window.addEventListener('sidebarToggle', handleSidebarToggle);
    
    const sidebar = document.querySelector('.sidebar');
    if (sidebar) {
      const collapsed = sidebar.classList.contains('collapsed');
      setIsSidebarCollapsed(collapsed);
      document.body.classList.toggle('sidebar-collapsed', collapsed);
    }
    
    return () => {
      window.removeEventListener('sidebarToggle', handleSidebarToggle);
      document.body.classList.remove('sidebar-collapsed');
    };
  }, []);

  // ============================================
  // STATE
  // ============================================
  const [searchInput, setSearchInput] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedProject, setSelectedProject] = useState("All Projects");
  const [selectedMilestone, setSelectedMilestone] = useState("All Milestones");
  const [selectedPriority, setSelectedPriority] = useState("All Priorities");
  const location = useLocation();
  const [selectedStatus, setSelectedStatus] = useState(location.state?.selectedStatus || "To Do");

  useEffect(() => {
    if (location.state?.selectedStatus) {
      setSelectedStatus(location.state.selectedStatus);
      setCurrentPage(1);
    }
  }, [location.state]);
  const [projectsList, setProjectsList] = useState([]);
  const [milestonesList, setMilestonesList] = useState([]);
  const [upcomingTaskIds, setUpcomingTaskIds] = useState([]);
  const [taskAttachments, setTaskAttachments] = useState([]);
  const [loadingAttachments, setLoadingAttachments] = useState(false);
  const [previewModalFile, setPreviewModalFile] = useState(null);
  const [selectedDueDate, setSelectedDueDate] = useState("");
  const [showFilters, setShowFilters] = useState(true);
  const [taskFilter, setTaskFilter] = useState("All");

  const handleStatusFilterChange = (statusVal) => {
    if (selectedStatus === statusVal) {
      setSelectedStatus("All Statuses");
    } else {
      setSelectedStatus(statusVal);
    }
  };

  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  const [alertOpen, setAlertOpen] = useState(false);
  const [alertConfig, setAlertConfig] = useState({ type: "success", title: "", message: "" });

  // Lock body scroll
  useEffect(() => {
    if (alertOpen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => { document.body.style.overflow = ""; };
  }, [alertOpen]);

  // ============================================
  // WORKFLOW ACTIONS - DYNAMIC
  // ============================================

  const sendNotification = async (empId, message, taskContext = null) => {
    if (!empId) return;
    try {
      const payload = {
        empId: parseInt(empId, 10),
        title: "Task Update",
        message
      };
      if (taskContext) {
        payload.entityTyp = taskContext.isIndividual ? "INDIVIDUAL_TASK" : "TASK";
        payload.entityId = parseInt(taskContext.taskId, 10);
      }
      await apiPost("/api/notifications", payload);
    } catch (e) {
      console.warn("Failed to send notification:", e);
    }
  };

  const handleStartTask = async (task, skipAlert = false) => {
    if (!task) return task;
    try {
      setLoadingAction(task.id || task.taskId);
      const originalTask = task.rawTask || task;
      
      // OPEN + NONE -> WORK_IN_PROGRESS + NONE
      const updatedTaskObj = {
        ...originalTask,
        taskSts: "WIP",
        prcsYesActn: "NONE"
      };
      
      const taskId = task.taskId || task.id;
      const updatePath = task.isIndividual 
        ? `/api/assignments/${taskId}`
        : `/api/task-live/${taskId}`;
        
      console.log(`🚀 Starting task ${taskId}`);
      await apiPut(`${updatePath}?_t=${Date.now()}`, updatedTaskObj);
      const latestTasks = await fetchTasks();
      if (!skipAlert) triggerAlert("success", "Started", "Task moved to Work In Progress.");
      
      let returnedTask = task;
      if (latestTasks) {
        const found = latestTasks.find(t => t.id === task.id);
        if (found) {
          returnedTask = found;
          if (selectedTask && selectedTask.id === task.id) {
            setSelectedTask(found);
          }
        }
      }
      return returnedTask;
    } catch (err) {
      console.error("Error starting task:", err);
      if (!skipAlert) triggerAlert("danger", "Error", "Failed to start task: " + err.message);
      return task;
    } finally {
      setLoadingAction(null);
    }
  };

  const handleSubmitReview = async (task) => {
    if (!task) return;
    try {
      setLoadingAction(task.id || task.taskId);
      const originalTask = task.rawTask || task;
      
      // WORK_IN_PROGRESS + NONE/REWORK -> WORK_IN_PROGRESS + UNDER_REVIEW
      const updatedTaskObj = {
        ...originalTask,
        taskSts: "WIP",
        prcsYesActn: originalTask.reviewerId ? "PENDING_REVIEWER" : "PENDING_APPROVER"
      };
      
      const taskId = task.taskId || task.id;
      const updatePath = task.isIndividual 
        ? `/api/assignments/${taskId}`
        : `/api/task-live/${taskId}`;
        
      console.log(`📤 Submitting task ${taskId} for review`);
      await apiPut(`${updatePath}?_t=${Date.now()}`, updatedTaskObj);
      
      const targetId = originalTask.reviewerId || originalTask.approverId;
      if (targetId) {
        await sendNotification(targetId, `Task submitted for review: ${task.id}`, task);
      }
      
      const latestTasks = await fetchTasks();
      triggerAlert("success", "Submitted", "Task submitted for review.");
      if (selectedTask && latestTasks) {
        const updatedTask = latestTasks.find(t => t.id === task.id);
        if (updatedTask) setSelectedTask(updatedTask);
      }
    } catch (err) {
      console.error("Error submitting for review:", err);
      triggerAlert("danger", "Error", "Failed to submit: " + err.message);
    } finally {
      setLoadingAction(null);
    }
  };

  const handleCompleteTask = async (task) => {
    if (!task) return;
    try {
      setLoadingAction(task.id || task.taskId);
      const originalTask = task.rawTask || task;
      
      // 1. Complete all checklists
      if (updateChecklist && updateChecklist.length > 0) {
        await Promise.all(updateChecklist
          .filter(item => item.id != null)
          .map(item => apiPatch(`/api/checklists/${item.id}/complete?_t=${Date.now()}`, {}))
        );
      }

      // 2. Build updated remarks
      let newRem = originalTask.remarks || originalTask.addlRem || "";
      if (updateRemarks) {
        newRem = newRem ? `${newRem}\n---\n[Executor]: ${updateRemarks}` : updateRemarks;
      }

      const updatedTaskObj = {
        ...originalTask,
        taskSts: { statusId: 4, statusNm: "Closed" },
        prcsYesActn: "NONE",
        actCmpDt: new Date().toISOString().split("T")[0]
      };
      if (task.isIndividual) {
        updatedTaskObj.remarks = newRem;
      } else {
        updatedTaskObj.addlRem = newRem;
      }
      
      const taskId = task.taskId || task.id;
      const updatePath = task.isIndividual 
        ? `/api/assignments/${taskId}`
        : `/api/task-live/${taskId}`;
        
      console.log(`✅ Direct completing task ${taskId}`);
      await apiPut(`${updatePath}?_t=${Date.now()}`, updatedTaskObj);

      // 3. Patch status endpoint to guarantee status_id = 4 in DB
      const statusPath = task.isIndividual 
        ? `/api/assignments/${taskId}/status`
        : `/api/task-live/${taskId}/status`;
      await apiPatch(`${statusPath}?_t=${Date.now()}`, { taskSts: "CLOSED" });
      
      const latestTasks = await fetchTasks();
      triggerAlert("success", "Completed", "Task completed successfully.");
      if (selectedTask && latestTasks) {
        const updatedTask = latestTasks.find(t => t.id === task.id);
        if (updatedTask) setSelectedTask(updatedTask);
      }
    } catch (err) {
      console.error("Error completing task:", err);
      triggerAlert("danger", "Error", "Failed to complete: " + err.message);
    } finally {
      setLoadingAction(null);
    }
  };

  const handleReviewerApprove = async (task) => {
    if (!task) return;
    try {
      setLoadingAction(task.id || task.taskId);
      const originalTask = task.rawTask || task;
      
      // WORK_IN_PROGRESS + UNDER_REVIEW -> WORK_IN_PROGRESS + UNDER_REVIEW (to approver) or COMPLETED
      let finalStatus = "WIP";
      let finalProcess = "PENDING_APPROVER";
      
      if (!originalTask.approverId) {
        finalStatus = "COMPLETED";
        finalProcess = "NONE";
      }
      
      const updatedTaskObj = {
        ...originalTask,
        taskSts: finalStatus,
        subStatus: finalStatus === "COMPLETED" ? null : "Under Review",
        prcsYesActn: finalProcess,
        actCmpDt: finalStatus === "COMPLETED" ? new Date().toISOString().split("T")[0] : originalTask.actCmpDt
      };
      
      const taskId = task.taskId || task.id;
      const updatePath = task.isIndividual 
        ? `/api/assignments/${taskId}`
        : `/api/task-live/${taskId}`;
        
      console.log(`✅ Reviewer approving task ${taskId}`);
      await apiPut(`${updatePath}?_t=${Date.now()}`, updatedTaskObj);
      
      if (finalStatus === "COMPLETED") {
        await sendNotification(originalTask.empId, `Task Closed: ${task.id}`, task);
      } else if (originalTask.approverId) {
        await sendNotification(originalTask.approverId, `Task ready for approval: ${task.id}`, task);
      }
      
      const latestTasks = await fetchTasks();
      triggerAlert("success", "Approved", "Task approved successfully.");
      if (selectedTask && latestTasks) {
        const updatedTask = latestTasks.find(t => t.id === task.id);
        if (updatedTask) setSelectedTask(updatedTask);
      }
    } catch (err) {
      console.error("Error approving task:", err);
      triggerAlert("danger", "Error", "Failed to approve: " + err.message);
    } finally {
      setLoadingAction(null);
    }
  };

  const handleApproverApprove = async (task) => {
    if (!task) return;
    try {
      setLoadingAction(task.id || task.taskId);
      const originalTask = task.rawTask || task;
      
      // WORK_IN_PROGRESS + UNDER_REVIEW -> COMPLETED + NONE
      const updatedTaskObj = {
        ...originalTask,
        taskSts: "COMPLETED",
        prcsYesActn: "NONE",
        actCmpDt: new Date().toISOString().split("T")[0]
      };
      
      const taskId = task.taskId || task.id;
      const updatePath = task.isIndividual 
        ? `/api/assignments/${taskId}`
        : `/api/task-live/${taskId}`;
        
      console.log(`✅ Approver approving task ${taskId}`);
      await apiPut(`${updatePath}?_t=${Date.now()}`, updatedTaskObj);
      
      await sendNotification(originalTask.empId, `Task Closed: ${task.id}`, task);
      if (originalTask.reviewerId) {
        await sendNotification(originalTask.reviewerId, `Task Closed: ${task.id}`, task);
      }
      
      const latestTasks = await fetchTasks();
      triggerAlert("success", "Closed", "Task closed successfully.");
      if (selectedTask && latestTasks) {
        const updatedTask = latestTasks.find(t => t.id === task.id);
        if (updatedTask) setSelectedTask(updatedTask);
      }
    } catch (err) {
      console.error("Error closing task:", err);
      triggerAlert("danger", "Error", "Failed to close: " + err.message);
    } finally {
      setLoadingAction(null);
    }
  };

  const handleReviewerReject = async (task, reason) => {
    if (!task) return;
    try {
      setLoadingAction(task.id || task.taskId);
      const originalTask = task.rawTask || task;
      
      // WORK_IN_PROGRESS + UNDER_REVIEW -> WORK_IN_PROGRESS + REWORK
      const prefix = `[Rejected - ${sessionStorage.getItem("userName") || 'Reviewer'}]`;
      const existingRem = task.isIndividual ? originalTask.remarks : originalTask.addlRem;
      let newRem = existingRem ? `${existingRem}\n---\n${prefix}: ${reason}` : `${prefix}: ${reason}`;
      if (newRem.length > 240) {
        newRem = newRem.slice(-240);
      }

      const updatedTaskObj = {
        ...originalTask,
        taskSts: "WIP",
        prcsYesActn: "REWORK"
      };

      if (task.isIndividual) {
        updatedTaskObj.remarks = newRem;
      } else {
        updatedTaskObj.addlRem = newRem;
      }
      
      const taskId = task.taskId || task.id;
      const updatePath = task.isIndividual 
        ? `/api/assignments/${taskId}`
        : `/api/task-live/${taskId}`;
        
      console.log(`❌ Reviewer rejecting task ${taskId}`);
      await apiPut(`${updatePath}?_t=${Date.now()}`, updatedTaskObj);
      await sendNotification(originalTask.empId, `Task rejected, needs rework: ${task.id}`, task);
      
      await fetchTasks();
      triggerAlert("warning", "Rejected", "Task sent back for rework.");
      if (selectedTask) {
        const updatedTask = tasks.find(t => t.id === task.id);
        if (updatedTask) setSelectedTask(updatedTask);
      }
    } catch (err) {
      console.error("Error rejecting task:", err);
      triggerAlert("danger", "Error", "Failed to reject: " + err.message);
    } finally {
      setLoadingAction(null);
    }
  };

  const handleReviewerReassign = async (task, reason, newExecutorId) => {
    if (!task) return;
    try {
      setLoadingAction(task.id || task.taskId);
      const originalTask = task.rawTask || task;
      
      // WORK_IN_PROGRESS + UNDER_REVIEW -> WORK_IN_PROGRESS + REASSIGN
      const prefix = `[Reassigned - ${sessionStorage.getItem("userName") || 'Reviewer'}]`;
      const existingRem = task.isIndividual ? originalTask.remarks : originalTask.addlRem;
      const newRem = existingRem ? `${existingRem}\n---\n${prefix}: ${reason}` : `${prefix}: ${reason}`;

      const updatedTaskObj = {
        ...originalTask,
        taskSts: "WIP",
        prcsYesActn: "REASSIGN",
        empId: newExecutorId || originalTask.empId
      };

      if (task.isIndividual) {
        updatedTaskObj.remarks = newRem;
      } else {
        updatedTaskObj.addlRem = newRem;
      }
      
      const taskId = task.taskId || task.id;
      const updatePath = task.isIndividual 
        ? `/api/assignments/${taskId}`
        : `/api/task-live/${taskId}`;
        
      console.log(`🔄 Reviewer reassigning task ${taskId}`);
      await apiPut(`${updatePath}?_t=${Date.now()}`, updatedTaskObj);
      
      if (newExecutorId) {
        await sendNotification(newExecutorId, `Task reassigned to you: ${task.id}`, task);
      }
      
      await fetchTasks();
      triggerAlert("info", "Reassigned", "Task reassigned successfully.");
      if (selectedTask) {
        const updatedTask = tasks.find(t => t.id === task.id);
        if (updatedTask) setSelectedTask(updatedTask);
      }
    } catch (err) {
      console.error("Error reassigning task:", err);
      triggerAlert("danger", "Error", "Failed to reassign: " + err.message);
    } finally {
      setLoadingAction(null);
    }
  };

  const handleApproverReject = async (task, reason) => {
    if (!task) return;
    try {
      setLoadingAction(task.id || task.taskId);
      const originalTask = task.rawTask || task;
      
      // WORK_IN_PROGRESS + UNDER_REVIEW -> WORK_IN_PROGRESS + REWORK
      const prefix = `[Rejected by Approver - ${sessionStorage.getItem("userName") || 'Approver'}]`;
      const existingRem = task.isIndividual ? originalTask.remarks : originalTask.addlRem;
      let newRem = existingRem ? `${existingRem}\n---\n${prefix}: ${reason}` : `${prefix}: ${reason}`;
      if (newRem.length > 240) {
        newRem = newRem.slice(-240);
      }

      const updatedTaskObj = {
        ...originalTask,
        taskSts: "WIP",
        prcsYesActn: "REWORK"
      };

      if (task.isIndividual) {
        updatedTaskObj.remarks = newRem;
      } else {
        updatedTaskObj.addlRem = newRem;
      }
      
      const taskId = task.taskId || task.id;
      const updatePath = task.isIndividual 
        ? `/api/assignments/${taskId}`
        : `/api/task-live/${taskId}`;
        
      console.log(`❌ Approver rejecting task ${taskId}`);
      await apiPut(`${updatePath}?_t=${Date.now()}`, updatedTaskObj);
      await sendNotification(originalTask.empId, `Task rejected by approver, needs rework: ${task.id}`, task);
      
      await fetchTasks();
      triggerAlert("warning", "Rejected", "Task sent back for rework.");
      if (selectedTask) {
        const updatedTask = tasks.find(t => t.id === task.id);
        if (updatedTask) setSelectedTask(updatedTask);
      }
    } catch (err) {
      console.error("Error rejecting task:", err);
      triggerAlert("danger", "Error", "Failed to reject: " + err.message);
    } finally {
      setLoadingAction(null);
    }
  };

  const handleResumeTask = async (task) => {
    if (!task) return;
    try {
      setLoadingAction(task.id || task.taskId);
      const originalTask = task.rawTask || task;
      
      // HOLD + NONE -> WORK_IN_PROGRESS + NONE
      const updatedTaskObj = {
        ...originalTask,
        taskSts: "WIP",
        prcsYesActn: "NONE"
      };
      
      const taskId = task.taskId || task.id;
      const updatePath = task.isIndividual 
        ? `/api/assignments/${taskId}`
        : `/api/task-live/${taskId}`;
        
      console.log(`▶️ Resuming task ${taskId}`);
      await apiPut(`${updatePath}?_t=${Date.now()}`, updatedTaskObj);
      await fetchTasks();
      triggerAlert("success", "Resumed", "Task resumed.");
      if (selectedTask) {
        const updatedTask = tasks.find(t => t.id === task.id);
        if (updatedTask) setSelectedTask(updatedTask);
      }
    } catch (err) {
      console.error("Error resuming task:", err);
      triggerAlert("danger", "Error", "Failed to resume: " + err.message);
    } finally {
      setLoadingAction(null);
    }
  };

  const handleUpdateProgress = async () => {
    if (!selectedTask) return;
    try {
      setLoadingAction(selectedTask.id || selectedTask.taskId);
      const originalTask = selectedTask.rawTask || selectedTask;
      
      await Promise.all(updateChecklist
        .filter(item => item.id != null)
        .map(item => {
          const path = `/api/checklists/${item.id}/${item.completed ? 'complete' : 'reopen'}?_t=${Date.now()}`;
          return apiPatch(path, {});
        })
      );

      if (updateRemarks) {
        const existingRem = selectedTask.isIndividual ? originalTask.remarks : originalTask.addlRem;
        const newRem = existingRem ? `${existingRem}\n---\n[Executor]: ${updateRemarks}` : updateRemarks;
        const updatedTaskObj = {
          ...originalTask
        };
        if (selectedTask.isIndividual) {
          updatedTaskObj.remarks = newRem;
        } else {
          updatedTaskObj.addlRem = newRem;
        }
        const taskId = selectedTask.taskId || selectedTask.id;
        const updatePath = selectedTask.isIndividual 
          ? `/api/assignments/${taskId}`
          : `/api/task-live/${taskId}`;
        await apiPut(`${updatePath}?_t=${Date.now()}`, updatedTaskObj);
      }
      
      await fetchTasks();
      triggerAlert("success", "Updated", "Progress updated successfully.");
      if (selectedTask) {
        const updatedTask = tasks.find(t => t.id === selectedTask.id);
        if (updatedTask) setSelectedTask(updatedTask);
      }
    } catch (err) {
      console.error("Error updating progress:", err);
      triggerAlert("danger", "Error", "Failed to update: " + err.message);
    } finally {
      setLoadingAction(null);
    }
  };

  const handleSaveProgress = async () => {
    if (!selectedTask) return;
    let progress = updateProgressVal;
    const originalTask = selectedTask.rawTask || selectedTask;
    const prcsFlg = originalTask?.prcsFlg || originalTask?.prcsflg || false;
    const currentSts = selectedTask.rawStatus || selectedTask.status;

    if (updateChecklist.length === 0 && currentSts !== "SUBMIT_REVIEW" && currentSts !== "UNDER_REVIEW") {
       progress = 100;
    }

    let backendSts = "OPEN";
    let newPrcsActn = originalTask.prcsYesActn || "NONE";
    const allChecked = updateChecklist.length > 0 && updateChecklist.every(c => c.completed);
    
    if (currentSts === "UNDER_REVIEW") {
       backendSts = "COMPLETED";
    } else {
       if (prcsFlg && (progress === 100 || allChecked)) {
           backendSts = "UNDER_REVIEW";
           if (originalTask?.reviewerId) {
               newPrcsActn = "PENDING_REVIEWER";
           } else if (originalTask?.approverId) {
               newPrcsActn = "PENDING_APPROVER";
           } else {
               backendSts = "COMPLETED";
           }
       } else if (!prcsFlg && (progress === 100 || allChecked)) {
           backendSts = "COMPLETED";
       } else if (progress > 0) {
           backendSts = "WIP";
       } else {
           backendSts = (currentSts === "WIP" || currentSts === "OPEN" || currentSts === "REASSIGN" || currentSts === "REWORK") ? "WIP" : "OPEN";
       }
    }

    try {
      setLoadingAction(selectedTask.id || selectedTask.taskId);
      const existingRem = selectedTask.isIndividual ? originalTask.remarks : originalTask.addlRem;
      const newRem = updateRemarks ? (existingRem ? `${existingRem}\n---\n[Executor]: ${updateRemarks}` : updateRemarks) : existingRem;

      const updatedTaskObj = {
        ...originalTask,
        taskSts: backendSts,
        prcsYesActn: newPrcsActn,
      };

      if (selectedTask.isIndividual) {
        updatedTaskObj.remarks = newRem;
      } else {
        updatedTaskObj.addlRem = newRem;
      }

      if (currentSts !== "UNDER_REVIEW") {
        await Promise.all(updateChecklist
          .filter(item => item.id != null)
          .map(item => {
            const path = `/api/checklists/${item.id}/${item.completed ? 'complete' : 'reopen'}?_t=${Date.now()}`;
            return apiPatch(path, {});
          })
        );
      }

      const taskId = selectedTask.taskId || selectedTask.id;
      const updatePath = selectedTask.isIndividual 
        ? `/api/assignments/${taskId}`
        : `/api/task-live/${taskId}`;
        
      console.log(`💾 Saving progress for task ${taskId}`);
      await apiPut(`${updatePath}?_t=${Date.now()}`, updatedTaskObj);

      const latestTasks = await fetchTasks();
      triggerAlert("success", "Success", "Task progress updated successfully.");
      
      if (originalTask?.reviewerId) {
        await sendNotification(originalTask.reviewerId, `${userName || "Executor"} updated progress for task: ${originalTask.taskNm || originalTask.task_nm || "Task"}`, selectedTask);
      }
      if (originalTask?.approverId) {
        await sendNotification(originalTask.approverId, `${userName || "Executor"} updated progress for task: ${originalTask.taskNm || originalTask.task_nm || "Task"}`, selectedTask);
      }

      if (selectedTask && latestTasks) {
        const updatedTask = latestTasks.find(t => t.id === selectedTask.id);
        if (updatedTask) setSelectedTask(updatedTask);
      }
    } catch (err) {
      console.error("Error saving progress:", err);
      triggerAlert("danger", "Error", "Failed to update task: " + err.message);
    } finally {
      setLoadingAction(null);
    }
  };

  const handleToggleChecklist = (id) => {
    if (!id) return;
    if (selectedTask?.status === "WIP" && selectedTask?.rawTask?.prcsYesActn === "PENDING_APPROVER") return;
    if (selectedTask?.status === "COMPLETED") return;
    const executorId = selectedTask?.rawTask?.empId || selectedTask?.rawTask?.assignedTo;
    if (String(executorId) !== String(currentUserEmpId)) return;

    setUpdateChecklist(prev => {
      const newList = prev.map(item =>
        item.id === id ? { ...item, completed: !item.completed } : item
      );
      const progress = computeProgress(newList, selectedTask);
      setUpdateProgressVal(progress);
      return newList;
    });
  };

  const handleSendReminder = async (targetId, role) => {
    if (!targetId) return;
    try {
      await sendNotification(targetId, `Reminder: Task "${selectedTask.title}" (${selectedTask.id}) is pending for your action.`, selectedTask);
      triggerAlert("success", "Sent", `Reminder sent to ${role}!`);
      setShowDetailView(false);
    } catch (err) {
      console.error("Failed to send reminder:", err);
      triggerAlert("danger", "Error", "Failed to send reminder.");
    }
  };

  const handleSubmitDeny = async (actionType) => {
    if (!selectedTask) return;
    try {
      const originalTask = selectedTask.rawTask || selectedTask;
      
      const newStatus = actionType || denyData.type;
      const prefix = `[${newStatus === "REWORK" ? 'Rejected' : 'Reassigned'} - ${sessionStorage.getItem("userName") || 'Reviewer'}]`;
      const existingRem = selectedTask.isIndividual ? originalTask.remarks : originalTask.addlRem;
      let newRem = existingRem ? `${existingRem}\n---\n${prefix}: ${denyData.reason}` : `${prefix}: ${denyData.reason}`;
      if (newRem.length > 240) {
        newRem = newRem.slice(-240);
      }

      const updatedTaskObj = {
        ...originalTask,
        taskSts: "WIP",
        prcsYesActn: newStatus === "REWORK" ? "REWORK" : "REASSIGN"
      };

      if (newStatus === "REASSIGN" && denyData.milestone) {
        updatedTaskObj.empId = denyData.milestone;
      }

      if (selectedTask.isIndividual) {
        updatedTaskObj.remarks = newRem;
      } else {
        updatedTaskObj.addlRem = newRem;
      }

      const taskId = selectedTask.taskId || selectedTask.id;
      const updatePath = selectedTask.isIndividual 
        ? `/api/assignments/${taskId}`
        : `/api/task-live/${taskId}`;
        
      console.log(`📝 Processing denial for task ${taskId}`);
      await apiPut(`${updatePath}?_t=${Date.now()}`, updatedTaskObj);

      if (updateChecklist.length > 0) {
        await Promise.all(updateChecklist
          .filter(item => item.id != null)
          .map(item => {
            const path = `/api/checklists/${item.id}/reopen?_t=${Date.now()}`;
            return apiPatch(path, {});
          })
        );
      }

      await fetchTasks();
      setShowDenyForm(false);
      triggerAlert("success", "Success", `Task ${newStatus === "REWORK" ? 'sent back for rework' : 'reassigned'}.`);
      if (selectedTask) {
        const updatedTask = tasks.find(t => t.id === selectedTask.id);
        if (updatedTask) setSelectedTask(updatedTask);
      }
    } catch (err) {
      console.error("Error processing denial:", err);
      triggerAlert("danger", "Error", "Failed to process: " + err.message);
    }
  };

  const computeProgress = (checklist, task) => {
    if (!checklist || checklist.length === 0) return 0;
    const completed = checklist.filter(item => item.completed).length;
    const prcsFlg = task?.rawTask?.prcsFlg || task?.rawTask?.prcsflg || false;
    const taskSts = task?.rawStatus || task?.status;

    if (!prcsFlg) {
      return Math.round((completed / checklist.length) * 100);
    } else {
       if (taskSts === 'COMPLETED') return 100;
       if (taskSts === 'UNDER_REVIEW') return task?.rawTask?.prcsYesActn === "PENDING_APPROVER" ? 95 : 90;
       if (taskSts === 'SUBMIT_REVIEW') return 90;
       let prog = Math.round((completed / checklist.length) * 100);
       if (prog === 100 && taskSts !== 'COMPLETED' && taskSts !== 'UNDER_REVIEW' && taskSts !== 'SUBMIT_REVIEW') {
           return 85;
       }
       return prog;
    }
  };

  const triggerAlert = (type, title, message) => {
    setAlertConfig({ type, title, message });
    setAlertOpen(true);
  };

  // ============================================
  // FILTERING & PAGINATION
  // ============================================

  const visibleTasks = tasks;

  const isCompletedTab = (task) => {
    const rawTask = task.rawTask || task;
    const sts = String(rawTask.taskSts || rawTask.status || task.rawStatus || task.status || "").toUpperCase();
    return sts === "COMPLETED" || sts === "CLOSED" || sts === "DONE" || task.progress === 100;
  };

  const isUpcomingTab = (task) => {
    if (isCompletedTab(task)) return false;

    const rawTask = task.rawTask || task;
    const sts = String(rawTask.taskSts || rawTask.status || task.rawStatus || task.status || "").toUpperCase();
    if (sts === "WIP" || sts === "IN_PROGRESS" || sts.includes("PROGRESS") || sts === "UNDER_REVIEW" || sts === "REWORK" || sts === "REASSIGN" || sts === "DRAFT") {
      return false;
    }

    const startDtStr = rawTask.stDt || rawTask.startDate || rawTask.start_dt || task.startDate || task.startDt;
    if (startDtStr) {
      try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const dateOnly = String(startDtStr).split('T')[0];
        const [year, month, day] = dateOnly.split('-');
        const startDateObj = new Date(parseInt(year, 10), parseInt(month, 10) - 1, parseInt(day, 10));
        startDateObj.setHours(0, 0, 0, 0);

        if (startDateObj > today) {
          return true;
        } else {
          return false;
        }
      } catch (e) {}
    }

    if (sts === "UPCOMING" || task.status === "UPCOMING" || task.status === "Upcoming" || task.isUpcoming === true) {
      return true;
    }

    return false;
  };

  const isToDo = (task) => {
    if (isCompletedTab(task)) return false;
    if (isUpcomingTab(task)) return false;
    return true;
  };

  const getTaskStatusFilter = (task) => {
    const rawTask = task.rawTask || task;
    const sts = (rawTask.taskSts || rawTask.status || task.status || "OPEN").toUpperCase();
    const process = (rawTask.prcsYesActn || "NONE").toUpperCase();
    
    if (sts === "OPEN" || sts === "DRAFT") {
      return "OPEN";
    }
    
    if (sts === "COMPLETED" || sts === "CLOSED") {
      return "COMPLETED";
    }
    
    if (sts === "WIP" || sts === "IN_PROGRESS") {
      if (process === "PENDING_REVIEWER" || process === "PENDING_APPROVER" || process === "UNDER_REVIEW") {
        return "UNDER_REVIEW";
      }
      if (process === "REASSIGN") {
        return "REASSIGNED";
      }
      return "IN_PROGRESS";
    }
    
    if (sts === "HOLD") {
      return "HOLD";
    }
    
    return sts;
  };

  const isTaskOverdue = (task) => {
    const rawTask = task.rawTask || task;
    if (!rawTask.endDt) return false;
    const sts = String(rawTask.taskSts || "").toUpperCase();
    if (sts === "COMPLETED" || sts === "CLOSED") return false;
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const dueDate = new Date(rawTask.endDt);
    dueDate.setHours(0, 0, 0, 0);
    
    return today > dueDate;
  };

  const filteredTasks = tasks.filter(task => {
    // 1. Basic filters
    if (selectedProject !== "All Projects" && task.project !== selectedProject) return false;
    if (selectedMilestone !== "All Milestones" && task.milestone !== selectedMilestone) return false;
    if (selectedPriority !== "All Priorities" && task.priority !== selectedPriority) return false;
    
    if (taskFilter !== "All" && selectedStatus !== "Completed") {
      const statusFilter = getTaskStatusFilter(task);
      if (taskFilter === "OVERDUE") {
        if (!isTaskOverdue(task)) return false;
      } else if (statusFilter !== taskFilter) {
        return false;
      }
    }
    
    // 2. Status card filter (To Do, Upcoming, Completed, All)
    if (selectedStatus !== "All Statuses" && selectedStatus !== "All Tasks") {
      if (selectedStatus === "To Do") {
        if (!isToDo(task)) return false;
      } else if (selectedStatus === "Upcoming") {
        if (!isUpcomingTab(task)) return false;
      } else if (selectedStatus === "Completed" || selectedStatus === "Closed") {
        if (!isCompletedTab(task)) return false;
      }
    }
    
    if (selectedDueDate && task.dueDate !== selectedDueDate) return false;
    return true;
  });

  const sortedTasks = [...filteredTasks].sort((a, b) => {
    const aOverdue = isTaskOverdue(a);
    const bOverdue = isTaskOverdue(b);
    if (aOverdue && !bOverdue) return -1;
    if (!aOverdue && bOverdue) return 1;
    if (a.dueDate && b.dueDate) {
      return a.dueDate.localeCompare(b.dueDate);
    }
    return 0;
  });

  const totalPages = Math.ceil(sortedTasks.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginatedTasks = sortedTasks.slice(startIndex, startIndex + itemsPerPage);

  const handlePageChange = (page) => {
    if (page >= 1 && page <= totalPages) {
      setCurrentPage(page);
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
    setTaskFilter("All");
    setCurrentPage(1);
  };

  useEffect(() => {
    setCurrentPage(1);
  }, [searchQuery, selectedProject, selectedMilestone, selectedPriority, selectedStatus, selectedDueDate, taskFilter]);

  const handleSearchKeyDown = (e) => {
    if (e.key === "Enter") {
      e.preventDefault();
      handleSearch();
    }
  };

  const getCurrentStatusDisplay = () => {
    if (!selectedTask) return "OPEN";
    const prcsFlg = selectedTask.rawTask?.prcsFlg || false;
    return getDisplayStatus(updateProgressVal, selectedTask.status, prcsFlg);
  };

  // ============================================
  // OPEN TASK DETAIL SCREEN
  // ============================================
  const openTaskDetail = async (task) => {
    if (!task) return;
    setSelectedTask(task);
    setUpdateRemarks("");
    setShowDenyForm(false);
    setDenyData({ type: "", reason: "", milestone: "", deliverable: "", impact: "Medium" });

    try {
      const taskId = task.taskId || task.id;
      const path = task.isIndividual
        ? `/api/checklists/assignments/${taskId}`
        : `/api/checklists/live-task/${taskId}`;
        
      const items = await apiGet(path);
      const mapped = (items || []).map(item => ({
        id: item.chkId || item.id,
        text: item.chkNm || item.name || item.text,
        completed: item.chkSts || item.completed || false
      }));
      setUpdateChecklist(mapped);
      const progress = computeProgress(mapped, task);
      setUpdateProgressVal(progress);
    } catch (err) {
      console.error("Failed to load checklist:", err);
      setUpdateChecklist([]);
      setUpdateProgressVal(0);
    }

    // Load attachments
    setLoadingAttachments(true);
    setTaskAttachments([]);
    try {
      const rawT = task.rawTask || task;
      const tId = rawT.taskId || rawT.empTaskId || rawT.id || task.taskId || task.id;
      
      let attList = [];
      const isInd = task.isIndividual || rawT.taskSource === "INDIVIDUAL";
      const primaryPath = isInd
        ? `/api/attachments/assignment/${tId}`
        : `/api/attachments/live-task/${tId}`;
      const fallbackPath = isInd
        ? `/api/attachments/live-task/${tId}`
        : `/api/attachments/draft-task/${tId}`;

      try {
        const res = await apiGet(primaryPath);
        if (Array.isArray(res) && res.length > 0) attList = res;
      } catch (e1) {}

      if (attList.length === 0) {
        try {
          const res2 = await apiGet(fallbackPath);
          if (Array.isArray(res2) && res2.length > 0) attList = res2;
        } catch (e2) {}
      }
      
      // Also check if rawTask or task has direct attachment url/path
      const directPath = rawT.atPath || rawT.attachmentUrl || rawT.filePath || rawT.photoUrl || task.atPath;
      if (directPath) {
        const fileName = rawT.fileNm || rawT.fileName || "Task Attachment";
        if (!attList.some(a => a.atPath === directPath)) {
          attList.push({ fileId: 'raw_1', fileNm: fileName, atPath: directPath });
        }
      }
      
      setTaskAttachments(attList);
    } catch (err) {
      console.error("Failed to load attachments:", err);
      setTaskAttachments([]);
    } finally {
      setLoadingAttachments(false);
    }

    setShowDetailView(true);
  };

  const parseRemarksHistory = (rawStr, task, employeesList) => {
    if (!rawStr || typeof rawStr !== 'string') return [];
    
    const rawBlocks = rawStr.split(/\n---\n|\n(?=\[[^\]]+\]:)/).map(s => s.trim()).filter(Boolean);
    const parsed = [];
    
    rawBlocks.forEach((block, idx) => {
      let name = "";
      let role = "TEAM";
      let action = "Remark";
      let text = block;
      let attachments = [];
      
      const bracketMatch = block.match(/^\[([^\]]+)\]:\s*([\s\S]*)/);
      if (bracketMatch) {
        const header = bracketMatch[1].trim();
        text = bracketMatch[2].trim();
        
        if (header.includes('-')) {
          const parts = header.split('-');
          action = parts[0].trim();
          name = parts.slice(1).join('-').trim();
        } else {
          name = header;
        }
      }

      const attachMatch = text.match(/\|\|ATTACHMENTS:(.*)\|\|/);
      if (attachMatch) {
        try {
          attachments = JSON.parse(attachMatch[1].trim());
        } catch (_) {}
        text = text.replace(/\|\|ATTACHMENTS:.*\|\|/, '').trim();
      }
      
      const rawTask = task?.rawTask || task || {};
      const appName = getEmployeeName(rawTask.approverId || rawTask.approver, employeesList);
      const revName = getEmployeeName(rawTask.reviewerId || rawTask.reviewer, employeesList);
      const exeName = getEmployeeName(rawTask.empId || rawTask.assignedTo, employeesList);
      
      if (name) {
        const lowerName = name.toLowerCase();
        const foundEmp = employeesList?.find(e => {
          const fn = (e.fullName || e.empNm || e.name || "").toLowerCase();
          return fn && (fn.includes(lowerName) || lowerName.includes(fn));
        });
        if (foundEmp) {
          name = foundEmp.fullName || foundEmp.empNm || foundEmp.name || name;
        }

        if (appName && appName.toLowerCase().includes(lowerName)) { role = "APPROVER"; name = appName; }
        else if (revName && revName.toLowerCase().includes(lowerName)) { role = "REVIEWER"; name = revName; }
        else if (exeName && exeName.toLowerCase().includes(lowerName)) { role = "EXECUTOR"; name = exeName; }
        else if (lowerName.includes("approver")) { role = "APPROVER"; if (appName) name = appName; }
        else if (lowerName.includes("reviewer")) { role = "REVIEWER"; if (revName) name = revName; }
        else if (lowerName.includes("executor")) { role = "EXECUTOR"; if (exeName) name = exeName; }
      } else {
        name = "Team Member";
      }
      
      const initials = name.split(' ').map(n => n[0]).join('').toUpperCase().substring(0, 2) || "TM";
      
      parsed.push({
        id: idx,
        name,
        initials,
        role: role.toUpperCase(),
        action: action.charAt(0).toUpperCase() + action.slice(1),
        text,
        attachments
      });
    });
    
    return parsed;
  };

  // ============================================
  // TASK DETAIL SCREEN RENDERER - DYNAMIC (INLINE HELPER)
  // ============================================
  const renderTaskDetailScreen = (task, onBack) => {
    if (!task) return null;

    const rawTask = task.rawTask || task;

    const getProjectInfo = () => {
      if (task.isIndividual || task.project === "Individual Task") {
        return { isIndividual: true };
      }

      let pName = null;
      let mName = null;

      // 1. Check if rawTask has project_info (e.g. "PRJ-01 - m1")
      if (rawTask.project_info && typeof rawTask.project_info === 'string' && rawTask.project_info.includes(' - ')) {
        const parts = rawTask.project_info.split(' - ');
        if (parts[0] && parts[0].trim()) pName = parts[0].trim();
        if (parts[1] && parts[1].trim()) mName = parts[1].trim();
      }

      // 2. Resolve Milestone via milestonesList or raw properties
      const targetMId = String(rawTask.mId || rawTask.m_id || rawTask.mid || rawTask.drftMId || rawTask.milestoneId || '');
      let targetPrjId = String(rawTask.prjId || rawTask.prj_id || rawTask.prjid || rawTask.projectId || '');

      let foundM = null;
      if (targetMId && milestonesList && milestonesList.length > 0) {
        foundM = milestonesList.find(m => {
          const idStr = String(m.mId || m.m_id || m.mid || m.id || m.milestoneId || '');
          return idStr && idStr === targetMId;
        });
        if (foundM) {
          mName = foundM.mlstnTtl || foundM.title || foundM.name || foundM.mlstn_ttl || foundM.mlstnNm || mName;
          if (!targetPrjId) {
            targetPrjId = String(foundM.prjId || foundM.prj_id || foundM.prjid || foundM.projectId || '');
          }
        }
      }

      if (!mName) {
        const mCandidates = [task.milestone, rawTask.milestoneName, rawTask.mlstnTtl, rawTask.milestoneTitle, rawTask.mlstnNm, rawTask.mlstn_ttl];
        for (const c of mCandidates) {
          if (c && typeof c === 'string' && c.trim() !== '' && c.trim() !== '—' && c.trim() !== 'Internal') {
            mName = c.trim();
            break;
          }
        }
      }

      // Title pattern fallback: "Task Name(Milestone Name)"
      if (!mName && task.title && task.title.includes('(') && task.title.includes(')')) {
        const matchM = task.title.match(/\(([^)]+)\)$/);
        if (matchM && matchM[1]) {
          mName = matchM[1].trim();
        }
      }

      // 3. Resolve Project via projectsList or raw properties
      let foundP = null;
      if (targetPrjId && projectsList && projectsList.length > 0) {
        foundP = projectsList.find(p => {
          const idStr = String(p.prjId || p.prj_id || p.prjid || p.id || p.projectId || '');
          return idStr && idStr === targetPrjId;
        });
        if (foundP) {
          pName = foundP.prjNm || foundP.name || foundP.prj_nm || foundP.prjCd || pName;
        }
      }

      if (pName && projectsList && projectsList.length > 0) {
        // If pName is code like "PRJ-01", try finding full name in projectsList
        const codeMatch = projectsList.find(p => 
          String(p.prjCd || '').toUpperCase() === pName.toUpperCase() ||
          String(p.prjNm || '').toUpperCase() === pName.toUpperCase()
        );
        if (codeMatch) {
          pName = codeMatch.prjNm || codeMatch.name || codeMatch.prj_nm || pName;
        }
      }

      if (!pName || pName === "Internal") {
        const pCandidates = [task.project, rawTask.projectName, rawTask.prjNm, rawTask.prj_nm, rawTask.projectCodeName, rawTask.prjCd];
        for (const c of pCandidates) {
          if (c && typeof c === 'string' && c.trim() !== '' && c.trim() !== 'Internal') {
            pName = c.trim();
            break;
          }
        }
      }

      return {
        isIndividual: false,
        projectName: pName || "Internal",
        milestoneName: mName || "—"
      };
    };

    const projectInfo = getProjectInfo();
    const timeStatus = calculateTimeStatus(rawTask);
    const progressBadge = getProgressBadge(task.status || task.rawStatus);
    const priorityBadge = getPriorityBadge(task.priority);
    
    // Get dynamic action based on current state
    const action = getActionButton(rawTask, currentUserEmpId);
    
    const isOverdue = (() => {
      if (!rawTask?.endDt) return false;
      if (rawTask?.taskSts === "COMPLETED" || rawTask?.taskSts === "CLOSED") return false;
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const dueDate = new Date(rawTask.endDt);
      dueDate.setHours(0, 0, 0, 0);
      return today > dueDate;
    })();

    const isCompleted = task.rawStatus === "COMPLETED" || task.rawStatus === "CLOSED";
    const isDoer = String(rawTask.empId || rawTask.assignedTo) === String(currentUserEmpId);
    const isReviewer = String(rawTask.reviewerId || rawTask.reviewer) === String(currentUserEmpId);
    const isApprover = String(rawTask.approverId || rawTask.approver) === String(currentUserEmpId);

    // Get current progress and process for display
    const currentProgress = task.rawStatus || task.status || "OPEN";
    const currentProcess = rawTask.prcsYesActn || "NONE";
    
    // Determine if task is in review
    const isUnderReview = currentProcess === "PENDING_REVIEWER" || currentProcess === "PENDING_APPROVER" || currentProcess === "UNDER_REVIEW";

    // Disable Rework button for 1st Milestone tasks of any project AND for Assignment/Individual tasks
    const isReworkDisabled = (() => {
      if (!task) return true;
      const raw = task.rawTask || task;

      // Rule 1: Assignment / Individual tasks -> Rework disabled
      if (task.isIndividual || raw.isIndividual || raw.taskSource === "INDIVIDUAL" || !raw.mId) {
        return true;
      }

      // Rule 2: 1st Milestone tasks of any project -> Rework disabled
      const currentMId = raw.mId || raw.mid || task.mId;
      const currentPrjId = raw.prjId || raw.prjid || task.prjId || task.projectId;

      if (!currentMId) return true;

      const projectMilestones = (milestonesList || []).filter(m => {
        const mPrjId = m.prjId || m.prjid || m.prj_id;
        return currentPrjId ? String(mPrjId) === String(currentPrjId) : true;
      }).sort((a, b) => {
        const ordA = a.ordrId || a.ordr_id || a.mId || a.mid || a.id || 0;
        const ordB = b.ordrId || b.ordr_id || b.mId || b.mid || b.id || 0;
        return Number(ordA) - Number(ordB);
      });

      if (projectMilestones.length > 0) {
        const firstMilestone = projectMilestones[0];
        const firstMId = firstMilestone.mId || firstMilestone.mid || firstMilestone.id;
        if (String(currentMId) === String(firstMId)) {
          return true;
        }
      }

      return false;
    })();

    const renderTeamMember = (empId, role, label, fallbackName = null) => {
      if (!empId && !fallbackName) return null;
      let name = getEmployeeName(empId, employeesList);
      if ((!name || name === "Unknown" || name.startsWith("User ")) && fallbackName) {
        name = fallbackName;
      }
      let initials = getEmployeeInitials(empId, employeesList);
      if ((!initials || initials === "UN") && name && name !== "Unknown") {
        const parts = name.trim().split(" ");
        initials = parts.length >= 2 ? (parts[0][0] + parts[1][0]).toUpperCase() : parts[0].substring(0, 2).toUpperCase();
      }
      const photo = getEmployeePhoto(empId, employeesList);
      
      const roleColors = {
        "Assigned By": { bg: "#6366F1", light: "#EEF2FF" },
        "Executor": { bg: "#3B82F6", light: "#DBEAFE" },
        "Reviewer": { bg: "#8B5CF6", light: "#EDE9FE" },
        "Approver": { bg: "#F59E0B", light: "#FEF3C7" }
      };
      const color = roleColors[role] || { bg: "#64748B", light: "#F1F5F9" };

      return (
        <div style={{ 
          display: "flex", 
          alignItems: "center", 
          gap: "12px",
          padding: "8px 12px",
          borderRadius: "8px",
          backgroundColor: color.light,
          border: `1px solid ${color.bg}33`
        }}>
          <div style={{
            width: "40px",
            height: "40px",
            borderRadius: "50%",
            backgroundColor: color.bg,
            color: "white",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: "12px",
            fontWeight: "700",
            overflow: "hidden",
            flexShrink: 0
          }}>
            {photo ? (
              <img 
                src={photo.startsWith('data:') || photo.startsWith('http') ? photo : `data:image/jpeg;base64,${photo}`} 
                alt={name} 
                style={{ width: "100%", height: "100%", objectFit: "cover" }} 
                onError={(e) => {
                  e.target.style.display = "none";
                  e.target.parentElement.textContent = initials || "UN";
                }}
              />
            ) : initials || "UN"}
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontWeight: "600", fontSize: "14px", color: "#0f172a" }}>{name}</div>
            <div style={{ fontSize: "12px", color: color.bg, fontWeight: "500" }}>{role}</div>
          </div>
          <span style={{ 
            fontSize: "10px", 
            fontWeight: "700", 
            color: color.bg,
            backgroundColor: `${color.bg}22`,
            padding: "2px 10px",
            borderRadius: "12px"
          }}>
            {label}
          </span>
        </div>
      );
    };

    const getCurrentStatusDisplay = () => {
      const rawSts = String(rawTask?.taskSts?.statusNm || rawTask?.taskSts || task.rawStatus || task.status || "").toUpperCase();
      const taskStsId = rawTask?.taskSts?.statusId || rawTask?.taskSts;
      if (rawSts === "CLOSED" || rawSts === "COMPLETED" || taskStsId === 4 || isCompleted) {
        return "CLOSED";
      }
      if (currentProcess === "PENDING_REVIEWER" || currentProcess === "PENDING_APPROVER" || currentProcess === "UNDER_REVIEW") {
        return "UNDER_REVIEW";
      }
      if (isOverdue) return "OVERDUE";
      if (currentProgress === "HOLD") return "HOLD";
      if (currentProgress === "OPEN" || currentProgress === "DRAFT") return "OPEN";
      return "WIP";
    };

    const getStatusColor = (status) => {
      if (status === "CLOSED" || status === "COMPLETED") return "#16a34a";
      if (status === "OVERDUE") return "#ef4444";
      if (status === "UNDER_REVIEW") return "#8b5cf6";
      return "#3b82f6";
    };

    const getStatusBgColor = (status) => {
      if (status === "CLOSED" || status === "COMPLETED") return "#dcfce7";
      if (status === "OVERDUE") return "#fee2e2";
      if (status === "UNDER_REVIEW") return "#f3e8ff";
      if (status === "IN_PROGRESS" || status === "WIP") return "#fef3c7";
      return "#f1f5f9";
    };

    // Render action buttons based on dynamic state
    const renderActionButtons = () => {
      if (isCompleted) {
        return null;
      }

      // REVIEWER ACTIONS
      if (isReviewer && (currentProcess === "PENDING_REVIEWER" || currentProcess === "UNDER_REVIEW")) {
        return (
          <div style={{ display: "flex", flexDirection: "column", gap: "8px", width: "100%" }}>
            <button 
              className="cc-btn danger" 
              onClick={() => {
                setShowDenyForm(true);
                setIsRaiseRequest(false);
                setDenyData({ type: "", reason: "", milestone: "", deliverable: "", impact: "Medium" });
              }} 
              style={{ borderRadius: "6px", backgroundColor: "#ef4444", color: "white", border: "none", width: "100%" }}
            >
              Denied
            </button>
            <button 
              className="cc-btn primary" 
              onClick={async () => {
                await handleReviewerApprove(task);
                onBack();
              }} 
              style={{ borderRadius: "6px", backgroundColor: "#10b981", border: "none", color: "white", width: "100%" }}
            >
              Approve
            </button>
          </div>
        );
      }

      // APPROVER ACTIONS
      if (isApprover && currentProcess === "PENDING_APPROVER") {
        return (
          <div style={{ display: "flex", flexDirection: "column", gap: "8px", width: "100%" }}>
            <button 
              className="cc-btn danger" 
              onClick={() => {
                setShowDenyForm(true);
                setIsRaiseRequest(false);
                setDenyData({ type: "", reason: "", milestone: "", deliverable: "", impact: "Medium" });
              }} 
              style={{ borderRadius: "6px", backgroundColor: "#ef4444", color: "white", border: "none", width: "100%" }}
            >
              Denied
            </button>
            <button 
              className="cc-btn primary" 
              onClick={async () => {
                await handleApproverApprove(task);
                onBack();
              }} 
              style={{ borderRadius: "6px", backgroundColor: "#10b981", border: "none", color: "white", width: "100%" }}
            >
              Approve
            </button>
          </div>
        );
      }

      // EXECUTOR ACTIONS - DYNAMIC BASED ON PROGRESS & PROCESS
      if (isDoer) {
        // OPEN / DRAFT -> Start
        if (currentProgress === "OPEN" || currentProgress === "DRAFT") {
          return (
            <div style={{ display: "flex", flexDirection: "column", gap: "8px", width: "100%" }}>
              <button 
                className="cc-btn primary" 
                onClick={async () => {
                  await handleStartTask(task);
                }} 
                style={{ borderRadius: "6px", backgroundColor: "#3b82f6", border: "none", color: "white", width: "100%" }}
              >
                Start
              </button>
            </div>
          );
        }

        // WORK_IN_PROGRESS with NONE or REWORK or REASSIGN -> Update / Submit Review / Mark as Complete
        if ((currentProgress === "WIP" || currentProgress === "IN_PROGRESS") && 
            (currentProcess === "NONE" || currentProcess === "REWORK" || currentProcess === "REASSIGN" || !currentProcess)) {
          const allChecked = updateChecklist.length > 0 && updateChecklist.every(c => c.completed);
          const hasWorkflow = rawTask?.prcsFlg === true || rawTask?.prcsFlg === 'YES' || rawTask?.prcsFlg === 1 || rawTask?.prcsFlg === 'true';
          
          let label = "Save Progress";
          if (allChecked || updateChecklist.length === 0) {
            label = hasWorkflow ? "Submit Review" : "Mark as Complete";
          }
          
          return (
            <div style={{ display: "flex", flexDirection: "column", gap: "8px", width: "100%" }}>
              <button 
                className="cc-btn primary" 
                onClick={async () => {
                  if (label === "Mark as Complete") {
                    await handleCompleteTask(task);
                  } else if (label === "Submit Review") {
                    await handleUpdateProgress();
                    await handleSubmitReview(task);
                  } else {
                    await handleSaveProgress();
                  }
                }} 
                style={{ 
                  borderRadius: "6px", 
                  backgroundColor: label === "Mark as Complete" ? "#16a34a" : label === "Submit Review" ? "#8B5CF6" : "#0F172A", 
                  border: "none", 
                  color: "white", 
                  width: "100%",
                  fontWeight: "600"
                }}
              >
                {label}
              </button>
            </div>
          );
        }

        // WORK_IN_PROGRESS with UNDER_REVIEW -> Send Reminder
        if ((currentProgress === "WIP" || currentProgress === "IN_PROGRESS" || currentProgress === "UNDER_REVIEW") && 
            (currentProcess === "PENDING_REVIEWER" || currentProcess === "PENDING_APPROVER")) {
          const targetId = rawTask.reviewerId || rawTask.approverId;
          const role = rawTask.reviewerId ? "Reviewer" : "Approver";
          
          return (
            <div style={{ display: "flex", flexDirection: "column", gap: "8px", width: "100%" }}>
              <button 
                className="cc-btn primary" 
                onClick={() => handleSendReminder(targetId, role)} 
                style={{ borderRadius: "6px", backgroundColor: "#0F172A", border: "none", color: "white", width: "100%" }}
              >
                Send Reminder
              </button>
            </div>
          );
        }

        // HOLD -> Resume
        if (currentProgress === "HOLD") {
          return (
            <div style={{ display: "flex", flexDirection: "column", gap: "8px", width: "100%" }}>
              <button 
                className="cc-btn primary" 
                onClick={async () => {
                  await handleResumeTask(task);
                }} 
                style={{ borderRadius: "6px", backgroundColor: "#3b82f6", border: "none", color: "white", width: "100%" }}
              >
                Resume
              </button>
            </div>
          );
        }
      }

      return null;
    };

    return (
      <div style={{ 
        width: "100%",
        background: "#f8fafc",
        borderRadius: "12px",
        padding: "0",
        marginTop: "0",
        maxHeight: "calc(100vh - 180px)",
        overflowY: "auto"
      }}>
        {/* Header */}
        <div style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "16px 24px",
          background: "white",
          borderBottom: "1px solid #e2e8f0",
          borderRadius: "12px 12px 0 0",
          marginBottom: "24px",
          flexWrap: "wrap",
          gap: "12px",
          position: "sticky",
          top: 0,
          zIndex: 10
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
            <button
              onClick={onBack}
              style={{
                display: "flex",
                alignItems: "center",
                gap: "8px",
                background: "none",
                border: "1px solid #e2e8f0",
                borderRadius: "8px",
                padding: "8px 16px",
                cursor: "pointer",
                color: "#475569",
                fontWeight: 500,
                fontSize: "14px"
              }}
              onMouseEnter={(e) => e.currentTarget.style.backgroundColor = "#f8fafc"}
              onMouseLeave={(e) => e.currentTarget.style.backgroundColor = "transparent"}
            >
              <ArrowLeft size={18} />
              Back
            </button>
            <div>
              <div style={{ fontSize: "12px", color: "#94a3b8", fontWeight: "500" }}>{task.id}</div>
              <div style={{ fontSize: "18px", fontWeight: "600", color: "#0f172a" }}>{task.title}</div>
            </div>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
            <span className="cc-status-badge" style={{
              backgroundColor: progressBadge.bg,
              color: progressBadge.color,
              padding: "4px 14px",
              borderRadius: "20px",
              fontSize: "12px",
              fontWeight: "600"
            }}>
              {progressBadge.label}
            </span>
            {action && action.action !== "view" && !isCompleted && (
              <button
                onClick={async () => {
                  if (action.action === "start") {
                    await handleStartTask(task);
                  } else if (action.action === "update") {
                    // Already in detail view
                  } else if (action.action === "review") {
                    // Already in detail view
                  } else if (action.action === "approve") {
                    // Already in detail view
                  }
                }}
                style={{
                  backgroundColor: action.variant === "primary" ? "#3B82F6" :
                                action.variant === "warning" ? "#F59E0B" :
                                action.variant === "success" ? "#10B981" :
                                action.variant === "review" ? "#8B5CF6" : "#64748B",
                  color: "white",
                  border: "none",
                  padding: "8px 20px",
                  borderRadius: "8px",
                  cursor: "pointer",
                  fontSize: "14px",
                  fontWeight: "600",
                  display: "flex",
                  alignItems: "center",
                  gap: "8px"
                }}
              >
                {action.action === "start" && <Play size={16} />}
                {action.action === "update" && <RotateCw size={16} />}
                {action.action === "review" && <Eye size={16} />}
                {action.action === "approve" && <Check size={16} />}
                {action.label}
              </button>
            )}
          </div>
        </div>

        {/* Main Content */}
        <div style={{
          display: "grid",
          gridTemplateColumns: "1fr 340px",
          gap: "24px",
          padding: "0 24px 24px 24px"
        }}>
          {/* Left Column */}
          <div>
            {/* Task Details Card - Shows Progress, Process, Priority, Time */}
            <div style={{
              backgroundColor: "white",
              borderRadius: "12px",
              border: "1px solid #e2e8f0",
              padding: "24px",
              marginBottom: "24px"
            }}>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
                <div>
                  <div style={{ fontSize: "12px", fontWeight: "600", color: "#94a3b8", textTransform: "uppercase", letterSpacing: "0.5px", marginBottom: "4px" }}>
                    <Flag size={14} style={{ display: "inline", marginRight: "4px" }} /> Priority
                  </div>
                  <span className="cc-status-badge" style={{
                    backgroundColor: priorityBadge.bg,
                    color: priorityBadge.color,
                    padding: "2px 10px",
                    borderRadius: "12px",
                    fontSize: "13px",
                    fontWeight: "600"
                  }}>
                    {task.priority || "Normal"}
                  </span>
                </div>
                <div>
                  <div style={{ fontSize: "12px", fontWeight: "600", color: "#94a3b8", textTransform: "uppercase", letterSpacing: "0.5px", marginBottom: "4px" }}>
                    <Calendar size={14} style={{ display: "inline", marginRight: "4px" }} /> Due Date
                  </div>
                  <div style={{ fontSize: "14px", fontWeight: "600", color: isOverdue ? "#EF4444" : "#0f172a" }}>
                    {formatDate(task.dueDate) || "—"}
                    {isOverdue && <span style={{ fontSize: "12px", color: "#EF4444", marginLeft: "8px" }}>⚠️ Overdue</span>}
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", fontWeight: "600", color: "#94a3b8", textTransform: "uppercase", letterSpacing: "0.5px", marginBottom: "4px" }}>
                    <ClockIcon size={14} style={{ display: "inline", marginRight: "4px" }} /> Time Status
                  </div>
                  <div style={{ fontSize: "14px", fontWeight: "600", color: timeStatus ? timeStatus.color : "#64748b" }}>
                    {timeStatus ? timeStatus.title : "—"}
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", fontWeight: "600", color: "#94a3b8", textTransform: "uppercase", letterSpacing: "0.5px", marginBottom: "4px" }}>
                    <CheckSquare size={14} style={{ display: "inline", marginRight: "4px" }} /> Progress
                  </div>
                  <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                    <div style={{ flex: 1, height: "6px", backgroundColor: "#e2e8f0", borderRadius: "3px", overflow: "hidden" }}>
                      <div style={{
                        width: `${updateProgressVal || 0}%`,
                        height: "100%",
                        backgroundColor: getStatusColor(getCurrentStatusDisplay()),
                        borderRadius: "3px",
                        transition: "width 0.3s ease"
                      }} />
                    </div>
                    <span style={{ fontSize: "14px", fontWeight: "600", color: "#0f172a" }}>{updateProgressVal || 0}%</span>
                  </div>
                </div>
              </div>

              {/* Project / Milestone or Individual Task Badge */}
              <div style={{ marginTop: "20px", paddingTop: "16px", borderTop: "1px solid #f1f5f9" }}>
                {projectInfo.isIndividual ? (
                  <span style={{
                    backgroundColor: "#dbeafe",
                    color: "#2563eb",
                    padding: "6px 14px",
                    borderRadius: "8px",
                    fontSize: "13px",
                    fontWeight: "600",
                    display: "inline-block"
                  }}>
                    Individual Task
                  </span>
                ) : (
                  <div>
                    <div style={{ fontSize: "13px", color: "#64748b" }}>
                      <span style={{ fontWeight: "600", color: "#0f172a" }}>Project:</span> {projectInfo.projectName}
                    </div>
                    <div style={{ fontSize: "13px", color: "#64748b", marginTop: "4px" }}>
                      <span style={{ fontWeight: "600", color: "#0f172a" }}>Milestone:</span> {projectInfo.milestoneName}
                    </div>
                  </div>
                )}
              </div>

              {/* Process Status Details */}
              {rawTask?.prcsYesActn && rawTask?.prcsYesActn !== "NONE" && (
                <div style={{ marginTop: "16px", paddingTop: "16px", borderTop: "1px solid #f1f5f9" }}>
                  <div style={{ fontSize: "12px", fontWeight: "600", color: "#94a3b8", textTransform: "uppercase", letterSpacing: "0.5px", marginBottom: "4px" }}>
                    <RefreshCw size={14} style={{ display: "inline", marginRight: "4px" }} /> Process Status
                  </div>
                  <div style={{ fontSize: "14px", fontWeight: "600", color: "#0f172a" }}>
                    {rawTask.prcsYesActn === "PENDING_REVIEWER" && "⏳ Under Review (Reviewer)"}
                    {rawTask.prcsYesActn === "PENDING_APPROVER" && "⏳ Under Review (Approver)"}
                    {rawTask.prcsYesActn === "REWORK" && <><RefreshCw size={16} color="#F97316" style={{ display: "inline", marginRight: "6px" }} /><span style={{ color: "#F97316" }}>Rework Required</span></>}
                    {rawTask.prcsYesActn === "REASSIGN" && <><ReassignIcon size={16} color="#4F46E5" style={{ display: "inline", marginRight: "6px" }} /><span style={{ color: "#4F46E5" }}>Reassigned</span></>}
                  </div>
                </div>
              )}
            </div>

            {/* Checklist Section */}
            <div style={{
              backgroundColor: "white",
              borderRadius: "12px",
              border: "1px solid #e2e8f0",
              padding: "24px",
              marginBottom: "24px"
            }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" }}>
                <div style={{ fontSize: "16px", fontWeight: "600", color: "#0f172a" }}>
                  <ListChecks size={18} style={{ display: "inline", marginRight: "8px" }} />
                  Checklist
                </div>
                <div style={{ fontSize: "14px", fontWeight: "600", color: "#64748b" }}>
                  {updateChecklist.filter(c => c.completed).length}/{updateChecklist.length}
                </div>
              </div>
              {updateChecklist.length === 0 ? (
                <div style={{ textAlign: "center", padding: "20px", color: "#64748b" }}>
                  No checklist items defined for this task.
                </div>
              ) : (
                <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
                  {updateChecklist.map(item => (
                    <div 
                      key={item.id} 
                      onClick={() => handleToggleChecklist(item.id)} 
                      style={{ 
                        display: "flex",
                        alignItems: "center",
                        gap: "12px",
                        padding: "10px 12px",
                        backgroundColor: item.completed ? "#f0fdf4" : "#f8fafc",
                        borderRadius: "8px",
                        border: `1px solid ${item.completed ? "#bbf7d0" : "#e2e8f0"}`,
                        cursor: isCompleted || isUnderReview ? "not-allowed" : "pointer",
                        opacity: isCompleted || isUnderReview ? 0.7 : 1
                      }}
                    >
                      <div style={{
                        width: "20px",
                        height: "20px",
                        borderRadius: "4px",
                        backgroundColor: item.completed ? "#22c55e" : "white",
                        border: `2px solid ${item.completed ? "#22c55e" : "#cbd5e1"}`,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        flexShrink: 0
                      }}>
                        {item.completed && <Check size={12} color="white" strokeWidth={3} />}
                      </div>
                      <span style={{
                        fontSize: "14px",
                        color: item.completed ? "#166534" : "#0f172a",
                        textDecoration: item.completed ? "line-through" : "none",
                        flex: 1
                      }}>
                        {item.text}
                      </span>
                      <span className={`myt-chk-status ${item.completed ? 'completed' : 'pending'}`}>
                        {item.completed ? 'Completed' : 'Pending'}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Description */}
            {task.description && (
              <div style={{
                backgroundColor: "white",
                borderRadius: "12px",
                border: "1px solid #e2e8f0",
                padding: "24px",
                marginBottom: "24px"
              }}>
                <div style={{ fontSize: "14px", fontWeight: "600", color: "#0f172a", marginBottom: "8px" }}>
                  <FileText size={18} style={{ display: "inline", marginRight: "8px" }} />
                  Description
                </div>
                <div style={{ fontSize: "14px", color: "#475569", lineHeight: "1.6" }}>
                  {task.description}
                </div>
              </div>
            )}

            {/* Task Attachments Card */}
            <div style={{
              backgroundColor: "white",
              borderRadius: "12px",
              border: "1px solid #e2e8f0",
              padding: "24px",
              marginBottom: "24px"
            }}>
              <div style={{ fontSize: "15px", fontWeight: "700", color: "#0f172a", marginBottom: "16px", display: "flex", alignItems: "center", gap: "8px" }}>
                <Paperclip size={18} color="#0f172a" />
                Task Attachments {taskAttachments.length > 0 ? `(${taskAttachments.length})` : ''}
              </div>

              {loadingAttachments ? (
                <div style={{ padding: "16px", textAlign: "center", color: "#64748b", fontSize: "14px" }}>
                  <Loader2 size={16} className="spinning" style={{ display: "inline", marginRight: "8px" }} /> Loading attachments...
                </div>
              ) : taskAttachments.length === 0 ? (
                <div style={{ padding: "16px", backgroundColor: "#f8fafc", borderRadius: "8px", border: "1px solid #e2e8f0", fontSize: "13px", color: "#64748b" }}>
                  No attachments uploaded for this task.
                </div>
              ) : (
                  <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))", gap: "16px" }}>
                    {taskAttachments.map((att, idx) => {
                      const fileName = att.fileNm || att.fileName || `Attachment ${idx + 1}`;
                      let rawUrl = att.atPath || att.url || att.filePath || "#";
                      if (typeof rawUrl === "string" && rawUrl.trim().startsWith("{")) {
                        try {
                          const parsed = JSON.parse(rawUrl);
                          if (parsed && parsed.url) rawUrl = parsed.url;
                        } catch (e) {}
                      }
                      let url = rawUrl;
                      if (typeof rawUrl === "string" && rawUrl.startsWith("http") && (rawUrl.includes("supabase.co") || rawUrl.includes("/storage/v1/object/"))) {
                        url = `${apiBaseUrl}/api/storage/view?url=${encodeURIComponent(rawUrl)}`;
                      }
                      const isImage = /\.(png|jpe?g|gif|webp|svg)($|\?)/i.test(fileName) || /\.(png|jpe?g|gif|webp|svg)($|\?)/i.test(url) || (url && url.startsWith('data:image'));
                      const isPdf = /\.pdf($|\?)/i.test(fileName) || /\.pdf($|\?)/i.test(url);
                      const isZip = /\.(zip|rar|7z|tar|gz)($|\?)/i.test(fileName) || /\.(zip|rar|7z|tar|gz)($|\?)/i.test(url);

                      const downloadUrl = `${apiBaseUrl}/api/storage/download?url=${encodeURIComponent(rawUrl)}&name=${encodeURIComponent(fileName)}`;

                      return (
                        <div key={att.fileId || idx} style={{
                          border: "1px solid #e2e8f0",
                          borderRadius: "10px",
                          overflow: "hidden",
                          backgroundColor: "#f8fafc",
                          display: "flex",
                          flexDirection: "column",
                          transition: "all 0.2s ease"
                        }}>
                          {/* Preview Thumbnail for Image or File Header */}
                          {isImage ? (
                            <div style={{ height: "130px", backgroundColor: "#0f172a", position: "relative", overflow: "hidden" }}>
                              <img 
                                src={url.startsWith('http') || url.startsWith('data:') ? url : `data:image/jpeg;base64,${url}`} 
                                alt={fileName} 
                                style={{ width: "100%", height: "100%", objectFit: "cover" }} 
                              />
                            </div>
                          ) : (
                            <div style={{ height: "90px", backgroundColor: isPdf ? "#fee2e2" : isZip ? "#f3e8ff" : "#e0f2fe", display: "flex", alignItems: "center", justifyContent: "center", flexDirection: "column", gap: "4px" }}>
                              <FileText size={32} color={isPdf ? "#ef4444" : isZip ? "#9333ea" : "#0284c7"} />
                              {isZip && <span style={{ fontSize: "10px", fontWeight: "700", color: "#9333ea", backgroundColor: "#e9d5ff", padding: "1px 6px", borderRadius: "4px" }}>ZIP ARCHIVE</span>}
                            </div>
                          )}

                          {/* File details & view/download button */}
                          <div style={{ padding: "12px", flex: 1, display: "flex", flexDirection: "column", justifyContent: "space-between", gap: "8px" }}>
                            <div style={{ fontSize: "13px", fontWeight: "600", color: "#0f172a", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }} title={fileName}>
                              {fileName}
                            </div>
                            <button 
                              type="button"
                              onClick={() => setPreviewModalFile({ name: fileName, url: url, downloadUrl: downloadUrl, isImage: isImage, isPdf: isPdf })}
                              style={{
                                fontSize: "12px",
                                fontWeight: "600",
                                color: "#2563eb",
                                border: "none",
                                cursor: "pointer",
                                display: "inline-flex",
                                alignItems: "center",
                                gap: "4px",
                                backgroundColor: "#dbeafe",
                                padding: "6px 12px",
                                borderRadius: "6px",
                                width: "fit-content"
                              }}
                            >
                              <Eye size={13} /> View / Open File
                            </button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>

            {/* Attachment Preview Modal */}
            {previewModalFile && (
              <div style={{
                position: "fixed",
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                backgroundColor: "rgba(15, 23, 42, 0.8)",
                backdropFilter: "blur(4px)",
                zIndex: 99999,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                padding: "20px"
              }}>
                <div style={{
                  backgroundColor: "white",
                  borderRadius: "16px",
                  width: "90%",
                  maxWidth: "900px",
                  maxHeight: "90vh",
                  display: "flex",
                  flexDirection: "column",
                  boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.3)",
                  overflow: "hidden"
                }}>
                  {/* Modal Header */}
                  <div style={{
                    padding: "16px 24px",
                    borderBottom: "1px solid #e2e8f0",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    backgroundColor: "#fafbfc"
                  }}>
                    <div style={{ fontWeight: "700", fontSize: "16px", color: "#0f172a", display: "flex", alignItems: "center", gap: "8px" }}>
                      <FileText size={18} color="#2563eb" />
                      {previewModalFile.name}
                    </div>
                    <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                      <a
                        href={previewModalFile.downloadUrl}
                        download={previewModalFile.name}
                        style={{
                          padding: "6px 14px",
                          backgroundColor: "#16a34a",
                          color: "white",
                          borderRadius: "6px",
                          fontSize: "13px",
                          fontWeight: "600",
                          textDecoration: "none",
                          display: "inline-flex",
                          alignItems: "center",
                          gap: "6px"
                        }}
                      >
                        📥 Download File
                      </a>
                      <a
                        href={previewModalFile.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        style={{
                          padding: "6px 14px",
                          backgroundColor: "#2563eb",
                          color: "white",
                          borderRadius: "6px",
                          fontSize: "13px",
                          fontWeight: "600",
                          textDecoration: "none",
                          display: "inline-flex",
                          alignItems: "center",
                          gap: "6px"
                        }}
                      >
                        🔗 Open View
                      </a>
                      <button
                        onClick={() => setPreviewModalFile(null)}
                        style={{
                          background: "#f1f5f9",
                          border: "none",
                          borderRadius: "50%",
                          width: "32px",
                          height: "32px",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          cursor: "pointer",
                          color: "#64748b"
                        }}
                      >
                        <X size={18} />
                      </button>
                    </div>
                  </div>

                  {/* Modal Body */}
                  <div style={{
                    padding: "24px",
                    overflowY: "auto",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    backgroundColor: "#0f172a",
                    minHeight: "350px"
                  }}>
                    {previewModalFile.isImage ? (
                      <img
                        src={previewModalFile.url}
                        alt={previewModalFile.name}
                        style={{ maxWidth: "100%", maxHeight: "70vh", objectFit: "contain", borderRadius: "8px" }}
                      />
                    ) : previewModalFile.isPdf ? (
                      <iframe
                        src={previewModalFile.url}
                        title={previewModalFile.name}
                        style={{ width: "100%", height: "70vh", border: "none", borderRadius: "8px", backgroundColor: "white" }}
                      />
                    ) : (
                      <div style={{ textAlign: "center", color: "white", padding: "40px" }}>
                        <FileText size={64} color="#94a3b8" style={{ marginBottom: "16px" }} />
                        <div style={{ fontSize: "16px", fontWeight: "600" }}>{previewModalFile.name}</div>
                        <a
                          href={previewModalFile.url}
                          download={previewModalFile.name}
                          target="_blank"
                          rel="noopener noreferrer"
                          style={{
                            marginTop: "16px",
                            display: "inline-block",
                            padding: "10px 20px",
                            backgroundColor: "#2563eb",
                            color: "white",
                            borderRadius: "6px",
                            textDecoration: "none",
                            fontWeight: "600"
                          }}
                        >
                          Download File
                        </a>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            )}

            {/* Remarks History */}
            {(rawTask?.addlRem || rawTask?.remarks) && (
              <div style={{
                backgroundColor: "white",
                borderRadius: "12px",
                border: "1px solid #e2e8f0",
                padding: "24px",
                marginBottom: "24px"
              }}>
                <div style={{ fontSize: "15px", fontWeight: "700", color: "#0f172a", marginBottom: "16px", display: "flex", alignItems: "center", gap: "8px" }}>
                  <MessageSquare size={18} color="#0f172a" />
                  Remarks History
                </div>
                
                <div style={{
                  backgroundColor: "#f8fafc",
                  borderRadius: "10px",
                  border: "1px solid #e2e8f0",
                  padding: "16px",
                  display: "flex",
                  flexDirection: "column",
                  gap: "12px"
                }}>
                  {parseRemarksHistory(rawTask.addlRem || rawTask.remarks, task, employeesList).map((rem) => (
                    <div key={rem.id} style={{
                      backgroundColor: "white",
                      borderRadius: "8px",
                      border: "1px solid #e2e8f0",
                      padding: "16px 20px",
                      display: "flex",
                      alignItems: "flex-start",
                      gap: "16px"
                    }}>
                      {/* Avatar Circle */}
                      <div style={{
                        width: "40px",
                        height: "40px",
                        borderRadius: "50%",
                        backgroundColor: "#3b82f6",
                        color: "white",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        fontWeight: "700",
                        fontSize: "13px",
                        flexShrink: 0
                      }}>
                        {rem.initials}
                      </div>
                      
                      {/* Main Info */}
                      <div style={{ flex: 1 }}>
                        <div style={{ display: "flex", alignItems: "center", gap: "10px", flexWrap: "wrap", marginBottom: "6px" }}>
                          <span style={{ fontSize: "15px", fontWeight: "700", color: "#0f172a" }}>{rem.name}</span>
                          <span style={{
                            backgroundColor: "#fef3c7",
                            color: "#d97706",
                            fontSize: "11px",
                            fontWeight: "700",
                            padding: "2px 8px",
                            borderRadius: "4px",
                            letterSpacing: "0.5px"
                          }}>
                            {rem.role}
                          </span>
                          <span style={{
                            backgroundColor: rem.action?.toLowerCase().includes("rework") ? "#FFF7ED" : (rem.action?.toLowerCase().includes("reassign") ? "#EEF2FF" : "#FEF3C7"),
                            color: rem.action?.toLowerCase().includes("rework") ? "#F97316" : (rem.action?.toLowerCase().includes("reassign") ? "#4F46E5" : "#D97706"),
                            fontSize: "12px",
                            fontWeight: "600",
                            padding: "2px 10px",
                            borderRadius: "12px",
                            display: "inline-flex",
                            alignItems: "center",
                            gap: "4px"
                          }}>
                            {rem.action?.toLowerCase().includes("rework") && <RefreshCw size={13} color="#F97316" />}
                            {rem.action?.toLowerCase().includes("reassign") && <ReassignIcon size={13} color="#4F46E5" />}
                            {rem.action}
                          </span>
                        </div>
                        <div style={{ fontSize: "14px", color: "#475569", lineHeight: "1.5" }}>
                          {rem.text}
                        </div>
                        {rem.attachments && rem.attachments.length > 0 && (
                          <div style={{ marginTop: "8px", display: "flex", flexWrap: "wrap", gap: "8px" }}>
                            {rem.attachments.map((att, attIdx) => (
                              <a
                                key={attIdx}
                                href={att.url}
                                target="_blank"
                                rel="noopener noreferrer"
                                style={{
                                  display: "inline-flex",
                                  alignItems: "center",
                                  gap: "6px",
                                  padding: "4px 10px",
                                  backgroundColor: "#f1f5f9",
                                  color: "#2563eb",
                                  borderRadius: "6px",
                                  fontSize: "12px",
                                  fontWeight: "600",
                                  textDecoration: "none",
                                  border: "1px solid #cbd5e1"
                                }}
                              >
                                <Paperclip size={13} /> {att.name || 'Attachment'}
                              </a>
                            ))}
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Add Remarks & Evidence */}
            {!isCompleted && isDoer && !isUnderReview && (
              <div style={{
                backgroundColor: "white",
                borderRadius: "12px",
                border: "1px solid #e2e8f0",
                padding: "24px"
              }}>
                <div style={{ fontSize: "14px", fontWeight: "600", color: "#0f172a", marginBottom: "12px" }}>
                  <MessageSquare size={18} style={{ display: "inline", marginRight: "8px" }} />
                  Add Remarks <span style={{ fontWeight: "400", color: "#64748b" }}>(Optional)</span>
                </div>
                <textarea
                  className="myt-remarks-input"
                  placeholder="Enter remarks..."
                  value={updateRemarks}
                  onChange={(e) => setUpdateRemarks(e.target.value)}
                  style={{
                    width: "100%",
                    minHeight: "80px",
                    padding: "10px 12px",
                    border: "1px solid #cbd5e1",
                    borderRadius: "6px",
                    fontSize: "13.5px",
                    fontFamily: "inherit",
                    resize: "vertical",
                    outline: "none",
                    background: "#fff",
                    color: "#0f172a",
                    marginBottom: "12px"
                  }}
                  disabled={isCompleted}
                />
                <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                  <label className="myt-file-upload-btn" style={{ 
                    padding: "8px 16px",
                    backgroundColor: "#f8fafc",
                    border: "1px solid #cbd5e1",
                    borderRadius: "6px",
                    fontSize: "13px",
                    fontWeight: "500",
                    color: "#334155",
                    cursor: isCompleted ? "not-allowed" : "pointer",
                    opacity: isCompleted ? 0.6 : 1
                  }}>
                    Choose Files
                    <input type="file" style={{ display: "none" }} disabled={isCompleted} />
                  </label>
                  <span style={{ fontSize: "13px", color: "#64748b" }}>No file chosen</span>
                </div>
              </div>
            )}
          </div>

          {/* Right Column - Sidebar */}
          <div>
            {/* Team Members */}
            <div style={{
              backgroundColor: "white",
              borderRadius: "12px",
              border: "1px solid #e2e8f0",
              padding: "20px",
              marginBottom: "20px"
            }}>
              <div style={{ fontSize: "15px", fontWeight: "600", color: "#0f172a", marginBottom: "14px" }}>
                <Users size={18} style={{ display: "inline", marginRight: "8px" }} />
                Team
              </div>
              <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
                {(task.isIndividual || projectInfo.isIndividual || rawTask?.assignedBy || rawTask?.assigned_by) && (
                  renderTeamMember(
                    rawTask?.assignedBy || rawTask?.assigned_by || rawTask?.createdBy,
                    "Assigned By",
                    "AB",
                    rawTask?.assignedByNm || rawTask?.assignedByName
                  )
                )}
                {renderTeamMember(rawTask?.empId || rawTask?.assignedTo, "Executor", "EX")}
                {renderTeamMember(rawTask?.reviewerId || rawTask?.reviewer, "Reviewer", "RV")}
                {renderTeamMember(rawTask?.approverId || rawTask?.approver, "Approver", "AP")}
              </div>
            </div>

            {/* Status Details - Dynamic */}
            <div style={{
              backgroundColor: "white",
              borderRadius: "12px",
              border: "1px solid #e2e8f0",
              padding: "20px",
              marginBottom: "20px"
            }}>
              <div style={{ fontSize: "15px", fontWeight: "600", color: "#0f172a", marginBottom: "12px" }}>
                <AlertCircle size={18} style={{ display: "inline", marginRight: "8px" }} />
                Status Details
              </div>
              <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
                <div style={{ display: "flex", justifyContent: "space-between", padding: "6px 0", borderBottom: "1px solid #f1f5f9" }}>
                  <span style={{ fontSize: "13px", color: "#64748b" }}>Progress Status</span>
                  <span className="cc-status-badge" style={{
                    backgroundColor: getStatusBgColor(getCurrentStatusDisplay()),
                    color: getStatusColor(getCurrentStatusDisplay()),
                    padding: "2px 10px",
                    borderRadius: "12px",
                    fontSize: "12px",
                    fontWeight: "600"
                  }}>
                    {getCurrentStatusDisplay()}
                  </span>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", padding: "6px 0", borderBottom: "1px solid #f1f5f9" }}>
                  <span style={{ fontSize: "13px", color: "#64748b" }}>Process</span>
                  <span style={{ fontSize: "13px", fontWeight: "600", color: "#0f172a" }}>
                    {currentProcess === "NONE" ? "None" : currentProcess}
                  </span>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", padding: "6px 0", borderBottom: "1px solid #f1f5f9" }}>
                  <span style={{ fontSize: "13px", color: "#64748b" }}>Priority</span>
                  <span style={{ fontSize: "13px", fontWeight: "600", color: "#0f172a" }}>
                    {task.priority || "Normal"}
                  </span>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", padding: "6px 0" }}>
                  <span style={{ fontSize: "13px", color: "#64748b" }}>Assigned To</span>
                  <span style={{ fontSize: "13px", fontWeight: "500", color: "#0f172a" }}>
                    {getEmployeeName(rawTask?.empId || rawTask?.assignedTo, employeesList) || "Unassigned"}
                  </span>
                </div>
              </div>
            </div>

            {/* Action Buttons - Dynamic */}
            {!isCompleted && renderActionButtons() && (
              <div style={{
                backgroundColor: "white",
                borderRadius: "12px",
                border: "1px solid #e2e8f0",
                padding: "20px"
              }}>
                <div style={{ fontSize: "15px", fontWeight: "600", color: "#0f172a", marginBottom: "14px" }}>
                  <Play size={18} style={{ display: "inline", marginRight: "8px" }} />
                  Actions
                </div>
                {renderActionButtons()}
              </div>
            )}
          </div>
        </div>

        {/* Deny / Raise Request Form - Full Width at Bottom */}
        {showDenyForm && (
          <div style={{
            backgroundColor: "white",
            borderRadius: "12px",
            border: "1px solid #e2e8f0",
            padding: "32px",
            marginTop: "24px",
            boxShadow: "0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)",
            animation: "fadeInUp 0.3s ease-out"
          }}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "24px", paddingBottom: "16px", borderBottom: "1px solid #f1f5f9" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
                <span style={{ fontSize: "18px", fontWeight: "700", color: "#0f172a" }}>Raise Request</span>
                {/* Toggle Switch */}
                <div 
                  onClick={() => {
                    const newToggleState = !isRaiseRequest;
                    setIsRaiseRequest(newToggleState);
                    setDenyData({...denyData, type: newToggleState ? (isReworkDisabled ? "REASSIGN" : "REWORK") : ""});
                  }}
                  style={{
                    width: "48px", height: "26px", borderRadius: "13px",
                    backgroundColor: isRaiseRequest ? "#3b82f6" : "#cbd5e1",
                    position: "relative", cursor: "pointer", transition: "all 0.3s ease"
                  }}
                >
                  <div style={{
                    width: "20px", height: "20px", borderRadius: "50%",
                    backgroundColor: "white", position: "absolute", top: "3px",
                    left: isRaiseRequest ? "25px" : "3px", transition: "all 0.3s ease",
                    boxShadow: "0 1px 3px rgba(0,0,0,0.2)"
                  }} />
                </div>
              </div>
              <button onClick={() => setShowDenyForm(false)} style={{ background: "#f1f5f9", borderRadius: "50%", padding: "8px", border: "none", cursor: "pointer", color: "#64748b", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <X size={20} />
              </button>
            </div>

            {isRaiseRequest ? (
              <div style={{ paddingTop: "8px" }}>
                {(() => {
                  const currentRawTask = task?.rawTask || task || {};
                  const currentMId = currentRawTask.mId || currentRawTask.mid;
                  const currentMilestoneObj = (milestonesList || []).find(m => String(m.mId || m.mid || m.id) === String(currentMId));
                  const currentPrjId = currentRawTask.prjId || currentRawTask.prjid || currentMilestoneObj?.prjId || currentMilestoneObj?.prjid;

                  const projectMilestones = (milestonesList || []).filter(m => 
                    currentPrjId ? String(m.prjId || m.prjid) === String(currentPrjId) : true
                  );

                  const selectedMId = denyData.milestone;
                  const matchingTasks = (tasks || []).filter(t => {
                    const tMId = t.rawTask?.mId || t.rawTask?.mid || t.mId || t.milestoneId;
                    return selectedMId ? String(tMId) === String(selectedMId) : true;
                  });

                  return (
                    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "24px", marginBottom: "20px" }}>
                      <div className="myt-form-group">
                        <label style={{ display: "block", fontSize: "14px", fontWeight: "600", color: "#475569", marginBottom: "8px" }}>Select Milestone</label>
                        <select className="myt-input" style={{ width: "100%", padding: "10px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "14px" }}
                          value={denyData.milestone || ""} onChange={e => setDenyData({...denyData, milestone: e.target.value, targetMId: e.target.value})}>
                          <option value="">Previous Milestone (Auto-Route)</option>
                          {projectMilestones.map(m => (
                            <option key={m.mId || m.mid || m.id} value={m.mId || m.mid || m.id}>
                              {m.mlstnTtl || m.mlstnNm || m.name || m.title || `Milestone ${m.mId || m.id}`}
                            </option>
                          ))}
                        </select>
                      </div>
                      <div className="myt-form-group">
                        <label style={{ display: "block", fontSize: "14px", fontWeight: "600", color: "#475569", marginBottom: "8px" }}>Select Deliverable (Task)</label>
                        <select className="myt-input" style={{ width: "100%", padding: "10px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "14px" }}
                          value={denyData.deliverable || ""} onChange={e => setDenyData({...denyData, deliverable: e.target.value})}>
                          <option value="">Last Task of Target Milestone (Auto-Route)</option>
                          {matchingTasks.map(t => (
                            <option key={t.id || t.taskId} value={t.id || t.taskId}>
                              {t.code ? `${t.code} - ${t.title || t.name}` : (t.title || t.name)}
                            </option>
                          ))}
                        </select>
                      </div>
                    </div>
                  );
                })()}
                <div className="myt-form-group" style={{ marginBottom: "20px" }}>
                  <label style={{ display: "block", fontSize: "14px", fontWeight: "600", color: "#475569", marginBottom: "8px" }}>Reason <span style={{ color: "#ef4444" }}>*</span></label>
                  <textarea className="myt-input" style={{ width: "100%", padding: "12px", borderRadius: "8px", border: "1px solid #cbd5e1", minHeight: "100px", fontSize: "14px" }}
                    placeholder="Enter detailed reason..." value={denyData.reason || ""} onChange={e => setDenyData({...denyData, reason: e.target.value})} />
                </div>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "24px", marginBottom: "24px" }}>
                  <div className="myt-form-group">
                    <label style={{ display: "block", fontSize: "14px", fontWeight: "600", color: "#475569", marginBottom: "8px" }}>Attachments (optional)</label>
                    <div style={{ width: "100%", padding: "16px", border: "2px dashed #cbd5e1", borderRadius: "8px", textAlign: "center", cursor: "pointer", color: "#64748b", backgroundColor: "#f8fafc", position: "relative" }}>
                      <input type="file" accept=".pdf,.doc,.docx,.xls,.xlsx,.csv,.ppt,.pptx,.txt,.jpg,.jpeg,.png,.gif,.webp" multiple onChange={(e) => setDenyData({...denyData, attachments: e.target.files})} style={{ opacity: 0, position: "absolute", top: 0, left: 0, width: "100%", height: "100%", cursor: "pointer" }} />
                      <Paperclip size={18} style={{ verticalAlign: "middle", marginRight: "8px" }} /> <span style={{ fontSize: "14px" }}>Click or drag files to upload</span>
                    </div>
                  </div>
                  <div className="myt-form-group">
                    <label style={{ display: "block", fontSize: "14px", fontWeight: "600", color: "#475569", marginBottom: "8px" }}>Impact</label>
                    <select className="myt-input" style={{ width: "100%", padding: "10px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "14px" }}
                      value={denyData.impact || "Medium"} onChange={e => setDenyData({...denyData, impact: e.target.value})}>
                      <option value="High">High</option>
                      <option value="Medium">Medium</option>
                      <option value="Low">Low</option>
                    </select>
                  </div>
                </div>
                <div style={{ display: "flex", justifyContent: "flex-end", gap: "12px", paddingTop: "20px", borderTop: "1px solid #e2e8f0" }}>
                  <button className="cc-btn secondary" onClick={() => setShowDenyForm(false)} style={{ borderRadius: "8px", padding: "10px 20px" }}>Cancel</button>
                  <button className="cc-btn secondary" onClick={() => { setDenyData(prev => ({...prev, type: "REASSIGN"})); handleSubmitDeny("REASSIGN"); }} disabled={!denyData.reason} 
                    style={{ borderRadius: "8px", backgroundColor: "#64748b", border: "none", color: "white", padding: "10px 20px", fontSize: "14px", fontWeight: "600" }}>
                    Reassign
                  </button>
                  {!isReworkDisabled && (
                    <button className="cc-btn primary" onClick={() => { setDenyData(prev => ({...prev, type: "REWORK"})); handleSubmitDeny("REWORK"); }} disabled={!denyData.reason} 
                      style={{ borderRadius: "8px", backgroundColor: "#f97316", border: "none", color: "white", padding: "10px 24px", fontSize: "15px", fontWeight: "600" }}>
                      Rework
                    </button>
                  )}
                </div>
              </div>
            ) : (
              <div style={{ padding: "40px", textAlign: "center", color: "#64748b" }}>
                <p style={{ fontSize: "15px" }}>Please toggle <b>Raise Request</b> to proceed with rejection.</p>
              </div>
            )}
          </div>
        )}
      </div>
    );
  };

  // ============================================
  // RENDER TEAM MEMBERS - For List View
  // ============================================
  const renderTeamMembers = (task) => {
    const rawTask = task.rawTask || task;
    
    const executorId = rawTask.empId || rawTask.assignedTo || rawTask.executorId;
    const reviewerId = rawTask.reviewerId || rawTask.reviewer;
    const approverId = rawTask.approverId || rawTask.approver;
    const assignedById = rawTask.assignedBy || rawTask.assigned_by || rawTask.createdBy;
    
    let teamMembers = [
      ...((task.isIndividual || rawTask.taskSource === "INDIVIDUAL" || assignedById) && (assignedById || rawTask.assignedByNm) ? [{
        empId: assignedById,
        role: "Assigned By",
        label: "AB",
        fallbackName: rawTask.assignedByNm || rawTask.assignedByName,
        fallbackPhoto: null
      }] : []),
      { 
        empId: executorId, 
        role: "Executor", 
        label: "EX",
        fallbackName: rawTask.executorName || rawTask.empNm || rawTask.empName || rawTask.assignedToName || rawTask.executorNm,
        fallbackPhoto: rawTask.executorPhoto || rawTask.empPhoto
      },
      { 
        empId: reviewerId, 
        role: "Reviewer", 
        label: "RV",
        fallbackName: rawTask.reviewerName || rawTask.reviewerNm || rawTask.revNm || rawTask.revName,
        fallbackPhoto: rawTask.reviewerPhoto || rawTask.revPhoto
      },
      { 
        empId: approverId, 
        role: "Approver", 
        label: "AP",
        fallbackName: rawTask.approverName || rawTask.approverNm || rawTask.appNm || rawTask.appName,
        fallbackPhoto: rawTask.approverPhoto || rawTask.appPhoto
      }
    ].filter(m => m.empId || m.fallbackName);

    // Fallback for dashboard upcoming tasks which might use an employees array
    if (teamMembers.length === 0 && Array.isArray(rawTask.employees) && rawTask.employees.length > 0) {
      teamMembers = rawTask.employees.map((e, idx) => {
        let rawRole = e.participantType || e.stepType || e.taskRole || e.type || e.role || e.designation || "Executor";
        let label = "EX";
        if (rawRole.toUpperCase().includes("REVIEWER")) label = "RV";
        if (rawRole.toUpperCase().includes("APPROVER")) label = "AP";
        return {
          empId: e.empId || e.employeeId || e.id || `emp-fallback-${idx}`,
          role: rawRole,
          label: label,
          fallbackName: e.fullName || e.empName || e.name || e.employeeName,
          fallbackPhoto: e.photoUrl || e.photo || e.profileImage || null
        };
      }).filter(m => m.fallbackName || m.empId !== `emp-fallback-undefined`);
    }

    if (teamMembers.length === 0) {
      return <span style={{ color: "#94a3b8", fontSize: "12px" }}>—</span>;
    }

    return (
      <div style={{ display: "flex", alignItems: "center", gap: "6px", flexWrap: "wrap" }}>
        <style>
          {`
            .team-member-hover {
              position: relative;
            }
            .team-member-hover .member-tooltip {
              opacity: 0;
              visibility: hidden;
              transition: all 0.2s ease-in-out;
              position: absolute;
              bottom: calc(100% + 8px);
              left: 50%;
              transform: translateX(-50%) translateY(4px);
              background-color: #1e293b;
              color: white;
              padding: 6px 12px;
              border-radius: 6px;
              font-size: 12px;
              font-weight: 500;
              white-space: nowrap;
              z-index: 50;
              box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
              pointer-events: none;
            }
            .team-member-hover:hover .member-tooltip {
              opacity: 1;
              visibility: visible;
              transform: translateX(-50%) translateY(0);
            }
            .member-tooltip::after {
              content: '';
              position: absolute;
              bottom: -4px;
              left: 50%;
              transform: translateX(-50%);
              width: 0;
              height: 0;
              border-left: 5px solid transparent;
              border-right: 5px solid transparent;
              border-top: 5px solid #1e293b;
            }
          `}
        </style>
        {teamMembers.map((member, idx) => {
          let empName = getEmployeeName(member.empId, employeesList);
          let photo = getEmployeePhoto(member.empId, employeesList);
          
          // Fallback to embedded names if API list is empty or failed
          if (!empName || empName === "Unknown" || empName.startsWith("User ")) {
            // Try to find from rawTask.employees array if it exists (like in UserDashboard)
            if (rawTask.employees && Array.isArray(rawTask.employees)) {
              const embeddedEmp = rawTask.employees.find(e => 
                String(e.empId || e.id || e.employeeId) === String(member.empId) || 
                (e.taskRole && String(e.taskRole).toUpperCase().includes(member.label))
              );
              if (embeddedEmp) {
                empName = embeddedEmp.fullName || embeddedEmp.name || embeddedEmp.employeeName || empName;
                photo = embeddedEmp.photoUrl || embeddedEmp.profileImage || photo;
              }
            }
            // If still unknown, use direct fallback fields
            if ((!empName || empName === "Unknown" || empName.startsWith("User ")) && member.fallbackName) {
              empName = member.fallbackName;
            }
            if (!photo && member.fallbackPhoto) {
              photo = member.fallbackPhoto;
            }
          }
          
          let initials = "";
          if (empName && empName !== "Unknown" && !empName.startsWith("User ")) {
            const parts = empName.trim().split(" ");
            initials = parts.length >= 2 ? (parts[0][0] + parts[1][0]).toUpperCase() : parts[0].substring(0, 2).toUpperCase();
          } else {
            initials = String(member.empId).substring(0, 2).toUpperCase();
          }
          
          const roleColors = {
            "Assigned By": { bg: "#6366F1", light: "#EEF2FF" },
            "Executor": { bg: "#3B82F6", light: "#DBEAFE" },
            "Reviewer": { bg: "#8B5CF6", light: "#EDE9FE" },
            "Approver": { bg: "#F59E0B", light: "#FEF3C7" }
          };
          const color = roleColors[member.role] || { bg: "#64748B", light: "#F1F5F9" };

          return (
            <div 
              key={idx} 
              className="team-member-hover"
              style={{ 
                display: "flex",
                alignItems: "center",
                gap: "4px",
                padding: "2px 6px 2px 2px",
                borderRadius: "16px",
                backgroundColor: color.light,
                border: `1px solid ${color.bg}33`,
                cursor: "pointer",
                transition: "all 0.2s"
              }}
            >
              {/* Tooltip */}
              <div className="member-tooltip">
                <span style={{ fontWeight: "600" }}>{empName || 'Unknown'}</span> 
                <span style={{ color: color.bg, opacity: 0.9, marginLeft: "4px" }}>• {member.role}</span>
              </div>

              <div style={{
                width: "24px",
                height: "24px",
                borderRadius: "50%",
                backgroundColor: color.bg,
                color: "white",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: "8px",
                fontWeight: "700",
                overflow: "hidden",
                flexShrink: 0
              }}>
                {photo ? (
                  <img 
                    src={photo.startsWith('data:') || photo.startsWith('http') ? photo : `data:image/jpeg;base64,${photo}`} 
                    alt={empName || 'User'} 
                    style={{ width: "100%", height: "100%", objectFit: "cover" }} 
                    onError={(e) => {
                      e.target.style.display = "none";
                      e.target.parentElement.textContent = initials || "UN";
                    }}
                  />
                ) : initials || "UN"}
              </div>
              
              <span style={{ 
                fontSize: "7px", 
                fontWeight: "700", 
                color: color.bg,
                backgroundColor: `${color.bg}22`,
                padding: "1px 5px",
                borderRadius: "8px",
                letterSpacing: "0.3px"
              }}>
                {member.label}
              </span>
            </div>
          );
        })}
      </div>
    );
  };

  // ============================================
  // RENDER ACTION BUTTON - List View
  // ============================================
  const renderActionButton = (task) => {
    if (!task) return null;
    
    const rawTask = task.rawTask || task;
    const action = getActionButton(rawTask, currentUserEmpId);
    const isDisabled = loadingAction === (task.id || task.taskId);
    
    if (!action) return null;
    
    const getButtonStyle = (variant) => {
      switch(variant) {
        case "primary": return { bg: "#3B82F6", hover: "#2563EB", color: "white" };
        case "warning": return { bg: "#F59E0B", hover: "#D97706", color: "white" };
        case "success": return { bg: "#10B981", hover: "#059669", color: "white" };
        case "review": return { bg: "#8B5CF6", hover: "#7C3AED", color: "white" };
        default: return { bg: "#F1F5F9", hover: "#E2E8F0", color: "#475569" };
      }
    };
    
    const style = getButtonStyle(action.variant);
    
    const handleClick = async (e) => {
      e.stopPropagation();
      if (isDisabled) return;
      
      // ALL actions open the same detail screen
      if (action.action === "view") {
        await openTaskDetail(task);
        return;
      }
      
      // For actions other than 'view', execute then open detail
      switch(action.action) {
        case "start": 
          const startedTask = await handleStartTask(task);
          await openTaskDetail(startedTask || task);
          break;
        case "update": 
          await openTaskDetail(task);
          break;
        case "review": 
          await openTaskDetail(task);
          break;
        case "approve": 
          await openTaskDetail(task);
          break;
        default: 
          break;
      }
    };
    
    return (
      <button
        style={{
          backgroundColor: style.bg,
          color: style.color,
          border: action.variant === "secondary" ? "1px solid #E2E8F0" : "none",
          padding: "6px 16px",
          borderRadius: "6px",
          cursor: isDisabled ? "not-allowed" : "pointer",
          fontSize: "12px",
          fontWeight: "600",
          opacity: isDisabled ? 0.6 : 1,
          transition: "all 0.2s",
          minWidth: "60px",
          display: "inline-flex",
          alignItems: "center",
          justifyContent: "center",
          gap: "6px"
        }}
        onClick={handleClick}
        disabled={isDisabled}
        onMouseEnter={(e) => { if (!isDisabled) e.currentTarget.style.backgroundColor = style.hover; }}
        onMouseLeave={(e) => { e.currentTarget.style.backgroundColor = style.bg; }}
      >
        {isDisabled ? (
          <Loader2 size={12} className="spinning" />
        ) : (
          <>
            {action.action === "start" && <Play size={12} />}
            {action.action === "update" && <RotateCw size={12} />}
            {action.action === "view" && <Eye size={12} />}
            {action.action === "review" && <CheckCircle2 size={12} />}
            {action.action === "approve" && <Check size={12} />}
            {action.label}
          </>
        )}
      </button>
    );
  };

  // ============================================
  // MAIN RENDER
  // ============================================

  const countTodo = tasks.filter(isToDo).length;
  const countUpcoming = tasks.filter(isUpcomingTab).length;
  const countCompleted = tasks.filter(isCompletedTab).length;
  const countAllTasks = tasks.length;
  
  // Custom check for overdue
  const countOverdue = tasks.filter(isTaskOverdue).length;

  const showTaskFilters = selectedStatus === "To Do" || selectedStatus === "All Statuses" || selectedStatus === "All Tasks";

  return (
    <div className={`cc-shell-container ${isSidebarCollapsed ? 'sidebar-collapsed' : ''}`}>
      <Sidebar onLogout={onLogout} />
      <div className="cc-shell">
        <Header 
          title="My Tasks" 
          subtitle={showDetailView && selectedTask ? selectedTask.title : "View and manage all tasks assigned to you."} 
          onLogout={onLogout} 
          userRole={userRole} 
        />

        <main className="cc-main" style={{ overflow: "visible" }}>
          {apiError && (
            <div style={{ backgroundColor: "#fee2e2", color: "#b91c1c", padding: "16px", borderRadius: "8px", marginBottom: "20px", border: "1px solid #fca5a5", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div><strong>⚠️ Error:</strong> {apiError}</div>
              <button onClick={() => fetchTasks()} style={{ padding: "6px 16px", backgroundColor: "#b91c1c", color: "white", border: "none", borderRadius: "6px", cursor: "pointer", fontWeight: "500" }}>Retry</button>
            </div>
          )}

          {showDetailView && selectedTask ? (
            renderTaskDetailScreen(
              selectedTask, 
              () => {
                setShowDetailView(false);
                setSelectedTask(null);
                setShowDenyForm(false);
                setUpdateRemarks("");
              }
            )
          ) : (
            /* Tasks List View */
            <>
              {/* Metrics Cards */}
              <div className="myt-metrics-grid" style={{ marginBottom: "24px", display: "flex", gap: "16px", flexWrap: "nowrap", overflowX: "auto" }}>
                <div className={`myt-metric-card sketch-layout todo ${selectedStatus === "To Do" ? "active" : ""}`} onClick={() => handleStatusFilterChange("To Do")} style={{ flex: "1", minWidth: "120px" }}>
                  <div className="myt-metric-left"><div className="myt-metric-icon-box yellow-circle"><ClipboardList size={20} /></div><div className="myt-metric-text-group"><div className="myt-metric-title">To-Do</div><div className="myt-metric-subtitle">Active Tasks</div></div></div>
                  <div className="myt-metric-right"><div className="myt-metric-value">{countTodo}</div></div>
                </div>
                
                <div className={`myt-metric-card sketch-layout upcoming ${selectedStatus === "Upcoming" ? "active" : ""}`} onClick={() => handleStatusFilterChange("Upcoming")} style={{ flex: "1", minWidth: "120px" }}>
                  <div className="myt-metric-left"><div className="myt-metric-icon-box" style={{ backgroundColor: "#e0e7ff", color: "#4f46e5" }}><Calendar size={20} /></div><div className="myt-metric-text-group"><div className="myt-metric-title">Upcoming</div><div className="myt-metric-subtitle">Planned</div></div></div>
                  <div className="myt-metric-right"><div className="myt-metric-value">{countUpcoming}</div></div>
                </div>

                <div className={`myt-metric-card sketch-layout completed ${selectedStatus === "Completed" ? "active" : ""}`} onClick={() => handleStatusFilterChange("Completed")} style={{ flex: "1", minWidth: "120px" }}>
                  <div className="myt-metric-left"><div className="myt-metric-icon-box green-circle"><CheckCircle2 size={20} /></div><div className="myt-metric-text-group"><div className="myt-metric-title">Closed</div><div className="myt-metric-subtitle">Done</div></div></div>
                  <div className="myt-metric-right"><div className="myt-metric-value">{countCompleted}</div></div>
                </div>
                
                <div className={`myt-metric-card sketch-layout all ${selectedStatus === "All Tasks" ? "active" : ""}`} onClick={() => handleStatusFilterChange("All Tasks")} style={{ flex: "1", minWidth: "120px" }}>
                  <div className="myt-metric-left"><div className="myt-metric-icon-box orange-circle"><Layers size={20} /></div><div className="myt-metric-text-group"><div className="myt-metric-title">All Tasks</div><div className="myt-metric-subtitle">Total Work</div></div></div>
                  <div className="myt-metric-right"><div className="myt-metric-value">{countAllTasks}</div></div>
                </div>
              </div>

              {/* Search and Filters */}
              {showTaskFilters && (
                <div className="myt-tabs-container" style={{ marginBottom: "20px", borderBottom: "none", display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: "12px" }}>
                  <div className="myt-tabs-left" style={{ display: "flex", gap: "8px", flexWrap: "wrap" }}>
                    <button 
                      className={`myt-filter-btn ${taskFilter === "All" ? "active" : ""}`}
                      onClick={() => { setTaskFilter("All"); setCurrentPage(1); }}
                      style={{
                        padding: "6px 14px",
                        borderRadius: "20px",
                        border: "1px solid #e2e8f0",
                        backgroundColor: taskFilter === "All" ? "#3B82F6" : "white",
                        color: taskFilter === "All" ? "white" : "#475569",
                        cursor: "pointer",
                        fontSize: "12px",
                        fontWeight: "500",
                        transition: "all 0.2s"
                      }}
                    >
                      All
                    </button>
                    <button 
                      className={`myt-filter-btn ${taskFilter === "OPEN" ? "active" : ""}`}
                      onClick={() => { setTaskFilter("OPEN"); setCurrentPage(1); }}
                      style={{
                        padding: "6px 14px",
                        borderRadius: "20px",
                        border: "1px solid #e2e8f0",
                        backgroundColor: taskFilter === "OPEN" ? "#3B82F6" : "white",
                        color: taskFilter === "OPEN" ? "white" : "#475569",
                        cursor: "pointer",
                        fontSize: "12px",
                        fontWeight: "500",
                        transition: "all 0.2s"
                      }}
                    >
                      Open
                    </button>
                    <button 
                      className={`myt-filter-btn ${taskFilter === "IN_PROGRESS" ? "active" : ""}`}
                      onClick={() => { setTaskFilter("IN_PROGRESS"); setCurrentPage(1); }}
                      style={{
                        padding: "6px 14px",
                        borderRadius: "20px",
                        border: "1px solid #e2e8f0",
                        backgroundColor: taskFilter === "IN_PROGRESS" ? "#3B82F6" : "white",
                        color: taskFilter === "IN_PROGRESS" ? "white" : "#475569",
                        cursor: "pointer",
                        fontSize: "12px",
                        fontWeight: "500",
                        transition: "all 0.2s"
                      }}
                    >
                      Work In Progress
                    </button>
                    <button 
                      className={`myt-filter-btn ${taskFilter === "UNDER_REVIEW" ? "active" : ""}`}
                      onClick={() => { setTaskFilter("UNDER_REVIEW"); setCurrentPage(1); }}
                      style={{
                        padding: "6px 14px",
                        borderRadius: "20px",
                        border: "1px solid #e2e8f0",
                        backgroundColor: taskFilter === "UNDER_REVIEW" ? "#3B82F6" : "white",
                        color: taskFilter === "UNDER_REVIEW" ? "white" : "#475569",
                        cursor: "pointer",
                        fontSize: "12px",
                        fontWeight: "500",
                        transition: "all 0.2s"
                      }}
                    >
                      Under Review
                    </button>
                    <button 
                      className={`myt-filter-btn ${taskFilter === "REASSIGNED" ? "active" : ""}`}
                      onClick={() => { setTaskFilter("REASSIGNED"); setCurrentPage(1); }}
                      style={{
                        padding: "6px 14px",
                        borderRadius: "20px",
                        border: "1px solid #e2e8f0",
                        backgroundColor: taskFilter === "REASSIGNED" ? "#3B82F6" : "white",
                        color: taskFilter === "REASSIGNED" ? "white" : "#475569",
                        cursor: "pointer",
                        fontSize: "12px",
                        fontWeight: "500",
                        transition: "all 0.2s"
                      }}
                    >
                      Re-Assigned
                    </button>
                    <button 
                      className={`myt-filter-btn ${taskFilter === "OVERDUE" ? "active" : ""}`}
                      onClick={() => { setTaskFilter("OVERDUE"); setCurrentPage(1); }}
                      style={{
                        padding: "6px 14px",
                        borderRadius: "20px",
                        border: "1px solid #e2e8f0",
                        backgroundColor: taskFilter === "OVERDUE" ? "#EF4444" : "white",
                        color: taskFilter === "OVERDUE" ? "white" : "#475569",
                        cursor: "pointer",
                        fontSize: "12px",
                        fontWeight: "500",
                        transition: "all 0.2s"
                      }}
                    >
                      Overdue
                    </button>
                  </div>
                  <div className="myt-tabs-right" style={{ display: "flex", gap: "8px", alignItems: "center" }}>
                    <div className="myt-search-box" style={{ position: "relative" }}>
                      <Search size={15} className="myt-search-icon" style={{ position: "absolute", left: "10px", top: "50%", transform: "translateY(-50%)", color: "#94a3b8" }} />
                      <input 
                        type="text" 
                        placeholder="Search task..." 
                        value={searchInput} 
                        onChange={(e) => { setSearchInput(e.target.value); setSearchQuery(e.target.value); }} 
                        style={{ padding: "8px 12px 8px 32px", border: "1px solid #e2e8f0", borderRadius: "6px", outline: "none", fontSize: "13px", width: "220px" }}
                        onKeyDown={handleSearchKeyDown}
                      />
                    </div>
                    <button onClick={handleResetFilters} style={{ padding: "6px 12px", border: "1px solid #e2e8f0", borderRadius: "6px", backgroundColor: "white", cursor: "pointer", fontSize: "12px", color: "#64748b" }}>
                      Clear
                    </button>
                  </div>
                </div>
              )}

              {/* Table */}
              <div className="cc-table-panel" style={{ border: "none", boxShadow: "none", padding: 0 }}>
                <div className="cc-table-container">
                  <table className="cc-list-table myt-table">
                    <thead>
                      <tr>
                        <th>
                          <div style={{ display: "flex", flexDirection: "column" }}>
                            <span style={{ fontSize: "12px", fontWeight: "700", color: "#0f172a", textTransform: "uppercase", marginBottom: "2px" }}>TASK</span>
                            <span style={{ fontSize: "11px", fontWeight: "500", color: "#64748b" }}>Task Code / Name<br/>Milestone</span>
                          </div>
                        </th>
                        <th>
                          <div style={{ display: "flex", flexDirection: "column" }}>
                            <span style={{ fontSize: "12px", fontWeight: "700", color: "#0f172a", textTransform: "uppercase", marginBottom: "2px" }}>TEAM</span>
                            <span style={{ fontSize: "11px", fontWeight: "500", color: "#64748b" }}>Members</span>
                          </div>
                        </th>
                        <th>
                          <span style={{ fontSize: "12px", fontWeight: "700", color: "#0f172a", textTransform: "uppercase" }}>PRIORITY</span>
                        </th>
                        <th style={{ textAlign: "center" }}>
                          <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
                            <span style={{ fontSize: "12px", fontWeight: "700", color: "#0f172a", textTransform: "uppercase", marginBottom: "2px" }}>DUE DATE</span>
                            <span style={{ fontSize: "11px", fontWeight: "500", color: "#64748b" }}>(Date Only)</span>
                          </div>
                        </th>
                        <th style={{ textAlign: "center" }}>
                          <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
                            <span style={{ fontSize: "12px", fontWeight: "700", color: "#0f172a", textTransform: "uppercase", marginBottom: "2px" }}>PROGRESS</span>
                            <span style={{ fontSize: "11px", fontWeight: "500", color: "#64748b" }}>(Status &bull; Process &bull; Time)</span>
                          </div>
                        </th>
                        <th style={{ textAlign: "center" }}>
                          <span style={{ fontSize: "12px", fontWeight: "700", color: "#0f172a", textTransform: "uppercase" }}>ACTION</span>
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {isLoading ? (
                        <tr><td colSpan="6" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}><Loader2 size={24} className="spinning" /> Loading tasks...</td></tr>
                      ) : paginatedTasks.length > 0 ? (
                        paginatedTasks.map((task) => {
                          const progressBadge = getProgressBadge(task.status);
                          const processIcon = getProcessIcon(task.rawTask?.prcsYesActn);
                          const timeStatus = calculateTimeStatus(task.rawTask || task);
                          const priorityBadge = getPriorityBadge(task.priority);
                          const isCompleted = task.rawStatus === "COMPLETED" || task.rawStatus === "CLOSED";
                          const isOverdue = isTaskOverdue(task);
                          
                          return (
                            <tr key={task.id || task.taskId} onClick={() => { openTaskDetail(task); }} style={{ cursor: "pointer", backgroundColor: isOverdue ? "#FEF2F2" : "transparent" }}>
                              <td style={{ maxWidth: "250px" }}>
                                <div style={{ fontWeight: "600", color: "#0f172a", marginBottom: "4px" }}>{task.taskCode || task.id}</div>
                                <div style={{ fontWeight: "500", color: "#64748b", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }} title={task.title}>{task.title}</div>
                                {!task.isIndividual && task.project !== "Individual Task" && task.milestone && task.milestone !== "—" && (
                                  <div style={{ fontSize: "12px", color: "#94a3b8" }}>{task.milestone}</div>
                                )}
                              </td>
                              <td>
                                {renderTeamMembers(task)}
                              </td>
                              <td>
                                {!isCompleted && (
                                  <span className="cc-status-badge" style={{ backgroundColor: priorityBadge.bg, color: priorityBadge.color, padding: "4px 10px", borderRadius: "12px", fontSize: "12px", fontWeight: "600" }}>
                                    {task.priority === "ATMOST CRITICAL" ? "Atmost Critical" : task.priority}
                                  </span>
                                )}
                              </td>
                              <td style={{ fontWeight: "600", color: isOverdue ? "#EF4444" : "#0f172a", textAlign: "center" }}>
                                {formatDate(task.dueDate) || "—"}
                                {isOverdue && <span style={{ display: "block", fontSize: "10px", color: "#EF4444" }}>⚠️ Overdue</span>}
                              </td>
                              <td>
                                <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "8px" }}>
                                  <span className="cc-status-badge" style={{ backgroundColor: progressBadge.bg, color: progressBadge.color, minWidth: "90px", textAlign: "center", display: "inline-block", textTransform: "uppercase", fontWeight: "700", padding: "4px 12px", borderRadius: "12px", fontSize: "11px" }}>{progressBadge.label}</span>
                                  {/* Hide process icon for closed tasks — only show Lead/Lag/On Time clock */}
                                  {!isCompleted && processIcon && <div className="myt-custom-tooltip-wrap" title={processIcon.title} style={{ color: processIcon.color, display: "flex", alignItems: "center", cursor: "help" }}><processIcon.icon size={18} strokeWidth={2.5} /></div>}
                                  {timeStatus && <div className="myt-custom-tooltip-wrap" title={timeStatus.title} style={{ color: timeStatus.color, display: "flex", alignItems: "center", cursor: "help" }}><timeStatus.icon size={18} strokeWidth={2.5} /></div>}
                                </div>
                              </td>
                              <td onClick={(e) => e.stopPropagation()} style={{ textAlign: "center" }}>
                                {renderActionButton(task)}
                              </td>
                            </tr>
                          );
                        })
                      ) : (
                        <tr><td colSpan="6" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>No tasks found.</td></tr>
                      )}
                    </tbody>
                  </table>

                  {sortedTasks.length > 0 && (
                    <div className="myt-pagination-container">
                      <div className="myt-pagination-info">Showing {startIndex + 1} to {Math.min(startIndex + itemsPerPage, sortedTasks.length)} of {sortedTasks.length} tasks</div>
                      <div className="myt-pagination-controls">
                        <button className="myt-page-btn" disabled={currentPage === 1} onClick={() => handlePageChange(currentPage - 1)}><ChevronLeft size={16} /></button>
                        {Array.from({ length: Math.min(totalPages, 5) }).map((_, i) => {
                          const pageNum = i + 1;
                          return <button key={i} className={`myt-page-btn ${currentPage === pageNum ? 'active' : ''}`} onClick={() => handlePageChange(pageNum)}>{pageNum}</button>;
                        })}
                        {totalPages > 5 && <span style={{ padding: "0 4px", color: "#94a3b8" }}>...</span>}
                        {totalPages > 5 && <button className="myt-page-btn" onClick={() => handlePageChange(totalPages)}>{totalPages}</button>}
                        <button className="myt-page-btn" disabled={currentPage === totalPages} onClick={() => handlePageChange(currentPage + 1)}><ChevronRight size={16} /></button>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </>
          )}
        </main>
      </div>

      <AlertModal isOpen={alertOpen} type={alertConfig.type} title={alertConfig.title} message={alertConfig.message} onClose={() => setAlertOpen(false)} />
    </div>
  );
};

export default MyTasks;