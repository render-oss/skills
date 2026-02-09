import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import * as schema from "./schema";

const connectionString = process.env.DATABASE_URL;

// Create a placeholder client if DATABASE_URL is not set
// This allows the app to start without a database for local development
const client = connectionString
  ? postgres(connectionString)
  : postgres("postgres://placeholder:placeholder@localhost:5432/placeholder");

export const db = drizzle(client, { schema });

export const isDatabaseConfigured = !!connectionString;
