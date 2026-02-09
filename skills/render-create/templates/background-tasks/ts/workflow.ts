/**
 * Render Workflow
 *
 * Uses the Render SDK to define distributed tasks.
 * See: https://github.com/render-oss/sdk
 */

import "dotenv/config";
import { task, type Retry } from "@renderinc/sdk/workflows";

// Retry configuration
const retry: Retry = {
  maxRetries: 3,
  waitDurationMs: 1000,
  factor: 1.5,
};

/**
 * Simple task that squares a number (subtask)
 */
const square = task({ name: "square" }, function square(a: number): number {
  console.log(`Calculating square of ${a}`);
  return a * a;
});

/**
 * Async task that adds two squared numbers
 */
task(
  {
    name: "addSquares",
    timeoutSeconds: 300,
    retry,
  },
  async function addSquares(a: number, b: number): Promise<number> {
    console.log(`Adding squares of ${a} and ${b}`);

    const result1 = await square(a);
    const result2 = await square(b);

    const sum = result1 + result2;
    console.log(`Result: ${result1} + ${result2} = ${sum}`);
    return sum;
  },
);

/**
 * Task that processes data
 */
task(
  {
    name: "processData",
    timeoutSeconds: 300,
    retry,
  },
  async function processData(data: string): Promise<string> {
    console.log(`Processing data: ${data}`);

    // TODO: Add your data processing logic here
    const result = data.toUpperCase();

    console.log(`Processed result: ${result}`);
    return result;
  },
);

// Task server starts automatically when RENDER_SDK_SOCKET_PATH is set
