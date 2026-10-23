"""Versioned execution conditions; no inference answers enter live roles."""
import copy
from pathlib import Path
import sys
import unittest
import subprocess
import tempfile
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
import acceptance


class Candidate2ConfigurationTests(unittest.TestCase):
    def test_only_three_short3_attempts_disable_mechanical_skip_with_original_bounds(self):
        attempts = acceptance.schedule(acceptance.load(ROOT / 'corpus/manifest.json'))
        self.assertEqual(len(attempts), 22)
        self.assertEqual([a['id'] for a in attempts if not a['mechanical_sole_legal']],
                         ['short-3-r1', 'short-3-r2', 'short-3-r3'])
        self.assertEqual([a['decisions'] for a in attempts if a['case_id'] == 'short-3'], [12, 12, 12])
        self.assertTrue(all(a['mechanical_sole_legal'] for a in attempts if a['case_id'] != 'short-3'))

    def test_exact_cli_options_and_mode_audit_share_frozen_case_configuration(self):
        configuration = acceptance.execution_configuration()
        candidate = {'execution_configuration': configuration, 'binary': '/offline/bridge-play',
                     'request_timeout_seconds': 180, 'run_timeout_seconds': 1800}
        attempts = acceptance.schedule(acceptance.load(ROOT / 'corpus/manifest.json'))
        for attempt in attempts:
            command = acceptance.playing_command(candidate, attempt, Path('/offline/evidence'), '/offline/codex')
            self.assertEqual(command[command.index('--sole-legal') + 1], 'false' if attempt['case_id'] == 'short-3' else 'true')
            if attempt['case_id'] == 'short-3':
                self.assertEqual(command[command.index('--decisions') + 1], '12')
        tampered = copy.deepcopy(next(a for a in attempts if a['case_id'] == 'short-3'))
        tampered['mechanical_sole_legal'] = True
        with self.assertRaisesRegex(ValueError, 'execution option'):
            acceptance.playing_command(candidate, tampered, Path('/offline/evidence'), '/offline/codex')
        changed_plan = copy.deepcopy(attempts)
        changed_plan[6]['mechanical_sole_legal'] = True
        with self.assertRaisesRegex(ValueError, 'schedule changed'):
            acceptance.verify_schedule(changed_plan)
        directory = ROOT / 'evidence/ticket40/development-v3'
        trace = acceptance.load(directory / 'trace.json')
        trace['mechanicalSoleLegal'] = False
        board = acceptance.load(ROOT / 'corpus/boards/synthetic.json')
        audit = acceptance.inspect_play(board, trace, directory, False)
        self.assertTrue(any('skipping is disabled' in error for error in audit['errors']))
        trace['mechanicalSoleLegal'] = True
        audit = acceptance.inspect_play(board, trace, directory, False)
        self.assertTrue(any('differs from frozen case option' in error for error in audit['errors']))

    def test_offline_freeze_metadata_and_preflight_attest_execution_options(self):
        # All subprocesses are system-boundary fakes; this is not a native freeze or validation cycle.
        def recorded_process(command, **kwargs):
            output = 'recorded-runtime' if '--version' in command else 'recorded-source' if 'rev-parse' in command else ''
            return subprocess.CompletedProcess(command, 0, stdout=output, stderr='')
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            binary = root / 'offline-runtime'
            binary.write_bytes(b'recorded binary')
            with patch('subprocess.run', side_effect=recorded_process), patch.object(acceptance, 'bundled_catalog', return_value=b'{"models":[]}'):
                candidate = acceptance.freeze(root / 'offline-freeze', binary, binary)
                self.assertEqual(candidate['execution_configuration'], acceptance.execution_configuration())
                self.assertIn('evals/stage1/case-execution.json', candidate['source_hashes'])
                candidate['source_commit'] = None  # The recorded fake has no Git archive; test config attestation independently.
                acceptance.preflight(candidate)
                complete = copy.deepcopy(candidate)
                candidate.pop('execution_configuration')
                with self.assertRaisesRegex(ValueError, 'per-case execution configuration'):
                    acceptance.preflight(candidate)
                candidate = complete
                candidate['execution_configuration']['case_options']['short-3']['mechanical_sole_legal'] = 0
                with self.assertRaisesRegex(ValueError, 'per-case execution configuration'):
                    acceptance.preflight(candidate)
                candidate['execution_configuration']['case_options']['short-3']['mechanical_sole_legal'] = True
                with self.assertRaisesRegex(ValueError, 'per-case execution configuration'):
                    acceptance.preflight(candidate)
            plan = acceptance.load(root / 'offline-freeze/plan.json')
            self.assertEqual(sum(not attempt['mechanical_sole_legal'] for attempt in plan), 3)
            report_candidate = {'source_commit': 'offline-source', 'execution_configuration': acceptance.execution_configuration()}
            acceptance.render_report(root, report_candidate, [])
            report = (root / 'REPORT.md').read_text()
            self.assertIn(report_candidate['execution_configuration']['version'], report)
            self.assertIn('Only short-3', report)
            self.assertIn('not a prompt-only controlled comparison', report)


if __name__ == '__main__':
    unittest.main()
