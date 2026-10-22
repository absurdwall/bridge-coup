#!/usr/bin/env python3
"""Temporary diagnostic RPC relay; never part of the player product."""
import hashlib
import json
import os
import re
from pathlib import Path
import subprocess
import sys
import threading

config=json.loads(Path(__file__+'.json').read_text())
if not sys.argv[1:] or sys.argv[1]!='app-server':
 os.execv(config['executable'],[config['executable']]+sys.argv[1:])

child=subprocess.Popen([config['executable']]+sys.argv[1:],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=sys.stderr.buffer)
ack=threading.Event();state={};inject_id=99000001

def pump():
 try:
  for line in child.stdout:
   obj=json.loads(line)
   if obj.get('id')==inject_id:
    state['response']=obj
    Path(config['ack']).write_text(json.dumps({'method':'thread/inject_items','accepted': 'error' not in obj,'error_code':obj.get('error',{}).get('code'),'error_message':re.sub(r'[A-Za-z0-9_+/=-]{100,}', '<OPAQUE>', obj.get('error',{}).get('message',''))[:600],'item_count':len(json.loads(Path(config['seed']).read_text()))},indent=2)+'\n')
    ack.set()
   else:
    sys.stdout.buffer.write(line);sys.stdout.buffer.flush()
 finally:
  if not ack.is_set():state['reader_closed']=True;ack.set()
  if child.poll() is not None:os._exit(child.returncode or 1)

threading.Thread(target=pump,daemon=True).start()
injected=False
try:
 for line in sys.stdin.buffer:
  obj=json.loads(line)
  if obj.get('method')=='turn/start' and not injected:
   items=json.loads(Path(config['seed']).read_text())
   payload={'id':inject_id,'method':'thread/inject_items','params':{'threadId':obj['params']['threadId'],'items':items}}
   child.stdin.write((json.dumps(payload,separators=(',',':'))+'\n').encode());child.stdin.flush()
   if not ack.wait(30) or 'response' not in state or 'error' in state['response']:
    print('[DEBUG-HISTORY01] raw-history injection failed; no model turn forwarded',file=sys.stderr,flush=True)
    raise SystemExit(3)
   injected=True
   if config.get('dry_run'):
    reply={'id':obj['id'],'error':{'code':-32000,'message':'DIAG-HISTORY-DRY-RUN: injection validated; no model turn started.'}}
    sys.stdout.buffer.write((json.dumps(reply)+'\n').encode());sys.stdout.buffer.flush()
    continue
  child.stdin.write(line);child.stdin.flush()
finally:
 child.terminate()
 try:child.wait(timeout=5)
 except subprocess.TimeoutExpired:child.kill();child.wait()
