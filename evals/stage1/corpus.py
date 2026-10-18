"""Finite evaluator-owned material. Complete deals never enter grader packages."""
import hashlib
import json
from pathlib import Path
import re

SEATS = ['north', 'east', 'south', 'west']
RANKS = '23456789TJQKA'
ROOT = Path(__file__).parent


def load(path):
    return json.loads(Path(path).read_text())


def replay(board, events):
    """Independent material check, not an alternate playing engine or bot."""
    hands = {h['seat']: set(h['cards']) for h in board['hands']}
    if len(board['hands']) != 4 or set(hands) != set(SEATS):
        raise ValueError('Exactly four distinct seats required')
    cards = [c for h in board['hands'] for c in h['cards']]
    if any(len(h['cards']) != 13 for h in board['hands']) or len(set(cards)) != 52:
        raise ValueError('Deal must contain 52 unique cards and 13 per hand')
    if any(not re.fullmatch('[SHDC][2-9TJQKA]', c) for c in cards):
        raise ValueError('Invalid card')
    contract = board['contract']
    declarer = contract['declarer']
    dummy = SEATS[(SEATS.index(declarer) + 2) % 4]
    leader = SEATS[(SEATS.index(declarer) + 1) % 4]
    trump = {'spades': 'S', 'hearts': 'H', 'diamonds': 'D', 'clubs': 'C', 'noTrump': None}[contract['strain']]
    trick = []
    wins = [0, 0]
    for i, event in enumerate(events):
        actor = SEATS[(SEATS.index(leader) + len(trick)) % 4]
        card = event['card']
        if event['sequence'] != i or event['seat'] != actor:
            raise ValueError('Event sequence or acting seat is unreachable')
        if card not in hands[actor]:
            raise ValueError('Played card is absent or already consumed')
        if trick and card[0] != trick[0]['card'][0] and any(c[0] == trick[0]['card'][0] for c in hands[actor]):
            raise ValueError('Play revokes while holding led suit')
        hands[actor].remove(card)
        trick.append(event)
        if len(trick) == 4:
            led = trick[0]['card'][0]
            winner = max(trick, key=lambda e: (2 if trump and e['card'][0] == trump else 1 if e['card'][0] == led else 0, RANKS.index(e['card'][1])))
            leader = winner['seat']
            wins[0 if leader in (declarer, dummy) else 1] += 1
            trick = []
    actor = SEATS[(SEATS.index(leader) + len(trick)) % 4] if len(events) < 52 else None
    return {'actingSeat': actor, 'hands': hands, 'currentTrick': trick, 'declarerTricks': wins[0], 'defenderTricks': wins[1]}


def initial_events(board):
    if 'initialEvents' in board:
        return board['initialEvents']
    leader = SEATS[(SEATS.index(board['contract']['declarer']) + 1) % 4]
    return [{'sequence': 0, 'seat': leader, 'card': board['openingLead']}]


def authorized_start(case, board):
    events = initial_events(board)
    state = replay(board, events)
    declarer = board['contract']['declarer']
    dummy = SEATS[(SEATS.index(declarer) + 2) % 4]
    if state['actingSeat'] not in (declarer, dummy):
        raise ValueError('Case must start at a controlled decision')
    return {'boardID': case['id'], 'revision': len(events), 'controller': declarer,
            'contract': board['contract'], 'scoring': board['scoring'], 'vulnerability': board['vulnerability'],
            'objective': board['objective'], 'events': events, 'actingSeat': state['actingSeat'],
            'currentTrick': state['currentTrick'], 'declarerTricks': state['declarerTricks'], 'defenderTricks': state['defenderTricks'],
            'hands': [{'seat': seat, 'cards': sorted(state['hands'][seat])} for seat in (declarer, dummy)]}


def case_rules(case):
    """Allowlist only decision-visible adjudication; never source/full-deal metadata."""
    return {key: case[key] for key in ('id', 'properties', 'acceptable_alternatives', 'severe_errors', 'coverage_trigger', 'hard_gate')}


