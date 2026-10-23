"""Read-only post-run aggregation, no model calls or raw evidence rewrites."""
from pathlib import Path
import json,statistics,sys
root=Path(sys.argv[1]).resolve();analysis=root.with_name('candidate2-analysis')
assert json.loads((analysis/'operational-recovery/finished.json').read_text())['remaining_attempts']==9
plan=json.loads((root/'plan.json').read_text());assert len(plan)==22
summaries=[json.loads((root/a['id']/'summary.json').read_text()) for a in plan if (root/a['id']/'summary.json').exists()]
assert len(summaries)==21 and not (root/'short-5-r1/summary.json').exists()
assert not (root/'short-5-r1/playing-outcome.json').exists() and not (root/'execution-finished.json').exists()
partial_cost=json.loads((analysis/'originals/interruption/interrupted-cost-observations.json').read_text())
partial_grade=json.loads((analysis/'operational-recovery/partial-delivered-grade/evaluation.json').read_text())
partial_grader_run=json.loads((analysis/'operational-recovery/partial-delivered-grade/run.json').read_text())
index=json.loads((analysis/'originals/candidate2-adjudication-index.json').read_text());assert len(index['attempts'])==21 and len(index['interrupted_attempts'])==1

def distribution(values):
 return {'count':len(values),'min':min(values) if values else None,'median':statistics.median(values) if values else None,'max':max(values) if values else None,'sum':sum(values)}
def totals(objects):
 keys={k for o in objects if o for k,v in o.items() if isinstance(v,(int,float)) and not isinstance(v,bool)}
 return {k:sum(o.get(k,0) for o in objects if o) for k in sorted(keys)} if any(objects) else None
delivered_grades=[];failure_grades=[];authorization_quality={}
for summary in summaries:
 directory=root/summary['id']/'grade'
 package=json.loads((directory/'input.json').read_text()) if (directory/'input.json').exists() else {'decisions':[]}
 evaluation=json.loads((directory/'evaluation.json').read_text()) if (directory/'evaluation.json').exists() else {'results':[]}
 identifiers={d['id'] for d in package['decisions']}
 delivered_grades += [r for r in evaluation['results'] if r['id'] in identifiers]
 failure_grades += [r for r in evaluation['results'] if r['id'] not in identifiers]
 for grade in evaluation['results']:
  if grade['id'] not in identifiers: continue
  decision_directory=root/summary['id']/'play'
  if not (decision_directory/'decision.json').exists(): decision_directory=decision_directory/grade['id']
  decision=json.loads((decision_directory/'decision.json').read_text())
  disposition=decision.get('executionDisposition','historical-direct')
  authorization_quality.setdefault(disposition,{})
  authorization_quality[disposition][grade['quality']]=authorization_quality[disposition].get(grade['quality'],0)+1
