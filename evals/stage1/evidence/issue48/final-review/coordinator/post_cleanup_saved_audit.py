"""Verify historical saved evidence after all seven ticket paths are absent."""
import concurrent.futures,datetime,hashlib,json,os,subprocess,sys,time
from pathlib import Path
repo=Path('/Users/tingranwang/.codex/worktrees/issue46-integration/bridge-coup');ctx=Path('/tmp/bridge-coup-issue48-context')
names=['issue49-reviewed-first','issue50-review-loop','issue51-review-recovery','issue48-review-fixes','issue48-candidate2','issue48-candidate3','issue52-reviewed-acceptance']
assert all(not (Path('/Users/tingranwang/.codex/worktrees')/n/'bridge-coup').exists() for n in names)
env=dict(os.environ,PYTHONDONTWRITEBYTECODE='1');commands=[]
for n in (1,2,3):
 d=repo/f'evals/stage1/evidence/issue48/ticket52/candidate{n}-analysis'
 for f in ('verify_preservation.py','check_lifetime_portability.py'):
  commands.append([sys.executable,str(d/f),'--repo',str(repo)])
d=repo/'evals/stage1/evidence/issue48/ticket52/candidate3-analysis';raw=d.with_name('candidate3')
commands += [[sys.executable,str(d/'audit_native_plan_encoding.py'),'--candidate',str(raw)],[sys.executable,str(d/'aggregate.py'),str(raw)]]
def run(cmd):
 t=time.monotonic();p=subprocess.run(cmd,cwd=repo,env=env,text=True,capture_output=True)
 return {'command':cmd,'exit_code':p.returncode,'elapsed_seconds':time.monotonic()-t,'stdout':p.stdout,'stderr':p.stderr}
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:results=list(pool.map(run,commands))
protected=json.loads((ctx/'pre-cleanup-protected-workspace.json').read_text())
for f in protected['integration_untracked_cache_files']:assert hashlib.sha256((repo/f['path']).read_bytes()).hexdigest()==f['sha256']
primary=Path(protected['primary'])
for k,args in [('head',['rev-parse','HEAD']),('branch',['branch','--show-current']),('git_status',['status','--porcelain=v1','--untracked-files=all'])]:
 actual=subprocess.check_output(['git',*args],cwd=primary,text=True)
 assert (actual if k=='git_status' else actual.strip())==protected['primary_'+k],k
record={'observed_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'all_seven_ticket_worktree_paths_absent':True,'integration_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip(),'protected_integration_cache_files_unchanged':len(protected['integration_untracked_cache_files']),'user_primary_head_branch_status_unchanged':True,'results':results,'scope':'CPU-only saved evidence audits after actual ticket worktree removal; no native/model/grader/build/source/GitHub mutation. Lifetime checks additionally use source-changed temporary skeletons without build/native/Git.'}
out=ctx/'candidate3-post-cleanup-portability-audit.json';assert not out.exists();out.write_text(json.dumps(record,indent=2)+'\n')
for r in results:print(Path(r['command'][1]).parent.name,Path(r['command'][1]).name,r['exit_code'])
assert all(r['exit_code']==0 for r in results)
print('PASS postcleanup8checks,20cachefiles anduserprimaryunchanged')
