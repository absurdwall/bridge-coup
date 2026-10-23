#!/usr/bin/env python3
"""Exercise saved-evidence auditing with absent .build and changed current source."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent

def verify(repo):
    relative = Path('evals/stage1/evidence/issue48/ticket52/candidate1')
    candidate = repo / relative
    freeze = json.loads((candidate / 'candidate.json').read_text())
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE='1')
    results = []
    with tempfile.TemporaryDirectory(prefix='bridge-cycle1-lifetime-') as directory:
        alternate = Path(directory)
        target = alternate / relative
        target.parent.mkdir(parents=True)
        target.symlink_to(candidate, target_is_directory=True)
        for name in freeze['source_hashes']:
            path = alternate / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('Deliberately changed current checkout bytes for portability regression.\n')
        assert not (alternate / '.build').exists()
        for script in ('verify_preservation.py','verify_adjudication_proofs.py'):
            outcome = subprocess.run([sys.executable,str(HERE/script),'--repo',str(alternate)],
                                     env=env, capture_output=True,text=True)
            assert outcome.returncode == 0, outcome.stderr
            result = json.loads(outcome.stdout)
            assert result['status'] == 'pass'
            results.append({'script':script,'historical_audit_with_changed_current_source':'pass'})
        negative = subprocess.run([sys.executable,str(HERE/'verify_preservation.py'),
                                   '--repo',str(alternate),'--check-current-source'],
                                  env=env,capture_output=True,text=True)
        assert negative.returncode != 0 and 'AssertionError' in negative.stderr
    return {'status':'pass','checks':results,'optional_current_source_comparison_rejects_changes':True,
            'scope':'Temporary deliberately altered source checkout, no .build or native executable used; raw evidence only symlinked read-only by audit commands. No actual repository source changed and no model calls.'}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo',type=Path,required=True)
    args = parser.parse_args()
    print(json.dumps(verify(args.repo.resolve()),indent=2))
