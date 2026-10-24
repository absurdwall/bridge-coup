import json
from pathlib import Path
ROOT=Path(__file__).parent
rows=[]
for a in json.loads((ROOT/'PLAN.json').read_text())['schedule']:
 d=ROOT/'runs'/a['id']; paths=list((d/'wire').glob('request-*.json')); assert len(paths)==1
 w=json.loads(paths[0].read_text()); r=json.loads((ROOT/a['request']).read_text())
 messages=[x for x in w['input'] if x['type']=='message']
 assert len(messages)==2 and [x['role'] for x in messages]==['developer','user']
 assert messages[0]['content']==[{'type':'input_text','text':r['instructions']}]
 assert messages[1]['content']==[{'type':'input_text','text':r['input']}]
 assert w['text']['format']['schema']==json.loads(r['outputSchema'])
 assert w['model']=='gpt-6-luna' and w['reasoning']=={'effort':'medium','context':'all_turns'}
 assert [x['tools'] for x in w['input'] if x['type']=='additional_tools']==[[]]
 assert len(w['input'])==3
 meta=json.loads((d/'wire/response-metadata-0.json').read_text());assert meta['httpStatus']==200
 rows.append({'id':a['id'],'single_request':True,'instructions_and_current_input_exact':True,'schema_matches':True,'model':'gpt-6-luna','reasoning':w['reasoning'],'tools':[],'httpStatus':200})
(ROOT/'wire-audit.json').write_text(json.dumps({'attempts':rows},indent=2)+'\n')
print('Audited',len(rows),'fresh requests against frozen variants.')
