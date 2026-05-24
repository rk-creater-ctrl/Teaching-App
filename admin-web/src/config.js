// src/config.js
export const API_URL = "http://localhost:3000"; // your Node backend


// also expose globally for simple fetch() usage
if (typeof window !== "undefined") {
  window.API_URL = API_URL;
}
