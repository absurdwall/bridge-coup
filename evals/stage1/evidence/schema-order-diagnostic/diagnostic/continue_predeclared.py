"""Predeclared three-config control and schema-order probes at sealed-public-D4, sequential, no reroll.

Fresh app-server sessions receive identical recorded PUBLIC history; no opaque
reasoning is replayed or fabricated. This is diagnostic, not acceptance evidence.
Authentication is copied privately and never logged; HTTP capture stores no headers.
"""
import copy,hashlib,json,os,re,select,shutil,signal,subprocess,tempfile,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[5]
OUT=Path(__file__).resolve().parent
OLD=ROOT/'evals/stage1/evidence/winner-fact-repair/live-candidate/development-normal'
CLI=Path('/Users/tingranwang/.nvm/versions/node/v24.12.0/bin/codex')
AUTH=Path(os.environ.get('CODEX_HOME',str(Path.home()/'.codex')))/'auth.json'
def write(p,x):p.write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n')
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
rows=[json.loads(s) for s in (OLD/'play/rpc.jsonl').read_text().splitlines()]
requests=[r['value'] for r in rows if r['kind']=='request']
start=next(r['params'] for r in requests if r['method']=='thread/start')
turns=[r['params'] for r in requests if r['method']=='turn/start']
parts=['Sealed mid-board diagnostic. The following is the recorded public conversation. Earlier assistant suggestions are advice; actual-play messages are observed events. Answer the final current request, using the supplied output schema. No hidden reasoning is supplied.']
for i in range(3):
 d=json.loads((OLD/f'play/decision-{i+1:04d}/decision.json').read_text())
 assert turns[i]['input'][0]['text']==d['input']
 parts += [f'Earlier public turn {i+1}\nUSER:\n'+d['input']+'\nASSISTANT:\n'+d['rawOutput']]
parts += ['FINAL CURRENT USER REQUEST:\n'+turns[3]['input'][0]['text']]
sealed='\n\n'.join(parts)
(OUT/'sealed-public-input.txt').write_text(sealed)
write(OUT/'sealed-schema.json',turns[3]['outputSchema'])
plan={'kind':'sealed-public-D4-fresh-session','source_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
 'model':'gpt-6-luna','effort':'medium','runtime':subprocess.check_output([str(CLI),'--version'],text=True).strip(),
 'input_sha256':hashlib.sha256(sealed.encode()).hexdigest(),'instructions_sha256':hashlib.sha256(start['baseInstructions'].encode()).hexdigest(),
 'schema_sha256':hashlib.sha256(json.dumps(turns[3]['outputSchema'],sort_keys=True).encode()).hexdigest(),
 'schedule':['luna-medium-plan-2','luna-medium-reason-2'],'retries':0,
 'scope':'Tests isolation effect on sealed public history, NOT original continuous opaque history. No quality acceptance claim.',
 'hypotheses':[{'id':'H1','prediction':'If inherited role/catalog is load-bearing, agents disable reduces the specific CA/CQ factual-purpose defect under identical sealed public context.'},
 {'id':'H2','prediction':'If anchoring on prior wrong plan is load-bearing, defects may persist in both isolation arms.'},
 {'id':'H3','prediction':'If resource accounting from event-only continuity is load-bearing, isolation alone will not reliably fix it.'},
 {'id':'H4','prediction':'If plan/action contract sequencing is load-bearing, isolation alone will not reliably fix final-output inconsistency.'}],
 'predeclared_checks':['CQ cannot win the current trick above South CA; a legal unblock is acceptable.',
 'North CQ/C7 both follow to CA/CK; future use of remaining North clubs cannot be assumed after those rounds.',
 'No invented cards/entries; both legal cards can be acceptable when purpose/plan is feasible.']}
