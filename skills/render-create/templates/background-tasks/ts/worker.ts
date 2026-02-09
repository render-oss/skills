/**
 * Background Worker
 *
 * Long-running background process for async tasks.
 * Runs continuously and processes work items.
 */

import "dotenv/config";

const POLL_INTERVAL = 5000; // 5 seconds

interface WorkItem {
  id: string;
  data: unknown;
}

/**
 * Process a single work item
 */
async function processWorkItem(item: WorkItem): Promise<void> {
  console.log(`Processing work item: ${item.id}`);

  // TODO: Add your processing logic here
  // Example: fetch from queue, process data, update database

  await new Promise((resolve) => setTimeout(resolve, 100)); // Simulate work

  console.log(`Completed work item: ${item.id}`);
}

/**
 * Fetch pending work items
 */
async function fetchWorkItems(): Promise<WorkItem[]> {
  // TODO: Implement your work item fetching logic
  // Example: poll a database, queue, or API

  // Placeholder: return empty array (no work)
  return [];
}

/**
 * Main worker loop
 */
async function runWorker(): Promise<void> {
  console.log("Worker started");
  console.log(`Poll interval: ${POLL_INTERVAL}ms`);

  while (true) {
    try {
      const items = await fetchWorkItems();

      for (const item of items) {
        await processWorkItem(item);
      }

      if (items.length === 0) {
        // No work, wait before polling again
        await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL));
      }
    } catch (error) {
      console.error("Worker error:", error);
      // Wait before retrying on error
      await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL));
    }
  }
}

// Handle graceful shutdown
process.on("SIGTERM", () => {
  console.log("SIGTERM received, shutting down gracefully...");
  process.exit(0);
});

process.on("SIGINT", () => {
  console.log("SIGINT received, shutting down gracefully...");
  process.exit(0);
});

// Start the worker
runWorker().catch((error) => {
  console.error("Fatal worker error:", error);
  process.exit(1);
});
