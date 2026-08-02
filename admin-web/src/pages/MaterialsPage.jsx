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

export default function MaterialsPage() {
  const [materials, setMaterials] = useState([]);
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [form, setForm] = useState({ title: "", courseId: "", order: "" });

  useEffect(() => {
    loadAll();
  }, []);

  async function loadAll() {
    setLoading(true);
    setError("");
    try {
      const [materialsRes, coursesRes] = await Promise.all([
        api.get("/material/all"),
        api.get("/course/list"),
      ]);
      setMaterials(materialsRes.data || []);
      setCourses(coursesRes.data || []);
    } catch (err) {
      console.error(err);
      setError("Failed to load materials");
    } finally {
      setLoading(false);
    }
  }

  async function handleUpload() {
    if (!form.title.trim()) {
      setError("Title is required");
      return;
    }

    const input = document.createElement("input");
    input.type = "file";
    input.accept = ".pdf,.doc,.docx,image/*";
    input.onchange = async () => {
      const file = input.files?.[0];
      if (!file) return;

      const fd = new FormData();
      fd.append("title", form.title.trim());
      fd.append("file", file);
      if (form.courseId) fd.append("courseId", form.courseId);
      if (form.order) fd.append("order", String(form.order));

      try {
        setSaving(true);
        setError("");
        await api.post("/material/upload", fd, {
          headers: { "Content-Type": "multipart/form-data" },
        });
        setForm({ title: "", courseId: "", order: "" });
        await loadAll();
      } catch (err) {
        console.error(err);
        setError(err.response?.data?.error || "Failed to upload material");
      } finally {
        setSaving(false);
      }
    };
    input.click();
  }

  async function handleDelete(material) {
    if (!window.confirm(`Delete "${material.title}"?`)) return;
    try {
      setError("");
      await api.delete(`/material/${material.id}`);
      await loadAll();
    } catch (err) {
      console.error(err);
      setError(err.response?.data?.error || "Failed to delete material");
    }
  }

  return (
    <div style={{ padding: 20, color: "#e5e7eb", background: "#020617", minHeight: "100vh" }}>
      <h1 style={{ fontSize: 22, fontWeight: 600, marginBottom: 16 }}>Notes / Materials</h1>

      <div style={{ ...cardStyle, maxWidth: 520, marginBottom: 24 }}>
        <h2 style={{ fontSize: 16, fontWeight: 500, marginBottom: 12 }}>Upload material</h2>
        {error && (
          <div style={{ background: "rgba(239,68,68,0.15)", border: "1px solid #ef4444", color: "#fecaca", borderRadius: 8, padding: "6px 10px", marginBottom: 10, fontSize: 13 }}>
            {String(error)}
          </div>
        )}

        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <label style={{ fontSize: 13, color: "#9ca3af" }}>
            Title
            <input
              style={inputStyle}
              value={form.title}
              onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))}
              placeholder="Chapter 1 Notes"
            />
          </label>

          <label style={{ fontSize: 13, color: "#9ca3af" }}>
            Course access
            <select
              style={inputStyle}
              value={form.courseId}
              onChange={(e) => setForm((f) => ({ ...f, courseId: e.target.value }))}
            >
              <option value="">All students / global</option>
              {courses.map((course) => (
                <option key={course._id} value={course._id}>
                  {course.title}
                </option>
              ))}
            </select>
          </label>

          <label style={{ fontSize: 13, color: "#9ca3af" }}>
            Order
            <input
              style={inputStyle}
              type="number"
              value={form.order}
              onChange={(e) => setForm((f) => ({ ...f, order: e.target.value }))}
              placeholder="0"
            />
          </label>

          <button
            type="button"
            disabled={saving}
            onClick={handleUpload}
            style={{ padding: "9px 13px", borderRadius: 999, border: "none", background: saving ? "#4b5563" : "#22c55e", color: "#020617", fontWeight: 700, cursor: saving ? "default" : "pointer" }}
          >
            {saving ? "Uploading..." : "Choose file and upload"}
          </button>
        </div>
      </div>

      <div style={{ ...cardStyle, background: "#0f172a" }}>
        <h2 style={{ fontSize: 16, fontWeight: 500, marginBottom: 12 }}>All materials</h2>
        {loading ? (
          <div style={{ padding: 16, color: "#9ca3af" }}>Loading...</div>
        ) : materials.length === 0 ? (
          <div style={{ padding: 16, color: "#9ca3af" }}>No materials uploaded yet.</div>
        ) : (
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(260px, 1fr))", gap: 12 }}>
            {materials.map((material) => (
              <div key={material.id} style={{ border: "1px solid #1f2937", background: "#020617", borderRadius: 12, padding: 12 }}>
                <div style={{ fontWeight: 700, marginBottom: 5 }}>{material.title}</div>
                <div style={{ fontSize: 12, color: "#9ca3af" }}>
                  {material.courseTitle ? `Course: ${material.courseTitle}` : "Access: Global"}
                </div>
                <div style={{ fontSize: 11, color: "#6b7280", marginTop: 3 }}>
                  {material.fileName || "Material file"}
                </div>
                <div style={{ display: "flex", gap: 8, marginTop: 12 }}>
                  <a href={material.fileUrl} target="_blank" rel="noreferrer" style={{ flex: 1, textAlign: "center", padding: "7px 10px", borderRadius: 999, border: "1px solid #334155", color: "#e5e7eb", textDecoration: "none", fontSize: 12 }}>
                    Open
                  </a>
                  <button onClick={() => handleDelete(material)} style={{ flex: 1, padding: "7px 10px", borderRadius: 999, border: "1px solid #b91c1c", background: "rgba(127,29,29,0.2)", color: "#fecaca", fontSize: 12, cursor: "pointer" }}>
                    Delete
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
