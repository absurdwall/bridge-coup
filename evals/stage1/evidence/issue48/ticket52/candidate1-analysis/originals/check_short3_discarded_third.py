"""Offline authored legality witness for predicate semantics, NOT production policy evidence."""
import importlib.util,json
from pathlib import Path
repo=Path('/Users/tingranwang/.codex/worktrees/issue46-integration/bridge-coup')
spec=importlib.util.spec_from_file_location('corpus',repo/'evals/stage1/corpus.py');corpus=importlib.util.module_from_spec(spec);spec.loader.exec_module(corpus)
board=json.loads((repo/'evals/stage1/corpus/boards/synthetic.json').read_text())
plays=[('west','DQ'),('north','D3'),('east','D4'),('south','DK'),('south','CA'),('west','C3'),('north','C2'),('east','C5'),('south','CK'),('west','C9'),('north','C7'),('east','CT'),('south','H3'),('west','H5'),('north','HK'),('east','H2'),('north','H4'),('east','H8'),('south','HA'),('west','H9'),('south','H6'),('west','HT'),('north','H7'),('east','HJ'),('east','HQ'),('south','S4'),('west','CJ')]
events=[{'sequence':i,'seat':s,'card':c} for i,(s,c) in enumerate(plays)]
state=corpus.replay(board,events)
assert state['actingSeat']=='north'
assert len(state['currentTrick'])==3 and state['currentTrick'][0]['card']=='HQ'
seen={s:[e['card'] for e in events if e['seat']==s and e['card'].startswith('C')] for s in ('west','east')}
assert len(seen['west'])==3 and len(seen['east'])==2
assert not any(events[i-i%4]['card'].startswith('C') and e['seat']=='east' and not e['card'].startswith('C') for i,e in enumerate(events))
result={'status':'legal-authored-predicate-witness','scope':'Not live performance, not current conserve-high policy reachability. In particular East HQ at seq24 is a legal lead but current conserve-high would prefer its remaining opening-suit diamonds. No opponent/script substitution is proposed.','events':events,'window':{'revision':27,'actingSeat':'north','ledSuit':'H','third_defender_club':events[26],'observed_defender_clubs':seen,'other_first_club_showout':None,'legalCards':sorted(state['hands']['north'])},'public_inference':'Initially five opponent clubs; W C3/C9 and E C5/CT have appeared in two club rounds. West CJ discarded on a heart lead is the fifth, proving original W3/E2 without observing a future East club show-out/discard.'}
p=Path('/tmp/bridge-coup-issue48-context/short3-discarded-third-witness.json');p.write_text(json.dumps(result,indent=2)+'\n');print(p)
