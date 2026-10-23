"""Independent saved-evidence checks for the reviewed production decision seam.

This module never calls a player, reviewer or grader. Runtime judgments authorize
execution, while these checks establish provenance rather than bridge quality.
"""
import json

SEATS={'north':'N','east':'E','south':'S','west':'W'}
STRAINS={'noTrump':'NT','spades':'S','hearts':'H','diamonds':'D','clubs':'C'}
RANKS='23456789TJQKA'


def plan_after(prior, advice):
    plan=advice['plan']
    if plan['update']=='replace': return plan['text']
    if plan['update']=='keep': return prior
    if plan['update']=='withdraw': return None
    raise ValueError('Unknown plan operation')


def public_snapshot(snapshot, prior, kind):
    def play(p): return {'seat':SEATS[p['seat']],'card':p['card']}
    hands={SEATS[h['seat']]:{s:''.join(c[1] for c in sorted(h['cards'],key=lambda c:RANKS.index(c[1]),reverse=True) if c[0]==s) for s in 'SHDC'} for h in snapshot['hands']}
    contract=snapshot['contract']
    return {'type':kind,'contract':{'level':contract['level'],'strain':STRAINS[contract['strain']],
            'doubling':contract.get('doubling','undoubled'),'declarer':SEATS[contract['declarer']]},
            'scoring':snapshot['scoring'],'vulnerability':snapshot['vulnerability'],'objective':snapshot['objective'],
            'publicBackground':snapshot.get('publicBackground'),'controller':SEATS[snapshot['controller']],
            'hands':hands,'completedTricks':[{'plays':[play(p) for p in t['plays']],'winner':SEATS[t['winner']]} for t in snapshot['completedTricks']],
            'currentTrick':[play(p) for p in snapshot['currentTrick']],
            'current':{'toAct':SEATS[snapshot['actingSeat']],'winningPlay':play(snapshot['currentWinningPlay']) if snapshot.get('currentWinningPlay') else None,
                       'tricksWon':{'declarer':snapshot['declarerTricks'],'defenders':snapshot['defenderTricks']}},'effectivePlan':prior}


def valid_review(review):
    if set(review)!={'verdict','blockingFindings','advisorySuggestions'}: return False
    verdict=review['verdict'];findings=review['blockingFindings'];advice=review['advisorySuggestions']
    return (verdict in ('approve','revise','uncertain') and isinstance(findings,list) and isinstance(advice,list)
            and all(isinstance(x,str) for x in advice)
            and bool(findings)==(verdict=='revise')
            and all(set(f)=={'claim','evidence','requestedChange'} and all(isinstance(v,str) and v.strip() for v in f.values()) for f in findings)
            and (verdict!='uncertain' or any(s.strip() for s in advice)))


def identity_valid(identity):
    return (all(identity.get(k)=='gpt-6.1-sol' for k in ('requestedModel','observedModel'))
            and all(identity.get(k)=='medium' for k in ('requestedEffort','observedEffort'))
            and bool(identity.get('threadID')) and bool(identity.get('turnID')))


