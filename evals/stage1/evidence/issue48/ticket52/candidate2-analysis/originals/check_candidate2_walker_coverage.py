#!/usr/bin/env python3
"""Evaluator-only environment coverage; never feed hidden holdings to a role.

Run after the three public quality reports are final. Replays only immutable
recorded events with the reducer and complete fixture from the frozen C2 source
archive. Default mode compares the adjacent saved proof; --write creates it.
"""
import argparse
import hashlib
import json
from pathlib import Path
import tarfile

SOURCE_COMMIT = '0a307cbde5498ed24b73da0d781cb9113ce92180'
FIXTURE_MEMBER = 'evals/stage1/corpus/boards/walker-holdup-adapted.json'
FIXTURE_SHA256 = '1ee7dd3747426124dee7cd29f914aa8677818ad6558e2e5a327373cdacbea208'
REDUCER_MEMBER = 'evals/stage1/corpus.py'
REDUCER_SHA256 = '5028d0dbc8a9f633932f8d8989fe0169e9166bc51738c22fa9e8ac64c27c626a'
ARCHIVE_REL = 'evals/stage1/evidence/issue48/ticket52/candidate2-analysis/runtime/candidate2-source.tar.gz'
ATTEMPTS_REL = 'evals/stage1/evidence/issue48/ticket52/candidate2'
ATTEMPTS = ('short-6-r1', 'short-6-r2', 'short-6-r3')
TRACE_HASHES = {
    'short-6-r1': '9fbff91d6f40e6dd4a33406a43980c57d2226b6376391213a714f4e3a35039a7',
    'short-6-r2': '9321205dfaad9e7bb2dc560db559420b8270c96b7bf653531ee6290f1557f334',
    'short-6-r3': '2649994cb2652dda827246e7b0809427cecb135b3d431c3c434df2c26af79e1c',
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, default=Path('/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup'))
    parser.add_argument('--reports', type=Path, default=Path(__file__).resolve().parent)
    parser.add_argument('--proof', type=Path, default=Path(__file__).with_name('candidate2-short6-coverage-environment-proof.json'))
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()

    # All public reports must already exist. Their exact bytes are bound below;
    # this script never edits them or emits a new player quality judgment.
    reports = {}
    for attempt in ATTEMPTS:
        name = f'candidate2-{attempt}-review.md'
        data = (args.reports / name).read_bytes()
        assert b'12 pass, 0 fail, 0 uncertain' in data
        reports[attempt] = {'file': name, 'sha256': sha(data)}

    archive = args.repo / ARCHIVE_REL
    archive_bytes = archive.read_bytes()
    with tarfile.open(archive, 'r:gz') as frozen:
        fixture_bytes = frozen.extractfile(FIXTURE_MEMBER).read()
        reducer_bytes = frozen.extractfile(REDUCER_MEMBER).read()
    assert sha(fixture_bytes) == FIXTURE_SHA256, 'Frozen Walker fixture hash mismatch'
    assert sha(reducer_bytes) == REDUCER_SHA256, 'Frozen replay reducer hash mismatch'
    board = json.loads(fixture_bytes)
    # corpus.py uses only standard-library imports and defines an independent
    # legality/reachability replay; no source or package from current C3 is used.
    namespace = {'__file__': str(archive) + '/' + REDUCER_MEMBER, '__name__': 'frozen_candidate2_corpus'}
    exec(compile(reducer_bytes, REDUCER_MEMBER, 'exec'), namespace)
    replay = namespace['replay']

    rows = []
    for attempt in ATTEMPTS:
        root = args.repo / ATTEMPTS_REL / attempt
        trace_bytes = (root / 'play/trace.json').read_bytes()
        assert sha(trace_bytes) == TRACE_HASHES[attempt], f'{attempt}: trace changed'
        trace = json.loads(trace_bytes)
        assert json.loads((root / 'playing-outcome.json').read_text())['exit_code'] == 0
        assert trace['modelActions'] == 12
        events = list(trace['initialEvents'])
        assert events == [{'sequence': 0, 'seat': 'west', 'card': 'SK'}]
        model_cards = []
        for step in trace['steps']:
            if 'decision' in step:
                decision = step['decision']
                snapshot = decision['snapshot']
                assert snapshot['events'] == events
                state = replay(board, events)
                for key in ('actingSeat', 'currentTrick', 'declarerTricks', 'defenderTricks'):
                    assert snapshot[key] == state[key], (attempt, key)
                for hand in snapshot['hands']:
                    assert set(hand['cards']) == state['hands'][hand['seat']]
                model_cards.append(step['execution']['event']['card'])
            event = step['execution']['event'] if 'execution' in step else step['event']
            events.append(event)
            replay(board, events)  # Every actual prefix must be legal.
        assert events[3] == {'sequence': 3, 'seat': 'south', 'card': 'S3'}
        assert events[7] == {'sequence': 7, 'seat': 'south', 'card': 'S9'}
        assert events[11] == {'sequence': 11, 'seat': 'south', 'card': 'SA'}
        da = next(event for event in events if event['card'] == 'DA')
        assert da['seat'] == 'east'
        da_index = da['sequence']
        after_da = replay(board, events[:da_index + 1])
        assert after_da['actingSeat'] == 'east' and not after_da['currentTrick']
        east_spades = sorted(card for card in after_da['hands']['east'] if card.startswith('S'))
        west_spades = sorted(card for card in after_da['hands']['west'] if card.startswith('S'))
        assert east_spades == []
        assert west_spades == ['S2', 'ST']
        actual_switch = events[da_index + 1]
        expected_switch = 'CK' if attempt == 'short-6-r3' else 'HT'
        assert actual_switch == {'sequence': da_index + 1, 'seat': 'east', 'card': expected_switch}
        assert actual_switch['card'] in after_da['hands']['east']
        # An unrestricted lead is legal from any card actually held. Enumerate
        # these leads through the frozen reducer; none is a spade.
        legal_leads = sorted(after_da['hands']['east'])
        for card in legal_leads:
            replay(board, events[:da_index + 1] + [{'sequence': da_index + 1, 'seat': 'east', 'card': card}])
        assert not any(card.startswith('S') for card in legal_leads)
        end = replay(board, events)
        assert (end['declarerTricks'], end['defenderTricks']) == (4, 3)
        assert not trace['complete']
        rows.append({
            'attempt': attempt,
            'trace': f'{ATTEMPTS_REL}/{attempt}/play/trace.json',
            'trace_sha256': sha(trace_bytes),
            'grade_input_sha256': sha((root / 'grade/input.json').read_bytes()),
            'public_quality_report': reports[attempt],
            'events_count': len(events),
            'recorded_events': events,
            'all_actual_event_prefixes_legally_replayed': True,
            'all_12_public_decision_snapshots_match_fixture_replay': True,
            'two_hold_up_south_cards': ['S3', 'S9'],
            'third_spade_won_by': 'SA',
            'diamond_ace_sequence': da_index,
            'after_diamond_ace_next_actor': after_da['actingSeat'],
            'after_diamond_ace_tricks': [after_da['declarerTricks'], after_da['defenderTricks']],
            'actual_switch': actual_switch,
            'environment_only_remaining_hands_before_switch': {seat: sorted(cards) for seat, cards in after_da['hands'].items()},
            'environment_only_east_remaining_spades': east_spades,
            'environment_only_west_remaining_spades': west_spades,
            'environment_only_east_legal_leads_before_switch': legal_leads,
            'environment_only_east_could_legally_return_a_spade': False,
            'environment_only_actual_spade_communications_severed': True,
            'final_actual_tricks': [end['declarerTricks'], end['defenderTricks']],
            'final_actual_hands': {seat: sorted(cards) for seat, cards in end['hands'].items()},
            'board_complete': trace['complete'],
            'limits': 'Hidden-environment reachability only. East void was not established by a public show-out. This does not change player knowledge, quality labels, or prove unplayed heart/diamond/club continuation.',
        })

    proof = {
        'scope': 'Evaluator-only exact frozen environment coverage after all three public quality reports were finalized. Never feed complete holdings into a role.',
        'frozen_source_commit': SOURCE_COMMIT,
        'frozen_archive': ARCHIVE_REL,
        'frozen_archive_sha256': sha(archive_bytes),
        'fixture_archive_member': FIXTURE_MEMBER,
        'fixture_sha256': FIXTURE_SHA256,
        'replay_reducer_archive_member': REDUCER_MEMBER,
        'replay_reducer_sha256': REDUCER_SHA256,
        'attempts': rows,
        'conclusion': 'All three actual attempts legally reached East winning DA after South ducked twice and won the third spade. East then held no spades, so a spade return was impossible in this exact environment; r1/r2 switched HT and r3 switched CK. This actual environment fact is distinct from public decision-time knowledge.',
    }
    if args.write:
        args.proof.write_text(json.dumps(proof, ensure_ascii=False, indent=2) + '\n')
        print(f'Wrote {args.proof}')
    else:
        expected = json.loads(args.proof.read_text())
        assert proof == expected, 'Saved proof differs from reproducible frozen replay'
    for row in rows:
        print(f"{row['attempt']}: legal DA win at sequence {row['diamond_ace_sequence']}; East spades=[]; spade return impossible; actual switch={row['actual_switch']['card']}; public reports unchanged")


if __name__ == '__main__':
    main()
