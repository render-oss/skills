import { Hono } from "hono";
import { cors } from "hono/cors";
import { serve } from "@hono/node-server";
import { db } from "./db";
import { users } from "./db/schema";

const app = new Hono();

// Middleware
app.use("*", cors());

// Health check endpoint
app.get("/health", (c) => {
  return c.json({ status: "ok" });
});

// Example: Get all users
app.get("/users", async (c) => {
  try {
    const allUsers = await db.select().from(users);
    return c.json(allUsers);
  } catch (error) {
    console.error("[users] Error:", error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

// Start server
const host = process.env.HOST ?? "0.0.0.0";
const port = Number(process.env.PORT) || 3000;

console.log(`Server running at http://${host}:${port}`);

serve({
  fetch: app.fetch,
  hostname: host,
  port,
});
