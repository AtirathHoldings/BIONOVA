import React, { useState } from "react";
import { Copy, Check, Lock, Sparkles, AlertCircle } from "lucide-react";

export default function SkuPreviewCard({
  sku,
  format,
  isValid = true,
  missingFields = [],
  chips = [],
  categoryName = "Inventory Item"
}) {
  const [copied, setCopied] = useState(false);

  const handleCopy = (e) => {
    e.preventDefault();
    if (!sku) return;
    navigator.clipboard.writeText(sku);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div
      style={{
        background: "linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%)",
        border: isValid ? "1.5px solid #cbd5e1" : "1.5px solid #f59e0b",
        borderRadius: "12px",
        padding: "16px 20px",
        marginBottom: "22px",
        boxShadow: "0 2px 4px rgba(0, 0, 0, 0.04)",
        position: "relative"
      }}
    >
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "10px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
          <span
            style={{
              display: "inline-flex",
              alignItems: "center",
              gap: "5px",
              fontSize: "11.5px",
              fontWeight: "700",
              letterSpacing: "0.5px",
              textTransform: "uppercase",
              padding: "3px 10px",
              borderRadius: "20px",
              backgroundColor: isValid ? "#ecfdf5" : "#fffbeb",
              color: isValid ? "#059669" : "#d97706",
              border: isValid ? "1px solid #a7f3d0" : "1px solid #fde68a"
            }}
          >
            <span
              style={{
                width: "7px",
                height: "7px",
                borderRadius: "50%",
                backgroundColor: isValid ? "#10b981" : "#f59e0b",
                display: "inline-block"
              }}
            />
            {isValid ? "Real-Time System Generated SKU" : "SKU Preview (Pending Selections)"}
          </span>
          <span style={{ fontSize: "12px", color: "#64748b", display: "flex", alignItems: "center", gap: "4px" }}>
            <Lock size={12} /> Read-Only
          </span>
        </div>

        <button
          type="button"
          onClick={handleCopy}
          title="Copy SKU code to clipboard"
          style={{
            display: "inline-flex",
            alignItems: "center",
            gap: "6px",
            padding: "5px 12px",
            borderRadius: "6px",
            backgroundColor: copied ? "#059669" : "#ffffff",
            color: copied ? "#ffffff" : "#334155",
            border: "1px solid #cbd5e1",
            fontSize: "12px",
            fontWeight: "600",
            cursor: "pointer",
            transition: "all 0.2s ease"
          }}
        >
          {copied ? <Check size={14} /> : <Copy size={14} />}
          {copied ? "Copied!" : "Copy SKU"}
        </button>
      </div>

      <div style={{ display: "flex", alignItems: "baseline", gap: "14px", flexWrap: "wrap", marginBottom: "10px" }}>
        <div
          style={{
            fontFamily: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace",
            fontSize: "20px",
            fontWeight: "800",
            letterSpacing: "1px",
            color: isValid ? "#0f172a" : "#b45309",
            backgroundColor: "#ffffff",
            padding: "8px 16px",
            borderRadius: "8px",
            border: "1.5px dashed #94a3b8",
            display: "inline-block"
          }}
        >
          {sku || "GENERATING..."}
        </div>
        <div style={{ fontSize: "12px", color: "#64748b" }}>
          Template: <code style={{ backgroundColor: "#e2e8f0", padding: "2px 6px", borderRadius: "4px", fontSize: "11.5px" }}>{format}</code>
        </div>
      </div>

      {/* Specifications Breakdown Chips */}
      {chips && chips.length > 0 && (
        <div style={{ display: "flex", flexWrap: "wrap", gap: "8px", marginTop: "8px" }}>
          {chips.map((c, i) => (
            <span
              key={i}
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: "5px",
                fontSize: "11.5px",
                padding: "3px 9px",
                borderRadius: "6px",
                backgroundColor: "#ffffff",
                border: "1px solid #e2e8f0",
                color: "#475569"
              }}
            >
              <strong style={{ color: "#1e293b" }}>{c.label}:</strong>
              <span style={{ color: "#0284c7", fontWeight: "600" }}>{c.value}</span>
            </span>
          ))}
        </div>
      )}

      {/* Missing specifications notice */}
      {!isValid && missingFields && missingFields.length > 0 && (
        <div
          style={{
            marginTop: "10px",
            display: "flex",
            alignItems: "center",
            gap: "8px",
            fontSize: "12px",
            color: "#b45309",
            backgroundColor: "#fffbeb",
            padding: "6px 12px",
            borderRadius: "6px",
            border: "1px solid #fef3c7"
          }}
        >
          <AlertCircle size={15} />
          <span>
            Please complete required selections: <strong>{missingFields.join(", ")}</strong> to finalize the SKU sequence.
          </span>
        </div>
      )}
    </div>
  );
}
