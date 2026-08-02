import { useEffect, useState } from "react";
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
  marginTop: 4,
  padding: "8px 10px",
  borderRadius: 8,
  border: "1px solid #374151",
  background: "#020617",
  color: "#e5e7eb",
  fontSize: 14,
};

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState([]);
  const [courses, setCourses] = useState([]);
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({
    title: "",
    message: "",
    courseId: "",
  });

  useEffect(() => {
    loadAll();
  }, []);

  async function loadAll() {
    try {
      const [notificationsRes, coursesRes] = await Promise.all([
        api.get("/notification/all"),
        api.get("/course/list"),
      ]);
      setNotifications(notificationsRes.data || []);
      setCourses(coursesRes.data || []);
    } catch (err) {
      console.error(err);
      setError("Failed to load notifications");
    }
  }

  async function handleSubmit(e) {
    e.preventDefault();
    if (!form.title.trim()) {
      setError("Title is required");
      return;
    }

    try {
      setSaving(true);
      setError("");
      await api.post("/notification/all", {
        title: form.title.trim(),
        message: form.message.trim(),
        courseId: form.courseId || null,
        type: "announcement",
      });
      setForm({ title: "", message: "", courseId: "" });
      await loadAll();
    } catch (err) {
      console.error(err);
      setError(err.response?.data?.error || "Failed to send notification");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div style={{ padding: 20, color: "#e5e7eb", background: "#020617", minHeight: "100vh" }}>
      <h1 style={{ fontSize: 22, fontWeight: 600, marginBottom: 16 }}>Notifications</h1>

      <div style={{ ...cardStyle, maxWidth: 560, marginBottom: 24 }}>
        <h2 style={{ fontSize: 16, fontWeight: 500, marginBottom: 12 }}>Send announcement</h2>
        {error && (
          <div style={{ background: "rgba(239,68,68,0.15)", border: "1px solid #ef4444", color: "#fecaca", borderRadius: 8, padding: "6px 10px", marginBottom: 10, fontSize: 13 }}>
            {String(error)}
          </div>
        )}
        <form onSubmit={handleSubmit} style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <label style={{ fontSize: 13, color: "#9ca3af" }}>
            Title
            <input style={inputStyle} value={form.title} onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))} />
          </label>
          <label style={{ fontSize: 13, color: "#9ca3af" }}>
            Message
            <textarea style={{ ...inputStyle, minHeight: 90 }} value={form.message} onChange={(e) => setForm((f) => ({ ...f, message: e.target.value }))} />
          </label>
          <label style={{ fontSize: 13, color: "#9ca3af" }}>
            Course target
            <select style={inputStyle} value={form.courseId} onChange={(e) => setForm((f) => ({ ...f, courseId: e.target.value }))}>
              <option value="">All students / global</option>
              {courses.map((course) => (
                <option key={course._id} value={course._id}>{course.title}</option>
              ))}
            </select>
          </label>
          <button type="submit" disabled={saving} style={{ padding: "9px 13px", borderRadius: 999, border: "none", background: saving ? "#4b5563" : "#22c55e", color: "#020617", fontWeight: 700 }}>
            {saving ? "Sending..." : "Send notification"}
          </button>
        </form>
      </div>

      <div style={cardStyle}>
        <h2 style={{ fontSize: 16, fontWeight: 500, marginBottom: 12 }}>Recent notifications</h2>
        {notifications.length === 0 ? (
          <div style={{ color: "#9ca3af" }}>No notifications yet.</div>
        ) : (
          <div style={{ display: "grid", gap: 10 }}>
            {notifications.map((item) => (
              <div key={item.id} style={{ border: "1px solid #1f2937", borderRadius: 12, padding: 12, background: "#020617" }}>
                <div style={{ fontWeight: 700 }}>{item.title}</div>
                <div style={{ color: "#cbd5e1", fontSize: 13, marginTop: 4 }}>{item.message}</div>
                <div style={{ color: "#64748b", fontSize: 11, marginTop: 6 }}>
                  {item.courseTitle ? `Course: ${item.courseTitle}` : "Global"} · {item.type}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
