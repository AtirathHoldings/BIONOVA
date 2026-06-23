import { useState, useEffect } from "react";
import {
  ArrowLeft,
  Bell,
  ChevronDown,
  ChevronRight,
  Edit,
  Eye,
  EyeOff,
  Menu,
  RefreshCcw,
  Save,
  Trash2,
  User,
  Search,
  X,
  MoreVertical,
  Calendar,
  Mail,
  Phone,
  MapPin,
  Image,
  Lock,
  Plus,
  Building,
  Factory,
  Users,
  Briefcase,
  Upload,
  CheckCircle2,
  FileText
} from "lucide-react";
import Sidebar from "../Sidebar";
import Header from "../Header";
import AlertModal from "../AlertModal";
import "../../styles/EmployeeMaster.css";

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || "http://localhost:8080";

const getAuthHeaders = () => ({
  "Content-Type": "application/json",
  "Authorization": `Bearer ${sessionStorage.getItem("authToken") || ""}`
});

const EmployeeCreation = ({ userRole, onLogout }) => {
  // API States
  const [employees, setEmployees] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [companies, setCompanies] = useState([]);
  const [plants, setPlants] = useState([]);
  const [loading, setLoading] = useState(false);

  // Views & UI States
  const [view, setView] = useState("list");
  const [isEditing, setIsEditing] = useState(false);
  const [editId, setEditId] = useState(null);
  const [photo, setPhoto] = useState(null);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [activeActionsMenu, setActiveActionsMenu] = useState(null);

  const [alertConfig, setAlertConfig] = useState({
    isOpen: false,
    type: "info",
    title: "",
    message: ""
  });

  const triggerAlert = (type, title, message) => {
    setAlertConfig({ isOpen: true, type, title, message });
  };

  // Department Modal State
  const [showDeptModal, setShowDeptModal] = useState(false);
  const [deptForm, setDeptForm] = useState({
    code: "",
    name: "",
    description: "",
    status: "Active"
  });
  // Employee Form State
  const [form, setForm] = useState({
    employeeCode: "",
    firstName: "",
    lastName: "",
    gender: "",
    dateOfBirth: "",
    email: "",
    mobile: "",
    bloodGroup: "",
    address: "",
    photoPath: "",
    joiningDate: "",
    designation: "",
    company: "",
    plant: "",
    department: "",
    workLocation: "",
    reportingManager: "",
    username: "",
    password: "",
    confirmPassword: "",
    status: ""
  });

  const fetchAllData = async () => {
    setLoading(true);
    try {
      const [empRes, coyRes, pltRes, deptRes] = await Promise.all([
        fetch(`${apiBaseUrl}/api/employees`, { headers: getAuthHeaders() }),
        fetch(`${apiBaseUrl}/api/companies`, { headers: getAuthHeaders() }),
        fetch(`${apiBaseUrl}/api/plants`, { headers: getAuthHeaders() }),
        fetch(`${apiBaseUrl}/api/departments`, { headers: getAuthHeaders() })
      ]);

      const coyData = coyRes.ok ? await coyRes.json() : [];
      const pltData = pltRes.ok ? await pltRes.json() : [];
      const deptData = deptRes.ok ? await deptRes.json() : [];

      if (empRes.ok) {
        const data = await empRes.json();
        const mappedEmps = data.map(emp => {
          const coyNm = coyData.find(c => String(c.coyId || c.id) === String(emp.coyId))?.coyNm || emp.company || "N/A";
          const pltNm = pltData.find(p => String(p.pltId || p.id) === String(emp.pltId))?.pltNm || emp.plant || "N/A";
          const deptNm = deptData.find(d => String(d.deptId || d.id) === String(emp.deptId))?.deptNm || emp.department || "N/A";

          return {
            ...emp,
            id: emp.empId || emp.id,
            employeeCode: emp.empCode || emp.employeeCode || "",
            employeeName: `${emp.firstName || ""} ${emp.lastName || ""}`.trim(),
            gender: emp.gender ? (emp.gender.charAt(0) + emp.gender.slice(1).toLowerCase()) : "",
            dateOfBirth: emp.dob || emp.dateOfBirth || "",
            mobile: emp.mobNum || emp.mobile || "",
            bloodGroup: emp.bldGrp || emp.bloodGroup || "",
            photoPath: emp.photoUrl || emp.photoPath || "",
            joiningDate: emp.doj || emp.joiningDate || "",
            workLocation: emp.wloc || emp.wLoc || emp.workLocation || "",
            status: emp.status === true || emp.status === "Active" ? "Active" : "Inactive",
            company: coyNm,
            plant: pltNm,
            department: deptNm
          };
        });
        setEmployees(mappedEmps);
      }
      
      setCompanies(coyData);
      setPlants(pltData);
      setDepartments(deptData);
    } catch (err) {
      console.error("Error fetching data:", err);
      // alertConfig might not be available right away, so we just log
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAllData();
  }, []);

  // Handle Input Change for Employee Form
  const handleChange = (e) => {
    const { name, value } = e.target;

    // Check if user clicked "+ Create Department"
    if (name === "department" && value === "CREATE_NEW") {
      setShowDeptModal(true);
      return;
    }

    let newValue = value;
    if (name === "employeeCode") {
      newValue = value.slice(0, 10);
    } else if (name === "firstName" || name === "lastName") {
      newValue = value.slice(0, 50);
    } else if (name === "gender") {
      newValue = value.slice(0, 10);
    } else if (name === "email" || name === "username") {
      newValue = value.slice(0, 50);
    } else if (name === "mobile") {
      newValue = value.replace(/[^0-9]/g, '').slice(0, 10);
    } else if (name === "bloodGroup") {
      newValue = value.slice(0, 5);
    } else if (name === "address") {
      newValue = value.slice(0, 255);
    } else if (name === "workLocation") {
      newValue = value.slice(0, 100);
    } else if (name === "password" || name === "confirmPassword") {
      newValue = value.slice(0, 10); // <--- changed to 10
    }

    if (name === "email") {
      setForm((prev) => ({ ...prev, email: newValue, username: newValue }));
    } else {
      setForm((prev) => ({ ...prev, [name]: newValue }));
    }
  };

  // Handle Profile Photo Upload
  const handlePhotoChange = (event) => {
    const file = event.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = () => {
      setPhoto(reader.result);
      setForm((prev) => ({ ...prev, photoPath: reader.result }));
    };
    reader.readAsDataURL(file);
  };

  // Handle New Department Modal Input Change
  const handleDeptChange = (e) => {
    const { name, value } = e.target;
    setDeptForm((prev) => ({ ...prev, [name]: value }));
  };

  // Save New Department from Modal
  const handleSaveNewDepartment = async () => {
    if (!deptForm.code.trim() || !deptForm.name.trim()) {
      triggerAlert("error", "Validation Error", "Department code and name are required.");
      return;
    }

    const payload = {
      deptCd: deptForm.code.trim().toUpperCase(),
      deptNm: deptForm.name.trim(),
      descr: deptForm.description.trim(),
      sts: deptForm.status === "Active"
    };

    try {
      const response = await fetch(`${apiBaseUrl}/api/departments`, {
        method: "POST",
        headers: getAuthHeaders(),
        body: JSON.stringify(payload)
      });

      if (response.ok) {
        const newDept = await response.json();
        triggerAlert("success", "Success", "Department created successfully!");
        setDeptForm({ code: "", name: "", description: "", status: "Active" });
        setShowDeptModal(false);
        const deptRes = await fetch(`${apiBaseUrl}/api/departments`, { headers: getAuthHeaders() });
        if (deptRes.ok) {
          setDepartments(await deptRes.json());
        }
        setForm((prev) => ({ ...prev, department: String(newDept.deptId || newDept.id) }));
      } else {
        triggerAlert("error", "Error", "Failed to save department. Ensure department code is unique.");
      }
    } catch (err) {
      console.error("Error saving department:", err);
      triggerAlert("error", "Error", "Server error occurred.");
    }
  };

  // Reset Employee Form
  const handleReset = () => {
    setForm({
      employeeCode: "",
      firstName: "",
      lastName: "",
      gender: "",
      dateOfBirth: "",
      email: "",
      mobile: "",
      bloodGroup: "",
      address: "",
      photoPath: "",
      joiningDate: "",
      designation: "",
      company: "",
      plant: "",
      department: "",
      workLocation: "",
      reportingManager: "",
      username: "",
      password: "",
      confirmPassword: "",
      status: ""
    });
    setPhoto(null);
    setShowPassword(false);
    setShowConfirmPassword(false);
  };

  // Save / Submit Employee
  const handleSave = async (e) => {
    if (e) e.preventDefault();

    // 1. Employee Code check
    if (!form.employeeCode.trim()) {
      triggerAlert("error", "Validation Error", "Employee Code is required.");
      return;
    }
    if (form.employeeCode.length > 10) {
      triggerAlert("error", "Validation Error", "Employee Code cannot exceed 10 characters.");
      return;
    }

    // 2. First Name check
    if (!form.firstName.trim()) {
      triggerAlert("error", "Validation Error", "First Name is required.");
      return;
    }
    if (form.firstName.length > 50) {
      triggerAlert("error", "Validation Error", "First Name cannot exceed 50 characters.");
      return;
    }

    // 3. Last Name check
    if (!form.lastName.trim()) {
      triggerAlert("error", "Validation Error", "Last Name is required.");
      return;
    }
    if (form.lastName.length > 50) {
      triggerAlert("error", "Validation Error", "Last Name cannot exceed 50 characters.");
      return;
    }

    // 4. Gender check
    if (!form.gender) {
      triggerAlert("error", "Validation Error", "Gender selection is required.");
      return;
    }
    if (form.gender.length > 10) {
      triggerAlert("error", "Validation Error", "Gender cannot exceed 10 characters.");
      return;
    }

    // 5. Date of Birth check
    if (!form.dateOfBirth) {
      triggerAlert("error", "Validation Error", "Date of Birth is required.");
      return;
    }

    // 6. Employee Email check
    if (!form.email.trim()) {
      triggerAlert("error", "Validation Error", "Employee Email is required.");
      return;
    }
    if (form.email.length > 50) {
      triggerAlert("error", "Validation Error", "Employee Email cannot exceed 50 characters.");
      return;
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(form.email.trim())) {
      triggerAlert("error", "Validation Error", "Please enter a valid Employee Email address.");
      return;
    }

    // 7. Mobile Number check
    if (!form.mobile.trim()) {
      triggerAlert("error", "Validation Error", "Mobile Number is required.");
      return;
    }
    const mobileRegex = /^\d{10}$/;
    if (!mobileRegex.test(form.mobile.trim())) {
      triggerAlert("error", "Validation Error", "Mobile Number must be exactly 10 digits.");
      return;
    }

    // 8. Blood Group check
    if (form.bloodGroup && form.bloodGroup.length > 5) {
      triggerAlert("error", "Validation Error", "Blood Group cannot exceed 5 characters.");
      return;
    }

    // 9. Employee Address check
    if (!form.address.trim()) {
      triggerAlert("error", "Validation Error", "Employee Address is required.");
      return;
    }
    if (form.address.length > 255) {
      triggerAlert("error", "Validation Error", "Employee Address cannot exceed 255 characters.");
      return;
    }

    // 10. Joining Date check
    if (!form.joiningDate) {
      triggerAlert("error", "Validation Error", "Joining Date is required.");
      return;
    }

    // 11. Designation check
    if (!form.designation.trim()) {
      triggerAlert("error", "Validation Error", "Designation is required.");
      return;
    }

    // 12. Company check
    if (!form.company) {
      triggerAlert("error", "Validation Error", "Company selection is required.");
      return;
    }

    // 13. Plant check
    if (!form.plant) {
      triggerAlert("error", "Validation Error", "Plant selection is required.");
      return;
    }

    // 14. Department check
    if (!form.department) {
      triggerAlert("error", "Validation Error", "Department selection is required.");
      return;
    }

    // 15. Work Location check
    if (!form.workLocation.trim()) {
      triggerAlert("error", "Validation Error", "Work Location is required.");
      return;
    }
    if (form.workLocation.length > 100) {
      triggerAlert("error", "Validation Error", "Work Location cannot exceed 100 characters.");
      return;
    }

    // 16. Reporting Manager check
    if (!form.reportingManager) {
      triggerAlert("error", "Validation Error", "Reporting Manager is required.");
      return;
    }

    // 17. Username check
    if (!form.username.trim()) {
      triggerAlert("error", "Validation Error", "Username (Email) is required.");
      return;
    }
    if (form.username.length > 50) {
      triggerAlert("error", "Validation Error", "Username cannot exceed 50 characters.");
      return;
    }

    // 18. Password check with complexity rules (EXACTLY 10 characters, 1 upper, 1 lower, 1 special)
    if (!form.password) {
      triggerAlert("error", "Validation Error", "Password is required.");
      return;
    }
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]).{10}$/;
    if (!passwordRegex.test(form.password)) {
      triggerAlert(
        "error",
        "Validation Error",
        "Password must be exactly 10 characters long and include at least one uppercase letter, one lowercase letter, and one special character."
      );
      return;
    }
    if (form.password !== form.confirmPassword) {
      triggerAlert("error", "Validation Error", "Password and Confirm Password do not match!");
      return;
    }

    // 19. Status check
    if (!form.status) {
      triggerAlert("error", "Validation Error", "Employee Status is required.");
      return;
    }

    // Unique Employee Code check is handled by backend, but we can do a quick local check
    const isDuplicate = employees.some(
      emp => emp.employeeCode.toLowerCase().trim() === form.employeeCode.toLowerCase().trim() && emp.id !== editId
    );

    if (isDuplicate) {
      triggerAlert("error", "Duplicate Error", "Employee code must be unique. This code already exists.");
      return;
    }

    const payload = {
      empCode: form.employeeCode.trim(),
      firstName: form.firstName.trim(),
      lastName: form.lastName.trim(),
      gender: form.gender.toUpperCase(),
      dob: form.dateOfBirth,
      email: form.email.trim(),
      mobNum: form.mobile.trim(),
      bldGrp: form.bloodGroup || null,
      address: form.address.trim(),
      photoUrl: form.photoPath || null,
      doj: form.joiningDate,
      desigId: 1, // Default or map if designation table exists
      coyId: parseInt(form.company),
      pltId: parseInt(form.plant),
      deptId: parseInt(form.department),
      wloc: form.workLocation.trim(),
      repManId: form.reportingManager ? parseInt(form.reportingManager) : null,
      status: form.status === "Active",
      role: form.role || "user",
      password: form.password || null
    };

    setLoading(true);
    try {
      let url = `${apiBaseUrl}/api/employees`;
      let method = "POST";
      if (isEditing) {
        url = `${apiBaseUrl}/api/employees/${editId}`;
        method = "PUT";
      }

      const response = await fetch(url, {
        method: method,
        headers: getAuthHeaders(),
        body: JSON.stringify(payload)
      });

      if (response.ok) {
        triggerAlert("success", "Success", isEditing ? "Employee updated successfully!" : "Employee created successfully!");
        setIsEditing(false);
        setEditId(null);
        handleReset();
        setView("list");
        fetchAllData();
      } else {
        const errorText = await response.text();
        triggerAlert("error", "Error", "Failed to save employee: " + (errorText || "Ensure Unique constraints are met."));
      }
    } catch (err) {
      console.error("Error saving employee:", err);
      triggerAlert("error", "Error", "Server error: " + err.message);
    } finally {
      setLoading(false);
    }
  };

  // Edit Action
  const handleEdit = (emp) => {
    setForm({
      employeeCode: emp.empCode || emp.employeeCode || "",
      firstName: emp.firstName || "",
      lastName: emp.lastName || "",
      gender: emp.gender ? (emp.gender.charAt(0) + emp.gender.slice(1).toLowerCase()) : "",
      dateOfBirth: emp.dob || emp.dateOfBirth || "",
      email: emp.email || "",
      mobile: emp.mobNum || emp.mobile || "",
      bloodGroup: emp.bldGrp || emp.bloodGroup || "",
      address: emp.address || "",
      photoPath: emp.photoUrl || emp.photoPath || "",
      joiningDate: emp.doj || emp.joiningDate || "",
      designation: String(emp.desigId || emp.designation || ""),
      company: String(emp.coyId || emp.company || ""),
      plant: String(emp.pltId || emp.plant || ""),
      department: String(emp.deptId || emp.department || ""),
      workLocation: emp.wloc || emp.wLoc || emp.workLocation || "",
      reportingManager: String(emp.repManId || emp.reportingManager || ""),
      username: emp.email || emp.username || "",
      password: "",
      confirmPassword: "",
      status: emp.status === true || emp.status === "Active" ? "Active" : "Inactive"
    });

    setPhoto(emp.photoUrl && emp.photoUrl.startsWith("data:") ? emp.photoUrl : (emp.photoPath && emp.photoPath.startsWith("data:") ? emp.photoPath : null));
    setIsEditing(true);
    setEditId(emp.empId || emp.id);
    setView("form");
    setActiveActionsMenu(null);
  };

  // Toggle Status Action
  const handleToggleStatus = async (empId) => {
    const emp = employees.find(e => (e.empId || e.id) === empId);
    if (!emp) return;

    const nextStatus = emp.status === "Active" ? false : true;
    const payload = {
      ...emp,
      status: nextStatus
    };

    try {
      const response = await fetch(`${apiBaseUrl}/api/employees/${empId}`, {
        method: "PUT",
        headers: getAuthHeaders(),
        body: JSON.stringify(payload)
      });

      if (response.ok) {
        triggerAlert("success", "Status Update", `Employee is now ${nextStatus ? "Active" : "Inactive"}!`);
        fetchAllData();
      } else {
        triggerAlert("error", "Error", "Failed to toggle employee status.");
      }
    } catch (err) {
      console.error("Error toggling employee status:", err);
      triggerAlert("error", "Error", "Server error occurred while toggling status.");
    }
    setActiveActionsMenu(null);
  };
  const filteredEmployees = employees;

  return (
    <div className="emp-shell-container">
      <Sidebar userRole={userRole} onLogout={onLogout} />

      <div className="emp-shell">
        <Header
          title="Employee Master"
          showSearch={false}
          userName="Syed Mohammad Johny Basha"
          userRole="Web Developer"
          initials="SB"
        />

        <main className="emp-main" style={{ padding: '24px', position: 'relative' }}>

          {view === "form" ? (
            /* ================= VIEW: ADD NEW EMPLOYEE FORM ================= */
            <div className="emp-content" style={{ paddingBottom: '80px', maxWidth: '1280px', margin: '0 auto' }}>

              <div className="emp-form-card" style={{ backgroundColor: 'white', borderRadius: '8px', border: '1px solid #e2e8f0', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '20px 24px', borderBottom: '1px solid #e2e8f0', backgroundColor: '#fafbfc' }}>
                  <h2 style={{ fontSize: '20px', fontWeight: '700', color: '#0f172a', margin: 0 }}>
                    {isEditing ? "Edit Employee" : "Add New Employee"}
                  </h2>
                  <button type="button" className="emp-nav-view-btn" onClick={() => {
                    setView("list"); handleReset(); setIsEditing(false); setEditId(null);
                  }}>
                    <ArrowLeft size={15} /> Back to Employee List
                  </button>
                </div>

                <div style={{ padding: '24px' }}>
                  {/* 1. PERSONAL INFORMATION */}
                  <div className="emp-form-section">
                    <h3 className="emp-form-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>
                      Personal Information
                    </h3>
                    <div className="emp-form-row-4">
                      <div className="emp-form-item">
                        <label>Employee Code <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><User size={16} /></span>
                          <input type="text" name="employeeCode" value={form.employeeCode} onChange={handleChange} placeholder="Enter employee code" maxLength="10" required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>First Name <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><User size={16} /></span>
                          <input type="text" name="firstName" value={form.firstName} onChange={handleChange} placeholder="Enter first name" maxLength="50" required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Last Name <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><User size={16} /></span>
                          <input type="text" name="lastName" value={form.lastName} onChange={handleChange} placeholder="Enter last name" maxLength="50" required />
                        </div>
                      </div>
                    </div>

                    <div className="emp-form-row-4" style={{ marginTop: '16px' }}>
                      <div className="emp-form-item">
                        <label>Gender <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <select name="gender" value={form.gender} onChange={handleChange} required>
                            <option value="">Select gender</option>
                            <option value="Male">Male</option>
                            <option value="Female">Female</option>
                            <option value="Others">Others</option>
                          </select>
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Date of Birth <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Calendar size={16} /></span>
                          <input type="date" name="dateOfBirth" value={form.dateOfBirth} onChange={handleChange} required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Email <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Mail size={16} /></span>
                          <input type="email" name="email" value={form.email} onChange={handleChange} placeholder="Enter email id" maxLength="50" required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Mobile Number <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Phone size={16} /></span>
                          <input type="text" name="mobile" value={form.mobile} onChange={handleChange} placeholder="Enter mobile number" maxLength="10" required />
                        </div>
                      </div>
                    </div>

                    <div className="emp-form-row-4" style={{ marginTop: '16px' }}>
                      <div className="emp-form-item">
                        <label>Blood Group</label>
                        <div className="emp-input-icon-wrap">
                          <select name="bloodGroup" value={form.bloodGroup} onChange={handleChange}>
                            <option value="">Select blood group</option>
                            <option value="A+">A+</option>
                            <option value="A-">A-</option>
                            <option value="B+">B+</option>
                            <option value="B-">B-</option>
                            <option value="AB+">AB+</option>
                            <option value="AB-">AB-</option>
                            <option value="O+">O+</option>
                            <option value="O-">O-</option>
                            <option value="Bombay">Bombay</option>
                            <option value="Rh Null">Rh Null</option>
                          </select>
                        </div>
                      </div>
                    </div>

                    <div className="emp-form-row-2" style={{ marginTop: '16px' }}>
                      <div className="emp-form-item">
                        <label>Address <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon" style={{ alignSelf: "flex-start", marginTop: "14px" }}><MapPin size={16} /></span>
                          <textarea name="address" value={form.address} onChange={handleChange} placeholder="Enter full address" maxLength="255" required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Upload Image</label>
                        {/* PHOTO SECTION – upload button on left, preview on right with equal height to Address textarea and correct alignment */}
                        <div style={{ display: 'flex', alignItems: 'flex-start', gap: '16px', height: '96px' }}>
                          <input id="empPhotoUpload" type="file" accept="image/*" onChange={handlePhotoChange} hidden />
                          <button type="button" className="emp-photo-row-upload-btn" onClick={() => document.getElementById("empPhotoUpload").click()} style={{ padding: '0 16px', background: 'white', border: '1px solid #cbd5e1', borderRadius: '6px', cursor: 'pointer', fontSize: '13px', display: 'inline-flex', alignItems: 'center', gap: '6px', color: '#334155', flexShrink: 0, height: '38px' }}>
                            <Upload size={14} /> Upload File instead
                          </button>
                          <div className="emp-photo-row-preview" style={{ flex: 1, height: '96px', borderRadius: '8px', overflow: 'hidden', border: '1px solid #e2e8f0', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#f8fafc' }}>
                            {form.photoPath || photo ? (
                              <img src={form.photoPath || photo} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                            ) : (
                              <User size={48} style={{ color: '#94a3b8' }} />
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* 2. EMPLOYMENT INFORMATION */}
                  <div className="emp-form-section" style={{ marginTop: '32px' }}>
                    <h3 className="emp-form-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>
                      Employment Information
                    </h3>
                    <div className="emp-form-row-4">
                      <div className="emp-form-item">
                        <label>Joining Date <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Calendar size={16} /></span>
                          <input type="date" name="joiningDate" value={form.joiningDate} onChange={handleChange} required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Designation <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Briefcase size={16} /></span>
                          <input type="text" name="designation" value={form.designation} onChange={handleChange} placeholder="Enter designation" required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Company <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Building size={16} /></span>
                          <select name="company" value={form.company} onChange={handleChange} required>
                            <option value="">Select company</option>
                            {companies.map((coy) => (
                              <option key={coy.coyId || coy.id} value={coy.coyId || coy.id}>{coy.coyNm || coy.name}</option>
                            ))}
                          </select>
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Plant <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Factory size={16} /></span>
                          <select name="plant" value={form.plant} onChange={handleChange} required>
                            <option value="">Select plant</option>
                            {plants.map((plt) => (
                              <option key={plt.pltId || plt.id} value={plt.pltId || plt.id}>{plt.pltNm || plt.name}</option>
                            ))}
                          </select>
                        </div>
                      </div>
                    </div>

                    <div className="emp-form-row-4" style={{ marginTop: '16px' }}>
                      <div className="emp-form-item">
                        <label>Department <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Users size={16} /></span>
                          <select name="department" value={form.department} onChange={handleChange} required>
                            <option value="">Select department</option>
                            {departments.map((dept) => (
                              <option key={dept.deptId || dept.id} value={dept.deptId || dept.id}>{dept.deptNm || dept.name}</option>
                            ))}
                            <option value="CREATE_NEW" style={{ fontWeight: 'bold', color: '#2563eb' }}>
                              + Create Department
                            </option>
                          </select>
                        </div>
                      </div>
                      <div className="emp-form-item emp-span-2">
                        <label>Work Location <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><MapPin size={16} /></span>
                          <input type="text" name="workLocation" value={form.workLocation} onChange={handleChange} placeholder="Enter work location" maxLength="100" required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Reporting Manager <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><User size={16} /></span>
                          <select name="reportingManager" value={form.reportingManager} onChange={handleChange} required>
                            <option value="">Select reporting manager</option>
                            {employees.map((emp) => (
                              <option key={emp.empId || emp.id} value={emp.empId || emp.id}>{emp.employeeName || `${emp.firstName} ${emp.lastName}`}</option>
                            ))}
                          </select>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* 3. LOGIN INFORMATION */}
                  <div className="emp-form-section" style={{ marginTop: '32px' }}>
                    <h3 className="emp-form-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>
                      Login Information
                    </h3>
                    <div className="emp-form-row-3">
                      <div className="emp-form-item">
                        <label>Username (Email) <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Mail size={16} /></span>
                          <input type="email" name="username" value={form.username} onChange={handleChange} placeholder="Enter email id" maxLength="50" required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Password <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Lock size={16} /></span>
                          <input 
                            type={showPassword ? "text" : "password"} 
                            name="password" 
                            value={form.password} 
                            onChange={handleChange} 
                            placeholder="Enter Password" 
                            maxLength="10" 
                            required 
                          />
                          <button type="button" className="emp-input-suffix-btn" onClick={() => setShowPassword(!showPassword)}>
                            {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                          </button>
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Confirm Password <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Lock size={16} /></span>
                          <input 
                            type={showConfirmPassword ? "text" : "password"} 
                            name="confirmPassword" 
                            value={form.confirmPassword} 
                            onChange={handleChange} 
                            placeholder="Confirm password" 
                            maxLength="10" 
                            required 
                          />
                          <button type="button" className="emp-input-suffix-btn" onClick={() => setShowConfirmPassword(!showConfirmPassword)}>
                            {showConfirmPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* 4. STATUS */}
                  <div className="emp-form-section" style={{ marginTop: '32px' }}>
                    <h3 className="emp-form-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>
                      Status
                    </h3>
                    <div className="emp-form-row-4">
                      <div className="emp-form-item">
                        <label>Employee Status <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><CheckCircle2 size={16} /></span>
                          <select name="status" value={form.status} onChange={handleChange} required>
                            <option value="">Select status</option>
                            <option value="Active">Active</option>
                            <option value="Inactive">Inactive</option>
                          </select>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="emp-form-footer" style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', padding: '16px 24px', backgroundColor: '#fafbfc', borderTop: '1px solid #e2e8f0' }}>
                  <button type="button" className="emp-btn secondary" onClick={() => { setView("list"); handleReset(); setIsEditing(false); setEditId(null); }}>
                    Cancel
                  </button>
                  <button type="button" className="emp-btn tertiary" onClick={handleReset}>
                    <RefreshCcw size={14} /> Reset
                  </button>
                  <button type="button" className="emp-btn primary" onClick={handleSave}>
                    <Save size={14} /> {isEditing ? "Update Employee" : "Save Employee"}
                  </button>
                </div>
              </div>
            </div>
          ) : (
            /* ================= VIEW: EMPLOYEE LIST ================= */
            <div className="emp-content" style={{ maxWidth: '1280px', margin: '0 auto' }}>
              <div className="emp-table-panel" style={{ backgroundColor: 'white', borderRadius: '8px', border: '1px solid #e2e8f0', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '20px 24px', borderBottom: '1px solid #e2e8f0' }}>
                  <div>
                    <h2 style={{ fontSize: '18px', fontWeight: '700', color: '#0f172a', margin: 0 }}>Employee List</h2>
                    <p style={{ color: '#64748b', margin: '4px 0 0 0', fontSize: '14px' }}>View and manage all employees</p>
                  </div>
                  <button type="button" className="emp-btn-add-new" onClick={() => { handleReset(); setIsEditing(false); setView("form"); }}>
                    <Plus size={16} /> Add New Employee
                  </button>
                </div>

                <div className="emp-table-container" style={{ overflowX: 'auto' }}>
                  <table className="emp-list-table" style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: '2200px' }}>
                    <thead style={{ backgroundColor: '#f8fafc', borderBottom: '2px solid #e2e8f0' }}>
                      <tr>
                        <th style={{ width: "50px", padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>#</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Employee Code</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Employee Name</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Gender</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Date of Birth</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Email</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Mobile</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Blood Group</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Address</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Joining Date</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Designation</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Company</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Plant</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Department</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Work Location</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Reporting Manager</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Username</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Status</th>
                        <th style={{ textAlign: "center", width: "100px", padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>ACTIONS</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredEmployees.length === 0 ? (
                        <tr><td colSpan="20" style={{ textAlign: "center", padding: "60px 20px", color: '#64748b', fontSize: '14px' }}>No employee records found. Add a new employee using the button above.</td></tr>
                      ) : (
                        filteredEmployees.map((emp, index) => (
                          <tr key={emp.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{index + 1}</td>
                              <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}><span style={{ backgroundColor: '#f1f5f9', padding: '4px 10px', borderRadius: '4px', fontWeight: '600', color: '#0f172a', border: '1px solid #e2e8f0', fontSize: '13px' }}>{emp.employeeCode}</span></td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                {emp.photoPath ? (<img src={emp.photoPath} alt="" style={{ width: '28px', height: '28px', borderRadius: '50%', objectFit: 'cover', border: '1px solid #e2e8f0' }} />) : (<div style={{ width: '28px', height: '28px', borderRadius: '50%', background: '#e2e8f0', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: '600', color: '#475569' }}>{emp.employeeName ? emp.employeeName.charAt(0) : ''}</div>)}
                                <strong>{emp.employeeName}</strong>
                              </div>
                            </td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{emp.gender}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{emp.dateOfBirth}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{emp.email}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{emp.mobile}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{emp.bloodGroup || "-"}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155', maxWidth: '200px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={emp.address}>{emp.address}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{emp.joiningDate}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{emp.designation}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{emp.company}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{emp.plant}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{emp.department}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{emp.workLocation}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{emp.reportingManager}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{emp.username}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>
                              <span style={{ padding: '4px 12px', borderRadius: '12px', fontSize: '12px', fontWeight: '600', display: 'inline-block', backgroundColor: emp.status === 'Active' ? '#dcfce7' : '#fee2e2', color: emp.status === 'Active' ? '#166534' : '#991b1b' }}>{emp.status}</span>
                            </td>
                            <td style={{ position: "relative", padding: '14px 16px', textAlign: 'center' }}>
                              <button type="button" style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#64748b', padding: '4px 8px', borderRadius: '4px' }} onClick={() => setActiveActionsMenu(activeActionsMenu === emp.id ? null : emp.id)} onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f1f5f9'} onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}>
                                <MoreVertical size={18} />
                              </button>
                              {activeActionsMenu === emp.id && (
                                <>
                                  <div className="emp-actions-dropdown-backdrop" onClick={() => setActiveActionsMenu(null)} style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, zIndex: 9 }} />
                                  <div className="emp-actions-dropdown-menu" style={{ position: 'absolute', right: '30px', top: '8px', backgroundColor: 'white', border: '1px solid #e2e8f0', borderRadius: '8px', boxShadow: '0 4px 12px rgba(0,0,0,0.15)', zIndex: 10, display: 'flex', flexDirection: 'column', padding: '4px 0', minWidth: '140px' }}>
                                    <button type="button" style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#334155', borderRadius: '4px', margin: '2px 4px' }} onClick={() => { triggerAlert("info", "Employee Details", `Employee Details:\nName: ${emp.employeeName}\nCode: ${emp.employeeCode}\nDepartment: ${emp.department}\nLocation: ${emp.workLocation || "N/A"}`); setActiveActionsMenu(null); }} onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f1f5f9'} onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}> <Eye size={15} /> View </button>
                                    <button type="button" style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#334155', borderRadius: '4px', margin: '2px 4px' }} onClick={() => handleEdit(emp)} onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f1f5f9'} onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}> <Edit size={15} /> Edit </button>
                                    <button type="button" style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#334155', borderRadius: '4px', margin: '2px 4px' }} onClick={() => { triggerAlert("success", "Saved", `${emp.employeeName}'s record saved successfully.`); setActiveActionsMenu(null); }} onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f1f5f9'} onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}> <Save size={15} /> Save </button>
                                  </div>
                                </>
                              )}
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>

              </div>
            </div>
          )}

          {/* ===================== DEPARTMENT CREATION POPUP MODAL ===================== */}
          {showDeptModal && (
            <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', zIndex: 999, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <div style={{ backgroundColor: 'white', borderRadius: '8px', width: '500px', maxWidth: '95%', boxShadow: '0 10px 25px rgba(0,0,0,0.2)', overflow: 'hidden' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid #e2e8f0', backgroundColor: '#fafbfc' }}>
                  <h3 style={{ margin: 0, fontSize: '16px', fontWeight: '700', color: '#0f172a' }}>Add New Department</h3>
                  <button onClick={() => { setShowDeptModal(false); setForm(p => ({ ...p, department: "" })); }} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#64748b' }}>
                    <X size={18} />
                  </button>
                </div>

                <div style={{ padding: '24px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
                  <div className="emp-form-item">
                    <label>Department Code <span className="emp-req-star">*</span></label>
                    <div className="emp-input-icon-wrap">
                      <span className="emp-input-prefix-icon"><Calendar size={16} /></span>
                      <input type="text" name="code" value={deptForm.code} onChange={handleDeptChange} placeholder="Enter department code" required />
                    </div>
                  </div>
                  <div className="emp-form-item">
                    <label>Department Name <span className="emp-req-star">*</span></label>
                    <div className="emp-input-icon-wrap">
                      <span className="emp-input-prefix-icon"><Building size={16} /></span>
                      <input type="text" name="name" value={deptForm.name} onChange={handleDeptChange} placeholder="Enter department name" required />
                    </div>
                  </div>
                  <div className="emp-form-item">
                    <label>Description</label>
                    <div className="emp-input-icon-wrap">
                      <span className="emp-input-prefix-icon" style={{ alignSelf: "flex-start", marginTop: "14px" }}><FileText size={16} /></span>
                      <textarea name="description" value={deptForm.description} onChange={handleDeptChange} placeholder="Enter description (optional)" rows={3} style={{ height: "80px" }} />
                    </div>
                  </div>
                  <div className="emp-form-item">
                    <label>Status</label>
                    <div className="emp-input-icon-wrap">
                      <select name="status" value={deptForm.status} onChange={handleDeptChange}>
                        <option value="Active">Active</option>
                        <option value="Inactive">Inactive</option>
                      </select>
                    </div>
                  </div>
                </div>

                <div style={{ padding: '16px 24px', borderTop: '1px solid #e2e8f0', display: 'flex', justifyContent: 'flex-end', gap: '12px', backgroundColor: '#fafbfc' }}>
                  <button type="button" onClick={() => { setShowDeptModal(false); setForm(p => ({ ...p, department: "" })); }} style={{ padding: '8px 16px', background: 'white', border: '1px solid #cbd5e1', borderRadius: '6px', color: '#475569', cursor: 'pointer', fontWeight: '500' }}>
                    Cancel
                  </button>
                  <button type="button" onClick={handleSaveNewDepartment} style={{ padding: '8px 16px', background: '#2563eb', color: 'white', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: '500', display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <Save size={14} /> Save Department
                  </button>
                </div>
              </div>
            </div>
          )}
        </main>
      </div>
      <AlertModal
        isOpen={alertConfig.isOpen}
        type={alertConfig.type}
        title={alertConfig.title}
        message={alertConfig.message}
        onClose={() => setAlertConfig(prev => ({ ...prev, isOpen: false }))}
      />
    </div>
  );
};

export default EmployeeCreation;