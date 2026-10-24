"""Read-only completed-trace material diagnosis; no model and no source changes."""
import importlib.util,json
from pathlib import Path
repo=Path('/Users/tingranwang/.codex/worktrees/issue46-integration/bridge-coup')
root=Path('/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup/evals/stage1/evidence/issue48/ticket52/candidate1')
spec=importlib.util.spec_from_file_location('corpus',repo/'evals/stage1/corpus.py');corpus=importlib.util.module_from_spec(spec);spec.loader.exec_module(corpus)
board=json.loads((repo/'evals/stage1/corpus/boards/synthetic.json').read_text())
results=[]
for run in ('short-3-r1','short-3-r2','short-3-r3'):
 trace=json.loads((root/run/'play/trace.json').read_text());events=trace['steps'][-1]['actualEvents'];club_count={'west':0,'east':0};windows=[]
 for index,event in enumerate(events):
  if event['seat'] not in club_count or not event['card'].startswith('C'):continue
  club_count[event['seat']]+=1
  if club_count[event['seat']]!=3:continue
  state=corpus.replay(board,events[:index+1]);trick=state['currentTrick']
  first_round_start=index-len(trick)+1
  prior_void=any(e['seat']=='east' and not e['card'].startswith('C') for e in events[first_round_start:index])
  if not trick or not trick[0]['card'].startswith('C') or prior_void:continue
  actor=state['actingSeat'];holding=state['hands'][actor];led=trick[0]['card'][0]
  legal=sorted(c for c in holding if c.startswith(led)) or sorted(holding)
  if actor not in ('north','south'):continue
  actual_step=next(s for s in trace['steps'] if s['execution']['event']['sequence']==index+1)
  ordinal=sum(e['seat'] in ('north','south') for e in events[1:index+2])
  windows.append({'revision':index+1,'observed_third_club':event,'actingSeat':actor,'legalCards':legal,'actual_source':actual_step['execution']['source'],'hypothetical_model_ordinal_with_mechanical_false_on_same_event_route':ordinal,'within_unchanged_12_bound':ordinal<=12})
 results.append({'run':run,'third_club_first_controlled_windows':windows})
assert results[0]['third_club_first_controlled_windows']==[]
assert results[1]['third_club_first_controlled_windows'][0]['legalCards']==['CQ']
assert results[2]['third_club_first_controlled_windows'][0]['legalCards']==['C7']
output=Path('/tmp/bridge-coup-issue48-context/short3-coverage-witness.json')
output.write_text(json.dumps({'scope':'Completed candidate1 routes replayed solely for offline prospective coverage diagnosis. Reclassification does not predict new model choices or quality. Full fixture stays evaluator-only.','results':results},indent=2)+'\n')
print(output.read_text())
