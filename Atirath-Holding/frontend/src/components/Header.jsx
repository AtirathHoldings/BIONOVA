import React from "react";
import { Menu, Search, Bell } from "lucide-react";

const Header = ({ title, showSearch = false, userName = "User", userRole = "Role", initials = "U" }) => {
  return (
    <header style={{
      display: "flex", 
      justifyContent: "space-between", 
      alignItems: "center",
      padding: "16px 28px", 
      background: "white", 
      borderBottom: "1px solid #e2e8f0",
      position: "sticky", 
      top: 0, 
      zIndex: 10
    }}>
      {/* Left Side: Menu Toggle & Title */}
      <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
        
        <h1 style={{ margin: 0, fontSize: "20px", color: "#1e293b", fontWeight: "700" }}>
          {title}
        </h1>
      </div>
      
      {/* Right Side: Search, Notifications & User Info */}
      <div style={{ display: "flex", alignItems: "center", gap: "24px" }}>
        
       
        
        <div style={{ display: "flex", alignItems: "center", gap: "12px", borderLeft: "2px solid #e2e8f0", paddingLeft: "24px" }}>
          <div style={{ 
            width: "38px", height: "38px", borderRadius: "50%", background: "#2563eb", 
            color: "white", display: "flex", alignItems: "center", justifyContent: "center", 
            fontWeight: "bold", fontSize: "14px", letterSpacing: "1px" 
          }}>
            {initials}
          </div>
          <div style={{ display: "flex", flexDirection: "column" }}>
            <strong style={{ fontSize: "14px", color: "#1e293b" }}>{userName}</strong>
            <small style={{ fontSize: "12px", color: "#64748b", fontWeight: "500" }}>{userRole}</small>
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;