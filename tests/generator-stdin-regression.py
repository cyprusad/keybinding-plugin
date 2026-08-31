#!/usr/bin/env python3
"""Prove catalog discovery never inherits a permanently open service stdin."""

import os
import runpy
import signal
import sys
import time
from pathlib import Path


class ProbeTimeout(RuntimeError):
    pass


def timeout_handler(_signum, _frame):
    raise ProbeTimeout("catalog subprocess inherited the open service stdin")


root = Path(__file__).resolve().parents[1]
generator = runpy.run_path(str(root / "scripts/generate-catalog"))
command_output = generator["command_output"]

# Model Quickshell's Process: fd 0 is a pipe whose writer remains open for the
# service lifetime. A child that inherits it blocks while trying to read EOF.
read_fd, write_fd = os.pipe()
saved_stdin = os.dup(0)
previous_handler = signal.signal(signal.SIGALRM, timeout_handler)

try:
    os.dup2(read_fd, 0)
    os.close(read_fd)
    signal.alarm(2)
    started = time.monotonic()
    output = command_output([
        sys.executable,
        "-c",
        "import os; print('eof' if os.read(0, 1) == b'' else 'data')",
    ], "stdin-probe")
    elapsed = time.monotonic() - started
finally:
    signal.alarm(0)
    signal.signal(signal.SIGALRM, previous_handler)
    os.dup2(saved_stdin, 0)
    os.close(saved_stdin)
    os.close(write_fd)

if output.strip() != "eof":
    raise SystemExit("catalog subprocess did not receive closed stdin")
if elapsed >= 1.5:
    raise SystemExit(f"catalog subprocess took too long to observe EOF: {elapsed:.3f}s")
