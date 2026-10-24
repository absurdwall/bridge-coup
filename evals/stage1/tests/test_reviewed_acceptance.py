"""Synthetic saved-boundary regressions; historical native captures stay unchanged."""
import copy,json,sys,unittest,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
import evaluate,acceptance,reviewed_evidence,corpus


def rpc_turn(identity,input_text,raw,schema=None):
    return [{'kind':'request','value':{'method':'turn/start','params':{'threadId':identity['threadID'],'input':[{'type':'text','text':input_text}],'outputSchema':schema or {}}}},
            {'kind':'response','value':{'method':'turn/start','result':{'turn':{'id':identity['turnID']}}}},
            {'kind':'completion','value':{'id':identity['turnID'],'status':'completed','items':[{'type':'agentMessage','text':raw}]}}]


def reviewed_record(path=None):
    """Explicit synthetic adapter of saved natural decision4, repairing its known
    omitted-null encoding only, and supplying a scripted RPC/attempt journal.
    Never represented as a new native model result."""
    path=path or ROOT/'fixtures/saved-boundaries/issue48/ticket50/native-correction/play/decision-0004'
    r=evaluate.read_json(path/'decision.json');r['executionEvents']=evaluate.read_json(path/'events.json')
    r['rpc']=[];r['review_rpc']={};r['requestEvidence']=[]
    for round in r['reviewRounds']:
        candidate=round['pending']['candidate'];candidate['plan'].setdefault('text',None)
        review=round['review'];q=json.loads(review['input']);q['candidate']=candidate;review['input']=evaluate.json_text(q)
        r['rpc']+=rpc_turn(round['playerIdentity'],round['playerInput'],round['playerRawOutput'],{'properties':{'selectedCard':{'enum':r['snapshot']['legalCards']}}})
        r['review_rpc'][review['identity']['threadID']]=rpc_turn(review['identity'],review['input'],review['rawOutput'])
        for role,request_id,input_text,raw,identity in [
            ('player',round['playerRequestID'],round['playerInput'],round['playerRawOutput'],round['playerIdentity']),
            ('reviewer',review['requestID'],review['input'],review['rawOutput'],review['identity'])]:
            r['requestEvidence'].append({'role':role,'requestID':request_id,'decisionID':r['session']['id'],
                'candidateID':round['pending']['candidateID'] if role=='reviewer' else None,
                'semanticRound':round['number'],'technicalAttempt':1,'input':input_text,'rawOutput':raw,
                'identity':identity,'replyRequestID':request_id,'outcome':'valid','elapsedSeconds':1,
                'instructions':r['instructions'] if role=='player' else review['instructions'],'outputSchema':json.dumps({'properties':{'selectedCard':{'enum':r['snapshot']['legalCards']}}}) if role=='player' else '{}'})
    r['review']=copy.deepcopy(r['reviewRounds'][-1]['review']);r['pending']=copy.deepcopy(r['reviewRounds'][-1]['pending']);r['advice']=json.loads(r['rawOutput'])
    return r


