import React, { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { publicApi, authService } from "../apiService";

const Hero = () => {
  const isAuthenticated = authService.isAuthenticated();
  const currentUser = authService.getCurrentUser();

  return (
    <section
      className="card"
      style={{
        borderRadius: 0,
        padding: 48,
        marginBottom: 24,
        background:
          "linear-gradient(135deg, rgba(248,246,241,1) 0%, rgba(238,245,229,1) 100%)",
      }}
    >
      <div
        className="container"
        style={{
          display: "flex",
          alignItems: "center",
          gap: 40,
          flexWrap: "wrap",
        }}
      >
        <div style={{ flex: "1 1 420px" }}>
          <h1>CollabSphere — Build together, faster</h1>
          <p style={{ fontSize: "1.125rem", color: "var(--text-medium)" }}>
            Discover community projects, find collaborators, and secure funding
            — all in one place. Join thousands of creators and researchers
            building solutions for real-world problems.
          </p>
          <div style={{ marginTop: 16 }} className="btn-group">
            {isAuthenticated ? (
              <>
                <Link to="/dashboard" className="btn btn-primary">
                  Go to Dashboard
                </Link>
                <Link to="/projects" className="btn btn-outline">
                  Browse Projects
                </Link>
              </>
            ) : (
              <>
                <a
                  href="https://web06.cs.ait.ac.th/app/"
                  className="btn btn-primary"
                >
                  Login
                </a>
              </>
            )}
          </div>
        </div>
        <div style={{ flex: "1 1 360px" }}>
          <div
            style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}
          >
            <div className="card" style={{ padding: 14 }}>
              <strong>145+</strong>
              <div className="text-muted">Active projects</div>
            </div>
            <div className="card" style={{ padding: 14 }}>
              <strong>150+</strong>
              <div className="text-muted">Active contributors</div>
            </div>
            <div className="card" style={{ padding: 14 }}>
              <strong>$2.4M</strong>
              <div className="text-muted">Funding raised</div>
            </div>
            <div className="card" style={{ padding: 14 }}>
              <strong>160+</strong>
              <div className="text-muted">Tags & Topics</div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

const ProjectCard = ({ project }) => (
  <div className="project-card">
    <div className="project-title">{project.title}</div>
    <div className="project-description">
      {project.description?.slice(0, 140)}
      {project.description && project.description.length > 140 ? "..." : ""}
    </div>
    <div className="project-meta">
      <div className="text-muted">
        By {project.owner_name || project.owner?.full_name || "Unknown"}
      </div>
      <div>
        <span
          className={`badge ${
            project.status === "Completed" ? "badge-primary" : ""
          }`}
        >
          {project.status}
        </span>
      </div>
    </div>
  </div>
);

const HomePage = () => {
  const [projects, setProjects] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let mounted = true;
    const fetch = async () => {
      try {
        // Use publicApi (no 401 redirect) for public homepage listing. If the backend
        // requires auth for projects index, this will return 401 but won't redirect.
        const res = await publicApi.get("/api/v1/projects", {
          params: { page: 1, per_page: 6 },
        });
        const data = res?.data?.data ?? res?.data ?? [];
        if (mounted) setProjects(data || []);
      } catch (e) {
        // If backend rejects anonymous requests, we don't force navigation.
        console.debug(
          "HomePage: public projects fetch failed",
          e?.response?.status
        );
        if (mounted) setProjects([]);
      } finally {
        if (mounted) setLoading(false);
      }
    };
    fetch();
    return () => {
      mounted = false;
    };
  }, []);

  return (
    <div>
      <Hero />
      <div className="container">
        <div className="card">
          <h2 className="mb-2">Featured Projects</h2>
          <p className="text-muted">
            Explore a curated selection of public projects — join, contribute or
            fund what excites you.
          </p>
          {loading ? (
            <div className="loading">
              <div className="spinner" />
            </div>
          ) : (
            <div className="project-grid">
              {projects.length ? (
                projects.map((p) => (
                  <Link
                    key={p.id}
                    to={`/projects/${p.id}`}
                    style={{ textDecoration: "none" }}
                  >
                    <ProjectCard
                      project={{ ...p, owner_name: p.owner?.full_name }}
                    />
                  </Link>
                ))
              ) : (
                <div className="text-center">No projects available.</div>
              )}
            </div>
          )}
        </div>

        <div className="divider" />

        <div className="card">
          <h3>How it works</h3>
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
              gap: 16,
            }}
          >
            <div className="card" style={{ padding: 18 }}>
              <h4>Discover</h4>
              <p className="text-muted">
                Find public projects across research, social impact, and
                startups.
              </p>
            </div>
            <div className="card" style={{ padding: 18 }}>
              <h4>Collaborate</h4>
              <p className="text-muted">
                Join other contributors, manage tasks and share resources.
              </p>
            </div>
            <div className="card" style={{ padding: 18 }}>
              <h4>Fund</h4>
              <p className="text-muted">
                Support projects you believe in directly through micro-funding.
              </p>
            </div>
          </div>
        </div>

        <div className="divider" />

        {/* Download Mobile App Section */}
        <div
          className="card"
          style={{
            background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
            color: "white",
            textAlign: "center",
            padding: "48px 24px",
          }}
        >
          <h2 style={{ color: "white", marginBottom: 16 }}>
            Get the Mobile App
          </h2>
          <p
            style={{
              fontSize: "1.125rem",
              opacity: 0.95,
              marginBottom: 24,
              maxWidth: 600,
              margin: "0 auto 24px",
            }}
          >
            Take CollabSphere with you. Download our mobile app to discover
            projects, collaborate, and manage your work on the go.
          </p>
          <a
            href={(() => {
              const userAgent =
                navigator.userAgent || navigator.vendor || window.opera;
              const isAndroid = /android/i.test(userAgent);
              return isAndroid
                ? "https://play.google.com/store/apps/details?id=com.collabsphere.app"
                : "https://play.google.com/apps/testing/com.collabsphere.app";
            })()}
            className="btn"
            style={{
              backgroundColor: "white",
              color: "#667eea",
              fontWeight: 600,
              padding: "12px 32px",
              fontSize: "1.125rem",
              border: "none",
              textDecoration: "none",
              display: "inline-block",
              borderRadius: 8,
              boxShadow: "0 4px 12px rgba(0,0,0,0.15)",
            }}
          >
            📱 Download App
          </a>
        </div>

        <div className="divider" />

        {/* Beta Testing Signup Section */}
        <BetaTestingSignup />
      </div>
    </div>
  );
};

