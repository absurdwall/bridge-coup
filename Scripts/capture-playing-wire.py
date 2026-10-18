#!/usr/bin/env python3
"""Audit a real app-server request without storing headers or rewriting its payload.

Run the printed wrapper as bridge-play's --codex executable while this proxy runs.
The wrapper selects a transparent Responses provider using existing ChatGPT auth;
the requested playing model/effort and the JSON payload are unchanged.
"""
import argparse
import http.server
import json
import shlex
import threading
import urllib.error
import urllib.request
from pathlib import Path

UPSTREAM = "https://chatgpt.com/backend-api/codex"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--codex", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--port", type=int, default=0)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    sequence_lock = threading.Lock()
    sequence = 0

    class Handler(http.server.BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.0"

        def log_message(self, *_):
            pass  # HTTP headers, including authentication, never enter evidence.

        def do_POST(self):
            nonlocal sequence
            if self.path != "/responses":
                self.send_error(404)
                return
            payload = self.rfile.read(int(self.headers.get("Content-Length", "0")))
            try:
                request_object = json.loads(payload)
            except ValueError:
                self.send_error(400, "Expected an uncompressed JSON request")
                return
            with sequence_lock:
                ordinal = sequence
                sequence += 1
            (args.output / f"request-{ordinal}.json").write_bytes(payload)
            excluded = {"host", "connection", "content-length", "transfer-encoding"}
            headers = {key: value for key, value in self.headers.items() if key.lower() not in excluded}
            request = urllib.request.Request(UPSTREAM + self.path, data=payload, headers=headers, method="POST")
            try:
                upstream = urllib.request.urlopen(request, timeout=180)
            except urllib.error.HTTPError as error:
                upstream = error
            except Exception as error:
                (args.output / f"transport-error-{ordinal}.json").write_text(json.dumps({"errorType": type(error).__name__}))
                self.send_error(502, "Upstream transport failed")
                return
            metadata = {"httpStatus": upstream.status}
            metadata_path = args.output / f"response-metadata-{ordinal}.json"

            def persist_metadata():
                # Readers may terminate the proxy as soon as completion is visible.
                # Publish one complete file before exposing the matching bytes.
                temporary = metadata_path.with_suffix(".json.tmp")
                temporary.write_text(json.dumps(metadata, indent=2))
                temporary.replace(metadata_path)

            persist_metadata()
            self.send_response(upstream.status)
            for key, value in upstream.headers.items():
                if key.lower() not in {"connection", "transfer-encoding", "content-length"}:
                    self.send_header(key, value)
            self.end_headers()
            # Forward bytes unchanged. Retain only public response identity, not reasoning.
            pending = b""
            try:
                with upstream:
                    while chunk := upstream.read1(65536):
                        pending += chunk
                        while b"\n" in pending:
                            line, pending = pending.split(b"\n", 1)
                            if line.startswith(b"data: "):
                                try:
                                    event = json.loads(line[6:])
                                except ValueError:
                                    continue
                                if event.get("type") in {"response.created", "response.completed"}:
                                    response = event.get("response", {})
                                    for key in ("id", "model", "status", "usage"):
                                        if key in response:
                                            metadata[key] = response[key]
                                    persist_metadata()
                        self.wfile.write(chunk)
                        self.wfile.flush()
            finally:
                persist_metadata()

    server = http.server.ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    provider = {
        "name": "bridge-wire-audit", "base_url": f"http://127.0.0.1:{server.server_port}",
        "wire_api": "responses", "requires_openai_auth": True, "supports_websockets": False,
    }
    # Inline TOML table, not JSON (TOML uses '=' for fields).
    table = "{" + ",".join(f"{key}={json.dumps(value)}" for key, value in provider.items()) + "}"
    overrides = ["-c", 'model_provider="bridge-wire-audit"', "-c", "model_providers.bridge-wire-audit=" + table,
                 "-c", "features.enable_request_compression=false"]
    wrapper = args.output / "codex-wire-audit"
    wrapper.write_text("#!/bin/sh\nexport PATH=" + shlex.quote(str(args.codex.parent)) + ':"$PATH"\nexec ' + shlex.quote(str(args.codex)) + ' "$@" ' + shlex.join(overrides) + "\n")
    wrapper.chmod(0o700)
    (args.output / "capture-config.json").write_text(json.dumps({"upstream": UPSTREAM, "overrides": overrides}, indent=2))
    print(str(wrapper.resolve()), flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
