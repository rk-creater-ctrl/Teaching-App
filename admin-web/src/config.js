// Set VITE_API_URL in Vercel to your Render service URL.
// The hosted Vercel app also has a safe default so API calls never go to
// the frontend domain by mistake.
const DEFAULT_API_URL =
  typeof window !== "undefined" &&
  window.location.hostname !== "localhost" &&
  window.location.hostname !== "127.0.0.1"
    ? "https://backend-7sek.onrender.com"
    : "http://localhost:3000";

export const API_URL = (import.meta.env.VITE_API_URL || DEFAULT_API_URL).replace(
  /\/$/,
  ""
);

export function normalizeAssetUrl(url) {
  if (!url) return "";
  if (typeof window !== "undefined" && window.location.protocol === "https:") {
    return String(url).replace(/^http:\/\//i, "https://");
  }
  return String(url);
}


// also expose globally for simple fetch() usage
if (typeof window !== "undefined") {
  window.API_URL = API_URL;
}
