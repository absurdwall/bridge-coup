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
    external_expected = {row['portable_path'] for row in external['files']}
    external_actual = {path.relative_to(analysis).as_posix() for path in (analysis/'originals').rglob('*') if path.is_file()}
    assert external_actual == external_expected, 'outside original file set differs from preservation manifest'
    assert len(external_expected) == len(external['files'])
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
    index = load(analysis / 'originals/candidate3-adjudication-index.json')
    verify_references(index)
    expected_ids=[row['id'] for row in load(root/'plan.json')]
    assert len(expected_ids)==22 and len(set(expected_ids))==22
    assert [row['attempt'] for row in index['attempts']]==expected_ids
    assert not index.get('interrupted_attempts')
    assert load(root/'execution-finished.json')['attempts']==len(expected_ids)
    for identifier in expected_ids:
        assert (root/identifier/'summary.json').is_file(), identifier
    for row in index['attempts']:
        assert digest((analysis / 'originals' / Path(row['review']).name).read_bytes()) == row['review_sha256']
        if row.get('raw_grade_addendum'):
            assert digest((analysis / 'originals' / Path(row['raw_grade_addendum']).name).read_bytes()) == row['raw_grade_addendum_sha256']
    archive = analysis / 'runtime/candidate3-runtime.tar.gz'
    expected = load(analysis / 'runtime/candidate3-runtime-verification.json')
    assert digest(archive.read_bytes()) == expected['archive_sha256']
    assert archive.stat().st_size == expected['bytes']
    with tarfile.open(fileobj=io.BytesIO(archive.read_bytes()), mode='r:gz') as bundle:
        assert {member.name for member in bundle.getmembers() if member.isfile()} == set(expected['member_sha256'])
        for name, sha in expected['member_sha256'].items():
            assert digest(bundle.extractfile(name).read()) == sha, name
    assert expected['member_sha256']['bridge-play'] == candidate['binary_sha256']
    for role, filename in [('player','DeclarerInstructions.txt'),('reviewer','ReviewerInstructions.txt')]:
        assert expected['member_sha256']['BridgeTeacher_BridgeExpert.bundle/'+filename] == candidate['instruction_sha256'][role]
    return {'status':'pass', 'raw_files':manifest['file_count'], 'raw_bytes':manifest['total_bytes'],
            'external_originals':len(external['files']), 'frozen_source_files':len(candidate['source_hashes']),
            'normal_completed_reviews':len(index['attempts']), 'interrupted_partial_reviews':len(index.get('interrupted_attempts',[])), 'runtime_archive_sha256':expected['archive_sha256'],
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
