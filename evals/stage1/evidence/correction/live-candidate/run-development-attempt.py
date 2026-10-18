"""Run exactly one predeclared affected development attempt; root reviews before another."""
import json
from pathlib import Path
import sys

repo, frozen, output, selected = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]), int(sys.argv[4])
sys.path.insert(0, str(repo / 'evals/stage1'))
import acceptance

plan = [
    {'id': 'development-normal', 'case_id': 'short-2', 'kind': 'short', 'board': 'boards/synthetic.json', 'decisions': 8, 'opponent_policy': 'conserve-high'},
    {'id': 'development-entries', 'case_id': 'short-4', 'kind': 'short', 'board': 'boards/synthetic.json', 'decisions': 16, 'opponent_policy': 'conserve-high'},
    {'id': 'development-former-reserve', 'case_id': 'full-reserved', 'kind': 'short', 'board': 'boards/reserved-acceptance.json', 'decisions': 8, 'opponent_policy': 'conserve-high'},
    {'id': 'development-walker', 'case_id': 'short-6', 'kind': 'short', 'board': 'boards/walker-holdup-adapted.json', 'decisions': 12, 'opponent_policy': 'conserve-high'},
]
if not 0 <= selected < len(plan):
    raise SystemExit('Attempt index outside predeclared development plan')
output.mkdir(parents=True, exist_ok=True)
saved_plan = output / 'development-plan.json'
if saved_plan.exists():
    if acceptance.load(saved_plan) != plan:
        raise SystemExit('Predeclared development plan changed')
else:
    with saved_plan.open('x') as stream:
        json.dump(plan, stream, indent=2)
for earlier in plan[:selected]:
    review = output / earlier['id'] / 'root-review.json'
    if not review.exists() or acceptance.load(review).get('continue_candidate') is not True:
        raise SystemExit('Earlier attempt lacks a reviewed continuation decision')
candidate = acceptance.load(frozen / 'candidate.json')
acceptance.preflight(candidate)
print(json.dumps(acceptance.run_attempt(candidate, plan[selected], output), indent=2))
