import importlib.util
from pathlib import Path
import unittest
import tempfile
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('acceptance', ROOT / 'acceptance.py')
acceptance = importlib.util.module_from_spec(spec)
spec.loader.exec_module(acceptance)


class AcceptanceTests(unittest.TestCase):
    def test_finite_schedule_has_22_independent_attempts_and_fixed_policies(self):
        manifest = acceptance.load(ROOT / 'corpus/manifest.json')
        attempts = acceptance.schedule(manifest)
        self.assertEqual(len(attempts), 22)
        self.assertEqual(len({a['id'] for a in attempts}), 22)
        self.assertEqual(sum(a['kind'] == 'short' for a in attempts), 18)
        self.assertEqual(sum(a['kind'] == 'full' for a in attempts), 4)
        self.assertEqual([a['opponent_policy'] for a in attempts if a['case_id'] == 'short-5'], ['pavlicek-entry'] * 3)
        self.assertEqual([a['decisions'] for a in attempts if a['case_id'] == 'short-1'], [1] * 3)

    def test_saved_complete_board_is_independently_replayed_and_sources_counted(self):
        evidence = ROOT / 'evidence/ticket40/development-v3'
        board = acceptance.load(ROOT / 'corpus/boards/synthetic.json')
        trace = acceptance.load(evidence / 'trace.json')
        result = acceptance.inspect_play(board, trace, evidence)
        self.assertEqual(result['status'], 'pass')
        self.assertEqual(result['actual_events'], 52)
        self.assertEqual(result['tricks'], [7, 6])
        self.assertEqual(result['actual_rpc_requests'], 20)
        self.assertEqual(result['model_actions'], 20)
        self.assertEqual(result['forced_actions'], 6)
        self.assertEqual(result['initial_opponent_actions'], 1)
        self.assertEqual(result['driver_opponent_actions'], 25)
        self.assertTrue(result['complete'])
        trace['steps'][-1]['execution']['source'] = 'model'
        broken = acceptance.inspect_play(board, trace, evidence)
        self.assertEqual(broken['status'], 'fail')
        self.assertTrue(any('model source' in error for error in broken['errors']))

    def test_frozen_candidate_rejects_changed_source_or_binary(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'core.swift').write_text('original source')
            (root / 'bridge-play').write_text('original binary')
            hashes = acceptance.hash_files(root, ['core.swift', 'bridge-play'])
            self.assertEqual(acceptance.changed_files(root, hashes), [])
            (root / 'core.swift').write_text('changed source')
            self.assertEqual(acceptance.changed_files(root, hashes), ['core.swift'])
            (root / 'bridge-play').unlink()
            self.assertEqual(acceptance.changed_files(root, hashes), ['bridge-play', 'core.swift'])

    def test_quality_failure_or_uncertainty_never_becomes_board_pass(self):
        self.assertEqual(acceptance.quality_status({'results': [{'overall': 'pass'}]}), 'pass')
        self.assertEqual(acceptance.quality_status({'results': [{'overall': 'pass'}, {'overall': 'fail'}]}), 'fail')
        self.assertEqual(acceptance.quality_status({'results': [{'overall': 'uncertain', 'attribution': 'evaluator_issue'}]}), 'pending')
        self.assertEqual(acceptance.quality_status({'results': []}), 'pending')

    def test_failed_last_request_never_completes_short_task(self):
        attempt = {'kind': 'short', 'decisions': 8}
        inspection = {'status': 'pass', 'complete': False, 'model_actions': 7}
        trace = {'modelRequests': 8, 'failure': 'eighth request failed'}
        self.assertFalse(acceptance.task_complete(attempt, inspection, trace, {'exit_code': 1}))
        self.assertFalse(acceptance.task_complete(attempt, inspection, trace, {'exit_code': 0}))
        trace['failure'] = None
        inspection['model_actions'] = 8
        self.assertTrue(acceptance.task_complete(attempt, inspection, trace, {'exit_code': 0}))

    def test_final_no_answer_failure_is_preserved_after_good_decisions(self):
        with tempfile.TemporaryDirectory() as directory:
            play = Path(directory)
            good = play / 'decision-0001'
            good.mkdir()
            (good / 'decision.json').write_text('{}')
            (play / 'failure.json').write_text('{"error":"unreadable answer"}')
            self.assertEqual(acceptance.decision_directories(play), [good, play])
            bad = play / 'decision-0002'
            bad.mkdir()
            (bad / 'decision.json').write_text('{}')
            (bad / 'failure.json').write_text('{}')
            self.assertEqual(acceptance.decision_directories(play), [good, bad])

    def test_continuation_requires_three_actual_decisions_and_plan_review(self):
        self.assertEqual(acceptance.coverage('short-2', [], [{}, {}], False)['status'], 'uncovered')
        self.assertEqual(acceptance.coverage('short-2', [], [{}, {}, {}], False)['status'], 'pending')

    def test_matrix_plan_cannot_drop_or_replace_an_attempt(self):
        plan = acceptance.schedule(acceptance.load(ROOT / 'corpus/manifest.json'))
        acceptance.verify_schedule(plan)
        with self.assertRaises(ValueError):
            acceptance.verify_schedule(plan[:-1])
        plan[0]['opponent_policy'] = 'other'
        with self.assertRaises(ValueError):
            acceptance.verify_schedule(plan)

    def test_partial_proxy_startup_is_bounded(self):
        process = subprocess.Popen([sys.executable, '-c', "import sys,time;sys.stdout.write('partial');sys.stdout.flush();time.sleep(2)"], stdout=subprocess.PIPE)
        started = time.monotonic()
        try:
            with self.assertRaises(TimeoutError):
                acceptance.proxy_wrapper(process, timeout=0.05)
            self.assertLess(time.monotonic() - started, 1)
        finally:
            process.terminate()
            process.wait()
            process.stdout.close()

    def test_outer_command_deadline_terminates_unresponsive_process_group(self):
        with tempfile.TemporaryFile() as sink:
            started = time.monotonic()
            with self.assertRaises(subprocess.TimeoutExpired):
                acceptance.bounded_command([sys.executable, '-c', 'import signal,time;signal.signal(signal.SIGTERM,signal.SIG_IGN);time.sleep(2)'], sink, sink, 0.05)
            self.assertLess(time.monotonic() - started, 1)

    def test_durable_report_identifies_actual_source_commit(self):
        with tempfile.TemporaryDirectory() as directory:
            acceptance.render_report(Path(directory), {'source_commit': '37fe44c-example'}, [])
            report = (Path(directory) / 'REPORT.md').read_text()
            self.assertIn('`37fe44c-example`', report)
            self.assertNotIn('`%s`', report)
            self.assertIn('PENDING INDEPENDENT REVIEW', report)
            self.assertIn('0 of 22', report)


if __name__ == '__main__':
    unittest.main()
