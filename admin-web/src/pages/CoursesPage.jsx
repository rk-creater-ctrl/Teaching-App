//* eslint-disable no-unused-vars */
// src/pages/CoursesPage.jsx
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import api from "../api";

const cardStyle = {
  background: "#0b1120",
  borderRadius: 16,
  padding: 20,
  border: "1px solid #1f2937",
  boxShadow: "0 18px 40px rgba(0,0,0,0.45)",
  color: "#e5e7eb",
};

const inputStyle = {
  width: "100%",
  padding: "8px 10px",
  borderRadius: 8,
  border: "1px solid #374151",
  background: "#020617",
  color: "#e5e7eb",
  fontSize: 13,
};

const buttonPrimary = {
  padding: "7px 13px",
  borderRadius: 999,
  border: "none",
  background: "linear-gradient(90deg,#22c55e,#16a34a)",
  color: "#0f172a",
  cursor: "pointer",
  fontSize: 13,
  fontWeight: 600,
};

const buttonGhost = {
  padding: "6px 11px",
  borderRadius: 999,
  border: "1px solid #4b5563",
  background: "transparent",
  color: "#e5e7eb",
  cursor: "pointer",
  fontSize: 12,
};

const tableWrapper = {
  marginTop: 16,
  background: "#020617",
  borderRadius: 16,
  border: "1px solid #1f2937",
  overflow: "hidden",
};

const tableStyle = {
  width: "100%",
  borderCollapse: "collapse",
  fontSize: 13,
};

export default function CoursesPage() {
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error,   setError]   = useState("");
  const [search,  setSearch]  = useState("");
  const navigate = useNavigate();

  const loadCourses = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await api.get("/course/list");
      setCourses(res.data);
    } catch (err) {
      console.error(err);
      setError("Failed to load courses");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadCourses();
  }, []);

  const handleDelete = async (id) => {
    if (!window.confirm("Delete this course?")) return;
    try {
      await api.delete(`/course/${id}`);
      await loadCourses();
    } catch (err) {
      console.error(err);
      alert(err.response?.data || "Error deleting course");
    }
  };

  const filtered = courses.filter((c) => {
    const q = search.trim().toLowerCase();
    if (!q) return true;
    return (
      c.title?.toLowerCase().includes(q) ||
      c.category?.toLowerCase().includes(q)
    );
  });

  if (loading) return <p style={{ padding: 16 }}>Loading...</p>;
  if (error)   return <p style={{ padding: 16, color: "red" }}>{error}</p>;

  return (
    <div>
      <div className="page-card" style={cardStyle}>
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            gap: 12,
            alignItems: "center",
            marginBottom: 10,
          }}
        >
          <div>
            <h3 style={{ fontSize: 16, fontWeight: 500 }}>Courses</h3>
            <p style={{ fontSize: 12, color: "#9ca3af", marginTop: 2 }}>
              Manage all courses, pricing and paid/free status.
            </p>
          </div>
          <button
            style={buttonPrimary}
            onClick={() => navigate("/admin/courses/new")}
          >
            + New Course
          </button>
        </div>

        <input
          style={inputStyle}
          placeholder="Search by title or category..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      <div className="table-panel" style={tableWrapper}>
        {filtered.length === 0 ? (
          <div style={{ padding: 16 }}>No courses found.</div>
        ) : (
          <table className="admin-table" style={tableStyle}>
            <thead>
              <tr style={{ background: "#020617" }}>
                <th style={{ padding: 10, textAlign: "left", borderBottom: "1px solid #111827" }}>Title</th>
                <th style={{ padding: 10, textAlign: "left", borderBottom: "1px solid #111827" }}>Category</th>
                <th style={{ padding: 10, textAlign: "left", borderBottom: "1px solid #111827" }}>Paid</th>
                <th style={{ padding: 10, textAlign: "left", borderBottom: "1px solid #111827" }}>Price</th>
                <th style={{ padding: 10, textAlign: "left", borderBottom: "1px solid #111827" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((c, idx) => (
                <tr
                  key={c._id}
                  style={{ background: idx % 2 === 0 ? "#020617" : "#020617" }}
                >
                  <td style={{ padding: 10, borderBottom: "1px solid #111827" }}>
                    {c.title}
                  </td>
                  <td style={{ padding: 10, borderBottom: "1px solid #111827" }}>
                    {c.category || ""}
                  </td>
                  <td style={{ padding: 10, borderBottom: "1px solid #111827" }}>
                    {c.isPaid ? "Yes" : "No"}
                  </td>
                  <td style={{ padding: 10, borderBottom: "1px solid #111827" }}>
                    {c.isPaid ? `₹${c.price || 0}` : "-"}
                  </td>
                  <td style={{ padding: 10, borderBottom: "1px solid #111827" }}>
                    <button
                      onClick={() => navigate(`/admin/courses/${c._id}/edit`)}
                      style={{
                        ...buttonGhost,
                        marginRight: 6,
                      }}
                    >
                      Edit
                    </button>
                    <button
                      onClick={() => handleDelete(c._id)}
                      style={{
                        ...buttonGhost,
                        borderColor: "#b91c1c",
                        color: "#fecaca",
                      }}
                    >
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