const BetaTestingSignup = () => {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!email || !email.includes("@")) {
      setStatus("Please enter a valid email address");
      return;
    }

    setLoading(true);
    setStatus("");

    try {
      // Simulate API call - replace with actual endpoint when available
      await new Promise((resolve) => setTimeout(resolve, 1000));
      setStatus("✓ Thank you! You've been added to our beta testing list.");
      setEmail("");
    } catch (error) {
      setStatus("Something went wrong. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      className="card"
      style={{
        background:
          "linear-gradient(135deg, rgba(52, 211, 153, 0.1) 0%, rgba(16, 185, 129, 0.1) 100%)",
        border: "2px solid #34d399",
        textAlign: "center",
        padding: "48px 24px",
      }}
    >
      <h2 style={{ marginBottom: 16 }}>Join Our Open Beta Testing</h2>
      <p
        style={{
          fontSize: "1.125rem",
          color: "var(--text-medium)",
          marginBottom: 24,
          maxWidth: 600,
          margin: "0 auto 24px",
        }}
      >
        Be among the first to test new features and help shape the future of
        CollabSphere. Sign up for early access to our mobile app beta program.
      </p>
      <form onSubmit={handleSubmit} style={{ maxWidth: 480, margin: "0 auto" }}>
        <div
          style={{
            display: "flex",
            gap: 12,
            flexWrap: "wrap",
            justifyContent: "center",
          }}
        >
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="Enter your email address"
            className="input"
            style={{
              flex: "1 1 280px",
              padding: "12px 16px",
              fontSize: "1rem",
              border: "2px solid #34d399",
              borderRadius: 8,
            }}
            disabled={loading}
          />
          <button
            type="submit"
            className="btn btn-primary"
            style={{
              padding: "12px 32px",
              fontSize: "1rem",
              fontWeight: 600,
              backgroundColor: "#34d399",
              borderColor: "#34d399",
              minWidth: 140,
            }}
            disabled={loading}
          >
            {loading ? "Joining..." : "Join Beta"}
          </button>
        </div>
        {status && (
          <p
            style={{
              marginTop: 16,
              fontSize: "0.95rem",
              color: status.startsWith("✓") ? "#10b981" : "#ef4444",
              fontWeight: 500,
            }}
          >
            {status}
          </p>
        )}
      </form>
    </div>
  );
};

export default HomePage;
