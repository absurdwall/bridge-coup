"""Archive already-frozen C3 before any calls; no native execution."""
from pathlib import Path
import datetime,gzip,hashlib,io,json,shutil,subprocess,tarfile,os
repo=Path('/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup')
root=repo/'evals/stage1/evidence/issue48/ticket52/candidate3';analysis=root.with_name('candidate3-analysis');runtime=analysis/'runtime'
runtime.mkdir(parents=True,exist_ok=False)
candidate=json.loads((root/'candidate.json').read_text())
assert candidate['source_commit']=='3f0fc65470633dd90363ad0417b29a9f7f68be18'
cycle={'cycle':3,'maximumCycles':3,'authorization':'Root explicitly authorized final reviewed integration3f0fc654 build/freeze/archive after clear Standards/Spec/WFA and merger validation; model execution awaits independent archive validation and separate launch authorization.','source_commit':candidate['source_commit'],'scope':'Last substantive frozen candidate. Exactly22 strict sequential original-pipeline attempts with unchanged case-execution-v1/bounds/material/rubric/models and no tools. No probes/rerolls/source changes/feedback or resumption.','prior_cycles':'Candidate1 immutable NO-GO; candidate2 immutable interrupted NO-GO. Neither interruption nor supplemental diagnosis refunds the budget.'}
with (root/'cycle.json').open('x') as f:json.dump(cycle,f,indent=2)
sha=lambda data:hashlib.sha256(data).hexdigest()
def archive(path,members):
 with path.open('xb') as raw:
  with gzip.GzipFile(filename='',fileobj=raw,mode='wb',mtime=0) as zipped:
   with tarfile.open(fileobj=zipped,mode='w') as tar:
    for name,data in sorted(members.items()):
     info=tarfile.TarInfo(name);info.size=len(data);info.mtime=0;info.uid=info.gid=0;info.uname=info.gname='';info.mode=0o755 if name=='bridge-play' else 0o644
     tar.addfile(info,io.BytesIO(data))
 return {'sha256':sha(path.read_bytes()),'bytes':path.stat().st_size}
blobs={name:subprocess.check_output(['git','show',candidate['source_commit']+':'+name],cwd=repo) for name in candidate['source_hashes']}
assert {name:sha(data) for name,data in blobs.items()}==candidate['source_hashes']
source_meta={'source_commit':candidate['source_commit'],**archive(runtime/'candidate3-source.tar.gz',blobs),'members':candidate['source_hashes']}
(runtime/'candidate3-source-archive.json').write_text(json.dumps(source_meta,indent=2)+'\n')
binary=Path(candidate['binary']);bundle=binary.parent/'BridgeTeacher_BridgeExpert.bundle'
preserved=Path('/tmp/bridge-coup-issue48-context/frozen-binaries')/candidate['binary_sha256'];preserved.mkdir(parents=True,exist_ok=False)
shutil.copy2(binary,preserved/'bridge-play');shutil.copytree(bundle,preserved/bundle.name)
member_bytes={'bridge-play':(preserved/'bridge-play').read_bytes()}
member_bytes.update({bundle.name+'/'+str(p.relative_to(preserved/bundle.name)):p.read_bytes() for p in (preserved/bundle.name).rglob('*') if p.is_file()})
assert sha(member_bytes['bridge-play'])==candidate['binary_sha256']
for role,name in [('player','DeclarerInstructions.txt'),('reviewer','ReviewerInstructions.txt')]:assert sha(member_bytes[bundle.name+'/'+name])==candidate['instruction_sha256'][role]
preservation={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source_commit':candidate['source_commit'],'original_binary':str(binary),'preserved_binary':str(preserved/'bridge-play'),'binary_sha256':candidate['binary_sha256'],'original_bundle':str(bundle),'preserved_bundle':str(preserved/bundle.name),'member_sha256':{name:sha(data) for name,data in member_bytes.items()},'before_any_model_calls':True}
(preserved/'preservation.json').write_text(json.dumps(preservation,indent=2)+'\n');member_bytes['preservation.json']=(preserved/'preservation.json').read_bytes()
runtime_archive=archive(runtime/'candidate3-runtime.tar.gz',member_bytes)
verification={'archive_sha256':runtime_archive['sha256'],'bytes':runtime_archive['bytes'],'member_sha256':{name:sha(data) for name,data in member_bytes.items()},'verified_against_freeze':True}
(runtime/'candidate3-runtime-verification.json').write_text(json.dumps(verification,indent=2)+'\n')
for archive_path,expected in [(runtime/'candidate3-source.tar.gz',blobs),(runtime/'candidate3-runtime.tar.gz',member_bytes)]:
 with tarfile.open(archive_path,'r:gz') as tar:
  assert {m.name for m in tar.getmembers() if m.isfile()}==set(expected)
  for name,data in expected.items():assert tar.extractfile(name).read()==data
build={'source_commit':candidate['source_commit'],'command':['swift','build','--product','bridge-play'],'command_environment':{'SDKROOT':'/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk'},'exit_code':0,'log':'build.stdout-stderr.log','binary_sha256':candidate['binary_sha256'],'toolchain_observations':{}}
for name,argv in [('swift_version',['swift','--version']),('sdk_path',['xcrun','--sdk','macosx','--show-sdk-path']),('xcode',['xcodebuild','-version']),('uname',['uname','-a'])]:
 r=subprocess.run(argv,env=dict(os.environ,SDKROOT=build['command_environment']['SDKROOT']),capture_output=True,text=True);build['toolchain_observations'][name]={'argv':argv,'exit_code':r.returncode,'stdout':r.stdout,'stderr':r.stderr}
launch=Path('/tmp/bridge-coup-issue48-context/candidate3-launch')
(launch/'build-environment.json').write_text(json.dumps(build,indent=2)+'\n')
print(json.dumps({'source':candidate['source_commit'],'cycle':cycle,'binary_sha256':candidate['binary_sha256'],'instruction_sha256':candidate['instruction_sha256'],'native_sha256':candidate['codex_sha256'],'native_version':candidate['runtime_version'],'native_catalog_sha256':candidate['runtime_catalog_sha256'],'source_archive':source_meta['sha256'],'runtime_archive':verification['archive_sha256'],'source_blobs':len(blobs),'preserved_runtime':str(preserved)},indent=2))
