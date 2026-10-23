"""Harmless outside-repository regression: no model/native/acceptance invocation."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time

HERE=Path(__file__).resolve().parent
LAUNCHER=HERE/'launch_candidate3.py'
PYTHON='/tmp/bridge-coup-issue48-context/venv/bin/python'
with tempfile.TemporaryDirectory(prefix='bridge-c3-detached-test-') as temp:
    root=Path(temp)
    code="import pathlib,sys,time; r=pathlib.Path(sys.argv[1]); assert sys.stdin.read()==''; (r/'ready').write_text('stdin EOF'); print('child starts',flush=True); time.sleep(1.5); (r/'finished').write_text('done'); print('child done',flush=True)"
    command=[PYTHON,'-u','-c',code,str(root)]
    harness="import importlib.util,json,pathlib,sys; s=importlib.util.spec_from_file_location('launch',sys.argv[1]); m=importlib.util.module_from_spec(s); s.loader.exec_module(m); print(json.dumps(m.spawn_once(json.loads(sys.argv[3]),pathlib.Path(sys.argv[2]),pathlib.Path(sys.argv[2])/'execution',{'scope':'harmless lifecycle test'})))"
    started=time.monotonic()
    first=subprocess.run([PYTHON,'-c',harness,str(LAUNCHER),str(root),json.dumps(command)],capture_output=True,text=True,check=True,timeout=2)
    launcher_elapsed=time.monotonic()-started
    metadata=json.loads(first.stdout)
    assert launcher_elapsed<1.5 and not (root/'finished').exists()
    assert metadata['pid']==metadata['pgid']==metadata['session']
    assert metadata['pgid']!=metadata['launcher_pgid']
    assert os.getpgid(metadata['pid'])==metadata['pid']
    deadline=time.monotonic()+1
    while not (root/'ready').exists() and time.monotonic()<deadline:time.sleep(.01)
    assert (root/'ready').read_text()=='stdin EOF'
    # Launcher already exited; child is still alive in its own session.
    process=subprocess.check_output(['ps','-p',str(metadata['pid']),'-o','pid=,ppid=,pgid=,command='],text=True).strip()
    assert int(process.split()[1])!=metadata['launcher_pid']
    second=subprocess.run([PYTHON,'-c',harness,str(LAUNCHER),str(root),json.dumps(command)],capture_output=True,text=True,timeout=2)
    assert second.returncode!=0 and 'FileExistsError' in second.stderr
    deadline=time.monotonic()+3
    while not (root/'finished').exists() and time.monotonic()<deadline:time.sleep(.02)
    assert (root/'finished').read_text()=='done'
    assert 'child done' in (root/'execution/runner.stdout-stderr.log').read_text()
    result={'status':'pass','launcher_exit_before_child_completion':True,'child_distinct_pid_pgid_session':True,
            'child_reparented_after_launcher_exit':True,'stdin_is_devnull':True,'stdout_stderr_survive_launcher_exit':True,
            'duplicate_registry_rejects_second_launch':True,'launcher_elapsed_seconds':launcher_elapsed,
            'launcher_sha256':hashlib.sha256(LAUNCHER.read_bytes()).hexdigest(),
            'scope':'Only harmless Python child in temporary directory. No project writes, builds, freeze, native/model/acceptance calls or general recovery.'}
print(json.dumps(result,indent=2))
