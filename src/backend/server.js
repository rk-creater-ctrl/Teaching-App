// Shim for Render deployments.
// Render is attempting to start `src/backend/server.js` in the deployed filesystem.
// Your actual server entry lives at `backend/server.js` at repo root.

require("../../backend/server.js");

