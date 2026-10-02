"""Exercise the packaging probe's JSONL reader against real subprocess pipes."""

import contextlib
import importlib.util
import pathlib
import subprocess
import sys
import time
import unittest


script = pathlib.Path(__file__).resolve().parents[2] / "Scripts/verify-codex-handshake.py"
spec = importlib.util.spec_from_file_location("verify_codex_handshake", script)
probe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(probe)


@contextlib.contextmanager
def server(source):
    process = subprocess.Popen(
        [sys.executable, "-u", "-c", source],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, bufsize=0,
    )
    reader = probe.LineReader(process)
    try:
        yield process, reader
    finally:
        reader.close()
        process.terminate()
        try:
            process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=2)
        process.stdin.close()
        process.stdout.close()


class HandshakeReaderTests(unittest.TestCase):
    def test_coalesced_notification_and_responses_remain_readable(self):
        # One write puts all three lines in the pipe, including the next request's response.
        payload = b'{"method":"notice"}\n{"id":1,"result":{"ready":true}}\n{"id":2,"result":{"account":null}}\n'
        with server(f"import os, sys; os.write(1, {payload!r}); sys.stdin.read()") as (_, reader):
            deadline = time.monotonic() + 2
            self.assertEqual(probe.receive(reader, 1, deadline), {"ready": True})
            self.assertEqual(probe.receive(reader, 2, deadline), {"account": None})

    def test_partial_line_is_assembled_before_decoding(self):
        with server(
            "import os, sys, time; os.write(1, b'{\"id\":1,'); "
            "time.sleep(0.05); os.write(1, b'\"result\":{}}\\n'); sys.stdin.read()"
        ) as (_, reader):
            self.assertEqual(probe.receive(reader, 1, time.monotonic() + 2), {})

    def test_silent_server_and_unterminated_response_obey_deadline(self):
        for payload in [b"", b'{"id":1,"result":{}}']:
            with self.subTest(payload=payload), server(
                f"import os, sys; os.write(1, {payload!r}); sys.stdin.read()"
            ) as (process, reader):
                started = time.monotonic()
                with self.assertRaisesRegex(RuntimeError, "timed out on request 1"):
                    probe.receive(reader, 1, started + 0.2)
                self.assertLess(time.monotonic() - started, 1)
                self.assertIsNone(process.poll())
            self.assertIsNotNone(process.poll())

    def test_notifications_do_not_extend_deadline(self):
        with server(
            "import os, time\nwhile True:\n os.write(1, b'{\"method\":\"notice\"}\\n'); time.sleep(0.01)"
        ) as (_, reader):
            started = time.monotonic()
            with self.assertRaisesRegex(RuntimeError, "timed out on request 1"):
                probe.receive(reader, 1, started + 0.2)
            self.assertLess(time.monotonic() - started, 1)

    def test_matching_error_is_reported(self):
        payload = b'{"id":1,"error":{"message":"failed"}}\n'
        with server(f"import os, sys; os.write(1, {payload!r}); sys.stdin.read()") as (_, reader):
            with self.assertRaisesRegex(RuntimeError, "Codex app-server error"):
                probe.receive(reader, 1, time.monotonic() + 2)

    def test_exit_without_response_is_reported(self):
        with server("pass") as (_, reader):
            with self.assertRaisesRegex(RuntimeError, "Codex app-server (exited|closed stdout)"):
                probe.receive(reader, 1, time.monotonic() + 2)


if __name__ == "__main__":
    unittest.main()
