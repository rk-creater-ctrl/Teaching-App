import { useEffect, useState } from "react";
import api from "../api";

const cardStyle = {
  background: "#0b1120",
  borderRadius: 16,
  padding: 20,
  border: "1px solid #1f2937",
  boxShadow: "0 18px 40px rgba(0,0,0,0.45)",
  color: "#e5e7eb",
  maxWidth: 720,
};

const inputStyle = {
  width: "100%",
  padding: "9px 10px",
  borderRadius: 8,
  border: "1px solid #374151",
  background: "#020617",
  color: "#e5e7eb",
  fontSize: 13,
};

const labelStyle = {
  display: "block",
  marginBottom: 5,
  fontSize: 12,
  color: "#9ca3af",
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

export default function SettingsPage({ onSettingsSaved }) {
  const [appName, setAppName] = useState("TechJaguar");
  const [logoUrl, setLogoUrl] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [logoPreviewFailed, setLogoPreviewFailed] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    let mounted = true;

    async function loadSettings() {
      setLoading(true);
      setError("");
      try {
        const res = await api.get("/settings/public");
        if (!mounted) return;
        setAppName(res.data.appName || "TechJaguar");
        setLogoUrl(res.data.logoUrl || "");
        setLogoPreviewFailed(false);
      } catch (err) {
        console.error(err);
        if (mounted) {
          setAppName("TechJaguar");
          setLogoUrl("");
          setError(
            "Could not load saved settings. You can still edit and save after the backend is running with the latest code."
          );
        }
      } finally {
        if (mounted) setLoading(false);
      }
    }

    loadSettings();

    return () => {
      mounted = false;
    };
  }, []);

  async function handleLogoUpload(e) {
    const file = e.target.files?.[0];
    if (!file) return;

    const formData = new FormData();
    formData.append("cover", file);

    setUploading(true);
    setError("");
    setMessage("");

    try {
      const res = await api.post("/upload/cover", formData);
      setLogoUrl(res.data.coverImageUrl || res.data.path || "");
      setLogoPreviewFailed(false);
      setMessage("Logo uploaded. Save settings to apply it.");
    } catch (err) {
      console.error(err);
      setError("Failed to upload logo");
    } finally {
      setUploading(false);
    }
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setSaving(true);
    setError("");
    setMessage("");

    try {
      const res = await api.post("/settings/admin", {
        appName,
        logoUrl,
      });
      setMessage("Settings saved");
      onSettingsSaved?.(res.data);
    } catch (err) {
      console.error(err);
      const status = err.response?.status;
      if (status === 401 || status === 403) {
        setError("Please log in again as admin, then save settings.");
      } else if (status === 404) {
        setError("Settings API not found. Restart the backend server.");
      } else {
        setError(err.response?.data?.message || "Failed to save settings");
      }
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <div style={{ padding: 16 }}>Loading settings...</div>;

  return (
    <div className="settings-card" style={cardStyle}>
      <div style={{ marginBottom: 18 }}>
        <h3 style={{ fontSize: 18, fontWeight: 600, margin: 0 }}>
          App Settings
        </h3>
        <p style={{ fontSize: 13, color: "#9ca3af", marginTop: 6 }}>
          Update the app name and logo shown in the admin panel.
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
            padding: "7px 10px",
          }}
        >
          {error}
        </div>
      )}

      {message && (
        <div
          style={{
            marginBottom: 12,
            fontSize: 12,
            color: "#bbf7d0",
            background: "#052e16",
            borderRadius: 10,
            padding: "7px 10px",
          }}
        >
          {message}
        </div>
      )}

      <form
        onSubmit={handleSubmit}
        style={{ display: "flex", flexDirection: "column", gap: 14 }}
      >
        <div>
          <label style={labelStyle}>App Name</label>
          <input
            style={inputStyle}
            value={appName}
            onChange={(e) => setAppName(e.target.value)}
            required
          />
        </div>

        <div>
          <label style={labelStyle}>Logo</label>
          <input
            type="file"
            accept="image/*"
            onChange={handleLogoUpload}
            style={{ color: "#e5e7eb", fontSize: 12 }}
          />
          {uploading && (
            <div style={{ color: "#9ca3af", fontSize: 12, marginTop: 6 }}>
              Uploading logo...
            </div>
          )}
        </div>

        <div>
          <label style={labelStyle}>Logo URL</label>
          <input
            style={inputStyle}
            value={logoUrl}
            onChange={(e) => {
              setLogoUrl(e.target.value);
              setLogoPreviewFailed(false);
            }}
            placeholder="Upload a logo or paste an image URL"
          />
        </div>

        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 12,
            padding: 12,
            borderRadius: 12,
            background: "#020617",
            border: "1px solid #1f2937",
          }}
        >
          {logoUrl && !logoPreviewFailed ? (
            <img
              className="logo-preview"
              src={logoUrl}
              alt="App logo preview"
              onError={() => setLogoPreviewFailed(true)}
              style={{
                width: 48,
                height: 48,
                borderRadius: 12,
                objectFit: "cover",
                background: "#111827",
              }}
            />
          ) : (
            <div
              className="logo-preview"
              style={{
                width: 48,
                height: 48,
                borderRadius: 12,
                background: "#111827",
                display: "grid",
                placeItems: "center",
                color: "#9ca3af",
                fontWeight: 700,
              }}
            >
              T
            </div>
          )}
          <div>
            <div style={{ fontSize: 15, fontWeight: 600 }}>{appName}</div>
            <div style={{ color: "#9ca3af", fontSize: 12 }}>
              Branding preview
            </div>
          </div>
        </div>

        <div>
          <button type="submit" style={buttonPrimary} disabled={saving}>
            {saving ? "Saving..." : "Save Settings"}
          </button>
        </div>
      </form>
    </div>
  );
}
