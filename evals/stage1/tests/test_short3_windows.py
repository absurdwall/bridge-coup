"""Public inference opportunity is distinct from a forced event and semantic use."""
import copy
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
import acceptance
import corpus

FIXTURES = ROOT / 'regressions/candidate2'
BOARD = corpus.load(ROOT / 'corpus/boards/synthetic.json')


def decision(events, revision):
    prefix = events[:revision]
    state = corpus.replay(BOARD, prefix)
    return {'snapshot': {'revision': revision, 'controller': 'south', 'actingSeat': state['actingSeat'],
        'events': prefix, 'currentTrick': state['currentTrick'],
        'hands': [{'seat': seat, 'cards': sorted(state['hands'][seat])} for seat in ['north', 'south']]}}


class Short3WindowsTests(unittest.TestCase):
    def test_prior_first_showout_never_reopens_at_the_other_defenders_next_play(self):
        saved = corpus.load(FIXTURES / 'public-window-prefixes.json')['cases'][0]
        decisions = [decision(saved['events'], revision) for revision in saved['model_revisions']]
        result = acceptance.coverage('short-3', saved['events'], decisions, False)
        self.assertTrue(result['facets']['two_round_break_decision_revisions'])
        self.assertEqual(result['facets']['third_club_before_other_defender_revisions'], [])

    def test_forced_windows_are_recorded_separately_from_model_windows(self):
        for saved, window in zip(corpus.load(FIXTURES / 'public-window-prefixes.json')['cases'][1:], [14, 18]):
            decisions = [decision(saved['events'], revision) for revision in saved['model_revisions']]
            result = acceptance.coverage('short-3', saved['events'], decisions, False)
            self.assertIn(window, result['facets']['third_club_event_only_revisions'])
            self.assertEqual(result['facets']['third_club_before_other_defender_revisions'], [])
            decisions.append(decision(saved['events'], window))
            reviewed = acceptance.coverage('short-3', saved['events'], decisions, False)
            self.assertEqual(reviewed['facets']['third_club_before_other_defender_revisions'], [window])

    def test_a_third_club_discarded_on_hearts_before_any_club_showout_is_eligible(self):
        witness = corpus.load(FIXTURES / 'discarded-third-witness.json')
        events = witness['events']
        result = acceptance.coverage('short-3', events, [decision(events, 1), decision(events, 27)], False)
        self.assertEqual(result['facets']['third_club_before_other_defender_revisions'], [27])
        self.assertIsNone(result['facets']['third_club_event_windows'][0]['other_first_club_showout'])
        self.assertEqual(result['status'], 'pending')

    def test_other_defenders_side_suit_play_does_not_close_a_club_window(self):
        events = corpus.load(FIXTURES / 'discarded-third-witness.json')['events']
        for seat, card in [('north', 'S2'), ('east', 'D9')]:
            events.append({'sequence': len(events), 'seat': seat, 'card': card})
        corpus.replay(BOARD, events)  # Authored legal extension; no claim about the fixed opponent policy.
        result = acceptance.coverage('short-3', events, [decision(events, 1), decision(events, 29)], False)
        self.assertEqual(result['facets']['third_club_before_other_defender_revisions'], [29])
        self.assertIsNone(result['facets']['third_club_event_windows'][0]['other_first_club_showout'])

    def test_first_showout_boundary_prefix_integrity_and_count_basis(self):
        saved = corpus.load(FIXTURES / 'public-window-prefixes.json')['cases'][1]
        events = saved['events']
        initial = decision(events, 1)
        at_window = decision(events, 14)
        result = acceptance.coverage('short-3', events, [initial, at_window, decision(events, 16)], False)
        self.assertEqual(result['facets']['third_club_before_other_defender_revisions'], [14])
        self.assertEqual(result['facets']['third_club_event_windows'][0]['other_first_club_showout'], 15)
        prefix = events[:14]
        bounded = acceptance.coverage('short-3', prefix, [initial, at_window], False)
        self.assertEqual(bounded['facets']['third_club_before_other_defender_revisions'], [14])
        self.assertIsNone(bounded['facets']['third_club_event_windows'][0]['other_first_club_showout'])
        at_window = copy.deepcopy(at_window)
        at_window['snapshot']['events'][13]['card'] = 'C8'
        fabricated = acceptance.coverage('short-3', events, [initial, at_window], False)
        self.assertEqual(fabricated['facets']['third_club_before_other_defender_revisions'], [])
        early = acceptance.coverage('short-3', events[:10], [initial, decision(events, 8)], False)
        self.assertEqual(early['facets']['two_round_break_decision_revisions'], [])
        self.assertEqual(early['facets']['third_club_before_other_defender_revisions'], [])


if __name__ == '__main__':
    unittest.main()
