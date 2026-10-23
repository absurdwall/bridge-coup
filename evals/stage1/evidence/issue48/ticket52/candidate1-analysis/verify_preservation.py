#!/usr/bin/env python3
"""Verify immutable raw matrix, external originals, source and runtime archive."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import tarfile

HERE = Path(__file__).resolve().parent

def load(path):
    return json.loads(path.read_text())

def digest(data):
    return hashlib.sha256(data).hexdigest()

def verify(repo, analysis):
    manifest = load(analysis / 'raw-preservation.json')
    root = repo / manifest['candidate_root']
    for row in manifest['files']:
        data = (root / row['path']).read_bytes()
        assert len(data) == row['bytes'] and digest(data) == row['sha256'], row['path']
    candidate = load(root / 'candidate.json')
    for relative, expected in candidate['source_hashes'].items():
        assert digest((repo / relative).read_bytes()) == expected, relative
    external = load(analysis / 'external-preservation.json')
    for row in external['files']:
        data = (analysis / row['portable_path']).read_bytes()
        assert len(data) == row['bytes'] and digest(data) == row['sha256'], row['portable_path']
    index = load(analysis / 'originals/candidate1-adjudication-index.json')
    assert index['complete'] and len(index['attempts']) == 22
    for row in index['attempts']:
        assert digest((analysis / 'originals' / Path(row['review']).name).read_bytes()) == row['review_sha256']
    archive = analysis / 'runtime/candidate1-runtime.tar.gz'
    expected = load(analysis / 'runtime/candidate1-runtime-verification.json')
    assert digest(archive.read_bytes()) == expected['archive_sha256']
    with tarfile.open(fileobj=io.BytesIO(archive.read_bytes()), mode='r:gz') as bundle:
        for name, sha in expected['member_sha256'].items():
            assert digest(bundle.extractfile(name).read()) == sha, name
    assert expected['member_sha256']['bridge-play'] == candidate['binary_sha256']
    for role, filename in [('player','DeclarerInstructions.txt'),('reviewer','ReviewerInstructions.txt')]:
        assert expected['member_sha256']['BridgeTeacher_BridgeExpert.bundle/'+filename] == candidate['instruction_sha256'][role]
    return {'status':'pass', 'raw_files':manifest['file_count'], 'raw_bytes':manifest['total_bytes'],
            'external_originals':len(external['files']), 'frozen_source_files':len(candidate['source_hashes']),
            'independent_reviews':len(index['attempts']), 'runtime_archive_sha256':expected['archive_sha256'],
            'source_commit':candidate['source_commit'], 'raw_evidence_unchanged':True}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, required=True)
    parser.add_argument('--analysis', type=Path, default=HERE)
    args = parser.parse_args()
    print(json.dumps(verify(args.repo.resolve(),args.analysis.resolve()),indent=2))
