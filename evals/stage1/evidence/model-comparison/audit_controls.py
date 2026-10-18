"""Read-only matched-control audit; never calls a model or changes captures."""
from pathlib import Path
import hashlib,json,statistics,sys
ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT/'evals/stage1'));import acceptance
OUT=Path(__file__).resolve().parent
runs=[('medium-baseline','gpt-6-luna','medium',ROOT/'evals/stage1/evidence/reason-order-repair/live-candidate/development-normal'),
 ('high-control','gpt-6-luna','high',ROOT/'evals/stage1/evidence/high-effort-diagnostic/high-continuity-1')]+[(name,model,effort,OUT/name/'continuous-1') for name,model,effort in [('luna-max','gpt-6-luna','max'),('sol-medium','gpt-6.1-sol','medium'),('astra-medium','gpt-6-astra','medium')]]
result=[]
for label,model,effort,run in runs:
 summary=json.loads((run/'summary.json').read_text());trace=json.loads((run/'play/trace.json').read_text())
 records=[json.loads(f.read_text()) for f in sorted((run/'play').glob('decision-*/decision.json'))]
 assert len(records)==8
 calls=[json.loads(line) for line in (run/'play/rpc.jsonl').read_text().splitlines()]
 turns=[r['value']['params'] for r in calls if r['kind']=='request' and r['value'].get('method')=='turn/start'];assert len(turns)==8
 ack=next(r['value'] for r in calls if r['kind']=='catalogAcknowledgement')
 assert ack['model']==model and any(v['reasoningEffort']==effort for v in ack['supportedReasoningEfforts'])
 wire=sorted((run/'wire').glob('request-*.json'),key=lambda p:int(p.stem.split('-')[-1]));assert len(wire)==8
 row={'id':label,'model':model,'effort':effort,'directory':str(run),'catalog_acknowledgement':ack,'raw_quality':summary['quality_counts'],'raw_outcome':summary['outcome'],'counts':summary['counts'],'timing':summary['timing'],'requests':[]}
 for i,(record,file,turn) in enumerate(zip(records,wire,turns)):
  w=json.loads(file.read_text());m=json.loads((run/'wire'/f'response-metadata-{i}.json').read_text())
  assert w['model']==model and w['reasoning']['effort']==effort
  assert m['httpStatus']==200 and m['model']==model and m['status']=='completed'
  assert record['identity']['requestedModel']==model and record['identity']['requestedEffort']==effort
  assert turn['model']==model and turn['effort']==effort
  latest=[v for v in w['input'] if v.get('role')=='user'][-1]
  assert latest['content'][0]['text']==record['input']==turn['input'][0]['text']
  texts=[c.get('text','') for v in w['input'] if v.get('role')=='developer' for c in v.get('content',[])];assert record['instructions'] in texts
  assert list(w['text']['format']['schema']['properties'])==['publicReason','plan','selectedCard']
  assert set(w['text']['format']['schema']['properties']['selectedCard']['enum'])==set(record['snapshot']['legalCards'])
  tools=w.get('tools') or next(v['tools'] for v in w['input'] if v['type']=='additional_tools')
  assert all(t.get('name')!='collaboration' for t in tools)
  assert not any('<multi_agent_role>' in t or '<multi_agent_mode>' in t for t in texts)
  for prior in records[:i]:
   assistant_texts=[c.get('text','') for v in w['input'] if v.get('role')=='assistant' for c in v.get('content',[])];assert prior['rawOutput'] in assistant_texts
  # Public, independently recomputed current winner; no hidden reasoning inspection.
  snapshot=record['snapshot'];trick=snapshot['currentTrick'];rank='23456789TJQKA';suits={'spades':'S','hearts':'H','diamonds':'D','clubs':'C'};trump=suits.get(snapshot['contract']['strain']);led=trick[0]['card'][0] if trick else None
  winner=max(trick,key=lambda event:(200 if event['card'][0]==trump else 100 if event['card'][0]==led else 0)+rank.index(event['card'][1])) if trick else None
  assert snapshot.get('currentWinningPlay')==winner
  row['requests'].append({'ordinal':i+1,'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'schema_order':list(w['text']['format']['schema']['properties']),'catalog_sha256':hashlib.sha256(json.dumps(tools,sort_keys=True).encode()).hexdigest(),'tool_namespaces':{n['name']:[t['name'] for t in n.get('tools',[])] for n in tools},'model_observed':m['model'],'reasoning_tokens':m['usage'].get('output_tokens_details',{}).get('reasoning_tokens'),'input_tokens':m['usage']['input_tokens'],'output_tokens':m['usage']['output_tokens'],'latency_seconds':record['elapsedSeconds']})
 row['reasoning_tokens_total']=sum(r['reasoning_tokens'] or 0 for r in row['requests'])
 row['initial_instructions_sha256']=hashlib.sha256(records[0]['instructions'].encode()).hexdigest();row['initial_input_sha256']=hashlib.sha256(records[0]['input'].encode()).hexdigest();row['initial_schema_sha256']=hashlib.sha256(json.dumps(json.loads(wire[0].read_text())['text']['format']['schema'],sort_keys=True).encode()).hexdigest()
 result.append(row)
assert len({r['initial_instructions_sha256'] for r in result})==1
assert len({r['initial_input_sha256'] for r in result})==1
assert len({r['initial_schema_sha256'] for r in result})==1
(OUT/'matched-audit.json').write_text(json.dumps({'status':'pass','same_initial_public_task_instructions_schema':True,'later_positions':'Endogenously differ with actual choices; never forced to replay a reference line.','all40requests_exact_model_effort_legal_schema_context_and_observed_response':True,'rows':result},ensure_ascii=False,indent=2)+'\n')
for r in result:print(r['id'],r['raw_quality'],round(r['timing']['elapsedSeconds'],3),'seconds',r['reasoning_tokens_total'],'reasoning tokens','catalogs',len({x['catalog_sha256'] for x in r['requests']}))
