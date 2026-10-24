import json,os,pathlib,shutil,subprocess,sys
ROOT=pathlib.Path(__file__).parent
REPO=pathlib.Path('/Users/tingranwang/.codex/worktrees/issue46-integration/bridge-coup')
sys.path.insert(0,str(REPO/'evals/stage1'));import acceptance
from evaluate import run_owned_runtime
wire=json.loads((REPO/'evals/stage1/evidence/issue46-completion/development-v4/short-6-r1/wire/request-11.json').read_text())
items=[i for i in wire['input'] if i['type'] not in ['additional_tools'] and not(i['type']=='message' and i.get('role') in ['developer','system'])]
assert items[-1]['type']=='message' and items[-1]['role']=='user'
items=items[:-1]
d=ROOT/'dry-history';d.mkdir(exist_ok=False)
(d/'seed.json').write_text(json.dumps(items,indent=2)+'\n')
native='/Users/tingranwang/.nvm/versions/node/v24.12.0/lib/node_modules/@openai/codex/node_modules/@openai/codex-darwin-arm64/vendor/aarch64-apple-darwin/bin/codex'
log=(d/'proxy-stderr.txt').open('w')
proxy=subprocess.Popen([sys.executable,str(REPO/'Scripts/capture-playing-wire.py'),'--codex',native,'--output',str(d/'wire')],stdout=subprocess.PIPE,stderr=log)
try:
 actual=acceptance.proxy_wrapper(proxy)
 relay=d/'relay';relay.write_text('#!'+sys.executable+'\n'+(ROOT/'history_relay.py').read_text());relay.chmod(0o700)
 config={'executable':actual,'seed':str(d/'seed.json'),'ack':str(d/'injection-ack.json'),'dry_run':True}
 pathlib.Path(str(relay)+'.json').write_text(json.dumps(config))
 result=run_owned_runtime([str(ROOT/'probe'),str(ROOT/'requests/club-full-r1.json'),str(d/'runtime'),str(relay),str(pathlib.Path.home()/'.codex/auth.json')],env=dict(os.environ),cwd=ROOT,timeout=90)
 (d/'stdout.txt').write_text(result.stdout);(d/'stderr.txt').write_text(result.stderr)
 ack=json.loads((d/'injection-ack.json').read_text());requests=list((d/'wire').glob('request-*.json'))
 assert ack['accepted'],ack
 assert len(requests)==0
 print('Offline history injection accepted:',ack['item_count'],'items; model HTTP requests:',len(requests),'; deliberate dry-run exit:',result.returncode)
finally:
 proxy.terminate();proxy.wait(timeout=5);log.close()