def checks(record, recorded_turn):
    """Named deterministic checks; malformed saved records fail visibly."""
    results={}
    def check(name, fact, function):
        try: success=bool(function())
        except (ValueError,KeyError,TypeError,IndexError,AttributeError): success=False
        results[name]={'status':'pass' if success else 'fail','fact':fact}
    pending_decision=record.get('pending') or {};review_rounds=record.get('reviewRounds') or []
    prior_active_plan=(pending_decision.get('priorPlan') or {}).get('text')
    decision_snapshot=record['snapshot']
    def canonical():
        canonical_snapshot_input=json.loads(record['canonicalInput'])
        controlled_seats={decision_snapshot['controller'],next(seat for seat,seat_code in SEATS.items() if seat_code=={'N':'S','S':'N','E':'W','W':'E'}[SEATS[decision_snapshot['controller']]])}
        authorized_hands={hand['seat']:hand['cards'] for hand in decision_snapshot['hands']}
        acting_holding=authorized_hands[decision_snapshot['actingSeat']];current_trick=decision_snapshot['currentTrick'];led_suit=current_trick[0]['card'][0] if current_trick else None
        legal_cards={card for card in acting_holding if card[0]==led_suit} if led_suit else set(acting_holding);legal_cards=legal_cards or set(acting_holding)
        return (canonical_snapshot_input['type'] in ('initial','update') and set(authorized_hands)==controlled_seats and len(decision_snapshot['hands'])==2
                and set(decision_snapshot['legalCards'])==legal_cards and len(decision_snapshot['legalCards'])==len(legal_cards)
                and canonical_snapshot_input==public_snapshot(decision_snapshot,prior_active_plan,canonical_snapshot_input['type']))
    check('canonical_snapshot','Canonical full snapshot must reproduce authorized state, legal choices and prior active plan independently.',canonical)
    def history():
        if not 1<=len(review_rounds)<=5: return False
        canonical_snapshot_input=json.loads(record['canonicalInput']);candidate_ids=set()
        for round_index,review_round in enumerate(review_rounds):
            pending_candidate=review_round['pending'];review_record=review_round['review'];candidate_advice=json.loads(review_round['playerRawOutput']);reviewer_verdict=json.loads(review_record['rawOutput'])
            proposed_effective_plan=plan_after(prior_active_plan,candidate_advice)
            if (review_round['number']!=round_index+1 or pending_candidate['id']!=record['session']['id'] or pending_candidate['snapshot']!=decision_snapshot or pending_candidate.get('priorPlan')!=pending_decision.get('priorPlan')
                or pending_candidate['candidate']!=candidate_advice or pending_candidate.get('proposedEffectivePlan')!=proposed_effective_plan
                or pending_candidate['candidateID'] in candidate_ids or review_record['candidateID']!=pending_candidate['candidateID'] or review_record['pendingDecisionID']!=pending_candidate['id']
                or review_record['result']!=reviewer_verdict or not valid_review(reviewer_verdict)
                or (round_index<len(review_rounds)-1 and reviewer_verdict['verdict']=='approve')): return False
            candidate_ids.add(pending_candidate['candidateID'])
            expected_review_input={'latestSnapshot':canonical_snapshot_input,'legalCurrentCards':decision_snapshot['legalCards'],'candidate':candidate_advice,'proposedEffectivePlan':proposed_effective_plan}
            if json.loads(review_record['input'])!=expected_review_input: return False
            if round_index==0:
                if review_round['playerInput']!=record['canonicalInput']: return False
            else:
                previous_round=review_rounds[round_index-1];previous_review=previous_round['review'];previous_advice=json.loads(previous_round['playerRawOutput'])
                feedback_input={'latestSnapshot':canonical_snapshot_input,'legalCurrentCards':decision_snapshot['legalCards'],'candidate':previous_advice,'proposedEffectivePlan':plan_after(prior_active_plan,previous_advice),
                    'type':'clarification' if previous_review['result']['verdict']=='uncertain' else 'revision','review':previous_review['result'],
                    'rawReview':previous_review['rawOutput'],'rawCandidate':previous_round['playerRawOutput']}
                if json.loads(review_round['playerInput'])!=feedback_input: return False
            if candidate_advice['selectedCard'] not in decision_snapshot['legalCards']: return False
            if canonical_snapshot_input['type']=='initial' and candidate_advice['plan']['update']!='replace': return False
        final_round=review_rounds[-1];final_verdict=final_round['review']['result']['verdict']
        return (record['input']==final_round['playerInput'] and record['rawOutput']==final_round['playerRawOutput']
                and record['identity']==final_round['playerIdentity'] and record['advice']==json.loads(record['rawOutput'])
                and pending_decision==final_round['pending'] and record['review']==final_round['review']
                and record['executionDisposition']==('reviewApproved' if final_verdict=='approve' else 'contested')
                and (final_verdict=='approve' or len(review_rounds)==5))
    check('review_history','Each review/feedback and authorization must bind the exact candidate at one frozen position; only round-five unresolved review permits contested play.',history)
    def effect():
        candidate_advice=json.loads(record['rawOutput']);expected_effective_plan=plan_after(prior_active_plan,candidate_advice);plan_association=record.get('planAssociation')
        if candidate_advice['plan']['update']=='keep': expected_association=pending_decision.get('priorPlan')
        elif candidate_advice['plan']['update']=='withdraw': expected_association=None
        else:
            expected_association={'boardID':decision_snapshot['boardID'],'controller':decision_snapshot['controller'],'sourceSnapshotID':record['session']['snapshotID'],
                                  'sourceSessionID':record['session']['id'],'text':candidate_advice['plan']['text']}
        return record.get('effectivePlan')==expected_effective_plan and pending_decision.get('proposedEffectivePlan')==expected_effective_plan and plan_association==expected_association
    check('plan_effect','Apply final keep/replace/withdraw independently to the pre-pending plan; require exact text and source association.',effect)
    def identities():
        player_identities=[review_round['playerIdentity'] for review_round in review_rounds];reviewer_identities=[review_round['review']['identity'] for review_round in review_rounds]
        return (bool(player_identities) and all(identity_valid(identity) for identity in player_identities+reviewer_identities)
                and len({identity['threadID'] for identity in player_identities})==1 and len({identity['turnID'] for identity in player_identities})==len(player_identities)
                and all(identity['threadID']!=player_identities[0]['threadID'] for identity in reviewer_identities))
    check('role_identity','Both roles must acknowledge Sol Medium; revisions retain one player thread with new turns and independent reviewer threads.',identities)
    def requests():
        request_entries=[request_entry for request_entry in record['requestEvidence'] if request_entry['outcome']!='late']
        if len({request_entry['requestID'] for request_entry in request_entries})!=len(request_entries): return False
        expected_request_ids=set()
        for review_round in review_rounds:
            review_record=review_round['review']
            for role_name,request_id,input_text,raw_output,role_identity in [('player',review_round['playerRequestID'],review_round['playerInput'],review_round['playerRawOutput'],review_round['playerIdentity']),
                ('reviewer',review_record['requestID'],review_record['input'],review_record['rawOutput'],review_record['identity'])]:
                matching_evidence=[request_entry for request_entry in request_entries if request_entry['requestID']==request_id]
                if len(matching_evidence)!=1: return False
                request_entry=matching_evidence[0];expected_request_ids.add(request_id)
                if not (request_entry['role']==role_name and request_entry['decisionID']==record['session']['id'] and request_entry['semanticRound']==review_round['number']
                    and request_entry['input']==input_text and request_entry['rawOutput']==raw_output and request_entry['identity']==role_identity and request_entry['outcome']=='valid'
                    and request_entry['replyRequestID']==request_id): return False
                role_rpc=record.get('rpc') if role_name=='player' else (record.get('review_rpc') or {}).get(role_identity['threadID'])
                native_request,native_completion=recorded_turn({'rpc':role_rpc or [],'identity':role_identity})
                output_schema=json.loads(request_entry['outputSchema'])
                if native_request.get('outputSchema')!=output_schema or request_entry['instructions']!=(record['instructions'] if role_name=='player' else review_record['instructions']): return False
                if role_name=='player' and output_schema.get('properties',{}).get('selectedCard',{}).get('enum')!=decision_snapshot['legalCards']: return False
                if not any(item.get('text')==input_text for item in native_request.get('input',[])): return False
                if native_completion.get('status')!='completed' or not any(item.get('type')=='agentMessage' and item.get('text')==raw_output for item in native_completion.get('items',[])): return False
            reviewer_attempts=[request_entry for request_entry in request_entries if request_entry['role']=='reviewer' and request_entry['semanticRound']==review_round['number']]
            if [request_entry['technicalAttempt'] for request_entry in reviewer_attempts]!=list(range(1,len(reviewer_attempts)+1)) or not 1<=len(reviewer_attempts)<=4: return False
            for request_entry in reviewer_attempts:
                if request_entry.get('candidateID')!=review_round['pending']['candidateID'] or request_entry['input']!=review_record['input']: return False
                if request_entry['requestID']!=review_record['requestID'] and request_entry['outcome'] not in ('transportFailure','protocolFailure','timeout'): return False
                expected_request_ids.add(request_entry['requestID'])
        return {request_entry['requestID'] for request_entry in request_entries}==expected_request_ids
    check('role_requests','Final and prior valid role results must match their true native turns; technical retries preserve one candidate and separate attempt budget.',requests)
    return results


