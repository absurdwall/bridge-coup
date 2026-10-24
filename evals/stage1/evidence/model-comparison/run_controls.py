"""User-requested sequential continuous8 diagnostics; never stage acceptance.

Use frozen352d61f modules with only requested model/effort literals changed in an
isolated diagnostic package. The production target/source remain untouched.
Sol acting output is packaged for coordinator review, not graded by Sol itself.
"""
import difflib,hashlib,json,os,subprocess,sys,tempfile,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
COMMIT='352d61f'
sys.path.insert(0,str(ROOT/'evals/stage1'))
import acceptance,evaluate
schedule=[{'id':'luna-max','model':'gpt-6-luna','effort':'max'},
          {'id':'sol-medium','model':'gpt-6.1-sol','effort':'medium'},
          {'id':'astra-medium','model':'gpt-6-astra','effort':'medium'}]
with (OUT/'plan.json').open('x') as stream:
 json.dump({'diagnostic_only':True,'base_commit':COMMIT,'schedule':schedule,'attempts_per_config':1,'decisions':8,'retry_policy':'No answer retries/rerolls; all attempts retained.','fixed':'instructions/schema/deal/opponent/limits/rubric; target-specific catalog differences audited.','sol_player_evaluation':'Same rubric and public package, coordinator direct independent review; no Sol model call to grade its own acting output.','acceptance_credit':False},stream,indent=2)
# Finish the already-started High playing AND grading call before any next model request.
high=ROOT/'evals/stage1/evidence/high-effort-diagnostic/summary.json'
deadline=time.monotonic()+1800
while not high.exists():
 if time.monotonic()>deadline:raise TimeoutError('Existing High diagnostic did not produce terminal summary; no new call started')
 time.sleep(.5)
