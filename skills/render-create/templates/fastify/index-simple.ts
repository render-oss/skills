import Fastify from "fastify";
import cors from "@fastify/cors";

const fastify = Fastify({
  logger: true,
});

// Register CORS
await fastify.register(cors, {
  origin: process.env.CORS_ORIGIN || "*",
});

// Health check endpoint
fastify.get("/health", async () => {
  return { status: "ok" };
});

// API routes
fastify.get("/api/hello", async () => {
  return {
    message: "Hello from Fastify!",
    timestamp: new Date().toISOString(),
  };
});

// Start server
const start = async () => {
  try {
    const host = process.env.HOST || "0.0.0.0";
    const port = parseInt(process.env.PORT || "3000", 10);
    await fastify.listen({ port, host });
    console.log(`Server running at http://${host}:${port}`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();
