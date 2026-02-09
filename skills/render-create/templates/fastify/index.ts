import Fastify from "fastify";
import cors from "@fastify/cors";
import { db } from "./db";
import { users } from "./db/schema";

const fastify = Fastify({
  logger: true,
});

// Register plugins
fastify.register(cors, {
  origin: true,
});

// Health check endpoint
fastify.get("/health", async () => {
  return { status: "ok" };
});

// Example: Get all users
fastify.get("/users", async () => {
  const allUsers = await db.select().from(users);
  return allUsers;
});

// Start server
const start = async () => {
  try {
    const host = process.env.HOST ?? "0.0.0.0";
    const port = Number(process.env.PORT) || 3000;

    await fastify.listen({ host, port });
    console.log(`Server running at http://${host}:${port}`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();
