#!/usr/bin/env python3
"""Verify immutable raw matrix, external originals, source and runtime archive."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import tarfile
from frozen_sources import FrozenSources

HERE = Path(__file__).resolve().parent

def load(path):
    return json.loads(path.read_text())

def digest(data):
    return hashlib.sha256(data).hexdigest()

def verify(repo, analysis, check_current_source=False):
    manifest = load(analysis / 'raw-preservation.json')
    root = repo / manifest['candidate_root']
    expected_paths = {row['path'] for row in manifest['files']}
    actual_paths = {path.relative_to(root).as_posix() for path in root.rglob('*') if path.is_file()}
    assert actual_paths == expected_paths, 'raw file set differs from preservation manifest'
    assert len(expected_paths) == len(manifest['files']) == manifest['file_count']
    assert sum(row['bytes'] for row in manifest['files']) == manifest['total_bytes']
    for row in manifest['files']:
        data = (root / row['path']).read_bytes()
        assert len(data) == row['bytes'] and digest(data) == row['sha256'], row['path']
    candidate = load(root / 'candidate.json')
    frozen = FrozenSources(analysis, candidate)
    if check_current_source:
        for relative, expected in candidate['source_hashes'].items():
            assert digest((repo / relative).read_bytes()) == expected, relative
    external = load(analysis / 'external-preservation.json')
    for row in external['files']:
        data = (analysis / row['portable_path']).read_bytes()
        assert len(data) == row['bytes'] and digest(data) == row['sha256'], row['portable_path']
    external_paths={str(Path(row['original_path']).resolve()):analysis/row['portable_path'] for row in external['files']}
    def verify_references(value):
        if isinstance(value,dict):
            if 'path' in value and 'sha256' in value and str(value['path']).startswith('/tmp/bridge-coup-issue48-context/'):
                assert digest(external_paths[str(Path(value['path']).resolve())].read_bytes())==value['sha256']
            for nested in value.values():verify_references(nested)
        elif isinstance(value,list):
            for nested in value:verify_references(nested)
    index = load(analysis / 'originals/candidate2-adjudication-index.json')
    verify_references(index)
    assert len(index['attempts']) == 21 and len(index['interrupted_attempts']) == 1
    assert index['interrupted_attempts'][0]['attempt']=='short-5-r1' and not index['interrupted_attempts'][0]['task_complete']
    expected_ids=[row['id'] for row in load(root/'plan.json') if row['id']!='short-5-r1']
    assert [row['attempt'] for row in index['attempts']]==expected_ids
    assert sum(row['independent_decision_counts']['pass'] for row in index['attempts'])==254
    assert not (root / 'short-5-r1/summary.json').exists()
    assert not (root / 'short-5-r1/playing-outcome.json').exists()
    assert not (root / 'execution-finished.json').exists()
    recovery = analysis / 'operational-recovery'
    assert load(recovery / 'finished.json')['remaining_attempts'] == 9
    for relative, expected in load(recovery / 'original13-inventory.json').items():
        assert digest((root / relative).read_bytes()) == expected, relative
    for row in index['attempts'] + index['interrupted_attempts']:
        assert digest((analysis / 'originals' / Path(row['review']).name).read_bytes()) == row['review_sha256']
        if row.get('raw_grade_addendum'):
            assert digest((analysis / 'originals' / Path(row['raw_grade_addendum']).name).read_bytes()) == row['raw_grade_addendum_sha256']
    archive = analysis / 'runtime/candidate2-runtime.tar.gz'
    expected = load(analysis / 'runtime/candidate2-runtime-verification.json')
    assert digest(archive.read_bytes()) == expected['archive_sha256']
    with tarfile.open(fileobj=io.BytesIO(archive.read_bytes()), mode='r:gz') as bundle:
        for name, sha in expected['member_sha256'].items():
            assert digest(bundle.extractfile(name).read()) == sha, name
    assert expected['member_sha256']['bridge-play'] == candidate['binary_sha256']
    for role, filename in [('player','DeclarerInstructions.txt'),('reviewer','ReviewerInstructions.txt')]:
        assert expected['member_sha256']['BridgeTeacher_BridgeExpert.bundle/'+filename] == candidate['instruction_sha256'][role]
    return {'status':'pass', 'raw_files':manifest['file_count'], 'raw_bytes':manifest['total_bytes'],
            'external_originals':len(external['files']), 'frozen_source_files':len(candidate['source_hashes']),
            'normal_completed_reviews':len(index['attempts']), 'interrupted_partial_reviews':len(index['interrupted_attempts']), 'runtime_archive_sha256':expected['archive_sha256'],
            'source_commit':candidate['source_commit'], 'frozen_source_archive_sha256':frozen.sha256,
            'current_source_comparison':check_current_source, 'raw_evidence_unchanged':True}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, required=True)
    parser.add_argument('--analysis', type=Path, default=HERE)
    parser.add_argument('--check-current-source', action='store_true',
                        help='Optional freeze-era check; omit after later candidates change the checkout.')
    args = parser.parse_args()
    print(json.dumps(verify(args.repo.resolve(),args.analysis.resolve(),args.check_current_source),indent=2))
