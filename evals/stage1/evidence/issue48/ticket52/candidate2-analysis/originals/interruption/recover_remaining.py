#!/usr/bin/env python3
"""Explicit operational supplement after lost orchestrator; never resumes a board."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import sys

REPO=Path('/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup')
ROOT=REPO/'evals/stage1/evidence/issue48/ticket52/candidate2'
OUT=ROOT.with_name('candidate2-analysis')/'operational-recovery'
BASE=Path(__file__).resolve().parent
REMAINING=['short-5-r2','short-5-r3','short-6-r1','short-6-r2','short-6-r3',
           'full-development-r1','full-development-r2','full-reserved-r1','full-reserved-r2']
sys.path.insert(0,str(REPO/'evals/stage1'))
import acceptance
import corpus
import evaluate

def utc():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def load(path):return json.loads(path.read_text())
def write(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n')
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def existing_inventory(plan):
    paths=[ROOT/'summary.json',ROOT/'REPORT.md',ROOT/'execution-started.json',ROOT/'candidate.json',ROOT/'plan.json']
    for attempt in plan[:13]:
        paths += [p for p in (ROOT/attempt['id']).rglob('*') if p.is_file()]
    return {str(path.relative_to(ROOT)):sha(path) for path in sorted(paths)}

def prepare():
    candidate=load(ROOT/'candidate.json');plan=load(ROOT/'plan.json')
    assert candidate['source_commit']=='0a307cbde5498ed24b73da0d781cb9113ce92180'
    acceptance.verify_schedule(plan);acceptance.preflight(candidate)
    assert [row['id'] for row in plan[13:]]==REMAINING and len(REMAINING)==9
    assert plan[12]['id']=='short-5-r1'
    assert len(load(ROOT/'summary.json')['attempts'])==12
    assert not (ROOT/'execution-finished.json').exists()
    assert all((ROOT/row['id']/'summary.json').exists() for row in plan[:12])
    assert not (ROOT/'short-5-r1/summary.json').exists()
    assert not (ROOT/'short-5-r1/playing-outcome.json').exists()
    assert all(not (ROOT/identifier).exists() for identifier in REMAINING), 'Unknown started slot; stop without any rerun.'
    return candidate,plan

def partial_package():
    play=ROOT/'short-5-r1/play'
    directories=sorted(p.parent for p in play.glob('decision-*/decision.json'))
    assert len(directories)==3
    records=[(directory.name,evaluate.read_decision(directory)) for directory in directories]
    for identifier,record in records:
        assert record.get('executionEvents') is not None and not record.get('runtimeFailure'),identifier
        assert all(row['status']=='pass' for row in evaluate.deterministic_checks(record).values()),identifier
    package=evaluate.grader_package(records)
    manifest=REPO/'evals/stage1/corpus/manifest.json'
    material=corpus.validate(manifest);corpus.verify_case_decisions(manifest,'short-5',records)
    package['case']=next(row for row in material['case_rules'] if row['id']=='short-5')
    package['corpus_version']=material['corpus_version']
    return directories,package

def summarize(original,recovered,partial):
    actual=[row for row in recovered if row.get('task_complete')]
    result={'utc':utc(),'source_commit':'0a307cbde5498ed24b73da0d781cb9113ce92180',
            'cycle':2,'maximumCycles':3,'outcome':'NO-GO','uninterrupted_strict22_complete':False,
            'discontinuity':'User interruption killed original orchestration/capture; short-5-r1 is permanently incomplete, never reconnected/restarted/rerolled. Remaining9 are explicit operational supplemental execution.',
            'original_completed_attempts':12,'remaining_attempts_started_once':len(recovered),
            'task_complete_count':12+len(actual),'interrupted_attempts':['short-5-r1'],
            'original12_summary_sha256':original['summary.json'],'original12_report_sha256':original['REPORT.md'],
            'partial_delivered_grade':partial,'recovered_attempts':recovered,
            'limits':['No normal interrupted process exit or unknown usage is invented.',
                      'Original12 summaries/report/marker and interrupted raw records remain unchanged.',
                      'This is not a product live-board recovery feature or an uninterrupted acceptance pass.']}
    write(OUT/'recovery-summary.json',result)
    lines=['# Candidate 2 operational supplement','','**NO-GO: original matrix was interrupted.**',
           '',f"{result['task_complete_count']} task-complete attempts; short-5-r1 remains interrupted and incomplete.",
           'Original12 records are unchanged; these nine untouched scheduled attempts run once in their original order.',
           'No execution-finished marker or normal interrupted outcome is fabricated.','',
           '| Supplemental attempt | Task | Legal | Raw quality |','|---|---|---|---|']
    for row in recovered:lines.append('| %s | %s | %s | %s |'%(row['id'],row.get('task_complete'),row.get('legal_execution','unknown'),row.get('quality','unknown')))
    (OUT/'REPORT.md').write_text('\n'.join(lines)+'\n')

def run():
    candidate,plan=prepare();OUT.mkdir(parents=True,exist_ok=True)
    with (OUT/'started.json').open('x') as stream:
        json.dump({'utc':utc(),'pid':os.getpid(),'pgid':os.getpgrp(),'session':os.getsid(0),
                   'remaining_ids':REMAINING,'wrapper_sha256':sha(Path(__file__)),
                   'authorization':'Coordinator reviewed explicit operational recovery after user continued; no interrupted board resume.'},stream,indent=2)
    write(OUT/'frozen-attestation.json',{'utc':utc(),'frozen_preflight':'returned_without_error',
          'candidate_sha256':sha(ROOT/'candidate.json'),'source_commit':candidate['source_commit'],
          'binary_sha256':candidate['binary_sha256'],'native_sha256':candidate['codex_sha256'],
          'native_version':candidate['runtime_version'],'native_catalog_sha256':candidate['runtime_catalog_sha256'],
          'role_configurations':candidate['role_configurations'],'execution_configuration':candidate['execution_configuration']})
    original=existing_inventory(plan);write(OUT/'original13-inventory.json',original)
    partial={'attempt':'short-5-r1','task_complete':False,'status':'not_called','process_exit':None,
             'usage_limit':'Captured usage only; interrupted/lost observations remain unknown.'}
    try:
        directories,package=partial_package()
        write(OUT/'partial-prepared-input.json',package)
        output=OUT/'partial-delivered-grade';assert not output.exists()
        command=[sys.executable,str(REPO/'evals/stage1/evaluate.py'),'grade','--case','short-5',
                 '--codex',candidate['codex'],'--timeout',str(candidate['grader_timeout_seconds']),'--output',str(output)]
        for directory in directories:command += ['--decision',str(directory)]
        acceptance.verify_schedule(load(ROOT/'plan.json'));acceptance.preflight(candidate)
        write(OUT/'partial-grade-command.json',command)
        with (OUT/'partial-grade-stdout.txt').open('w') as stdout,(OUT/'partial-grade-stderr.txt').open('w') as stderr:
            process=acceptance.bounded_command(command,stdout,stderr,candidate['grader_timeout_seconds']+30)
        partial.update(status='called_once_for3_delivered_only',grader_exit_code=process.returncode,
                       output=str(output),delivered_decisions=3)
        assert load(output/'input.json')==package,'Actual partial grader package differs.'
    except Exception as error:
        partial.update(status='partial_grading_unavailable_or_failed_no_retry',error=str(error))
    write(OUT/'partial-grade-outcome.json',partial)
    print('partial interrupted delivered-only grading:',partial['status'],flush=True)
    recovered=[];summarize(original,recovered,partial)
    for identifier,attempt in zip(REMAINING,plan[13:]):
        acceptance.verify_schedule(load(ROOT/'plan.json'));acceptance.preflight(candidate)
        assert attempt['id']==identifier and not (ROOT/identifier).exists(),'Unknown started slot; refusing rerun.'
        write(OUT/('preflight-'+identifier+'.json'),{'utc':utc(),'frozen_preflight':'returned_without_error',
              'source_commit':candidate['source_commit'],'candidate_sha256':sha(ROOT/'candidate.json'),
              'native_catalog_sha256':candidate['runtime_catalog_sha256']})
        try:row=acceptance.run_attempt(candidate,attempt,ROOT)
        except Exception as error:
            row={'id':identifier,'task_complete':False,'quality':'unknown','operational_exception':str(error),
                 'actual_outcome':'Unknown beyond preserved helper artifacts; no fallback or rerun.'}
        recovered.append(row);summarize(original,recovered,partial)
        assert existing_inventory(plan)==original,'Original12/interrupted evidence changed.'
        print(identifier+': supplemental completed task='+str(row.get('task_complete'))+' quality='+str(row.get('quality')),flush=True)
    write(OUT/'finished.json',{'utc':utc(),'remaining_attempts':len(recovered),'outcome':'NO-GO',
                             'original_matrix_uninterrupted_complete':False,'original13_inventory_unchanged':True})

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--run',action='store_true');args=parser.parse_args()
    if args.run:run()
    else:
        candidate,plan=prepare()
        try:directories,package=partial_package();partial={'safe':True,'delivered_records':len(directories),'deterministic_checks':'allpass','case':'short-5'}
        except Exception as error:partial={'safe':False,'reason':str(error)}
        print(json.dumps({'source':candidate['source_commit'],'remaining_ids':REMAINING,'untouched_directories':True,
                          'partial_grade_preparation':partial,'model_calls':0},indent=2))
