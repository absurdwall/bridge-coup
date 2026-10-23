"""Recheck saved native first-decision evidence without model calls."""
from pathlib import Path
import hashlib, json
OUT = Path(__file__).resolve().parent/'native-smoke'
def load(p): return json.loads(p.read_text())
def text(request, role): return '\n'.join(part.get('text','') for item in request['input'] if item.get('role')==role for part in item.get('content',[]))
decision=load(OUT/'play/decision.json'); trace=load(OUT/'play/trace.json'); manifest=load(OUT/'manifest.json')
for path,digest in manifest['sourceHashes'].items(): assert hashlib.sha256((OUT/'source'/path).read_bytes()).hexdigest()==digest
roles=[]
for index,role in enumerate(['player','reviewer']):
 request=load(OUT/f'wire/request-{index}.json'); metadata=load(OUT/f'wire/response-metadata-{index}.json')
 expected=decision if role=='player' else decision['review']
 assert request['model']==metadata['model']=='gpt-6.1-sol' and request['reasoning']['effort']=='medium'
 assert metadata['httpStatus']==200 and metadata['status']=='completed'
 assert [item['tools'] for item in request['input'] if item['type']=='additional_tools']==[[]]
 assert text(request,'developer')==expected['instructions']
 assert text(request,'user')==expected['input']
 assert expected['identity']['requestedModel']==expected['identity']['observedModel']=='gpt-6.1-sol'
 assert expected['identity']['requestedEffort']==expected['identity']['observedEffort']=='medium'
 roles.append({'role':role,'identity':expected['identity'],'usage':metadata['usage'],'tools':[]})
player=load(OUT/'wire/request-0.json');reviewer=load(OUT/'wire/request-1.json')
assert player['text']['format']['schema']['properties']['selectedCard']['enum']==['D8','D6','D5','D3']
review=json.loads(decision['review']['input']); candidate=json.loads(decision['rawOutput'])
assert review['candidate']==candidate and review['latestSnapshot']==json.loads(decision['input'])
assert set(review['latestSnapshot']['hands'])=={'N','S'}
assert review['proposedEffectivePlan']==candidate['plan']['text']==decision['effectivePlan']
assert decision['review']['pendingDecisionID']==decision['pending']['id']==decision['session']['id']
assert decision['review']['candidateID']==decision['pending']['candidateID']
assert decision['review']['result']['verdict']=='approve'
assert len(trace['steps'])==1 and len(trace['steps'][0]['actualEvents'])==2
assert trace['steps'][0]['execution']['event']['card']==candidate['selectedCard']=='D3'
assert roles[0]['identity']['threadID']!=roles[1]['identity']['threadID']
summary={'status':'runtime-integration-pass','qualityAcceptance':'not-run','requests':2,'roles':roles,'appliedCard':'D3','deliveredPlan':decision['effectivePlan'],'elapsedSeconds':decision['elapsedSeconds'],'sourceNote':'Exact probe sources under native-smoke/source; subsequent atomic-publication and cancelled-session hardening is separately diffed and covered by offline tests.'}
(OUT/'audit.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False)+'\n')
print('Native first-decision protocol audit passed; no quality-acceptance claim.')
