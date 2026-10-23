#!/usr/bin/env python3
"""Public snapshot/execution/plan bindings only; no complete fixture is read."""
import argparse
import hashlib
import json
from pathlib import Path


def sha(data): return hashlib.sha256(data).hexdigest()


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo',type=Path,default=Path('/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup'))
    parser.add_argument('--proof',type=Path,default=Path(__file__).with_name('candidate3-short-6-r3-public-proof.json'))
    parser.add_argument('--write',action='store_true');args=parser.parse_args()
    root=args.repo/'evals/stage1/evidence/issue48/ticket52/candidate3';directory=root/'short-6-r3'
    candidate_bytes=(root/'candidate.json').read_bytes();candidate=json.loads(candidate_bytes)
    assert candidate['source_commit']=='3f0fc65470633dd90363ad0417b29a9f7f68be18'
    trace_bytes=(directory/'play/trace.json').read_bytes();input_bytes=(directory/'grade/input.json').read_bytes()
    assert sha(trace_bytes)=='33d7995eee011cc85650d833a36b27edf5165f234de154708056d21580a8456f'
    assert sha(input_bytes)=='a55a8482e4843fddbf1c00ead1e0a0be7ff9212cb28b33ababc4ea60200c1a61'
    trace=json.loads(trace_bytes);package=json.loads(input_bytes);decisions=package['decisions']
    assert len(decisions)==trace['modelActions']==12 and trace['mechanicalActions']==2
    events=list(trace['initialEvents'])
    for step in trace['steps']:events.append(step['execution']['event'] if 'execution'in step else step['event'])
    assert len(events)==28 and [e['sequence']for e in events]==list(range(28))
    assert len({e['card']for e in events})==28
    steps=[s for s in trace['steps']if'decision'in s];assert len(steps)==12
    previous_plan=None;rows=[]
    for row,step in zip(decisions,steps):
        path=directory/'play'/row['id']/'decision.json';data=path.read_bytes();record=json.loads(data)
        facts=row['decision_time_facts'];snapshot=json.loads(row['authorized_input']);answer=json.loads(row['raw_output']);actual=json.loads(row['actual_player_input']);revision=facts['revision']
        assert record==step['decision'] and record['snapshot']==facts
        assert record['canonicalInput']==row['authorized_input'] and record['input']==row['actual_player_input']
        assert record['rawOutput']==row['raw_output'] and record['effectivePlan']==row['effective_plan']
        if actual['type']in('revision','clarification'):assert actual['latestSnapshot']==snapshot
        else:assert row['actual_player_input']==row['authorized_input']
        assert facts['events']==events[:revision] and snapshot['effectivePlan']==previous_plan
        holding=next(h['cards']for h in facts['hands']if h['seat']==facts['actingSeat'])
        assert answer['selectedCard']in holding and answer['selectedCard']in facts['legalCards']
        if facts['currentTrick']and any(c[0]==facts['currentTrick'][0]['card'][0]for c in holding):assert answer['selectedCard'][0]==facts['currentTrick'][0]['card'][0]
        assert step['execution']=={'event':{'sequence':revision,'seat':facts['actingSeat'],'card':answer['selectedCard']},'source':'model'}
        assert step['actualEvents']==events[:revision+1]
        operation=answer['plan']['update']
        if operation=='replace':previous_plan=answer['plan']['text']
        elif operation=='withdraw':previous_plan=None
        else:assert operation=='keep'
        assert previous_plan==row['effective_plan']
        rows.append({'id':row['id'],'revision':revision,'card':answer['selectedCard'],'plan_operation':operation,
                     'publicReason':answer['publicReason'],'actual_input_type':actual['type'],
                     'semantic_review_rounds':len(record['reviewRounds']), 'decision_sha256':sha(data),
                     'authorized_input_sha256':sha(row['authorized_input'].encode()),'raw_output_sha256':sha(row['raw_output'].encode()),
                     'prefix_once_execution_plan_bound':True})
    assert rows[0]['actual_input_type']=='revision' and sum(r['semantic_review_rounds']for r in rows)==13
    assert events[3]=={'card':'S3','seat':'south','sequence':3}
    assert events[7]=={'card':'S9','seat':'south','sequence':7}
    assert events[11]=={'card':'SA','seat':'south','sequence':11}
    assert events[23]=={'card':'DA','seat':'east','sequence':23}
    assert events[24]=={'card':'CK','seat':'east','sequence':24}
    assert rows[-2]['card']=='CA' and rows[-1]['card']=='C5'
    preserved=json.loads(decisions[8]['authorized_input'])['hands']
    final=json.loads(decisions[-1]['authorized_input'])['hands']
    assert preserved['S']['H']=='J' and preserved['N']['H']=='A'
    assert preserved['N']['D']=='KQJT9' and final['N']['D']=='QJT9'
    assert final['S']['H']=='J' and final['N']['H']=='A'
    # Trick winners require only actual public plays, not defender holdings.
    ranks='23456789TJQKA';wins={'declarer':0,'defenders':0};winners=[]
    for start in range(0,28,4):
        trick=events[start:start+4];led=trick[0]['card'][0]
        winner=max(trick,key=lambda e:(e['card'][0]==led,ranks.index(e['card'][1])))['seat'];winners.append(winner)
        wins['declarer'if winner in('north','south')else'defenders']+=1
    assert wins=={'declarer':4,'defenders':3} and not trace['complete']
    proof={'scope':'Public record bindings and observable core events only; no actual complete fixture, hidden spade lengths or environment-only coverage conclusion.',
           'attempt':'short-6-r3','source_commit':candidate['source_commit'],'candidate_sha256':sha(candidate_bytes),
           'trace_sha256':sha(trace_bytes),'grade_input_sha256':sha(input_bytes),
           'raw_grader_sha256':sha((directory/'grade/grader-output.json').read_bytes()),'evaluation_sha256':sha((directory/'grade/evaluation.json').read_bytes()),
           'all12_final_model_records':rows,'actual_events':events,'completed_trick_winners':winners,'completed_tricks':wins,
           'actual_hold_up_south_cards':['S3','S9'],'forced_third_round_spade':'SA',
           'defender_continuation_before_diamond_concession':['SK','SQ','SJ'],
           'actual_diamond_ace_win':events[23],'actual_following_switch':events[24],
           'actual_model_recovery_cards':['CA','C5'],
           'critical_named_transfer_preserved_at_diamond_start':{'south':'HJ','north':'HA'},
           'critical_named_transfer_still_available_at_final_delivery':{'south':'HJ','north':'HA'},
           'late_diamond_cashout_public_cards':final['N']['D'],
           'east_public_spade_follows':['S4','S5','S6'],'east_void_publicly_established':False,
           'limits':'Three East spade follows and a later switch do not prove East exhausted spades. The final HJ-to-HA transfer/four diamond cashes have not occurred. Separate archived environment-only proof is not yet authorized/read here.'}
    if args.write:args.proof.write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n');print(f'Wrote {args.proof}')
    else:assert json.loads(args.proof.read_text())==proof
    print('12 finals/prefixes/plan effects bound; S3/S9 hold-ups, DA concession and CA recovery observed; HJ/HA preserved; actual East void not established from public facts.')


if __name__=='__main__':main()
