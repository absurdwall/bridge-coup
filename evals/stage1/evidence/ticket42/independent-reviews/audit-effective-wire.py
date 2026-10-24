import json,sys,hashlib,re
from pathlib import Path
root=Path(sys.argv[1]);sys.path.insert(0,str(root/'evals/stage1'));import corpus
matrix=root/'evals/stage1/evidence/ticket42/matrix';manifest=corpus.load(root/'evals/stage1/corpus/manifest.json');cases={c['id']:c for c in manifest['cases']};candidate=corpus.load(matrix/'candidate.json');results=[]
for summary in sorted(matrix.glob('*/summary.json')):
 directory=summary.parent;row=corpus.load(summary);case=cases[row['case_id']];board=corpus.load(root/'evals/stage1/corpus'/case['board']);play=directory/'play';rpc=[json.loads(l) for l in (play/'rpc.jsonl').read_text().splitlines()] if (play/'rpc.jsonl').exists() else [];turns=[r['value']['params'] for r in rpc if r['kind']=='request' and r['value'].get('method')=='turn/start'];completions=[i['text'] for r in rpc if r['kind']=='completion' for i in r['value'].get('items',[]) if i.get('type')=='agentMessage'];texts=[t['input'][0]['text'] for t in turns];trace=corpus.load(play/'trace.json') if (play/'trace.json').exists() else {};records=[s['decision'] for s in trace.get('steps',[]) if s.get('decision')];by_input={r['input']:r for r in records};errors=[];opaque=0;history_types=set();payloads=[]
 for path in sorted((directory/'wire').glob('request-*.json'),key=lambda p:int(p.stem.split('-')[-1])):
  wire=corpus.load(path);messages=[i for i in wire.get('input',[]) if i.get('type')=='message'];users=[''.join(c.get('text','') for c in m.get('content',[])) for m in messages if m.get('role')=='user'];assistants=[''.join(c.get('text','') for c in m.get('content',[])) for m in messages if m.get('role')=='assistant'];developer=[''.join(c.get('text','') for c in m.get('content',[])) for m in messages if m.get('role')=='developer'];last=users[-1] if users else '';index=texts.index(last) if last in texts else None
  if index is None:errors.append(path.name+': latest user input does not match actual RPC')
  else:
   if users!=texts[:index+1]:errors.append(path.name+': actual user history differs')
   if assistants!=completions[:index]:errors.append(path.name+': actual public assistant history differs')
   schema=wire.get('text',{}).get('format',{}).get('schema')
   if schema!=turns[index]['outputSchema']:errors.append(path.name+': schema differs from actual RPC')
   if list(schema['properties'])!=['plan','publicReason','selectedCard']:errors.append(path.name+': output order changed')
   record=by_input.get(last);events=record['snapshot']['events'] if record else (trace.get('steps') or [{}])[-1].get('actualEvents',trace.get('initialEvents',[]));state=corpus.replay(board,events);hand=state['hands'][state['actingSeat']];led=state['currentTrick'][0]['card'][0] if state['currentTrick'] else None;legal={c for c in hand if c[0]==led} if led else hand;legal=legal or hand;choices=schema['properties']['selectedCard']['enum']
   if set(choices)!=legal or len(choices)!=len(legal):errors.append(path.name+': enum differs from complete legal choices')
  if candidate['english_instructions'] not in developer:errors.append(path.name+': concise English instructions absent')
  if wire.get('model')!='gpt-6-luna' or wire.get('reasoning',{}).get('effort')!='medium':errors.append(path.name+': requested model/effort mismatch')
  if any(re.search('[\u4e00-\u9fff]',s) for s in users+assistants):errors.append(path.name+': non-English CJK text in public conversation')
  for item in wire.get('input',[]):
   kind=item.get('type','unknown');history_types.add(kind)
   if kind=='reasoning' and item.get('encrypted_content'):opaque+=1
   if 'call' in kind:errors.append(path.name+': tool-call history item '+kind)
  payloads.append({'file':path.name,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'rpc_index':index})
 results.append({'attempt':row['id'],'status':'fail' if errors else 'pass','errors':errors,'rpc_requests':len(turns),'captured_http_attempts':len(payloads),'input_item_types':sorted(history_types),'opaque_encrypted_reasoning_items_across_cumulative_payloads':opaque,'scope':'Exact actual RPC schema/input/history, complete independent legal enum, concise instructions and requested identity. No tool invocation history observed if pass; inherited catalog and opaque reasoning remain. Not an assertion of internal resolved identity.','payloads':payloads})
(matrix/'effective-wire-audit.json').write_text(json.dumps({'attempts_audited':len(results),'results':results},indent=2)+'\n');print([(r['attempt'],r['status'],r['errors']) for r in results])
