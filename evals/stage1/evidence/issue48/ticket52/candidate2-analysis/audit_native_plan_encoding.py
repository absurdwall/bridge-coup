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
        if (directory/'summary.json').exists():
            summary = json.loads((directory/'summary.json').read_text())
            assert summary['wire']['protocol_status']=='pass',attempt['id']
            wire=summary['wire']
        else:
            assert attempt['id']=='short-5-r1'
            assert not (directory/'playing-outcome.json').exists()
            cost=json.loads((root.with_name('candidate2-analysis')/'originals/interruption/interrupted-cost-observations.json').read_text())
            wire=cost['wire_observations']
        candidates = 0
        roles = {row['wire_request']:row['role'] for row in wire['role_requests']}
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
        assert candidates == wire['roles']['reviewer']['upstream_attempts'], attempt['id']
    return {'status':'encoding_observations_pass', 'scheduled_slots':len(schedule),
            'normal_completed_attempts':21,'interrupted_partial_attempts':1,
            'whole_protocol_pass':False,
            'reviewer_operation_counts':dict(counts), 'reviewer_wire_candidates':len(records),
            'player_round_operation_counts':dict(player_round_counts),
            'player_rounds':round_records,
            'limits':['Observed operations only: absent withdraw events do not establish live withdraw coverage.',
                      'Normal21 role/candidate bindings are separately checked by immutable summaries and deterministic decision checks. Interrupted request10/11 binding gaps remain unresolved; no whole-protocol pass is claimed.',
                      'Reviewer wire observations include interrupted rejected/pending proposals; saved player rounds describe persisted delivered-decision histories. These are encoding/cost observations, never extra delivered quality grades.'],
            'requests':records}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(audit(args.candidate.resolve()), indent=2))
