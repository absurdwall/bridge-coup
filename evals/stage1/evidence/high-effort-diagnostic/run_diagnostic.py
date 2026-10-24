"""One Luna/high continuous8 diagnostic; accepted production target stays medium.

Builds the same six public production modules/driver from frozen352d61f in an
isolated temporary package. Only the transport's requested/configured effort
constants differ; original and patched hashes/diff are recorded before calls.
No model-output repair, hidden inputs, alternative reasoner or acceptance credit.
"""
import difflib,hashlib,json,os,subprocess,sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
COMMIT='352d61f'
sys.path.insert(0,str(ROOT/'evals/stage1'))
import acceptance
source=Path(tempfile.mkdtemp(prefix='bridge-luna-high-source-'))
modules=['BridgeDomain','BridgeEngine','BridgeExpert','BridgeCodex','BridgeDriver','BridgePlayCLI']
files=subprocess.check_output(['git','ls-tree','-r','--name-only',COMMIT,'--']+['Sources/'+m for m in modules],cwd=ROOT,text=True).splitlines()
manifest='''// swift-tools-version: 5.10
import PackageDescription
let package = Package(name: "BridgeTeacher", platforms: [.macOS(.v14)], products: [.executable(name: "bridge-play", targets: ["BridgePlayCLI"])], targets: [
.target(name: "BridgeDomain"),
.target(name: "BridgeEngine", dependencies: ["BridgeDomain"]),
.target(name: "BridgeExpert", dependencies: ["BridgeDomain"]),
.target(name: "BridgeCodex", dependencies: ["BridgeExpert", "BridgeDomain"]),
.target(name: "BridgeDriver", dependencies: ["BridgeExpert", "BridgeEngine", "BridgeDomain"]),
.executableTarget(name: "BridgePlayCLI", dependencies: ["BridgeCodex", "BridgeDriver", "BridgeExpert", "BridgeEngine", "BridgeDomain"])
])
'''
(source/'Package.swift').write_text(manifest)
(OUT/'diagnostic-Package.swift.txt').write_text(manifest)
provenance=[];delta=[]
for name in files:
 data=subprocess.check_output(['git','show',COMMIT+':'+name],cwd=ROOT)
 original=data.decode();changed=original
 if name=='Sources/BridgeCodex/CodexTransport.swift':
  assert changed.count('private static let effort = "medium"')==1
  assert changed.count('model_reasoning_effort = "medium"')==1
  changed=changed.replace('private static let effort = "medium"','private static let effort = "high"').replace('model_reasoning_effort = "medium"','model_reasoning_effort = "high"')
  delta=list(difflib.unified_diff(original.splitlines(keepends=True),changed.splitlines(keepends=True),fromfile=COMMIT+'/'+name,tofile='diagnostic-high/'+name))
 path=source/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_text(changed)
 provenance.append({'path':name,'original_sha256':hashlib.sha256(data).hexdigest(),'diagnostic_sha256':hashlib.sha256(changed.encode()).hexdigest(),'unchanged':original==changed})
(OUT/'source-effort-only.patch').write_text(''.join(delta))
assert sum(not r['unchanged'] for r in provenance)==1
acceptance.write(OUT/'predeclared.json',{'diagnostic_only':True,'base_commit':COMMIT,'production_target':'gpt-6-luna/medium','diagnostic_target':'gpt-6-luna/high','samples':1,'decisions':8,'source_path':str(source),'public_modules':provenance,'package_note':'Only same six public modules/driver; omit unrelated UI/test targets, same macOS14/Swift5.10 settings.','source_delta':'Two effort literals only. No production files modified. No result counts toward acceptance.'})
env=dict(os.environ);env.pop('SDKROOT',None)
with (OUT/'build.log').open('w') as log:
 subprocess.run(['swift','build','--package-path',str(source),'--product','bridge-play'],cwd=ROOT,env=env,stdout=log,stderr=log,check=True,timeout=180)
candidate=acceptance.load(ROOT/'evals/stage1/evidence/reason-order-repair/live-candidate/candidate.json')
candidate.update(binary=str(source/'.build/debug/bridge-play'),binary_sha256=hashlib.sha256((source/'.build/debug/bridge-play').read_bytes()).hexdigest(),requested_play_effort='high',diagnostic_only=True,source_override='See predeclared.json/source-effort-only.patch. Source is not unmodified production commit; effort-only diagnostic.')
acceptance.write(OUT/'candidate.json',candidate)
attempt={'id':'high-continuity-1','case_id':'short-2','kind':'short','board':'boards/synthetic.json','decisions':8,'opponent_policy':'conserve-high','diagnostic_only':True,'requested_effort':'high'}
result=acceptance.run_attempt(candidate,attempt,OUT)
acceptance.write(OUT/'summary.json',result)
print(json.dumps({k:result[k] for k in ['outcome','quality_counts','counts','timing']},indent=2))
