from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]


class CorpusPublicEntryTests(unittest.TestCase):
    def validate(self, manifest=None):
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / 'validation'
            run = subprocess.run([sys.executable, str(ROOT / 'evaluate.py'), 'validate-corpus', '--manifest', str(manifest or ROOT / 'corpus/manifest.json'), '--output', str(output)], text=True, capture_output=True)
            result = json.loads((output / 'corpus-validation.json').read_text()) if (output / 'corpus-validation.json').exists() else None
            return run, result

    def test_revised_corpus_preserves_finite_cases_and_labels_used_reserve_as_regression(self):
        run, report = self.validate()
        self.assertEqual(run.returncode, 0, run.stderr)
        self.assertEqual(report['status'], 'pass')
        self.assertEqual(report['short_cases'], 6)
        self.assertEqual(report['full_boards'], 2)
        self.assertTrue(report['regression_distinct'])
        self.assertEqual(report['rubric_version'], 'stage1-basic-v3')
        self.assertEqual(report['corpus_version'], 'stage1-finite-v2')
        manifest = json.loads((ROOT / 'corpus/manifest.json').read_text())
        case = next(c for c in manifest['cases'] if c['id'] == 'full-reserved')
        self.assertEqual(case['role'], 'regression')
        self.assertEqual(case['former_role'], 'reserved')
        self.assertEqual(len(manifest['cases']), 8)
        self.assertFalse(report['playing_model_called'])

    def test_authored_hold_up_witness_is_legally_reachable_and_never_model_performance(self):
        run, report = self.validate()
        self.assertEqual(run.returncode, 0, run.stderr)
        witness = report['communication_reachability']
        self.assertEqual(witness['tricks'], [2, 3])
        self.assertEqual(witness['east_remaining_spades'], 0)
        self.assertTrue(witness['north_heart_ace_entry'])
        self.assertFalse(witness['model_performance'])

    def test_case_rules_reach_existing_grader_entry_without_environment_or_expected_labels(self):
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / 'grade'
            run = subprocess.run([sys.executable, str(ROOT / 'evaluate.py'), 'grade', '--answers', str(ROOT / 'calibration/answers.json'), '--case', 'short-1', '--codex', '/no/such/codex', '--output', str(output)], text=True, capture_output=True)
            self.assertEqual(run.returncode, 0, run.stderr)
            package = json.loads((output / 'input.json').read_text())
            self.assertEqual(package['case']['id'], 'short-1')
            self.assertIn('there are eight', package['case']['properties'][0])
            self.assertNotIn('expected', json.dumps(package))
            self.assertNotIn('boards/synthetic.json', json.dumps(package))
            self.assertEqual({h['seat'] for h in package['decisions'][0]['decision_time_facts']['hands']}, {'south', 'north'})

    def test_changed_frozen_case_is_material_error_and_cannot_silently_redefine_acceptance(self):
        with tempfile.TemporaryDirectory() as temporary:
            copied = Path(temporary) / 'corpus'
            shutil.copytree(ROOT / 'corpus', copied)
            manifest = copied / 'manifest.json'
            value = json.loads(manifest.read_text())
            value['cases'][0]['severe_errors'] = []
            manifest.write_text(json.dumps(value))
            run, report = self.validate(manifest)
            self.assertEqual(run.returncode, 0, run.stderr)
            self.assertEqual(report['status'], 'fail')
            self.assertEqual(report['attribution'], 'case_material_error')
            self.assertIn('Frozen asset changed', report['error'])

    def test_wrong_case_cannot_supply_facts_to_an_unrelated_actual_decision(self):
        with tempfile.TemporaryDirectory() as temporary:
            run = subprocess.run([sys.executable, str(ROOT / 'evaluate.py'), 'grade', '--answers', str(ROOT / 'calibration/answers.json'), '--case', 'short-5', '--codex', '/no/such/codex', '--output', str(Path(temporary) / 'wrong-case')], text=True, capture_output=True)
            self.assertEqual(run.returncode, 2)
            self.assertIn('case/trace mismatch', run.stderr)


if __name__ == '__main__':
    unittest.main()
