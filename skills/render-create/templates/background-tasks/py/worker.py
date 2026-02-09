"""
Background Worker

Long-running background process for async tasks.
Runs continuously and processes work items.
"""

import os
import signal
import sys
import time
from dataclasses import dataclass
from typing import Any

from dotenv import load_dotenv

load_dotenv()

POLL_INTERVAL = 5  # seconds


@dataclass
class WorkItem:
    id: str
    data: Any


# Graceful shutdown flag
shutdown_requested = False


def signal_handler(signum, frame):
    """Handle shutdown signals gracefully."""
    global shutdown_requested
    print(f"Received signal {signum}, shutting down gracefully...")
    shutdown_requested = True


def process_work_item(item: WorkItem) -> None:
    """Process a single work item."""
    print(f"Processing work item: {item.id}")

    # TODO: Add your processing logic here
    # Example: fetch from queue, process data, update database

    time.sleep(0.1)  # Simulate work

    print(f"Completed work item: {item.id}")


def fetch_work_items() -> list[WorkItem]:
    """Fetch pending work items."""
    # TODO: Implement your work item fetching logic
    # Example: poll a database, queue, or API

    # Placeholder: return empty list (no work)
    return []


def run_worker() -> None:
    """Main worker loop."""
    print("Worker started")
    print(f"Poll interval: {POLL_INTERVAL}s")

    while not shutdown_requested:
        try:
            items = fetch_work_items()

            for item in items:
                if shutdown_requested:
                    break
                process_work_item(item)

            if not items:
                # No work, wait before polling again
                time.sleep(POLL_INTERVAL)

        except Exception as e:
            print(f"Worker error: {e}")
            # Wait before retrying on error
            time.sleep(POLL_INTERVAL)

    print("Worker shutdown complete")


if __name__ == "__main__":
    # Register signal handlers
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    try:
        run_worker()
    except Exception as e:
        print(f"Fatal worker error: {e}")
        sys.exit(1)
