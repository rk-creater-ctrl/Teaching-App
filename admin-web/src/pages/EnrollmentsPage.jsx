// src/pages/EnrollmentsPage.jsx
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

const tableWrapper = {
  marginTop: 12,
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

const badge = (bg, color) => ({
  display: "inline-block",
  padding: "2px 8px",
  borderRadius: 999,
  fontSize: 11,
  background: bg,
  color,
});

const buttonSmall = {
  padding: "4px 10px",
  borderRadius: 999,
  border: "1px solid #4b5563",
  background: "transparent",
  color: "#e5e7eb",
  cursor: "pointer",
  fontSize: 12,
};

export default function EnrollmentsPage() {
  const [enrollments, setEnrollments] = useState([]);
  const [loading, setLoading]         = useState(true);
  const [error, setError]             = useState("");
  const [search, setSearch]           = useState("");
  const [markingId, setMarkingId]     = useState(null);

  const loadEnrollments = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await api.get("/enrollment/all");
      setEnrollments(res.data);
    } catch (err) {
      console.error(err);
      setError("Failed to load enrollments");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadEnrollments();
  }, []);

  const handleMarkPaid = async (id) => {
    if (!window.confirm("Mark this enrollment as paid and active?")) return;
    setMarkingId(id);
    try {
      await api.post(`/enrollment/mark-paid/${id}`);
      await loadEnrollments();
    } catch (err) {
      console.error(err);
      alert(err.response?.data || "Error marking as paid");
    } finally {
      setMarkingId(null);
    }
  };

  const handleMarkUnpaid = async (id) => {
    if (!window.confirm("Mark this enrollment as unpaid and pending again?")) return;
    setMarkingId(id);
    try {
      await api.post(`/enrollment/mark-unpaid/${id}`);
      await loadEnrollments();
    } catch (err) {
      console.error(err);
      alert(err.response?.data || "Error marking as unpaid");
    } finally {
      setMarkingId(null);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Remove this enrollment?")) return;
    try {
      await api.delete(`/enrollment/${id}`);
      await loadEnrollments();
    } catch (err) {
      console.error(err);
      alert(err.response?.data || "Error deleting enrollment");
    }
  };

  const filtered = enrollments.filter((e) => {
    const q = search.trim().toLowerCase();
    if (!q) return true;
    return (
      e.studentId?.fullName?.toLowerCase().includes(q) ||
      e.studentId?.username?.toLowerCase().includes(q) ||
      e.courseId?.title?.toLowerCase().includes(q)
    );
  });

  return (
    <div>
      <div className="page-card" style={cardStyle}>
        <div style={{ marginBottom: 12 }}>
          <h3 style={{ fontSize: 16, fontWeight: 500 }}>Enrollments</h3>
          <p style={{ fontSize: 12, color: "#9ca3af", marginTop: 4 }}>
            View who applied to which course, their mode and fee status.
          </p>
        </div>

        <div>
          <label style={labelStyle}>Search enrollments</label>
          <input
            style={inputStyle}
            placeholder="Search by student or course..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <div style={{ marginTop: 8, fontSize: 12, color: "#9ca3af" }}>
          Total: {filtered.length} record(s)
        </div>
      </div>

      <div className="table-panel" style={tableWrapper}>
        {loading ? (
          <div style={{ padding: 16 }}>Loading...</div>
        ) : error ? (
          <div style={{ padding: 16, color: "#f87171" }}>{error}</div>
        ) : filtered.length === 0 ? (
          <div style={{ padding: 16 }}>No enrollments found.</div>
        ) : (
          <table className="admin-table" style={tableStyle}>
            <thead>
              <tr style={{ background: "#020617" }}>
                <th style={{ padding: 10, textAlign: "left", borderBottom: "1px solid #111827" }}>Student</th>
                <th style={{ padding: 10, textAlign: "left", borderBottom: "1px solid #111827" }}>Course</th>
                <th style={{ padding: 10, textAlign: "left", borderBottom: "1px solid #111827" }}>Mode</th>
                <th style={{ padding: 10, textAlign: "left", borderBottom: "1px solid #111827" }}>Payment</th>
                <th style={{ padding: 10, textAlign: "left", borderBottom: "1px solid #111827" }}>Pending Fees</th>
                <th style={{ padding: 10, textAlign: "left", borderBottom: "1px solid #111827" }}>Status</th>
                <th style={{ padding: 10, textAlign: "left", borderBottom: "1px solid #111827" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((e, idx) => (
                <tr
                  key={e._id}
                  style={{
                    background: idx % 2 === 0 ? "#020617" : "#020617",
                  }}
                >
                  <td style={{ padding: 10, borderBottom: "1px solid #111827" }}>
                    <div style={{ fontSize: 13 }}>{e.studentId?.fullName}</div>
                    <div style={{ fontSize: 11, color: "#9ca3af" }}>
                      @{e.studentId?.username}
                    </div>
                  </td>
                  <td style={{ padding: 10, borderBottom: "1px solid #111827" }}>
                    {e.courseId?.title}
                  </td>
                  <td style={{ padding: 10, borderBottom: "1px solid #111827" }}>
                    <span
                      style={
                        e.mode === "online"
                          ? badge("#1d4ed8", "#e5e7eb")
                          : badge("#047857", "#ecfdf5")
                      }
                    >
                      {e.mode}
                    </span>
                  </td>
                  <td style={{ padding: 10, borderBottom: "1px solid #111827" }}>
                    <div>
                      <span
                        style={
                          e.paymentStatus === "paid"
                            ? badge("#065f46", "#bbf7d0")
                            : badge("#92400e", "#ffedd5")
                        }
                      >
                        {e.paymentStatus}
                      </span>
                    </div>
                    <div style={{ fontSize: 11, color: "#9ca3af", marginTop: 2 }}>
                      {e.paymentType || "N/A"}
                    </div>
                  </td>
                  <td style={{ padding: 10, borderBottom: "1px solid #111827" }}>
                    {e.paymentStatus === "unpaid" ? e.amount : 0}
                  </td>
                  <td style={{ padding: 10, borderBottom: "1px solid #111827" }}>
                    <span
                      style={
                        e.status === "active"
                          ? badge("#0369a1", "#e0f2fe")
                          : e.status === "completed"
                          ? badge("#15803d", "#dcfce7")
                          : badge("#4b5563", "#e5e7eb")
                      }
                    >
                      {e.status}
                    </span>
                  </td>
                  <td style={{ padding: 10, borderBottom: "1px solid #111827" }}>
                    {e.paymentStatus === "unpaid" ? (
                      <button
                        style={buttonSmall}
                        onClick={() => handleMarkPaid(e._id)}
                        disabled={markingId === e._id}
                      >
                        {markingId === e._id ? "Updating..." : "Mark as Paid"}
                      </button>
                    ) : (
                      <button
                        style={{
                          ...buttonSmall,
                          borderColor: "#eab308",
                          color: "#fef9c3",
                          marginRight: 6,
                        }}
                        onClick={() => handleMarkUnpaid(e._id)}
                        disabled={markingId === e._id}
                      >
                        {markingId === e._id ? "Updating..." : "Mark Unpaid"}
                      </button>
                    )}
                    <button
                      style={{
                        ...buttonSmall,
                        borderColor: "#b91c1c",
                        color: "#fecaca",
                        marginLeft: 6,
                      }}
                      onClick={() => handleDelete(e._id)}
                    >
                      Remove
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
