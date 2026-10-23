"""Evaluator-only coverage: never feed these hidden holdings into any role."""
from pathlib import Path
import hashlib
import json
import sys
REPO=Path('/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup')
sys.path.insert(0,str(REPO/'evals/stage1'))
import corpus
proof=json.loads(Path(__file__).with_name('candidate1-short6-r1-r2-coverage-environment-proof.json').read_text())
for row in proof['attempts']:
 fixture=Path(row['fixture'])
 assert hashlib.sha256(fixture.read_bytes()).hexdigest()==row['fixture_sha256']
 p=REPO/'evals/stage1/evidence/issue48/ticket52/candidate1'/row['attempt']/'play/trace.json'
 assert hashlib.sha256(p.read_bytes()).hexdigest()==row['trace_sha256']
 trace=json.loads(p.read_text());events=list(trace['initialEvents'])
 events.extend(s['execution']['event'] for s in trace['steps'] if s.get('execution'))
 state=corpus.replay(json.loads(fixture.read_text()),events[:row['diamond_ace_sequence']+1])
 assert state['actingSeat']=='east'
 assert not any(c.startswith('S') for c in state['hands']['east'])
 assert {c for c in state['hands']['west'] if c.startswith('S')}=={'ST','S2'}
 for seat,cards in row['environment_only_remaining_hands'].items():
  assert state['hands'][seat]==set(cards)
 print(row['attempt']+': evaluator-only actual severance confirmed')