def contested_record():
    record=reviewed_record();template=copy.deepcopy(record['reviewRounds'][0]);canonical=json.loads(record['canonicalInput'])
    rounds=[];record['rpc']=[];record['review_rpc']={};record['requestEvidence']=[]
    for i in range(5):
        row=copy.deepcopy(template);row['number']=i+1;row['playerRequestID']=f'player-{i}';row['pending']['candidateID']=f'candidate-{i}'
        row['playerIdentity']['turnID']=f'player-turn-{i}'
        review=row['review'];review['requestID']=f'review-{i}';review['candidateID']=row['pending']['candidateID']
        review['identity']['threadID']=f'review-thread-{i}';review['identity']['turnID']=f'review-turn-{i}'
        if i:
            previous=rounds[-1]
            feedback=json.loads(previous['review']['input']);feedback.update(type='revision',review=previous['review']['result'],rawReview=previous['review']['rawOutput'],rawCandidate=previous['playerRawOutput'])
            row['playerInput']=evaluate.json_text(feedback)
        else: row['playerInput']=record['canonicalInput']
        rounds.append(row)
        record['rpc']+=rpc_turn(row['playerIdentity'],row['playerInput'],row['playerRawOutput'],{'properties':{'selectedCard':{'enum':record['snapshot']['legalCards']}}})
        record['review_rpc'][review['identity']['threadID']]=rpc_turn(review['identity'],review['input'],review['rawOutput'])
        for role,rid,input_text,raw,identity in [('player',row['playerRequestID'],row['playerInput'],row['playerRawOutput'],row['playerIdentity']),
                ('reviewer',review['requestID'],review['input'],review['rawOutput'],review['identity'])]:
            record['requestEvidence'].append({'role':role,'requestID':rid,'decisionID':record['session']['id'],
                'candidateID':row['pending']['candidateID'] if role=='reviewer' else None,'semanticRound':i+1,'technicalAttempt':1,
                'input':input_text,'rawOutput':raw,'identity':identity,'replyRequestID':rid,'outcome':'valid','elapsedSeconds':1,
                'instructions':record['instructions'] if role=='player' else review['instructions'],
                'outputSchema':json.dumps({'properties':{'selectedCard':{'enum':record['snapshot']['legalCards']}}}) if role=='player' else '{}'})
    last=rounds[-1];record.update(reviewRounds=rounds,pending=last['pending'],review=last['review'],input=last['playerInput'],rawOutput=last['playerRawOutput'],identity=last['playerIdentity'],executionDisposition='contested')
    record['advice']=json.loads(record['rawOutput']);record['action']['card']=record['advice']['selectedCard'];record['effectivePlan']=record['advice']['plan']['text']
    record['planAssociation']={'boardID':record['snapshot']['boardID'],'controller':record['snapshot']['controller'],
        'sourceSnapshotID':record['session']['snapshotID'],'sourceSessionID':record['session']['id'],'text':record['effectivePlan']}
    record['executionEvents'][-1]['card']=record['action']['card']
    return record


