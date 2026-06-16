/* eslint-disable react-hooks/set-state-in-effect */
// src/App.jsx
import { useState, useEffect } from "react";
import { Routes, Route, Navigate, Link, useNavigate } from "react-router-dom";
import api from "./api";
import AdminLogin from "./pages/AdminLogin.jsx";
import DashboardPage from "./pages/DashboardPage.jsx";
import CoursesPage from "./pages/CoursesPage.jsx";
import CourseFormPage from "./pages/CourseFormPage.jsx";
import StudentsPage from "./pages/StudentsPage.jsx";
import EnrollmentsPage from "./pages/EnrollmentsPage.jsx";
import LiveClassPage from "./pages/LiveClassPage";
import VideosPage from "./pages/VideosPage.jsx";
import SettingsPage from "./pages/SettingsPage.jsx";
import {
  DEFAULT_INSTITUTE_NAME,
  FIXED_BRAND_NAME,
  normalizeAppSettings,
} from "./branding";

const layoutStyles = {
  appShell: {
    display: "flex",
    minHeight: "100vh",
    background: "transparent",
    color: "#e5e7eb",
    fontFamily:
      "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
  },
  sidebar: {
    width: 240,
    background: "rgba(2, 6, 23, 0.74)",
    borderRight: "1px solid rgba(148, 163, 184, 0.16)",
    padding: "16px 12px",
    display: "flex",
    flexDirection: "column",
    gap: 16,
  },
  brand: {
    fontSize: 20,
    fontWeight: 600,
    letterSpacing: 0,
    marginBottom: 2,
  },
  sidebarSectionTitle: {
    fontSize: 12,
    textTransform: "uppercase",
    color: "#6b7280",
    marginTop: 8,
    marginBottom: 4,
  },
  navLink: (active) => ({
    display: "block",
    padding: "8px 10px",
    borderRadius: 8,
    color: active ? "#0f172a" : "#d1d5db",
    background: active ? "linear-gradient(90deg, #f97316, #fb923c)" : "transparent",
    textDecoration: "none",
    fontSize: 14,
    fontWeight: 500,
    marginBottom: 4,
  }),
  main: {
    flex: 1,
    display: "flex",
    flexDirection: "column",
    background: "transparent",
  },
  header: {
    padding: "10px 20px",
    borderBottom: "1px solid rgba(148, 163, 184, 0.16)",
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    backdropFilter: "blur(12px)",
    background: "rgba(15, 23, 42, 0.78)",
    position: "sticky",
    top: 0,
    zIndex: 10,
  },
  headerTitle: { fontSize: 18, fontWeight: 500 },
  headerRight: { display: "flex", alignItems: "center", gap: 10 },
  chip: {
    fontSize: 12,
    padding: "2px 8px",
    borderRadius: 999,
    background: "#1d4ed8",
    color: "#e5e7eb",
  },
  logoutBtn: {
    padding: "6px 12px",
    borderRadius: 999,
    border: "1px solid #4b5563",
    background: "transparent",
    color: "#e5e7eb",
    cursor: "pointer",
    fontSize: 13,
  },
  contentWrapper: {
    padding: 20,
    overflow: "auto",
  },
};

