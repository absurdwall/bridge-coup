"""Completed metadata only; never read unfinished proposal/reviewer semantics."""
from pathlib import Path
import json,os,subprocess
root=Path('/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup/evals/stage1/evidence/issue48/ticket52/candidate3')
plan=json.loads((root/'plan.json').read_text());complete=[];started=[]
for row in plan:
 d=root/row['id']
 if (d/'summary.json').exists():
  s=json.loads((d/'summary.json').read_text())
  complete.append({'id':row['id'],'task':s['task_complete'],'legal':s['legal_execution'],'raw_quality':s['quality'],'raw_outcome':s['outcome'],'coverage':s['coverage']['status'],'counts':s['quality_counts'],'board_complete':s['counts'].get('complete'),'tricks':s['counts'].get('tricks'),'model_actions':s['counts'].get('model_actions'),'forced_actions':s['counts'].get('forced_actions'),'rpc_requests':s['counts'].get('actual_rpc_requests'),'automatic_seconds':s['timing'].get('automaticRuntimeSeconds'),'artifact':str(d)})
 elif d.exists():started.append(row['id'])
registry=json.loads((Path(__file__).parent/'execution/detached-registry.json').read_text());pid=registry['pid']
p=subprocess.run(['ps','-p',str(pid),'-o','pid=,ppid=,pgid=,stat=,etime=,command='],capture_output=True,text=True)
print(json.dumps({'completed':len(complete),'attempts':complete,'started_unfinished':started,'runner_alive':p.returncode==0 and not p.stdout.split()[3].startswith('Z') and 'acceptance.py run --output' in p.stdout,'runner':p.stdout.strip(),'execution_finished':(root/'execution-finished.json').exists()},indent=2))
