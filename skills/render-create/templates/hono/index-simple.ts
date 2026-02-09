import { Hono } from "hono";
import { cors } from "hono/cors";
import { serve } from "@hono/node-server";

const app = new Hono();

// Middleware
app.use("*", cors());

// Health check endpoint
app.get("/health", (c) => {
  return c.json({ status: "ok" });
});

// API routes
app.get("/api/hello", (c) => {
  return c.json({
    message: "Hello from Hono!",
    timestamp: new Date().toISOString(),
  });
});

// Start server
const host = process.env.HOST || "0.0.0.0";
const port = parseInt(process.env.PORT || "3000", 10);

console.log(`Server running at http://${host}:${port}`);

serve({
  fetch: app.fetch,
  hostname: host,
  port,
});
