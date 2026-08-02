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

const statCard = {
  ...cardStyle,
  minHeight: 110,
  display: "flex",
  flexDirection: "column",
  justifyContent: "space-between",
};

function getCount(result) {
  if (result.status !== "fulfilled") return "Error";
  return Array.isArray(result.value.data) ? result.value.data.length : 0;
}

const iconPaths = {
  courses:
    "M4 5.5A2.5 2.5 0 0 1 6.5 3H20v15H6.5A2.5 2.5 0 0 0 4 20.5v-15Zm2.5-.5a.5.5 0 0 0-.5.5v11.56c.17-.04.34-.06.5-.06H18V5H6.5ZM8 8h8v2H8V8Zm0 4h6v2H8v-2Z",
  students:
    "M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8Zm0 2c-4.42 0-8 2.24-8 5v1h16v-1c0-2.76-3.58-5-8-5Zm6.5-3A3.5 3.5 0 1 0 18 4.03a5.94 5.94 0 0 1 0 7.94c.17.02.33.03.5.03Zm.5 2c1.93.62 3 1.7 3 3v1h-2.02c-.29-1.47-1.25-2.77-2.75-3.79.56-.14 1.15-.21 1.77-.21Z",
  enrollments:
    "M5 3h14v18H5V3Zm2 2v14h10V5H7Zm2 3h6v2H9V8Zm0 4h6v2H9v-2Zm0 4h4v2H9v-2Z",
  videos:
    "M4 6.5A2.5 2.5 0 0 1 6.5 4h11A2.5 2.5 0 0 1 20 6.5v11a2.5 2.5 0 0 1-2.5 2.5h-11A2.5 2.5 0 0 1 4 17.5v-11ZM6.5 6a.5.5 0 0 0-.5.5v11a.5.5 0 0 0 .5.5h11a.5.5 0 0 0 .5-.5v-11a.5.5 0 0 0-.5-.5h-11Zm4 3 5 3-5 3V9Z",
  materials:
    "M6 2h9l5 5v15H6V2Zm8 1.5V8h4.5L14 3.5ZM8 11h8v2H8v-2Zm0 4h8v2H8v-2Z",
  revenue:
    "M12 3h8v2h-3.2A5.5 5.5 0 0 1 12 13h-1.2l6.6 8H14.8L8.2 13H5v-2h7a3.5 3.5 0 0 0 3.32-2.4H5v-2h10.32A3.5 3.5 0 0 0 12 5H5V3h7Z",
  live:
    "M4 6h10a2 2 0 0 1 2 2v1.1l4-2.1v10l-4-2.1V16a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2Z",
};

function StatIcon({ name, color }) {
  return (
    <div
      style={{
        width: 42,
        height: 42,
        borderRadius: 12,
        background: `${color}22`,
        border: `1px solid ${color}55`,
        display: "grid",
        placeItems: "center",
      }}
    >
      <svg
        width="23"
        height="23"
        viewBox="0 0 24 24"
        fill={color}
        aria-hidden="true"
      >
        <path d={iconPaths[name]} />
      </svg>
    </div>
  );
}

export default function DashboardPage() {
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    courses: 0,
    students: 0,
    enrollments: 0,
    activeEnrollments: 0,
    pendingEnrollments: 0,
    videos: 0,
    materials: 0,
    revenue: 0,
    live: null,
  });

  useEffect(() => {
    let mounted = true;

    async function loadStats() {
      setLoading(true);
      const statsRes = await api.get("/dashboard/admin").catch(async () => {
        const [courses, students, enrollments, videos] = await Promise.allSettled(
          [
            api.get("/course/list"),
            api.get("/user/list"),
            api.get("/enrollment/all"),
            api.get("/video/all"),
          ]
        );
        return {
          data: {
            courses: getCount(courses),
            students: getCount(students),
            enrollments: getCount(enrollments),
            videos: getCount(videos),
          },
        };
      });

      if (!mounted) return;

      setStats((prev) => ({ ...prev, ...statsRes.data }));
      setLoading(false);
    }

    loadStats();

    return () => {
      mounted = false;
    };
  }, []);

  const cards = [
    { label: "Courses", value: stats.courses, accent: "#22c55e", icon: "courses" },
    { label: "Students", value: stats.students, accent: "#38bdf8", icon: "students" },
    {
      label: "Enrollments",
      value: stats.enrollments,
      accent: "#f97316",
      icon: "enrollments",
    },
    { label: "Videos", value: stats.videos, accent: "#a855f7", icon: "videos" },
    { label: "Notes", value: stats.materials, accent: "#facc15", icon: "materials" },
    { label: "Pending", value: stats.pendingEnrollments, accent: "#fb923c", icon: "enrollments" },
    { label: "Revenue", value: `₹${stats.revenue || 0}`, accent: "#10b981", icon: "revenue" },
    {
      label: "Live",
      value: stats.live?.internal_live_active ? "ON" : "OFF",
      accent: stats.live?.internal_live_active ? "#ef4444" : "#64748b",
      icon: "live",
    },
  ];

  return (
    <div>
      <div className="page-card" style={{ ...cardStyle, marginBottom: 18 }}>
        <h3 style={{ fontSize: 18, fontWeight: 600, margin: 0 }}>
          Dashboard
        </h3>
        <p style={{ fontSize: 13, color: "#9ca3af", marginTop: 6 }}>
          Quick overview of courses, students, enrollments and learning videos.
        </p>
      </div>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))",
          gap: 16,
        }}
      >
        {cards.map((card) => (
          <div key={card.label} className="stat-card" style={statCard}>
            <StatIcon name={card.icon} color={card.accent} />
            <div>
              <div style={{ color: "#9ca3af", fontSize: 13 }}>
                {card.label}
              </div>
              <div
                style={{
                  color: card.accent,
                  fontSize: 30,
                  fontWeight: 700,
                  lineHeight: 1.1,
                  marginTop: 4,
                }}
              >
                {loading ? "..." : card.value}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