def verify_case_decisions(manifest_path, case_id, decisions):
    """Check environment binding before attaching case facts to actual evidence."""
    manifest_path = Path(manifest_path)
    manifest = load(manifest_path)
    case = next(c for c in manifest['cases'] if c['id'] == case_id)
    board = load(manifest_path.parent / case['board'])
    prefix = initial_events(board)
    for _, record in decisions:
        snapshot = record['snapshot']
        events = snapshot['events']
        if events[:len(prefix)] != prefix or snapshot['contract'] != board['contract']:
            raise ValueError('case/trace mismatch: initial events or contract differ')
        state = replay(board, events)
        for hand in snapshot['hands']:
            if set(hand['cards']) != state['hands'][hand['seat']]:
                raise ValueError('case/trace mismatch: visible remaining holding differs')
        if any(snapshot[key] != state[key] for key in ('actingSeat', 'currentTrick', 'declarerTricks', 'defenderTricks')):
            raise ValueError('case/trace mismatch: reachable public state differs')


def validate(manifest_path):
    manifest_path = Path(manifest_path)
    assets = {'@rubric': ROOT / 'rubric.txt', 'manifest.json': manifest_path,
              'synthetic-demonstration.json': manifest_path.parent / 'synthetic-demonstration.json',
              'communication-reachability.json': manifest_path.parent / 'communication-reachability.json'}
    assets.update({str(p.relative_to(manifest_path.parent)): p for p in (manifest_path.parent / 'boards').glob('*.json')})
    hashes = {name: hashlib.sha256(path.read_bytes()).hexdigest() for name, path in assets.items()}
    frozen = load(manifest_path.parent / 'frozen-sha256.json')
    if hashes != frozen:
        raise ValueError('Frozen asset changed; review, revise version and log correction before re-freezing')
    manifest = load(manifest_path)
    cases = manifest['cases']
    if len({c['id'] for c in cases}) != len(cases):
        raise ValueError('Duplicate case identifiers')
    short = [c for c in cases if c['kind'] == 'short']
    full = [c for c in cases if c['kind'] == 'full']
    if len(short) != 6 or len(full) != 2 or {c['role'] for c in full} != {'development', 'regression'}:
        raise ValueError('Finite corpus requires six short, one development and one used regression board')
    if manifest['corpus_version'] != 'stage1-finite-v2' or manifest['rubric_version'] != 'stage1-basic-v4':
        raise ValueError('Unreviewed rubric version')
    starts, fingerprints = {}, {}
    for case in cases:
        board = load(manifest_path.parent / case['board'])
        if board['scoring'] != 'IMP' or board['vulnerability'] != 'neither' or board['contract']['strain'] != 'noTrump':
            raise ValueError('Case conditions differ from reviewed adaptation')
        starts[case['id']] = authorized_start(case, board)
        case_rules(case)
        fingerprint = sorted((h['seat'], tuple(sorted(h['cards']))) for h in board['hands'])
        fingerprints[case['id']] = fingerprint
        if case['required_runs'] != (3 if case['kind'] == 'short' else 2):
            raise ValueError('Finite acceptance run count changed')
    reserve = next(c for c in full if c['role'] == 'regression')
    distinct = all(fingerprints[c['id']] != fingerprints[reserve['id']] for c in cases if c != reserve)
    if not distinct:
        raise ValueError('Used regression board must differ from every tuning/development board')
    demonstration = load(manifest_path.parent / 'synthetic-demonstration.json')
    demo = replay(load(manifest_path.parent / demonstration['board']), demonstration['events'])
    if len(demonstration['events']) != 52 or demo['declarerTricks'] != 10 or demo['defenderTricks'] != 3 or any(demo['hands'].values()):
        raise ValueError('Synthetic authored demonstration did not legally finish 10:3')
    witness = load(manifest_path.parent / 'communication-reachability.json')
    communication = replay(load(manifest_path.parent / witness['board']), witness['events'])
    east_spades = sum(c.startswith('S') for c in communication['hands']['east'])
    if (witness['model_performance'] is not False or len(witness['events']) != 20
            or communication['declarerTricks'] != 2 or communication['defenderTricks'] != 3
            or east_spades != 0 or 'HA' not in communication['hands']['north']):
        raise ValueError('Authored communication witness does not establish its stated reachable facts')
    return {'status': 'pass', 'corpus_version': manifest['corpus_version'], 'rubric_version': manifest['rubric_version'],
            'short_cases': len(short), 'full_boards': len(full), 'regression_distinct': distinct,
            'playing_model_called': False, 'grading_model_called': False,
            'demonstration': {'status': 'legal-authored-example', 'tricks': [10, 3], 'model_performance': False},
            'communication_reachability': {'status': 'legal-authored-example', 'tricks': [2, 3],
                                          'east_remaining_spades': east_spades, 'north_heart_ace_entry': True,
                                          'model_performance': False},
            'sha256': hashes,
            'authorized_starts': starts,
            'case_rules': [case_rules(c) for c in cases]}
