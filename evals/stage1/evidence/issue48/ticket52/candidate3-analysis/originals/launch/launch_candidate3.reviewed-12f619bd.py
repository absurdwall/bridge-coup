#!/usr/bin/env python3
"""Validate a fresh frozen C3, then launch the original runner once, detached."""
import argparse
import datetime
import hashlib
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tarfile

PYTHON = '/tmp/bridge-coup-issue48-context/venv/bin/python'
RELATIVE = Path('evals/stage1/evidence/issue48/ticket52/candidate3')
HERE = Path(__file__).resolve().parent

def sha(data):
    return hashlib.sha256(data).hexdigest()

def load(path):
    return json.loads(path.read_text())

def validate(repo, expected_source):
    candidate_root = repo / RELATIVE
    candidate = load(candidate_root / 'candidate.json')
    plan = load(candidate_root / 'plan.json')
    expected_ids = ['short-%d-r%d' % (case, repeat) for case in range(1, 7) for repeat in range(1, 4)]
    expected_ids += ['full-%s-r%d' % (case, repeat) for case in ('development', 'reserved') for repeat in (1, 2)]
    assert [row['id'] for row in plan] == expected_ids
    assert candidate['source_commit'] == expected_source
    observed_head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip()
    assert observed_head == expected_source, (observed_head, expected_source)
    for relative, expected in candidate['source_hashes'].items():
        assert sha((repo / relative).read_bytes()) == expected, relative
    dirty = subprocess.check_output(['git', 'status', '--porcelain', '--'] + sorted(candidate['source_hashes']), cwd=repo, text=True)
    assert not dirty.strip(), dirty
    for name in ('execution-started.json', 'execution-finished.json', 'summary.json', 'REPORT.md'):
        assert not (candidate_root / name).exists(), 'Fresh C3 already has ' + name
    assert all(not (candidate_root / identifier).exists() for identifier in expected_ids)
    for row in plan:
        assert row['execution_config_version'] == 'stage1-reviewed-case-execution-v1'
        assert row['mechanical_sole_legal'] is (row['case_id'] != 'short-3')
    assert all(candidate['role_configurations'][role] == {'model':'gpt-6.1-sol','effort':'medium','additional_tools':[]} for role in ('player','reviewer'))
    assert candidate['requested_grader_model'] == 'gpt-6.1-sol' and candidate['requested_grader_effort'] == 'medium'
    assert candidate['max_semantic_rounds'] == 5 and candidate['max_reviewer_technical_attempts'] == 4
    assert candidate['request_timeout_seconds'] == 180 and candidate['run_timeout_seconds'] == 1800
    for key in ('binary', 'codex'):
        assert sha(Path(candidate[key]).read_bytes()) == candidate[key + '_sha256'], key
    analysis = candidate_root.with_name('candidate3-analysis')
    runtime = analysis / 'runtime'
    source_meta = load(runtime / 'candidate3-source-archive.json')
    assert source_meta['source_commit'] == expected_source
    assert source_meta['members'] == candidate['source_hashes']
    source_bytes = (runtime / 'candidate3-source.tar.gz').read_bytes()
    assert len(source_bytes) == source_meta['bytes'] and sha(source_bytes) == source_meta['sha256']
    with tarfile.open(fileobj=io.BytesIO(source_bytes), mode='r:gz') as archive:
        members = {member.name for member in archive.getmembers() if member.isfile()}
        assert members == set(candidate['source_hashes'])
        for name, expected in candidate['source_hashes'].items():
            assert sha(archive.extractfile(name).read()) == expected, name
    runtime_meta = load(runtime / 'candidate3-runtime-verification.json')
    runtime_bytes = (runtime / 'candidate3-runtime.tar.gz').read_bytes()
    assert len(runtime_bytes) == runtime_meta['bytes'] and sha(runtime_bytes) == runtime_meta['archive_sha256']
    with tarfile.open(fileobj=io.BytesIO(runtime_bytes), mode='r:gz') as archive:
        assert {member.name for member in archive.getmembers() if member.isfile()} == set(runtime_meta['member_sha256'])
        for name, expected in runtime_meta['member_sha256'].items():
            assert sha(archive.extractfile(name).read()) == expected, name
    assert runtime_meta['member_sha256']['bridge-play'] == candidate['binary_sha256']
    for role, name in [('player','DeclarerInstructions.txt'),('reviewer','ReviewerInstructions.txt')]:
        expected = candidate['instruction_sha256'][role]
        assert runtime_meta['member_sha256']['BridgeTeacher_BridgeExpert.bundle/' + name] == expected
        assert sha((Path(candidate['binary']).parent / 'BridgeTeacher_BridgeExpert.bundle' / name).read_bytes()) == expected
    runner = repo / 'evals/stage1/acceptance.py'
    return {'source_commit':expected_source,'candidate':str(candidate_root),'candidate_sha256':sha((candidate_root/'candidate.json').read_bytes()),
            'plan_sha256':sha((candidate_root/'plan.json').read_bytes()),'schedule_ids':expected_ids,
            'source_archive_sha256':source_meta['sha256'],'runtime_archive_sha256':runtime_meta['archive_sha256'],
            'binary_sha256':candidate['binary_sha256'],'instruction_sha256':candidate['instruction_sha256'],
            'native_sha256':candidate['codex_sha256'],'runner_sha256':sha(runner.read_bytes()),
            'command':[PYTHON,'-u',str(runner),'run','--output',str(candidate_root)]}

