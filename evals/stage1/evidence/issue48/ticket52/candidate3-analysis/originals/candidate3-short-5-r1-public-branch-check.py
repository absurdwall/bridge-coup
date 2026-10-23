"""Public-compatible counterfactual; never reads evaluator fixture or future actual holdings."""
from pathlib import Path
import json
root=Path('/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup/evals/stage1/evidence/issue48/ticket52/candidate3/short-5-r1')
d=json.loads((root/'grade/input.json').read_text())['decisions'][6]
deal={'north':'S3 S6 S5 H4 H3 DK DQ D9 D7 D5 CA CT C4'.split(),'south':'SA SQ S7 S4 HA HK H6 H2 D4 D3 CK C7 C3'.split(),'west':'SJ ST S9 S8 DT D6 DA C6 HT H9 H8 H7 H5'.split(),'east':'SK S2 DJ D8 D2 CQ CJ C9 C8 C5 C2 HQ HJ'.split()}
assert len(set(sum(deal.values(),[])))==52 and all(len(h)==13 for h in deal.values())
hands={s:set(h) for s,h in deal.items()};prefix=d['decision_time_facts']['events'];rank='23456789TJQKA';order=['north','east','south','west'];trick=[];expected_leader='west'
def play(e):
 global trick, expected_leader
 s,c=e['seat'],e['card'];assert c in hands[s],(s,c)
 if not trick:assert s==expected_leader,(s,expected_leader)
 if trick:
  assert s==order[(order.index(trick[-1]['seat'])+1)%4]
  suit=trick[0]['card'][0]
  assert c[0]==suit or not any(x[0]==suit for x in hands[s]),(s,c,'revoke')
 hands[s].remove(c);trick.append(e)
 if len(trick)==4:
  suit=trick[0]['card'][0];w=max((x for x in trick if x['card'][0]==suit),key=lambda x:rank.index(x['card'][1]));trick=[];expected_leader=w['seat'];return w['seat']
for e in prefix:play(e)
for h in d['decision_time_facts']['hands']:assert hands[h['seat']]==set(h['cards'])
play({'seat':'north','card':'DK','sequence':18});winner=play({'seat':'east','card':'D2','sequence':19});assert winner=='north'
assert sorted(c for c in hands['north'] if c[0]=='D')==['D7','D9','DQ'];assert 'DA' in hands['west'] and 'DJ' in hands['east']
for e in [{'seat':'north','card':'DQ','sequence':20},{'seat':'east','card':'DJ','sequence':21},{'seat':'south','card':'S7','sequence':22},{'seat':'west','card':'DA','sequence':23}]:
 winner2=play(e)
assert winner2=='west' and {c for c in hands['north'] if c[0]=='D'}=={'D9','D7'}
assert not any(c[0]=='D' for s in ('east','west') for c in hands[s])
out={'purpose':'Counterfactual public-compatible branch, not actual environment or hidden quality facts','decision':d['id'],'branch_initial_defender_diamonds':{'west':['DA','DT','D6'],'east':['DJ','D8','D2']},'authorized_prefix_cards':len(prefix),'all_52_unique':True,'all_prefix_plays_legal':True,'controlled_remaining_hands_match':True,'current_continuation':[{'seat':'north','card':'DK'},{'seat':'east','card':'D2'}],'winner':winner,'north_remaining_diamonds':['DQ','D9','D7'],'defenders_remaining_diamonds':{'west':['DA'],'east':['DJ']},'verified_next_trick':['north DQ','east DJ','south S7 (discard)','west DA'],'north_after_next_trick':['D9','D7'],'remaining_defender_diamonds_after_next_trick':[],'conclusion':'A 3–3 break does not itself make Q97 immediate winners after DK wins; DA must still be driven out. Leading DQ then losing to DA leaves D97 (two future diamonds) plus already-won DK (three total). The active force-out-DA route remains feasible with CA retained; this branch alone establishes no material route failure.'}
print(json.dumps(out,indent=2));Path('/tmp/bridge-coup-issue48-context/candidate3-short-5-r1-public-branch-check.json').write_text(json.dumps(out,indent=2)+'\n')
