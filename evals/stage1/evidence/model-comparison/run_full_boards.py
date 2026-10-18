"""One matched complete development board/config, sequential, no acceptance credit."""
import hashlib,json,subprocess,sys,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4];BASE=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'evals/stage1'));import acceptance,evaluate
OUT=BASE/'full-boards';OUT.mkdir(exist_ok=False)
schedule=[{'id':'luna-max','model':'gpt-6-luna','effort':'max'},{'id':'sol-medium','model':'gpt-6.1-sol','effort':'medium'},{'id':'astra-medium','model':'gpt-6-astra','effort':'medium'}]
acceptance.write(OUT/'plan.json',{'diagnostic_only':True,'source_base':'352d61f','schedule':schedule,'attempts_per_config':1,'task':'All52cards, thirteen legal tricks, same synthetic board/conserve-high/sole-legal true. Every nonforced controlled choice via public Expert.','request_timeout_seconds':180,'run_timeout_seconds':1800,'retries':0,'evaluation':'samev4;Solactingrequiresdirectindependentreview,noselfgrade','acceptance_credit':False})
results=[]
for spec in schedule:
 old=BASE/spec['id'];candidate=acceptance.load(old/'candidate.json');provenance=acceptance.load(old/'source-provenance.json')
 for row in provenance['files']:
  file=Path(provenance['source_path'])/row['path'];assert hashlib.sha256(file.read_bytes()).hexdigest()==row['diagnostic_sha256']
 acceptance.preflight(candidate)
 out=OUT/spec['id'];out.mkdir();acceptance.write(out/'candidate.json',candidate)
 acceptance.write(out/'reuse-verification.json',{'binary_and_runtime_preflight':'pass','source_files_match_diagnostic_provenance':True,'source_provenance':str(old/'source-provenance.json'),'original8control':str(old/'summary.json'),'requested':spec})
 attempt={'id':'full-1','case_id':'full-development','kind':'full','board':'boards/synthetic.json','decisions':None,'opponent_policy':'conserve-high','diagnostic_only':True,'requested_model':spec['model'],'requested_effort':spec['effort']}
 if spec['model']!='gpt-6.1-sol':
  result=acceptance.run_attempt(candidate,attempt,out)
 else:
  directory=out/'full-1';directory.mkdir();acceptance.write(directory/'attempt.json',{**attempt,'status':'started','playing_retries':0})
  wire=directory/'wire';log=(directory/'proxy-stderr.txt').open('w')
  proxy=subprocess.Popen([sys.executable,str(ROOT/'Scripts/capture-playing-wire.py'),'--codex',candidate['codex'],'--output',str(wire)],stdout=subprocess.PIPE,stderr=log)
  started=time.monotonic()
  try:
   wrapper=acceptance.proxy_wrapper(proxy)
   command=[candidate['binary'],'--fixture',str(ROOT/'evals/stage1/corpus/boards/synthetic.json'),'--output',str(directory/'play'),'--codex',wrapper,'--timeout','180','--run-timeout','1800','--opponent','conserve-high','--sole-legal','true','--full-board','true']
   acceptance.write(directory/'play-command.json',command)
   with (directory/'play-stdout.txt').open('w') as stdout,(directory/'play-stderr.txt').open('w') as stderr:process=acceptance.bounded_command(command,stdout,stderr,1830)
   outcome={'exit_code':process.returncode,'wall_seconds':round(time.monotonic()-started,3)}
  except Exception as error:outcome={'exit_code':None,'runner_error':str(error),'wall_seconds':round(time.monotonic()-started,3)}
  finally:
   proxy.terminate()
   try:proxy.wait(timeout=5)
   except subprocess.TimeoutExpired:proxy.kill();proxy.wait()
   log.close()
  acceptance.write(directory/'playing-outcome.json',outcome)
  decisions=acceptance.decision_directories(directory/'play');records=[(p.name,evaluate.read_decision(p)) for p in decisions]
  grade=directory/'grade';grade.mkdir();acceptance.write(grade/'input.json',evaluate.grader_package(records))
  acceptance.write(directory/'grading-outcome.json',{'model_called':False,'exit_code':None,'grading_evidence_available':False,'reason':'Solactingoutputrequirescoordinatordirectreview,samev4package,noselfgrade.'})
  acceptance.write(directory/'attempt.json',{**attempt,'status':'finished','playing_retries':0});result=acceptance.summarize_attempt(attempt,directory)
 acceptance.write(out/'summary.json',result)
 results.append({'config':spec,'outcome':result['outcome'],'quality_counts':result['quality_counts'],'counts':result['counts'],'timing':result['timing'],'summary':str(out/'summary.json')})
 acceptance.write(OUT/'results.json',results);print(spec['id'],result['outcome'],result['quality_counts'],result['timing'].get('elapsedSeconds'),flush=True)
