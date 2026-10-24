"""Serialized grader contract at the confirmed public Python Eval boundary.

jsonschema is a test-only dependency; the production evaluator uses stdlib.
"""
import importlib.util
import json
from pathlib import Path
import unittest
import jsonschema

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('evaluate', ROOT / 'evaluate.py')
evaluate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(evaluate)


class GraderContractTests(unittest.TestCase):
    def test_authored_retained_plan_matches_the_public_prior_advice(self):
        records = json.loads((ROOT / 'fixtures/saved-boundaries/notation-repair/calibration/answers.json').read_text())
        package = evaluate.grader_package([(record['id'], record) for record in records])
        for record in package['decisions']:
            if json.loads(record['raw_output'])['plan']['update'] == 'keep':
                self.assertIn(record['effective_plan'], record['authorized_input'], record['id'])

    def test_all_45_actual_empty_pass_rows_are_rejected_by_serialized_schema(self):
        schema = evaluate.read_json(ROOT / 'grader-schema.json')
        validator = jsonschema.Draft202012Validator(schema)
        original_schema = evaluate.read_json(ROOT / 'fixtures/saved-boundaries/ticket42/matrix/full-reserved-r1/grade/schema.json')
        historical = jsonschema.Draft202012Validator(original_schema)
        rows = [row for p in (ROOT / 'fixtures/saved-boundaries/ticket42/matrix').glob('*/grade/grader-output.json')
                for row in evaluate.read_json(p)['results'] if row['status'] == 'pass' and not row['findings']]
        self.assertEqual(len(rows), 45)
        for row in rows:
            with self.subTest(id=row['id']):
                document = {'results': [row]}
                self.assertTrue(historical.is_valid(document))
                self.assertFalse(validator.is_valid(document))

    def test_every_verdict_requires_exact_citations_and_preserves_real_uncertainty(self):
        validator = jsonschema.Draft202012Validator(evaluate.read_json(ROOT / 'grader-schema.json'))
        record = evaluate.read_decision(ROOT / 'fixtures/saved-boundaries/ticket37/live3')
        package = evaluate.grader_package([('alternative', record)])
        self.assertEqual(package['rubric_version'], 'stage1-basic-v4')
        self.assertIn('every status', package['rubric'])
        for status in ('pass', 'fail', 'uncertain'):
            finding = {'dimension': 'current action', 'quotes': ['D3'],
                       'fact': 'North holds D3 and must follow diamonds.',
                       'explanation': 'The lawful low diamond is an acceptable spot-card alternative.'}
            row = {'id': 'alternative', 'status': status, 'findings': [finding]}
            grade = {'results': [row]}
            self.assertTrue(validator.is_valid(grade))
            self.assertEqual(evaluate.adjudicate(package, grade)['results'][0]['quality'], status)
            finding['quotes'] = []
            self.assertFalse(validator.is_valid(grade))
            result = evaluate.adjudicate(package, grade)['results'][0]
            self.assertEqual(result['quality'], 'uncertain')
            self.assertEqual(result['attribution'], 'evaluator_issue')

    def test_evaluator_error_does_not_hide_simultaneous_mechanical_product_failure(self):
        record = evaluate.read_decision(ROOT / 'fixtures/saved-boundaries/ticket37/live2')
        package = evaluate.grader_package([('illegal', record)])
        result = evaluate.adjudicate(package, {'results': [
            {'id': 'illegal', 'status': 'pass', 'findings': []}]})['results'][0]
        self.assertEqual(result['mechanical'], 'fail')
        self.assertEqual(result['overall'], 'fail')
        self.assertEqual(result['attribution'], 'product_error')
        self.assertEqual(result['evaluator_attribution'], 'evaluator_issue')


if __name__ == '__main__':
    unittest.main()
