#!/usr/bin/env python3
"""Verify saved public window facts; semantic cohort judgment stays in reports."""
import argparse
import hashlib
import json
from pathlib import Path

HERE=Path(__file__).resolve().parent

def load(path):return json.loads(path.read_text())
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def observed(events):
    return {seat:[e['card'] for e in events if e['seat']==seat and e['card'].startswith('C')] for seat in ('west','east')}
def showouts(events):
    return [event for i in range(0,len(events),4) for event in events[i+1:i+4]
            if events[i]['card'].startswith('C') and event['seat'] in ('west','east') and not event['card'].startswith('C')]

def verify(repo, analysis):
    root=repo/'evals/stage1/evidence/issue48/ticket52/candidate2';results=[]
    for repetition in (1,2,3):
        identifier=f'short-3-r{repetition}';directory=root/identifier
        proof=load(analysis/'originals'/f'candidate2-{identifier}-window-proof.json')
        package=load(directory/'grade/input.json');trace=load(directory/'play/trace.json');summary=load(directory/'summary.json')
        initial=package['decisions'][0]['decision_time_facts']
        assert sum(c.startswith('C') for h in initial['hands'] for c in h['cards'])==8
        events=trace['steps'][-1]['actualEvents']
        for decision in package['decisions']:
            record=load(directory/'play'/decision['id']/'decision.json');facts=decision['decision_time_facts'];answer=json.loads(decision['raw_output'])
            assert record['snapshot']==facts and record['canonicalInput']==decision['authorized_input']
            assert record['rawOutput']==decision['raw_output'] and record['effectivePlan']==decision['effective_plan']
            assert facts['events']==events[:facts['revision']]
            holding=next(h['cards'] for h in facts['hands'] if h['seat']==facts['actingSeat'])
            assert answer['selectedCard'] in holding and answer['selectedCard'] in facts['legalCards']
            if facts['currentTrick'] and any(c[0]==facts['currentTrick'][0]['card'][0] for c in holding):
                assert answer['selectedCard'][0]==facts['currentTrick'][0]['card'][0]
            step=next(s for s in trace['steps'] if s['execution']['event']['sequence']==facts['revision'])
            assert step['execution']['source']=='model' and step['decision']['rawOutput']==record['rawOutput']
        assert len(package['decisions'])==12 and summary['counts']['forced_actions']==0
        if repetition==1:
            decision_id=Path(proof['decision']).name
            if decision_id=='decision.json':decision_id=Path(proof['decision']).parent.name
            record_path=directory/'play'/decision_id/'decision.json'
            assert sha(record_path)==proof['decision_sha256']
            record=load(record_path);revision=proof['snapshot_revision']
            assert record['snapshot']['revision']==revision
        else:
            for relative,expected in proof['source_sha256'].items():assert sha(directory/relative)==expected
            decision_id=proof['eligible_window']['decision'];revision=proof['eligible_window']['revision']
            record=load(directory/'play'/decision_id/'decision.json')
        prefix=record['snapshot']['events']
        assert prefix==events[:revision] and prefix[-1]['seat']=='west' and prefix[-1]['card']=='CJ'
        assert observed(prefix)=={'west':['C3','C9','CJ'],'east':['C5','CT']}
        assert not any(e['seat']=='east' for e in showouts(prefix))
        later=next(e for e in showouts(events) if e['seat']=='east')
        assert later['sequence']>revision
        expected=summary['coverage']['facets']['third_club_before_other_defender_revisions']
        assert revision in expected
        results.append({'attempt':identifier,'all12_public_records_bound':True,'eligible_model_revision':revision,
                        'public_defender_club_count':[3,2],'later_coverage_only_showout':later['sequence']})
    return {'status':'public_facts_verified','attempts':results,
            'semantic_facet':'No semantic pass is inferred; final cohort resolution and independent Spec dissent remain separate immutable reports.',
            'limits':'Only saved authorized hands, actual public events and exact output/execution records are read. No hidden fixture or current source/native executable is used.'}

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--repo',required=True,type=Path)
    parser.add_argument('--analysis',type=Path,default=HERE);args=parser.parse_args()
    print(json.dumps(verify(args.repo.resolve(),args.analysis.resolve()),indent=2))
