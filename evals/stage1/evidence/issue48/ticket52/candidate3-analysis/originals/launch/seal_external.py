"""After Spec finalization only: preserve final original inputs and central documents."""
from pathlib import Path
import hashlib,json
context=Path('/tmp/bridge-coup-issue48-context')
repo=Path('/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup')
analysis=repo/'evals/stage1/evidence/issue48/ticket52/candidate3-analysis'
for name in ('final-acceptance-report.md','legacy-obligations-after-cycle3.md','candidate3-evidence-helper-audit.md'):
 assert (context/name).is_file(),name
paths=[]
directories={'candidate3-launch':'launch','candidate3-package-draft':'package-draft','candidate3-evidence-helper-audit-checks':'helper-audit-checks'}
for source in sorted(context.iterdir()):
 if source.name.startswith(('candidate3-','check_candidate3','final-tracker-snapshot','final-acceptance-report','legacy-obligations-after-cycle3')):
  if source.is_dir():
   assert source.name in directories,source
   for path in sorted(source.rglob('*')):
    if path.is_file() and '__pycache__' not in path.parts:paths.append((path,Path('originals')/directories[source.name]/path.relative_to(source)))
  else:paths.append((source,Path('originals')/source.name))
paths.append((context/'COORDINATION.md',Path('originals/COORDINATION-at-candidate3-final.md')))
rows=[]
for source,relative in paths:
 data=source.read_bytes();target=analysis/relative;target.parent.mkdir(parents=True,exist_ok=True)
 if target.exists():assert target.read_bytes()==data,('Previously staged original differs',source,target)
 else:target.write_bytes(data)
 rows.append({'original_path':str(source),'portable_path':relative.as_posix(),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
manifest={'scope':'Final cycle3 external originals, retained verbatim after all22 runs/independent overlays and Spec final master+ledger/freshtracker/helper audit. Historical drafts/checkpoints preserve their original limits, not current authorization or a quality pass. Original raw/model evidence remains unchanged.','files':sorted(rows,key=lambda r:r['original_path'])}
(analysis/'external-preservation.json').write_text(json.dumps(manifest,indent=2)+'\n')
central=repo/'evals/stage1/evidence/issue48'
for source,name in [('final-acceptance-report.md','ACCEPTANCE-REPORT.md'),('legacy-obligations-after-cycle3.md','OBLIGATION-LEDGER.md')]:
 data=(context/source).read_bytes();target=central/name
 if target.exists():assert target.read_bytes()==data,('Existing central document differs',target)
 else:target.write_bytes(data)
print(json.dumps({'external_originals':len(rows),'central_documents_copied_verbatim':True,'raw_originals_unchanged':True},indent=2))
