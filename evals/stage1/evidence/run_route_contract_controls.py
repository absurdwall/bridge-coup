"""Sequential High/xhigh public-driver diagnostics on one committed contract.

One eight-decision attempt per effort, without retries or acceptance credit.
Only effort literals differ between builds. All production module bytes and the
exact diagnostic deltas are recorded before generation.
"""
import difflib
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'evals/stage1'))
import acceptance

commit, output = sys.argv[1:3]
hypothesis = sys.argv[3] if len(sys.argv) > 3 else 'Carrying hypothetical card consumption, the trick winner, next leader and remaining entries through the whole route improves physical plan feasibility. This is unproven until real outputs are independently reviewed.'
commit = subprocess.check_output(['git', 'rev-parse', commit], cwd=ROOT, text=True).strip()
assert subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip() == commit
OUT = Path(output).resolve()
OUT.mkdir(exist_ok=False)
manifest = (ROOT / 'evals/stage1/evidence/high-effort-diagnostic/diagnostic-Package.swift.txt').read_text()
modules = ['BridgeDomain', 'BridgeEngine', 'BridgeExpert', 'BridgeCodex', 'BridgeDriver', 'BridgePlayCLI']
files = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', commit, '--'] + ['Sources/' + m for m in modules], cwd=ROOT, text=True).splitlines()
acceptance.write(OUT / 'predeclared.json', {
    'source_commit': commit, 'diagnostic_only': True, 'acceptance_credit': False,
    'schedule': ['high', 'xhigh'], 'model': 'gpt-6-luna', 'attempts_per_effort': 1,
    'decisions': 8, 'playing_retries': 0,
    'fixed': 'Same route contract, schema, board, opponent, runtime, grading and limits.',
    'hypothesis': hypothesis,
    'followup': 'For independently acceptable eight-decision controls, predeclare one complete development board; no unchanged candidate rerolls.',
})
for effort in ['high', 'xhigh']:
    source = Path(tempfile.mkdtemp(prefix='bridge-route-' + effort + '-'))
    (source / 'Package.swift').write_text(manifest)
    provenance, delta = [], []
    for name in files:
        original = subprocess.check_output(['git', 'show', commit + ':' + name], cwd=ROOT).decode()
        changed = original
        if name == 'Sources/BridgeCodex/CodexTransport.swift':
            assert original.count('private static let effort = "medium"') == 1
            assert original.count('model_reasoning_effort = "medium"') == 1
            changed = original.replace('private static let effort = "medium"', 'private static let effort = ' + json.dumps(effort)).replace('model_reasoning_effort = "medium"', 'model_reasoning_effort = ' + json.dumps(effort))
            delta = list(difflib.unified_diff(original.splitlines(keepends=True), changed.splitlines(keepends=True), fromfile=commit + '/' + name, tofile=effort + '/' + name))
        target = source / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(changed)
        provenance.append({'path': name, 'original_sha256': hashlib.sha256(original.encode()).hexdigest(), 'diagnostic_sha256': hashlib.sha256(changed.encode()).hexdigest(), 'unchanged': changed == original})
    assert sum(not row['unchanged'] for row in provenance) == 1
    log = OUT / (effort + '-build.log')
    env = dict(os.environ)
    env.pop('SDKROOT', None)
    with log.open('w') as stream:
        subprocess.run(['swift', 'build', '--package-path', str(source), '--product', 'bridge-play'], cwd=ROOT, env=env, stdout=stream, stderr=stream, timeout=180, check=True)
    out = OUT / effort
    candidate = acceptance.freeze(out, source / '.build/debug/bridge-play', '/Users/tingranwang/.nvm/versions/node/v24.12.0/bin/codex')
    # freeze is the unchanged production metadata collector; label overrides explicitly.
    candidate.update(requested_play_effort=effort, diagnostic_only=True, source_override='Effort-only build; see source-provenance.json and source-effort-only.patch; no acceptance credit.')
    acceptance.write(out / 'candidate.json', candidate)
    acceptance.write(out / 'source-provenance.json', {'source_path': str(source), 'source_commit': commit, 'files': provenance, 'manifest': manifest})
    (out / 'source-effort-only.patch').write_text(''.join(delta))
    # Avoid suggesting that freeze's unused 22-attempt plan was executed.
    (out / 'plan.json').rename(out / 'unused-finite-schedule.json')
    attempt = {'id': 'continuous-1', 'case_id': 'short-2', 'kind': 'short', 'board': 'boards/synthetic.json', 'decisions': 8, 'opponent_policy': 'conserve-high', 'diagnostic_only': True, 'requested_effort': effort}
    result = acceptance.run_attempt(candidate, attempt, out)
    acceptance.write(out / 'summary.json', result)
    print(effort, result['outcome'], result['quality_counts'], result['timing'].get('elapsedSeconds'), flush=True)
