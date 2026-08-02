import { useEffect, useRef, useState } from "react";
import { io } from "socket.io-client";
import api from "../api";
import { API_URL } from "../config";

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

const primaryButton = {
  padding: "9px 14px",
  borderRadius: 999,
  border: "none",
  background: "linear-gradient(90deg,#38bdf8,#22c55e)",
  color: "#03111f",
  cursor: "pointer",
  fontSize: 13,
  fontWeight: 700,
};

const dangerButton = {
  ...primaryButton,
  background: "linear-gradient(90deg,#ef4444,#b91c1c)",
  color: "#fff",
};

const ghostButton = {
  padding: "9px 13px",
  borderRadius: 999,
  border: "1px solid #334155",
  background: "#0f172a",
  color: "#e5e7eb",
  cursor: "pointer",
  fontSize: 13,
  fontWeight: 700,
};

const iconButtonStyles = {
  primary: primaryButton,
  danger: dangerButton,
  ghost: ghostButton,
};

const iconPaths = {
  save: "M5 4h12l2 2v14H5V4Zm2 2v12h10V7.2L15.8 6H15v5H8V6H7Zm3 0v3h3V6h-3Zm-1 8h6v2H9v-2Z",
  play: "M8 5v14l11-7L8 5Z",
  stop: "M6 6h12v12H6V6Z",
  mic: "M12 14a3 3 0 0 0 3-3V5a3 3 0 0 0-6 0v6a3 3 0 0 0 3 3Zm5-3a5 5 0 0 1-10 0H5a7 7 0 0 0 6 6.92V21h2v-3.08A7 7 0 0 0 19 11h-2Z",
  micOff: "M4.7 3.3 3.3 4.7l16 16 1.4-1.4-4.05-4.05A6.96 6.96 0 0 0 19 11h-2c0 .98-.28 1.89-.76 2.66L15 12.42V5a3 3 0 0 0-5.1-2.14L8.46 1.42 7.05 2.83 21.17 16.95l1.41-1.41-1.88-1.88ZM12 14c.31 0 .6-.05.88-.14L9 9.98V11a3 3 0 0 0 3 3Zm-7-3h2a5 5 0 0 0 6.35 4.82l1.55 1.55c-.6.28-1.24.46-1.9.55V21h-2v-3.08A7 7 0 0 1 5 11Z",
  camera: "M4 6h10a2 2 0 0 1 2 2v1.1l4-2.1v10l-4-2.1V16a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2Z",
  cameraOff: "m3.3 2 18.7 18.7-1.4 1.3-3.1-3.1L16 18H4a2 2 0 0 1-2-2V8c0-.7.35-1.32.88-1.68L2 5.42 3.3 4.1ZM4 8v8h10.5L6.5 8H4Zm16-1v8.1l-2.8-1.47L20 16.43V7Zm-6-1a2 2 0 0 1 2 2v2.2L11.8 6H14Z",
  screen: "M3 5h18v11H3V5Zm2 2v7h14V7H5Zm5 11h4v2h-4v-2Z",
  send: "M3 20 21 12 3 4v6l12 2-12 2v6Z",
  clear: "M6 6h12v2H6V6Zm2 4h8l-1 10H9L8 10Zm2 2 .6 6h2.8l.6-6h-4Z",
};

function formatLiveTime(totalSeconds) {
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;
  return [hours, minutes, seconds]
    .map((part) => String(part).padStart(2, "0"))
    .join(":");
}

function formatMessageTime(value) {
  if (!value) return "now";
  try {
    return new Date(value).toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return "now";
  }
}

function getInitials(name = "Class") {
  return String(name)
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part[0])
    .join("")
    .toUpperCase() || "C";
}

function LiveIconButton({
  icon,
  label,
  variant = "ghost",
  disabled = false,
  type = "button",
  onClick,
}) {
  return (
    <button
      type={type}
      className="live-icon-button"
      style={iconButtonStyles[variant]}
      disabled={disabled}
      onClick={onClick}
      title={label}
      aria-label={label}
    >
      <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
        <path d={iconPaths[icon]} />
      </svg>
      <span className="live-tooltip">{label}</span>
    </button>
  );
}