with (OUT/'continuation-plan.json').open('x') as f:json.dump(plan,f,indent=2)
assert AUTH.is_file(),'Configured ChatGPT authentication unavailable (contents not read for diagnostics)'
results=[]
samples={name:{'model':'gpt-6.1-sol' if name=='sol-medium-control' else 'gpt-6-luna','effort':'high' if name=='luna-high-control' else 'medium','reason_first':'reason-' in name} for name in plan['schedule']}
plan['samples']=samples
plan['scope']='Three-config diagnostic (one sample/config) plus two-per-arm schema-order diagnostic sharing first Luna/medium baseline sample. No opaque replay or acceptance claim.'
plan['hypotheses']=[{'id':'contract-order','prediction':'If plan-first final serialization biases the current rationale, publicReason-first with identical schema semantics/context will reduce the specific CQ-under-CA winner contradiction.'},{'id':'configuration-control','prediction':'Higher effort or Sol may change this primitive error; catalog/tool differences and one-sample uncertainty must be disclosed. Accepted player remains Luna/medium.'}]
# Persist the complete predeclared schedule before any request; the initial plan file is generated above in this same invocation.
write(OUT/'continuation-plan.json',plan)
for name in plan['schedule']:
 sample=samples[name]
 run=OUT/name;run.mkdir(exist_ok=False)
 proxylog=(run/'proxy-stderr.txt').open('w')
 proxy=subprocess.Popen(['python3',str(ROOT/'Scripts/capture-playing-wire.py'),'--codex',str(CLI),'--output',str(run/'wire')],stdout=subprocess.PIPE,stderr=proxylog,text=True,start_new_session=True)
 process=None;began=time.monotonic();public=[];buffer=b'';sequence=1
 try:
  assert select.select([proxy.stdout],[],[],10)[0],'Capture proxy failed to initialize'
  wrapper=proxy.stdout.readline().strip();assert Path(wrapper).is_file(),wrapper
  with tempfile.TemporaryDirectory(prefix='bridge-sealed-D4-') as temp:
   runtime=Path(temp);home=runtime/'home';home.mkdir();cwd=runtime/'cwd';cwd.mkdir()
   shutil.copy2(AUTH,home/'auth.json');os.chmod(home/'auth.json',0o600)
   config=re.sub(r'path = "[^"]+/home/skills/','path = "'+str(home.resolve())+'/skills/',(OLD/'play/runtime-config.toml').read_text())
   if name.startswith('agents-disabled'):config+='\n[agents]\nenabled = false\n'
   config=re.sub(r'^model = .*$', 'model = '+json.dumps(sample['model']),config,flags=re.M)
   config=re.sub(r'^model_reasoning_effort = .*$', 'model_reasoning_effort = '+json.dumps(sample['effort']),config,flags=re.M)
   (home/'config.toml').write_text(config);(run/'runtime-config.toml').write_text(config)
   env={'HOME':str(runtime),'CODEX_HOME':str(home),'PATH':str(CLI.parent)+':/usr/bin:/bin:/usr/sbin:/sbin'}
   args=[wrapper,'app-server','--listen','stdio://','-c','model_providers.bridge-wire-audit.request_max_retries=0','-c','model_providers.bridge-wire-audit.stream_max_retries=0']
   err=(run/'runtime-stderr.txt').open('w')
   process=subprocess.Popen(args,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=err,env=env,cwd=cwd,start_new_session=True)
   def read(deadline):
    global buffer
    while time.monotonic()<deadline:
     if b'\n' in buffer:
      line,buffer=buffer.split(b'\n',1)
      if line:return json.loads(line)
     if not select.select([process.stdout],[],[],max(0,deadline-time.monotonic()))[0]:break
     chunk=os.read(process.stdout.fileno(),65536)
     if not chunk:break
     buffer+=chunk
    raise TimeoutError('app-server request deadline')
   def call(method,params,reply=True):
    global sequence
    request={'method':method,'params':params}
    if reply:request['id']=sequence;sequence+=1
    public.append({'kind':'request','value':request});process.stdin.write((json.dumps(request)+'\n').encode());process.stdin.flush()
    if not reply:return
    deadline=time.monotonic()+180
    while True:
     row=read(deadline)
     if row.get('id')==request['id']:
      public.append({'kind':'response','value':row})
      if 'error' in row:raise RuntimeError(str(row['error']))
      return row['result']
   call('initialize',{'clientInfo':{'name':'bridge-declarer','version':'1'},'capabilities':{'experimentalApi':True}})
   call('initialized',{},False)
   catalog=call('model/list',{'includeHidden':True})
   match=next(m for m in catalog['data'] if m['model']==sample['model']);write(run/'catalog-acknowledgement.json',match)
   assert any(e['reasoningEffort']==sample['effort'] for e in match['supportedReasoningEfforts']), 'Requested diagnostic effort not explicitly supported'
   threadparams=copy.deepcopy(start);threadparams['cwd']=str(cwd);threadparams['model']=sample['model']
   thread=call('thread/start',threadparams);threadid=thread['thread']['id']
   params=copy.deepcopy(turns[3]);params['threadId']=threadid;params['model']=sample['model'];params['effort']=sample['effort'];params['input']=[{'type':'text','text':sealed,'text_elements':[]}]
   if sample['reason_first']:
    props=params['outputSchema']['properties'];params['outputSchema']['properties']={k:props[k] for k in ['publicReason','plan','selectedCard']}
   turn=call('turn/start',params);turnid=turn['turn']['id']
   deadline=time.monotonic()+180
   while True:
    row=read(deadline)
    if 'id' in row and 'method' in row:raise RuntimeError('Unexpected runtime tool/approval request; not executed')
    if row.get('method')=='turn/completed':
     value=row['params']['turn'];assert value['id']==turnid
     value['items']=[item for item in value.get('items',[]) if item.get('type')=='agentMessage']
     public.append({'kind':'completion','value':value});write(run/'public-completion.json',value)
     assert value['status']=='completed',value.get('error')
     text=value['items'][-1]['text'];(run/'raw-output.txt').write_text(text)
     try:write(run/'decoded-output.json',json.loads(text))
     except json.JSONDecodeError:pass
     results.append({'id':name,'status':'completed','model':sample['model'],'effort':sample['effort'],'observed_model':thread.get('model'),'schema_order':list(params['outputSchema']['properties']),'thread_id':threadid,'turn_id':turnid,'wall_seconds':time.monotonic()-began,'retries':0})
     break
   process.stdin.close();process.terminate();process.wait(timeout=5);err.close()
 except Exception as e:
  results.append({'id':name,'status':'failed','error':str(e),'wall_seconds':time.monotonic()-began,'retries':0})
 finally:
  if process and process.poll() is None:os.killpg(process.pid,signal.SIGKILL);process.wait()
  proxy.terminate()
  try:proxy.wait(timeout=5)
  except subprocess.TimeoutExpired:proxy.kill();proxy.wait()
  proxylog.close()
  write(run/'public-rpc.json',public);write(OUT/'continuation-outcomes.json',results)
 print(name,results[-1]['status'],round(results[-1]['wall_seconds'],3),flush=True)
 if results[-1]['status']!='completed':break
