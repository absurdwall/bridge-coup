#!/usr/bin/env python3
"""Verify two exact failure witnesses from the real saved Expert/runtime path.
This is a narrow diagnostic witness, not a general bridge-prose validator.
It never changes or repairs a player answer.
"""
import json
from pathlib import Path
import sys

REPO = Path('/Users/tingranwang/.codex/worktrees/issue46-integration/bridge-coup')
sys.path.insert(0, str(REPO / 'evals/stage1'))
from evaluate import read_decision, deterministic_checks, recorded_turn

run = REPO / 'evals/stage1/evidence/issue46-completion/development-v4/short-6-r1'
records = {}
for number in [6, 11, 12]:
    identifier = f'decision-{number:04}'
    record = read_decision(run / 'play' / identifier)
    checks = deterministic_checks(record)
    assert all(c['status'] == 'pass' for c in checks.values()), checks
    request, completion = recorded_turn(record)
    assert request['input'][0]['text'] == record['input']
    assert any(i.get('text') == record['rawOutput'] for i in completion['items'])
    records[number] = (record, json.loads(record['input']), json.loads(record['rawOutput']))

record, position, answer = records[6]
hearts = {seat: position['hands'][seat]['H'] for seat in ['N', 'S']}
assert hearts == {'N': 'A43', 'S': 'KQJ'}
quote = 'Cash the heart honors for four tricks'
assert quote in answer['plan']['text']
heart_witness = {'id': 'heart-count', 'authorized_hearts': hearts,
                 'upper_bound_from_hand_lengths': max(map(len, hearts.values())),
                 'claimed_tricks': 4, 'exact_output_excerpt': quote,
                 'is_defect': 4 > max(map(len, hearts.values()))}

record, position, answer = records[12]
assert position['contract']['strain'] == 'NT'
assert position['current']['toAct'] == 'S'
assert position['hands']['S']['C'] == 'AJ'
assert record['snapshot']['legalCards'] == ['CA', 'CJ']
assert [p['card'] for p in position['currentTrick']] == ['CQ', 'H3', 'C9']
assert answer['selectedCard'] == 'CJ'
quote = 'West’s winning CQ'
assert quote in answer['publicReason']
club_witness = {'id': 'club-winner', 'actual_plays': position['currentTrick'],
                'south_clubs': 'AJ', 'legal_cards': ['CA', 'CJ'],
                'selected_card': answer['selectedCard'],
                'current_highest_play': 'CQ', 'higher_legal_card': 'CA',
                'exact_output_excerpt': quote, 'is_defect': True}
result = {'source': str(run), 'actual_same_turn_input_output_and_legality': 'verified',
          'scope': 'Saved-output diagnosis only; a future live response needs new evidence.',
          'witnesses': [heart_witness, club_witness]}
Path(__file__).with_name('saved-failure-witnesses.json').write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n')
for witness in result['witnesses']:
    print('RED', witness['id'], json.dumps(witness, ensure_ascii=False))
sys.exit(1 if any(w['is_defect'] for w in result['witnesses']) else 0)
