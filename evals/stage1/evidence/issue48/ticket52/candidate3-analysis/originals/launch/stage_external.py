"""Stage completed external inputs verbatim; final masters/audit assets append later."""
from pathlib import Path
import hashlib,json
context=Path('/tmp/bridge-coup-issue48-context')
repo=Path('/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup')
analysis=repo/'evals/stage1/evidence/issue48/ticket52/candidate3-analysis'
paths=[]
for source in sorted(context.iterdir()):
 if source.name.startswith(('candidate3-','check_candidate3','final-tracker-snapshot','final-acceptance-report','legacy-obligations-after-cycle3')):
  if source.is_dir():
   if source.name not in ('candidate3-launch','candidate3-package-draft'):continue  # Active audit-output directories append only after their author seals them.
   folder='launch' if source.name=='candidate3-launch' else 'package-draft'
   for path in sorted(source.rglob('*')):
    if path.is_file() and '__pycache__' not in path.parts:paths.append((path,Path('originals')/folder/path.relative_to(source)))
  else:paths.append((source,Path('originals')/source.name))
rows=[]
for source,relative in paths:
 data=source.read_bytes();target=analysis/relative;target.parent.mkdir(parents=True,exist_ok=True)
 if target.exists():assert target.read_bytes()==data,('Previously staged original differs',source,target)
 else:target.write_bytes(data)
 rows.append({'original_path':str(source),'portable_path':relative.as_posix(),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
manifest={'scope':'IN-PROGRESS packaging input checkpoint: completed22 adjudication/proofs/launch/tracker records staged verbatim for CPU audit. Final master/ledger and helper audit originals append before final sealing/commit; this is not the final external inventory.','files':sorted(rows,key=lambda r:r['original_path'])}
(analysis/'external-preservation.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps({'external_input_checkpoint_files':len(rows),'final_external_inventory':False},indent=2))
