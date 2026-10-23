#!/usr/bin/env python3
"""Public-record bindings and window facts only; no hidden fixture or model call."""
import argparse
import hashlib
import json
from pathlib import Path


def sha(data):
    return hashlib.sha256(data).hexdigest()


def showouts(events):
    return [event for start in range(0, len(events), 4)
            if events[start]['card'].startswith('C')
            for event in events[start+1:start+4]
            if event['seat'] in ('east', 'west') and not event['card'].startswith('C')]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, default=Path('/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup'))
    parser.add_argument('--proof', type=Path, default=Path(__file__).with_name('candidate3-short-3-r1-public-proof.json'))
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    root = args.repo/'evals/stage1/evidence/issue48/ticket52/candidate3'
    directory = root/'short-3-r1'
    candidate_bytes = (root/'candidate.json').read_bytes()
    candidate = json.loads(candidate_bytes)
    assert candidate['source_commit'] == '3f0fc65470633dd90363ad0417b29a9f7f68be18'
    trace_bytes = (directory/'play/trace.json').read_bytes()
    input_bytes = (directory/'grade/input.json').read_bytes()
    assert sha(trace_bytes) == '412e663d2ba2708ad4aca9351937c4482a3a04edcca45db9ef6a8078db7803df'
    assert sha(input_bytes) == 'e72610689684653a04dd46af2d1c835f111c72cb65b673c69576916602e73b6d'
    trace, package = json.loads(trace_bytes), json.loads(input_bytes)
    decisions = package['decisions']
    assert len(decisions) == trace['modelActions'] == 12 and trace['mechanicalActions'] == 0
    events = list(trace['initialEvents'])
    for step in trace['steps']:
        events.append(step['execution']['event'] if 'execution' in step else step['event'])
    assert len(events) == 23 and [event['sequence'] for event in events] == list(range(23))
    assert len({event['card'] for event in events}) == len(events)
    prior_plan = None
    records = []
    names = {'N':'north', 'E':'east', 'S':'south', 'W':'west'}
    initial = json.loads(decisions[0]['authorized_input'])
    outside = 13 - sum(len(hand['C']) for hand in initial['hands'].values())
    assert outside == 5
    model_steps = [step for step in trace['steps'] if 'decision' in step]
    assert len(model_steps) == 12
    for row, step in zip(decisions, model_steps):
        decision_path = directory/'play'/row['id']/'decision.json'
        decision_bytes = decision_path.read_bytes()
        record = json.loads(decision_bytes)
        facts = row['decision_time_facts']
        snapshot = json.loads(row['authorized_input'])
        answer = json.loads(row['raw_output'])
        revision = facts['revision']
        assert record == step['decision']
        assert record['snapshot'] == facts and record['canonicalInput'] == row['authorized_input']
        assert record['input'] == row['actual_player_input'] == row['authorized_input']
        assert record['rawOutput'] == row['raw_output']
        assert facts['events'] == events[:revision]
        assert record['effectivePlan'] == row['effective_plan']
        assert snapshot['effectivePlan'] == prior_plan
        assert snapshot['current']['toAct'] in ('N','S')
        assert names[snapshot['current']['toAct']] == facts['actingSeat']
        holding = next(hand['cards'] for hand in facts['hands'] if hand['seat'] == facts['actingSeat'])
        assert answer['selectedCard'] in holding and answer['selectedCard'] in facts['legalCards']
        if facts['currentTrick'] and any(card[0] == facts['currentTrick'][0]['card'][0] for card in holding):
            assert answer['selectedCard'][0] == facts['currentTrick'][0]['card'][0]
        event = step['execution']['event']
        assert step['execution']['source'] == 'model'
        assert event == {'sequence':revision, 'seat':facts['actingSeat'], 'card':answer['selectedCard']}
        assert step['actualEvents'] == events[:revision+1]
        operation = answer['plan']['update']
        if operation == 'replace': prior_plan = answer['plan']['text']
        elif operation == 'withdraw': prior_plan = None
        else: assert operation == 'keep'
        assert prior_plan == row['effective_plan']
        records.append({'id':row['id'], 'revision':revision, 'selectedCard':answer['selectedCard'],
                        'plan_operation':operation, 'publicReason':answer['publicReason'],
                        'decision_sha256':sha(decision_bytes), 'authorized_input_sha256':sha(row['authorized_input'].encode()),
                        'raw_output_sha256':sha(row['raw_output'].encode()),
                        'exact_prefix_and_once_execution_bound':True})
    club_events = {seat:[event for event in events if event['seat'] == seat and event['card'].startswith('C')]
                   for seat in ('west','east')}
    first_out = {seat:next((event for event in showouts(events) if event['seat'] == seat), None)
                 for seat in ('west','east')}
    windows = []
    for seat, cards in club_events.items():
        if len(cards) < 3: continue
        third = cards[2]
        other = 'east' if seat == 'west' else 'west'
        if first_out[other] is None or third['sequence'] < first_out[other]['sequence']:
            windows.append({'third_club':third, 'other_first_showout':first_out[other]})
    assert [event['card'] for event in club_events['west']] == ['C3','C9','CJ']
    assert [event['card'] for event in club_events['east']] == ['C5','CT']
    assert first_out['east'] == {'card':'H2','seat':'east','sequence':13}
    assert club_events['west'][2]['sequence'] == 15 and windows == []
    assert records[6]['revision'] == 12 and records[7]['revision'] == 14
    assert records[7]['selectedCard'] == 'CK'
    proof = {
        'scope':'Public facts, bindings and actual window eligibility only. Semantic quality/core conclusions remain in the independent report; no hidden fixture is read.',
        'attempt':'short-3-r1', 'source_commit':candidate['source_commit'],
        'candidate_metadata_sha256':sha(candidate_bytes), 'trace_sha256':sha(trace_bytes), 'grade_input_sha256':sha(input_bytes),
        'raw_grader_sha256':sha((directory/'grade/grader-output.json').read_bytes()),
        'evaluation_sha256':sha((directory/'grade/evaluation.json').read_bytes()),
        'initial_partnership_clubs':8, 'initial_defender_clubs':outside,
        'all12_model_records':records, 'actual_events':events,
        'defender_club_events':club_events, 'first_club_showouts':first_out,
        'second_complete_club_round_end_sequence':11,
        'public_possible_lengths_after_two_rounds':[{'west':3,'east':2},{'west':2,'east':3}],
        'remaining_club_after_two_rounds':'CJ',
        'owner_after_east_first_showout_at_sequence13':'west',
        'first_model_owner_localization':records[7],
        'eligible_third_club_before_other_first_showout_event_windows':windows,
        'eligible_third_club_model_windows':[],
        'prior_equivalent_localization_before_west_third_club':{'established_by':'East H2 discard on club C7 at sequence13','model_revision':14,'third_west_club_sequence':15},
        'facet_result':'unexercised: first other-defender show-out precedes third club; correct post-show-out localization is outside the fixed stronger facet',
        'limits':'No matrix-level cohort result is inferred; the other fixed repetitions are unreviewed here. No phrase/length/forced-replace gate is applied.',
    }
    if args.write:
        args.proof.write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n')
        print(f'Wrote {args.proof}')
    else: assert json.loads(args.proof.read_text()) == proof
    print('12 final model records/prefixes/plan effects bound; East show-out seq13 precedes West third-club seq15; no eligible stronger window.')


if __name__ == '__main__': main()
