"""Public CLI stepping with recorded app-server replies; no model service."""
import json
import os
import pty
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[3]


class StepwiseCLITests(unittest.TestCase):
    def test_launcher_rejects_closed_input_before_starting_a_board(self):
        with tempfile.TemporaryDirectory(prefix='bridge-closed-input-') as temporary:
            output = Path(temporary) / 'play'
            result = subprocess.run([str(ROOT / 'Scripts/step-playing.sh'),
                '--fixture', str(ROOT / 'evals/stage1/corpus/boards/synthetic.json'),
                '--output', str(output), '--codex', '/recorded-runtime-not-invoked'],
                stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=5)
            self.assertEqual(result.returncode, 2)
            self.assertIn('terminal', result.stderr)
            self.assertFalse(output.exists(), 'Closed stdin must be caught before starting a board')

    def test_launcher_preserves_terminal_and_reuses_the_live_thread(self):
        with tempfile.TemporaryDirectory(prefix='bridge-stepwise-') as temporary:
            root = Path(temporary)
            (root / 'auth.json').write_text('{}')
            runtime = root / 'recorded-app-server'
            runtime.write_text('#!/bin/sh\nexec ' + shlex.quote(sys.executable) + ' ' +
                               shlex.quote(str(root / 'runtime.py')) + ' "$@"\n')
            runtime.chmod(0o700)
            (root / 'runtime.py').write_text('''import json, sys
if '--version' in sys.argv:
    print('recorded stepwise boundary'); sys.exit(0)
if sys.argv[1:4] == ['debug', 'models', '--bundled']:
    print(json.dumps({'models':[{'slug':'gpt-6-luna','tool_mode':'code','experimental_supported_tools':['exec'],'apply_patch_tool_type':'freeform','shell_type':'default'}]})); sys.exit(0)
turn = 0
for line in sys.stdin:
    request = json.loads(line)
    if 'id' not in request: continue
    method = request.get('method')
    result = {}
    if method == 'model/list':
        result = {'data':[{'model':'gpt-6-luna','supportedReasoningEfforts':[{'reasoningEffort':'medium'}]}]}
    elif method == 'thread/start':
        result = {'thread':{'id':'recorded-board-thread'},'model':'gpt-6-luna'}
    elif method == 'turn/start':
        turn += 1
        result = {'turn':{'id':f'turn-{turn}'}}
        reply = {'publicReason':'Recorded legal choice.',
                 'plan':{'update':'replace' if turn == 1 else 'keep','text':'Recorded board plan.' if turn == 1 else None},
                 'selectedCard':request['params']['outputSchema']['properties']['selectedCard']['enum'][0]}
    print(json.dumps({'id':request['id'],'result':result}),flush=True)
    if method == 'turn/start':
        print(json.dumps({'method':'turn/completed','params':{'threadId':'recorded-board-thread','turn':{'id':f'turn-{turn}','status':'completed','items':[{'type':'agentMessage','text':json.dumps(reply)}]}}}),flush=True)
''')
            output = root / 'play'
            terminal, child_stdin = pty.openpty()
            try:
                process = subprocess.Popen([str(ROOT / 'Scripts/step-playing.sh'),
                    '--fixture', str(ROOT / 'evals/stage1/corpus/boards/synthetic.json'),
                    '--output', str(output), '--codex', str(runtime)], cwd=ROOT,
                    env={**os.environ, 'CODEX_HOME':str(root)}, stdin=child_stdin,
                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            except BaseException:
                os.close(terminal)
                raise
            finally:
                os.close(child_stdin)
            try:
                def wait_for(name):
                    deadline = time.monotonic() + 8
                    while not (output / name).exists():
                        if process.poll() is not None:
                            self.fail('CLI exited before the decision was saved: ' + process.communicate()[1])
                        if time.monotonic() > deadline:
                            self.fail('Timed out waiting for ' + name)
                        time.sleep(0.02)

                wait_for('decision-0001/decision.json')
                time.sleep(0.1)
                self.assertIsNone(process.poll(), 'The board must stay alive while waiting')
                rows = [json.loads(line) for line in (output / 'rpc.jsonl').read_text().splitlines()]
                turns = [row['value']['params'] for row in rows if row['kind']=='request' and row['value'].get('method')=='turn/start']
                self.assertEqual(len(turns), 1, 'Waiting must not send another model request')
                os.write(terminal, b'next\n')
                wait_for('decision-0002/decision.json')
                os.write(terminal, b'stop\n')
                stdout, stderr = process.communicate(timeout=8)
                self.assertEqual(process.returncode, 0, stderr)
                self.assertIn('Waiting for next or stop', stdout)
                rows = [json.loads(line) for line in (output / 'rpc.jsonl').read_text().splitlines()]
                requests = [row['value'] for row in rows if row['kind']=='request']
                self.assertEqual(sum(r.get('method')=='thread/start' for r in requests), 1)
                turns = [r['params'] for r in requests if r.get('method')=='turn/start']
                self.assertEqual([t['threadId'] for t in turns], ['recorded-board-thread'] * 2)
                decisions = [json.loads((output / f'decision-{n:04}/decision.json').read_text()) for n in (1, 2)]
                self.assertNotEqual(decisions[0]['identity']['turnID'], decisions[1]['identity']['turnID'])
                self.assertEqual(json.loads(decisions[1]['input'])['effectivePlan'], 'Recorded board plan.')
                self.assertFalse((output / 'decision-0003').exists())
            finally:
                try:
                    if process.poll() is None:
                        process.terminate()
                        process.communicate(timeout=5)
                finally:
                    os.close(terminal)