result={'candidate_source':json.loads((root/'candidate.json').read_text())['source_commit'],'cycle':2,'maximum_cycles':3,'attempts':len(summaries),
 'task_complete':sum(s['task_complete'] for s in summaries),'legal_execution_pass':sum(s['legal_execution']=='pass' for s in summaries),
 'raw_attempt_outcomes':{k:sum(s['outcome']==k for s in summaries) for k in ['pass','pending','fail']},
 'raw_quality':{k:sum(s['quality']==k for s in summaries) for k in ['pass','pending','fail']},
 'raw_delivered_grade_counts':{k:sum(r['quality']==k for r in delivered_grades) for k in ['pass','uncertain','fail']},
 'separate_failure_reports':len(failure_grades),
 'raw_quality_by_execution_authorization':authorization_quality,
 'coverage_status_before_independent_adjudication':{k:sum(s['coverage']['status']==k for s in summaries) for k in ['covered','pending','uncovered']},
 'native_roles':{},'upstream_roles':{},'dispositions':totals([s['dispositions'] for s in summaries]),
 'feedback_revisions':sum(s['requests']['feedback_revisions'] for s in summaries),
 'clarification_requests':sum(s['requests']['clarification_requests'] for s in summaries),
 'semantic_reviews':sum(s['requests']['semantic_reviews'] for s in summaries),
 'technical_retries':sum(s['requests']['reviewer_retries'] for s in summaries),
 'late_observations':sum(s['requests']['late_observations'] for s in summaries),
 'mechanical_actions':sum(s['counts'].get('forced_actions',0) for s in summaries),
 'model_actions':sum(s['counts'].get('model_actions',0) for s in summaries),
 'rpc_requests':sum(s['counts'].get('actual_rpc_requests',0) for s in summaries),
 'http_attempts':sum(s['wire']['upstream_request_attempts'] for s in summaries),
 'driver_automatic_seconds':sum(s['timing'].get('automaticRuntimeSeconds') or 0 for s in summaries),
 'human_wait_seconds':sum(s['timing'].get('humanWaitingSeconds') or 0 for s in summaries),
 'first_decision_seconds':distribution([s['timing']['initialRequestSeconds'] for s in summaries if s['timing'].get('initialRequestSeconds') is not None]),
 'later_decision_seconds':distribution([v for s in summaries for v in s['timing'].get('subsequentRequestSeconds',[])]),
 'full_boards':[{'id':s['id'],'complete':s['counts']['complete'],'elapsed_seconds':s['timing']['elapsedSeconds'],'automatic_seconds':s['timing'].get('automaticRuntimeSeconds'),'human_wait_seconds':s['timing'].get('humanWaitingSeconds'),'tricks':s['counts']['tricks'],'quality':s['quality']} for s in summaries if s['kind']=='full'],
 'grader':{'elapsed_seconds':sum((s.get('grader_cost') or {}).get('elapsed_seconds') or 0 for s in summaries),
  'usage_observed_attempts':sum(bool((s.get('grader_cost') or {}).get('observed_usage')) for s in summaries),
  'observed_tokens':totals([u for s in summaries for u in (s.get('grader_cost') or {}).get('observed_usage') or []])},
 'limits':['Raw grades and coverage remain provisional until independent cited-fact adjudication.','Do not add native per-turn token totals to HTTP totals; they describe overlapping cost observations.','Missing usage remains unknown, not zero; monetary cost is unavailable without attested prices.','Candidate sources and raw model evidence remain unchanged.']}
for role in ['player','reviewer']:
 native=[s['requests']['roles'][role] for s in summaries]
 upstream=[s['wire']['roles'][role] for s in summaries]
 result['native_roles'][role]={'attempts':sum(s['attempts'] for s in native),'elapsed_seconds':sum(s['elapsed_seconds'] for s in native),
  'usage_observed_attempts':sum(s['usage_observed_attempts'] for s in native),'usage_unknown_attempts':sum(s['usage_unknown_attempts'] for s in native),
  'observed_tokens':totals([s.get('observed_tokens') for s in native]),'request_seconds':distribution([v for s in native for v in s['request_seconds']])}
 result['upstream_roles'][role]={'attempts':sum(s['upstream_attempts'] for s in upstream),
  'usage_observed_attempts':sum(s['usage_observed_attempts'] for s in upstream),'usage_unknown_attempts':sum(s['usage_unknown_attempts'] for s in upstream),
  'observed_tokens':totals([s.get('observed_tokens') for s in upstream])}
