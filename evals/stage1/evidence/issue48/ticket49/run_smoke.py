"""One bounded real first-decision probe through the production Expert/BoardDriver.

This is runtime integration evidence, not a frozen quality-acceptance cycle.
Never reruns or replaces a failed probe. Run from the repository root.
"""
from pathlib import Path
import hashlib, json, os, select, shutil, subprocess, sys
ROOT = Path(__file__).resolve().parents[5]
OUT = Path(__file__).resolve().parent / 'native-smoke'
NATIVE = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(shutil.which('codex'))
assert not OUT.exists(), 'Existing probe evidence must be preserved; no reroll.'
OUT.mkdir()
def save(path, value): path.write_text(json.dumps(value, indent=2, ensure_ascii=False)+'\n')
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
files=['Sources/BridgeExpert/Expert.swift','Sources/BridgeExpert/PlayReview.swift','Sources/BridgeCodex/CodexTransport.swift','Sources/BridgeCodex/CodexReviewTransport.swift','Sources/BridgeDriver/BoardDriver.swift','Sources/BridgeExpert/Resources/DeclarerInstructions.txt','Sources/BridgeExpert/Resources/ReviewerInstructions.txt']
save(OUT/'manifest.json', {'purpose':'One actual initial player + independent reviewer; no repair, retry or quality claim.', 'baseline':'c74d69781498f5a69ea0be9e0dc26612d5c96e6d','sourceHashes':{p:sha(ROOT/p) for p in files},'model':'gpt-6.1-sol','effort':'medium','requestTimeout':180,'nativeSha256':sha(NATIVE)})
with (OUT/'proxy-stderr.txt').open('w') as error:
 proxy=subprocess.Popen([sys.executable,str(ROOT/'Scripts/capture-playing-wire.py'),'--codex',str(NATIVE),'--output',str(OUT/'wire')],stdout=subprocess.PIPE,stderr=error)
 try:
  assert select.select([proxy.stdout],[],[],10)[0], 'Proxy startup timeout'
  wrapper=proxy.stdout.readline().decode().strip()
  command=[str(ROOT/'.build/debug/bridge-play'),'--fixture',str(ROOT/'evals/stage1/corpus/boards/synthetic.json'),'--output',str(OUT/'play'),'--codex',wrapper,'--decisions','1','--timeout','180']
  save(OUT/'command.json',command)
  with (OUT/'stdout.txt').open('w') as stdout, (OUT/'stderr.txt').open('w') as stderr:
   result=subprocess.run(command,cwd=ROOT,stdout=stdout,stderr=stderr,timeout=390)
  save(OUT/'process.json',{'returncode':result.returncode})
 finally:
  proxy.terminate(); proxy.wait(timeout=5)
print(OUT)