function StudentStreamCard({ item }) {
  const videoRef = useRef(null);

  useEffect(() => {
    if (videoRef.current) {
      videoRef.current.srcObject = item.stream;
    }
  }, [item.stream]);

  return (
    <div
      style={{
        borderRadius: 14,
        overflow: "hidden",
        border: "1px solid #1f2937",
        background: "#020617",
      }}
    >
      <video
        ref={videoRef}
        autoPlay
        playsInline
        controls
        style={{ width: "100%", minHeight: 150, display: "block", background: "#000" }}
      />
      <div style={{ padding: "8px 10px", color: "#cbd5e1", fontSize: 12, fontWeight: 800 }}>
        {item.name} · {item.mediaType === "screen" ? "Screen" : "Camera/Mic"}
      </div>
    </div>
  );
}

function getAdminToken() {
  try {
    const admin = JSON.parse(localStorage.getItem("admin") || "null");
    return admin?.token || "";
  } catch {
    return "";
  }
}

export default function LiveClassPage() {
  const [title, setTitle] = useState("");
  const [scheduledAt, setScheduledAt] = useState("");
  const [courseId, setCourseId] = useState("");
  const [courses, setCourses] = useState([]);
  const [savingMeta, setSavingMeta] = useState(false);
  const [starting, setStarting] = useState(false);
  const [live, setLive] = useState(false);
  const [viewerCount, setViewerCount] = useState(0);
  const [viewers, setViewers] = useState([]);
  const [micEnabled, setMicEnabled] = useState(true);
  const [cameraEnabled, setCameraEnabled] = useState(true);
  const [screenSharing, setScreenSharing] = useState(false);
  const [chatText, setChatText] = useState("");
  const [messages, setMessages] = useState([]);
  const [raisedHands, setRaisedHands] = useState([]);
  const [message, setMessage] = useState("");
  const [messageType, setMessageType] = useState("info");
  const [connectionStatus, setConnectionStatus] = useState("Studio offline");
  const [liveSeconds, setLiveSeconds] = useState(0);
  const [studentMediaStreams, setStudentMediaStreams] = useState([]);

  const localVideoRef = useRef(null);
  const socketRef = useRef(null);
  const localStreamRef = useRef(null);
  const cameraTrackRef = useRef(null);
  const screenTrackRef = useRef(null);
  const peersRef = useRef(new Map());
  const studentMediaPeersRef = useRef(new Map());
  const iceServersRef = useRef([]);

  useEffect(() => {
    api.get("/course/list")
      .then((res) => setCourses(Array.isArray(res.data) ? res.data : []))
      .catch((err) => console.error("Load live courses failed:", err));
  }, []);

  useEffect(() => {
    return () => {
      stopLive({ callApi: false });
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (!live) {
      setLiveSeconds(0);
      return undefined;
    }

    const timer = window.setInterval(() => {
      setLiveSeconds((value) => value + 1);
    }, 1000);

    return () => window.clearInterval(timer);
  }, [live]);

  function showMessage(type, text) {
    setMessageType(type);
    setMessage(text);
  }

  function addMessage(nextMessage) {
    setMessages((prev) => [...prev.slice(-80), nextMessage]);
  }

  async function handleSaveMeta(e) {
    e.preventDefault();
    setSavingMeta(true);
    setMessage("");

    try {
      await api.post("/live-class/admin/save", {
        title,
        courseId: courseId || null,
        scheduledAt: scheduledAt ? new Date(scheduledAt).toISOString() : undefined,
      });
      showMessage("info", "Live class details saved.");
    } catch (err) {
      console.error(err);
      showMessage("error", "Failed to save live class details.");
    } finally {
      setSavingMeta(false);
    }
  }

  function replaceVideoTrack(newTrack) {
    peersRef.current.forEach((peer) => {
      const sender = peer
        .getSenders()
        .find((item) => item.track && item.track.kind === "video");
      if (sender) sender.replaceTrack(newTrack);
    });
  }

  async function createPeerForViewer(viewerId) {
    const stream = localStreamRef.current;
    const socket = socketRef.current;
    if (!stream || !socket || peersRef.current.has(viewerId)) return;

    const peer = new RTCPeerConnection({ iceServers: iceServersRef.current });
    peersRef.current.set(viewerId, peer);
    setViewerCount(peersRef.current.size);

    stream.getTracks().forEach((track) => peer.addTrack(track, stream));

    peer.onicecandidate = (event) => {
      if (event.candidate) {
        socket.emit("internal-live:candidate", {
          to: viewerId,
          candidate: event.candidate,
        });
      }
    };

    peer.onconnectionstatechange = () => {
      if (["failed", "closed", "disconnected"].includes(peer.connectionState)) {
        peer.close();
        peersRef.current.delete(viewerId);
        setViewerCount(peersRef.current.size);
      }
    };

    const offer = await peer.createOffer();
    await peer.setLocalDescription(offer);
    socket.emit("internal-live:offer", { to: viewerId, offer });
  }

  async function startLive() {
    setStarting(true);
    setMessage("");

    try {
      if (!navigator.mediaDevices?.getUserMedia) {
        throw new Error("Camera and microphone are not available in this browser");
      }

      const res = await api.post("/live-class/admin/start-internal", {
        title: title || "Live class",
        courseId: courseId || null,
      });
      const roomCode = res.data.liveClass.internalRoomCode;
      iceServersRef.current = Array.isArray(res.data.iceServers)
        ? res.data.iceServers
        : [];

      const stream = await navigator.mediaDevices.getUserMedia({
        video: true,
        audio: true,
      });

      localStreamRef.current = stream;
      cameraTrackRef.current = stream.getVideoTracks()[0] || null;

      if (localVideoRef.current) {
        localVideoRef.current.srcObject = stream;
      }

      const socket = io(API_URL, { transports: ["websocket", "polling"] });
      socketRef.current = socket;

      socket.on("connect", () => {
        setConnectionStatus("Connected to live server");
        socket.emit("internal-live:broadcaster-start", {
          token: getAdminToken(),
          roomCode,
        });
      });

      socket.on("internal-live:broadcaster-ready", () => {
        setLive(true);
        setConnectionStatus("Broadcasting to students");
        showMessage("info", "Live class started.");
      });

      socket.on("internal-live:viewer-joined", ({ viewerId, name }) => {
        setViewers((prev) => {
          if (prev.some((item) => item.viewerId === viewerId)) return prev;
          return [
            ...prev,
            {
              viewerId,
              name: name || "Student",
              permissions: { mic: false, camera: false, screen: false },
            },
          ];
        });
        addMessage({
          name: "Class",
          text: `${name || "A student"} joined.`,
        });
        createPeerForViewer(viewerId).catch((err) => {
          console.error("Create viewer peer error:", err);
        });
      });

      socket.on("internal-live:viewer-left", ({ viewerId, name }) => {
        const peer = peersRef.current.get(viewerId);
        if (peer) peer.close();
        peersRef.current.delete(viewerId);
        const mediaPeer = studentMediaPeersRef.current.get(viewerId);
        if (mediaPeer) mediaPeer.close();
        studentMediaPeersRef.current.delete(viewerId);
        setViewerCount(peersRef.current.size);
        setViewers((prev) => prev.filter((item) => item.viewerId !== viewerId));
        setStudentMediaStreams((prev) => prev.filter((item) => item.viewerId !== viewerId));
        addMessage({
          name: "Class",
          text: `${name || "A student"} left.`,
        });
      });

      socket.on("internal-live:answer", async ({ from, answer }) => {
        const peer = peersRef.current.get(from);
        if (!peer) return;
        await peer.setRemoteDescription(new RTCSessionDescription(answer));
      });

      socket.on("internal-live:candidate", async ({ from, candidate }) => {
        const peer = peersRef.current.get(from);
        if (!peer || !candidate) return;
        try {
          await peer.addIceCandidate(new RTCIceCandidate(candidate));
        } catch (err) {
          console.error("Broadcaster candidate error:", err);
        }
      });

      socket.on("internal-live:chat-message", (nextMessage) => {
        addMessage(nextMessage);
      });

      socket.on("internal-live:hand-raised", ({ viewerId, name }) => {
        setRaisedHands((prev) => {
          if (prev.some((item) => item.viewerId === viewerId)) return prev;
          return [...prev, { viewerId, name: name || "Student" }];
        });
        addMessage({
          name: "Class",
          text: `${name || "A student"} raised their hand.`,
        });
      });

      socket.on("internal-live:student-media-offer", async ({ from, name, offer, mediaType }) => {
        try {
          const peer = new RTCPeerConnection({ iceServers: iceServersRef.current });
          studentMediaPeersRef.current.set(from, peer);

          peer.ontrack = (event) => {
            const stream = event.streams[0];
            setStudentMediaStreams((prev) => {
              const next = prev.filter((item) => item.viewerId !== from);
              return [
                ...next,
                {
                  viewerId: from,
                  name: name || "Student",
                  mediaType: mediaType || "camera",
                  stream,
                },
              ];
            });
          };

          peer.onicecandidate = (event) => {
            if (event.candidate) {
              socket.emit("internal-live:student-media-candidate", {
                to: from,
                candidate: event.candidate,
              });
            }
          };

          await peer.setRemoteDescription(new RTCSessionDescription(offer));
          const answer = await peer.createAnswer();
          await peer.setLocalDescription(answer);
          socket.emit("internal-live:student-media-answer", { to: from, answer });
        } catch (err) {
          console.error("Student media offer failed:", err);
        }
      });

      socket.on("internal-live:student-media-candidate", async ({ from, candidate }) => {
        const peer = studentMediaPeersRef.current.get(from);
        if (!peer || !candidate) return;
        try {
          await peer.addIceCandidate(new RTCIceCandidate(candidate));
        } catch (err) {
          console.error("Student media candidate error:", err);
        }
      });

      socket.on("internal-live:student-media-stopped", ({ viewerId }) => {
        const peer = studentMediaPeersRef.current.get(viewerId);
        if (peer) peer.close();
        studentMediaPeersRef.current.delete(viewerId);
        setStudentMediaStreams((prev) => prev.filter((item) => item.viewerId !== viewerId));
      });

      socket.on("internal-live:error", ({ message: socketMessage }) => {
        setConnectionStatus("Live connection needs attention");
        showMessage("error", socketMessage || "Live connection failed.");
      });
    } catch (err) {
      console.error(err);
      showMessage("error", err.message || "Failed to start live class.");
      await stopLive({ callApi: true });
    } finally {
      setStarting(false);
    }
  }

  async function stopLive({ callApi = true } = {}) {
    peersRef.current.forEach((peer) => peer.close());
    peersRef.current.clear();
    studentMediaPeersRef.current.forEach((peer) => peer.close());
    studentMediaPeersRef.current.clear();
    setViewerCount(0);
    setViewers([]);
    setRaisedHands([]);
    setStudentMediaStreams([]);

    if (socketRef.current) {
      socketRef.current.disconnect();
      socketRef.current = null;
    }

    if (screenTrackRef.current) {
      const screenTrack = screenTrackRef.current;
      screenTrackRef.current = null;
      screenTrack.onended = null;
      screenTrack.stop();
    }

    if (localStreamRef.current) {
      localStreamRef.current.getTracks().forEach((track) => track.stop());
      localStreamRef.current = null;
    }

    cameraTrackRef.current = null;
    setScreenSharing(false);

    if (localVideoRef.current) {
      localVideoRef.current.srcObject = null;
    }

    setLive(false);
    setConnectionStatus("Studio offline");

    if (callApi) {
      try {
        await api.post("/live-class/admin/end-internal");
        showMessage("info", "Live class ended.");
      } catch (err) {
        console.error(err);
        showMessage("error", "Live stopped locally, but backend end failed.");
      }
    }
  }

  function toggleMic() {
    const stream = localStreamRef.current;
    if (!stream) return;

    const next = !micEnabled;
    stream.getAudioTracks().forEach((track) => {
      track.enabled = next;
    });
    setMicEnabled(next);
  }

  function toggleCamera() {
    const stream = localStreamRef.current;
    if (!stream || screenSharing) return;

    const next = !cameraEnabled;
    stream.getVideoTracks().forEach((track) => {
      track.enabled = next;
    });
    setCameraEnabled(next);
  }

  async function startScreenShare() {
    if (!localStreamRef.current || screenSharing) return;

    try {
      const displayStream = await navigator.mediaDevices.getDisplayMedia({
        video: true,
        audio: false,
      });
      const screenTrack = displayStream.getVideoTracks()[0];
      if (!screenTrack) return;

      const stream = localStreamRef.current;
      stream.getVideoTracks().forEach((track) => {
        stream.removeTrack(track);
        track.stop();
      });
      stream.addTrack(screenTrack);
      screenTrackRef.current = screenTrack;
      replaceVideoTrack(screenTrack);

      if (localVideoRef.current) {
        localVideoRef.current.srcObject = stream;
      }

      screenTrack.onended = () => {
        stopScreenShare().catch((err) => console.error(err));
      };

      setScreenSharing(true);
    } catch (err) {
      console.error(err);
      showMessage("error", "Screen share was cancelled or blocked.");
    }
  }

  async function stopScreenShare() {
    const stream = localStreamRef.current;
    if (!stream || !screenSharing) return;

    if (screenTrackRef.current) {
      const screenTrack = screenTrackRef.current;
      screenTrackRef.current = null;
      screenTrack.onended = null;
      screenTrack.stop();
    }

    const cameraStream = await navigator.mediaDevices.getUserMedia({ video: true });
    const cameraTrack = cameraStream.getVideoTracks()[0];
    cameraTrack.enabled = cameraEnabled;
    cameraTrackRef.current = cameraTrack;

    stream.getVideoTracks().forEach((track) => stream.removeTrack(track));
    stream.addTrack(cameraTrack);
    replaceVideoTrack(cameraTrack);

    if (localVideoRef.current) {
      localVideoRef.current.srcObject = stream;
    }

    setScreenSharing(false);
  }

  function sendChat(e) {
    e.preventDefault();
    const text = chatText.trim();
    if (!text || !socketRef.current) return;

    socketRef.current.emit("internal-live:chat-message", {
      text,
      name: "Teacher",
    });
    setChatText("");
  }

  function setStudentPermission(viewerId, permission, value) {
    setViewers((prev) =>
      prev.map((viewer) =>
        viewer.viewerId === viewerId
          ? {
              ...viewer,
              permissions: {
                ...viewer.permissions,
                [permission]: value,
              },
            }
          : viewer
      )
    );

    const nextViewer = viewers.find((viewer) => viewer.viewerId === viewerId);
    const nextPermissions = {
      mic: nextViewer?.permissions?.mic === true,
      camera: nextViewer?.permissions?.camera === true,
      screen: nextViewer?.permissions?.screen === true,
      [permission]: value,
    };

    socketRef.current?.emit("internal-live:set-student-permissions", {
      viewerId,
      permissions: nextPermissions,
    });
  }

  return (
    <div>
      <div
        className="page-card"
        style={{
          ...cardStyle,
          marginBottom: 18,
          background:
            "linear-gradient(135deg, rgba(15,23,42,.98), rgba(7,17,31,.98) 48%, rgba(127,29,29,.34))",
          border: "1px solid rgba(148,163,184,.18)",
        }}
      >
        <div style={{ display: "flex", justifyContent: "space-between", gap: 16, alignItems: "flex-start" }}>
          <div>
            <div style={{ color: "#38bdf8", fontSize: 12, fontWeight: 900, letterSpacing: ".14em", textTransform: "uppercase" }}>
              Host Studio
            </div>
            <h3 style={{ fontSize: 24, fontWeight: 800, margin: "6px 0 0" }}>
              Live Class Control Panel
            </h3>
            <p style={{ color: "#9ca3af", fontSize: 13, marginTop: 6 }}>
              Start app-only live classes, manage camera/mic, watch students join, and answer doubts from one place.
            </p>
          </div>
          <span
            className="admin-badge"
            style={{
              background: live ? "rgba(239,68,68,0.16)" : "rgba(56,189,248,0.14)",
              color: live ? "#fecaca" : "#bae6fd",
              border: "1px solid rgba(148,163,184,0.18)",
            }}
          >
            {live ? "LIVE" : "OFFLINE"}
          </span>
        </div>

        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(4, minmax(130px, 1fr))",
            gap: 12,
            marginTop: 18,
          }}
        >
          {[
            { label: "Stream time", value: live ? formatLiveTime(liveSeconds) : "00:00:00", color: "#f87171" },
            { label: "Viewers", value: viewerCount, color: "#38bdf8" },
            { label: "Raised hands", value: raisedHands.length, color: "#f59e0b" },
            { label: "Studio status", value: connectionStatus, color: live ? "#22c55e" : "#94a3b8" },
          ].map((item) => (
            <div
              key={item.label}
              style={{
                padding: 14,
                borderRadius: 16,
                background: "rgba(2,6,23,.56)",
                border: "1px solid rgba(148,163,184,.14)",
              }}
            >
              <div style={{ color: "#94a3b8", fontSize: 11, fontWeight: 800, textTransform: "uppercase" }}>
                {item.label}
              </div>
              <div style={{ color: item.color, fontSize: 18, fontWeight: 900, marginTop: 5 }}>
                {item.value}
              </div>
            </div>
          ))}
        </div>
      </div>

      {message && (
        <div
          className="page-card"
          style={{
            marginBottom: 18,
            padding: "10px 12px",
            borderRadius: 12,
            color: messageType === "error" ? "#fecaca" : "#bbf7d0",
            background:
              messageType === "error"
                ? "rgba(127,29,29,0.38)"
                : "rgba(5,46,22,0.38)",
          }}
        >
          {message}
        </div>
      )}

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "minmax(320px, 1.6fr) minmax(300px, 0.9fr)",
          gap: 18,
        }}
      >
        <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
          <div className="form-card" style={cardStyle}>
            <div style={{ display: "flex", justifyContent: "space-between", gap: 12 }}>
              <div>
                <h4 style={{ fontSize: 15, margin: 0 }}>Class Setup</h4>
                <p style={{ color: "#94a3b8", fontSize: 12, margin: "4px 0 0" }}>
                  Set the title students will see before going live.
                </p>
              </div>
              <span style={{ color: title.trim() ? "#86efac" : "#fca5a5", fontSize: 12, fontWeight: 800 }}>
                {title.trim() ? "Ready" : "Title needed"}
              </span>
            </div>
            <form
              onSubmit={handleSaveMeta}
              style={{
                display: "grid",
                gridTemplateColumns: "minmax(0, 1fr) minmax(0, 220px) minmax(0, 220px) auto",
                gap: 12,
                marginTop: 14,
                alignItems: "end",
              }}
            >
              <div>
                <label style={labelStyle}>Live class heading</label>
                <input
                  type="text"
                  style={inputStyle}
                  placeholder="Live Physics Doubt Session"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  required
                />
              </div>
              <div>
                <label style={labelStyle}>Who can join?</label>
                <select
                  style={inputStyle}
                  value={courseId}
                  disabled={live}
                  onChange={(e) => setCourseId(e.target.value)}
                >
                  <option value="">All enrolled students</option>
                  {courses.map((course) => (
                    <option key={course._id || course.id} value={course._id || course.id}>
                      {course.title}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label style={labelStyle}>Scheduled time</label>
                <input
                  type="datetime-local"
                  style={inputStyle}
                  value={scheduledAt}
                  onChange={(e) => setScheduledAt(e.target.value)}
                />
              </div>
              <LiveIconButton
                type="submit"
                icon="save"
                label={savingMeta ? "Saving" : "Save Details"}
                variant="primary"
                disabled={savingMeta}
              />
            </form>
          </div>

          <div className="form-card" style={cardStyle}>
            <div
              style={{
                position: "relative",
                borderRadius: 18,
                overflow: "hidden",
                border: "1px solid #1f2937",
                background: "#020617",
              }}
            >
              <video
                ref={localVideoRef}
                autoPlay
                muted
                playsInline
                style={{
                  width: "100%",
                  minHeight: 380,
                  display: "block",
                  objectFit: "cover",
                  background: "#020617",
                }}
              />
              <div
                style={{
                  position: "absolute",
                  left: 14,
                  top: 14,
                  display: "flex",
                  gap: 8,
                  alignItems: "center",
                }}
              >
                <span
                  style={{
                    padding: "6px 10px",
                    borderRadius: 999,
                    background: live ? "rgba(220,38,38,.88)" : "rgba(15,23,42,.82)",
                    color: "#fff",
                    fontSize: 11,
                    fontWeight: 900,
                    letterSpacing: ".08em",
                  }}
                >
                  {live ? "● LIVE" : "PREVIEW"}
                </span>
                {screenSharing && (
                  <span style={{ padding: "6px 10px", borderRadius: 999, background: "rgba(8,47,73,.86)", color: "#bae6fd", fontSize: 11, fontWeight: 900 }}>
                    SCREEN SHARE
                  </span>
                )}
              </div>
              {!live && (
                <div
                  style={{
                    position: "absolute",
                    inset: 0,
                    display: "grid",
                    placeItems: "center",
                    pointerEvents: "none",
                    background: "linear-gradient(180deg, transparent, rgba(2,6,23,.55))",
                  }}
                >
                  <div style={{ textAlign: "center", color: "#94a3b8", fontSize: 13 }}>
                    Camera preview will appear after you start live.
                  </div>
                </div>
              )}
            </div>

            <div
              style={{
                display: "flex",
                gap: 8,
                flexWrap: "wrap",
                marginTop: 14,
                alignItems: "center",
              }}
            >
              {!live ? (
                <LiveIconButton
                  icon="play"
                  label={starting ? "Starting Live" : "Start Live"}
                  variant="primary"
                  disabled={starting}
                  onClick={startLive}
                />
              ) : (
                <LiveIconButton
                  icon="stop"
                  label="End Live"
                  variant="danger"
                  onClick={() => stopLive({ callApi: true })}
                />
              )}
              <LiveIconButton
                icon={micEnabled ? "mic" : "micOff"}
                label={micEnabled ? "Mute Mic" : "Unmute Mic"}
                disabled={!live}
                onClick={toggleMic}
              />
              <LiveIconButton
                icon={cameraEnabled ? "camera" : "cameraOff"}
                label={cameraEnabled ? "Camera Off" : "Camera On"}
                disabled={!live || screenSharing}
                onClick={toggleCamera}
              />
              {!screenSharing ? (
                <LiveIconButton
                  icon="screen"
                  label="Share Screen"
                  disabled={!live}
                  onClick={startScreenShare}
                />
              ) : (
                <LiveIconButton
                  icon="screen"
                  label="Stop Screen Share"
                  onClick={stopScreenShare}
                />
              )}
              <span style={{ marginLeft: "auto", color: "#9ca3af", fontSize: 13 }}>
                {micEnabled ? "Mic on" : "Mic muted"} · {cameraEnabled ? "Camera on" : "Camera off"} · Viewers: {viewerCount}
              </span>
            </div>
          </div>

          <div className="form-card" style={cardStyle}>
            <h4 style={{ fontSize: 15, margin: 0 }}>Host Checklist</h4>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 10, marginTop: 12 }}>
              {[
                { label: "Class title", ready: Boolean(title.trim()) },
                { label: "Camera permission", ready: Boolean(localStreamRef.current) || live },
                { label: "Students notified", ready: live },
              ].map((item) => (
                <div
                  key={item.label}
                  style={{
                    padding: "10px 12px",
                    borderRadius: 14,
                    background: item.ready ? "rgba(5,46,22,.45)" : "rgba(30,41,59,.52)",
                    border: `1px solid ${item.ready ? "rgba(34,197,94,.28)" : "rgba(148,163,184,.16)"}`,
                    color: item.ready ? "#bbf7d0" : "#cbd5e1",
                    fontSize: 12,
                    fontWeight: 800,
                  }}
                >
                  {item.ready ? "✓" : "○"} {item.label}
                </div>
              ))}
            </div>
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
          <div className="form-card" style={cardStyle}>
            <h4 style={{ fontSize: 15, margin: 0 }}>Student Access Control</h4>
            <p style={{ color: "#94a3b8", fontSize: 12, margin: "4px 0 0" }}>
              Students cannot use mic, camera, or screen share until you allow it here.
            </p>
            <div style={{ marginTop: 12, display: "flex", flexDirection: "column", gap: 10 }}>
              {viewers.length === 0 ? (
                <div style={{ color: "#9ca3af", fontSize: 13 }}>No students connected yet.</div>
              ) : (
                viewers.map((viewer) => (
                  <div
                    key={viewer.viewerId}
                    style={{
                      padding: 10,
                      borderRadius: 14,
                      background: "#020617",
                      border: "1px solid #1f2937",
                    }}
                  >
                    <div style={{ fontWeight: 800, marginBottom: 8 }}>{viewer.name}</div>
                    <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                      {[
                        ["mic", "Mic"],
                        ["camera", "Camera"],
                        ["screen", "Screen"],
                      ].map(([permission, label]) => {
                        const allowed = viewer.permissions?.[permission] === true;
                        return (
                          <button
                            key={permission}
                            type="button"
                            onClick={() => setStudentPermission(viewer.viewerId, permission, !allowed)}
                            style={{
                              ...ghostButton,
                              padding: "7px 10px",
                              background: allowed ? "rgba(34,197,94,.18)" : "#0f172a",
                              color: allowed ? "#bbf7d0" : "#e5e7eb",
                              borderColor: allowed ? "rgba(34,197,94,.35)" : "#334155",
                            }}
                          >
                            {allowed ? "Allowed" : "Allow"} {label}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>

          {studentMediaStreams.length > 0 && (
            <div className="form-card" style={cardStyle}>
              <h4 style={{ fontSize: 15, margin: 0 }}>Student Shared Media</h4>
              <div style={{ display: "grid", gap: 10, marginTop: 12 }}>
                {studentMediaStreams.map((item) => (
                  <StudentStreamCard key={item.viewerId} item={item} />
                ))}
              </div>
            </div>
          )}

          <div className="form-card" style={cardStyle}>
            <h4 style={{ fontSize: 15, margin: 0 }}>Raised Hands</h4>
            <div style={{ marginTop: 12, display: "flex", flexDirection: "column", gap: 8 }}>
              {raisedHands.length === 0 ? (
                <div style={{ color: "#9ca3af", fontSize: 13 }}>No hands raised.</div>
              ) : (
                raisedHands.map((item) => (
                  <div
                    key={item.viewerId}
                    style={{
                      display: "flex",
                      justifyContent: "space-between",
                      gap: 10,
                      padding: "8px 10px",
                      borderRadius: 10,
                      background: "#020617",
                      border: "1px solid #1f2937",
                    }}
                  >
                    <span>{item.name}</span>
                    <LiveIconButton
                      icon="clear"
                      label="Clear Hand"
                      onClick={() =>
                        setRaisedHands((prev) =>
                          prev.filter((hand) => hand.viewerId !== item.viewerId)
                        )
                      }
                    />
                  </div>
                ))
              )}
            </div>
          </div>

          <div className="form-card" style={{ ...cardStyle, minHeight: 420, display: "flex", flexDirection: "column" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 12 }}>
              <div>
                <h4 style={{ fontSize: 15, margin: 0 }}>Live Comments</h4>
                <p style={{ color: "#94a3b8", fontSize: 12, margin: "4px 0 0" }}>
                  YouTube-style doubt section for students.
                </p>
              </div>
              <span style={{ color: "#94a3b8", fontSize: 12 }}>{messages.length} comments</span>
            </div>
            <div
              style={{
                flex: 1,
                overflowY: "auto",
                marginTop: 12,
                display: "flex",
                flexDirection: "column",
                gap: 14,
                minHeight: 260,
              }}
            >
              {messages.length === 0 ? (
                <div
                  style={{
                    color: "#9ca3af",
                    fontSize: 13,
                    padding: 18,
                    borderRadius: 14,
                    background: "#020617",
                    border: "1px dashed #334155",
                    textAlign: "center",
                  }}
                >
                  No comments yet. When students ask doubts, they will appear here.
                </div>
              ) : (
                messages.map((item, index) => (
                  <div
                    key={item.id || index}
                    style={{
                      display: "grid",
                      gridTemplateColumns: "36px 1fr",
                      gap: 10,
                    }}
                  >
                    <div
                      style={{
                        width: 36,
                        height: 36,
                        borderRadius: "50%",
                        display: "grid",
                        placeItems: "center",
                        background:
                          item.role === "broadcaster"
                            ? "linear-gradient(135deg,#38bdf8,#22c55e)"
                            : "linear-gradient(135deg,#334155,#0f172a)",
                        color: item.role === "broadcaster" ? "#03111f" : "#e5e7eb",
                        fontSize: 12,
                        fontWeight: 900,
                      }}
                    >
                      {getInitials(item.name)}
                    </div>
                    <div>
                      <div style={{ display: "flex", alignItems: "center", gap: 7, flexWrap: "wrap" }}>
                        <span style={{ color: "#e5e7eb", fontSize: 13, fontWeight: 800 }}>
                          {item.name || "Class"}
                        </span>
                        {item.role === "broadcaster" && (
                          <span style={{ color: "#03111f", background: "#38bdf8", borderRadius: 999, padding: "2px 7px", fontSize: 10, fontWeight: 900 }}>
                            TEACHER
                          </span>
                        )}
                        <span style={{ color: "#64748b", fontSize: 11 }}>
                          {formatMessageTime(item.createdAt)}
                        </span>
                      </div>
                      <div style={{ color: "#d1d5db", fontSize: 13, marginTop: 3, lineHeight: 1.45 }}>
                        {item.text}
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>
            <form onSubmit={sendChat} style={{ display: "flex", gap: 8, marginTop: 12 }}>
              <input
                style={inputStyle}
                value={chatText}
                onChange={(e) => setChatText(e.target.value)}
                placeholder="Message students..."
              />
              <LiveIconButton
                type="submit"
                icon="send"
                label="Send Message"
                variant="primary"
                disabled={!live || !chatText.trim()}
              />
            </form>
          </div>
        </div>
      </div>
    </div>
  );
}