result['normal_independent_attempt_counts']={k:sum(row['quality']==k for row in index['attempts']) for k in ('pass','fail','uncertain')}
result['normal_independent_decision_counts']={k:sum(row['independent_decision_counts'][k] for row in index['attempts']) for k in ('pass','fail','uncertain')}
result['partial_independent_decision_counts']=index['interrupted_attempts'][0]['independent_decision_counts']
result['scheduled_slots']=22
result['outcome']='NO-GO'
result['uninterrupted_strict22_complete']=False
result['counts_scope']='Top-level attempts/task/role/timing/grade aggregates describe21 normal completed attempts only. Partial3 delivered and all interrupted request costs are explicit separate observations below.'
result['interrupted_partial']={'attempt':'short-5-r1','task_complete':False,'actual_process_exit':None,
 'delivered_decisions':3,'raw_quality_counts':{k:sum(r['quality']==k for r in partial_grade['results']) for k in ('pass','fail','uncertain')},
 'rpc_role_attempts':partial_cost['observable_rpc_turn_starts'],
 'native_usage':partial_cost['native_rpc_cost_observations'],
 'http_usage':partial_cost['wire_observations']['roles'],
 'saved_journal_lower_bound':partial_cost['last_delivered_trace_journal'],
 'partial_grader':{key:partial_grader_run.get(key) for key in ('elapsed_seconds','observed_usage','requested_model','requested_effort')},
 'terminal_duration_seconds':None,'protocol_gaps':partial_cost['wire_observations']['protocol_errors']}
result['all_observed_roles']={}
common=('cachedInputTokens','inputTokens','outputTokens','reasoningOutputTokens','totalTokens')
for role in ('player','reviewer'):
 normal=result['native_roles'][role];partial=partial_cost['native_rpc_cost_observations'][role]
 partial_journal=partial_cost['last_delivered_trace_journal']['roles'][role]
 http_normal=result['upstream_roles'][role];http_partial=partial_cost['wire_observations']['roles'][role]
 result['all_observed_roles'][role]={
  'native_rpc_attempts':normal['attempts']+partial['observed_rpc_turn_starts'],
  'native_usage_observed_attempts':normal['usage_observed_attempts']+partial['usage_observed_turns'],
  'native_usage_unknown_attempts':normal['usage_unknown_attempts']+partial['usage_unknown_turns'],
  'native_observed_tokens':{key:normal['observed_tokens'][key]+partial['observed_token_totals'][key] for key in common},
  'native_known_elapsed_seconds_lower_bound':normal['elapsed_seconds']+partial_journal['elapsed_seconds'],
  'native_elapsed_unknown_attempts':normal['attempts']-normal['request_seconds']['count']+partial['observed_rpc_turn_starts']-partial_journal['attempts'],
  'http_attempts':http_normal['attempts']+http_partial['upstream_attempts'],
  'http_usage_observed_attempts':http_normal['usage_observed_attempts']+http_partial['usage_observed_attempts'],
  'http_usage_unknown_attempts':http_normal['usage_unknown_attempts']+http_partial['usage_unknown_attempts'],
  'http_observed_tokens':totals([http_normal['observed_tokens'],http_partial['observed_tokens']])}
result['all_grader_observed']={'invocations':len(summaries)+1,
 'elapsed_seconds':result['grader']['elapsed_seconds']+partial_grader_run['elapsed_seconds'],
 'observed_tokens':totals([result['grader']['observed_tokens']]+partial_grader_run['observed_usage'])}
result['all_completed_semantic_reviews_observed']=result['semantic_reviews']+partial_cost['last_delivered_trace_journal']['semantic_reviews']
result['all_feedback_revisions_observed']=result['feedback_revisions']+partial_cost['last_delivered_trace_journal']['feedback_revisions']
result['all_observed_rpc_requests']=sum(v['native_rpc_attempts'] for v in result['all_observed_roles'].values())
result['all_observed_http_attempts']=sum(v['http_attempts'] for v in result['all_observed_roles'].values())
result['whole_automatic_duration_seconds']=None
result['independent_adjudication']={key:value for key,value in index.items() if key not in ('attempts','interrupted_attempts')}
result['limits'] += ['Cycle2 is operationally interrupted and cannot be an uninterrupted22 acceptance pass.',
 'The lost trace journal undercounts whole interrupted request cost;13 RPC starts and12 captured HTTP attempts remain distinct.',
 'Pending/rejected outputs are never final delivered quality targets; partial grading covers3 executed finals once.',
 'Whole automatic terminal duration is unknown; reported normal21 timings and interrupted saved-journal durations cannot invent the missing interval.']
print(json.dumps(result,indent=2,ensure_ascii=False))
