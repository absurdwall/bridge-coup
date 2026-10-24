#!/usr/bin/env python3
"""Read-only public bindings and full-play legality; no hidden fixture is read."""
import argparse,collections,hashlib,json
from pathlib import Path

def sha(b): return hashlib.sha256(b).hexdigest()
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--repo',type=Path,default=Path('/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup'));p.add_argument('--proof',type=Path,default=Path(__file__).with_name('candidate3-full-reserved-r1-public-proof.json'));p.add_argument('--write',action='store_true');a=p.parse_args()
 root=a.repo/'evals/stage1/evidence/issue48/ticket52/candidate3';d=root/'full-reserved-r1';cb=(root/'candidate.json').read_bytes();candidate=json.loads(cb)
 assert candidate['source_commit']=='3f0fc65470633dd90363ad0417b29a9f7f68be18'
 tb=(d/'play/trace.json').read_bytes();ib=(d/'grade/input.json').read_bytes()
 assert sha(tb)=='b7c60f26bad5346177adb39f7642d305b3f9e926f79a93d88bf578fc41f023a0'
 assert sha(ib)=='b59568ce1343de971b58282cc494a4856dc7a6b874d200a3388c8d2a5b0d029c'
 t=json.loads(tb);g=json.loads(ib);ds=g['decisions'];events=list(t['initialEvents'])
 for s in t['steps']: events.append(s['execution']['event'] if 'execution'in s else s['event'])
 assert len(events)==52 and [e['sequence']for e in events]==list(range(52))
 assert {e['card']for e in events}=={s+r for s in'SHDC'for r in'23456789TJQKA'}
 assert collections.Counter(e['seat']for e in events)==dict.fromkeys(['north','east','south','west'],13)
 steps=[s for s in t['steps']if'decision'in s];assert len(ds)==len(steps)==t['modelActions']==21
 assert t['mechanicalActions']==5 and t['complete'] and t['controlledActions']==26
 previous=None;rows=[]
 for row,step in zip(ds,steps):
  data=(d/'play'/row['id']/'decision.json').read_bytes();r=json.loads(data);f=row['decision_time_facts'];s=json.loads(row['authorized_input']);out=json.loads(row['raw_output']);actual=json.loads(row['actual_player_input']);rev=f['revision']
  assert r==step['decision'] and r['snapshot']==f and r['canonicalInput']==row['authorized_input'] and r['input']==row['actual_player_input'] and r['rawOutput']==row['raw_output'] and r['effectivePlan']==row['effective_plan']
  if actual['type']in('revision','clarification'): assert actual['latestSnapshot']==s
  else: assert row['authorized_input']==row['actual_player_input']
  assert f['events']==events[:rev] and s['effectivePlan']==previous
  h=next(h['cards']for h in f['hands']if h['seat']==f['actingSeat']);assert out['selectedCard']in h and out['selectedCard']in f['legalCards']
  assert step['execution']=={'event':{'sequence':rev,'seat':f['actingSeat'],'card':out['selectedCard']},'source':'model'} and step['actualEvents']==events[:rev+1]
  op=out['plan']['update']
  if op=='replace':previous=out['plan']['text']
  elif op=='withdraw':previous=None
  else:assert op=='keep'
  assert row['effective_plan']==previous
  rows.append({'id':row['id'],'revision':rev,'card':out['selectedCard'],'plan_operation':op,'publicReason':out['publicReason'],'effective_plan':previous,'actual_input_type':actual['type'],'semantic_review_rounds':len(r['reviewRounds']),'decision_sha256':sha(data),'authorized_input_sha256':sha(row['authorized_input'].encode()),'raw_output_sha256':sha(row['raw_output'].encode()),'prefix_once_execution_plan_bound':True})
 assert collections.Counter(r['plan_operation']for r in rows)=={'keep':19,'replace':2}
 assert rows[6]['actual_input_type']=='revision' and sum(r['semantic_review_rounds']for r in rows)==22
 # Execution integrity only: reconstruct each original hand from all completed PUBLIC plays.
 # This is never used as decision-time knowledge or to grade an earlier answer.
 hands={seat:{e['card']for e in events if e['seat']==seat}for seat in['north','east','south','west']};order=['north','east','south','west'];leader='west';ranks='23456789TJQKA';won={'declarer':0,'defenders':0};tricks=[];facts_by_rev={r['decision_time_facts']['revision']:r['decision_time_facts']for r in ds}
 forced=[]
 for step in t['steps']:
  if step.get('execution',{}).get('source')=='forced':forced.append(step['execution']['event'])
 for start in range(0,52,4):
  plays=events[start:start+4];led=plays[0]['card'][0]
  for offset,e in enumerate(plays):
   rev=e['sequence'];seat=e['seat'];card=e['card'];assert seat==order[(order.index(leader)+offset)%4] and card in hands[seat]
   legal={c for c in hands[seat]if c[0]==led}if offset and any(c[0]==led for c in hands[seat])else set(hands[seat]);assert card in legal
   if rev in facts_by_rev:
    f=facts_by_rev[rev];assert f['actingSeat']==seat and set(f['legalCards'])==legal
    assert f['declarerTricks']==won['declarer'] and f['defenderTricks']==won['defenders']
    assert f['currentTrick']==plays[:offset] and f['completedTricks']==tricks
    for h in f['hands']:assert set(h['cards'])==hands[h['seat']]
   if e in forced:assert len(legal)==1
   hands[seat].remove(card)
  leader=max((e for e in plays if e['card'][0]==led),key=lambda e:ranks.index(e['card'][1]))['seat'];won['declarer'if leader in('north','south')else'defenders']+=1;tricks.append({'plays':plays,'winner':leader})
 assert not any(hands.values()) and won=={'declarer':12,'defenders':1}
 summary=json.loads((d/'summary.json').read_text());assert summary['counts']['actual_events']==52 and summary['quality_counts']=={'pass':21,'fail':0,'uncertain':0}
 role_counts=collections.Counter(r['role']for r in t['requestEvidence']);assert role_counts=={'player':22,'reviewer':22}
 proof={'scope':'Public prefix/card/plan bindings plus complete PUBLIC execution integrity. Full completed plays reconstruct hands ONLY for legality replay, never for earlier quality. No hidden fixture read.','attempt':'full-reserved-r1','classification':'used regression board, not fresh held-out','source_commit':candidate['source_commit'],'candidate_sha256':sha(cb),'trace_sha256':sha(tb),'grade_input_sha256':sha(ib),'raw_grader_sha256':sha((d/'grade/grader-output.json').read_bytes()),'evaluation_sha256':sha((d/'grade/evaluation.json').read_bytes()),'final_deliveries':rows,'actual_events':events,'tricks':tricks,'actual_result':won,'complete_52_distinct_13_per_seat_legal':True,'forced_sole_legal_events':forced,'actual_role_requests':dict(role_counts),'raw_quality':summary['quality_counts'],'independent_quality':{'pass':21,'fail':0,'uncertain':0},'quality_is_independent_human_adjudication_not_computed_by_this_checker':True}
 if a.write:a.proof.write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n');print('Wrote',a.proof)
 else:assert json.loads(a.proof.read_text())==proof
 print('21 final snapshots, prefixes, once execution and plan effects bound; all 52 distinct public cards legally replay to 13 tricks (NS12/EW1).')
if __name__=='__main__':main()
