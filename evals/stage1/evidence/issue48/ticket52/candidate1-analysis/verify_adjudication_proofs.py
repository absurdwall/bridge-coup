#!/usr/bin/env python3
"""Offline replay of preserved candidate-1 adjudication proofs; no model calls."""
import argparse
import hashlib
import json
from pathlib import Path
from frozen_sources import FrozenSources

HERE = Path(__file__).resolve().parent

def load(path):
    return json.loads(path.read_text())

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def verify(repo, proof_dir, candidate):
    candidate_freeze = load(candidate / 'candidate.json')
    frozen = FrozenSources(Path(__file__).resolve().parent, candidate_freeze)
    corpus = frozen.corpus()
    reducer_hash = hashlib.sha256(frozen.read('evals/stage1/corpus.py')).hexdigest()
    proof = load(proof_dir / 'candidate1-short1-counterexample.json')
    decision = candidate / 'short-1-r1/play/decision.json'
    assert digest(decision) == proof['source_sha256']
    assert reducer_hash == proof['reducer_sha256']
    board = proof['counterfactual_board']
    known = {h['seat']:set(h['cards']) for h in load(decision)['snapshot']['hands']}
    initial = corpus.replay(board, load(decision)['snapshot']['events'])
    assert all(initial['hands'][seat] == cards for seat,cards in known.items())
    branch_results = []
    for label, branch in [('delivered-rule-counterexample', proof),
                          ('altered-rule-comparison', proof['alternative_covering_nine'])]:
        events = [event for trick in branch['tricks'] for event in trick['plays']]
        club_wins = 0
        for stop in range(4, len(events)+1, 4):
            before = corpus.replay(board, events[:stop-4])
            after = corpus.replay(board, events[:stop])
            won = after['declarerTricks'] > before['declarerTricks']
            club_wins += events[stop-4]['card'].startswith('C') and won
        assert club_wins == branch['club_tricks_taken_by_declarer']
        assert not any(card.startswith('C') for cards in after['hands'].values() for card in cards)
        branch_results.append({'scope':label, 'legal_events':len(events), 'declarer_club_tricks':club_wins})
    assert [row['declarer_club_tricks'] for row in branch_results] == [3,4]

    walker = load(proof_dir / 'candidate1-short6-r1-r2-coverage-environment-proof.json')
    third = load(proof_dir / 'candidate1-short6-r3-coverage-environment-proof.json')
    assert reducer_hash == walker['reducer_sha256'] == third['reducer_sha256']
    rows = walker['attempts'] + [dict(third, diamond_ace_sequence=third['DA_sequence'],
                                    environment_only_remaining_hands=third['remaining_after_DA'])]
    walker_results = []
    for row in rows:
        fixture = 'evals/stage1/corpus/boards/' + Path(row['fixture']).name
        trace_path = candidate / row['attempt'] / 'play/trace.json'
        assert hashlib.sha256(frozen.read(fixture)).hexdigest() == row['fixture_sha256']
        assert digest(trace_path) == row['trace_sha256']
        trace = load(trace_path)
        events = list(trace['initialEvents']) + [s['execution']['event'] for s in trace['steps'] if s.get('execution')]
        sequence = row['diamond_ace_sequence']
        assert events[sequence]['seat'] == 'east' and events[sequence]['card'] == 'DA'
        state = corpus.replay(frozen.load_json(fixture), events[:sequence+1])
        assert state['actingSeat'] == 'east'
        assert not any(c.startswith('S') for c in state['hands']['east'])
        assert {c for c in state['hands']['west'] if c.startswith('S')} == {'ST','S2'}
        assert all(state['hands'][s] == set(cards) for s,cards in row['environment_only_remaining_hands'].items())
        assert events[sequence+1] == row['actual_next_event']
        walker_results.append({'attempt':row['attempt'], 'environment_only_severance_confirmed':True})

    expected = load(proof_dir / 'short3-coverage-witness.json')['results']
    board = frozen.load_json('evals/stage1/corpus/boards/synthetic.json')
    windows = []
    for row in expected:
        trace = load(candidate / row['run'] / 'play/trace.json')
        events = trace['steps'][-1]['actualEvents']
        counts = {'west':0,'east':0}
        observed = []
        for index, event in enumerate(events):
            if event['seat'] not in counts or not event['card'].startswith('C'):
                continue
            counts[event['seat']] += 1
            if counts[event['seat']] != 3:
                continue
            state = corpus.replay(board, events[:index+1])
            trick = state['currentTrick']
            start = index-len(trick)+1
            prior_void = any(e['seat']=='east' and not e['card'].startswith('C') for e in events[start:index])
            if not trick or not trick[0]['card'].startswith('C') or prior_void:
                continue
            actor = state['actingSeat']
            if actor not in ('north','south'):
                continue
            legal = sorted(c for c in state['hands'][actor] if c.startswith('C')) or sorted(state['hands'][actor])
            step = next(s for s in trace['steps'] if s['execution']['event']['sequence']==index+1)
            ordinal = sum(e['seat'] in ('north','south') for e in events[1:index+2])
            observed.append({'revision':index+1,'observed_third_club':event,'actingSeat':actor,
                             'legalCards':legal,'actual_source':step['execution']['source'],
                             'hypothetical_model_ordinal_with_mechanical_false_on_same_event_route':ordinal,
                             'within_unchanged_12_bound':ordinal<=12})
        assert observed == row['third_club_first_controlled_windows']
        windows.append({'attempt':row['run'], 'verified_windows':len(observed)})
    authored = load(proof_dir / 'short3-discarded-third-witness.json')
    state = corpus.replay(board, authored['events'])
    assert state['actingSeat'] == authored['window']['actingSeat'] == 'north'
    assert state['currentTrick'][0]['card'] == 'HQ'
    assert sorted(state['hands']['north']) == authored['window']['legalCards']
    seen = {seat:[e['card'] for e in authored['events'] if e['seat']==seat and e['card'].startswith('C')]
            for seat in ('west','east')}
    assert seen == authored['window']['observed_defender_clubs']
    assert len(seen['west']) == 3 and len(seen['east']) == 2
    assert authored['events'][-1] == authored['window']['third_defender_club']
    assert not any(authored['events'][i-i%4]['card'].startswith('C') and event['seat']=='east'
                   and not event['card'].startswith('C') for i,event in enumerate(authored['events']))
    return {'status':'pass', 'authored_discard_witness':{'legal_events':len(authored['events']),
            'scope':'Authored predicate legality only, not current production-policy reachability or live coverage.'},
            'counterfactual_branches':branch_results,
            'walker_environment_only':walker_results,'short3_diagnostic_windows':windows,
            'limits':['Counterfactual proofs do not become actual plays or live role inputs.',
                      'Environment-only coverage holdings do not establish decision-time public knowledge.',
                      'Proof replay does not itself decide textual materiality or acceptance.']}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', required=True, type=Path)
    parser.add_argument('--proof-dir', type=Path, default=HERE / 'originals')
    parser.add_argument('--candidate', type=Path)
    args = parser.parse_args()
    repo = args.repo.resolve()
    candidate = (args.candidate or repo / 'evals/stage1/evidence/issue48/ticket52/candidate1').resolve()
    print(json.dumps(verify(repo,args.proof_dir.resolve(),candidate),indent=2))
