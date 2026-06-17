import clsx from "clsx";
import Layout from "@theme/Layout";
import Link from "@docusaurus/Link";
import { useEffect, useRef, useState } from "react";
import styles from "./index.module.css";

const features = [
  {
    icon: "⏱",
    title: "Timesheet Recording",
    description:
      "Log hours, track work entries, and maintain clear records across projects and activities.",
    tag: "Core"
  },
  {
    icon: "☑",
    title: "Task Management",
    description:
      "Organize tasks by project, track progress through stages, and manage work from a single view.",
    tag: "Core"
  },
  {
    icon: "📊",
    title: "Dashboard & Charts",
    description:
      "Visual summaries, project timelines, and charts that show where time is actually going.",
    tag: "Analytics"
  },
  {
    icon: "🔄",
    title: "Odoo Sync",
    description:
      "Background daemon syncs with Odoo instances — local data and remote systems stay aligned.",
    tag: "Integration"
  },
  {
    icon: "📱",
    title: "Ubuntu Touch & Desktop",
    description:
      "Convergent design for phones and desktops. One codebase, two form factors.",
    tag: "Platform"
  },
  {
    icon: "🔔",
    title: "Live Notifications",
    description:
      "System-level alerts for project updates, task changes, and sync events.",
    tag: "UX"
  }
];

const techStack = [
  {
    layer: "Interface",
    tech: "QML",
    description:
      "Application UI, pages, shared components, and user interaction layer.",
    path: "qml/"
  },
  {
    layer: "Logic",
    tech: "JavaScript",
    description:
      "Shared state, data models, and cross-feature helper modules.",
    path: "models/"
  },
  {
    layer: "Services",
    tech: "Python",
    description:
      "Backend bridging, daemon process, sync routines, and system integration.",
    path: "src/"
  }
];

const docPaths = [
  {
    audience: "Users",
    description:
      "Installation, setup, sync configuration, and troubleshooting guides.",
    link: "/docs/user/overview",
    cta: "User Docs",
    pages: ["Overview", "Install & Run", "Setup & Sync", "Features", "Troubleshooting"]
  },
  {
    audience: "Contributors",
    description:
      "PR workflow, local development setup, and documentation governance.",
    link: "/docs/contributing/getting-started",
    cta: "Contributing Guide",
    pages: ["Getting Started", "PR Guidelines", "Doc Governance"]
  },
  {
    audience: "Maintainers",
    description:
      "Architecture decisions, repository layout, build system, and release process.",
    link: "/docs/technical/architecture",
    cta: "Technical Docs",
    pages: ["Architecture", "Repo Organization", "Build & Packaging", "Release Process"]
  }
];

function useScrollReveal() {
  const ref = useRef(null);

  useEffect(() => {
    const prefersReduced = window.matchMedia(
      "(prefers-reduced-motion: reduce)"
    ).matches;
    if (prefersReduced) {
      ref.current
        ?.querySelectorAll("[data-reveal]")
        .forEach((el) => el.setAttribute("data-visible", "true"));
      return;
    }

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.setAttribute("data-visible", "true");
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.08, rootMargin: "0px 0px -40px 0px" }
    );

    ref.current
      ?.querySelectorAll("[data-reveal]")
      .forEach((el) => observer.observe(el));

    return () => observer.disconnect();
  }, []);

  return ref;
}