def spawn_once(command, repo, record_dir, attestation):
    # Exclusive creation is a once-only operational boundary. Any failed launch
    # retains this record and requires inspection; this launcher never resumes.
    record_dir.mkdir(parents=True, exist_ok=True)
    registry = record_dir / 'detached-registry.json'
    with registry.open('x') as stream:
        metadata = {'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'state':'launch-reserved',
                    'launcher_pid':os.getpid(),'launcher_pgid':os.getpgrp(),'interpreter':PYTHON,
                    'interpreter_realpath':str(Path(PYTHON).resolve()),'interpreter_sha256':sha(Path(PYTHON).read_bytes()),
                    'launcher_path':str(Path(__file__).resolve()),'launcher_sha256':sha(Path(__file__).read_bytes()),
                    'command':command,'cwd':str(repo),'attestation':attestation,
                    'scope':'Fresh original acceptance.py run, once, strict22; no resume/retry/supervisor/product restart feature.'}
        json.dump(metadata, stream, indent=2);stream.flush();os.fsync(stream.fileno())
        log_path = record_dir / 'runner.stdout-stderr.log'
        with log_path.open('x') as log:
            child = subprocess.Popen(command, cwd=repo, env=dict(os.environ,PYTHONDONTWRITEBYTECODE='1',PYTHONUNBUFFERED='1'),
                                     stdin=subprocess.DEVNULL,stdout=log,stderr=subprocess.STDOUT,
                                     start_new_session=True,close_fds=True)
        metadata.update({'state':'spawned','pid':child.pid,'pgid':os.getpgid(child.pid),'session':os.getsid(child.pid),
                         'stdout_stderr':str(log_path),'actual_exit':None})
        assert metadata['pid'] == metadata['pgid'] == metadata['session']
        assert metadata['pgid'] != metadata['launcher_pgid']
        stream.seek(0);json.dump(metadata,stream,indent=2);stream.truncate();stream.flush();os.fsync(stream.fileno())
    return metadata

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo',type=Path,required=True)
    parser.add_argument('--expected-source',required=True)
    parser.add_argument('--launch',action='store_true',help='Only after explicit root authorization; otherwise read-only validation.')
    args = parser.parse_args();repo=args.repo.resolve()
    assert Path(sys.executable).resolve() == Path(PYTHON).resolve(), 'Use the exact isolated interpreter.'
    attestation = validate(repo,args.expected_source)
    if args.launch:
        metadata = spawn_once(attestation['command'],repo,HERE/'execution',attestation)
        print(json.dumps(metadata,indent=2))
    else:
        print(json.dumps({'state':'read-only-ready','attestation':attestation},indent=2))

if __name__ == '__main__':
    main()
