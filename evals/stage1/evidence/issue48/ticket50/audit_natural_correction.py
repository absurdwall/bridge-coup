"""Audit saved production correction evidence without model calls."""
from pathlib import Path
import hashlib,json,copy
OUT=Path(__file__).resolve().parent/'native-correction'
def load(p): return json.loads(p.read_text())
def text(request,role):
 messages=['\n'.join(part.get('text','') for part in item.get('content',[])) for item in request['input'] if item.get('role')==role and item.get('content')]
 return messages[-1] if messages else ''
manifest=load(OUT/'manifest.json');process=load(OUT/'process.json');trace=load(OUT/'play/trace.json')
assert process['returncode']==0
for path,digest in manifest['sourceHashes'].items(): assert hashlib.sha256((OUT/'source'/path).read_bytes()).hexdigest()==digest
wire={int(p.stem.split('-')[1]):load(p) for p in (OUT/'wire').glob('request-*.json')}
used=set();roles=[];playerThreads=set();corrected=[];proposals=0;gaps=[]
def candidate(value):
 # Diagnose the saved pre-repair null omission without rewriting raw evidence.
 normalized=copy.deepcopy(value)
 if normalized['plan']['update'] in ('keep','withdraw'):
  normalized['plan'].setdefault('text',None)
 return normalized
records=[load(p) for p in sorted((OUT/'play').glob('decision-*/decision.json'))]
for delivered,record in enumerate(records,1):
 canonical=json.loads(record['canonicalInput']);rounds=record['reviewRounds'];assert 1<=len(rounds)<=5
 assert set(canonical['hands'])=={'N','S'}
 for index,r in enumerate(rounds):
  assert r['number']==index+1 and r['pending']['id']==record['session']['id']
  assert json.loads(r['review']['input'])['latestSnapshot']==canonical
  rawCandidate=json.loads(r['playerRawOutput']);reviewed=json.loads(r['review']['input'])['candidate']
  assert rawCandidate==candidate(r['pending']['candidate'])==candidate(reviewed)
  if rawCandidate!=reviewed:
   gaps.append({'decision':delivered,'round':index+1,'gap':'PlanChange.text null omitted from encoded candidate; raw player JSON preserved.','repairedAfterCapture':True})
  assert r['pending']['candidateID']==r['review']['candidateID']
  if index==0: assert r['playerInput']==record['canonicalInput']
  else:
   feedback=json.loads(r['playerInput']);previous=rounds[index-1]
   assert feedback['latestSnapshot']==canonical and feedback['rawReview']==previous['review']['rawOutput']
   assert feedback['rawCandidate']==previous['playerRawOutput']
   assert feedback['candidate']==previous['pending']['candidate'] and feedback['review']==previous['review']['result']
   assert feedback['type']==('clarification' if previous['review']['result']['verdict']=='uncertain' else 'revision')
  for role,expectedInput,instructions,identity,elapsed in [
    ('player',r['playerInput'],record['instructions'],r['playerIdentity'],r['playerElapsedSeconds']),
    ('reviewer',r['review']['input'],r['review']['instructions'],r['review']['identity'],r['review']['elapsedSeconds'])]:
   matches=[i for i,q in wire.items() if text(q,'user')==expectedInput and text(q,'developer')==instructions and i not in used]
   assert len(matches)==1,(role,delivered,index,matches)
   i=matches[0];used.add(i);request=wire[i];metadata=load(OUT/f'wire/response-metadata-{i}.json')
   assert request['model']==metadata['model']=='gpt-6.1-sol' and request['reasoning']['effort']=='medium'
   assert [item['tools'] for item in request['input'] if item['type']=='additional_tools']==[[]]
   assert metadata['httpStatus']==200 and metadata['status']=='completed'
   assert identity['requestedModel']==identity['observedModel']=='gpt-6.1-sol'
   assert identity['requestedEffort']==identity['observedEffort']=='medium'
   roles.append({'decision':delivered,'round':index+1,'role':role,'wireRequest':i,'identity':identity,'usage':metadata['usage'],'elapsedSeconds':elapsed})
  assert r['playerIdentity']['threadID']!=r['review']['identity']['threadID']
  playerThreads.add(r['playerIdentity']['threadID']);proposals+=1
 assert record['input']==rounds[-1]['playerInput'] and record['rawOutput']==rounds[-1]['playerRawOutput']
 assert record['pending']==rounds[-1]['pending']
 verdicts=[r['review']['result']['verdict'] for r in rounds]
 assert record['executionDisposition']==('reviewApproved' if verdicts[-1]=='approve' else 'contested')
 if 'revise' in verdicts[:-1] and verdicts[-1]=='approve': corrected.append(delivered)
 step=next(s for s in trace['steps'] if s.get('decision',{}).get('session',{}).get('id')==record['session']['id'])
 assert step['execution']['event']['card']==record['advice']['selectedCard']
 assert len(step['actualEvents'])==len(record['snapshot']['events'])+1
assert len(playerThreads)==1 and len(used)==len(wire)==proposals*2
assert trace['modelActions']==len(records)<=12
assert bool(corrected)==process['naturalCorrectionObserved']
if corrected: assert corrected==[len(records)],'Stop immediately after first natural correction'
summary={'status':'natural-correction-observed-with-null-encoding-gap' if corrected and gaps else 'natural-correction-protocol-pass' if corrected else 'natural-correction-not-observed','capturedContractGaps':gaps,'qualityAcceptance':'not-run','naturalCorrectionDecisions':corrected,'deliveredDecisions':len(records),'playerProposals':proposals,'reviewerJudgments':proposals,'wireRequests':len(wire),'playerThread':next(iter(playerThreads)),'boardComplete':trace['complete'],'elapsedSeconds':trace['elapsedSeconds'],'roles':roles}
(OUT/'audit.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False)+'\n')
print(summary['status'])
