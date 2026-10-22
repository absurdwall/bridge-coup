"""Production Expert/driver -> installed runtime -> offline HTTP boundary.

Requires macOS, a local codex installation and Swift. No credentials or model
service: a loopback provider captures the request and immediately rejects it.
"""
import http.server
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import threading
import unittest

ROOT = Path(__file__).resolve().parents[3]


@unittest.skipUnless(os.uname().sysname == 'Darwin' and shutil.which('codex'),
                     'Needs installed macOS Codex runtime; never downloads one')
class RuntimeIsolationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.binary = Path(os.environ.get('BRIDGE_TEST_PLAY_BINARY', str(ROOT/'.build/debug/bridge-play')))
        if not cls.binary.is_file():
            raise RuntimeError('Build the production public driver with swift build --product bridge-play first')

    def public_request(self, fixture='evals/stage1/fixtures/synthetic-initial.json'):
        captures = []

        class RejectingProvider(http.server.BaseHTTPRequestHandler):
            def log_message(self, *_):
                pass

            def do_POST(self):
                self.assert_no_auth = self.headers.get('Authorization') is None
                captures.append((json.loads(self.rfile.read(int(self.headers['Content-Length']))), self.assert_no_auth))
                body = b'{"error":{"type":"invalid_request_error","message":"OFFLINE_ISOLATION_REGRESSION_NO_INFERENCE"}}'
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Content-Length', str(len(body)))
                self.end_headers()
                self.wfile.write(body)

        server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), RejectingProvider)
        threading.Thread(target=server.serve_forever, daemon=True).start()
        try:
            with tempfile.TemporaryDirectory(prefix='bridge-isolation-test-') as temp:
                root = Path(temp)
                (root/'auth.json').write_text('{}')  # Deliberately no real authentication.
                codex = Path(shutil.which('codex'))
                wrapper = root/'offline-codex'
                provider = '{name="offline-isolation-test",base_url="http://127.0.0.1:%d",wire_api="responses",requires_openai_auth=false,supports_websockets=false,request_max_retries=0,stream_max_retries=0}' % server.server_port
                wrapper.write_text('#!/bin/sh\nexport PATH='+shlex.quote(str(codex.parent))+':"$PATH"\nexec '+shlex.quote(str(codex))+' "$@" -c model_provider="offline-isolation-test" -c '+shlex.quote('model_providers.offline-isolation-test='+provider)+' -c features.enable_request_compression=false\n')
                wrapper.chmod(0o700)
                result = subprocess.run([str(self.binary),
                    '--fixture', str(ROOT/fixture),
                    '--output', str(root/'play'), '--codex', str(wrapper), '--timeout', '15'],
                    cwd=ROOT, env={**os.environ, 'CODEX_HOME': str(root)},
                    capture_output=True, text=True, timeout=25)
                self.assertNotEqual(result.returncode, 0)  # Fake rejection cannot be a playing pass.
                self.assertEqual(len(captures), 1, result.stderr)
                source = json.loads((root/'play/runtime-bundled-catalog.json').read_text())
                effective = json.loads((root/'play/runtime-model-catalog.json').read_text())
                luna = next(model for model in source['models'] if model['slug'] == 'gpt-6-luna')
                expected = {**luna, 'tool_mode': 'direct', 'experimental_supported_tools': [],
                            'apply_patch_tool_type': None, 'shell_type': 'disabled'}
                self.assertEqual(effective, {**source, 'models': [expected if model['slug'] == 'gpt-6-luna'
                                                               else model for model in source['models']]})
                request, auth_absent = captures[0]
                self.assertTrue(auth_absent)
                self.assertEqual(request['model'], 'gpt-6-luna')
                self.assertEqual(request['reasoning']['effort'], 'medium')
                rows = [json.loads(line) for line in (root/'play/rpc.jsonl').read_text().splitlines()]
                sent = next(row['value']['params']['outputSchema'] for row in rows
                            if row['kind'] == 'request' and row['value'].get('method') == 'turn/start')
                self.assertEqual(list(sent['properties']), list(request['text']['format']['schema']['properties']))
                return request
        finally:
            server.shutdown()
            server.server_close()


    def test_public_expert_request_has_no_tools(self):
        request = self.public_request()
        tools = next(item['tools'] for item in request['input'] if item['type'] == 'additional_tools')
        names = {namespace['name'] for namespace in tools}
        self.assertNotIn('collaboration', names, 'Inherited collaboration must be disabled in the actual public request')
        text = '\n'.join(part.get('text', '') for item in request['input'] for part in item.get('content', []))
        self.assertNotIn('<multi_agent_role>', text)
        self.assertNotIn('<multi_agent_mode>', text)
        self.assertEqual(tools, [], 'Playing requests must not contain generic tools')

    def test_actual_schema_preserves_plan_card_reason_and_update_text_order(self):
        request = self.public_request()
        self.assertEqual(list(request['text']['format']['schema']['properties']),
                         ['plan', 'selectedCard', 'publicReason'])
        for variant in request['text']['format']['schema']['properties']['plan']['anyOf']:
            self.assertEqual(list(variant['properties']), ['update', 'text'])

    def test_complete_json_snapshot_preserves_visibility_and_schema_legal_actions(self):
        fixture_path = 'evals/stage1/corpus/boards/walker-holdup-adapted.json'
        request = self.public_request(fixture_path)
        text = '\n'.join(part.get('text', '') for item in request['input']
                         if item.get('role') == 'user' for part in item.get('content', []))
        snapshot = json.loads(text)
        self.assertEqual(set(snapshot), {'type', 'contract', 'scoring', 'vulnerability', 'objective', 'publicBackground', 'controller',
                         'hands', 'completedTricks', 'currentTrick', 'current', 'effectivePlan'})
        self.assertEqual(snapshot['type'], 'initial')
        self.assertEqual(snapshot['contract'], {'level':3, 'strain':'NT', 'doubling':'undoubled', 'declarer':'S'})
        self.assertEqual(set(snapshot['hands']), {'N', 'S'})
        self.assertEqual(snapshot['hands']['S'], {'S':'A93', 'H':'KQJ', 'D':'5432', 'C':'AJ6'})
        self.assertEqual(snapshot['hands']['N'], {'S':'87', 'H':'A43', 'D':'KQJT9', 'C':'T54'})
        self.assertEqual(snapshot['currentTrick'], [{'seat':'W', 'card':'SK'}])
        self.assertEqual(snapshot['completedTricks'], [])
        self.assertEqual(snapshot['current'], {'toAct':'N', 'tricksWon':{'declarer':0, 'defenders':0},
                                               'winningPlay':{'seat':'W', 'card':'SK'}})
        self.assertIsNone(snapshot['effectivePlan'])
        self.assertEqual(request['text']['format']['schema']['properties']['selectedCard']['enum'], ['S8', 'S7'])
        instructions = (ROOT/'Sources/BridgeExpert/Resources/DeclarerInstructions.txt').read_text()
        developer = [part.get('text', '') for item in request['input'] if item.get('role') == 'developer'
                     for part in item.get('content', [])]
        self.assertIn(instructions, developer, 'The actual request explicitly loads the single fixed source')
