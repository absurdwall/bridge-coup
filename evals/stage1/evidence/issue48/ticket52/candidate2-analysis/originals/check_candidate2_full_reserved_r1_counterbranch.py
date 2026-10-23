#!/usr/bin/env python3
"""Public-compatible counterbranch only; no actual hidden fixture is read.

Shows an original East-four/West-two club layout compatible with decision 0009,
and the feasible thirteenth trick after East's already-public C2 discard.
It does not decide whether the retained fallback actually forbids that trick.
"""
import argparse
import hashlib
import json
from pathlib import Path

SEATS = ['north', 'east', 'south', 'west']
RANKS = '23456789TJQKA'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def replay(hands_at_start, events):
    hands = {seat: set(cards) for seat, cards in hands_at_start.items()}
    assert set(hands) == set(SEATS) and all(len(cards) == 13 for cards in hands.values())
    assert len(set().union(*hands.values())) == 52
    leader = 'west'
    trick = []
    tricks = []
    for sequence, event in enumerate(events):
        seat, card = event['seat'], event['card']
        assert event['sequence'] == sequence
        assert seat == SEATS[(SEATS.index(leader) + len(trick)) % 4]
        assert card in hands[seat]
        if trick and card[0] != trick[0]['card'][0]:
            assert not any(held[0] == trick[0]['card'][0] for held in hands[seat])
        hands[seat].remove(card)
        trick.append(event)
        if len(trick) == 4:
            led = trick[0]['card'][0]
            winner = max(trick, key=lambda play: (play['card'][0] == led, RANKS.index(play['card'][1])))['seat']
            tricks.append({'plays': list(trick), 'winner': winner})
            leader = winner
            trick = []
    return {'hands': {seat: sorted(cards) for seat, cards in hands.items()},
            'currentTrick': trick, 'completedTricks': tricks,
            'declarerTricks': sum(t['winner'] in ('north', 'south') for t in tricks),
            'defenderTricks': sum(t['winner'] in ('east', 'west') for t in tricks)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, default=Path('/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup'))
    parser.add_argument('--proof', type=Path, default=Path(__file__).with_name('candidate2-full-reserved-r1-counterbranch-proof.json'))
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    root = args.repo / 'evals/stage1/evidence/issue48/ticket52/candidate2/full-reserved-r1'
    input_bytes = (root / 'grade/input.json').read_bytes()
    assert sha(input_bytes) == '0ededac3a6c3dd891e79c353265770fb271c4365a46b13cfd33c96f51a11f522'
    package = json.loads(input_bytes)
    initial = json.loads(package['decisions'][0]['authorized_input'])
    decision = next(d for d in package['decisions'] if d['id'] == 'decision-0009')
    snapshot = json.loads(decision['authorized_input'])
    assert initial['contract']['strain'] == 'NT'
    hands = {long: sorted(suit + rank for suit, ranks in initial['hands'][short].items() for rank in ranks)
             for short, long in [('N', 'north'), ('S', 'south')]}
    # These defender holdings are CONSTRUCTED, not read from any environment.
    # All known H/D cards through decision 0009 are respected; the unseen
    # spade/heart/club cards are assigned to form a compatible original 4–2.
    hands['east'] = ['SQ', 'SJ', 'S8', 'HT', 'H9', 'H2', 'DK', 'D6', 'D4', 'CJ', 'CT', 'C9', 'C2']
    hands['west'] = ['ST', 'S9', 'S5', 'S3', 'HJ', 'H7', 'H6', 'H3', 'DT', 'D8', 'D5', 'C7', 'C4']
    prefix = decision['decision_time_facts']['events']
    assert len(prefix) == 18 and prefix[-1]['card'] == 'C2'
    at_decision = replay(hands, prefix)
    for short, long in [('N', 'north'), ('S', 'south')]:
        assert set(at_decision['hands'][long]) == {suit + rank for suit, ranks in snapshot['hands'][short].items() for rank in ranks}
    seat_code = {'N': 'north', 'E': 'east', 'S': 'south', 'W': 'west'}
    assert [{ 'card': p['card'], 'seat': seat_code[p['seat']] } for p in snapshot['currentTrick']] == [
        {'card': p['card'], 'seat': p['seat']} for p in at_decision['currentTrick']]
    assert (at_decision['declarerTricks'], at_decision['defenderTricks']) == (4, 0)
    assert json.loads(decision['raw_output'])['selectedCard'] == 'S4'
    continuation = [
        ('south','S4'), ('west','H3'),
        ('north','C5'), ('east','CT'), ('south','CK'), ('west','C4'),
        ('south','CQ'), ('west','C7'), ('north','C6'), ('east','CJ'),
        ('south','C3'), ('west','S3'), ('north','CA'), ('east','C9'),
        ('north','H4'), ('east','H9'), ('south','HK'), ('west','H6'),
        ('south','C8'), ('west','S5'), ('north','S2'), ('east','S8'),
        ('south','HA'), ('west','H7'), ('north','H8'), ('east','HT'),
        ('south','SA'), ('west','S9'), ('north','S7'), ('east','SJ'),
        ('south','S6'), ('west','ST'), ('north','SK'), ('east','SQ'),
    ]
    events = prefix + [{'sequence': len(prefix) + i, 'seat': seat, 'card': card} for i, (seat, card) in enumerate(continuation)]
    after_test = replay(hands, events[:32])
    assert not any(card.startswith('C') for seat in ('east', 'west') for card in after_test['hands'][seat])
    assert 'C8' in after_test['hands']['south'] and 'HK' in after_test['hands']['south']
    assert 'H4' in after_test['hands']['north']
    end = replay(hands, events)
    assert len(events) == 52 and len(end['completedTricks']) == 13
    assert (end['declarerTricks'], end['defenderTricks']) == (13, 0)
    assert all(not cards for cards in end['hands'].values())
    raw_grade_bytes = (root / 'grade/grader-output.json').read_bytes()
    raw = next(result for result in json.loads(raw_grade_bytes)['results'] if result['id'] == 'decision-0009')
    assert raw['status'] == 'fail'
    proof = {
        'scope': 'Constructed public-compatible counterfactual, NOT the actual hidden environment. Uses only initial authorized NS cards and the exact authorized public prefix at decision 0009; future branch cards are authored possibilities, not decision-time facts.',
        'attempt': 'full-reserved-r1', 'decision': 'decision-0009',
        'grade_input_sha256': sha(input_bytes), 'raw_grader_output_sha256': sha(raw_grade_bytes),
        'raw_grader_decision_0009_verbatim_values': raw,
        'constructed_initial_hands': {seat: sorted(cards) for seat, cards in hands.items()},
        'original_defender_club_lengths': {'east': 4, 'west': 2},
        'exact_authorized_public_prefix': prefix,
        'constructed_continuation_after_prefix': events[len(prefix):],
        'all_52_counterfactual_cards_legally_played': True,
        'after_three_club_honor_rounds': after_test,
        'fourth_club_established_and_heart_return_available': True,
        'counterfactual_final_tricks': [end['declarerTricks'], end['defenderTricks']],
        'conclusion': 'East original four / West two is compatible with the public position and C2 discard. CK, CQ, CA then exhaust all opposing clubs; a retained heart reaches C8, allowing thirteen. This establishes the old condition is underinclusive, but does not itself prove that its conservative fallback forbids taking a subsequently observed established winner, nor prove a material defect in the current S4 discard/entries. The actual later replacement is separate recorded evidence.',
    }
    if args.write:
        args.proof.write_text(json.dumps(proof, ensure_ascii=False, indent=2) + '\n')
        print(f'Wrote {args.proof}')
    else:
        assert json.loads(args.proof.read_text()) == proof
    print('Public-compatible original club 4–2 counterbranch verified: retained entry reaches established C8; 52 legal cards / 13:0. No actual hidden fixture used.')


if __name__ == '__main__':
    main()
