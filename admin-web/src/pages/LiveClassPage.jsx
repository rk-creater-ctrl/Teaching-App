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
  const [savingMeta, setSavingMeta] = useState(false);
  const [starting, setStarting] = useState(false);
  const [live, setLive] = useState(false);
  const [viewerCount, setViewerCount] = useState(0);
  const [micEnabled, setMicEnabled] = useState(true);
  const [cameraEnabled, setCameraEnabled] = useState(true);
  const [screenSharing, setScreenSharing] = useState(false);
  const [chatText, setChatText] = useState("");
  const [messages, setMessages] = useState([]);
  const [raisedHands, setRaisedHands] = useState([]);
  const [message, setMessage] = useState("");
  const [messageType, setMessageType] = useState("info");

  const localVideoRef = useRef(null);
  const socketRef = useRef(null);
  const localStreamRef = useRef(null);
  const cameraTrackRef = useRef(null);
  const screenTrackRef = useRef(null);
  const peersRef = useRef(new Map());
  const iceServersRef = useRef([]);

  useEffect(() => {
    return () => {
      stopLive({ callApi: false });
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

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
        socket.emit("internal-live:broadcaster-start", {
          token: getAdminToken(),
          roomCode,
        });
      });

      socket.on("internal-live:broadcaster-ready", () => {
        setLive(true);
        showMessage("info", "Live class started.");
      });

      socket.on("internal-live:viewer-joined", ({ viewerId, name }) => {
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
        setViewerCount(peersRef.current.size);
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

      socket.on("internal-live:error", ({ message: socketMessage }) => {
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
    setViewerCount(0);
    setRaisedHands([]);

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

  return (
    <div>
      <div className="page-card" style={{ ...cardStyle, marginBottom: 18 }}>
        <div style={{ display: "flex", justifyContent: "space-between", gap: 16 }}>
          <div>
            <h3 style={{ fontSize: 18, fontWeight: 600, margin: 0 }}>
              Live Class
            </h3>
            <p style={{ color: "#9ca3af", fontSize: 13, marginTop: 6 }}>
              Broadcast inside the student app with chat and raise-hand.
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
            <h4 style={{ fontSize: 15, margin: 0 }}>Class Details</h4>
            <form
              onSubmit={handleSaveMeta}
              style={{
                display: "grid",
                gridTemplateColumns: "minmax(0, 1fr) minmax(0, 220px) auto",
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
            <video
              ref={localVideoRef}
              autoPlay
              muted
              playsInline
              style={{
                width: "100%",
                minHeight: 360,
                borderRadius: 14,
                objectFit: "cover",
                background: "#020617",
                border: "1px solid #1f2937",
              }}
            />

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
                Viewers: {viewerCount}
              </span>
            </div>
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
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
            <h4 style={{ fontSize: 15, margin: 0 }}>Class Chat</h4>
            <div
              style={{
                flex: 1,
                overflowY: "auto",
                marginTop: 12,
                display: "flex",
                flexDirection: "column",
                gap: 8,
                minHeight: 260,
              }}
            >
              {messages.length === 0 ? (
                <div style={{ color: "#9ca3af", fontSize: 13 }}>No messages yet.</div>
              ) : (
                messages.map((item, index) => (
                  <div
                    key={item.id || index}
                    style={{
                      padding: "8px 10px",
                      borderRadius: 12,
                      background: item.role === "broadcaster" ? "#082f49" : "#020617",
                      border: "1px solid #1f2937",
                    }}
                  >
                    <div style={{ color: "#38bdf8", fontSize: 12, fontWeight: 700 }}>
                      {item.name || "Class"}
                    </div>
                    <div style={{ fontSize: 13 }}>{item.text}</div>
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