results=[]
modules=['BridgeDomain','BridgeEngine','BridgeExpert','BridgeCodex','BridgeDriver','BridgePlayCLI']
files=subprocess.check_output(['git','ls-tree','-r','--name-only',COMMIT,'--']+['Sources/'+m for m in modules],cwd=ROOT,text=True).splitlines()
manifest=(ROOT/'evals/stage1/evidence/high-effort-diagnostic/diagnostic-Package.swift.txt').read_text()
for spec in schedule:
 out=OUT/spec['id'];out.mkdir(exist_ok=False)
 source=Path(tempfile.mkdtemp(prefix='bridge-'+spec['id']+'-source-'));(source/'Package.swift').write_text(manifest)
 provenance=[];delta=[]
 for name in files:
  data=subprocess.check_output(['git','show',COMMIT+':'+name],cwd=ROOT);original=data.decode();changed=original
  if name=='Sources/BridgeCodex/CodexTransport.swift':
   changed=changed.replace('private static let model = "gpt-6-luna"','private static let model = '+json.dumps(spec['model']))
   changed=changed.replace('private static let effort = "medium"','private static let effort = '+json.dumps(spec['effort']))
   changed=changed.replace('    model = "gpt-6-luna"','    model = '+json.dumps(spec['model']))
   changed=changed.replace('    model_reasoning_effort = "medium"','    model_reasoning_effort = '+json.dumps(spec['effort']))
   delta=list(difflib.unified_diff(original.splitlines(keepends=True),changed.splitlines(keepends=True),fromfile=COMMIT+'/'+name,tofile='diagnostic-'+spec['id']+'/'+name))
  target=source/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(changed)
  provenance.append({'path':name,'original_sha256':hashlib.sha256(data).hexdigest(),'diagnostic_sha256':hashlib.sha256(changed.encode()).hexdigest(),'unchanged':changed==original})
 assert sum(not r['unchanged'] for r in provenance)==1
 (out/'source-config-only.patch').write_text(''.join(delta))
 acceptance.write(out/'source-provenance.json',{'source_path':str(source),'base_commit':COMMIT,'config':spec,'files':provenance,'manifest_same_as_high_harness':True,'actual_support_gate':'Unmodified transport start() calls model/list and verifies selected model and supportedReasoningEfforts before any turn; actual catalogAcknowledgement saved in play/rpc.jsonl.'})
 env=dict(os.environ);env.pop('SDKROOT',None)
 with (out/'build.log').open('w') as log:
  subprocess.run(['swift','build','--package-path',str(source),'--product','bridge-play'],cwd=ROOT,env=env,stdout=log,stderr=log,check=True,timeout=180)
 candidate=acceptance.load(ROOT/'evals/stage1/evidence/reason-order-repair/live-candidate/candidate.json')
 candidate.update(binary=str(source/'.build/debug/bridge-play'),binary_sha256=hashlib.sha256((source/'.build/debug/bridge-play').read_bytes()).hexdigest(),requested_play_model=spec['model'],requested_play_effort=spec['effort'],diagnostic_only=True,source_override='See source-provenance.json and source-config-only.patch; not unmodified production binary.')
 acceptance.write(out/'candidate.json',candidate)
 attempt={'id':'continuous-1','case_id':'short-2','kind':'short','board':'boards/synthetic.json','decisions':8,'opponent_policy':'conserve-high','diagnostic_only':True,'requested_model':spec['model'],'requested_effort':spec['effort']}
 if spec['model']!='gpt-6.1-sol':
  result=acceptance.run_attempt(candidate,attempt,out)
 else:
  # Same actual public driver/capture/replay, with self-model grading omitted.
  directory=out/'continuous-1';directory.mkdir(exist_ok=False);acceptance.write(directory/'attempt.json',{**attempt,'status':'started','playing_retries':0})
  wire=directory/'wire';log=(directory/'proxy-stderr.txt').open('w')
  proxy=subprocess.Popen([sys.executable,str(ROOT/'Scripts/capture-playing-wire.py'),'--codex',candidate['codex'],'--output',str(wire)],stdout=subprocess.PIPE,stderr=log)
  started=time.monotonic()
  try:
   wrapper=acceptance.proxy_wrapper(proxy)
   command=[candidate['binary'],'--fixture',str(ROOT/'evals/stage1/corpus/boards/synthetic.json'),'--output',str(directory/'play'),'--codex',wrapper,'--timeout','180','--run-timeout','1800','--opponent','conserve-high','--sole-legal','true','--decisions','8']
   acceptance.write(directory/'play-command.json',command)
   with (directory/'play-stdout.txt').open('w') as stdout,(directory/'play-stderr.txt').open('w') as stderr:
    process=acceptance.bounded_command(command,stdout,stderr,1830)
   outcome={'exit_code':process.returncode,'wall_seconds':round(time.monotonic()-started,3)}
  except Exception as error:outcome={'exit_code':None,'runner_error':str(error),'wall_seconds':round(time.monotonic()-started,3)}
  finally:
   proxy.terminate()
   try:proxy.wait(timeout=5)
   except subprocess.TimeoutExpired:proxy.kill();proxy.wait()
   log.close()
  acceptance.write(directory/'playing-outcome.json',outcome)
  decisions=acceptance.decision_directories(directory/'play')
  records=[(p.name,evaluate.read_decision(p)) for p in decisions]
  grade=directory/'grade';grade.mkdir();acceptance.write(grade/'input.json',evaluate.grader_package(records))
  acceptance.write(directory/'grading-outcome.json',{'model_called':False,'exit_code':None,'grading_evidence_available':False,'reason':'Sol acting output not self-graded; same v4 public package requires coordinator direct review.'})
  acceptance.write(directory/'attempt.json',{**attempt,'status':'finished','playing_retries':0})
  result=acceptance.summarize_attempt(attempt,directory)
 acceptance.write(out/'summary.json',result)
 results.append({'config':spec,'summary_path':str(out/'summary.json'),'outcome':result['outcome'],'quality_counts':result['quality_counts'],'counts':result['counts'],'timing':result['timing']})
 acceptance.write(OUT/'results.json',results)
 print(spec['id'],result['outcome'],result['quality_counts'],flush=True)
