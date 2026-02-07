/**
 * Render Workflows entry point.
 *
 * Define your workflow tasks here and in other modules.
 * The task server starts automatically when RENDER_SDK_SOCKET_PATH is set.
 *
 * Quick test:
 *   render ea tasks dev -- npx ts-node workflows/main.ts
 *   # Then in another terminal:
 *   render ea tasks list --local
 *   # Select "ping", run with [], expect "pong"
 */

import { task } from "@renderinc/sdk/workflows";

/**
 * Zero-arg task to verify the workflow is working. Run with input [].
 */
task({ name: "ping" }, function ping(): string {
  return "pong";
});

/**
 * Greet someone. Run with input ["world"].
 */
task({ name: "hello" }, function hello(name: string): string {
  console.log(`Greeting ${name}`);
  return `Hello, ${name}!`;
});

/**
 * Square a number. Run with input [5].
 */
const square = task(
  { name: "square" },
  function square(a: number): number {
    return a * a;
  },
);

/**
 * Add the squares of two numbers using subtasks. Run with input [3, 4].
 */
task(
  {
    name: "sumSquares",
    retry: {
      maxRetries: 3,
      waitDurationMs: 1000,
      backoffScaling: 1.5,
    },
  },
  async function sumSquares(a: number, b: number): Promise<number> {
    const result1 = await square(a);
    const result2 = await square(b);
    return result1 + result2;
  },
);