function Layout({ admin, appSettings, onLogout, children, currentPath }) {
  const navigate = useNavigate();
  const adminLabel = admin?.level === "super_admin" ? "Real Admin" : "Admin";
  const brandName = appSettings?.brandName || FIXED_BRAND_NAME;
  const instituteName = appSettings?.instituteName || DEFAULT_INSTITUTE_NAME;

  const handleLogout = () => {
    localStorage.removeItem("admin");
    onLogout();
    navigate("/admin/login");
  };

  const isActive = (path) => currentPath.startsWith(path);

  return (
    <div className="admin-shell" style={layoutStyles.appShell}>
      {/* Sidebar */}
      <aside className="admin-sidebar" style={layoutStyles.sidebar}>
        <div>
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            {appSettings?.logoUrl && (
              <img
                className="admin-brand-logo"
                src={appSettings.logoUrl}
                alt={`${brandName} logo`}
                style={{
                  width: 34,
                  height: 34,
                  borderRadius: 10,
                  objectFit: "cover",
                  background: "#111827",
                }}
              />
            )}
            <div>
              <div style={layoutStyles.brand}>{brandName}</div>
              <div style={{ fontSize: 12, color: "#cbd5e1" }}>
                {instituteName}
              </div>
            </div>
          </div>
          <div style={{ fontSize: 11, color: "#9ca3af" }}>Admin Dashboard</div>
        </div>

        <div>
          <div style={layoutStyles.sidebarSectionTitle}></div>
          <Link
            className="admin-nav-link"
            to="/admin/dashboard"
            style={layoutStyles.navLink(isActive("/admin/dashboard"))}
          >
            Dashboard
          </Link>
          <Link
            className="admin-nav-link"
            to="/admin/courses"
            style={layoutStyles.navLink(isActive("/admin/courses"))}
          >
            Courses
          </Link>
          <Link
            className="admin-nav-link"
            to="/admin/students"
            style={layoutStyles.navLink(isActive("/admin/students"))}
          >
            Students
          </Link>
          <Link
            className="admin-nav-link"
            to="/admin/enrollments"
            style={layoutStyles.navLink(isActive("/admin/enrollments"))}
          >
            Enrollments
          </Link>
          <Link
            className="admin-nav-link"
            to="/live-class"
            style={layoutStyles.navLink(isActive("/live-class"))}
          >
            Live Class
          </Link>
          <Link
            className="admin-nav-link"
            to="/admin/videos"
            style={layoutStyles.navLink(isActive("/admin/videos"))}
          >
            Videos
          </Link>
          <Link
            className="admin-nav-link"
            to="/admin/settings"
            style={layoutStyles.navLink(isActive("/admin/settings"))}
          >
            Settings
          </Link>
        </div>
      </aside>

      {/* Main */}
      <div style={layoutStyles.main}>
        <header className="admin-header" style={layoutStyles.header}>
          <div style={layoutStyles.headerTitle}>
            {isActive("/admin/dashboard") && "Dashboard"}
            {isActive("/admin/courses") && "Courses"}
            {isActive("/admin/students") && "Students"}
            {isActive("/admin/enrollments") && "Enrollments"}
            {isActive("/live-class") && "Live Class"}
            {isActive("/admin/videos") && "Videos"}
            {isActive("/admin/settings") && "Settings"}
          </div>
          {admin && (
            <div style={layoutStyles.headerRight}>
              <span style={layoutStyles.chip}>{adminLabel}</span>
              <span style={{ fontSize: 13, color: "#9ca3af" }}>
                {admin.username}
              </span>
              <button style={layoutStyles.logoutBtn} onClick={handleLogout}>
                Logout
              </button>
            </div>
          )}
        </header>

        <main className="admin-content" style={layoutStyles.contentWrapper}>
          {children}
        </main>
      </div>
    </div>
  );
}

function AppInner() {
  const [admin, setAdmin] = useState(null);
  const [appSettings, setAppSettings] = useState(normalizeAppSettings());
  const navigate = useNavigate();

  useEffect(() => {
    const stored = localStorage.getItem("admin");
    if (stored) {
      try {
        const parsed = JSON.parse(stored);
        setAdmin(parsed);

        api
          .get("/auth/admin/me")
          .then((res) => {
            const refreshedAdmin = { ...res.data.admin, token: parsed.token };
            localStorage.setItem("admin", JSON.stringify(refreshedAdmin));
            setAdmin(refreshedAdmin);
          })
          .catch(() => {
            localStorage.removeItem("admin");
            setAdmin(null);
          });
      } catch {
        localStorage.removeItem("admin");
      }
    }

    api
      .get("/settings/public")
      .then((res) => {
        setAppSettings(normalizeAppSettings(res.data));
      })
      .catch(() => {});
  }, []);

  const handleLogin = (data) => {
    setAdmin(data);
    navigate("/admin/dashboard");
  };

  const requireAdmin = (element) =>
    admin ? element : <Navigate to="/admin/login" replace />;

  const makeLayout = (element) => (
    <Layout
      admin={admin}
      appSettings={appSettings}
      onLogout={() => setAdmin(null)}
      currentPath={window.location.pathname}
    >
      {element}
    </Layout>
  );

  return (
    <Routes>
      <Route
        path="/admin/login"
        element={
          <AdminLogin onLogin={handleLogin} appSettings={appSettings} />
        }
      />

      <Route
        path="/admin"
        element={requireAdmin(<Navigate to="/admin/dashboard" replace />)}
      />

      <Route
        path="/admin/dashboard"
        element={requireAdmin(makeLayout(<DashboardPage />))}
      />

      <Route
        path="/live-class"
        element={requireAdmin(makeLayout(<LiveClassPage />))}
      />

      <Route
        path="/admin/courses"
        element={requireAdmin(makeLayout(<CoursesPage />))}
      />

      <Route
        path="/admin/courses/new"
        element={requireAdmin(makeLayout(<CourseFormPage />))}
      />

      <Route
        path="/admin/courses/:id/edit"
        element={requireAdmin(makeLayout(<CourseFormPage />))}
      />

      <Route
        path="/admin/students"
        element={requireAdmin(makeLayout(<StudentsPage currentAdmin={admin} />))}
      />

      <Route
        path="/admin/enrollments"
        element={requireAdmin(makeLayout(<EnrollmentsPage />))}
      />

      <Route
        path="/admin/videos"
        element={requireAdmin(makeLayout(<VideosPage />))}
      />

      <Route
        path="/admin/settings"
        element={requireAdmin(
          makeLayout(<SettingsPage onSettingsSaved={setAppSettings} />)
        )}
      />

      <Route path="*" element={<Navigate to="/admin/login" replace />} />
    </Routes>
  );
}

export default function App() {
  return <AppInner />;
}
