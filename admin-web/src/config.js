// Set VITE_API_URL in Vercel to your Render service URL.
export const API_URL = (
  import.meta.env.VITE_API_URL || "http://localhost:3000"
).replace(/\/$/, "");

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
