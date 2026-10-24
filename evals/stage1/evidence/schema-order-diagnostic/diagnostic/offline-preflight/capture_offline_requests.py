"""Synthetic request assembly only. Loopback fake provider never forwards or generates.

The native app-server is additionally confined to loopback outbound connections by
macOS sandbox-exec. The fake server returns HTTP 400 before inference; no response
contains tools or a bridge answer, and no Bridge driver/evaluator is invoked.
"""
import copy
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import re
import select
import signal
import subprocess
import threading
import time

root = Path('/tmp/bridge-stage1-runtime-audit').resolve()
base = root / 'schema-order-preflight'
cli = '/Users/tingranwang/.nvm/versions/node/v24.12.0/bin/codex'
original = json.loads((root/'assembly-original-rpc-requests.json').read_text())
by_method = {r['method']: r for r in original}
recorded_config = (root/'recorded-home/config.toml').read_text()
active_arm = None
received = []
lock = threading.Lock()

class FakeProvider(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass
    def do_GET(self):
        self.send_error(400, 'OFFLINE_FAKE_PROVIDER_NO_EXTERNAL_FORWARDING')
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get('Content-Length', '0')))
        with lock:
            arm = active_arm
            assert arm is not None
            number = sum(1 for r in received if r['arm'] == arm)
            row = {'arm': arm, 'number': number, 'path': self.path,
                   'peer_is_loopback': self.client_address[0] == '127.0.0.1',
                   'authorization_header_present': self.headers.get('Authorization') is not None,
                   'content_encoding': self.headers.get('Content-Encoding'),
                   'body_sha256': hashlib.sha256(body).hexdigest(),
                   'response_status': 400, 'real_model_generation': False}
            (base/f'{arm}-request-{number}.json').write_bytes(body)
            received.append(row)
        payload = json.dumps({'error': {'type': 'invalid_request_error', 'code': 'offline_capture_only',
            'message': 'OFFLINE_FAKE_PROVIDER_CAPTURE_ONLY_NO_INFERENCE_NO_TOOLS'}}).encode()
        self.send_response(400)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

server = ThreadingHTTPServer(('127.0.0.1', 0), FakeProvider)
server.daemon_threads = True
threading.Thread(target=server.serve_forever, daemon=True).start()
port = server.server_address[1]
assert server.server_address[0] == '127.0.0.1'
results = []
allowed = {'initialize', 'initialized', 'config/read', 'experimentalFeature/list',
           'configRequirements/read', 'model/list', 'thread/start', 'turn/start'}

