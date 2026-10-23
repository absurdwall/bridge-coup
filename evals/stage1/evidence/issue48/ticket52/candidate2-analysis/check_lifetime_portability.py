#!/usr/bin/env python3
"""Audit historical C2 with deliberately changed current source and no native build."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

HERE=Path(__file__).resolve().parent

def verify(repo):
    relative=Path('evals/stage1/evidence/issue48/ticket52/candidate2')
    analysis_relative=relative.with_name('candidate2-analysis')
    candidate=repo/relative;freeze=json.loads((candidate/'candidate.json').read_text())
    env=dict(os.environ,PYTHONDONTWRITEBYTECODE='1');results=[]
    with tempfile.TemporaryDirectory(prefix='bridge-c2-lifetime-') as directory:
        alternate=Path(directory);target=alternate/relative;target.parent.mkdir(parents=True)
        target.mkdir()
        for original in candidate.rglob('*'):
            if original.is_file():
                linked=target/original.relative_to(candidate)
                linked.parent.mkdir(parents=True,exist_ok=True)
                linked.symlink_to(original)
        (alternate/analysis_relative).symlink_to(HERE,target_is_directory=True)
        for name in freeze['source_hashes']:
            path=alternate/name;path.parent.mkdir(parents=True,exist_ok=True)
            path.write_text('Deliberately changed current checkout for historical-audit regression.\n')
        assert not (alternate/'.build').exists()
        for name,expected in [('verify_preservation.py','pass'),('verify_public_windows.py','public_facts_verified'),('verify_interrupted_cost.py','pass')]:
            outcome=subprocess.run([sys.executable,str(HERE/name),'--repo',str(alternate)],env=env,capture_output=True,text=True)
            assert outcome.returncode==0,outcome.stderr
            assert json.loads(outcome.stdout)['status']==expected
            results.append({'script':name,'changed_current_source_no_build':'pass'})
        proof=HERE/'originals/check_candidate2_walker_coverage.py'
        outcome=subprocess.run([sys.executable,str(proof),'--repo',str(alternate),'--reports',str(HERE/'originals'),
                                '--proof',str(HERE/'originals/candidate2-short6-coverage-environment-proof.json')],
                                env=env,capture_output=True,text=True)
        assert outcome.returncode==0,outcome.stderr
        results.append({'script':proof.name,'frozen_archive_environment_only_replay':'pass'})
        counter=HERE/'originals/check_candidate2_full_reserved_r1_counterbranch.py'
        outcome=subprocess.run([sys.executable,str(counter),'--repo',str(alternate),
                                '--proof',str(HERE/'originals/candidate2-full-reserved-r1-counterbranch-proof.json')],
                               env=env,capture_output=True,text=True)
        assert outcome.returncode==0,outcome.stderr
        results.append({'script':counter.name,'public_compatible_counterbranch_only':'pass'})
        sentinel=target/'unlisted-audit-regression-sentinel.txt'
        sentinel.write_text('Owned temporary audit regression sentinel.\n')
        try:
            unlisted=subprocess.run([sys.executable,str(HERE/'verify_preservation.py'),'--repo',str(alternate)],env=env,capture_output=True,text=True)
            assert unlisted.returncode!=0 and 'raw file set differs from preservation manifest' in unlisted.stderr, 'Verifier accepted an unlisted raw file.'
        finally:
            sentinel.unlink()
        results.append({'script':'verify_preservation.py','unlisted_raw_file_rejected':'pass'})
        negative=subprocess.run([sys.executable,str(HERE/'verify_preservation.py'),'--repo',str(alternate),'--check-current-source'],env=env,capture_output=True,text=True)
        assert negative.returncode!=0 and 'AssertionError' in negative.stderr
    return {'status':'pass','checks':results,'optional_current_source_comparison_rejects_changes':True,
            'scope':'Only a temporary source skeleton is changed. Saved artifacts are read through symlinks; no actual current source, .build, installed native executable, network or model is used.'}

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--repo',required=True,type=Path);args=parser.parse_args()
    print(json.dumps(verify(args.repo.resolve()),indent=2))