def request_summary(trace):
    """All automatic role attempts, with late observations joined only for usage.

    Native per-turn last usage is not cumulative thread usage. Unknown attempts
    remain explicit even when other requests reported tokens successfully.
    """
    journal=trace.get('requestEvidence')
    if journal is None:
        return {'status':'unavailable-historical-journal','attempts':None,'roles':{},'late_observations':None,'reviewer_retries':None}
    rows=[r for r in journal if r['outcome']!='late']
    late=[r for r in journal if r['outcome']=='late']
    roles={}
    for role in ('player','reviewer'):
        selected=[r for r in rows if r['role']==role]
        usages=[]
        for row in selected:
            observed=row.get('usage')
            if observed is None:
                later=[r.get('usage') for r in late if r['requestID']==row['requestID'] and r.get('usage') is not None]
                observed=later[-1] if later else None
            usages.append(observed)
        known=[u for u in usages if u is not None]
        keys={k for u in known for k in u}
        tokens={key:sum(u.get(key,0) for u in known) for key in sorted(keys)} if known else ({} if not selected else None)
        roles[role]={'attempts':len(selected),'elapsed_seconds':sum(r['elapsedSeconds'] for r in selected),
                     'usage_observed_attempts':len(known),'usage_unknown_attempts':len(selected)-len(known),
                     'usage_complete':len(known)==len(selected),'observed_tokens':tokens,
                     'outcomes':{outcome:sum(r['outcome']==outcome for r in selected) for outcome in sorted({r['outcome'] for r in selected})},
                     'request_seconds':[r['elapsedSeconds'] for r in selected]}
    return {'status':'observed','attempts':len(rows),'late_observations':len(late),'roles':roles,
            'reviewer_retries':sum(r['role']=='reviewer' and r['technicalAttempt']>1 for r in rows),
            'semantic_reviews':sum(r['role']=='reviewer' and r['outcome']=='valid' for r in rows),
            'feedback_revisions':sum(r['role']=='player' and r.get('semanticRound',1)>1 for r in rows),
            'clarification_requests':sum(r['role']=='player' and json.loads(r['input']).get('type')=='clarification' for r in rows if r.get('input','').startswith('{')),
            'usage_note':'Observed native per-turn last usage, including failed attempts when available. Missing is unknown, never zero; late observations are not extra requests.'}


