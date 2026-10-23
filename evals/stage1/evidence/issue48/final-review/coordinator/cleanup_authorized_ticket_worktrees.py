"""Remove only the seven authorized ticket worktrees after committed preservation."""
import argparse,datetime,hashlib,json,os,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--integration-commit',required=True);p.add_argument('--execute',action='store_true');a=p.parse_args()
repo=Path('/Users/tingranwang/.codex/worktrees/issue46-integration/bridge-coup')
ctx=Path('/tmp/bridge-coup-issue48-context')
names=['issue49-reviewed-first','issue50-review-loop','issue51-review-recovery','issue48-review-fixes','issue48-candidate2','issue48-candidate3','issue52-reviewed-acceptance']
def git(args,cwd=repo):return subprocess.check_output(['git',*args],cwd=cwd,text=True).strip()
assert git(['rev-parse','HEAD'])==a.integration_commit
assert not git(['diff','--name-only']) and not git(['diff','--cached','--name-only'])
records=[]
for n in names:
 w=Path('/Users/tingranwang/.codex/worktrees')/n/'bridge-coup';assert w.is_dir() and not w.is_symlink()
 head=git(['rev-parse','HEAD'],w)
 subprocess.run(['git','merge-base','--is-ancestor',head,a.integration_commit],cwd=repo,check=True)
 assert not git(['diff','--name-only'],w) and not git(['diff','--cached','--name-only'],w)
 untracked=git(['ls-files','--others','--exclude-standard','-z'],w).split('\0');untracked=[x for x in untracked if x]
 caches=[]
 for f in untracked:
  q=w/f;assert '__pycache__' in q.parts and q.suffix=='.pyc' and q.is_file() and not q.is_symlink(),(w,f)
  caches.append({'path':f,'sha256':hashlib.sha256(q.read_bytes()).hexdigest(),'bytes':q.stat().st_size})
 ignored=git(['ls-files','--others','--ignored','--exclude-standard','-z'],w).split('\0');ignored=[x for x in ignored if x]
 assert all(Path(f).parts[0]=='.build' for f in ignored),(w,'unexpectedignored')
 records.append({'path':str(w),'branch':git(['branch','--show-current'],w),'head_preserved_in_integration':head,'generated_cache_files':caches,'ignored_build_files':len(ignored)})
result={'observed_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'integration_commit':a.integration_commit,'execute':a.execute,'records':records,'branches_retained':True,'removed':[],'protected_workspaces_untouched':['issue46-integration','userprimary','allolderworktrees']}
out=ctx/('cleanup-final-execution.json' if a.execute else 'cleanup-final-preflight.json')
assert not out.exists(),out
out.write_text(json.dumps(result,indent=2)+'\n')
if a.execute:
 for r in records:
  w=Path(r['path'])
  for f in r['generated_cache_files']:
   q=w/f['path'];assert hashlib.sha256(q.read_bytes()).hexdigest()==f['sha256'];q.unlink()
  subprocess.run(['git','worktree','remove',str(w)],cwd=repo,check=True)
  result['removed'].append(str(w));out.write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'execute':a.execute,'worktrees_checked':len(records),'removed':len(result['removed']),'receipt':str(out)}))