class ReviewedAcceptanceTests(unittest.TestCase):
    def test_final_revision_input_and_canonical_snapshot_are_separately_bound(self):
        record=reviewed_record();checks=evaluate.deterministic_checks(record)
        for name in ('request_evidence','output_evidence','canonical_snapshot','review_history','plan_effect','role_identity','role_requests'):
            self.assertEqual(checks[name]['status'],'pass',name)
        self.assertNotEqual(record['input'],record['canonicalInput'])
        record['canonicalInput']=record['input']
        self.assertEqual(evaluate.deterministic_checks(record)['canonical_snapshot']['status'],'fail')

    def test_grader_grades_only_delivered_advice_and_marks_feedback_as_nonauthoritative(self):
        record=reviewed_record();record['executionDisposition']='contested'
        package=evaluate.grader_package([('delivered',record)])
        row=package['decisions'][0]
        self.assertEqual(len(package['decisions']),1)
        self.assertEqual(row['authorized_input'],record['canonicalInput'])
        self.assertEqual(row['actual_player_input'],record['input'])
        self.assertEqual(row['raw_output'],record['rawOutput'])
        self.assertNotIn('reviewRounds',row)
        self.assertNotIn('executionDisposition',row)
        self.assertIn('non-authoritative',row['input_authority'])
        grade={'results':[{'id':'delivered','status':'fail','findings':[{'dimension':'quality','quotes':['C4'],
            'fact':'A demonstrated material final defect.','explanation':'Runtime verdict cannot override independent judgment.'}]}]}
        self.assertEqual(evaluate.adjudicate(package,grade)['results'][0]['quality'],'fail')

    def test_freeze_includes_both_instruction_sources_and_fixed_regression_assets(self):
        files=acceptance.source_files()
        self.assertIn('Sources/BridgeExpert/Resources/ReviewerInstructions.txt',files)
        self.assertIn('evals/stage1/regressions/reviewed-play/fixed-review/late-club-input.json',files)
        self.assertIn('evals/stage1/regressions/reviewed-play/check_public_proof.py',files)
        self.assertEqual(len(acceptance.schedule(acceptance.load(ROOT/'corpus/manifest.json'))),22)

    def test_role_costs_include_failures_and_late_usage_without_double_counting_attempts(self):
        def row(id,role,outcome,usage=None,attempt=1):
            return {'requestID':id,'role':role,'outcome':outcome,'technicalAttempt':attempt,'semanticRound':1,'decisionID':'one',
                    'elapsedSeconds':2,'input':'{}','usage':{'totalTokens':usage} if usage is not None else None}
        rows=[row('p','player','valid',10),row('r1','reviewer','protocolFailure'),row('r2','reviewer','valid',20,2),
              row('r1','reviewer','late',5),row('p2','player','timeout')]
        result=reviewed_evidence.request_summary({'requestEvidence':rows})
        self.assertEqual(result['attempts'],4)
        self.assertEqual(result['late_observations'],1)
        self.assertEqual(result['reviewer_retries'],1)
        self.assertEqual(result['roles']['reviewer']['observed_tokens']['totalTokens'],25)
        self.assertEqual(result['roles']['reviewer']['elapsed_seconds'],4)
        self.assertEqual(result['roles']['player']['usage_unknown_attempts'],1)
        self.assertFalse(result['roles']['player']['usage_complete'])
        self.assertIsNone(reviewed_evidence.request_summary({})['attempts'])

    def test_wire_roles_tools_and_token_costs_are_audited_without_guessing_pairs(self):
        directory=ROOT/'fixtures/saved-boundaries/issue48/ticket50/native-correction'
        candidate={'english_instructions':(directory/'source/Sources/BridgeExpert/Resources/DeclarerInstructions.txt').read_text(),
                   'reviewer_instructions':(directory/'source/Sources/BridgeExpert/Resources/ReviewerInstructions.txt').read_text()}
        result=acceptance.audit_wire(directory/'wire',candidate=candidate)
        self.assertEqual(result['protocol_status'],'pass')
        self.assertEqual(result['roles']['player']['upstream_attempts'],5)
        self.assertEqual(result['roles']['reviewer']['upstream_attempts'],5)
        self.assertGreater(result['roles']['reviewer']['observed_tokens']['total_tokens'],0)
        with tempfile.TemporaryDirectory() as temporary:
            wire=Path(temporary);q=json.loads((directory/'wire/request-0.json').read_text())
            q['input'][0]['tools']=[{'type':'forbidden'}]
            (wire/'request-0.json').write_text(json.dumps(q))
            self.assertEqual(acceptance.audit_wire(wire,candidate=candidate)['protocol_status'],'fail')

    def test_candidate_feedback_and_plan_tampering_fail_saved_boundary_checks(self):
        for mutate,check in [
            (lambda r:r['reviewRounds'][-1]['pending']['candidate'].update(selectedCard='H3'),'review_history'),
            (lambda r:r.update(effectivePlan='Invented replacement plan'),'plan_effect'),
            (lambda r:r.update(identity={**r['identity'],'turnID':'wrong-turn'}),'output_evidence'),
            (lambda r:r['reviewRounds'][-1]['playerIdentity'].update(threadID='fresh-player'),'role_identity')]:
            record=reviewed_record();mutate(record)
            self.assertEqual(evaluate.deterministic_checks(record)[check]['status'],'fail',check)

    def test_report_never_calls_the_reviewer_or_contested_disposition_quality(self):
        with tempfile.TemporaryDirectory() as temporary:
            acceptance.render_report(Path(temporary),{'source_commit':'reviewed-source'},[])
            report=(Path(temporary)/'REPORT.md').read_text()
            self.assertIn('gpt-6.1-sol / medium',report)
            self.assertNotIn('gpt-6-luna / medium',report)
            self.assertIn('contested',report)
            self.assertIn('unknown',report)

    def test_board_replay_checks_cross_decision_plan_and_counts_both_native_roles(self):
        directory=ROOT/'fixtures/saved-boundaries/issue48/ticket50/native-correction/play'
        trace=evaluate.read_json(directory/'trace.json')
        trace['requestEvidence']=[]
        for step in trace['steps']:
            if step.get('decision'):
                n=sum(1 for e in trace['requestEvidence'] if e['role']=='player' and e['semanticRound']==1)+1
                step['decision']=reviewed_record(directory/f'decision-{n:04d}')
                trace['requestEvidence']+=step['decision']['requestEvidence']
        trace['modelRequests']=trace['playerRequests']=5;trace['reviewerRequests']=5;trace['semanticReviews']=5
        trace['requestEvidence'].append({**trace['requestEvidence'][0],'outcome':'late'})
        board=evaluate.read_json(ROOT/'corpus/boards/walker-holdup-adapted.json')
        result=acceptance.inspect_play(board,trace,directory)
        self.assertEqual(result['status'],'pass',result['errors'])
        self.assertEqual(result['actual_rpc_requests'],10)
        self.assertEqual(result['reviewer_request_attempts'],5)
        steps=[s for s in trace['steps'] if s.get('decision')]
        steps[1]['decision']['pending']['priorPlan']['text']='Substituted prior advice'
        self.assertEqual(acceptance.inspect_play(board,trace,directory)['status'],'fail')

    def test_unexecuted_authorized_advice_is_not_sent_for_quality_grading(self):
        import subprocess
        with tempfile.TemporaryDirectory() as temporary:
            root=Path(temporary);decision=root/'failed';decision.mkdir()
            record=reviewed_record();(decision/'decision.json').write_text(json.dumps(record))
            (decision/'failure.json').write_text(json.dumps({'status':'failed','error':'Authorization expired before execution.'}))
            output=root/'grade'
            run=subprocess.run([sys.executable,str(ROOT/'evaluate.py'),'grade','--decision',str(decision),
                                '--codex','/no/such/runtime','--output',str(output)],capture_output=True,text=True)
            self.assertEqual(run.returncode,0,run.stderr)
            self.assertEqual(evaluate.read_json(output/'input.json')['decisions'],[])
            self.assertFalse(evaluate.read_json(output/'run.json')['grading_model_called'])
            self.assertEqual(evaluate.read_json(output/'evaluation.json')['results'][0]['overall'],'fail')

    def test_public_late_club_proof_preserves_eleven_exact_source_assets(self):
        import importlib.util
        path=ROOT/'regressions/reviewed-play/check_public_proof.py'
        spec=importlib.util.spec_from_file_location('public_proof',path);proof=importlib.util.module_from_spec(spec);spec.loader.exec_module(proof)
        result=proof.verify(ROOT.parents[1])
        self.assertEqual(result['source_assets_checked'],11)
        self.assertEqual([b['tricks'] for b in result['branches']],[(11,2),(11,2),(10,3)])

    def test_fifth_round_contested_is_bound_but_a_serious_final_error_still_fails_quality(self):
        record=contested_record();checks=evaluate.deterministic_checks(record)
        self.assertTrue(all(c['status']=='pass' for c in checks.values()),checks)
        package=evaluate.grader_package([('final',record)])
        grade={'results':[{'id':'final','status':'fail','findings':[{'dimension':'heart accounting','quotes':['H3'],
            'fact':'After H3, dummy has HA4 and must follow with HA on the second honor.',
            'explanation':'The final claimed four-heart route is impossible; contested release is not quality.'}]}]}
        result=evaluate.adjudicate(package,grade)['results'][0]
        self.assertEqual(result['mechanical'],'pass');self.assertEqual(result['quality'],'fail')
        record['reviewRounds'].append(copy.deepcopy(record['reviewRounds'][-1]))
        self.assertEqual(evaluate.deterministic_checks(record)['review_history']['status'],'fail')

    def test_case_binding_independently_checks_public_winning_play_and_completed_tricks(self):
        record=reviewed_record()
        corpus.verify_case_decisions(ROOT/'corpus/manifest.json','short-6',[('actual',record)])
        for mutate in (lambda r:r['snapshot']['currentWinningPlay'].update(card='CT'),
                       lambda r:r['snapshot']['completedTricks'][0].update(winner='north')):
            changed=copy.deepcopy(record);mutate(changed)
            with self.assertRaisesRegex(ValueError,'case/trace mismatch'):
                corpus.verify_case_decisions(ROOT/'corpus/manifest.json','short-6',[('changed',changed)])

if __name__=='__main__': unittest.main()
