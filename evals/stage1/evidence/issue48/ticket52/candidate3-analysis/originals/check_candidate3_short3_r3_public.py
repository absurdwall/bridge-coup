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
    parser.add_argument('--proof', type=Path, default=Path(__file__).with_name('candidate3-short-3-r3-public-proof.json'))
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    root = args.repo/'evals/stage1/evidence/issue48/ticket52/candidate3'
    directory = root/'short-3-r3'
    candidate_bytes = (root/'candidate.json').read_bytes()
    candidate = json.loads(candidate_bytes)
    assert candidate['source_commit'] == '3f0fc65470633dd90363ad0417b29a9f7f68be18'
    trace_bytes = (directory/'play/trace.json').read_bytes()
    input_bytes = (directory/'grade/input.json').read_bytes()
    assert sha(trace_bytes) == '6af7c57ae2adedc49bae1f4b79085bcb7ed2c93545683e852cbb02d3660f4620'
    assert sha(input_bytes) == '2710587292a28fbee55e64b9c26ecd60ef90b869452915c1a69df5384b382110'
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
        assert record['input'] == row['actual_player_input']
        actual_input = json.loads(row['actual_player_input'])
        if actual_input['type'] in ('revision', 'clarification'):
            assert actual_input['latestSnapshot'] == snapshot
        else:
            assert row['actual_player_input'] == row['authorized_input']
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
                        'actual_input_type':actual_input['type'], 'semantic_review_rounds':len(record['reviewRounds']),
                        'decision_sha256':sha(decision_bytes), 'authorized_input_sha256':sha(row['authorized_input'].encode()),
                        'raw_output_sha256':sha(row['raw_output'].encode()),
                        'exact_prefix_and_once_execution_bound':True})
    assert sum(row['semantic_review_rounds'] for row in records) == 13
    assert records[0]['actual_input_type'] == 'revision' and records[0]['semantic_review_rounds'] == 2
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
    assert first_out['east'] == {'card':'H2','seat':'east','sequence':19}
    assert club_events['west'][2]['sequence'] == 17 and len(windows) == 1
    assert records[6]['revision'] == 13 and records[8]['revision'] == 16
    assert records[9]['revision'] == 18 and records[9]['selectedCard'] == 'CQ'
    assert decisions[8]['effective_plan'] == decisions[9]['effective_plan']
    proof = {
        'scope':'Public facts, bindings and actual window eligibility only. Semantic quality/core conclusions remain in the independent report; no hidden fixture is read.',
        'attempt':'short-3-r3', 'source_commit':candidate['source_commit'],
        'candidate_metadata_sha256':sha(candidate_bytes), 'trace_sha256':sha(trace_bytes), 'grade_input_sha256':sha(input_bytes),
        'raw_grader_sha256':sha((directory/'grade/grader-output.json').read_bytes()),
        'evaluation_sha256':sha((directory/'grade/evaluation.json').read_bytes()),
        'initial_partnership_clubs':8, 'initial_defender_clubs':outside,
        'all12_model_records':records, 'actual_events':events,
        'defender_club_events':club_events, 'first_club_showouts':first_out,
        'second_complete_club_round_end_sequence':11,
        'public_possible_lengths_after_two_rounds':[{'west':3,'east':2},{'west':2,'east':3}],
        'remaining_club_after_two_rounds':'CJ',
        'public_original_club_lengths_at_revision18':{'west':3,'east':2},
        'public_new_owner_at_revision18':'CJ played by west; East has no club remaining before any actual show-out',
        'eligible_model_record':records[9],
        'previous_model_record':records[8],
        'previous_raw_output':decisions[8]['raw_output'],
        'eligible_raw_output':decisions[9]['raw_output'],
        'previous_and_eligible_effective_plan_identical':True,
        'unchanged_effective_plan':decisions[9]['effective_plan'],
        'eligible_third_club_before_other_first_showout_event_windows':windows,
        'eligible_third_club_model_windows':[records[9]],
        'prior_equivalent_localization_before_west_third_club':False,
        'prior_information_limit':'Two external club allocations remain compatible before CJ: West-three/East-two and West-two/East-three. No supplied defensive agreement or earlier show-out fixes its owner.',
        'facet_event_eligibility':'exercised: actual model decision00010/revision18 after West third club17 and before East first show-out19',
        'facet_semantic_result':'Not established in the independent report; exact prior/current reasons and unchanged effective plan are preserved for separate adjudication. No internal-inference conclusion follows.',
        'limits':'No matrix-level cohort result is inferred; the other fixed repetitions are unreviewed here. No phrase/length/forced-replace gate is applied.',
    }
    if args.write:
        args.proof.write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n')
        print(f'Wrote {args.proof}')
    else: assert json.loads(args.proof.read_text()) == proof
    print('12 finals/prefixes/plan effects bound; eligible MODEL revision18 after West third club17 before East show-out19; prior/current statements preserved without inferring internal state.')


if __name__ == '__main__': main()
