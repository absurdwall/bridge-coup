"""One predeclared native Walker correction probe at public Expert/BoardDriver.

At most 12 delivered decisions, stop after the first natural revise -> approve
sequence. Never seed a proposal or reviewer result; never rerun this directory.
This diagnostic is distinct from the unchanged 22-attempt acceptance matrix.
"""
from pathlib import Path
import hashlib, json, os, select, shutil, subprocess, sys, time
ROOT=Path(__file__).resolve().parents[5]
OUT=Path(__file__).resolve().parent/'native-correction'
NATIVE=Path(sys.argv[1]) if len(sys.argv)>1 else Path(shutil.which('codex'))
assert not OUT.exists(), 'Preserve existing evidence; no reroll.'
OUT.mkdir()
def save(path,value): path.write_text(json.dumps(value,indent=2,ensure_ascii=False)+'\n')
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
files=['Sources/BridgeExpert/Expert.swift','Sources/BridgeExpert/PlayReview.swift','Sources/BridgeCodex/CodexTransport.swift','Sources/BridgeCodex/CodexReviewTransport.swift','Sources/BridgeDriver/BoardDriver.swift','Sources/BridgeExpert/Resources/DeclarerInstructions.txt','Sources/BridgeExpert/Resources/ReviewerInstructions.txt']
save(OUT/'manifest.json',{'purpose':'One bounded natural correction diagnostic, not acceptance. No seeded proposals or synthetic reviewer verdicts.','baseline':'d4b4f86bae786ab8ec4d49b0c2f22f03cd549c97','sourceHashes':{p:sha(ROOT/p) for p in files},'binarySha256':sha(ROOT/'.build/debug/bridge-play'),'nativeSha256':sha(NATIVE),'model':'gpt-6.1-sol','effort':'medium','maxDeliveredDecisions':12,'maxSemanticRounds':5,'stopRule':'First natural revise followed by approve in one pending decision, otherwise stop at 12 decisions or failure.','requestTimeout':180,'runTimeout':1800})
with (OUT/'proxy-stderr.txt').open('w') as error:
 proxy=subprocess.Popen([sys.executable,str(ROOT/'Scripts/capture-playing-wire.py'),'--codex',str(NATIVE),'--output',str(OUT/'wire')],stdout=subprocess.PIPE,stderr=error)
 child=None
 try:
  assert select.select([proxy.stdout],[],[],10)[0], 'Proxy startup timeout'
  wrapper=proxy.stdout.readline().decode().strip()
  command=[str(ROOT/'.build/debug/bridge-play'),'--fixture',str(ROOT/'evals/stage1/corpus/boards/walker-holdup-adapted.json'),'--output',str(OUT/'play'),'--codex',wrapper,'--decisions','12','--interactive','true','--opponent','conserve-high','--sole-legal','true','--timeout','180','--run-timeout','1800']
  save(OUT/'command.json',command)
  started=time.monotonic(); deliveries=0; corrected=False
  with (OUT/'stdout.txt').open('w') as stdout, (OUT/'stderr.txt').open('w') as stderr:
   child=subprocess.Popen(command,cwd=ROOT,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=stderr)
   # Unbuffered OS reads avoid losing a prompt already held by a Python buffer.
   pending=b''
   while child.poll() is None:
    if time.monotonic()-started>1900: child.kill(); raise TimeoutError('Outer diagnostic deadline')
    if not select.select([child.stdout],[],[],1)[0]: continue
    chunk=os.read(child.stdout.fileno(),65536)
    if not chunk: break
    stdout.write(chunk.decode());stdout.flush();pending+=chunk
    while b'\n' in pending:
     line,pending=pending.split(b'\n',1)
     if line.startswith(b'Applied '): deliveries+=1
     if line.startswith(b'Waiting for next or stop'):
      decision=json.loads((OUT/'play'/f'decision-{deliveries:04d}'/'decision.json').read_text())
      verdicts=[r['review']['result']['verdict'] for r in decision['reviewRounds']]
      corrected='revise' in verdicts[:-1] and verdicts[-1]=='approve'
      child.stdin.write(b'stop\n' if corrected else b'next\n');child.stdin.flush()
   remainder=child.stdout.read()
   if remainder: stdout.write(remainder.decode())
   code=child.wait(timeout=15)
  save(OUT/'process.json',{'returncode':code,'elapsedSeconds':time.monotonic()-started,'deliveredDecisions':deliveries,'naturalCorrectionObserved':corrected})
 finally:
  if child and child.poll() is None: child.kill();child.wait(timeout=5)
  proxy.terminate();proxy.wait(timeout=5)
print(OUT)
