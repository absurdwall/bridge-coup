#!/usr/bin/env python3
"""Replay original saved public-only counterbranch, redirecting reads and denying writes."""
import argparse
import contextlib
import hashlib
import io
import json
from pathlib import Path
from unittest.mock import patch

HERE=Path(__file__).resolve().parent
ORIGINAL_ROOT=Path('/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup/evals/stage1/evidence/issue48/ticket52/candidate3/short-5-r1')
ORIGINAL_PROOF=Path('/tmp/bridge-coup-issue48-context/candidate3-short-5-r1-public-branch-check.json')
SCRIPT_SHA='7fe84050eef6b5a03babcf198d98b433fa54c555b4caaa8682737f64a57bba73'
PROOF_SHA='be196e7b714ddfdfed3e1a649e2a5061812709f33a22259d4ac5e595956f45b6'

def verify(repo,script,proof):
    code=script.read_bytes();saved=proof.read_bytes()
    assert hashlib.sha256(code).hexdigest()==SCRIPT_SHA
    assert hashlib.sha256(saved).hexdigest()==PROOF_SHA
    actual=repo/'evals/stage1/evidence/issue48/ticket52/candidate3/short-5-r1/grade/input.json'
    read_text=Path.read_text;reads=[];writes=[]
    def mapped_read(path,*args,**kwargs):
        assert path==ORIGINAL_ROOT/'grade/input.json',path
        reads.append(str(path))
        return read_text(actual,*args,**kwargs)
    def compare_write(path,text,*args,**kwargs):
        assert path==ORIGINAL_PROOF,path
        assert text.encode()==saved,'Original script generated a different proof.'
        writes.append(str(path))
        return len(text)
    output=io.StringIO()
    with patch.object(Path,'read_text',mapped_read),patch.object(Path,'write_text',compare_write),contextlib.redirect_stdout(output):
        exec(compile(code,str(script),'exec'),{'__name__':'saved_public_counterbranch','__file__':str(script)})
    assert len(reads)==len(writes)==1
    assert json.loads(output.getvalue())==json.loads(saved)
    assert proof.read_bytes()==saved
    return {'status':'pass','original_script_sha256':SCRIPT_SHA,'saved_proof_sha256':PROOF_SHA,
            'public_input_reads':len(reads),'intercepted_writes_compared_only':len(writes),
            'original_executed_unchanged':True,'saved_proof_unchanged':True,
            'scope':'Public-compatible counterfactual only; original hard-coded public input read is mapped to --repo, final historical write is intercepted for exact-byte comparison. No fixture, current source, native/model call or quality label.'}

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo',type=Path,required=True)
    parser.add_argument('--script',type=Path,default=HERE/'originals/candidate3-short-5-r1-public-branch-check.py')
    parser.add_argument('--proof',type=Path,default=HERE/'originals/candidate3-short-5-r1-public-branch-check.json')
    args=parser.parse_args();print(json.dumps(verify(args.repo.resolve(),args.script.resolve(),args.proof.resolve()),indent=2))
