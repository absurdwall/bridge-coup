import hashlib,json,pathlib,collections
p=pathlib.Path('/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup/evals/stage1/evidence/issue48/ticket52/candidate2/short-3-r3')
out=pathlib.Path('/tmp/bridge-coup-issue48-context')
g=json.loads((p/'grade/input.json').read_text());t=json.loads((p/'play/trace.json').read_text());s=json.loads((p/'summary.json').read_text());e=json.loads((p/'grade/evaluation.json').read_text())
rows=[]
for d in g['decisions']:
 f=d['decision_time_facts'];a=json.loads(d['raw_output']);r=json.loads((p/'play'/d['id']/'decision.json').read_text());h=next(x['cards'] for x in f['hands'] if x['seat']==f['actingSeat'])
 assert r['rawOutput']==d['raw_output'] and r['snapshot']==f and r['canonicalInput']==d['authorized_input'] and r['effectivePlan']==d['effective_plan']
 assert a['selectedCard'] in h and a['selectedCard'] in f['legalCards']
 if f['currentTrick'] and any(c[0]==f['currentTrick'][0]['card'][0] for c in h): assert a['selectedCard'][0]==f['currentTrick'][0]['card'][0]
 step=next(x for x in t['steps'] if x['execution']['event']['sequence']==f['revision'])
 assert step['execution']['source']=='model' and step['decision']['rawOutput']==d['raw_output']
 assert len(r['reviewRounds'])==1
 rows.append({'id':d['id'],'revision':f['revision'],'seat':f['actingSeat'],'card':a['selectedCard'],'reason':a['publicReason'],'update':a['plan']['update'],'public_record_exact':True,'owned_and_legal':True,'source':'model'})
assert len(rows)==12 and all(x['quality']=='pass' for x in e['results'])
initial=g['decisions'][0]['decision_time_facts'];clubs=[c for h in initial['hands'] for c in h['cards'] if c[0]=='C'];assert len(clubs)==8
before=g['decisions'][8]['decision_time_facts'];window=g['decisions'][9]['decision_time_facts']
def seen(f):return {seat:[x['card'] for x in f['events'] if x['seat']==seat and x['card'][0]=='C'] for seat in ['west','east']}
assert seen(before)=={'west':['C3','C9'],'east':['C5','CT']}
assert seen(window)=={'west':['C3','C9','CJ'],'east':['C5','CT']}
assert window['events'][-1]=={'card':'CJ','seat':'west','sequence':17} and window['revision']==18
assert all(x['seat']!='east' or x['card'][0]=='C' for trick in [window['events'][4:8],window['events'][8:12]] for x in trick)
events=t['steps'][-1]['actualEvents'];assert next(x for x in events if x['sequence']==19)=={'card':'H2','seat':'east','sequence':19}
# Coverage boundary uses the subsequent completed trace, never as decision18 knowledge.
showouts=[]
for i in range(0,len(events),4):
 trick=events[i:i+4]
 if trick and trick[0]['card'][0]=='C':showouts.extend(x for x in trick[1:] if x['seat'] in ['east','west'] and x['card'][0]!='C')
assert next(x for x in showouts if x['seat']=='east')['sequence']==19
files=['grade/input.json','grade/evaluation.json','grade/grader-output.json','play/trace.json','summary.json']
hashes={n:hashlib.sha256((p/n).read_bytes()).hexdigest() for n in files if (p/n).exists()}
proof={'attempt':'candidate2/short-3-r3','frozen_source':'0a307cbde5498ed24b73da0d781cb9113ce92180','root':str(p),'source_sha256':hashes,'decisions':rows,'public_core':{'initial_outside_clubs':5,'before_decision9_seen':seen(before),'last_outside_card':'CJ','split_known':'3-2','long_owner_not_yet_known':True},'eligible_window':{'decision':'decision-0010','revision':18,'new_observation':window['events'][-1],'seen_clubs':seen(window),'deduction':'West originally3 clubs; East originally2 and now0','prior_equivalent_localization':False,'source':'model','legal_cards':window['legalCards']},'later_trace_coverage_boundary_only':{'other_first_club_showout':19,'card':'H2','seat':'east'},'semantic_facet':'not established conservatively: current exhaustion statement is correct but repeats prior forecast without distinct observable use of newly localized owner','automatic_runtime_seconds':s['timing']['automaticRuntimeSeconds'],'raw_grade_counts':s['quality_counts']}
(out/'candidate2-short-3-r3-window-proof.json').write_text(json.dumps(proof,indent=2)+'\n')
print(json.dumps({'exact_public_records':12,'owned_legal_model_deliveries':12,'raw_grade_counts':s['quality_counts'],'model_window_revision':18,'other_first_showout':19,'proof':str(out/'candidate2-short-3-r3-window-proof.json')},indent=2))
