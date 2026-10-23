"""Launch the reviewed operational supplement once, outside tool process group."""
import datetime
import hashlib
import json
import os
from pathlib import Path
import subprocess

BASE=Path(__file__).resolve().parent
REPO=Path('/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup')
PYTHON='/tmp/bridge-coup-issue48-context/venv/bin/python'
WRAPPER=BASE/'recover_remaining.py'
OUT=REPO/'evals/stage1/evidence/issue48/ticket52/candidate2-analysis/operational-recovery'
OUT.mkdir(parents=True,exist_ok=True)
registry=BASE/'detached-registry.json'
with registry.open('x') as record:
    with (OUT/'detached-orchestrator.log').open('x') as log:
        child=subprocess.Popen([PYTHON,'-u',str(WRAPPER),'--run'],cwd=REPO,
             env=dict(os.environ,PYTHONDONTWRITEBYTECODE='1'),stdin=subprocess.DEVNULL,
             stdout=log,stderr=subprocess.STDOUT,start_new_session=True,close_fds=True)
    metadata={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'pid':child.pid,
              'pgid':os.getpgid(child.pid),'session':os.getsid(child.pid),'launcher_pid':os.getpid(),
              'launcher_pgid':os.getpgrp(),'interpreter':PYTHON,'command':[PYTHON,'-u',str(WRAPPER),'--run'],
              'cwd':str(REPO),'wrapper_sha256':hashlib.sha256(WRAPPER.read_bytes()).hexdigest(),
              'stdout_stderr':str(OUT/'detached-orchestrator.log'),
              'scope':'Reviewed explicit operational supplement, never interrupted board resume or uninterrupted22pass.'}
    assert metadata['pgid']==metadata['session']==metadata['pid'] and metadata['pgid']!=metadata['launcher_pgid']
    json.dump(metadata,record,indent=2)
print(json.dumps(metadata,indent=2))
