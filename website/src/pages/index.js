import React from "react";
import clsx from "clsx";
import Layout from "@theme/Layout";
import Link from "@docusaurus/Link";
import styles from "./index.module.css";
import { useScrollReveal } from "../hooks/useScrollReveal";
import { features, techStack, docPaths } from "../data/landingData";
import { TerminalPreview } from "../components/TerminalPreview";
import { DeviceSimulator } from "../components/DeviceSimulator";

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

        {/* ── INTERACTIVE MOBILE MODEL ── */}
        <DeviceSimulator />

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
