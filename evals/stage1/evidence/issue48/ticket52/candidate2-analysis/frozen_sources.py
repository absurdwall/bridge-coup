"""Read verified historical source bytes without depending on current checkout files."""
import hashlib
import io
import json
import tarfile
import types

class FrozenSources:
    def __init__(self, analysis, candidate):
        self.path = analysis / 'runtime/candidate2-source.tar.gz'
        metadata = json.loads((analysis / 'runtime/candidate2-source-archive.json').read_text())
        data = self.path.read_bytes()
        assert hashlib.sha256(data).hexdigest() == metadata['sha256']
        assert metadata['source_commit'] == candidate['source_commit']
        assert metadata['members'] == candidate['source_hashes']
        self.members = {}
        with tarfile.open(fileobj=io.BytesIO(data), mode='r:gz') as archive:
            assert {member.name for member in archive.getmembers()} == set(metadata['members'])
            for name, expected in metadata['members'].items():
                content = archive.extractfile(name).read()
                assert hashlib.sha256(content).hexdigest() == expected, name
                self.members[name] = content
        self.sha256 = metadata['sha256']

    def read(self, relative):
        return self.members[relative]

    def load_json(self, relative):
        return json.loads(self.read(relative))

    def corpus(self):
        name = 'evals/stage1/corpus.py'
        module = types.ModuleType('frozen_candidate2_corpus')
        module.__file__ = str(self.path) + '!/' + name
        exec(compile(self.read(name), module.__file__, 'exec'), module.__dict__)
        return module
