#!/usr/bin/env python3
"""Read-only audit of the frozen matrix's actual native reviewer request bytes."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path


def audit(root):
    schedule = json.loads((root / 'plan.json').read_text())
    records = []
    counts = Counter()
    player_round_counts = Counter()
    round_records = []
    for attempt in schedule:
        directory = root / attempt['id']
        summary = json.loads((directory / 'summary.json').read_text())
        assert summary['wire']['protocol_status'] == 'pass', attempt['id']
        candidates = 0
        roles = {row['wire_request']:row['role'] for row in summary['wire']['role_requests']}
        for decision_path in sorted((directory / 'play').rglob('decision.json')):
            decision = json.loads(decision_path.read_text())
            for row in decision.get('reviewRounds', []):
                raw_candidate = json.loads(row['playerRawOutput'])
                assert raw_candidate == row['pending']['candidate'], str(decision_path)
                plan = raw_candidate['plan']
                operation = plan['update']
                assert 'text' in plan, str(decision_path)
                if operation in ('keep', 'withdraw'):
                    assert plan['text'] is None, str(decision_path)
                player_round_counts[operation] += 1
                round_records.append({'decision':str(decision_path.relative_to(root)),
                                      'round':row['number'], 'operation':operation,
                                      'raw_decodes_to_pending_candidate':True,
                                      'explicit_text':True,
                                      'text_is_null':plan['text'] is None})
        for path in sorted((directory / 'wire').glob('request-*.json')):
            request = json.loads(path.read_text())
            assert not request.get('tools') and not request.get('additional_tools'), str(path)
            if roles[int(path.stem.split('-')[-1])] != 'reviewer':
                continue
            for message in request.get('input', []):
                if message.get('role') != 'user':
                    continue
                for content in message.get('content', []):
                    try:
                        value = json.loads(content.get('text', ''))
                    except (ValueError, TypeError):
                        continue
                    if not isinstance(value, dict) or 'candidate' not in value:
                        continue
                    candidate = value['candidate']
                    plan = candidate['plan']
                    operation = plan['update']
                    assert operation in ('keep', 'replace', 'withdraw'), str(path)
                    assert 'text' in plan, str(path)
                    if operation in ('keep', 'withdraw'):
                        assert plan['text'] is None, str(path)
                    else:
                        assert isinstance(plan['text'], str) and plan['text'].strip(), str(path)
                    counts[operation] += 1
                    candidates += 1
                    records.append({'request':str(path.relative_to(root)),
                                    'operation':operation,
                                    'explicit_text':True,
                                    'text_is_null':plan['text'] is None,
                                    'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
        assert candidates == summary['wire']['roles']['reviewer']['upstream_attempts'], attempt['id']
    return {'status':'pass', 'attempts':len(schedule),
            'reviewer_operation_counts':dict(counts), 'reviewer_wire_candidates':len(records),
            'player_round_operation_counts':dict(player_round_counts),
            'player_rounds':round_records,
            'limits':['Observed operations only: absent withdraw events do not establish live withdraw coverage.',
                      'Role identity, instructions, schemas, exact candidate/input binding and empty tools are separately checked by each immutable attempt summary and deterministic decision checks.'],
            'requests':records}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(audit(args.candidate.resolve()), indent=2))
