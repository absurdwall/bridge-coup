from pathlib import Path
import collections,hashlib,json
ROOT=Path(__file__).parent
manifest=json.loads((ROOT/'ARCHIVE-MANIFEST.json').read_text())
for f in manifest['files']:
 p=ROOT/f['archived_relative_path'];assert p.is_file()
 assert hashlib.sha256(p.read_bytes()).hexdigest()==f['sha256'],f['original_relative_path']
requests=sorted(ROOT.glob('**/wire/request-*.json'))
assert len(requests)==42,len(requests)
counts=collections.Counter();identities=set();seeded=0;fresh=0
for p in requests:
 w=json.loads(p.read_text());meta=json.loads(p.with_name(p.name.replace('request-','response-metadata-')).read_text())
 assert w['model']=='gpt-6-luna' and w['reasoning']=={'effort':'medium','context':'all_turns'}
 assert [x['tools'] for x in w['input'] if x['type']=='additional_tools']==[[]]
 assert meta['httpStatus']==200 and meta['status']=='completed'
 d=p.parent.parent;raw=json.loads((d/'runtime/raw-output.txt').read_text());identity=json.loads((d/'runtime/identity.json').read_text())
 identities.add(identity['threadID']);assert identity['requestedEffort']=='medium'
 assert (d/'runtime/rpc.jsonl').is_file()
 if (d/'injection-ack.json').exists():
  assert json.loads((d/'injection-ack.json').read_text())['accepted'];seeded+=1
 else:fresh+=1
 counts[p.relative_to(ROOT).parts[0]]+=1
assert (seeded,fresh)==(20,22)
assert len(identities)==42
report={'requests':42,'seeded':seeded,'fresh':fresh,'distinct_diagnostic_threads':len(identities),'http200_completed':42,'luna_medium_empty_tools':42,'all_archived_source_hashes_verified':True,'manifest_records':len(manifest['files']),'batches':dict(counts),'scope':'Archive validation only; no model call, production fix or acceptance claim.'}
(ROOT/'archive-validation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
