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
  Filter,
  RotateCw,
  ChevronLeft,
  ChevronRight,
  Check,
  Undo2,
} from "lucide-react";
import "../../styles/MyTasks.css";
import { apiGet, apiPut, apiPatch, apiPost } from "../../utils/api";

const mapBackendTask = (t, projects, milestones) => {
  const milestone = milestones.find(m => String(m.mId) === String(t.mId));
  const project = milestone ? projects.find(p => String(p.prjId) === String(milestone.prjId)) : null;

  let status = "To-Do";
  if (t.taskSts === "COMPLETED") {
    status = "Completed";
  } else if (t.taskSts === "SUBMIT_REVIEW" || t.taskSts === "UNDER_REVIEW") {
    status = "Under Review";
  } else if (t.taskSts === "REASSIGN") {
    status = "Reassigned";
  } else if (t.taskSts === "REWORK") {
    status = "Rework";
  } else {
    const today = new Date().toISOString().split("T")[0];
    if (t.endDt && t.endDt < today) {
      status = "Overdue";
    } else if (t.taskSts === "WIP") {
      status = "In Progress";
    } else {
      status = "To-Do";
    }
  }

  const progress = 0;

  let calculatedPriority = "Low";
  if (t.endDt) {
    const [year, month, day] = t.endDt.split('-');
    const endDtObj = new Date(year, month - 1, day);
    endDtObj.setHours(0, 0, 0, 0);

    let compareDateObj = new Date();
    compareDateObj.setHours(0, 0, 0, 0);

    if (t.taskSts === "COMPLETED" || t.taskSts === "UNDER_REVIEW" || t.taskSts === "SUBMIT_REVIEW") {
       if (t.actCmpDt) {
           compareDateObj = new Date(t.actCmpDt);
           compareDateObj.setHours(0,0,0,0);
       } else if (compareDateObj > endDtObj) {
           compareDateObj = endDtObj;
       }
    }

    const diffTime = compareDateObj.getTime() - endDtObj.getTime();
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      calculatedPriority = "High";
    } else if (diffDays === 1) {
      calculatedPriority = "Critical";
    } else if (diffDays >= 2) {
      calculatedPriority = "Atmost Critical";
    }
  }

  return {
    id: t.taskCd || `TSK-${t.taskId}`,
    taskId: t.taskId,
    title: t.taskNm,
    project: project ? project.prjNm : "Unknown Project",
    milestone: milestone ? milestone.mlstnTtl : "Unknown Milestone",
    priority: calculatedPriority,
    dueDate: t.endDt || "",
    status: status,
    progress: progress,
    rawStatus: t.taskSts,
    rawTask: t,
    description: t.taskDesc || "",
    assignedBy: "Project Manager"
  };
};

const mapIndividualTask = (t) => {
  let status = "To-Do";
  if (t.taskSts === "COMPLETED") {
    status = "Completed";
  } else if (t.taskSts === "SUBMIT_REVIEW" || t.taskSts === "UNDER_REVIEW") {
    status = "Under Review";
  } else if (t.taskSts === "REASSIGN") {
    status = "Reassigned";
  } else if (t.taskSts === "REWORK") {
    status = "Rework";
  } else {
    const today = new Date().toISOString().split("T")[0];
    if (t.endDt && t.endDt < today) {
      status = "Overdue";
    } else if (t.taskSts === "WIP") {
      status = "In Progress";
    } else {
      status = "To-Do";
    }
  }

  let calculatedPriority = "Low";
  if (t.endDt) {
    const [year, month, day] = t.endDt.split('-');
    const endDtObj = new Date(year, month - 1, day);
    endDtObj.setHours(0, 0, 0, 0);

    let compareDateObj = new Date();
    compareDateObj.setHours(0, 0, 0, 0);

    if (t.taskSts === "COMPLETED" || t.taskSts === "UNDER_REVIEW" || t.taskSts === "SUBMIT_REVIEW") {
       if (t.actCmpDt) {
           compareDateObj = new Date(t.actCmpDt);
           compareDateObj.setHours(0,0,0,0);
       } else if (compareDateObj > endDtObj) {
           compareDateObj = endDtObj;
       }
    }

    const diffTime = compareDateObj.getTime() - endDtObj.getTime();
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      calculatedPriority = "High";
    } else if (diffDays === 1) {
      calculatedPriority = "Critical";
    } else if (diffDays >= 2) {
      calculatedPriority = "Atmost Critical";
    }
  }

  return {
    id: t.taskCd || `IND-${t.empTaskId}`,
    taskId: t.empTaskId,
    isIndividual: true,
    title: t.taskNm,
    project: "Individual Task",
    milestone: "-",
    priority: calculatedPriority,
    dueDate: t.endDt || "",
    status: status,
    progress: 0,
    rawStatus: t.taskSts,
    rawTask: t,
    description: t.taskDesc || "",
    assignedBy: "Task Manager"
  };
};

