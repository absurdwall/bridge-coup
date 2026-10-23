from pathlib import Path
import json,subprocess,sys,os
here=Path(__file__).resolve().parent
result=subprocess.check_output([sys.executable,str(here/'status.py')],env=dict(os.environ,PYTHONDONTWRITEBYTECODE='1'),text=True)
(here/'live-status.json').write_text(result)
s=json.loads(result)
print(json.dumps({'completed':s['completed'],'new':s['attempts'][int(sys.argv[1]):],'active':s['started_unfinished'],'alive':s['runner_alive'],'finished':s['execution_finished']}))
