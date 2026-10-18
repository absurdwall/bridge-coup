"""Offline tests at the capture CLI's HTTP and evidence interfaces."""
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time
import unittest
import urllib.request

ROOT = Path(__file__).resolve().parents[3]
CAPTURE = ROOT / 'Scripts/capture-playing-wire.py'

# Only the remote HTTP boundary is substituted. The real CLI, handler, socket,
# forwarding and evidence writer run in the child process.
DELAYED_EOF = r'''
import importlib.util, sys, threading
spec = importlib.util.spec_from_file_location('capture', sys.argv[1])
capture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(capture)
class Upstream:
    status = 200
    headers = {'Content-Type': 'text/event-stream'}
    def __init__(self):
        chunks = [
            b'data: {"type":"response.created","response":{"id":"offline-response","model":"fixture","status":"in_progress"}}\n\n',
            b'data: {"type":"response.completed","response":{"id":"offline-response","model":"fixture","status":"completed","usage":{"input_tokens":7,"output_tokens":3}}}\n\n']
        if sys.argv[3] == 'split':
            chunks = chunks[:1] + [chunks[1][:37], chunks[1][37:-2], chunks[1][-2:]]
        self.chunks = iter(chunks)
    def read1(self, _):
        chunk = next(self.chunks, None)
        if chunk is not None:
            return chunk
        threading.Event().wait(30)  # EOF is deliberately withheld, not a correctness delay.
        return b''
    def __enter__(self): return self
    def __exit__(self, *args): pass
capture.urllib.request.urlopen = lambda *args, **kwargs: Upstream()
sys.argv = [sys.argv[1], '--codex', '/usr/bin/true', '--output', sys.argv[2]]
capture.main()
'''


class CaptureTests(unittest.TestCase):
    def test_terminal_metadata_is_saved_before_completion_with_delayed_upstream_eof(self):
        self.assert_completion_capture('whole')

    def test_split_terminal_event_is_captured_before_completion_and_cleanup_is_bounded(self):
        self.assert_completion_capture('split')

    def assert_completion_capture(self, chunks):
        with tempfile.TemporaryDirectory() as directory:
            wire = Path(directory)
            process = subprocess.Popen([sys.executable, '-c', DELAYED_EOF, str(CAPTURE), str(wire), chunks],
                                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            response = None
            try:
                # Use the runner's public bounded startup interface.
                sys.path.insert(0, str(ROOT / 'evals/stage1'))
                import acceptance
                acceptance.proxy_wrapper(process, timeout=3)
                config = json.loads((wire / 'capture-config.json').read_text())
                url = re.search(r'http://127\.0\.0\.1:\d+', str(config)).group()
                response = urllib.request.urlopen(urllib.request.Request(url + '/responses', data=b'{"fixture":true}',
                                                        headers={'Content-Type': 'application/json'}), timeout=3)
                received = []
                while True:
                    line = response.readline()
                    self.assertTrue(line, 'Proxy ended before terminal completion')
                    received.append(line)
                    if b'"type":"response.completed"' in line:
                        break
                # The player can exit immediately at this observable boundary.
                # No sleep/poll/grace period may be needed for its evidence.
                metadata = wire / 'response-metadata-0.json'
                self.assertTrue(metadata.exists(), 'Client received response.completed before metadata was durable')
                self.assertEqual(json.loads(metadata.read_text()), {
                    'httpStatus': 200, 'id': 'offline-response', 'model': 'fixture', 'status': 'completed',
                    'usage': {'input_tokens': 7, 'output_tokens': 3}})
                self.assertEqual((wire / 'request-0.json').read_bytes(), b'{"fixture":true}')
                self.assertEqual(b''.join(received),
                    b'data: {"type":"response.created","response":{"id":"offline-response","model":"fixture","status":"in_progress"}}\n\n'
                    b'data: {"type":"response.completed","response":{"id":"offline-response","model":"fixture","status":"completed","usage":{"input_tokens":7,"output_tokens":3}}}\n')
            finally:
                started = time.monotonic()
                try:
                    process.terminate()
                    process.wait(timeout=1)
                    self.assertLess(time.monotonic() - started, 1)
                finally:
                    if process.poll() is None:
                        process.kill()
                        process.wait(timeout=1)
                    if response is not None:
                        response.close()
                    process.stdout.close()
                    process.stderr.close()
            self.assertEqual(json.loads(metadata.read_text())['status'], 'completed')


if __name__ == '__main__':
    unittest.main()
