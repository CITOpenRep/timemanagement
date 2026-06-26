import React, { useState } from "react";
import styles from "../pages/index.module.css";

export function TerminalPreview() {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText("clickable build && clickable install");
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className={styles.terminalBox} data-reveal style={{ "--reveal-delay": 1.5 }}>
      <div className={styles.terminalHeader}>
        <div className={styles.terminalDots}>
          <span></span>
          <span></span>
          <span></span>
        </div>
        <button 
          onClick={handleCopy}
          className={styles.copyBtn}
          title="Copy command to clipboard"
        >
          {copied ? "copied!" : "copy"}
        </button>
      </div>
      <pre className={styles.terminalContent}>
        <span className={styles.terminalPrompt}>$ </span>
        <span className={styles.terminalCmd}>git clone https://github.com/CITOpenRep/timemanagement.git</span>
        {"\n"}
        <span className={styles.terminalPrompt}>$ </span>
        <span className={styles.terminalCmd}>cd timemanagement</span>
        {"\n"}
        <span className={styles.terminalPrompt}>$ </span>
        <span className={styles.terminalCmd}>clickable build && clickable install</span>
      </pre>
    </div>
  );
}
export default TerminalPreview;