try:
    for arm in ['plan-first', 'reason-first']:
        active_arm = arm
        home = base/f'{arm}-home'; home.mkdir(exist_ok=True)
        cwd = base/f'{arm}-cwd'; cwd.mkdir(exist_ok=True)
        config = re.sub(r'path = "[^"]+/home/skills/', 'path = "'+str(home)+'/skills/', recorded_config)
        config = 'model_provider = "offline_assembly_audit"\n' + config
        if True:
            config += '\n[agents]\nenabled = false\n'
        config += f'''\n[model_providers.offline_assembly_audit]
name = "offline-loopback-request-assembly"
base_url = "http://127.0.0.1:{port}/v1"
wire_api = "responses"
requires_openai_auth = false
supports_websockets = false
request_max_retries = 0
stream_max_retries = 0
[analytics]
enabled = false
'''
        (home/'config.toml').write_text(config)
        assert not (home/'auth.json').exists()
        env = {'HOME': str(home), 'CODEX_HOME': str(home),
               'PATH': '/Users/tingranwang/.nvm/versions/node/v24.12.0/bin:/usr/bin:/bin:/usr/sbin:/sbin'}
        args = ['/usr/bin/sandbox-exec', '-f', str(base/'loopback-only.sb'), cli,
                'app-server', '--listen', 'stdio://', '-c', 'features.enable_request_compression=false']
        calls = []
        buffer = b''
        with (base/f'{arm}-stderr.txt').open('w') as err:
            process = subprocess.Popen(args, env=env, cwd=cwd, stdin=subprocess.PIPE,
                stdout=subprocess.PIPE, stderr=err, start_new_session=True)
            def receive(deadline):
                global buffer
                while time.monotonic() < deadline:
                    if b'\n' in buffer:
                        line, buffer = buffer.split(b'\n', 1)
                        if not line: continue
                        row = json.loads(line)
                        calls.append({'direction': 'from-runtime', 'value': row})
                        return row
                    ready = select.select([process.stdout], [], [], max(0,deadline-time.monotonic()))[0]
                    if not ready: break
                    chunk = os.read(process.stdout.fileno(), 65536)
                    if not chunk: break
                    buffer += chunk
                raise TimeoutError('runtime response timeout')
            next_id = 1
            def send(method, params, expect_reply=True):
                nonlocal_unused = None
                global next_id
                assert method in allowed
                row = {'method': method, 'params': params}
                identifier = next_id
                if expect_reply:
                    row['id'] = identifier; next_id += 1
                calls.append({'direction': 'to-runtime', 'value': row})
                process.stdin.write((json.dumps(row)+'\n').encode());process.stdin.flush()
                if not expect_reply: return None
                deadline = time.monotonic()+12
                while True:
                    reply = receive(deadline)
                    if reply.get('id') == identifier:
                        if 'error' in reply: raise RuntimeError(json.dumps(reply['error']))
                        return reply.get('result')
                    if 'id' in reply and 'method' in reply:
                        raise RuntimeError('Unexpected server request; no execution or approval handlers are installed')
            result = {'arm': arm, 'auth_before': False, 'args': args, 'synthetic_only': True}
            try:
                result['initialize'] = send('initialize',copy.deepcopy(by_method['initialize']['params']))
                send('initialized',{},False)
                cfg = send('config/read',{'cwd':str(cwd),'includeLayers':False})['config']
                result['config_selected'] = {k:cfg.get(k) for k in ['model','model_reasoning_effort','model_provider','features','agents','tools']}
                catalog = send('model/list',{'includeHidden':True})
                result['catalog_luna'] = [m for m in catalog.get('data',[]) if m.get('model') == 'gpt-6-luna']
                params = copy.deepcopy(by_method['thread/start']['params']);params['cwd']=str(cwd)
                thread = send('thread/start',params)
                result['thread_start_keys'] = list(thread)
                thread_id = thread['thread']['id']
                params = copy.deepcopy(by_method['turn/start']['params']);params['threadId']=thread_id
                if arm == 'reason-first':
                    props=params['outputSchema']['properties']
                    params['outputSchema']['properties']={k:props[k] for k in ['publicReason','plan','selectedCard']}
                turn = send('turn/start',params)
                result['turn_start'] = turn
                deadline=time.monotonic()+18
                while True:
                    reply=receive(deadline)
                    if 'id' in reply and 'method' in reply:
                        raise RuntimeError('Unexpected runtime request; no tool execution allowed')
                    if reply.get('method')=='turn/completed':
                        result['terminal_notification']=reply
                        break
            except Exception as exc:
                result['diagnostic_error']=str(exc)
            finally:
                process.stdin.close()
                try: process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid,signal.SIGTERM)
                    try: process.wait(timeout=2)
                    except subprocess.TimeoutExpired:
                        os.killpg(process.pid,signal.SIGKILL);process.wait(timeout=2)
                result['process_exit']=process.returncode
                result['auth_after']=(home/'auth.json').exists()
                process.stdout.close()
        (base/f'{arm}-rpc.json').write_text(json.dumps(calls,indent=2)+'\n')
        results.append(result)
finally:
    server.shutdown();server.server_close()
    (base/'http-capture-metadata.json').write_text(json.dumps(received,indent=2)+'\n')
    (base/'protocol-results.json').write_text(json.dumps(results,indent=2)+'\n')

summary = {'synthetic_only':True,'model_generations':0,'tool_executions':0,
           'provider':f'http://127.0.0.1:{port}/v1',
           'captures':received,'arms':[{'arm':r['arm'],'diagnostic_error':r.get('diagnostic_error'),
              'auth_before':r['auth_before'],'auth_after':r['auth_after']} for r in results]}
(base/'capture-summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))
assert len(received)==2, 'Expected exactly one captured synthetic request per arm'
assert all(not r['authorization_header_present'] and r['peer_is_loopback'] for r in received)
assert all(not r.get('diagnostic_error') and not r['auth_after'] for r in results)
