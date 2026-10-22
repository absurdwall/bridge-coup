import collections,hashlib,json
from pathlib import Path
ROOT=Path(__file__).parent
ORIGINAL=Path('/Users/tingranwang/.codex/worktrees/issue46-integration/bridge-coup/evals/stage1/evidence/issue46-completion/development-v4/short-6-r1/wire')

def normalize_item(item):
    d={k:v for k,v in item.items() if k!='id'}
    # The installed injection endpoint explicitly serializes absent optional reasoning content as null.
    if d.get('type')=='reasoning' and d.get('content') is None:d.pop('content',None)
    return d

rows=[]
for a in json.loads((ROOT/'memory-rule-study/results.json').read_text())['attempts']:
 directory=ROOT/'memory-rule-study/runs'/a['id']
 files=list((directory/'wire').glob('request-*.json'))
 row={'id':a['id'],'HTTP_requests':len(files)}
 assert len(files)==1,(a['id'],len(files))
 actual=json.loads(files[0].read_text());original=json.loads((ORIGINAL/f"request-{a['decision']-1}.json").read_text())
 expected=json.loads(json.dumps(original['input']))
 candidate=json.loads((ROOT/'requests/club-memory-rule.json').read_text())['instructions']
 if a['variant']=='memory-rule':
  developer=[x for x in expected if x.get('role')=='developer' and x['type']=='message']
  assert len(developer)==1
  assert developer[0]['content'][0]['type']=='input_text'
  original_text=developer[0]['content'][0]['text']
  insertion='   Treat prior assistant responses and reasoning as fallible hypotheses.\n   Derive current facts anew from the latest snapshot before using or\n   retaining any earlier conclusion.\n\n'
  assert candidate.replace(insertion,'',1)==original_text
  developer[0]['content'][0]['text']=candidate

 if a['history']=='public':expected=[x for x in expected if x['type']!='reasoning']
 elif a['history']=='fresh':expected=[x for x in expected if x['type']=='additional_tools' or x.get('role')=='developer']+[expected[-1]]
 row['input_matches_expected_except_ids_and_absent_reasoning_content']=([normalize_item(x) for x in actual['input']]==[normalize_item(x) for x in expected])
 row['current_input_exact']=actual['input'][-1]['content']==original['input'][-1]['content']
 row['fixed_parameters_equal']={k:actual[k]==original[k] for k in ['model','reasoning','text','tool_choice','parallel_tool_calls','store','stream','include']}
 row['schema_root_order']=list(actual['text']['format']['schema']['properties'])
 row['tool_arrays']=[x['tools'] for x in actual['input'] if x['type']=='additional_tools']
 row['reasoning_items']=sum(x['type']=='reasoning' for x in actual['input'])
 row['encrypted_reasoning_sha256']=[hashlib.sha256(x['encrypted_content'].encode()).hexdigest() for x in actual['input'] if x['type']=='reasoning']
 row['HTTP_statuses']=[json.loads(p.read_text()).get('httpStatus') for p in (directory/'wire').glob('response-metadata-*.json')]
 rows.append(row)
 assert row['input_matches_expected_except_ids_and_absent_reasoning_content'],row
 assert row['current_input_exact'] and all(row['fixed_parameters_equal'].values()),row
 assert row['tool_arrays']==[[]]
 assert row['schema_root_order']==['plan','selectedCard','publicReason']
(ROOT/'memory-rule-study/wire-audit.json').write_text(json.dumps({'normalization':'Remove item IDs and treat absent/null reasoning.content equivalently; all public text, item order, opaque encrypted_content and other fields are compared exactly. Client/routing/cache IDs vary by new thread.','attempts':rows},indent=2)+'\n')
print('Audited',len(rows),'single-request probes: all expected input histories and fixed parameters match.')
