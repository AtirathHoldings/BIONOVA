import React, { useState } from "react";
import Sidebar from "../Sidebar";
import Header from "../Header";
import { 
  User, 
  Camera, 
  ShieldCheck, 
  EyeOff, 
  Eye, 
  Lock,
  ChevronRight,
  Home,
  IdCard,
  Mail,
  Phone,
  Building,
  MapPin,
  Calendar,
  Clock
} from "lucide-react";
import "../../styles/profile.css";

const Profile = ({ userRole, onLogout }) => {
  const [showCurrentPassword, setShowCurrentPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  // Hardcoded based on the screenshot
  const profileDetails = {
    employeeCode: "EMP00125",
    employeeName: "Ravi Kumar",
    email: "ravi.kumar@cpgp.com",
    mobileNumber: "+91 98765 43210",
    department: "Engineering",
    role: "Engineer",
    reportingManager: "Suresh Babu (Project Manager)",
    workLocation: "Hyderabad, India",
    dateOfJoining: "15 Jan 2024",
    status: "Active"
  };

  return (
    <div className="pf-shell-container">
      <Sidebar userRole={userRole} onLogout={onLogout} />

      <div className="pf-shell">
        <Header 
          title="" 
          showSearch={false} 
          userName="Ravi Kumar" 
          userRole="Engineer" 
          initials="RK" 
        />

        <main className="pf-main">
          <h1 style={{ fontSize: '24px', fontWeight: '700', color: '#0f172a', margin: '0 0 8px 0' }}>
            My Profile
          </h1>
          
          <div className="pf-breadcrumb">
            <Home size={14} />
            <span>Home</span>
            <ChevronRight size={14} />
            <strong style={{ color: '#0f172a', fontWeight: '500' }}>Profile</strong>
          </div>

          <div className="pf-content">
            
            {/* Left Card: Profile Information */}
            <div className="pf-card pf-profile-card">
              <div className="pf-card-header">
                <User className="pf-card-icon" size={24} />
                <div className="pf-card-title-wrap">
                  <h2>Profile Information</h2>
                  <p>View your personal and professional details</p>
                </div>
              </div>

              <div className="pf-info-layout">
                {/* Avatar Section */}
                <div className="pf-avatar-section">
                  <div className="pf-avatar-wrapper">
                    <img 
                      src="https://images.unsplash.com/photo-1633332755192-727a05c4013d?q=80&w=250&auto=format&fit=crop" 
                      alt="Profile Avatar" 
                      className="pf-avatar-image" 
                    />
                  </div>
                  <button className="pf-change-photo-btn">
                    <Camera size={16} />
                    Change Photo
                  </button>
                  <span className="pf-avatar-hint">JPG, PNG or GIF. Max size of 2MB</span>
                </div>

                {/* Details List */}
                <div className="pf-details-list">
                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <IdCard size={16} />
                      Employee Code
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">{profileDetails.employeeCode}</div>
                  </div>

                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <User size={16} />
                      Employee Name
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">{profileDetails.employeeName}</div>
                  </div>

                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <Mail size={16} />
                      Email
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">{profileDetails.email}</div>
                  </div>

                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <Phone size={16} />
                      Mobile Number
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">{profileDetails.mobileNumber}</div>
                  </div>

                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <Building size={16} />
                      Department
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">{profileDetails.department}</div>
                  </div>

                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <ShieldCheck size={16} />
                      Role
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">{profileDetails.role}</div>
                  </div>

                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <User size={16} />
                      Reporting Manager
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">{profileDetails.reportingManager}</div>
                  </div>

                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <MapPin size={16} />
                      Work Location
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">{profileDetails.workLocation}</div>
                  </div>

                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <Calendar size={16} />
                      Date of Joining
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">{profileDetails.dateOfJoining}</div>
                  </div>

                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <Clock size={16} />
                      Status
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">
                      <span className="pf-status-badge">
                        <span className="pf-status-dot"></span>
                        {profileDetails.status}
                      </span>
                    </div>
                  </div>

                </div>
              </div>
            </div>

            {/* Right Card: Account & Security */}
            <div className="pf-card pf-security-card">
              <div className="pf-card-header">
                <ShieldCheck className="pf-card-icon" size={24} />
                <div className="pf-card-title-wrap">
                  <h2>Account & Security</h2>
                  <p>Update your account password</p>
                </div>
              </div>

              <div className="pf-security-form">
                <div className="pf-form-group">
                  <label>Current Password <span>*</span></label>
                  <div className="pf-input-wrapper">
                    <input 
                      type={showCurrentPassword ? "text" : "password"} 
                      placeholder="Enter current password" 
                    />
                    {showCurrentPassword ? (
                      <Eye className="pf-input-icon" size={18} onClick={() => setShowCurrentPassword(false)} />
                    ) : (
                      <EyeOff className="pf-input-icon" size={18} onClick={() => setShowCurrentPassword(true)} />
                    )}
                  </div>
                </div>

                <div className="pf-form-group">
                  <label>New Password <span>*</span></label>
                  <div className="pf-input-wrapper">
                    <input 
                      type={showNewPassword ? "text" : "password"} 
                      placeholder="Enter new password" 
                    />
                    {showNewPassword ? (
                      <Eye className="pf-input-icon" size={18} onClick={() => setShowNewPassword(false)} />
                    ) : (
                      <EyeOff className="pf-input-icon" size={18} onClick={() => setShowNewPassword(true)} />
                    )}
                  </div>
                  <p className="pf-password-hint">
                    Password must be at least 8 characters long and include uppercase, lowercase, number and special character.
                  </p>
                </div>

                <div className="pf-form-group">
                  <label>Confirm New Password <span>*</span></label>
                  <div className="pf-input-wrapper">
                    <input 
                      type={showConfirmPassword ? "text" : "password"} 
                      placeholder="Confirm new password" 
                    />
                    {showConfirmPassword ? (
                      <Eye className="pf-input-icon" size={18} onClick={() => setShowConfirmPassword(false)} />
                    ) : (
                      <EyeOff className="pf-input-icon" size={18} onClick={() => setShowConfirmPassword(true)} />
                    )}
                  </div>
                </div>

                <button className="pf-update-btn">
                  <Lock size={16} />
                  Update Password
                </button>
              </div>

            </div>
          </div>
        </main>
      </div>
    </div>
  );
};

export default Profile;
