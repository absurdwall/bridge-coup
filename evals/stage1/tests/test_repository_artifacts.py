"""Public commit guard: fixtures can be staged, generated runs cannot."""
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

GUARD = Path(__file__).resolve().parents[3]/'Scripts/check-repository-artifacts.py'


class RepositoryArtifactTests(unittest.TestCase):
    def test_small_fixture_is_allowed_but_raw_run_is_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            subprocess.run(['git', 'init', '-q', str(root)], check=True)
            sample = root/'Tests/Fixtures/example.json'
            sample.parent.mkdir(parents=True)
            sample.write_text('{}')
            subprocess.run(['git', 'add', '.'], cwd=root, check=True)
            good = subprocess.run([sys.executable, str(GUARD), '--staged'], cwd=root, capture_output=True, text=True)
            self.assertEqual(good.returncode, 0, good.stderr)
            raw = root/'evals/stage1/evidence/new-run/trace.json'
            raw.parent.mkdir(parents=True)
            raw.write_text('{}')
            subprocess.run(['git', 'add', '.'], cwd=root, check=True)
            bad = subprocess.run([sys.executable, str(GUARD), '--staged'], cwd=root, capture_output=True, text=True)
            self.assertNotEqual(bad.returncode, 0)
            self.assertIn('Generated run artifact', bad.stderr)


if __name__ == '__main__':
    unittest.main()