def wire_summary(wire, candidate, journal=None):
    """Attribute upstream HTTP attempts by exact active instructions/current input,
    independently of their ordinal number or runtime's internal transport retries.
    """
    from pathlib import Path
    wire=Path(wire);errors=[];roles={};rows=[]
    def message(q, role):
        values=['\n'.join(p.get('text','') for p in item.get('content',[])) for item in q.get('input',[]) if item.get('role')==role and item.get('content')]
        return values[-1] if values else ''
    for path in sorted(wire.glob('request-*.json'),key=lambda p:int(p.stem.split('-')[-1])):
        q=json.loads(path.read_text());developer=message(q,'developer');user=message(q,'user')
        role=next((r for r,text in [('player',candidate['english_instructions']),('reviewer',candidate['reviewer_instructions'])] if developer==text),'unknown')
        index=int(path.stem.split('-')[-1]);metadata_path=wire/f'response-metadata-{index}.json'
        metadata=json.loads(metadata_path.read_text()) if metadata_path.exists() else {}
        if role=='unknown': errors.append(f'{path.name}: unknown active role/instructions')
        if q.get('model')!='gpt-6.1-sol' or q.get('reasoning',{}).get('effort')!='medium': errors.append(f'{path.name}: wrong requested identity')
        if metadata.get('model') not in (None,'gpt-6.1-sol'): errors.append(f'{path.name}: wrong observed response model')
        if [item.get('tools') for item in q.get('input',[]) if item.get('type')=='additional_tools']!=[[]]: errors.append(f'{path.name}: tool surface is not empty')
        if journal is not None:
            matches=[e for e in journal if e['outcome']!='late' and e['role']==role and e['input']==user and e['instructions']==developer]
            schema=q.get('text',{}).get('format',{}).get('schema')
            if not matches or not any(json.loads(e['outputSchema'])==schema for e in matches): errors.append(f'{path.name}: no exact runtime input/schema association')
        schema=q.get('text',{}).get('format',{}).get('schema')
        template=candidate.get('schema_template' if role=='player' else 'reviewer_schema_template')
        if role in ('player','reviewer') and template is not None:
            import copy
            expected=copy.deepcopy(template)
            if role=='player':
                value=json.loads(user);position=value.get('latestSnapshot',value)
                expected['properties']['selectedCard']={'type':'string','enum':schema.get('properties',{}).get('selectedCard',{}).get('enum')}
                if position.get('type')=='initial':
                    variants=expected['properties']['plan']['anyOf']
                    expected['properties']['plan']['anyOf']=[v for v in variants if v['properties']['update']['enum']==['replace']]
            if schema!=expected: errors.append(f'{path.name}: schema differs from frozen role template')
        usage=metadata.get('usage');flat=None
        if isinstance(usage,dict):
            flat={k:v for k,v in usage.items() if isinstance(v,int)}
            for key,details in [('cached_input_tokens','input_tokens_details'),('reasoning_output_tokens','output_tokens_details')]:
                value=usage.get(details,{})
                if isinstance(value,dict):
                    count=value.get('cached_tokens' if key.startswith('cached') else 'reasoning_tokens')
                    if count is not None: flat[key]=count
        rows.append({'wire_request':index,'role':role,'metadata_present':metadata_path.exists(),'response_status':metadata.get('status'),
                     'http_status':metadata.get('httpStatus'),'observed_tokens':flat})
    for role in ('player','reviewer','unknown'):
        selected=[r for r in rows if r['role']==role];known=[r['observed_tokens'] for r in selected if r['observed_tokens'] is not None]
        keys={k for u in known for k in u}
        roles[role]={'upstream_attempts':len(selected),'usage_observed_attempts':len(known),'usage_unknown_attempts':len(selected)-len(known),
                     'observed_tokens':{k:sum(u.get(k,0) for u in known) for k in sorted(keys)} if known else ({} if not selected else None)}
    return {'protocol_status':'fail' if errors else 'pending' if not rows or any(not r['metadata_present'] for r in rows) else 'pass',
            'protocol_errors':errors,'roles':roles,'role_requests':rows,
            'usage_note':'Upstream per-HTTP usage includes all observed failures/retries; missing remains unknown. Do not add this to native per-turn totals.'}
