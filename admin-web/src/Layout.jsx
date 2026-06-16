// src/Layout.jsx
import { Link, NavLink } from "react-router-dom";

export default function Layout({ admin, onLogout, children }) {
  return (
    <div className="admin-layout">
      <aside className="sidebar">
        <div className="sidebar-header">
          <h2>SR EduNova Admin</h2>
          <p>{admin?.name}</p>
        </div>
        <nav>
          <ul>
            <li>
              <NavLink to="/admin/courses">Courses</NavLink>
            </li>
            <li>
              <NavLink to="/admin/students">Students</NavLink>
            </li>
            <li>
              <NavLink to="/admin/enrollments">Enrollments</NavLink>
            </li>
            <li>
              <NavLink to="/admin/live-classes">Live Classes</NavLink>
            </li>
          </ul>
        </nav>
        <button onClick={onLogout} className="logout-btn">
          Logout
        </button>
      </aside>
      <main className="content">
        <header className="top-bar">
          <Link to="/admin/courses">Dashboard</Link>
        </header>
        <section className="page-content">{children}</section>
      </main>
    </div>
  );
}
