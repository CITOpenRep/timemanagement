import clsx from "clsx";
import Layout from "@theme/Layout";
import Link from "@docusaurus/Link";
import styles from "./index.module.css";

const productHighlights = [
  {
    title: "Track work clearly",
    description:
      "Log timesheets, manage tasks, and keep day-to-day work visible from one app experience."
  },
  {
    title: "Bridge UI and backend",
    description:
      "The project combines QML, JavaScript models, and Python services to support desktop and Ubuntu Touch workflows."
  },
  {
    title: "Ship with confidence",
    description:
      "Keep functional docs, technical docs, and contributor guidance together so releases stay understandable."
  }
];

const audienceCards = [
  {
    title: "For users",
    description:
      "Start with installation, setup, sync, and troubleshooting guides.",
    link: "/docs/user/overview",
    cta: "Explore user docs"
  },
  {
    title: "For maintainers",
    description:
      "Understand architecture, repository layout, packaging, and release responsibilities.",
    link: "/docs/technical/architecture",
    cta: "Open technical docs"
  },
  {
    title: "For contributors",
    description:
      "Follow the PR workflow, local setup guidance, and documentation governance rules.",
    link: "/docs/contributing/getting-started",
    cta: "Read contributing docs"
  }
];

const featureList = [
  "Timesheet recording and work logging",
  "Task and project-oriented workflows",
  "Odoo sync support and backend services",
  "Desktop and Ubuntu Touch packaging workflow"
];

export default function Home() {
  return (
    <Layout
      title="Product and Documentation Hub"
      description="TimeManagement product website and documentation portal"
    >
      <header className={styles.hero}>
        <div className="container">
          <div className={styles.heroGrid}>
            <div>
              <p className={styles.kicker}>Product website + documentation hub</p>
              <h1 className={styles.heroTitle}>
                TimeManagement brings product guidance and project knowledge into one place.
              </h1>
              <p className={styles.heroText}>
                Use this site to understand what the app does, how to install it, how syncing works,
                and how to contribute without digging through the repository first.
              </p>
              <div className={styles.heroActions}>
                <Link className="button button--primary button--lg" to="/docs/user/overview">
                  Read the docs
                </Link>
                <Link className="button button--secondary button--lg" to="/docs/technical/architecture">
                  View architecture
                </Link>
              </div>
            </div>
            <div className={styles.heroPanel}>
              <img className={styles.heroLogo} src="/timemanagement/img/logo.png" alt="TimeManagement logo" />
              <h2>Supported audiences</h2>
              <ul className={styles.panelList}>
                <li>End users and product stakeholders</li>
                <li>Developers and maintainers</li>
                <li>Contributors and reviewers</li>
              </ul>
            </div>
          </div>
        </div>
      </header>

      <main>
        <section className={styles.section}>
          <div className="container">
            <div className={styles.sectionHeading}>
              <p className={styles.eyebrow}>Why this site exists</p>
              <h2>One place for product story, usage guidance, and engineering context.</h2>
            </div>
            <div className={styles.cardGrid}>
              {productHighlights.map((item) => (
                <article key={item.title} className={styles.card}>
                  <h3>{item.title}</h3>
                  <p>{item.description}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section className={clsx(styles.section, styles.sectionAlt)}>
          <div className="container">
            <div className={styles.sectionHeading}>
              <p className={styles.eyebrow}>Documentation paths</p>
              <h2>Start from the track that matches your role.</h2>
            </div>
            <div className={styles.cardGrid}>
              {audienceCards.map((card) => (
                <article key={card.title} className={styles.card}>
                  <h3>{card.title}</h3>
                  <p>{card.description}</p>
                  <Link className={styles.inlineLink} to={card.link}>
                    {card.cta}
                  </Link>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section className={styles.section}>
          <div className="container">
            <div className={styles.splitSection}>
              <div>
                <p className={styles.eyebrow}>Core capabilities</p>
                <h2>Built for active work management and sync-heavy workflows.</h2>
                <ul className={styles.featureList}>
                  {featureList.map((feature) => (
                    <li key={feature}>{feature}</li>
                  ))}
                </ul>
              </div>
              <div className={styles.visualCard}>
                <img src="/timemanagement/img/logo-mark.png" alt="TimeManagement brand mark" />
                <p>
                  The first release of this site focuses on clarity: installation, setup, structure,
                  release process, and contributor guidance.
                </p>
              </div>
            </div>
          </div>
        </section>
      </main>
    </Layout>
  );
}
