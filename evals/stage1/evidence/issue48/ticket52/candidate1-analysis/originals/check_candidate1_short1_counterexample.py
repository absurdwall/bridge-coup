"""Read-only conditional proof: synthesized unseen deal, not actual played split."""
import importlib.util, json, hashlib
from pathlib import Path
repo=Path('/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup')
corpus_path=repo/'evals/stage1/corpus.py'
spec=importlib.util.spec_from_file_location('corpus',corpus_path)
corpus=importlib.util.module_from_spec(spec);spec.loader.exec_module(corpus)
record_path=repo/'evals/stage1/evidence/issue48/ticket52/candidate1/short-1-r1/play/decision.json'
record=json.loads(record_path.read_text())
known={h['seat']:h['cards'] for h in record['snapshot']['hands']}
east='CJ CT C9 C5 C3 D2 DJ D4 H2 H9 HQ S3 S5'.split()
full={s+r for s in 'SHDC' for r in corpus.RANKS}
west=sorted(full-set(east)-set(known['north'])-set(known['south']))
board={'contract':record['snapshot']['contract'],'hands':[{'seat':s,'cards':known.get(s,east if s=='east' else west)} for s in corpus.SEATS]}
plays=[('west','DQ'),('north','D3'),('east','D2'),('south','DA'),
       ('south','C4'),('west','S7'),('north','CQ'),('east','C3'),
       ('north','C2'),('east','C9'),('south','C8'),('west','ST'),
       ('east','H2'),('south','HA'),('west','H5'),('north','H4'),
       ('south','H3'),('west','H8'),('north','HK'),('east','H9'),
       ('north','C7'),('east','CT'),('south','CA'),('west','SJ'),
       ('south','CK'),('west','SQ'),('north','S2'),('east','C5'),
       ('south','C6'),('west','SK'),('north','S6'),('east','CJ')]
events=[{'sequence':i,'seat':s,'card':c} for i,(s,c) in enumerate(plays)]
assert events[:2]==record['snapshot']['events']+[{'sequence':1,'seat':'north','card':'D3'}]
initial=corpus.replay(board,events[:1])
for s in ['north','south']: assert initial['hands'][s]==set(known[s])
tricks=[]
for stop in range(4,len(events)+1,4):
 state=corpus.replay(board,events[:stop]); prior=corpus.replay(board,events[:stop-4])
 side='declarer' if state['declarerTricks']>prior['declarerTricks'] else 'defenders'
 tricks.append({'plays':events[stop-4:stop],'winning_side':side,'is_club_trick':events[stop-4]['card'].startswith('C')})
club_wins=sum(t['is_club_trick'] and t['winning_side']=='declarer' for t in tricks)
assert club_wins==3
state=corpus.replay(board,events)
assert not any(c.startswith('C') for cards in state['hands'].values() for c in cards)
alternative_plays=plays[:8]+[
    ('north','C2'),('east','C9'),('south','CA'),('west','ST'),
    ('south','H3'),('west','H5'),('north','HK'),('east','H2'),
    ('north','C7'),('east','CT'),('south','CK'),('west','SJ'),
    ('south','C8'),('west','SQ'),('north','S2'),('east','CJ'),
    ('east','C5'),('south','C6'),('west','SK'),('north','S6')]
alternative_events=[{'sequence':i,'seat':s,'card':c} for i,(s,c) in enumerate(alternative_plays)]
alternative_tricks=[]
for stop in range(4,len(alternative_events)+1,4):
    current=corpus.replay(board,alternative_events[:stop]);previous=corpus.replay(board,alternative_events[:stop-4])
    won=current['declarerTricks']>previous['declarerTricks']
    alternative_tricks.append({'plays':alternative_events[stop-4:stop],'winning_side':'declarer' if won else 'defenders','is_club_trick':alternative_events[stop-4]['card'].startswith('C')})
alternative_club_wins=sum(t['is_club_trick'] and t['winning_side']=='declarer' for t in alternative_tricks)
assert alternative_club_wins==4
assert not any(c.startswith('C') for cards in current['hands'].values() for c in cards)
result={'scope':'Counterfactual conditional diagnostic only. Not actual acceptance environment/play; no hidden fixture read, no model calls.','source_decision':str(record_path),'source_sha256':hashlib.sha256(record_path.read_bytes()).hexdigest(),'reducer_sha256':hashlib.sha256(corpus_path.read_bytes()).hexdigest(),'counterfactual_board':board,'all_32_events_legal':True,'club_tricks_taken_by_declarer':club_wins,'all_clubs_consumed':True,'tricks':tricks,'alternative_covering_nine':{'scope':'Diagnostic comparison only, does not validate the actual stated otherwise-eight instruction.','all_28_events_legal':True,'club_tricks_taken_by_declarer':alternative_club_wins,'tricks':alternative_tricks},'interpretation':'Honor means T/J/Q/K/A. East C9 is not an honor, so the stated otherwise-C8 branch loses to C9. Subsequent low club from North is covered on East CT, but South C6 eventually loses CJ; QAK supply only three club tricks.'}
Path('/tmp/bridge-coup-issue48-context/candidate1-short1-counterexample.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({k:result[k] for k in ['all_32_events_legal','club_tricks_taken_by_declarer','all_clubs_consumed','source_sha256']}))
