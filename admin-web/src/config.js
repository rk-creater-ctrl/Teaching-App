// Set VITE_API_URL in Vercel to your Render service URL.
export const API_URL = (
  import.meta.env.VITE_API_URL || "http://localhost:3000"
).replace(/\/$/, "");


// also expose globally for simple fetch() usage
if (typeof window !== "undefined") {
  window.API_URL = API_URL;
}
