"""One predeclared complete xhigh development board, reusing audited binary."""
import hashlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
BASE = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / 'evals/stage1'))
import acceptance

OUT = BASE / 'full-board'
OUT.mkdir(exist_ok=False)
candidate = acceptance.load(BASE / 'candidate.json')
provenance = acceptance.load(BASE / 'predeclared.json')
for row in provenance['public_modules']:
    source = Path(provenance['source_path']) / row['path']
    assert hashlib.sha256(source.read_bytes()).hexdigest() == row['diagnostic_sha256']
acceptance.preflight(candidate)
acceptance.write(OUT / 'plan.json', {
    'diagnostic_only': True, 'acceptance_credit': False,
    'source_base': '352d61f', 'requested_model': 'gpt-6-luna',
    'requested_effort': 'xhigh', 'attempts': 1, 'playing_retries': 0,
    'task': 'All52cards,13tricks; synthetic/conserve-high/sole-legal true',
    'basis': 'Previous8 independently reviewed8acceptable; inspect later entry decisions.',
    'reuse': str(BASE / 'predeclared.json'),
})
acceptance.write(OUT / 'candidate.json', candidate)
attempt = {
    'id': 'full-1', 'case_id': 'full-development', 'kind': 'full',
    'board': 'boards/synthetic.json', 'decisions': None,
    'opponent_policy': 'conserve-high', 'diagnostic_only': True,
    'requested_model': 'gpt-6-luna', 'requested_effort': 'xhigh',
}
result = acceptance.run_attempt(candidate, attempt, OUT)
acceptance.write(OUT / 'summary.json', result)
print({key: result[key] for key in ['outcome', 'quality_counts', 'counts', 'timing']}, flush=True)
