#!/usr/bin/env python3
"""Verify interrupted native RPC/usage observations without current source/native."""
import argparse
import hashlib
import json
from pathlib import Path

HERE=Path(__file__).resolve().parent

def verify(repo, analysis):
    candidate=repo/'evals/stage1/evidence/issue48/ticket52/candidate2'
    attempt=candidate/'short-5-r1'
    cost=json.loads((analysis/'originals/interruption/interrupted-cost-observations.json').read_text())
    actual=[];usage={'player':[],'reviewer':[]};completions={'player':0,'reviewer':0}
    files=[('player',attempt/'play/rpc.jsonl')]+[('reviewer',p) for p in sorted((attempt/'play/reviewer').glob('*/rpc.jsonl'))]
    for role,path in files:
        for index,line in enumerate(path.read_text().splitlines()):
            row=json.loads(line);value=row.get('value',{})
            if row.get('kind')=='request' and value.get('method')=='turn/start':
                actual.append({'role':role,'rpc_file':str(path.relative_to(attempt)),'line':index+1,
                    'thread_id':value.get('params',{}).get('threadId'),
                    'row_sha256':hashlib.sha256(line.encode()).hexdigest()})
            if row.get('kind')=='tokenUsage':
                usage[role].append({'rpc_file':str(path.relative_to(attempt)),
                    'thread_id':value.get('threadId'),'turn_id':value.get('turnId'),
                    'observed_last':value['tokenUsage']['last']})
            if row.get('kind')=='completion':completions[role]+=1
    assert actual==cost['rpc_starts']
    for role in usage:
        saved=cost['native_rpc_cost_observations'][role]
        assert usage[role]==saved['usage_records']
        assert sum(r['role']==role for r in actual)==saved['observed_rpc_turn_starts']
        assert completions[role]==saved['completion_observations']
        assert saved['usage_unknown_turns']==saved['observed_rpc_turn_starts']-len(usage[role])
        totals={}
        for row in usage[role]:
            for key,value in row['observed_last'].items():totals[key]=totals.get(key,0)+value
        assert totals==saved['observed_token_totals']
    wire=cost['wire_observations'];requests=list((attempt/'wire').glob('request-*.json'))
    assert len(requests)==wire['upstream_request_attempts']==12
    assert len(wire['role_requests'])==len(requests)
    assert len(actual)==13 and cost['observable_rpc_turn_starts']=={'player':6,'reviewer':7}
    assert wire['roles']['player']['upstream_attempts']==6 and wire['roles']['reviewer']['upstream_attempts']==6
    assert wire['roles']['reviewer']['usage_unknown_attempts']==1
    assert not (attempt/'summary.json').exists() and not (attempt/'playing-outcome.json').exists()
    return {'status':'pass','native_rpc_starts':13,'native_player':6,'native_reviewer':7,
            'native_reviewer_unknown_usage':2,'captured_http_attempts':12,'http_unknown_usage':1,
            'task_complete':False,'actual_interrupted_process_exit':None,
            'limits':['Native and HTTP observations overlap; do not add them.',
                      'Uncommitted final RPC/HTTP journal associations remain unresolved.',
                      'Pending outputs are cost evidence only; quality targets remain three executed finals.',
                      'Captured HTTP usage values are preserved frozen-audit observations bound by raw/external manifests.']}

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--repo',required=True,type=Path)
    parser.add_argument('--analysis',type=Path,default=HERE);args=parser.parse_args()
    print(json.dumps(verify(args.repo.resolve(),args.analysis.resolve()),indent=2))
