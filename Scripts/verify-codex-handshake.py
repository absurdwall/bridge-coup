#!/usr/bin/env python3
"""Probe the shipped Codex app-server with an empty, isolated CODEX_HOME."""

import json
import os
import selectors
import subprocess
import sys
import tempfile
import time


class LineReader:
    """Keep complete JSONL messages and partial lines outside Python's I/O buffer."""

    def __init__(self, process):
        self.process = process
        self.buffer = b""
        self.selector = selectors.DefaultSelector()
        self.selector.register(process.stdout, selectors.EVENT_READ)

    def read_line(self, deadline):
        while time.monotonic() < deadline:
            line, separator, remainder = self.buffer.partition(b"\n")
            if separator:
                self.buffer = remainder
                return line
            if not self.selector.select(max(0, deadline - time.monotonic())):
                return None
            chunk = os.read(self.process.stdout.fileno(), 65536)
            if not chunk:
                if self.process.poll() is not None:
                    raise RuntimeError(f"Codex app-server exited {self.process.returncode}")
                raise RuntimeError("Codex app-server closed stdout")
            self.buffer += chunk
        return None

    def close(self):
        self.selector.close()


def receive(reader, request_id, deadline):
    while (line := reader.read_line(deadline)) is not None:
        message = json.loads(line)
        if message.get("id") == request_id:
            if "error" in message:
                raise RuntimeError(f"Codex app-server error: {message['error']}")
            return message.get("result")
    raise RuntimeError(f"Codex app-server timed out on request {request_id}")


def send(process, payload):
    process.stdin.write((json.dumps(payload) + "\n").encode("utf-8"))
    process.stdin.flush()


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: verify-codex-handshake.py /path/to/codex")
    executable = os.path.abspath(sys.argv[1])
    with tempfile.TemporaryDirectory(prefix="bridge-coup-codex-probe-") as isolated:
        env = dict(os.environ)
        env["CODEX_HOME"] = os.path.join(isolated, "codex-home")
        os.mkdir(env["CODEX_HOME"])
        env["PATH"] = "/usr/bin:/bin"
        process = subprocess.Popen(
            [executable, "app-server", "--listen", "stdio://"],
            cwd=isolated,
            env=env,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            bufsize=0,
        )
        reader = LineReader(process)
        try:
            deadline = time.monotonic() + 20
            send(process, {"id": 1, "method": "initialize", "params": {
                "clientInfo": {"name": "bridge_coup_package_probe", "title": "Bridge Coup", "version": "1.0.0"}
            }})
            initialized = receive(reader, 1, deadline)
            if not isinstance(initialized, dict):
                raise RuntimeError("Codex initialize response was not an object")
            send(process, {"method": "initialized", "params": {}})
            send(process, {"id": 2, "method": "account/read", "params": {}})
            account = receive(reader, 2, deadline)
            if not isinstance(account, dict) or account.get("account", "missing") is not None:
                raise RuntimeError("Isolated Codex account state was not signed out")
            print("Verified packaged Codex app-server initialize and signed-out account/read")
        finally:
            reader.close()
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)
            process.stdin.close()
            process.stdout.close()


if __name__ == "__main__":
    main()