const MyTasks = ({ userRole, onLogout }) => {
  const [tasks, setTasks] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [currentUserEmpId, setCurrentUserEmpId] = useState(null);
  const [employeesList, setEmployeesList] = useState([]);

  const fetchTasks = async () => {
    try {
      setIsLoading(true);
      const [projectsData, milestonesData, tasksData, indTasksData, profileRes, employeesData] = await Promise.all([
        apiGet("/api/project-live").catch(() => []),
        apiGet("/api/milestone-live").catch(() => []),
        apiGet("/api/task-live").catch(() => []),
        apiGet("/api/individual-tasks").catch(() => []),
        apiGet("/api/profile").catch(() => ({})),
        apiGet("/api/employees").catch(() => [])
      ]);

      setEmployeesList(employeesData || []);
      const empId = profileRes?.empId;
      const isAdmin = profileRes?.email === 'vsv.vempati@gmail.com';
      setCurrentUserEmpId(empId);

      const liveTasksWithConfigs = await Promise.all((tasksData || []).map(async task => {
         try {
             const pcs = await apiGet(`/api/process-config/live-task/${task.taskId}`);
             const configs = pcs || [];
             const revCfg = configs.find(pc => pc.ordrId === 1);
             const appCfg = configs.find(pc => pc.ordrId === 2);
             return {
                ...task,
                reviewerId: revCfg ? revCfg.empId : task.reviewerId,
                approverId: appCfg ? appCfg.empId : task.approverId
             };
         } catch(e) { return task; }
      }));

      const indTasksWithConfigs = await Promise.all((indTasksData || []).map(async task => {
         try {
             const pcs = await apiGet(`/api/process-config/individual-task/${task.empTaskId}`);
             const configs = pcs || [];
             const revCfg = configs.find(pc => pc.ordrId === 1);
             const appCfg = configs.find(pc => pc.ordrId === 2);
             return {
                ...task,
                reviewerId: revCfg ? revCfg.empId : task.reviewerId,
                approverId: appCfg ? appCfg.empId : task.approverId
             };
         } catch(e) { return task; }
      }));

      const userTasks = liveTasksWithConfigs.filter(t => isAdmin || String(t.empId) === String(empId) || String(t.reviewerId) === String(empId) || String(t.approverId) === String(empId));
      const userIndTasks = indTasksWithConfigs.filter(t => isAdmin || String(t.empId) === String(empId) || String(t.reviewerId) === String(empId) || String(t.approverId) === String(empId));

      let mapped = userTasks.map(t => mapBackendTask(t, projectsData || [], milestonesData || []));
      let mappedInd = userIndTasks.map(t => mapIndividualTask(t));
      mapped = [...mapped, ...mappedInd];

      const checklistPromises = mapped.map(task => {
        const path = task.isIndividual
          ? `/api/checklists/individual-task/${task.taskId}`
          : `/api/checklists/live-task/${task.taskId}`;
        
        return apiGet(path)
          .then(items => {
            const checklist = (items || []).map(item => ({
              id: item.chkId,
              completed: item.chkSts || false
            }));
            const completed = checklist.filter(item => item.completed).length;
            const total = checklist.length;
            
            let progress = 0;
            const prcsFlg = task.rawTask?.prcsFlg;
            const taskSts = task.rawStatus;

            if (!prcsFlg) {
              progress = total > 0 ? Math.round((completed / total) * 100) : 0;
              if (taskSts === 'COMPLETED') progress = 100;
            } else {
              if (taskSts === 'COMPLETED') {
                progress = 100;
              } else if (taskSts === 'UNDER_REVIEW') {
                progress = 95;
              } else if (taskSts === 'SUBMIT_REVIEW') {
                progress = 90;
              } else {
                progress = total > 0 ? Math.round((completed / total) * 100) : 0;
              }
            }
            return { taskId: task.taskId, progress };
          })
          .catch(() => ({ taskId: task.taskId, progress: 0 }));
      });

      const progressResults = await Promise.all(checklistPromises);
      const progressMap = {};
      progressResults.forEach(p => { progressMap[p.taskId] = p.progress; });

      mapped = mapped.map(task => ({
        ...task,
        progress: progressMap[task.taskId] !== undefined ? progressMap[task.taskId] : task.progress
      }));

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

  const [searchInput, setSearchInput] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedProject, setSelectedProject] = useState("All Projects");
  const [selectedMilestone, setSelectedMilestone] = useState("All Milestones");
  const [selectedPriority, setSelectedPriority] = useState("All Priorities");
  const [selectedStatus, setSelectedStatus] = useState("To-Do (Not Started)");
  const [selectedDueDate, setSelectedDueDate] = useState("");
  const [showFilters, setShowFilters] = useState(true);

  const handleStatusFilterChange = (statusVal) => {
    if (selectedStatus === statusVal) {
      setSelectedStatus("All Statuses");
    } else {
      setSelectedStatus(statusVal);
    }
  };

  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 5;

  const [selectedTask, setSelectedTask] = useState(null);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [updatingTask, setUpdatingTask] = useState(null);
  const [showUpdateModal, setShowUpdateModal] = useState(false);
  const [alertOpen, setAlertOpen] = useState(false);
  const [alertConfig, setAlertConfig] = useState({ type: "success", title: "", message: "" });

  const [updateProgressVal, setUpdateProgressVal] = useState(0);
  const [updateChecklist, setUpdateChecklist] = useState([]);
  const [updateRemarks, setUpdateRemarks] = useState("");

  const [showDenyForm, setShowDenyForm] = useState(false);
  const [denyData, setDenyData] = useState({
    milestone: "",
    deliverable: "",
    reason: "",
    impact: "Low",
    type: "REASSIGN"
  });

  // Lock body scroll when modals open
  useEffect(() => {
    if (showDetailModal || showUpdateModal || alertOpen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => { document.body.style.overflow = ""; };
  }, [showDetailModal, showUpdateModal, alertOpen]);

  const visibleTasks = tasks.filter(task => {
    const isExec = String(task.rawTask.empId) === String(currentUserEmpId);
    const isRev = String(task.rawTask.reviewerId) === String(currentUserEmpId);
    const isApp = String(task.rawTask.approverId) === String(currentUserEmpId);
    let isVisible = false;
    if (isExec) isVisible = true;
    if (isRev && (task.rawStatus === "SUBMIT_REVIEW" || task.rawStatus === "UNDER_REVIEW" || task.rawStatus === "COMPLETED")) isVisible = true;
    if (isApp && (task.rawStatus === "UNDER_REVIEW" || task.rawStatus === "COMPLETED")) isVisible = true;
    return isVisible;
  });

  const countTodo = visibleTasks.filter(t => {
      const isExec = String(t.rawTask.empId) === String(currentUserEmpId);
      return isExec && (t.status === "To-Do" || t.status === "Reassigned" || t.status === "Rework");
  }).length;
  
  const countInProgress = visibleTasks.filter(t => t.status === "In Progress").length;
  
  const countUnderReview = visibleTasks.filter(t => t.status === "Under Review").length;

  const countCompleted = visibleTasks.filter(t => t.status === "Completed").length;
  
  const countOverdue = visibleTasks.filter(t => {
      const isExec = String(t.rawTask.empId) === String(currentUserEmpId);
      return isExec && t.status === "Overdue";
  }).length;

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

  const computeProgress = (checklist, task) => {
    if (!checklist || checklist.length === 0) return 0;
    const completed = checklist.filter(item => item.completed).length;
    const prcsFlg = task?.rawTask?.prcsFlg;
    const taskSts = task?.rawStatus;

    if (!prcsFlg) {
      return Math.round((completed / checklist.length) * 100);
    } else {
       if (taskSts === 'COMPLETED') return 100;
       if (taskSts === 'UNDER_REVIEW') return 95;
       if (taskSts === 'SUBMIT_REVIEW') return 90;
       return Math.round((completed / checklist.length) * 100);
    }
  };

  const getDisplayStatus = (progress, originalStatus, prcsFlg) => {
    if (progress === 100 && !prcsFlg) return "Completed";
    if (progress === 100 && prcsFlg) {
      if (originalStatus === "Completed") return "Completed";
      return "In Progress";
    }
    if (prcsFlg && (progress === 90 || progress === 95)) {
      if (progress === 95) return "Under Review";
      if (progress === 90 && originalStatus === "Under Review") return "Under Review"; 
      return "In Progress";
    }
    if (progress > 0) return "In Progress";
    
    if (originalStatus === "In Progress" || originalStatus === "Under Review" || originalStatus === "Overdue" || originalStatus === "Reassigned" || originalStatus === "Rework") {
      return originalStatus;
    }
    return "To-Do";
  };

  const sendNotification = async (empId, message, taskContext = null) => {
    if (!empId) {
      console.warn("sendNotification aborted: empId is missing", { empId, message });
      return;
    }
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
      console.log("Notification sent successfully to empId:", empId);
    } catch (e) {
      console.warn("Failed to send notification (likely unauthorized)", e);
    }
  };

  const handleStartTask = async (task) => {
    try {
      const originalTask = task.rawTask;
      const updatedTaskObj = {
        ...originalTask,
        taskSts: "WIP",
      };
      
      const updatePath = task.isIndividual 
        ? `/api/individual-tasks/${task.taskId}`
        : `/api/task-live/${task.taskId}`;
        
      await apiPut(`${updatePath}?_t=${Date.now()}`, updatedTaskObj);

      if (originalTask.reviewerId) {
         await sendNotification(originalTask.reviewerId, `Task started: ${task.title} (${task.id})`, task);
      }
      
      if (originalTask.approverId) {
         await sendNotification(originalTask.approverId, `Task started: ${task.title} (${task.id})`, task);
      }

      await fetchTasks();
      triggerAlert("success", "Started", "Task moved to In Progress.");
    } catch (err) {
      console.error("Error starting task:", err);
      triggerAlert("danger", "Error", "Failed to start task: " + err.message);
    }
  };

  const openUpdateModal = async (task) => {
    setUpdatingTask(task);
    setUpdateRemarks(task.rawTask?.addlRem || "");
    setShowDenyForm(false);
    setDenyData({
      milestone: "",
      deliverable: "",
      reason: "",
      impact: "Low",
      type: "REASSIGN"
    });

    try {
      const path = task.isIndividual
        ? `/api/checklists/individual-task/${task.taskId}`
        : `/api/checklists/live-task/${task.taskId}`;
        
      const items = await apiGet(path);
      const mapped = (items || []).map(item => ({
        id: item.chkId,
        text: item.chkNm,
        completed: item.chkSts || false
      }));
      setUpdateChecklist(mapped);
      const progress = computeProgress(mapped, task);
      setUpdateProgressVal(progress);
    } catch (err) {
      console.error("Failed to load checklist:", err);
      setUpdateChecklist([]);
      setUpdateProgressVal(0);
    }

    setShowUpdateModal(true);
  };

  const handleToggleChecklist = (id) => {
    if (updatingTask?.status === "Under Review" || updatingTask?.status === "Completed" || String(updatingTask?.rawTask?.empId) !== String(currentUserEmpId)) return;

    setUpdateChecklist(prev => {
      const newList = prev.map(item =>
        item.id === id ? { ...item, completed: !item.completed } : item
      );
      const progress = computeProgress(newList, updatingTask);
      setUpdateProgressVal(progress);
      return newList;
    });
  };

  const handleAction = async (newStatus) => {
    if (!updatingTask) return;
    try {
      const originalTask = updatingTask.rawTask;
      const updatedTaskObj = {
        ...originalTask,
        taskSts: newStatus,
        addlRem: updateRemarks || originalTask.addlRem
      };

      const updatePath = updatingTask.isIndividual 
        ? `/api/individual-tasks/${updatingTask.taskId}`
        : `/api/task-live/${updatingTask.taskId}`;
        
      await apiPut(`${updatePath}?_t=${Date.now()}`, updatedTaskObj);

      const taskCode = updatingTask.id;
      if (newStatus === "REASSIGN") {
          await sendNotification(originalTask.empId, `Task Reassigned: ${taskCode}`, updatingTask);
      } else if (newStatus === "UNDER_REVIEW") { 
          if (originalTask.approverId) {
             await sendNotification(originalTask.approverId, `Task ready for Approval: ${taskCode}`, updatingTask);
          }
      } else if (newStatus === "COMPLETED") { 
          await sendNotification(originalTask.empId, `Task Completed: ${taskCode}`, updatingTask);
          if (originalTask.reviewerId) {
             await sendNotification(originalTask.reviewerId, `Task Completed: ${taskCode}`, updatingTask);
          }
      }

      await fetchTasks();
      setShowUpdateModal(false);
      triggerAlert("success", "Success", `Task status updated to ${newStatus}.`);
    } catch (err) {
      console.error("Error updating task:", err);
      triggerAlert("danger", "Error", "Failed to update task: " + err.message);
    }
  };

  const handleSubmitDeny = async () => {
    if (!updatingTask) return;
    try {
      const originalTask = updatingTask.rawTask;
      const newStatus = denyData.type; // "REASSIGN" or "REWORK"
      const updatedTaskObj = {
        ...originalTask,
        taskSts: newStatus,
        addlRem: denyData.reason
      };

      const updatePath = updatingTask.isIndividual 
        ? `/api/individual-tasks/${updatingTask.taskId}`
        : `/api/task-live/${updatingTask.taskId}`;
        
      await apiPut(`${updatePath}?_t=${Date.now()}`, updatedTaskObj);

      const taskCode = updatingTask.id;
      if (newStatus === "REASSIGN") {
          await sendNotification(originalTask.empId, `Task Reassigned: ${taskCode}. Reason: ${denyData.reason}`, updatingTask);
      } else if (newStatus === "REWORK") {
          await sendNotification(originalTask.empId, `Task sent back for Rework: ${taskCode}. Reason: ${denyData.reason}`, updatingTask);
      }

      await fetchTasks();
      setShowDenyForm(false);
      setShowUpdateModal(false);
      triggerAlert("success", "Success", `Task sent back to Executor.`);
    } catch (err) {
      console.error("Error denying task:", err);
      triggerAlert("danger", "Error", "Failed to deny task: " + err.message);
    }
  };

  const handleSaveProgress = async () => {
    if (!updatingTask) return;
    let progress = updateProgressVal;
    const originalTask = updatingTask.rawTask;
    const prcsFlg = originalTask?.prcsFlg || originalTask?.prcsflg || !!originalTask?.reviewerId || !!originalTask?.approverId || false;
    const currentSts = updatingTask.rawStatus;

    if (updateChecklist.length === 0 && currentSts !== "SUBMIT_REVIEW" && currentSts !== "UNDER_REVIEW") {
       progress = 100;
    }

    let backendSts = "OPEN";
    
    if (currentSts === "SUBMIT_REVIEW") {
       backendSts = "UNDER_REVIEW";
    } else if (currentSts === "UNDER_REVIEW") {
       backendSts = "COMPLETED";
    } else {
       if (prcsFlg && progress === 100) {
           backendSts = "SUBMIT_REVIEW";
       } else if (!prcsFlg && progress === 100) {
           backendSts = "COMPLETED";
       } else if (progress > 0) {
           backendSts = "WIP";
       } else {
           backendSts = (currentSts === "WIP" || currentSts === "OPEN" || currentSts === "REASSIGN" || currentSts === "REWORK") ? "WIP" : "OPEN";
       }
    }

    try {
      const updatedTaskObj = {
        ...originalTask,
        taskSts: backendSts,
        addlRem: updateRemarks || originalTask.addlRem
      };

      if (currentSts !== "SUBMIT_REVIEW" && currentSts !== "UNDER_REVIEW") {
        await Promise.all(updateChecklist
          .filter(item => item.id != null)
          .map(item => {
            const path = `/api/checklists/${item.id}/${item.completed ? 'complete' : 'reopen'}?_t=${Date.now()}`;
            return apiPatch(path, {});
          })
        );
      }

      const updatePath = updatingTask.isIndividual 
        ? `/api/individual-tasks/${updatingTask.taskId}`
        : `/api/task-live/${updatingTask.taskId}`;
        
      await apiPut(`${updatePath}?_t=${Date.now()}`, updatedTaskObj);

      if (backendSts === "SUBMIT_REVIEW") {
          if (originalTask.reviewerId) {
             await sendNotification(originalTask.reviewerId, `Task submitted for review: ${updatingTask.id}`, updatingTask);
          }
          if (originalTask.approverId) {
             await sendNotification(originalTask.approverId, `Task submitted for review: ${updatingTask.id}`, updatingTask);
          }
      } else if (backendSts === "COMPLETED") {
          await sendNotification(originalTask.empId, `Task Completed: ${updatingTask.id}`, updatingTask);
      } else if (backendSts === "WIP" || progress > 0) {
          const msg = `Task ${updatingTask.id} progress updated to ${progress}%`;
          if (originalTask.reviewerId) await sendNotification(originalTask.reviewerId, msg, updatingTask);
          if (originalTask.approverId) await sendNotification(originalTask.approverId, msg, updatingTask);
      }

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
    setCurrentPage(1);
  };

  useEffect(() => {
    setCurrentPage(1);
  }, [searchQuery, selectedProject, selectedMilestone, selectedPriority, selectedStatus, selectedDueDate]);

  const handleSearchKeyDown = (e) => {
    if (e.key === "Enter") {
      e.preventDefault();
      handleSearch();
    }
  };

  const filteredTasks = tasks.filter(task => {
    const isExec = String(task.rawTask.empId) === String(currentUserEmpId);
    const isRev = String(task.rawTask.reviewerId) === String(currentUserEmpId);
    const isApp = String(task.rawTask.approverId) === String(currentUserEmpId);
    
    let isVisible = false;
    if (isExec) isVisible = true;
    if (isRev && (task.rawStatus === "SUBMIT_REVIEW" || task.rawStatus === "UNDER_REVIEW" || task.rawStatus === "COMPLETED")) isVisible = true;
    if (isApp && (task.rawStatus === "UNDER_REVIEW" || task.rawStatus === "COMPLETED")) isVisible = true;

    if (!isVisible) return false;

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
      if (filterStatus === "To-Do") {
        if (task.status !== "To-Do" && task.status !== "Reassigned" && task.status !== "Rework") return false;
      } else if (task.status !== filterStatus) {
        return false;
      }
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

  const getCurrentStatusDisplay = () => {
    if (!updatingTask) return "To-Do";
    const prcsFlg = updatingTask.rawTask?.prcsFlg || false;
    return getDisplayStatus(updateProgressVal, updatingTask.status, prcsFlg);
  };

  // ===== MAIN RENDER =====
  return (
    <div className="cc-shell-container">
      <Sidebar onLogout={onLogout} />
      <div className="cc-shell">
        <Header title="My Tasks" subtitle="View and manage all tasks assigned to you." onLogout={onLogout} userRole={userRole} />

        <main className="cc-main">
          {(!showDetailModal && !showUpdateModal) && (
            <>
          {/* Metrics Cards */}
          <div className="myt-metrics-grid" style={{ marginBottom: "24px" }}>
            <div className={`myt-metric-card todo ${selectedStatus === "To-Do" || selectedStatus === "To-Do (Not Started)" ? "active" : ""}`} onClick={() => handleStatusFilterChange("To-Do")}>
              <div className="myt-metric-icon-box blue"><CalendarIcon size={20} /></div>
              <div className="myt-metric-info">
                <span className="myt-metric-label">To-Do</span>
                <span className="myt-metric-value">{countTodo} <small className="myt-small-label">Tasks</small></span>
              </div>
            </div>
            <div className={`myt-metric-card in-progress ${selectedStatus === "In Progress" ? "active" : ""}`} onClick={() => handleStatusFilterChange("In Progress")}>
              <div className="myt-metric-icon-box play-blue"><Play size={20} fill="currentColor" /></div>
              <div className="myt-metric-info">
                <span className="myt-metric-label">Open</span>
                <span className="myt-metric-value">{countInProgress} <small className="myt-small-label">Tasks</small></span>
              </div>
            </div>
            <div className={`myt-metric-card review ${selectedStatus === "Under Review" ? "active" : ""}`} onClick={() => handleStatusFilterChange("Under Review")}>
              <div className="myt-metric-icon-box eye-purple"><Eye size={20} /></div>
              <div className="myt-metric-info">
                <span className="myt-metric-label">Under Review</span>
                <span className="myt-metric-value">{countUnderReview} <small className="myt-small-label">Tasks</small></span>
              </div>
            </div>
            <div className={`myt-metric-card completed ${selectedStatus === "Completed" ? "active" : ""}`} onClick={() => handleStatusFilterChange("Completed")}>
              <div className="myt-metric-icon-box green"><CheckCircle2 size={20} /></div>
              <div className="myt-metric-info">
                <span className="myt-metric-label">Completed</span>
                <span className="myt-metric-value">{countCompleted} <small className="myt-small-label">Tasks</small></span>
              </div>
            </div>
            <div className={`myt-metric-card overdue ${selectedStatus === "Overdue" ? "active" : ""}`} onClick={() => handleStatusFilterChange("Overdue")}>
              <div className="myt-metric-icon-box red"><AlertCircle size={20} /></div>
              <div className="myt-metric-info">
                <span className="myt-metric-label">Overdue</span>
                <span className="myt-metric-value">{countOverdue} <small className="myt-small-label">Tasks</small></span>
              </div>
            </div>
          </div>

          <div className="myt-tabs-container" style={{ marginBottom: "20px", borderBottom: "none" }}>
            <div className="myt-tabs-left"></div>
            <div className="myt-tabs-right">
              <div className="myt-search-box">
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
            </div>
          </div>

          {/* Table Panel */}
          <div className="cc-table-panel" style={{ border: "none", boxShadow: "none", padding: 0 }}>
            <div className="cc-table-container">
              <table className="cc-list-table myt-table">
                <thead>
                  <tr>
                    <th>Task Code</th>
                    <th>Task Name</th>
                    <th>Team</th>
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
                      <td colSpan="8" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                        Loading tasks...
                      </td>
                    </tr>
                  ) : paginatedTasks.length > 0 ? (
                    paginatedTasks.map((task) => (
                      <tr key={task.id} onClick={() => openDetails(task)} style={{ cursor: "pointer" }}>
                        <td style={{ fontWeight: "600", color: "#0f172a" }}>{task.id}</td>
                        <td style={{ fontWeight: "500", color: "#1e293b" }}>{task.title}</td>
                        <td>
                          <div style={{ display: "flex", alignItems: "center" }}>
                            {[task.rawTask?.empId, task.rawTask?.reviewerId, task.rawTask?.approverId].filter(Boolean).map((eId, index) => {
                              const emp = employeesList.find(e => String(e.empId) === String(eId));
                              if (!emp) return null;
                              const name = emp.employeeName || `${emp.fstNm || emp.firstName || ""} ${emp.lstNm || emp.lastName || ""}`.trim() || "Unknown";
                              const initials = name === "Unknown" ? "UN" : name.substring(0, 2).toUpperCase();
                              const img = emp.photoUrl || emp.profileImageBase64 || emp.profileImage;
                              return (
                                <div key={index} title={`${name} (${index===0?'Executor':index===1?'Reviewer':'Approver'})`}
                                     style={{ 
                                       width: "28px", height: "28px", borderRadius: "50%", 
                                       backgroundColor: "#e2e8f0", color: "#475569", 
                                       display: "flex", alignItems: "center", justifyContent: "center",
                                       fontSize: "10px", fontWeight: "600", border: "2px solid #fff",
                                       marginLeft: index > 0 ? "-8px" : "0",
                                       overflow: "hidden"
                                     }}>
                                  {img ? <img src={img.startsWith('data:') || img.startsWith('http') ? img : `data:image/jpeg;base64,${img}`} alt={name} style={{ width: "100%", height: "100%", objectFit: "cover" }} /> : initials}
                                </div>
                              );
                            })}
                          </div>
                        </td>
                        <td>
                          <span className="cc-status-badge" style={{
                              backgroundColor: task.priority === "HIGH" ? "#fef2f2" : task.priority === "LOW" ? "#f0fdf4" : task.priority === "ATMOST CRITICAL" ? "#fef2f2" : "#fff7ed",
                              color: task.priority === "HIGH" ? "#ef4444" : task.priority === "LOW" ? "#16a34a" : task.priority === "ATMOST CRITICAL" ? "#dc2626" : "#ea580c"
                          }}>
                            {task.priority}
                          </span>
                        </td>
                        <td style={{ fontWeight: "600", color: "#0f172a" }}>{formatDate(task.dueDate || task.completedDate || task.submittedDate) || "—"}</td>
                        <td>
                          {task.status === "Reassigned" || task.status === "Rework" ? (
                            <span className="cc-status-badge" style={{ backgroundColor: "#fee2e2", color: "#ef4444", display: "inline-flex", alignItems: "center", gap: "4px" }}>
                              <Undo2 size={14} /> {task.status}
                            </span>
                          ) : (
                            <span className="cc-status-badge" style={{
                              backgroundColor: task.status === "Completed" ? "#dcfce7" : task.status === "Under Review" ? "#f3e8ff" : task.status === "In Progress" ? "#dbeafe" : task.status === "Overdue" ? "#fee2e2" : "#f1f5f9",
                              color: task.status === "Completed" ? "#166534" : task.status === "Under Review" ? "#6b21a8" : task.status === "In Progress" ? "#1d4ed8" : task.status === "Overdue" ? "#991b1b" : "#475569"
                            }}>
                              {task.status}
                            </span>
                          )}
                        </td>
                        <td onClick={(e) => e.stopPropagation()}>
                          <div className="myt-table-progress-wrap">
                            <span className="myt-progress-percentage">{task.progress}%</span>
                            <div className="myt-table-progress-track">
                              <div className="myt-table-progress-fill" style={{
                                width: `${task.progress}%`,
                                backgroundColor: task.status === "Completed" ? "#16a34a"
                                  : task.status === "Overdue" ? "#ef4444"
                                    : task.status === "In Progress" ? "#3b82f6"
                                      : task.status === "Under Review" ? "#8b5cf6"
                                        : "#e2e8f0"
                              }} />
                            </div>
                          </div>
                        </td>
                        <td onClick={(e) => e.stopPropagation()} style={{ textAlign: "center" }}>
                          {(() => {
                            const raw = task.rawTask;
                            const sts = task.rawStatus;
                            const isDoer = String(raw?.empId) === String(currentUserEmpId);
                            const isChecker = String(raw?.reviewerId) === String(currentUserEmpId);
                            const isApprover = String(raw?.approverId) === String(currentUserEmpId);
                            const isReviewerActionRequired = isChecker && sts === "SUBMIT_REVIEW";
                            const isApproverActionRequired = isApprover && sts === "UNDER_REVIEW";

                            if (isReviewerActionRequired || isApproverActionRequired) {
                              return (
                                <button className="myt-btn-update" style={{ backgroundColor: "#10b981" }} onClick={() => openUpdateModal(task)}>
                                  Approve
                                </button>
                              );
                            }

                            if (isDoer) {
                              if (task.status === "To-Do" || sts === "OPEN" || sts === "REASSIGN" || task.status === "Reassigned" || sts === "REWORK" || task.status === "Rework") {
                                return (
                                  <button className="myt-btn-update" style={{ backgroundColor: "#3b82f6", color: "white" }} onClick={() => openUpdateModal(task)}>
                                    Open
                                  </button>
                                );
                              } else if (task.status === "In Progress" || sts === "WIP") {
                                return (
                                  <button className="myt-btn-update" onClick={() => openUpdateModal(task)}>
                                    Update
                                  </button>
                                );
                              }
                            }

                            return (
                              <button className="myt-btn-update" onClick={() => openUpdateModal(task)}>
                                View
                              </button>
                            );
                          })()}
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan="8" style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
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
          </>)}

          {/* ====== DETAIL INLINE VIEW ====== */}
          {showDetailModal && selectedTask && (
              <div style={{
                maxWidth: "900px",
                margin: "0 auto",
                background: "#fff",
                borderRadius: "12px",
                boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
                display: "flex",
                flexDirection: "column",
                maxHeight: "calc(100vh - 120px)",
                overflow: "hidden"
              }}>
                <div className="cc-modal-header" style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "16px",
                  borderBottom: "1px solid #e2e8f0",
                  padding: "20px 24px",
                  flexWrap: "wrap"
                }}>
                  <button onClick={() => setShowDetailModal(false)} style={{
                    display: "flex",
                    alignItems: "center",
                    gap: "6px",
                    background: "none",
                    border: "1px solid #cbd5e1",
                    borderRadius: "8px",
                    padding: "7px 14px",
                    cursor: "pointer",
                    color: "#475569",
                    fontWeight: 500,
                    fontSize: "14px"
                  }}>
                    ← Back to My Tasks
                  </button>
                  <h3 style={{ margin: 0 }}>Task Details: {selectedTask.id}</h3>
                </div>
                <div className="cc-modal-body" style={{ padding: "24px" }}>
                  <div className="myt-detail-row"><span className="myt-detail-label">Task ID</span><span className="myt-detail-value">{selectedTask.id}</span></div>
                  <div className="myt-detail-row"><span className="myt-detail-label">Title</span><span className="myt-detail-value">{selectedTask.title}</span></div>
                  <div className="myt-detail-row"><span className="myt-detail-label">Project</span><span className="myt-detail-value">{selectedTask.project}</span></div>
                  <div className="myt-detail-row"><span className="myt-detail-label">Milestone</span><span className="myt-detail-value">{selectedTask.milestone}</span></div>
                  <div className="myt-detail-row"><span className="myt-detail-label">Assigned By</span><span className="myt-detail-value">{selectedTask.assignedBy}</span></div>
                  {selectedTask.submittedTo && <div className="myt-detail-row"><span className="myt-detail-label">Submitted To</span><span className="myt-detail-value">{selectedTask.submittedTo}</span></div>}
                  <div className="myt-detail-row"><span className="myt-detail-label">Priority</span><span className={`myt-priority-badge ${selectedTask.priority.toLowerCase().replace(/\s+/g, '-')}`}>{selectedTask.priority}</span></div>
                  {selectedTask.dueDate && <div className="myt-detail-row"><span className="myt-detail-label">Due Date</span><span className="myt-detail-value">{formatDate(selectedTask.dueDate)}</span></div>}
                  {selectedTask.submittedDate && <div className="myt-detail-row"><span className="myt-detail-label">Submitted Date</span><span className="myt-detail-value">{formatDate(selectedTask.submittedDate)}</span></div>}
                  {selectedTask.completedDate && <div className="myt-detail-row"><span className="myt-detail-label">Completed Date</span><span className="myt-detail-value">{formatDate(selectedTask.completedDate)}</span></div>}
                  <div className="myt-detail-row"><span className="myt-detail-label">Status</span><span className={`cc-status-badge`} style={{ backgroundColor: selectedTask.status === "Completed" ? "#dcfce7" : "#eff6ff", color: selectedTask.status === "Completed" ? "#166534" : "#1d4ed8" }}>{selectedTask.status}</span></div>
                  <div className="myt-detail-row"><span className="myt-detail-label">Progress</span><span className="myt-detail-value">{selectedTask.progress}%</span></div>
                  <div className="myt-detail-row"><span className="myt-detail-label">Description</span><span className="myt-detail-value myt-desc-val">{selectedTask.description}</span></div>
                </div>
                <div className="cc-modal-footer" style={{
                  display: "flex",
                  justifyContent: "flex-end",
                  padding: "16px 24px",
                  borderTop: "1px solid #e2e8f0"
                }}>
                  <button className="cc-btn primary" onClick={() => setShowDetailModal(false)}>Close</button>
                </div>
              </div>
      )}

      {/* ====== UPDATE PROGRESS INLINE VIEW ====== */}
      {showUpdateModal && updatingTask && (
              <div style={{
                maxWidth: "900px",
                margin: "0 auto",
                background: "#fff",
                borderRadius: "12px",
                boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
                display: "flex",
                flexDirection: "column",
                maxHeight: "calc(100vh - 120px)",
                overflow: "hidden"
              }}>
                <div className="cc-modal-header" style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "16px",
                  borderBottom: "1px solid #e2e8f0",
                  padding: "20px 24px",
                  flexWrap: "wrap"
                }}>
                  <button onClick={() => setShowUpdateModal(false)} style={{
                    display: "flex",
                    alignItems: "center",
                    gap: "6px",
                    background: "none",
                    border: "1px solid #cbd5e1",
                    borderRadius: "8px",
                    padding: "7px 14px",
                    cursor: "pointer",
                    color: "#475569",
                    fontWeight: 500,
                    fontSize: "14px"
                  }}>
                    ← Back to My Tasks
                  </button>
                  <h3 style={{ margin: 0 }}>
                    {(() => {
                      const sts = updatingTask?.rawStatus;
                      const isChecker = String(updatingTask?.rawTask?.reviewerId) === String(currentUserEmpId);
                      const isApprover = String(updatingTask?.rawTask?.approverId) === String(currentUserEmpId);
                      if ((isChecker && sts === "SUBMIT_REVIEW") || (isApprover && sts === "UNDER_REVIEW")) {
                        return "Approve Task";
                      }
                      return "Update Task Progress";
                    })()}
                  </h3>
                </div>
                <div className="cc-modal-body" style={{ padding: "0 24px 24px 24px" }}>
                  {showDenyForm ? (
                    <div className="myt-deny-form-container" style={{ padding: "20px 0" }}>
                      <h4 style={{ fontSize: "16px", fontWeight: "600", marginBottom: "20px", color: "#0f172a", borderBottom: "1px solid #e2e8f0", paddingBottom: "12px" }}>Raise Reassignment Request</h4>

                      <div className="myt-form-group" style={{ marginBottom: "24px" }}>
                        <label style={{ display: "block", fontSize: "13px", fontWeight: "600", color: "#475569", marginBottom: "8px" }}>Raise Reassignment Request</label>
                        <div style={{ display: "flex", gap: "16px" }}>
                          <label style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "14px", cursor: "pointer" }}>
                            <input type="radio" name="denyType" value="REASSIGN" checked={denyData.type === "REASSIGN"} onChange={() => setDenyData({...denyData, type: "REASSIGN"})} />
                            Task to Task (Reassign)
                          </label>
                          <label style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "14px", cursor: "pointer" }}>
                            <input type="radio" name="denyType" value="REWORK" checked={denyData.type === "REWORK"} onChange={() => setDenyData({...denyData, type: "REWORK"})} />
                            Milestone to Milestone (Rework)
                          </label>
                        </div>
                      </div>
                      
                      {denyData.type === "REWORK" && (
                        <div className="myt-form-group" style={{ marginBottom: "16px" }}>
                          <label style={{ display: "block", fontSize: "13px", fontWeight: "600", color: "#475569", marginBottom: "6px" }}>Select source Milestone</label>
                          <select className="myt-input" style={{ width: "100%", padding: "10px", borderRadius: "6px", border: "1px solid #cbd5e1" }}
                            value={denyData.milestone} onChange={e => setDenyData({...denyData, milestone: e.target.value})}>
                            <option value="">Select Milestone</option>
                            {milestonesList.filter(m => m !== "All Milestones").map(m => <option key={m} value={m}>{m}</option>)}
                          </select>
                        </div>
                      )}

                      <div className="myt-form-group" style={{ marginBottom: "16px" }}>
                        <label style={{ display: "block", fontSize: "13px", fontWeight: "600", color: "#475569", marginBottom: "6px" }}>{denyData.type === "REWORK" ? "Select Deliverable" : "Task dropdown"}</label>
                        <select className="myt-input" style={{ width: "100%", padding: "10px", borderRadius: "6px", border: "1px solid #cbd5e1" }}
                          value={denyData.deliverable} onChange={e => setDenyData({...denyData, deliverable: e.target.value})}>
                          <option value="">{denyData.type === "REWORK" ? "Select Deliverable" : "Select Task"}</option>
                          <option value={updatingTask.title}>{updatingTask.title}</option>
                        </select>
                      </div>

                      <div className="myt-form-group" style={{ marginBottom: "16px" }}>
                        <label style={{ display: "block", fontSize: "13px", fontWeight: "600", color: "#475569", marginBottom: "6px" }}>Reason</label>
                        <textarea className="myt-input" style={{ width: "100%", padding: "10px", borderRadius: "6px", border: "1px solid #cbd5e1", minHeight: "80px" }}
                          placeholder="Enter reason for denial..."
                          value={denyData.reason} onChange={e => setDenyData({...denyData, reason: e.target.value})}></textarea>
                      </div>

                      <div className="myt-form-group" style={{ marginBottom: "16px" }}>
                        <label style={{ display: "block", fontSize: "13px", fontWeight: "600", color: "#475569", marginBottom: "6px" }}>Attachments (optional)</label>
                        <input type="file" style={{ width: "100%", padding: "8px", borderRadius: "6px", border: "1px dashed #cbd5e1", backgroundColor: "#f8fafc" }} />
                      </div>

                      <div className="myt-form-group" style={{ marginBottom: "20px" }}>
                        <label style={{ display: "block", fontSize: "13px", fontWeight: "600", color: "#475569", marginBottom: "6px" }}>Impact</label>
                        <select className="myt-input" style={{ width: "100%", padding: "10px", borderRadius: "6px", border: "1px solid #cbd5e1" }}
                          value={denyData.impact} onChange={e => setDenyData({...denyData, impact: e.target.value})}>
                          <option value="Low">Low</option>
                          <option value="Medium">Medium</option>
                          <option value="High">High</option>
                        </select>
                      </div>

                      <div style={{ display: "flex", justifyContent: "flex-end", gap: "12px", borderTop: "1px solid #e2e8f0", paddingTop: "16px" }}>
                        <button className="cc-btn secondary" onClick={() => setShowDenyForm(false)} style={{ borderRadius: "6px" }}>Cancel</button>
                        <button className="cc-btn primary" onClick={handleSubmitDeny} disabled={!denyData.reason} style={{ borderRadius: "6px", backgroundColor: "#ef4444", border: "none" }}>Submit Rework Request</button>
                      </div>
                    </div>
                  ) : (
                  <>
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
                          <span className="value">: <span className={`myt-priority-badge ${updatingTask.priority.toLowerCase().replace(/\s+/g, '-')}`}>{updatingTask.priority}</span></span>
                        </div>
                        <div className="myt-detail-item">
                          <span className="label">Status</span>
                          <span className="value">:
                            <span className={`cc-status-badge`} style={{
                              marginLeft: "4px",
                              backgroundColor: getCurrentStatusDisplay() === "Completed" ? "#dcfce7" :
                                getCurrentStatusDisplay() === "Under Review" ? "#f3e8ff" :
                                getCurrentStatusDisplay() === "In Progress" ? "#dbeafe" : "#f1f5f9",
                              color: getCurrentStatusDisplay() === "Completed" ? "#166534" :
                                getCurrentStatusDisplay() === "Under Review" ? "#6b21a8" :
                                getCurrentStatusDisplay() === "In Progress" ? "#1d4ed8" : "#475569",
                              padding: "2px 8px",
                              borderRadius: "4px",
                              fontSize: "13px",
                              fontWeight: "500"
                            }}>
                              {getCurrentStatusDisplay()}
                            </span>
                          </span>
                        </div>
                        <div className="myt-detail-item"><span className="label">Current Progress</span><span className="value">: {updateProgressVal}%</span></div>
                      </div>
                    </div>
                  </div>

                  {(updatingTask?.rawStatus === "REASSIGN" || updatingTask?.rawStatus === "REWORK") && updatingTask?.rawTask?.addlRem && (
                    <div className="myt-modal-section" style={{ backgroundColor: "#fee2e2", padding: "12px", borderRadius: "8px", border: "1px solid #fca5a5" }}>
                      <h4 style={{ fontSize: "14px", fontWeight: "600", marginBottom: "4px", color: "#b91c1c" }}>Reviewer Remarks</h4>
                      <p style={{ margin: 0, fontSize: "13px", color: "#7f1d1d", whiteSpace: "pre-wrap" }}>{updatingTask.rawTask.addlRem}</p>
                    </div>
                  )}

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
                          <div className="myt-checklist-row" key={item.id} onClick={() => handleToggleChecklist(item.id)} style={{ 
                            cursor: updatingTask?.status === "Under Review" || updatingTask?.status === "Completed" ? "not-allowed" : "pointer", 
                            opacity: updatingTask?.status === "Under Review" || updatingTask?.status === "Completed" ? 0.7 : 1 
                          }}>
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
                    <div className="myt-overall-progress-track">
                      <div className="myt-overall-progress-fill" style={{ 
                          width: `${updateProgressVal}%`,
                          backgroundColor: getCurrentStatusDisplay() === "Completed" ? "#16a34a"
                            : getCurrentStatusDisplay() === "Overdue" ? "#ef4444"
                            : getCurrentStatusDisplay() === "Under Review" ? "#8b5cf6"
                            : "#3b82f6"
                      }}></div>
                    </div>
                    {(() => {
                       if (updatingTask?.rawTask?.prcsFlg) {
                           if (updatingTask?.rawStatus === 'SUBMIT_REVIEW') {
                               return <div style={{ fontSize: '12px', color: '#64748b', marginTop: '6px', fontStyle: 'italic' }}>Note: Remaining 10% is pending with Checker and Approver.</div>;
                           } else if (updatingTask?.rawStatus === 'UNDER_REVIEW') {
                               return <div style={{ fontSize: '12px', color: '#64748b', marginTop: '6px', fontStyle: 'italic' }}>Note: Remaining 5% is pending with Approver.</div>;
                           }
                       }
                       return null;
                    })()}
                  </div>

                  <div className="myt-modal-section">
                    <h4 style={{ fontSize: "14px", fontWeight: "600", marginBottom: "8px", color: "#0f172a" }}>Remarks <span style={{ fontWeight: "400", color: "#64748b" }}>(Optional)</span></h4>
                    <textarea
                      className="myt-remarks-input"
                      placeholder="Enter remarks..."
                      value={updateRemarks}
                      onChange={(e) => setUpdateRemarks(e.target.value)}
                      disabled={updatingTask?.status === "Completed"}
                    />
                  </div>

                  <div className="myt-modal-section">
                    <h4 style={{ fontSize: "14px", fontWeight: "600", marginBottom: "8px", color: "#0f172a" }}>Upload Evidence <span style={{ fontWeight: "400", color: "#64748b" }}>(Optional)</span></h4>
                    <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                      <label className="myt-file-upload-btn" style={{ opacity: updatingTask?.status === "Completed" ? 0.6 : 1, cursor: updatingTask?.status === "Completed" ? "not-allowed" : "pointer" }}>
                        Choose Files
                        <input type="file" style={{ display: "none" }} disabled={updatingTask?.status === "Completed"} />
                      </label>
                      <span style={{ fontSize: "13px", color: "#64748b" }}>No file chosen</span>
                    </div>
                  </div>

                  <div className="myt-modal-actions" style={{ borderTop: "none", marginTop: "16px", paddingTop: "0", display: "flex", gap: "10px", justifyContent: "flex-end" }}>
                    {(() => {
                      const sts = updatingTask?.rawStatus;
                      const isCompleted = sts === "COMPLETED";
                      const isDoer = String(updatingTask?.rawTask?.empId) === String(currentUserEmpId);
                      const isChecker = String(updatingTask?.rawTask?.reviewerId) === String(currentUserEmpId);
                      const isApprover = String(updatingTask?.rawTask?.approverId) === String(currentUserEmpId);
                      const isOther = !isDoer && !isChecker && !isApprover;

                      if (isCompleted) {
                          return <button className="cc-btn secondary" onClick={() => setShowUpdateModal(false)} style={{ borderRadius: "6px" }}>Close</button>;
                      }

                      if (sts === "SUBMIT_REVIEW") {
                          if (isDoer) {
                              return (
                                  <>
                                      <button className="cc-btn secondary" onClick={() => setShowUpdateModal(false)} style={{ borderRadius: "6px" }}>Close</button>
                                      <button className="cc-btn primary" onClick={() => { triggerAlert("success", "Sent", "Reminder sent!"); setShowUpdateModal(false); }} style={{ borderRadius: "6px", backgroundColor: "#0f172a" }}>Send Reminder</button>
                                  </>
                              );
                          } else if (isChecker || isOther) {
                              return (
                                  <>
                                      <button className="cc-btn secondary" onClick={() => setShowUpdateModal(false)} style={{ borderRadius: "6px" }}>Close</button>
                                      <button className="cc-btn danger" onClick={() => setShowDenyForm(true)} style={{ borderRadius: "6px", backgroundColor: "#ef4444", color: "white", border: "none" }}>Denied</button>
                                      <button className="cc-btn primary" onClick={() => handleAction("UNDER_REVIEW")} style={{ borderRadius: "6px", backgroundColor: "#10b981", border: "none" }}>Approve</button>
                                  </>
                              );
                          }
                      }

                      if (sts === "UNDER_REVIEW") {
                          if (isDoer || isChecker) {
                              return (
                                  <>
                                      <button className="cc-btn secondary" onClick={() => setShowUpdateModal(false)} style={{ borderRadius: "6px" }}>Close</button>
                                      <button className="cc-btn primary" onClick={() => { triggerAlert("success", "Sent", "Reminder sent!"); setShowUpdateModal(false); }} style={{ borderRadius: "6px", backgroundColor: "#0f172a" }}>Send Reminder</button>
                                  </>
                              );
                          } else if (isApprover || isOther) {
                              return (
                                  <>
                                      <button className="cc-btn secondary" onClick={() => setShowUpdateModal(false)} style={{ borderRadius: "6px" }}>Close</button>
                                      <button className="cc-btn danger" onClick={() => setShowDenyForm(true)} style={{ borderRadius: "6px", backgroundColor: "#ef4444", color: "white", border: "none" }}>Denied</button>
                                      <button className="cc-btn primary" onClick={() => handleAction("COMPLETED")} style={{ borderRadius: "6px", backgroundColor: "#10b981", border: "none" }}>Approve</button>
                                  </>
                              );
                          }
                      }

                      if (sts === "OPEN" || sts === "REASSIGN" || sts === "REWORK" || updatingTask?.status === "To-Do" || updatingTask?.status === "Reassigned" || updatingTask?.status === "Rework") {
                          return (
                              <>
                                <button className="cc-btn secondary" onClick={() => setShowUpdateModal(false)} style={{ borderRadius: "6px" }}>Close</button>
                                <button className="cc-btn primary" onClick={() => { setShowUpdateModal(false); handleStartTask(updatingTask); }} style={{ borderRadius: "6px", backgroundColor: "#3b82f6", border: "none" }}>Start Task</button>
                              </>
                          );
                      }

                      return (
                          <>
                            <button className="cc-btn secondary" onClick={() => setShowUpdateModal(false)} style={{ borderRadius: "6px" }}>Close</button>
                            <button className="cc-btn primary" onClick={handleSaveProgress} style={{ borderRadius: "6px", backgroundColor: "#0f172a" }}>
                              {updateProgressVal === 100 || updateChecklist.length === 0 
                                ? (updatingTask?.rawTask?.prcsFlg ? "Submit for Review" : "Mark as Completed") 
                                : "Update"}
                            </button>
                          </>
                      );
                    })()}
                  </div>
                  </>
                  )}
                </div>
              </div>
      )}
        </main>
      </div>

      <AlertModal isOpen={alertOpen} type={alertConfig.type} title={alertConfig.title} message={alertConfig.message} onClose={() => setAlertOpen(false)} />
    </div>
  );
};

export default MyTasks;