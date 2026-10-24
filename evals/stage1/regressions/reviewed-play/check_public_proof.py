#!/usr/bin/env python3
"""Verify copied bytes and late-club branches with existing corpus replay; no model."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
SEATS = {'N': 'north', 'E': 'east', 'S': 'south', 'W': 'west'}

def load(path):
    return json.loads(path.read_text())

def verify(repo):
    manifest = load(HERE / 'manifest.json')
    for asset in manifest['assets']:
        data = (HERE / asset['path']).read_bytes()
        assert len(data) == asset['bytes'] and hashlib.sha256(data).hexdigest() == asset['sha256'], asset['path']
    module = repo / 'evals/stage1/corpus.py'
    spec = importlib.util.spec_from_file_location('corpus', module)
    corpus = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(corpus)
    snapshot = load(HERE / 'fixed-review/late-club-input.json')['latestSnapshot']
    plays = [play for trick in snapshot['completedTricks'] for play in trick['plays']] + snapshot['currentTrick']
    prefix = [{'sequence': i, 'seat': SEATS[p['seat']], 'card': p['card']} for i, p in enumerate(plays)]
    assert len(prefix) == 46 and prefix[-2:] == [
        {'sequence': 44, 'seat': 'south', 'card': 'CJ'},
        {'sequence': 45, 'seat': 'west', 'card': 'SJ'}]
    visible = {SEATS[s]: {suit + rank for suit, ranks in hand.items() for rank in ranks}
               for s, hand in snapshot['hands'].items()}
    assert visible == {'north': {'CT', 'C5'}, 'south': {'S9'}}
    deck = {s + r for s in 'SHDC' for r in '23456789TJQKA'}
    missing = deck - {p['card'] for p in prefix} - set.union(*visible.values())
    assert missing == {'CK', 'C9', 'SQ'}
    # West just showed out on CJ, so both missing clubs must be East's. East
    # has already played 11 cards, so these fill its hand; SQ must be West's.
    east_played = sum(p['seat'] == 'east' for p in prefix)
    assert east_played == 11
    east_remaining = {c for c in missing if c.startswith('C')}
    west_remaining = missing - east_remaining
    assert len(east_remaining) == 13 - east_played and west_remaining == {'SQ'}
    remaining = {**visible, 'east': east_remaining, 'west': west_remaining}
    # Reconstruct starting holdings entirely from public actual plays and the
    # deductions above. No original hidden-deal file is read or bundled.
    board = {'contract': {'level': 3, 'strain': 'noTrump', 'declarer': 'south'},
             'hands': [{'seat': seat, 'cards': sorted(remaining[seat] | {p['card'] for p in prefix if p['seat'] == seat})}
                       for seat in corpus.SEATS]}
    before = corpus.replay(board, prefix)
    assert before['actingSeat'] == 'north' and before['currentTrick'] == prefix[-2:]
    assert [before['declarerTricks'], before['defenderTricks']] == [10, 1]
    assert before['hands'] == remaining
    proof = load(HERE / 'public-proof/late-club-branches.json')
    expected = {'preserve_CT_East_wins_CK': (11, 2),
                'preserve_CT_East_ducks_C9': (11, 2),
                'played_CT_East_wins_CK': (10, 3)}
    assert {b['branch'] for b in proof['branches']} == set(expected)
    results = []
    for branch in proof['branches']:
        events = prefix + branch['last_six_plays']
        state = corpus.replay(board, events)
        actual = (state['declarerTricks'], state['defenderTricks'])
        assert len(events) == 52 and not any(state['hands'].values())
        assert actual == expected[branch['branch']] == (branch['NS_tricks'], branch['EW_tricks'])
        results.append({'branch': branch['branch'], 'tricks': actual, 'all_52_cards_legal': True})
    # The two C5 branches enumerate both East legal clubs at fourth hand.
    preserved = [b for b in proof['branches'] if b['branch'].startswith('preserve_CT')]
    assert {b['last_six_plays'][1]['card'] for b in preserved} == east_remaining
    return {'status': 'pass', 'source_assets_checked': len(manifest['assets']),
            'scope': 'Public inference and existing corpus.replay only; not live reviewer behavior or Stage 1 acceptance.',
            'reducer': str(module), 'reducer_sha256': hashlib.sha256(module.read_bytes()).hexdigest(),
            'branches': results}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', required=True, type=Path)
    args = parser.parse_args()
    print(json.dumps(verify(args.repo.resolve()), indent=2))
