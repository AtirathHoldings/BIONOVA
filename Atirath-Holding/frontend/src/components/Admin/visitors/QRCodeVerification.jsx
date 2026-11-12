import React, { useState } from "react";
import {
  QrCode,
  Sparkles,
  ShieldCheck,
  CheckCircle2,
  Bell,
  Cpu,
  Layers,
  Lock,
  Wifi,
  ScanLine
} from "lucide-react";

const QRCodeVerification = ({ onNavigate }) => {
  const [isSubscribed, setIsSubscribed] = useState(false);
  const [emailInput, setEmailInput] = useState("");

  const handleSubscribe = (e) => {
    e.preventDefault();
    if (!emailInput) return;
    setIsSubscribed(true);
  };

  return (
    <div className="vm-submodule-container">
      {/* Feature Coming Soon Hero Section */}
      <div className="vm-coming-soon-card">
        <div className="vm-coming-soon-badge">
          <Sparkles size={14} className="text-amber-400" />
          <span>Next-Generation Hardware Integration</span>
        </div>

        <div className="vm-qr-scanner-mockup">
          <div className="vm-qr-viewfinder">
            <ScanLine size={48} className="vm-scan-line-anim" />
            <QrCode size={110} className="vm-qr-icon-center" />
            <div className="vm-corner top-left"></div>
            <div className="vm-corner top-right"></div>
            <div className="vm-corner bottom-left"></div>
            <div className="vm-corner bottom-right"></div>
          </div>
        </div>

        <h1 className="vm-coming-soon-title">
          Contactless QR Code & Smart Turnstile Gate Pass Verification
        </h1>

        <div className="vm-coming-soon-pill">
          🚀 COMING SOON — BioNova Smart Gate System v2.4
        </div>

        <p className="vm-coming-soon-desc">
          We are engineering automated hardware integration with high-speed optical barcode scanners and tripod turnstile gates. 
          Visitors will be able to present dynamic OTP QR passes on their smartphones for sub-second contactless verification.
        </p>

        {/* Planned Features Grid */}
        <div className="vm-upcoming-grid">
          <div className="vm-upcoming-card">
            <div className="vm-upcoming-icon" style={{ backgroundColor: "#dbeafe", color: "#2563eb" }}>
              <QrCode size={22} />
            </div>
            <h4>Dynamic Rotating QR Passes</h4>
            <p>Time-based cryptographic QR codes refreshed every 30 seconds to prevent pass duplication and sharing.</p>
          </div>

          <div className="vm-upcoming-card">
            <div className="vm-upcoming-icon" style={{ backgroundColor: "#d1fae5", color: "#059669" }}>
              <Lock size={22} />
            </div>
            <h4>Anti-Passback Enforcement</h4>
            <p>Smart turnstile interlocks prevent multiple entries with the same pass until a verified exit is stamped.</p>
          </div>

          <div className="vm-upcoming-card">
            <div className="vm-upcoming-icon" style={{ backgroundColor: "#fef3c7", color: "#d97706" }}>
              <Cpu size={22} />
            </div>
            <h4>Tripod & Flap Barrier SDK</h4>
            <p>Direct Ethernet / RS-485 controller integration with Hikvision, ZKTeco, and Honeywell perimeter hardware.</p>
          </div>

          <div className="vm-upcoming-card">
            <div className="vm-upcoming-icon" style={{ backgroundColor: "#f3e8ff", color: "#7c3aed" }}>
              <Wifi size={22} />
            </div>
            <h4>Offline Edge Gate Buffer</h4>
            <p>Local Raspberry Pi gate controllers preserve turnstile operations even during plant network dropouts.</p>
          </div>
        </div>

        {/* Notification Subscription */}
        <div className="vm-notify-box">
          {isSubscribed ? (
            <div className="d-flex align-items-center justify-content-center gap-2 text-emerald-800 font-semibold text-sm">
              <CheckCircle2 size={18} className="text-emerald-600" />
              Thank you! You will be notified the moment QR Turnstile Verification launches.
            </div>
          ) : (
            <form onSubmit={handleSubscribe} className="d-flex flex-wrap gap-2 justify-content-center">
              <input
                type="email"
                placeholder="Enter work email for early access preview..."
                value={emailInput}
                onChange={(e) => setEmailInput(e.target.value)}
                className="vm-input-text"
                style={{ maxWidth: "340px" }}
                required
              />
              <button type="submit" className="vm-btn-primary text-xs">
                <Bell size={14} /> Notify Me on Release
              </button>
            </form>
          )}
        </div>

        <div className="mt-4 pt-3 border-t border-slate-200">
          <button onClick={() => onNavigate("dashboard")} className="vm-btn-secondary text-xs">
            ← Return to Visitor Dashboard
          </button>
        </div>
      </div>
    </div>
  );
};

export default QRCodeVerification;

