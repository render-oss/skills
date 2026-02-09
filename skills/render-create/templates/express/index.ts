import express from "express";
import cors from "cors";
import { db } from "./db";
import { users } from "./db/schema";

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

// Example: Get all users
app.get("/users", async (_req, res) => {
  try {
    const allUsers = await db.select().from(users);
    res.json(allUsers);
  } catch (error) {
    console.error("[users] Error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Start server
const host = process.env.HOST ?? "0.0.0.0";
const port = Number(process.env.PORT) || 3000;

app.listen(port, host, () => {
  console.log(`Server running at http://${host}:${port}`);
});
