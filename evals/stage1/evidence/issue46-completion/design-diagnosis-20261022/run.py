import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

ROOT=Path(__file__).parent
REPO=Path('/Users/tingranwang/.codex/worktrees/issue46-integration/bridge-coup')
sys.path.insert(0,str(REPO/'evals/stage1'))
import acceptance
from evaluate import run_owned_runtime

plan=json.loads((ROOT/'PLAN.json').read_text())
native=Path('/Users/tingranwang/.nvm/versions/node/v24.12.0/lib/node_modules/@openai/codex/node_modules/@openai/codex-darwin-arm64/vendor/aarch64-apple-darwin/bin/codex')
auth=Path.home()/'.codex/auth.json'
assert auth.is_file()
for entry in plan['schedule']:
 assert hashlib.sha256((ROOT/entry['request']).read_bytes()).hexdigest()==entry['sha256']
metadata={'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=REPO,text=True).strip(),
          'native_sha256':hashlib.sha256(native.read_bytes()).hexdigest(),
          'harness_sha256':hashlib.sha256((ROOT/'probe').read_bytes()).hexdigest(),
          'plan_sha256':hashlib.sha256((ROOT/'PLAN.json').read_bytes()).hexdigest(),
          'runtime':subprocess.check_output([str(native),'--version'],text=True).strip(),
          'scope':'diagnostic counterfactuals, not product acceptance'}
(ROOT/'runtime-freeze.json').write_text(json.dumps(metadata,indent=2)+'\n')
rows=[]
for entry in plan['schedule']:
 started=time.monotonic()
 directory=ROOT/'runs'/entry['id'];directory.mkdir(parents=True,exist_ok=False)
 proxy_log=(directory/'proxy-stderr.txt').open('w')
 proxy=subprocess.Popen([sys.executable,str(REPO/'Scripts/capture-playing-wire.py'),'--codex',str(native),'--output',str(directory/'wire')],stdout=subprocess.PIPE,stderr=proxy_log)
 row={**entry}
 try:
  wrapper=acceptance.proxy_wrapper(proxy)
  request=ROOT/entry['request']
  assert hashlib.sha256(request.read_bytes()).hexdigest()==entry['sha256']
  command=[str(ROOT/'probe'),str(request),str(directory/'runtime'),wrapper,str(auth)]
  result=run_owned_runtime(command,env=dict(os.environ),cwd=ROOT,timeout=210)
  (directory/'stdout.txt').write_text(result.stdout);(directory/'stderr.txt').write_text(result.stderr)
  row['exit_code']=result.returncode
  if result.returncode==0:
   raw=(directory/'runtime/raw-output.txt').read_text();answer=json.loads(raw)
   row['raw_output']=answer
   row['identity']=json.loads((directory/'runtime/identity.json').read_text())
   if entry['task']=='factual-hearts':row['narrow_fact_check']='pass' if answer['maximumHeartTricks']==3 else 'fail'
   elif entry['task']=='factual-clubs':row['narrow_fact_check']='pass' if answer=={'canWin':True,'card':'CA'} else 'fail'
   elif entry['source_decision']==12:row['narrow_card_check']='CA' if answer['selectedCard']=='CA' else 'CJ'
   else:row['narrow_card_check']=answer.get('selectedCard')
 except Exception as error:
  row['error']=str(error)
 finally:
  proxy.terminate()
  try:proxy.wait(timeout=5)
  except subprocess.TimeoutExpired:proxy.kill();proxy.wait()
  proxy_log.close()
 row['elapsed_seconds']=round(time.monotonic()-started,3)
 (directory/'outcome.json').write_text(json.dumps(row,indent=2,ensure_ascii=False)+'\n')
 rows.append(row)
 (ROOT/'results.json').write_text(json.dumps({'metadata':metadata,'attempts':rows},indent=2,ensure_ascii=False)+'\n')
 print(entry['id'],'exit',row.get('exit_code'),'check',row.get('narrow_fact_check',row.get('narrow_card_check',row.get('error'))),'seconds',row['elapsed_seconds'],flush=True)
(ROOT/'execution-finished.json').write_text(json.dumps({'requests':len(rows),'scope':'diagnostic only','finished_unix':time.time()},indent=2)+'\n')
