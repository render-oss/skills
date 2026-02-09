"""
Render Workflow

Uses the Render SDK to define distributed tasks.
See: https://pypi.org/project/render-sdk/
"""

import asyncio
import logging

from dotenv import load_dotenv
from render_sdk import Retry, Workflows

load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Retry configuration
retry = Retry(max_retries=3, wait_duration_ms=1000, backoff_scaling=1.5)

# Initialize Workflows app
app = Workflows(
    default_retry=retry,
    default_timeout=300,
    auto_start=True,
)


@app.task
def square(a: int) -> int:
    """Square a number (subtask)."""
    logger.info(f"Computing square of {a}")
    return a * a


@app.task
async def add_squares(a: int, b: int) -> int:
    """Add the squares of two numbers using subtasks."""
    logger.info(f"Computing add_squares: {a}, {b}")

    result1 = await square(a)
    result2 = await square(b)

    total = result1 + result2
    logger.info(f"Total: {total}")
    return total


@app.task
async def process_data(data: str) -> str:
    """Process data."""
    logger.info(f"Processing data: {data}")

    # TODO: Add your data processing logic here
    result = data.upper()

    logger.info(f"Processed result: {result}")
    return result


@app.task
async def fan_out(items: list[str]) -> list[str]:
    """Process multiple items in parallel using subtasks."""
    logger.info(f"Processing {len(items)} items in parallel")

    tasks = [process_data(item) for item in items]
    results = await asyncio.gather(*tasks)

    return list(results)


# Task server starts automatically with auto_start=True
