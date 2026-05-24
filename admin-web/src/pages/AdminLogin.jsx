// src/pages/AdminLogin.jsx
import { useState } from "react";
import api from "../api";

const wrapper = {
  minHeight: "100vh",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
  background: "radial-gradient(circle at top, #1f2937, #020617 55%)",
  fontFamily: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
};

const card = {
  width: 340,
  background: "#020617",
  borderRadius: 20,
  padding: 24,
  border: "1px solid #1f2937",
  boxShadow: "0 25px 60px rgba(0,0,0,0.65)",
  color: "#e5e7eb",
};

const input = {
  width: "100%",
  padding: "8px 10px",
  borderRadius: 10,
  border: "1px solid #374151",
  background: "#020617",
  color: "#e5e7eb",
  fontSize: 14,
};

const label = {
  display: "block",
  marginBottom: 4,
  fontSize: 12,
  color: "#9ca3af",
};

const btn = {
  width: "100%",
  padding: "9px 0",
  borderRadius: 999,
  border: "none",
  background: "linear-gradient(90deg,#f97316,#fb923c)",
  color: "#111827",
  fontWeight: 600,
  cursor: "pointer",
  fontSize: 14,
  marginTop: 8,
};

export default function AdminLogin({ onLogin, appSettings }) {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [loading,  setLoading]  = useState(false);
  const [error,    setError]    = useState("");
  const appName = appSettings?.appName || "TechJaguar";

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const res = await api.post("/auth/admin/login", { username, password });
      const data = res.data;
      // data.admin and data.token expected
      const adminWithToken = { ...data.admin, token: data.token };
      localStorage.setItem("admin", JSON.stringify(adminWithToken));
      onLogin(adminWithToken);
    } catch (err) {
      console.error(err);
      setError(err.response?.data || "Invalid credentials");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={wrapper}>
      <div className="login-card" style={card}>
        <div style={{ marginBottom: 18 }}>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 12,
              marginBottom: 8,
            }}
          >
            {appSettings?.logoUrl && (
              <img
                src={appSettings.logoUrl}
                alt={`${appName} logo`}
                style={{
                  width: 42,
                  height: 42,
                  borderRadius: 12,
                  objectFit: "cover",
                  background: "#111827",
                  border: "1px solid #1f2937",
                }}
              />
            )}
            <div style={{ fontSize: 20, fontWeight: 600 }}>
              {appName} Admin
            </div>
          </div>
          <div style={{ fontSize: 12, color: "#9ca3af" }}>
            Sign in to manage courses, students and enrollments.
          </div>
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

        <form onSubmit={handleSubmit} style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <div>
            <label style={label}>Username</label>
            <input
              style={input}
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              autoComplete="username"
              required
            />
          </div>
          <div>
            <label style={label}>Password</label>
            <input
              type="password"
              style={input}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="current-password"
              required
            />
          </div>
          <button type="submit" style={btn} disabled={loading}>
            {loading ? "Signing in..." : "Login"}
          </button>
        </form>
      </div>
    </div>
  );
}
