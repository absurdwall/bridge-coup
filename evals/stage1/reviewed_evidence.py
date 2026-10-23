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
    pending=record.get('pending') or {};rounds=record.get('reviewRounds') or []
    prior=(pending.get('priorPlan') or {}).get('text')
    snapshot=record['snapshot']
    def canonical():
        q=json.loads(record['canonicalInput'])
        controlled={snapshot['controller'],next(s for s,c in SEATS.items() if c=={'N':'S','S':'N','E':'W','W':'E'}[SEATS[snapshot['controller']]])}
        hands={h['seat']:h['cards'] for h in snapshot['hands']}
        holding=hands[snapshot['actingSeat']];trick=snapshot['currentTrick'];led=trick[0]['card'][0] if trick else None
        legal={c for c in holding if c[0]==led} if led else set(holding);legal=legal or set(holding)
        return (q['type'] in ('initial','update') and set(hands)==controlled and len(snapshot['hands'])==2
                and set(snapshot['legalCards'])==legal and len(snapshot['legalCards'])==len(legal)
                and q==public_snapshot(snapshot,prior,q['type']))
    check('canonical_snapshot','Canonical full snapshot must reproduce authorized state, legal choices and prior active plan independently.',canonical)
    def history():
        if not 1<=len(rounds)<=5: return False
        q=json.loads(record['canonicalInput']);candidate_ids=set()
        for i,r in enumerate(rounds):
            p=r['pending'];review=r['review'];advice=json.loads(r['playerRawOutput']);rv=json.loads(review['rawOutput'])
            proposed=plan_after(prior,advice)
            if (r['number']!=i+1 or p['id']!=record['session']['id'] or p['snapshot']!=snapshot or p.get('priorPlan')!=pending.get('priorPlan')
                or p['candidate']!=advice or p.get('proposedEffectivePlan')!=proposed
                or p['candidateID'] in candidate_ids or review['candidateID']!=p['candidateID'] or review['pendingDecisionID']!=p['id']
                or review['result']!=rv or not valid_review(rv)
                or (i<len(rounds)-1 and rv['verdict']=='approve')): return False
            candidate_ids.add(p['candidateID'])
            expected={'latestSnapshot':q,'legalCurrentCards':snapshot['legalCards'],'candidate':advice,'proposedEffectivePlan':proposed}
            if json.loads(review['input'])!=expected: return False
            if i==0:
                if r['playerInput']!=record['canonicalInput']: return False
            else:
                previous=rounds[i-1];pr=previous['review'];pa=json.loads(previous['playerRawOutput'])
                feedback={'latestSnapshot':q,'legalCurrentCards':snapshot['legalCards'],'candidate':pa,'proposedEffectivePlan':plan_after(prior,pa),
                    'type':'clarification' if pr['result']['verdict']=='uncertain' else 'revision','review':pr['result'],
                    'rawReview':pr['rawOutput'],'rawCandidate':previous['playerRawOutput']}
                if json.loads(r['playerInput'])!=feedback: return False
            if advice['selectedCard'] not in snapshot['legalCards']: return False
            if q['type']=='initial' and advice['plan']['update']!='replace': return False
        final=rounds[-1];verdict=final['review']['result']['verdict']
        return (record['input']==final['playerInput'] and record['rawOutput']==final['playerRawOutput']
                and record['identity']==final['playerIdentity'] and record['advice']==json.loads(record['rawOutput'])
                and pending==final['pending'] and record['review']==final['review']
                and record['executionDisposition']==('reviewApproved' if verdict=='approve' else 'contested')
                and (verdict=='approve' or len(rounds)==5))
    check('review_history','Each review/feedback and authorization must bind the exact candidate at one frozen position; only round-five unresolved review permits contested play.',history)
    def effect():
        advice=json.loads(record['rawOutput']);expected=plan_after(prior,advice);association=record.get('planAssociation')
        if advice['plan']['update']=='keep': expected_association=pending.get('priorPlan')
        elif advice['plan']['update']=='withdraw': expected_association=None
        else:
            expected_association={'boardID':snapshot['boardID'],'controller':snapshot['controller'],'sourceSnapshotID':record['session']['snapshotID'],
                                  'sourceSessionID':record['session']['id'],'text':advice['plan']['text']}
        return record.get('effectivePlan')==expected and pending.get('proposedEffectivePlan')==expected and association==expected_association
    check('plan_effect','Apply final keep/replace/withdraw independently to the pre-pending plan; require exact text and source association.',effect)
    def identities():
        players=[r['playerIdentity'] for r in rounds];reviewers=[r['review']['identity'] for r in rounds]
        return (bool(players) and all(identity_valid(i) for i in players+reviewers)
                and len({i['threadID'] for i in players})==1 and len({i['turnID'] for i in players})==len(players)
                and all(i['threadID']!=players[0]['threadID'] for i in reviewers))
    check('role_identity','Both roles must acknowledge Sol Medium; revisions retain one player thread with new turns and independent reviewer threads.',identities)
    def requests():
        rows=[e for e in record['requestEvidence'] if e['outcome']!='late']
        if len({e['requestID'] for e in rows})!=len(rows): return False
        expected_ids=set()
        for r in rounds:
            review=r['review']
            for role,rid,input_text,raw,identity in [('player',r['playerRequestID'],r['playerInput'],r['playerRawOutput'],r['playerIdentity']),
                ('reviewer',review['requestID'],review['input'],review['rawOutput'],review['identity'])]:
                found=[e for e in rows if e['requestID']==rid]
                if len(found)!=1: return False
                e=found[0];expected_ids.add(rid)
                if not (e['role']==role and e['decisionID']==record['session']['id'] and e['semanticRound']==r['number']
                    and e['input']==input_text and e['rawOutput']==raw and e['identity']==identity and e['outcome']=='valid'
                    and e['replyRequestID']==rid): return False
                rpc=record.get('rpc') if role=='player' else (record.get('review_rpc') or {}).get(identity['threadID'])
                req,done=recorded_turn({'rpc':rpc or [],'identity':identity})
                schema=json.loads(e['outputSchema'])
                if req.get('outputSchema')!=schema or e['instructions']!=(record['instructions'] if role=='player' else review['instructions']): return False
                if role=='player' and schema.get('properties',{}).get('selectedCard',{}).get('enum')!=snapshot['legalCards']: return False
                if not any(item.get('text')==input_text for item in req.get('input',[])): return False
                if done.get('status')!='completed' or not any(item.get('type')=='agentMessage' and item.get('text')==raw for item in done.get('items',[])): return False
            retries=[e for e in rows if e['role']=='reviewer' and e['semanticRound']==r['number']]
            if [e['technicalAttempt'] for e in retries]!=list(range(1,len(retries)+1)) or not 1<=len(retries)<=4: return False
            for e in retries:
                if e.get('candidateID')!=r['pending']['candidateID'] or e['input']!=review['input']: return False
                if e['requestID']!=review['requestID'] and e['outcome'] not in ('transportFailure','protocolFailure','timeout'): return False
                expected_ids.add(e['requestID'])
        return {e['requestID'] for e in rows}==expected_ids
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
