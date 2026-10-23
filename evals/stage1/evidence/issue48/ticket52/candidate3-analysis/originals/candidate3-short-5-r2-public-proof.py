"""Offline public-compatible proof; never reads hidden fixture or actual future play."""
from pathlib import Path
import json, argparse
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--repo',type=Path,required=True,help='Repository root containing frozen candidate3 evidence')
parser.add_argument('--proof',type=Path,required=True,help='Saved proof JSON to check, or explicit generation destination')
parser.add_argument('--write',action='store_true',help='Generate proof only if absent; never replace differing existing bytes')
args=parser.parse_args()
root=args.repo/'evals/stage1/evidence/issue48/ticket52/candidate3/short-5-r2'
j=json.loads((root/'grade/input.json').read_text())
deal={'north':'S3 S6 S5 H4 H3 DK DQ D9 D7 D5 CA CT C4'.split(),'south':'SA SQ S7 S4 HA HK H6 H2 D4 D3 CK C7 C3'.split(),'west':'SJ ST S9 S8 DT D6 CQ CJ C9 C6 HT H9 H5'.split(),'east':'SK S2 DA DJ D8 D2 C8 C5 C2 HQ HJ H8 H7'.split()}
assert len(set(sum(deal.values(),[])))==52 and all(len(h)==13 for h in deal.values())
rank='23456789TJQKA';order=['north','east','south','west']
class Replay:
 def __init__(self):self.hands={s:set(h) for s,h in deal.items()};self.trick=[];self.leader='west';self.winners=[]
 def play(self,e):
  s,c=e['seat'],e['card'];assert c in self.hands[s],(s,c)
  if self.trick:
   assert s==order[(order.index(self.trick[-1]['seat'])+1)%4]
   suit=self.trick[0]['card'][0];assert c[0]==suit or not any(x[0]==suit for x in self.hands[s]),(s,c,'revoke')
  else:assert s==self.leader
  self.hands[s].remove(c);self.trick.append(e)
  if len(self.trick)==4:
   suit=self.trick[0]['card'][0];w=max((x for x in self.trick if x['card'][0]==suit),key=lambda x:rank.index(x['card'][1]));self.trick=[];self.leader=w['seat'];self.winners.append(w['seat'])
validated=[]
for d in j['decisions'][6:11]:
 r=Replay()
 for e in d['decision_time_facts']['events']:r.play(e)
 for h in d['decision_time_facts']['hands']:assert r.hands[h['seat']]==set(h['cards'])
 validated.append(d['id'])
r=Replay()
for e in j['decisions'][10]['decision_time_facts']['events']:r.play(e)
assert len(r.winners)==6 and sum(s in ['north','south'] for s in r.winners)==4
continuation=[('north','DK'),('east','DJ'),('south','S4'),('west','ST'),('north','D9'),('east','D2'),('south','S7'),('west','H9'),('north','D7'),('east','C5'),('south','H2'),('west','S9'),('north','C4'),('east','C8'),('south','CK'),('west','CQ'),('south','HA'),('west','HT'),('north','H4'),('east','HJ')]
for s,c in continuation:r.play({'seat':s,'card':c})
assert sum(s in ['north','south'] for s in r.winners)==9
out={'purpose':'Constructed public-compatible counterfactual only; not actual hidden holdings or actual outcome','all52_unique':True,'original_defender_diamonds':{'west':['DT','D6'],'east':['DA','DJ','D8','D2']},'all_authorized_prefixes_legal_and_controlled_hands_match':validated,'counterbranch':'On DK, East plays DJ from J2 and West shows out. D97 both win; DJ is no longer outstanding.','legal_counterfactual_continuation_from_d11':[{'seat':s,'card':c} for s,c in continuation],'prior_declarer_tricks':4,'final_declarer_tricks':9,'new_winning_tricks':['DK','D9','D7','CK','HA'],'materiality':'D7–D11 retained branch says only one immediate diamond winner and an outstanding jack, although this exact showout branch has three diamond winners and a feasible nine-trick route with CK/HA. D12 later replacement is judged separately.','spade_count_check':{'initial_ns_spades':7,'initial_ew_spades':6,'defender_cards_consumed_in_two_spade_rounds':4,'maximum_defender_spades_left_after_d3_trick':2},'initial_favorable_ace_example':{'west':['DA','D6'],'east':['DJ','DT','D8','D2'],'two_diamond_rounds':[['south D3','west D6','north D5','east D8'],['south D4','west DA','north D7','east D2']],'north_after_round_two':['DK','DQ','D9'],'east_after_round_two':['DJ','DT'],'result':'Three diamond winners by cashing K,Q,9; West DA appears before North chooses D7. This is a favorable doubleton-ace example, not a guarantee of all ace-doubleton layouts.'},'hostile_ace_example':{'west':['DJ','DT','D6','D2'],'east':['DA','D8'],'two_diamond_rounds':[['south D3','west D6','north D5','east D8'],['south D4','west DT','north DQ','east DA']],'north_after_round_two':['DK','D9','D7'],'west_after_round_two':['DJ','D2'],'result':'West may follow D2 under DK, retaining DJ over97. This demonstrates failure of universal doubleton-ace protection for the selected honor route, which the qualified delivered plan does not claim.'},'initial_doubleton_ace_claim_limit':'The delivered initial plan qualifies 4–2 as favorable and allows following revealed cards. The raw forced-cover counterexample is not an exhaustive refutation of that qualified possibility: two low ducks can preserve KQ9 against the remaining J8, producing three diamonds. This proof does not claim the delivered D6 honor choice takes that alternative or guarantees every doubleton-ace layout.'}
payload=json.dumps(out,indent=2)+'\n'
if args.write:
 if args.proof.exists():
  assert args.proof.read_text()==payload,'Existing proof differs; refusing to overwrite'
 else:args.proof.write_text(payload)
else:
 assert json.loads(args.proof.read_text())==out,'Saved proof does not match independently reconstructed results'
print('PASS: 52 unique cards; D7–D11 authorized prefixes/legal follows/controlled hands; J-drop plus showout; five-winner continuation to nine; saved proof matches.')
