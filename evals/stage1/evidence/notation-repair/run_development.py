"""One actual affected continuity attempt on the frozen notation/rank-rule repair."""
from pathlib import Path
import json,sys
ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT/'evals/stage1'))
import acceptance
out=Path(__file__).resolve().parent/'live-candidate'
candidate=acceptance.load(out/'candidate.json')
acceptance.preflight(candidate)
attempt={'id':'development-normal','case_id':'short-2','kind':'short','board':'boards/synthetic.json','decisions':8,'opponent_policy':'conserve-high'}
acceptance.write(out/'development-plan.json',{'hypothesis':'Notation/rank-rule-only playing change; evaluator v4 separate; actual continuing public entry, one affected attempt, no answer retries. Diagnose any failure before next changed candidate.','attempt':attempt})
result=acceptance.run_attempt(candidate,attempt,out)
acceptance.write(out/'development-summary.json',result)
print(json.dumps({k:result[k] for k in ['id','outcome','quality_counts','counts','timing','wire']},indent=2))
