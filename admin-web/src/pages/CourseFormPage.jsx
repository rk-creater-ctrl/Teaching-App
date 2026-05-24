// src/pages/CourseFormPage.jsx
import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import api from "../api";

const cardStyle = {
  background: "#0b1120",
  borderRadius: 16,
  padding: 20,
  border: "1px solid #1f2937",
  boxShadow: "0 18px 40px rgba(0,0,0,0.45)",
  color: "#e5e7eb",
  maxWidth: 640,
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

const labelStyle = {
  display: "block",
  marginBottom: 4,
  fontSize: 12,
  color: "#9ca3af",
};

const textareaStyle = {
  ...inputStyle,
  minHeight: 80,
  resize: "vertical",
};

const checkboxRow = {
  display: "flex",
  alignItems: "center",
  gap: 8,
  fontSize: 13,
  color: "#e5e7eb",
};

const buttonPrimary = {
  padding: "8px 16px",
  borderRadius: 999,
  border: "none",
  background: "linear-gradient(90deg,#22c55e,#16a34a)",
  color: "#0f172a",
  cursor: "pointer",
  fontSize: 13,
  fontWeight: 600,
};

const buttonGhost = {
  padding: "8px 16px",
  borderRadius: 999,
  border: "1px solid #4b5563",
  background: "transparent",
  color: "#e5e7eb",
  cursor: "pointer",
  fontSize: 13,
};

export default function CourseFormPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const isEdit = !!id;

  const [form, setForm] = useState({
    title: "",
    description: "",
    category: "",
    price: 0,
    coverImageUrl: "", // NEW
    modeOptions: {
      online: true,
      offline: false,
    },
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const [imageUploading, setImageUploading] = useState(false); // NEW
  const [imagePreview, setImagePreview] = useState(""); // NEW

  useEffect(() => {
    const loadCourse = async () => {
      if (!isEdit) return;
      setLoading(true);
      setError("");
      try {
        const res = await api.get(`/course/${id}`);
        const c = res.data;
        setForm({
          title: c.title || "",
          description: c.description || "",
          category: c.category || "",
          price: c.price ?? 0,
          coverImageUrl: c.coverImageUrl || "",
          modeOptions: {
            online: c.modeOptions?.online ?? true,
            offline: c.modeOptions?.offline ?? false,
          },
        });
        setImagePreview(c.coverImageUrl || "");
      } catch (err) {
        console.error(err);
        setError("Failed to load course");
      } finally {
        setLoading(false);
      }
    };
    loadCourse();
  }, [id, isEdit]);

  const handleChange = (field, value) => {
    setForm((prev) => ({ ...prev, [field]: value }));
  };

  const handleModeChange = (field, checked) => {
    setForm((prev) => ({
      ...prev,
      modeOptions: {
        ...prev.modeOptions,
        [field]: checked,
      },
    }));
  };

  const handleImageChange = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const previewUrl = URL.createObjectURL(file);
    setImagePreview(previewUrl);

    const formData = new FormData();
    formData.append("cover", file); // matches upload.single("cover")

    try {
      setImageUploading(true);
      setError("");
      const res = await api.post("/upload/cover", formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });

      const { coverImageUrl, path } = res.data;
      const finalUrl = coverImageUrl || path;
      if (!finalUrl) throw new Error("Upload did not return URL");

      setForm((prev) => ({
        ...prev,
        coverImageUrl: finalUrl,
      }));
    } catch (err) {
      console.error("UPLOAD ERROR:", err.response?.data || err.message);
      setError("Failed to upload image");
    } finally {
      setImageUploading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const payload = {
        title: form.title,
        description: form.description,
        category: form.category,
        price: Number(form.price) || 0,
        coverImageUrl: form.coverImageUrl || "",
        modeOptions: {
          online: !!form.modeOptions.online,
          offline: !!form.modeOptions.offline,
        },
      };

      if (isEdit) {
        await api.put(`/course/${id}`, payload);
      } else {
        await api.post("/course", payload);
      }

      navigate("/admin/courses");
    } catch (err) {
      console.error(err);
      setError(err.response?.data || "Error saving course");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="form-card" style={cardStyle}>
      <div style={{ marginBottom: 12 }}>
        <h3 style={{ fontSize: 16, fontWeight: 500 }}>
          {isEdit ? "Edit Course" : "New Course"}
        </h3>
        <p style={{ fontSize: 12, color: "#9ca3af", marginTop: 2 }}>
          Configure title, pricing and available modes for this course.
        </p>
      </div>

      {error && (
        <div
          style={{
            marginBottom: 12,
            fontSize: 12,
            color: "#fecaca",
            background: "#450a0a",
            borderRadius: 10,
            padding: "6px 10px",
          }}
        >
          {error}
        </div>
      )}

      <form
        onSubmit={handleSubmit}
        style={{ display: "flex", flexDirection: "column", gap: 12 }}
      >
        <div>
          <label style={labelStyle}>Title</label>
          <input
            style={inputStyle}
            value={form.title}
            onChange={(e) => handleChange("title", e.target.value)}
            required
          />
        </div>

        <div>
          <label style={labelStyle}>Description</label>
          <textarea
            style={textareaStyle}
            value={form.description}
            onChange={(e) => handleChange("description", e.target.value)}
          />
        </div>

        <div>
          <label style={labelStyle}>Category</label>
          <input
            style={inputStyle}
            value={form.category}
            onChange={(e) => handleChange("category", e.target.value)}
          />
        </div>

        <div>
          <label style={labelStyle}>Price</label>
          <input
            type="number"
            style={inputStyle}
            value={form.price}
            onChange={(e) => handleChange("price", e.target.value)}
            min="0"
          />
        </div>

        {/* Image, but with very simple UI to keep look same */}
        <div>
          <label style={labelStyle}>Cover Image</label>
          <input
            type="file"
            accept="image/*"
            onChange={handleImageChange}
            style={{ fontSize: 12, color: "#e5e7eb" }}
          />
          {imageUploading && (
            <div style={{ fontSize: 11, color: "#9ca3af", marginTop: 4 }}>
              Uploading...
            </div>
          )}
          {(imagePreview || form.coverImageUrl) && (
            <div style={{ marginTop: 8 }}>
              <img
                src={imagePreview || form.coverImageUrl}
                alt="Course cover"
                style={{ maxWidth: 160, borderRadius: 8 }}
              />
            </div>
          )}
        </div>

        <div>
          <label style={labelStyle}>Available Modes</label>
          <div style={{ display: "flex", gap: 16 }}>
            <label style={checkboxRow}>
              <input
                type="checkbox"
                checked={!!form.modeOptions.online}
                onChange={(e) => handleModeChange("online", e.target.checked)}
              />
              <span>Online</span>
            </label>
            <label style={checkboxRow}>
              <input
                type="checkbox"
                checked={!!form.modeOptions.offline}
                onChange={(e) => handleModeChange("offline", e.target.checked)}
              />
              <span>Offline</span>
            </label>
          </div>
        </div>

        <div style={{ display: "flex", gap: 8, marginTop: 4 }}>
          <button type="submit" style={buttonPrimary} disabled={loading}>
            {loading ? "Saving..." : "Save"}
          </button>
          <button
            type="button"
            style={buttonGhost}
            onClick={() => navigate("/admin/courses")}
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}
