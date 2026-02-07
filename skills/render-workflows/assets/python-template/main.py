"""Render Workflows entry point.

Define your workflow tasks here and in other modules.
Import any modules with task definitions before the auto-start runs.

Quick test:
  render ea tasks dev -- python workflows/main.py
  # Then in another terminal:
  render ea tasks list --local
  # Select "ping", run with [], expect "pong"
"""

import asyncio
import logging

from render_sdk import Retry, Workflows

logging.basicConfig(level=logging.WARNING)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

app = Workflows(
    default_retry=Retry(max_retries=3, wait_duration_ms=1000, backoff_scaling=2.0),
    default_timeout=300,
    default_plan="standard",
    auto_start=True,
)


@app.task
def ping() -> str:
    """Zero-arg task to verify the workflow is working. Run with input []."""
    return "pong"


@app.task
def hello(name: str) -> str:
    """Greet someone. Run with input ["world"]."""
    logger.info(f"Greeting {name}")
    return f"Hello, {name}!"


@app.task
def square(a: int) -> int:
    """Square a number. Run with input [5]."""
    return a * a


@app.task
async def sum_squares(a: int, b: int) -> int:
    """Add the squares of two numbers using subtasks. Run with input [3, 4]."""
    result1, result2 = await asyncio.gather(
        square(a),
        square(b),
    )
    return result1 + result2
