import hashlib,json,os,pathlib,subprocess,sys,time
ROOT=pathlib.Path(__file__).parent
REPO=pathlib.Path('/Users/tingranwang/.codex/worktrees/issue46-integration/bridge-coup')
sys.path.insert(0,str(REPO/'evals/stage1'));import acceptance
from evaluate import run_owned_runtime
study=ROOT/'memory-rule-study';study.mkdir(exist_ok=False)
source=REPO/'evals/stage1/evidence/issue46-completion/development-v4/short-6-r1/wire'
seeds={}
for n in [12]:
 wire=json.loads((source/f'request-{n-1}.json').read_text())
 items=[i for i in wire['input'] if i['type']!='additional_tools' and not(i['type']=='message' and i.get('role') in ['developer','system'])]
 assert items[-1]['type']=='message' and items[-1]['role']=='user'
 full=items[:-1]
 for mode,data in [('full',full),('public',[i for i in full if i['type']!='reasoning'])]:
  p=study/f'seed-d{n}-{mode}.json';p.write_text(json.dumps(data,indent=2)+'\n');seeds[n,mode]=p
schedule=[]
for repeat in [1,2,3]:
 modes=['control','memory-rule'] if repeat%2 else ['memory-rule','control']
 for mode in modes:
  request=ROOT/'requests'/('club-full-r1.json' if mode=='control' else 'club-memory-rule.json')
  schedule.append({'id':f'd12-{mode}-r{repeat}','decision':12,'history':'full','variant':mode,'repeat':repeat,
                   'request':str(request),'seed':str(seeds[12,'full'])})
plan={'purpose':'Predeclared6-request memory-contract instruction diagnostic. No production edit, acceptance claim or card-specific hint.',
      'runtime':'Same native0.160.0 and production CodexPlayingTransport/LunaMedium/no-tools; temporary RPC relay uses locally generated supported method thread/inject_items.',
      'schedule':schedule,'count':len(schedule),
      'predictions':['If explicit fallibility of earlier assistant responses/reasoning helps reassessment, the candidate should choose CA more often than contemporaneous controls under the same full original history. Inspect reasons/remaining plan as well; a card alone is not overall quality acceptance.'],
      'policy':'Three predetermined replicates per named condition; sequential, no retries/fallback/answer repair. History contains only the actual original authorized prefix, never a desired answer. Every injected/fresh HTTP request must be audited before interpreting content.',
      'limits':'History injection is diagnostic, not a product recovery feature. New sampling/time still vary; three samples per cell cannot establish reliability or exact probability. A failed injected request remains an unsuccessful probe; no silent fallback.'}
(study/'PLAN.json').write_text(json.dumps(plan,indent=2)+'\n')
native='/Users/tingranwang/.nvm/versions/node/v24.12.0/lib/node_modules/@openai/codex/node_modules/@openai/codex-darwin-arm64/vendor/aarch64-apple-darwin/bin/codex'
rows=[]
for entry in schedule:
 d=study/'runs'/entry['id'];d.mkdir(parents=True,exist_ok=False)
 log=(d/'proxy-stderr.txt').open('w')
 proxy=subprocess.Popen([sys.executable,str(REPO/'Scripts/capture-playing-wire.py'),'--codex',native,'--output',str(d/'wire')],stdout=subprocess.PIPE,stderr=log)
 row=dict(entry);start=time.monotonic()
 try:
  executable=acceptance.proxy_wrapper(proxy)
  if entry['seed']:
   relay=d/'relay';relay.write_text('#!'+sys.executable+'\n'+(ROOT/'history_relay.py').read_text());relay.chmod(0o700)
   pathlib.Path(str(relay)+'.json').write_text(json.dumps({'executable':executable,'seed':entry['seed'],'ack':str(d/'injection-ack.json'),'dry_run':False}))
   executable=str(relay)
  r=run_owned_runtime([str(ROOT/'probe'),entry['request'],str(d/'runtime'),executable,str(pathlib.Path.home()/'.codex/auth.json')],env=dict(os.environ),cwd=ROOT,timeout=210)
  (d/'stdout.txt').write_text(r.stdout);(d/'stderr.txt').write_text(r.stderr);row['exit_code']=r.returncode
  if r.returncode==0:
   row['raw_output']=json.loads((d/'runtime/raw-output.txt').read_text())
   row['identity']=json.loads((d/'runtime/identity.json').read_text())
  if (d/'injection-ack.json').exists():row['injection']=json.loads((d/'injection-ack.json').read_text())
 except Exception as e:row['error']=str(e)
 finally:
  proxy.terminate()
  try:proxy.wait(timeout=5)
  except subprocess.TimeoutExpired:proxy.kill();proxy.wait()
  log.close()
 row['seconds']=round(time.monotonic()-start,3)
 (d/'outcome.json').write_text(json.dumps(row,indent=2,ensure_ascii=False)+'\n');rows.append(row)
 (study/'results.json').write_text(json.dumps({'attempts':rows},indent=2,ensure_ascii=False)+'\n')
 print(entry['id'],'exit',row.get('exit_code'),'card',row.get('raw_output',{}).get('selectedCard'),'seconds',row['seconds'],flush=True)
(study/'execution-finished.json').write_text(json.dumps({'attempts':len(rows),'scope':'diagnostic only'},indent=2)+'\n')
