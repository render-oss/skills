import express from "express";
import cors from "cors";

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

// API routes
app.get("/api/hello", (_req, res) => {
  res.json({
    message: "Hello from Express!",
    timestamp: new Date().toISOString(),
  });
});

// Start server
const host = process.env.HOST || "0.0.0.0";
const port = parseInt(process.env.PORT || "3000", 10);

app.listen(port, host, () => {
  console.log(`Server running at http://${host}:${port}`);
});