function TerminalPreview() {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    const textToCopy = "git clone https://github.com/CITOpenRep/timemanagement.git\ncd timemanagement\nclickable build && clickable install";
    navigator.clipboard.writeText(textToCopy).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };

  return (
    <div className={styles.terminal}>
      <div className={styles.terminalBar}>
        <div className={styles.terminalDots}>
          <span className={styles.terminalDot} />
          <span className={styles.terminalDot} />
          <span className={styles.terminalDot} />
        </div>
        <button 
          className={styles.copyButton}
          onClick={handleCopy}
          aria-label="Copy code to clipboard"
        >
          {copied ? "Copied!" : "Copy"}
        </button>
      </div>
      <pre className={styles.terminalCode}>
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

export default function Home() {
  const mainRef = useScrollReveal();

  return (
    <Layout
      title="Product & Documentation Hub"
      description="TimeManagement — a practical time, task, and sync workspace for Ubuntu Touch and desktop. Open source, three-layer architecture, community-driven."
    >
      {/* ── HERO ── */}
      <header className={styles.hero}>
        <div className={styles.heroGlow} />
        <div className="container">
          <div className={styles.heroBadge}>
            Open Source · QML + JS + Python
          </div>

          <h1 className={styles.heroTitle}>
            Time
            <span className={styles.heroTitleAccent}>Management</span>
          </h1>

          <p className={styles.heroTagline}>
            A practical workspace for tracking time, managing tasks, and
            syncing with Odoo — built for Ubuntu Touch and desktop.
          </p>

          <div className={styles.heroCtas}>
            <Link className={styles.ctaPrimary} to="/docs/user/overview">
              Get Started
            </Link>
            <Link
              className={styles.ctaSecondary}
              href="https://github.com/CITOpenRep/timemanagement"
            >
              View on GitHub →
            </Link>
          </div>

          <TerminalPreview />
        </div>
      </header>

      {/* ── MAIN CONTENT ── */}
      <main ref={mainRef}>
        {/* ── FEATURES ── */}
        <section className={clsx(styles.section, styles.sectionLight)}>
          <div className="container">
            <div data-reveal>
              <p className={styles.sectionLabel}>Capabilities</p>
              <h2
                className={clsx(styles.sectionTitle, styles.sectionTitleLight)}
              >
                Everything you need to track work and stay organized
              </h2>
            </div>
            <div className={styles.featureGrid} data-reveal style={{ "--reveal-delay": 1 }}>
              {features.map((f) => (
                <article key={f.title} className={styles.featureCard}>
                  <div className={styles.featureCardHeader}>
                    <span className={styles.featureIcon}>{f.icon}</span>
                    <span className={styles.featureTag}>{f.tag}</span>
                  </div>
                  <h3>{f.title}</h3>
                  <p>{f.description}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        {/* ── ARCHITECTURE ── */}
        <section className={clsx(styles.section, styles.sectionDark)}>
          <div className="container">
            <div data-reveal>
              <p className={styles.sectionLabel}>Architecture</p>
              <h2
                className={clsx(styles.sectionTitle, styles.sectionTitleDark)}
              >
                Three layers, one coherent system
              </h2>
            </div>
            <div className={styles.stackDiagram}>
              {techStack.map((layer, i) => (
                <div
                  key={layer.tech}
                  className={styles.stackLayer}
                  data-reveal
                  style={{ "--reveal-delay": i + 1 }}
                >
                  <div className={styles.layerHeader}>
                    <span className={styles.layerLabel}>{layer.layer}</span>
                    <span className={styles.layerTech}>{layer.tech}</span>
                  </div>
                  <p>{layer.description}</p>
                  <code className={styles.layerPath}>{layer.path}</code>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ── DOCUMENTATION ── */}
        <section className={clsx(styles.section, styles.sectionLight)}>
          <div className="container">
            <div data-reveal>
              <p className={styles.sectionLabel}>Documentation</p>
              <h2
                className={clsx(styles.sectionTitle, styles.sectionTitleLight)}
              >
                Start from the track that matches your role
              </h2>
            </div>
            <div className={styles.docGrid}>
              {docPaths.map((doc, i) => (
                <article
                  key={doc.audience}
                  className={styles.docCard}
                  data-reveal
                  style={{ "--reveal-delay": i + 1 }}
                >
                  <h3>{doc.audience}</h3>
                  <p>{doc.description}</p>
                  <ul className={styles.docPageList}>
                    {doc.pages.map((page) => (
                      <li key={page}>{page}</li>
                    ))}
                  </ul>
                  <Link className={styles.docLink} to={doc.link}>
                    {doc.cta} <span aria-hidden="true">→</span>
                  </Link>
                </article>
              ))}
            </div>
          </div>
        </section>

        {/* ── OPEN SOURCE CTA ── */}
        <section className={clsx(styles.section, styles.sectionDark)}>
          <div className="container">
            <div className={styles.ossCta} data-reveal>
              <h2>Built in the open</h2>
              <p>
                TimeManagement is open source. Browse the code, report issues,
                or contribute directly on GitHub.
              </p>
              <div className={styles.ossLinks}>
                <Link
                  className={styles.ctaPrimary}
                  href="https://github.com/CITOpenRep/timemanagement"
                >
                  View Repository
                </Link>
                <Link
                  className={styles.ctaSecondary}
                  href="https://github.com/CITOpenRep/timemanagement/issues"
                >
                  Report an Issue →
                </Link>
              </div>
            </div>
          </div>
        </section>
      </main>
    </Layout>
  );
}
