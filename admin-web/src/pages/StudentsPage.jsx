// src/pages/StudentsPage.jsx
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

const buttonPrimary = {
  padding: "8px 14px",
  borderRadius: 999,
  border: "none",
  background: "linear-gradient(90deg,#f97316,#fb923c)",
  color: "#111827",
  cursor: "pointer",
  fontSize: 13,
  fontWeight: 600,
};

const buttonGhost = {
  padding: "8px 14px",
  borderRadius: 999,
  border: "1px solid #4b5563",
  background: "transparent",
  color: "#e5e7eb",
  cursor: "pointer",
  fontSize: 13,
};

const tableWrapper = {
  marginTop: 20,
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

function getStoredAdmin() {
  try {
    return JSON.parse(localStorage.getItem("admin") || "null");
  } catch {
    return null;
  }
}

function getInitials(user) {
  const source = user.fullName || user.username || "U";
  return source
    .split(" ")
    .map((part) => part[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();
}

function getRoleLabel(user) {
  if (user.adminLevel === "super_admin") return "Real admin";
  if (user.role === "admin") return "Admin";
  return "Student";
}

function getRoleStyle(user) {
  if (user.adminLevel === "super_admin") {
    return {
      background: "rgba(249,115,22,0.15)",
      color: "#fed7aa",
      border: "1px solid rgba(249,115,22,0.32)",
    };
  }

  if (user.role === "admin") {
    return {
      background: "rgba(56,189,248,0.14)",
      color: "#bae6fd",
      border: "1px solid rgba(56,189,248,0.32)",
    };
  }

  return {
    background: "rgba(34,197,94,0.13)",
    color: "#bbf7d0",
    border: "1px solid rgba(34,197,94,0.28)",
  };
}

function ActionButton({ children, danger, disabled, ...props }) {
  return (
    <button
      type="button"
      style={{
        ...buttonGhost,
        padding: "4px 10px",
        fontSize: 12,
        marginRight: 6,
        opacity: disabled ? 0.45 : 1,
        cursor: disabled ? "not-allowed" : "pointer",
        ...(danger
          ? {
              borderColor: "#b91c1c",
              color: "#fecaca",
            }
          : {}),
      }}
      disabled={disabled}
      {...props}
    >
      {children}
    </button>
  );
}

export default function StudentsPage({ currentAdmin }) {
  const [students, setStudents] = useState([]);
  const [loading, setLoading]   = useState(true);
  const [error, setError]       = useState("");
  const [notice, setNotice]     = useState("");
  const [form, setForm]         = useState({
    _id: null,
    fullName: "",
    username: "",
    password: "",
    role: "student",
  });
  const [saving, setSaving]     = useState(false);
  const [roleSavingId, setRoleSavingId] = useState(null);
  const [search, setSearch]     = useState("");

  const activeAdmin = currentAdmin || getStoredAdmin();
  const canManageAdmins = activeAdmin?.level === "super_admin";

  const loadStudents = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await api.get("/user/list");
      setStudents(res.data);
    } catch (err) {
      console.error(err);
      setError("Failed to load users");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadStudents();
  }, []);

  const resetForm = () => {
    setForm({
      _id: null,
      fullName: "",
      username: "",
      password: "",
      role: "student",
    });
  };

  const handleEdit = (u) => {
    if ((u.role === "admin" || u.adminLevel) && !canManageAdmins) {
      alert("Only the real admin can edit admin accounts.");
      return;
    }

    setForm({
      _id: u._id,
      fullName: u.fullName || "",
      username: u.username || "",
      password: "",
      role: u.role || "student",
    });
  };

  const handleDelete = async (u) => {
    if ((u.role === "admin" || u.adminLevel) && !canManageAdmins) {
      alert("Only the real admin can delete admin accounts.");
      return;
    }

    if (!window.confirm(`Delete ${u.fullName || u.username}?`)) return;

    try {
      await api.delete(`/user/${u._id}`);
      setNotice("User deleted");
      if (form._id === u._id) resetForm();
      await loadStudents();
    } catch (err) {
      console.error(err);
      alert(err.response?.data || "Error deleting user");
    }
  };

  const handleRoleChange = async (u, nextRole) => {
    if (!canManageAdmins) {
      alert("Only the real admin can change admin roles.");
      return;
    }

    const action = nextRole === "admin" ? "make this user an admin" : "make this admin a student";
    if (!window.confirm(`Are you sure you want to ${action}?`)) return;

    setRoleSavingId(u._id);
    setNotice("");
    try {
      await api.patch(`/user/${u._id}/role`, { role: nextRole });
      setNotice(nextRole === "admin" ? "User promoted to admin" : "Admin changed to student");
      await loadStudents();
    } catch (err) {
      console.error(err);
      alert(err.response?.data || "Error updating role");
    } finally {
      setRoleSavingId(null);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    setNotice("");

    try {
      const payload = {
        fullName: form.fullName.trim(),
        username: form.username.trim(),
      };

      if (form.password.trim()) {
        payload.password = form.password;
      }

      if (form._id) {
        await api.put(`/user/${form._id}`, payload);
        setNotice("User updated");
      } else {
        if (!payload.password) {
          alert("Password is required for a new user");
          return;
        }
        await api.post("/auth/admin/create-user", payload);
        setNotice("Student account created");
      }

      resetForm();
      await loadStudents();
    } catch (err) {
      console.error(err);
      alert(err.response?.data || "Error saving user");
    } finally {
      setSaving(false);
    }
  };

  const handleChange = (field, value) => {
    setForm((prev) => ({ ...prev, [field]: value }));
  };

  const filteredStudents = students.filter((u) => {
    const q = search.trim().toLowerCase();
    if (!q) return true;
    return (
      u.fullName?.toLowerCase().includes(q) ||
      u.username?.toLowerCase().includes(q) ||
      getRoleLabel(u).toLowerCase().includes(q)
    );
  });

  return (
    <div style={{ display: "grid", gridTemplateColumns: "minmax(0, 380px) minmax(0, 1fr)", gap: 20 }}>
      <div className="form-card" style={cardStyle}>
        <div style={{ marginBottom: 12, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <h3 style={{ fontSize: 16, fontWeight: 500, margin: 0 }}>
            {form._id ? "Edit User" : "Add Student"}
          </h3>
          <span
            className="admin-badge"
            style={{
              background: "rgba(34,197,94,0.13)",
              color: "#bbf7d0",
              border: "1px solid rgba(34,197,94,0.28)",
            }}
          >
            {form._id ? getRoleLabel(form) : "Student"}
          </span>
        </div>

        {notice && (
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
            {notice}
          </div>
        )}

        <form onSubmit={handleSubmit} style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <div>
            <label style={labelStyle}>Full Name</label>
            <input
              style={inputStyle}
              value={form.fullName}
              onChange={(e) => handleChange("fullName", e.target.value)}
              required
            />
          </div>

          <div>
            <label style={labelStyle}>Username</label>
            <input
              style={inputStyle}
              value={form.username}
              onChange={(e) => handleChange("username", e.target.value)}
              required
            />
          </div>

          <div>
            <label style={labelStyle}>Password</label>
            <input
              type="password"
              style={inputStyle}
              value={form.password}
              onChange={(e) => handleChange("password", e.target.value)}
              required={!form._id}
              placeholder={form._id ? "Leave blank to keep current" : ""}
            />
          </div>

          <div style={{ display: "flex", gap: 8, marginTop: 4 }}>
            <button type="submit" style={buttonPrimary} disabled={saving}>
              {saving ? "Saving..." : "Save"}
            </button>
            {form._id && (
              <button
                type="button"
                style={buttonGhost}
                onClick={resetForm}
              >
                Cancel
              </button>
            )}
          </div>
        </form>
      </div>

      <div>
        <div className="page-card" style={{ ...cardStyle, marginBottom: 16 }}>
          <div style={{ display: "flex", justifyContent: "space-between", gap: 12, alignItems: "center" }}>
            <div>
              <h3 style={{ fontSize: 16, margin: 0 }}>Users</h3>
              <p style={{ fontSize: 12, color: "#9ca3af", marginTop: 4 }}>
                Student accounts can be promoted to admin by a real admin.
              </p>
            </div>
            <span
              className="admin-badge"
              style={{
                background: canManageAdmins ? "rgba(249,115,22,0.15)" : "rgba(148,163,184,0.12)",
                color: canManageAdmins ? "#fed7aa" : "#cbd5e1",
                border: canManageAdmins ? "1px solid rgba(249,115,22,0.32)" : "1px solid rgba(148,163,184,0.22)",
              }}
            >
              {canManageAdmins ? "Role control on" : "Role control off"}
            </span>
          </div>
          <div style={{ marginTop: 14 }}>
            <label style={labelStyle}>Search users</label>
            <input
              style={inputStyle}
              placeholder="Search by name, username, or role..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </div>

        <div className="table-panel" style={tableWrapper}>
          {loading ? (
            <div style={{ padding: 16 }}>Loading...</div>
          ) : error ? (
            <div style={{ padding: 16, color: "#f87171" }}>{error}</div>
          ) : filteredStudents.length === 0 ? (
            <div style={{ padding: 16 }}>No users found.</div>
          ) : (
            <table className="admin-table" style={tableStyle}>
              <thead>
                <tr style={{ background: "#020617" }}>
                  <th style={{ padding: 10, textAlign: "left", borderBottom: "1px solid #111827" }}>User</th>
                  <th style={{ padding: 10, textAlign: "left", borderBottom: "1px solid #111827" }}>Role</th>
                  <th style={{ padding: 10, textAlign: "left", borderBottom: "1px solid #111827" }}>Created</th>
                  <th style={{ padding: 10, textAlign: "left", borderBottom: "1px solid #111827" }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredStudents.map((u, idx) => {
                  const isAdminUser = u.role === "admin" || Boolean(u.adminLevel);
                  const adminActionDisabled = !canManageAdmins || roleSavingId === u._id;
                  const editDisabled = isAdminUser && !canManageAdmins;
                  const deleteDisabled = isAdminUser && !canManageAdmins;

                  return (
                    <tr
                      key={u._id}
                      style={{
                        background: idx % 2 === 0 ? "#020617" : "#020617",
                      }}
                    >
                      <td style={{ padding: 10, borderBottom: "1px solid #111827" }}>
                        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                          <span className="admin-avatar">{getInitials(u)}</span>
                          <div>
                            <div style={{ fontWeight: 700 }}>{u.fullName}</div>
                            <div style={{ color: "#9ca3af", fontSize: 12 }}>{u.username}</div>
                          </div>
                        </div>
                      </td>
                      <td style={{ padding: 10, borderBottom: "1px solid #111827" }}>
                        <span className="admin-badge" style={getRoleStyle(u)}>
                          {getRoleLabel(u)}
                        </span>
                      </td>
                      <td style={{ padding: 10, borderBottom: "1px solid #111827", color: "#9ca3af" }}>
                        {u.createdAt ? new Date(u.createdAt).toLocaleDateString() : "-"}
                      </td>
                      <td style={{ padding: 10, borderBottom: "1px solid #111827" }}>
                        <ActionButton onClick={() => handleEdit(u)} disabled={editDisabled}>
                          Edit
                        </ActionButton>
                        {isAdminUser ? (
                          <ActionButton
                            onClick={() => handleRoleChange(u, "student")}
                            disabled={adminActionDisabled}
                          >
                            Make Student
                          </ActionButton>
                        ) : (
                          <ActionButton
                            onClick={() => handleRoleChange(u, "admin")}
                            disabled={adminActionDisabled}
                          >
                            Make Admin
                          </ActionButton>
                        )}
                        <ActionButton
                          danger
                          onClick={() => handleDelete(u)}
                          disabled={deleteDisabled}
                        >
                          Delete
                        </ActionButton>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
}
