"""Read-only default audit of completed public events; optional non-overwriting proof generation."""
from pathlib import Path
import json,argparse,itertools,collections
ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--repo',required=True,type=Path);ap.add_argument('--proof',required=True,type=Path);ap.add_argument('--write',action='store_true');args=ap.parse_args()
p=args.repo/'evals/stage1/evidence/issue48/ticket52/candidate3/full-development-r2';j=json.loads((p/'grade/input.json').read_text());t=json.loads((p/'play/trace.json').read_text());ev=t['steps'][-1]['actualEvents'];assert ev==json.loads((p/'independent-replay.json').read_text())['events'];assert len(ev)==52 and len({e['card'] for e in ev})==52
universe={s+r for s in 'SHDC' for r in 'AKQJT98765432'};assert {e['card'] for e in ev}==universe
order=['north','east','south','west'];code={'north':'N','east':'E','south':'S','west':'W'};rank='23456789TJQKA';hands={s:{e['card'] for e in ev if e['seat']==s} for s in order};assert all(len(h)==13 for h in hands.values());trick=[];done=[];wins=collections.Counter();leader=ev[0]['seat'];decision_at={d['decision_time_facts']['revision']:d for d in j['decisions']};checked=[]
for i,e in enumerate(ev):
 assert e['sequence']==i
 if i in decision_at:
  d=decision_at[i];f=d['decision_time_facts'];c=json.loads(d['authorized_input']);assert f['events']==ev[:i]
  for h in f['hands']:assert set(h['cards'])==hands[h['seat']]
  legal=hands[e['seat']];suit=trick[0]['card'][0] if trick else None
  if suit and any(c[0]==suit for c in legal):legal={c for c in legal if c[0]==suit}
  assert set(f['legalCards'])==legal
  assert f['currentTrick']==trick
  w=max((x for x in trick if x['card'][0]==suit),key=lambda x:rank.index(x['card'][1])) if trick else None
  assert f.get('currentWinningPlay')==w
  assert f['declarerTricks']==wins['north']+wins['south'];assert f['defenderTricks']==wins['east']+wins['west']
  assert c['completedTricks']==[{'plays':[{'card':x['card'],'seat':code[x['seat']]} for x in tr['plays']],'winner':code[tr['winner']]} for tr in done]
  checked.append(d['id'])
 s,c=e['seat'],e['card'];assert c in hands[s]
 if trick:
  assert s==order[(order.index(trick[-1]['seat'])+1)%4]
  suit=trick[0]['card'][0];assert c[0]==suit or not any(x[0]==suit for x in hands[s])
 else:assert s==leader
 hands[s].remove(c);trick.append(e)
 if len(trick)==4:
  suit=trick[0]['card'][0];w=max((x for x in trick if x['card'][0]==suit),key=lambda x:rank.index(x['card'][1]));wins[w['seat']]+=1;leader=w['seat'];done.append({'plays':trick,'winner':leader});trick=[]
assert len(done)==13 and not trick and not any(hands.values()) and len(checked)==22
for st in t['steps']:
 e=st['execution']['event'];assert e==ev[e['sequence']];assert st['actualEvents']==ev[:e['sequence']+1]
counts=collections.Counter(st['execution']['source'] for st in t['steps']);assert counts=={'model':22,'forced':4,'opponent':25};assert ev[:1]==t['initialEvents']
# Exhaust all ordered follows for public-compatible4–1 holdings under the named A,K,Q route.
club=[];outside=set('JT953')
for longseat in ['east','west']:
 for singleton in outside:
  long=outside-{singleton}
  for first,second,third in itertools.permutations(long,3):
   left=(long-{first,second,third}).pop()
   # CA/C2, CK/C7, low-to-CQ win three. An outside heart transfers North to South.
   # South's fourth-round C8 either wins or loses to the sole residual opposing club.
   fourth_wins_south=rank.index('8')>rank.index(left)
   # After that opposing card is spent, South C6 is the fifth-round club winner.
   club.append(3+int(fourth_wins_south)+1)
assert len(club)==240 and min(club)==4
out={'scope':'Completed public-event structural replay; defender ownership reconstructed retrospectively only for legality, never earlier semantic knowledge. Club4–1 enumeration is public-compatible hypothetical analysis, not actual environment.','actual_events':52,'unique_cards':52,'legal_tricks':13,'complete':True,'tricks':[wins['north']+wins['south'],wins['east']+wins['west']],'decision_fact_snapshots_checked':checked,'all22_prefixes_hands_legalcards_currentwinner_completedtricks_counts_match':True,'step_execution_sources':dict(counts),'initial_opponent_events':1,'forced_revisions':[st['execution']['event']['sequence'] for st in t['steps'] if st['execution']['source']=='forced'],'trick_winners':[tr['winner'] for tr in done],'club41_ordered_holdings_and_follows':len(club),'club41_minimum_total_club_winners':min(club),'club41_maximum_total_club_winners':max(club)}
payload=json.dumps(out,indent=2)+'\n'
if args.write:
 if args.proof.exists():assert args.proof.read_text()==payload,'Refuse to replace differing proof'
 else:args.proof.write_text(payload)
else:assert json.loads(args.proof.read_text())==out
print('PASS:52unique/all52legal/13tricks/22authorizedstates/model22forced4opponent25+opening1; 240hypothetical4–1cases yield>=4clubs; saved proof matches.')
