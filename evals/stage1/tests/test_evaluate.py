import importlib.util
from pathlib import Path
import unittest
import subprocess
import tempfile
import sys
import json

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('evaluate', ROOT / 'evaluate.py')
evaluate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(evaluate)


class SavedDecisionTests(unittest.TestCase):
    def test_grader_can_cite_actual_retained_plan_on_keep_turn(self):
        record = evaluate.read_decision(ROOT / 'evidence/ticket37/live3')
        answer = json.loads(record['rawOutput'])
        answer['plan'] = {'update': 'keep', 'text': None}
        record['rawOutput'] = json.dumps(answer)
        record['effectivePlan'] = 'Win with the nonexistent diamond eight over the queen.'
        record.pop('rpc')
        package = evaluate.grader_package([('retained', record)])
        grade = {'results': [{'id': 'retained', 'status': 'fail', 'findings': [{
            'dimension': 'retained plan', 'quotes': ['nonexistent diamond eight'],
            'fact': 'D8 cannot beat DQ.', 'explanation': 'Keeping a false winning route remains a quality defect.'}]}]}
        result = evaluate.adjudicate(package, grade)['results'][0]
        self.assertEqual(result['attribution'], 'product_error')
        self.assertEqual(result['quality'], 'fail')
        grade['results'][0]['findings'][0]['quotes'] = ['An unobserved earlier plan']
        self.assertEqual(evaluate.adjudicate(package, grade)['results'][0]['attribution'], 'evaluator_issue')

    def test_v3_legal_enum_contract_remains_independently_checked(self):
        record = evaluate.read_decision(ROOT / 'evidence/ticket37/live3')
        record['wireContractVersion'] = 'stage1-legal-selectedCard-v3'
        answer = json.loads(record['rawOutput'])
        answer['selectedCard'] = answer.pop('currentCard')
        record['rawOutput'] = json.dumps(answer)
        record.pop('rpc')
        self.assertEqual(evaluate.deterministic_checks(record)['structure']['status'], 'pass')
        answer['selectedCard'] = 'DA'
        record['rawOutput'] = json.dumps(answer)
        self.assertEqual(evaluate.deterministic_checks(record)['ownership']['status'], 'fail')

    def test_versioned_selected_card_wire_preserves_saved_execution_checks(self):
        record = evaluate.read_decision(ROOT / 'evidence/ticket37/live3')
        record['wireContractVersion'] = 'stage1-plan-publicReason-selectedCard-v2'
        answer = json.loads(record['rawOutput'])
        answer['selectedCard'] = answer.pop('currentCard')
        record['rawOutput'] = json.dumps(answer)
        record.pop('rpc')  # Original v1 transport must not certify this authored wire migration.
        checks = evaluate.deterministic_checks(record)
        self.assertEqual(checks['structure']['status'], 'pass')
        self.assertEqual(checks['action_binding']['status'], 'pass')
        self.assertEqual(checks['execution']['status'], 'pass')
        answer['currentCard'] = 'D8'
        record['rawOutput'] = json.dumps(answer)
        self.assertEqual(evaluate.deterministic_checks(record)['structure']['status'], 'fail')

    def test_actual_illegal_card_and_legal_execution_have_distinct_mechanical_results(self):
        illegal = evaluate.read_decision(ROOT / 'evidence/ticket37/live2')
        legal = evaluate.read_decision(ROOT / 'evidence/ticket37/live3')
        failed = evaluate.deterministic_checks(illegal)
        passed = evaluate.deterministic_checks(legal)
        self.assertEqual(failed['ownership']['status'], 'fail')
        self.assertEqual(failed['execution']['status'], 'fail')
        self.assertEqual(passed['execution']['status'], 'pass')
        self.assertEqual(passed['follow_suit']['status'], 'pass')
        self.assertEqual(legal['identity']['requestedModel'], 'gpt-6-luna')


    def test_grader_package_uses_actual_input_and_raw_output_without_expected_labels(self):
        record = evaluate.read_decision(ROOT / 'evidence/ticket37/live3')
        record['expected'] = 'fail'
        record['hiddenHands'] = {'east': ['DA']}
        package = evaluate.grader_package([('live3', record)])
        text = evaluate.json_text(package)
        self.assertNotIn('expected', text)
        self.assertNotIn('hiddenHands', text)
        self.assertEqual(package['decisions'][0]['raw_output'], record['rawOutput'])
        self.assertEqual(package['decisions'][0]['authorized_input'], record['input'])
        self.assertIn('alternative', package['rubric'].lower())


    def test_uncertain_and_malformed_grader_results_never_become_product_passes(self):
        package = evaluate.grader_package([('live3', evaluate.read_decision(ROOT / 'evidence/ticket37/live3'))])
        valid = {'results': [{'id': 'live3', 'status': 'uncertain', 'findings': [
            {'dimension': 'feasibility', 'quote': 'D8 wins the trick over West’s DQ',
             'fact': 'North D8 is below West DQ.', 'explanation': 'Further review needed.'}]}]}
        result = evaluate.adjudicate(package, valid)
        self.assertEqual(result['results'][0]['quality'], 'uncertain')
        self.assertEqual(result['results'][0]['attribution'], 'pending_review')
        valid['results'][0]['status'] = 'pass'
        valid['results'][0]['findings'][0]['quote'] = 'An invented quote'
        broken = evaluate.adjudicate(package, valid)
        self.assertEqual(broken['results'][0]['quality'], 'uncertain')
        self.assertEqual(broken['results'][0]['attribution'], 'evaluator_issue')


    def test_saved_grades_can_be_reprocessed_without_a_playing_or_grading_model(self):
        package = evaluate.grader_package([('live3', evaluate.read_decision(ROOT / 'evidence/ticket37/live3'))])
        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary) / 'saved'
            source.mkdir()
            (source / 'input.json').write_text(evaluate.json_text(package))
            (source / 'grader-output.json').write_text(json.dumps({'results': []}))
            output = Path(temporary) / 'regrade'
            run = subprocess.run([sys.executable, str(ROOT / 'evaluate.py'), 'regrade', '--run', str(source), '--output', str(output)], capture_output=True, text=True)
            self.assertEqual(run.returncode, 0, run.stderr)
            result = json.loads((output / 'evaluation.json').read_text())
            self.assertEqual(result['results'][0]['attribution'], 'evaluator_issue')


    def test_unavailable_grader_is_evaluator_issue_not_product_quality_failure(self):
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / 'unavailable'
            run = subprocess.run([sys.executable, str(ROOT / 'evaluate.py'), 'grade', '--decision', str(ROOT / 'evidence/ticket37/live3'), '--codex', '/no/such/codex', '--output', str(output)], capture_output=True, text=True)
            self.assertEqual(run.returncode, 0, run.stderr)
            result = json.loads((output / 'evaluation.json').read_text())['results'][0]
            self.assertEqual(result['quality'], 'uncertain')
            self.assertEqual(result['attribution'], 'evaluator_issue')
            self.assertEqual(result['mechanical'], 'pass')


    def test_unreadable_current_card_is_a_structural_product_failure(self):
        record = evaluate.read_decision(ROOT / 'evidence/ticket37/live3')
        record['rawOutput'] = json.dumps({'currentCard': 3, 'plan': {'update': 'replace', 'text': 'A plan'}, 'publicReason': 'A reason'})
        checks = evaluate.deterministic_checks(record)
        self.assertEqual(checks['structure']['status'], 'fail')

    def test_saved_rpc_mismatch_is_visible_and_no_defender_hand_enters_grader(self):
        record = evaluate.read_decision(ROOT / 'evidence/ticket37/live3')
        self.assertEqual(evaluate.deterministic_checks(record)['request_evidence']['status'], 'pass')
        record['input'] = 'A substituted request'
        self.assertEqual(evaluate.deterministic_checks(record)['request_evidence']['status'], 'fail')
        record['snapshot']['hands'].append({'seat': 'east', 'cards': ['DA']})
        with self.assertRaises(ValueError):
            evaluate.grader_package([('tainted', record)])


    def test_offline_regrade_preserves_runtime_and_actual_tool_failures(self):
        package = evaluate.grader_package([('live3', evaluate.read_decision(ROOT / 'evidence/ticket37/live3'))])
        grade = {'results': [{'id': 'live3', 'status': 'pass', 'findings': [{'dimension': 'test', 'quote': 'D3', 'fact': 'A legal diamond.', 'explanation': 'A valid-looking answer cannot override failed grader runtime.'}]}]}
        for metadata in ({'exit_code': 1, 'observed_tool_items': [], 'evaluator_error': 'Runtime failed'}, {'exit_code': 0, 'observed_tool_items': ['command_execution'], 'evaluator_error': 'Independent grader attempted a tool'}):
            with self.subTest(metadata=metadata), tempfile.TemporaryDirectory() as temporary:
                source = Path(temporary) / 'saved'
                source.mkdir()
                for name, value in [('input.json', package), ('grader-output.json', grade), ('run.json', metadata)]:
                    (source / name).write_text(evaluate.json_text(value))
                output = Path(temporary) / 'regrade'
                run = subprocess.run([sys.executable, str(ROOT / 'evaluate.py'), 'regrade', '--run', str(source), '--output', str(output)], capture_output=True, text=True)
                self.assertEqual(run.returncode, 0, run.stderr)
                result = json.loads((output / 'evaluation.json').read_text())['results'][0]
                self.assertEqual(result['quality'], 'uncertain')
                self.assertEqual(result['attribution'], 'evaluator_issue')


    def test_grader_can_cite_two_separate_exact_excerpts_without_inventing_a_quote(self):
        package = evaluate.grader_package([('live3', evaluate.read_decision(ROOT / 'evidence/ticket37/live3'))])
        grade = {'results': [{'id': 'live3', 'status': 'fail', 'findings': [{'dimension': 'action-plan consistency', 'quotes': ['D3', 'win the diamond lead with dummy’s D8'], 'fact': 'D3 is selected while the plan prescribes D8.', 'explanation': 'The action and plan disagree.'}]}]}
        result = evaluate.adjudicate(package, grade)['results'][0]
        self.assertEqual(result['quality'], 'fail')
        self.assertEqual(result['attribution'], 'product_error')


    def test_pre_inference_failure_is_reported_without_requesting_a_grader(self):
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / 'runtime'
            run = subprocess.run([sys.executable, str(ROOT / 'evaluate.py'), 'grade', '--decision', str(ROOT / 'evidence/ticket37/live1'), '--codex', '/no/such/codex', '--output', str(output)], capture_output=True, text=True)
            self.assertEqual(run.returncode, 0, run.stderr)
            result = json.loads((output / 'evaluation.json').read_text())['results'][0]
            self.assertEqual(result['attribution'], 'runtime_failure')
            self.assertEqual(result['quality'], 'uncertain')
            self.assertIn('Unexpected end of file', result['runtime_failure']['error'])
            self.assertFalse(json.loads((output / 'run.json').read_text())['grading_model_called'])


if __name__ == '__main__':
    unittest.main()
