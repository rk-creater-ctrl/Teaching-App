// src/pages/VideosPage.jsx
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

export default function VideosPage() {
  const [videos, setVideos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [deletingId, setDeletingId] = useState(null);
  const [error, setError] = useState("");
  const [form, setForm] = useState({
    title: "",
    youtubeVideoId: "",
    order: "",
  });

  useEffect(() => {
    loadVideos();
  }, []);

  async function loadVideos() {
    setLoading(true);
    setError("");
    try {
      const res = await api.get("/video/all");
      setVideos(res.data);
    } catch (e) {
      console.error("LOAD VIDEOS ERROR:", e.response?.status, e.response?.data);
      setError(e.response?.data || "Failed to load videos");
    } finally {
      setLoading(false);
    }
  }

  // Add YouTube video
  async function handleSubmit(e) {
    e.preventDefault();
    if (!form.title.trim() || !form.youtubeVideoId.trim()) {
      setError("Title and YouTube Video ID are required");
      return;
    }

    try {
      setSaving(true);
      setError("");

      const payload = {
        title: form.title.trim(),
        youtubeVideoId: form.youtubeVideoId.trim(),
        order: form.order ? Number(form.order) : 0,
      };

      const res = await api.post("/video/all", payload);

      setVideos((prev) => [res.data.video, ...prev]);
      setForm({ title: "", youtubeVideoId: "", order: "" });
    } catch (e) {
      console.error("SAVE VIDEO ERROR:", e.response?.status, e.response?.data);
      setError(e.response?.data || "Failed to save video");
    } finally {
      setSaving(false);
    }
  }

  // Upload file video from system
  async function handleUploadFromSystem() {
    try {
      setError("");

      if (!form.title.trim()) {
        setError("Title is required for uploaded video");
        return;
      }

      const input = document.createElement("input");
      input.type = "file";
      input.accept = "video/*";

      input.onchange = async () => {
        const file = input.files?.[0];
        if (!file) return;

        const fd = new FormData();
        fd.append("title", form.title.trim());
        if (form.order) fd.append("order", String(form.order));
        fd.append("file", file);

        try {
          setSaving(true);

          const res = await api.post("/video/upload", fd, {
            headers: {
              "Content-Type": "multipart/form-data",
            },
          });

          console.log("UPLOAD RES", res.data);

          const newVideo = res.data.video || res.data;

          if (!newVideo) {
            setError("Upload succeeded but no video returned from server");
          } else {
            setVideos((prev) => [newVideo, ...prev]);
            setForm({ title: "", youtubeVideoId: "", order: "" });
          }
        } catch (e) {
          console.error("UPLOAD VIDEO ERROR:", e);
          const msg =
            e.response?.data?.error ||
            e.response?.data ||
            e.message ||
            "Failed to upload video";
          setError(String(msg));
        } finally {
          setSaving(false);
        }
      };

      input.click();
    } catch (err) {
      console.error("Upload init error:", err);
      setError("Failed to open file picker");
    }
  }

  function thumbUrlYoutube(videoId) {
    return `https://img.youtube.com/vi/${videoId}/0.jpg`;
  }

  function thumbForVideo(v) {
    if (v.type === "youtube" && v.youtubeVideoId) {
      return thumbUrlYoutube(v.youtubeVideoId);
    }
    return "https://dummyimage.com/640x360/111827/9ca3af&text=Uploaded+Video";
  }

  async function handleDeleteVideo(video) {
    const videoId = video._id || video.id;

    if (!videoId) {
      setError("Cannot delete this video because its id is missing");
      return;
    }

    if (!window.confirm(`Delete "${video.title}"?`)) return;

    try {
      setDeletingId(videoId);
      setError("");
      await api.delete(`/video/all/${videoId}`);
      await loadVideos();
    } catch (e) {
      console.error("DELETE VIDEO ERROR:", e.response?.status, e.response?.data);
      const msg =
        e.response?.data?.error ||
        e.response?.data?.message ||
        e.response?.data ||
        e.message ||
        "Failed to delete video";
      setError(String(msg));
    } finally {
      setDeletingId(null);
    }
  }

  return (
    <div
      style={{
        padding: 20,
        color: "#e5e7eb",
        background: "#020617",
        minHeight: "100vh",
      }}
    >
      <h1 style={{ fontSize: 22, fontWeight: 600, marginBottom: 16 }}>
        Videos
      </h1>

      <div
        className="form-card"
        style={{
          ...cardStyle,
          marginBottom: 24,
          maxWidth: 480,
        }}
      >
        <h2 style={{ fontSize: 16, fontWeight: 500, marginBottom: 12 }}>
          Add new video
        </h2>
        {error && (
          <div
            style={{
              background: "rgba(239,68,68,0.15)",
              border: "1px solid #ef4444",
              color: "#fecaca",
              borderRadius: 8,
              padding: "6px 10px",
              marginBottom: 10,
              fontSize: 13,
            }}
          >
            {String(error)}
          </div>
        )}
        <form
          onSubmit={handleSubmit}
          style={{ display: "flex", flexDirection: "column", gap: 10 }}
        >
          <div>
            <label style={{ fontSize: 13, color: "#9ca3af" }}>Title</label>
            <input
              type="text"
              value={form.title}
              onChange={(e) =>
                setForm((f) => ({ ...f, title: e.target.value }))
              }
              style={{
                width: "100%",
                marginTop: 4,
                padding: "8px 10px",
                borderRadius: 8,
                border: "1px solid #374151",
                background: "#020617",
                color: "#e5e7eb",
                fontSize: 14,
              }}
              placeholder="Chapter 1 - Introduction"
            />
          </div>

          <div>
            <label style={{ fontSize: 13, color: "#9ca3af" }}>
              YouTube Video ID (for YouTube videos)
            </label>
            <input
              type="text"
              value={form.youtubeVideoId}
              onChange={(e) =>
                setForm((f) => ({ ...f, youtubeVideoId: e.target.value }))
              }
              style={{
                width: "100%",
                marginTop: 4,
                padding: "8px 10px",
                borderRadius: 8,
                border: "1px solid #374151",
                background: "#020617",
                color: "#e5e7eb",
                fontSize: 14,
              }}
              placeholder="e.g. JQvlGwI4Vxw"
            />
            <div style={{ fontSize: 11, color: "#6b7280", marginTop: 4 }}>
              Paste only the ID (the part after <code>v=</code> in the URL).
            </div>
          </div>

          <div>
            <label style={{ fontSize: 13, color: "#9ca3af" }}>
              Order (optional)
            </label>
            <input
              type="number"
              value={form.order}
              onChange={(e) =>
                setForm((f) => ({ ...f, order: e.target.value }))
              }
              style={{
                width: "100%",
                marginTop: 4,
                padding: "8px 10px",
                borderRadius: 8,
                border: "1px solid #374151",
                background: "#020617",
                color: "#e5e7eb",
                fontSize: 14,
              }}
              placeholder="0"
            />
          </div>

          <div
            style={{
              display: "flex",
              gap: 8,
              marginTop: 6,
              flexWrap: "wrap",
            }}
          >
            <button
              type="submit"
              disabled={saving}
              style={{
                padding: "8px 12px",
                borderRadius: 999,
                border: "none",
                background: saving ? "#4b5563" : "#22c55e",
                color: "#020617",
                fontWeight: 600,
                fontSize: 14,
                cursor: saving ? "default" : "pointer",
              }}
            >
              {saving ? "Saving..." : "Add YouTube video"}
            </button>

            <button
              type="button"
              disabled={saving}
              onClick={handleUploadFromSystem}
              style={{
                padding: "8px 12px",
                borderRadius: 999,
                border: "1px solid #4b5563",
                background: "#0f172a",
                color: "#e5e7eb",
                fontWeight: 500,
                fontSize: 14,
                cursor: saving ? "default" : "pointer",
              }}
            >
              {saving ? "Uploading..." : "Upload video from system"}
            </button>
          </div>
        </form>
      </div>

      <div
        className="page-card"
        style={{
          background: "#0f172a",
          borderRadius: 16,
          padding: 16,
          border: "1px solid #1f2937",
        }}
      >
        <h2 style={{ fontSize: 16, fontWeight: 500, marginBottom: 12 }}>
          All videos
        </h2>
        {loading ? (
          <div style={{ padding: 20, fontSize: 14, color: "#9ca3af" }}>
            Loading...
          </div>
        ) : videos.length === 0 ? (
          <div style={{ padding: 20, fontSize: 14, color: "#9ca3af" }}>
            No videos yet. Add a YouTube video or upload one from your system.
          </div>
        ) : (
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fill, minmax(260px, 1fr))",
              gap: 12,
            }}
          >
            {videos.map((v) => (
              <div
                className="video-card"
                key={v._id || v.id}
                style={{
                  borderRadius: 10,
                  overflow: "hidden",
                  border: "1px solid #1f2937",
                  background: "#020617",
                }}
              >
                <div style={{ position: "relative", paddingTop: "56.25%" }}>
                  <img
                    src={thumbForVideo(v)}
                    alt={v.title}
                    style={{
                      position: "absolute",
                      inset: 0,
                      width: "100%",
                      height: "100%",
                      objectFit: "cover",
                    }}
                  />
                </div>
                <div style={{ padding: 10 }}>
                  <div
                    style={{
                      fontSize: 14,
                      fontWeight: 500,
                      color: "#e5e7eb",
                      marginBottom: 4,
                    }}
                  >
                    {v.title}
                  </div>
                  <div style={{ fontSize: 11, color: "#6b7280" }}>
                    {v.type === "youtube"
                      ? `YouTube ID: ${v.youtubeVideoId}`
                      : "File video"}
                  </div>
                  <button
                    type="button"
                    onClick={() => handleDeleteVideo(v)}
                    disabled={deletingId === (v._id || v.id)}
                    style={{
                      marginTop: 10,
                      width: "100%",
                      padding: "7px 10px",
                      borderRadius: 999,
                      border: "1px solid #b91c1c",
                      background:
                        deletingId === (v._id || v.id)
                          ? "rgba(75,85,99,0.65)"
                          : "rgba(127,29,29,0.2)",
                      color: "#fecaca",
                      cursor:
                        deletingId === (v._id || v.id) ? "default" : "pointer",
                      fontSize: 12,
                      fontWeight: 700,
                    }}
                  >
                    {deletingId === (v._id || v.id)
                      ? "Deleting..."
                      : "Delete Video"}
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
