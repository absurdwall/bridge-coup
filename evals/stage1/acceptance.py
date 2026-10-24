#!/usr/bin/env python3
"""Freeze and execute the finite stage-1 matrix, preserving every attempt."""
import json
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[1]


def load(path):
    return json.loads(Path(path).read_text())


def execution_configuration():
    configuration = load(ROOT / 'case-execution.json')
    case_ids = {case['id'] for case in load(ROOT / 'corpus/manifest.json')['cases']}
    options = configuration['case_options']
    if configuration['version'] != 'stage1-reviewed-case-execution-v1' or set(options) != case_ids:
        raise ValueError('Unreviewed case execution configuration')
    if any(set(option) != {'mechanical_sole_legal'} or type(option['mechanical_sole_legal']) is not bool for option in options.values()):
        raise ValueError('Case mechanical-sole-legal options must be explicit booleans')
    return configuration


def schedule(manifest):
    configuration = execution_configuration()
    return [{'id': '%s-r%d' % (case['id'], number), 'case_id': case['id'],
             'kind': case['kind'], 'board': case['board'], 'decisions': case.get('decisions'),
             'opponent_policy': case['opponent_policy'],
             'execution_config_version': configuration['version'],
             **configuration['case_options'][case['id']]}
            for case in manifest['cases'] for number in range(1, case['required_runs'] + 1)]


def inspect_play(board, trace, evidence, mechanical_sole_legal=None):
    """Replay actual events independently; audit all execution source labels."""
    import sys
    if str(ROOT) not in sys.path:
        sys.path.insert(0, str(ROOT))
    import corpus
    errors = []
    if mechanical_sole_legal is not None and trace.get('mechanicalSoleLegal') is not mechanical_sole_legal:
        errors.append('actual mechanical sole-legal mode differs from frozen case option')
    events = list(trace.get('initialEvents', []))
    if events != corpus.initial_events(board):
        errors.append('initial prefix differs from frozen board')
    declarer = board['contract']['declarer']
    dummy = corpus.SEATS[(corpus.SEATS.index(declarer) + 2) % 4]
    controlled = {declarer, dummy}
    counts = {'model': 0, 'forced': 0, 'opponent': 0}
    decisions = []
    active_association = None
    player_thread, player_turns = None, set()
    for step in trace.get('steps', []):
        execution = step.get('execution')
        if not execution:
            # A failed request can have a decision but no applied action.
            continue
        event, source = execution['event'], execution['source']
        if step.get('actualEvents') != events + [event]:
            errors.append('actual events are not one immutable append')
        state = corpus.replay(board, events)
        holding = state['hands'].get(event['seat'], set())
        led = state['currentTrick'][0]['card'][0] if state['currentTrick'] else None
        legal = {c for c in holding if c[0] == led} if led else set(holding)
        legal = legal or set(holding)
        if source == 'model':
            decision = step.get('decision')
            if not decision or event['seat'] not in controlled:
                errors.append('model source lacks an actual controlled decision')
            else:
                decisions.append(decision)
                if decision.get('pending') is not None:
                    import reviewed_evidence
                    pending = decision['pending']
                    for round in decision.get('reviewRounds', []):
                        identity = round['playerIdentity']
                        if player_thread is not None and identity['threadID'] != player_thread or identity['turnID'] in player_turns:
                            errors.append('player conversation changed or reused a turn across delivered decisions')
                        player_thread = identity['threadID']; player_turns.add(identity['turnID'])
                    answer = json.loads(decision['rawOutput'])
                    expected_plan = reviewed_evidence.plan_after((active_association or {}).get('text'), answer)
                    if pending.get('priorPlan') != active_association or decision.get('effectivePlan') != expected_plan:
                        errors.append('reviewed plan does not continue the exact prior executed advice')
                    active_association = decision.get('planAssociation')
                if decision['action']['card'] != event['card'] or decision['snapshot']['events'] != events:
                    errors.append('model source does not bind to its actual event')
        elif source == 'forced':
            if mechanical_sole_legal is False:
                errors.append('forced controlled action while case mechanical skipping is disabled')
            if event['seat'] not in controlled or len(legal) != 1 or not decisions:
                errors.append('forced source is not sole-legal after initial model plan')
        elif source == 'opponent':
            if event['seat'] in controlled:
                errors.append('controlled action substituted by opponent')
        else:
            errors.append('unknown execution source')
        counts[source] = counts.get(source, 0) + 1
        events.append(event)
    try:
        state = corpus.replay(board, events)
        complete = len(events) == 52 and not any(state['hands'].values()) and state['declarerTricks'] + state['defenderTricks'] == 13
        if trace.get('complete') != complete:
            errors.append('completion does not match independent replay')
        if [trace.get('declarerTricks'), trace.get('defenderTricks')] != [state['declarerTricks'], state['defenderTricks']]:
            errors.append('trick result differs from independent replay')
    except ValueError as error:
        errors.append(str(error))
        complete = False
        state = {'declarerTricks': None, 'defenderTricks': None}
    for field, value in [('modelActions', counts['model']), ('mechanicalActions', counts['forced']), ('opponentActions', counts['opponent'])]:
        if trace.get(field) != value:
            errors.append('trace %s count mismatch' % field)
    rpc_paths = [Path(evidence) / 'rpc.jsonl'] + sorted((Path(evidence) / 'reviewer').glob('*/rpc.jsonl'))
    requests = [row for path in rpc_paths if path.exists() for row in (json.loads(line) for line in path.read_text().splitlines())
                if row.get('kind') == 'request' and row.get('value', {}).get('method') == 'turn/start']
    journal = trace.get('requestEvidence')
    attempts = [row for row in journal if row['outcome'] != 'late'] if journal is not None else None
    if attempts is not None:
        players = sum(r['role'] == 'player' for r in attempts)
        reviewers = sum(r['role'] == 'reviewer' for r in attempts)
        if trace.get('modelRequests') != players or trace.get('playerRequests') != players or trace.get('reviewerRequests') != reviewers:
            errors.append('native role attempt counters differ from the board journal')
        if len({r['requestID'] for r in attempts}) != len(attempts):
            errors.append('board journal duplicates native attempts')
        if trace.get('semanticReviews') != sum(r['role'] == 'reviewer' and r['outcome'] == 'valid' for r in attempts):
            errors.append('semantic review count differs from valid reviewer judgments')
    else:
        reviewers = None
    return {'status': 'fail' if errors else 'pass', 'errors': errors, 'actual_events': len(events),
            'complete': complete, 'tricks': [state['declarerTricks'], state['defenderTricks']],
            'model_request_attempts': trace.get('modelRequests'), 'reviewer_request_attempts': reviewers, 'actual_rpc_requests': len(requests),
            'model_actions': counts['model'], 'forced_actions': counts['forced'],
            'driver_opponent_actions': counts['opponent'],
            'initial_controlled_actions': sum(e['seat'] in controlled for e in trace.get('initialEvents', [])),
            'initial_opponent_actions': sum(e['seat'] not in controlled for e in trace.get('initialEvents', [])),
            'retries': trace.get('retries'), 'events': events}


def hash_files(root, names):
    import hashlib
    return {name: hashlib.sha256((Path(root) / name).read_bytes()).hexdigest() for name in sorted(names)}


def changed_files(root, hashes):
    return sorted(name for name, digest in hashes.items()
                  if not (Path(root) / name).is_file() or hash_files(root, [name])[name] != digest)


def quality_status(evaluation):
    results = evaluation.get('results', [])
    if any(r['quality'] == 'fail' for r in results):
        return 'fail'
    return 'pass' if results and all(r['quality'] == 'pass' for r in results) else 'pending'


def has_failed_evaluation(evaluation):
    return any(row['overall'] == 'fail' for row in evaluation.get('results', []))


def coverage(case_id, events, decisions, complete):
    """Conservative event predicates. Trigger coverage is not quality acceptance."""
    status, detail = 'uncovered', 'The predeclared actual-event trigger was not observed.'
    if case_id == 'short-1':
        covered = bool(decisions and decisions[0]['advice']['plan']['update'] == 'replace')
        detail = 'Initial actual model plan before the first controlled action.'
    elif case_id == 'short-2':
        covered = len(decisions) >= 3
        detail = 'At least three actual decisions; absence of a newly disproved plan premise requires independent review.'
        if covered:
            return {'status': 'pending', 'basis': detail}
    elif case_id == 'short-3':
        from coverage_windows import short3_windows
        return short3_windows(events, decisions)
    elif case_id == 'short-4':
        honors, entry_revisions, post_two = set(), [], False
        for decision in decisions:
            snapshot = decision['snapshot']
            consumed = {e['card'] for e in snapshot['events'] if e['card'] in ('CA', 'CK', 'CQ')}
            honors.update(consumed)
            hands = {h['seat']: h['cards'] for h in snapshot['hands']}
            # This is an observable opportunity, not a strategic claim that the entry is needed.
            remaining_clubs = any(c.startswith('C') for cards in hands.values() for c in cards)
            heart_entry = any(c in ('HA', 'HK') for cards in hands.values() for c in cards)
            heart_choice = any(c.startswith('H') for c in hands.get(snapshot['actingSeat'], []))
            if consumed and remaining_clubs and heart_entry and heart_choice:
                entry_revisions.append(snapshot['revision'])
                post_two |= len(consumed) >= 2
        return {'status': 'pending' if entry_revisions else 'uncovered',
                'basis': 'Consumed honor plus remaining-club/heart-entry opportunity; actual necessary transport and explanation require independent review.',
                'facets': {'consumed_club_honors': sorted(honors),
                           'entry_opportunity_revisions': entry_revisions, 'post_two_honors': post_two}}
    elif case_id == 'short-5':
        attempts = [e for e in events if e['seat'] == 'north' and e['card'][0] == 'D']
        covered = any('CA' in next(h['cards'] for h in d['snapshot']['hands'] if h['seat'] == 'north')
                      and any(e['sequence'] < d['snapshot']['revision'] - 1 for e in attempts)
                      for d in decisions)
        detail = 'Diamond attempt, retained North CA and later controlled decision observed; gift/entry meaning requires independent review.'
        if covered:
            return {'status': 'pending', 'basis': detail}
    elif case_id == 'short-6':
        ace = next((e['sequence'] for e in events if e['card'] == 'SA'), len(events))
        diamond_ace = next((e['sequence'] for e in events if e['card'] == 'DA' and e['seat'] in ('east', 'west')), None)
        before_loss = diamond_ace if diamond_ace is not None else len(events)
        ducks = [r for i in range(0, len(events) - 3, 4) if len(r := events[i:i+4]) == 4
                 and r[-1]['sequence'] < min(ace, before_loss)
                 and all(e['card'].startswith('S') for e in r)
                 and any(e['seat'] == 'south' and e['card'] != 'SA' for e in r)]
        continued = bool(ducks) and any(e['sequence'] > ducks[0][-1]['sequence']
                        and e['sequence'] < before_loss and e['seat'] in ('east', 'west')
                        and e['card'].startswith('S') for e in events)
        diamond_contest = diamond_ace is not None and any(e['sequence'] < diamond_ace
                              and e['seat'] in ('north', 'south') and e['card'].startswith('D') for e in events)
        later = diamond_ace is not None and any(d['snapshot']['revision'] > diamond_ace for d in decisions)
        return {'status': 'pending' if ducks and continued and diamond_contest and later else 'uncovered',
                'basis': 'Actual pre-DA-loss hold-up, spade continuation, diamond response and later decision are required; communication meaning still needs independent review.',
                'facets': {'hold_up_before_diamond_ace_loss': bool(ducks),
                           'spade_continuation_before_diamond_ace_loss': continued,
                           'diamond_ace_defensive_response': diamond_contest,
                           'later_controlled_decision': later}}
    else:
        covered = complete
        detail = 'All 52 actual cards consumed in thirteen independently replayed tricks.'
    return {'status': 'covered' if covered else status, 'basis': detail}


def write(path, value):
    Path(path).write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')


def source_files():
    paths = ['Package.swift', 'Scripts/capture-playing-wire.py', 'Scripts/step-playing.sh', 'evals/stage1/case-execution.json']
    for directory in ('BridgeDomain', 'BridgeEngine', 'BridgeExpert', 'BridgeCodex', 'BridgeDriver', 'BridgePlayCLI'):
        paths += [str(p.relative_to(REPO)) for p in (REPO / 'Sources' / directory).rglob('*.swift')]
    paths += [str(p.relative_to(REPO)) for p in ROOT.glob('*.py')]
    paths += [str(p.relative_to(REPO)) for p in ROOT.glob('*.toml')]
    paths += [str(p.relative_to(REPO)) for p in ROOT.glob('*schema.json')]
    paths += ['evals/stage1/rubric.txt', 'evals/stage1/requirements-test.txt']
    paths += [str(p.relative_to(REPO)) for p in (REPO / 'Sources/BridgeExpert/Resources').rglob('*') if p.is_file()]
    paths += [str(p.relative_to(REPO)) for p in (ROOT / 'regressions').rglob('*') if p.is_file() and '__pycache__' not in p.parts]
    paths += [str(p.relative_to(REPO)) for p in (ROOT / 'corpus').rglob('*.json')]
    return sorted(set(paths))


def bundled_catalog(codex):
    import subprocess
    data = subprocess.run([str(codex), 'debug', 'models', '--bundled'],
                          capture_output=True, check=True, timeout=10).stdout
    catalog = json.loads(data)
    if not isinstance(catalog.get('models'), list):
        raise ValueError('Installed runtime has no bundled model catalog')
    return data


def freeze(output, binary, codex):
    import datetime
    import re
    import subprocess
    import sys
    import shutil
    sys.path.insert(0, str(ROOT))
    import corpus
    output, binary = Path(output).resolve(), Path(binary).resolve()
    codex = Path(shutil.which(str(codex)) or str(codex)).absolute()
    output.mkdir(parents=True, exist_ok=False)
    validation = corpus.validate(ROOT / 'corpus/manifest.json')
    runtime = subprocess.run([str(codex), '--version'], text=True, capture_output=True, check=True, timeout=10).stdout.strip()
    catalog = bundled_catalog(codex)
    (output / 'runtime-bundled-catalog.json').write_bytes(catalog)
    version = subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=REPO, text=True, capture_output=True, check=True, timeout=10).stdout.strip()
    dirty = subprocess.run(['git', 'status', '--porcelain', '--'] + source_files(), cwd=REPO, text=True, capture_output=True, check=True).stdout
    if dirty.strip():
        raise ValueError('Commit candidate source before freezing: ' + dirty)
    source = (REPO / 'Sources/BridgeExpert/Expert.swift').read_text()
    instructions = (REPO / 'Sources/BridgeExpert/Resources/DeclarerInstructions.txt').read_text()
    schema = re.search(r'public static let outputSchema = #"(.*?)"#', source, re.S).group(1)
    reviewer_source = (REPO / 'Sources/BridgeExpert/PlayReview.swift').read_text()
    reviewer_instructions = (REPO / 'Sources/BridgeExpert/Resources/ReviewerInstructions.txt').read_text()
    reviewer_schema = re.search(r'public static let reviewOutputSchema = #"(.*?)"#', reviewer_source, re.S).group(1)
    candidate = {'created_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'source_commit': version,
                 'source_hashes': hash_files(REPO, source_files()),
                 'binary': str(binary), 'binary_sha256': hash_files(binary.parent, [binary.name])[binary.name],
                 'codex': str(codex), 'codex_sha256': hash_files(codex.parent, [codex.name])[codex.name],
                 'runtime_catalog_sha256': hashlib.sha256(catalog).hexdigest(),
                 'runtime_hash_scope': 'Hash covers the supplied executable. Supply the native Codex executable for native binary attestation; a launcher hash does not attest its child.',
                 'runtime_version': runtime, 'requested_play_model': 'gpt-6.1-sol', 'requested_play_effort': 'medium',
                 'requested_reviewer_model': 'gpt-6.1-sol', 'requested_reviewer_effort': 'medium',
                 'requested_grader_model': 'gpt-6.1-sol', 'requested_grader_effort': 'medium',
                 'identity_limit': 'Requested and observable runtime identities only; hidden service resolution is not independently established.',
                 'request_timeout_seconds': 180, 'run_timeout_seconds': 1800, 'grader_timeout_seconds': 600,
                 'execution_configuration': execution_configuration(), 'retry_policy': 'Five valid semantic reviews maximum per pending decision; four technical reviewer attempts maximum per round. Exhaustion stops without contested release. Player is never restarted.',
                 'max_semantic_rounds': 5, 'max_reviewer_technical_attempts': 4,
                 'execution_policy': 'Exact approved candidate, or exact legal round-five unresolved candidate as contested; apply only its final plan operation once.',
                 'active_plan_semantics': 'Working plan from authorized execution; active does not imply review-approved.',
                 'role_configurations': {role: {'model': 'gpt-6.1-sol', 'effort': 'medium', 'additional_tools': []} for role in ('player', 'reviewer')},
                 'grader_configuration': (ROOT / 'grader-config.toml').read_text(),
                 'reviewer_instructions': reviewer_instructions, 'reviewer_schema_template': json.loads(reviewer_schema),
                 'instruction_sha256': {'player': hashlib.sha256(instructions.encode()).hexdigest(), 'reviewer': hashlib.sha256(reviewer_instructions.encode()).hexdigest()},
                 'corpus_version': validation['corpus_version'], 'rubric_version': validation['rubric_version'],
                 'english_instructions': instructions, 'schema_template': json.loads(schema),
                 'schema_note': 'Production appends the exact complete current Engine legal-choice enum, without ranking.',
                 'proxy_note': 'All playing requests use the same unchanged-byte transparent provider-routing proxy; per-attempt ports and fresh runtime paths vary.'}
    write(output / 'candidate.json', candidate)
    write(output / 'plan.json', schedule(load(ROOT / 'corpus/manifest.json')))
    write(output / 'corpus-validation.json', validation)
    return candidate


def preflight(candidate):
    import subprocess
    errors = changed_files(REPO, candidate['source_hashes'])
    if 'evals/stage1/case-execution.json' in candidate['source_hashes'] and json.dumps(candidate.get('execution_configuration'), sort_keys=True) != json.dumps(execution_configuration(), sort_keys=True):
        errors.append('frozen per-case execution configuration changed or missing')
    if candidate.get('role_configurations') is not None and set(candidate['source_hashes']) != set(source_files()):
        errors.append('frozen source/fixture inventory changed')
    if candidate.get('source_commit') and candidate.get('role_configurations') is not None:
        import io, tarfile
        archive = subprocess.run(['git', 'archive', candidate['source_commit'], '--'] + sorted(candidate['source_hashes']), cwd=REPO, capture_output=True, check=True, timeout=15).stdout
        with tarfile.open(fileobj=io.BytesIO(archive)) as files:
            for name, digest in candidate['source_hashes'].items():
                entry = files.extractfile(name)
                if entry is None or hashlib.sha256(entry.read()).hexdigest() != digest:
                    errors.append('source commit attestation: ' + name)
    for key in ('binary', 'codex'):
        path = Path(candidate[key])
        if changed_files(path.parent, {path.name: candidate[key + '_sha256']}):
            errors.append(key)
    if errors:
        raise ValueError('Frozen candidate changed: ' + ', '.join(errors))
    observed = subprocess.run([candidate['codex'], '--version'], text=True, capture_output=True, check=True, timeout=10).stdout.strip()
    if observed != candidate['runtime_version']:
        raise ValueError('Codex runtime version changed')
    catalog_hash = hashlib.sha256(bundled_catalog(candidate['codex'])).hexdigest()
    if catalog_hash != candidate.get('runtime_catalog_sha256'):
        raise ValueError('Codex bundled catalog changed; freeze a new candidate')


def playing_command(candidate, attempt, play_directory, wrapper):
    configuration = candidate['execution_configuration']
    option = configuration['case_options'][attempt['case_id']]['mechanical_sole_legal']
    if attempt['execution_config_version'] != configuration['version'] or attempt['mechanical_sole_legal'] is not option:
        raise ValueError('Attempt execution option differs from frozen candidate')
    command = [candidate['binary'], '--fixture', str(ROOT / 'corpus' / attempt['board']), '--output', str(play_directory),
               '--artifact-store', str(play_directory.parent.parent / 'objects'),
               '--codex', wrapper, '--timeout', str(candidate['request_timeout_seconds']), '--run-timeout', str(candidate['run_timeout_seconds']),
               '--opponent', attempt['opponent_policy'], '--sole-legal', str(option).lower()]
    command += ['--full-board', 'true'] if attempt['kind'] == 'full' else ['--decisions', str(attempt['decisions'])]
    return command


def run_attempt(candidate, attempt, output):
    import subprocess
    import sys
    import time
    directory = output / attempt['id']
    directory.mkdir(exist_ok=False)
    write(directory / 'attempt.json', {**attempt, 'status': 'started', 'product_review_policy': 'up to five semantic reviews, four technical attempts per round; no board reroll'})
    wire = directory / 'wire'
    proxy_log = (directory / 'proxy-stderr.txt').open('w')
    proxy = subprocess.Popen([sys.executable, str(REPO / 'Scripts/capture-playing-wire.py'), '--codex', candidate['codex'], '--output', str(wire)],
                             stdout=subprocess.PIPE, stderr=proxy_log)
    start = time.monotonic()
    try:
        wrapper = proxy_wrapper(proxy)
        if not Path(wrapper).is_file():
            raise RuntimeError('Wire audit proxy did not produce its executable')
        probe = subprocess.run([wrapper, '--version'], env={'PATH': str(Path(wrapper).parent) + ':/usr/bin:/bin:/usr/sbin:/sbin'}, text=True, capture_output=True, timeout=10)
        write(directory / 'isolated-version-probe.json', {'exit_code': probe.returncode, 'version': probe.stdout.strip(), 'stderr': probe.stderr})
        if probe.returncode or probe.stdout.strip() != candidate['runtime_version']:
            raise RuntimeError('Isolated wrapper runtime version probe failed')
        command = playing_command(candidate, attempt, directory / 'play', wrapper)
        write(directory / 'play-command.json', command)
        with (directory / 'play-stdout.txt').open('w') as stdout, (directory / 'play-stderr.txt').open('w') as stderr:
            process = bounded_command(command, stdout, stderr, candidate['run_timeout_seconds'] + 30)
        outcome = {'exit_code': process.returncode, 'wall_seconds': round(time.monotonic() - start, 3)}
        catalogs = list((directory / 'play').rglob('runtime-bundled-catalog.json'))
        if not catalogs or any(hash_files(catalog.parent, [catalog.name])[catalog.name] != candidate['runtime_catalog_sha256'] for catalog in catalogs):
            outcome = {**outcome, 'exit_code': None, 'driver_exit_code': process.returncode,
                       'runner_error': 'A role runtime bundled catalog differs from frozen candidate'}
    except Exception as error:
        outcome = {'exit_code': None, 'runner_error': str(error), 'wall_seconds': round(time.monotonic() - start, 3)}
    finally:
        proxy.terminate()
        try:
            proxy.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proxy.kill()
            proxy.wait()
        proxy_log.close()
    write(directory / 'playing-outcome.json', outcome)
    play = directory / 'play'
    decisions = decision_directories(play)
    grade_command = [sys.executable, str(ROOT / 'evaluate.py'), 'grade', '--case', attempt['case_id'], '--codex', candidate['codex'],
                     '--timeout', str(candidate['grader_timeout_seconds']), '--output', str(directory / 'grade')]
    for decision in decisions:
        grade_command += ['--decision', str(decision)]
    write(directory / 'grade-command.json', grade_command)
    try:
        if not decisions:
            raise ValueError('No saved decision or runtime-failure record exists to grade; independent grader not called.')
        with (directory / 'grade-stdout.txt').open('w') as stdout, (directory / 'grade-stderr.txt').open('w') as stderr:
            grade = bounded_command(grade_command, stdout, stderr, candidate['grader_timeout_seconds'] + 30)
        grade_outcome = {'exit_code': grade.returncode}
    except Exception as error:
        grade_outcome = {'exit_code': None, 'runner_error': str(error)}
    grade_outcome['grading_evidence_available'] = (directory / 'grade/run.json').exists()
    write(directory / 'grading-outcome.json', grade_outcome)
    write(directory / 'attempt.json', {**attempt, 'status': 'finished', 'product_review_policy': 'up to five semantic reviews, four technical attempts per round; no board reroll'})
    return summarize_attempt(attempt, directory, candidate)


def summarize_attempt(attempt, directory, candidate=None):
    trace_path = directory / 'play/trace.json'
    trace = load(trace_path) if trace_path.exists() else {}
    decisions = [s['decision'] for s in trace.get('steps', []) if s.get('decision')]
    import reviewed_evidence
    if candidate is None and (directory.parent / 'candidate.json').exists():
        candidate = load(directory.parent / 'candidate.json')
    requests = reviewed_evidence.request_summary(trace)
    board = load(ROOT / 'corpus' / attempt['board'])
    try:
        inspection = inspect_play(board, trace, directory / 'play', attempt.get('mechanical_sole_legal')) if trace else {'status': 'fail', 'errors': ['No trace'], 'events': [], 'complete': False}
    except (ValueError, KeyError, TypeError) as error:
        inspection = {'status': 'fail', 'errors': [str(error)], 'events': [], 'complete': False}
    write(directory / 'independent-replay.json', inspection)
    grade_path = directory / 'grade/evaluation.json'
    evaluation = load(grade_path) if grade_path.exists() else {'results': []}
    rows = evaluation.get('results', [])
    playing = load(directory / 'playing-outcome.json')
    task = task_complete(attempt, inspection, trace, playing)
    timing_keys = ('elapsedSeconds', 'lastControlledActionSeconds', 'environmentOverheadSeconds', 'initialRequestSeconds', 'subsequentRequestSeconds', 'failedRequestSeconds', 'automaticRuntimeSeconds', 'humanWaitingSeconds')
    try:
        wire_audit = audit_wire(directory / 'wire', candidate=candidate, journal=trace.get('requestEvidence')) if candidate else audit_wire(directory / 'wire')
    except (OSError, ValueError, KeyError, TypeError) as error:
        wire_audit = {'protocol_status': 'fail', 'protocol_errors': [str(error)], 'upstream_request_attempts': len(list((directory / 'wire').glob('request-*.json'))), 'roles': {}}
    result = {**attempt, 'task_complete': task, 'legal_execution': inspection['status'], 'quality': quality_status(evaluation),
              'playing': playing, 'grading': load(directory / 'grading-outcome.json'),
              'coverage': coverage(attempt['case_id'], inspection['events'], decisions, inspection['complete']),
              'counts': {k: v for k, v in inspection.items() if k not in ('events', 'errors', 'status')},
              'wire': wire_audit,
              'requests': requests,
              'dispositions': {value: sum(d.get('executionDisposition') == value for d in decisions) for value in ('reviewApproved', 'contested')},
              'stop_outcome': 'needs-input' if trace.get('needsInput') else 'failed' if not task else 'board-complete' if inspection['complete'] else 'short-bound-complete',
              'grader_cost': {key: load(directory / 'grade/run.json').get(key) for key in ('elapsed_seconds', 'observed_usage', 'requested_model', 'requested_effort')} if (directory / 'grade/run.json').exists() else None,
              'timing': {k: trace.get(k) for k in timing_keys}, 'quality_counts': {status: sum(r['quality'] == status for r in rows) for status in ('pass', 'fail', 'uncertain')},
              'review_required': [r for r in rows if r['overall'] != 'pass'],
              'plan_updates': {update: sum(d['advice']['plan']['update'] == update for d in decisions) for update in ('keep', 'replace', 'withdraw')},
              'failures': inspection['errors'] + ([trace['failure']] if trace.get('failure') else [])}
    result['outcome'] = 'fail' if not task or has_failed_evaluation(evaluation) or result['wire'].get('protocol_status') == 'fail' else 'pending' if result['wire'].get('protocol_status', 'pass') != 'pass' or result['quality'] != 'pass' or result['coverage']['status'] != 'covered' else 'pass'
    write(directory / 'summary.json', result)
    return result


def execute(output):
    import datetime
    output = Path(output).resolve()
    candidate = load(output / 'candidate.json')
    attempts = load(output / 'plan.json')
    verify_schedule(attempts)
    preflight(candidate)
    marker = output / 'execution-started.json'
    with marker.open('x') as stream:
        json.dump({'utc': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'schedule': 'Strict sequential, one attempt each.'}, stream)
    summaries = []
    for attempt in attempts:
        verify_schedule(load(output / 'plan.json'))
        preflight(candidate)
        summaries.append(run_attempt(candidate, attempt, output))
        write(output / 'summary.json', {'candidate_source': candidate['source_commit'], 'attempts': summaries,
                                      'status': 'no-go' if any(r['outcome'] == 'fail' for r in summaries) else 'pending-review'})
        render_report(output, candidate, summaries)
        print('%s: %s, task=%s, quality=%s' % (attempt['id'], summaries[-1]['outcome'], summaries[-1]['task_complete'], summaries[-1]['quality']), flush=True)
    write(output / 'execution-finished.json', {'utc': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'attempts': len(summaries)})
    return summaries


def render_report(output, candidate, summaries):
    import statistics
    def distribution(values):
        return '%d / %.3f / %.3f–%.3f' % (len(values), statistics.median(values), min(values), max(values)) if values else '0 / unavailable'
    status = 'NO-GO' if any(row['outcome'] == 'fail' for row in summaries) else 'PENDING INDEPENDENT REVIEW'
    lines = ['# Stage 1 finite acceptance', '', '**%s.** %d of 22 predeclared attempts recorded.' % (status, len(summaries)), '',
             'Candidate source commit: `%s`. Both instruction sources, role configurations, schemas, runtime/capture code, fixtures, rubrics and binary/native-runtime hashes were frozen in [candidate.json](candidate.json).' % candidate['source_commit'], '',
             'Production player and independent runtime reviewer both request gpt-6.1-sol / medium with empty additional_tools. The separate acceptance grader requests gpt-6.1-sol / medium. Requested/observable identities do not prove hidden service internals. Every attempt runs strictly sequentially; the bounded product loop permits five semantic reviews and four technical attempts per review round. There are no board rerolls, manual controlled substitutes or grader feedback into live play.', '',
             'Only delivered advice is graded. Rejected drafts are diagnostic. Review approval and contested execution are authorization dispositions, never bridge-quality labels. Canonical snapshots establish public facts; feedback envelopes preserve actual prior reviewer assertions as non-authoritative provenance.', '',
             '| Attempt | Mechanical sole-legal | Task | Legal | Quality | Trigger | Player / reviewer / RPC / HTTP attempts | Model / forced / opponent plays | Tricks |',
             '|---|---|---|---|---|---|---|---|---|']
    if candidate.get('execution_configuration'):
        lines[4:4] = ['Case execution configuration: `%s`. Only short-3 disables mechanical sole-legal skipping; its twelve delivered-decision bound is unchanged. More sole-card advice can increase model/reviewer work and stop after fewer actual plays. This is not a prompt-only controlled comparison.' % candidate['execution_configuration']['version'], '', candidate['execution_configuration']['short3_coverage']['pre_showout_facet'], '']
    for row in summaries:
        c=row['counts'];roles=row.get('requests',{}).get('roles',{})
        lines.append('| [%s](%s/summary.json) | %s | %s | %s | %s | %s | %s / %s / %s / %s | %s / %s / %s | %s |' %
                     (row['id'],row['id'],row.get('mechanical_sole_legal','historical'),row['task_complete'],row['legal_execution'],row['quality'],row['coverage']['status'],
                      roles.get('player',{}).get('attempts'),roles.get('reviewer',{}).get('attempts'),c.get('actual_rpc_requests'),row['wire']['upstream_request_attempts'],
                      c.get('model_actions'),c.get('forced_actions'),c.get('driver_opponent_actions'),c.get('tricks')))
    lines += ['', 'Every initial fixture prefix is counted separately in summary.json. Native request attempts exclude late outcome observations; HTTP attempts include runtime-internal retries and are not interchangeable with technical retries. Missing usage is unknown, never zero.', '',
              '## Timing', '',
              '| Attempt | First decision or failed request s | Later n / median / range s | Automatic board s | Human wait s | Full-board complete |',
              '|---|---|---|---|---|---|']
    for row in summaries:
        t=row['timing']
        lines.append('| %s | %s | %s | %s | %s | %s |' % (row['id'],t.get('initialRequestSeconds'),distribution(t.get('subsequentRequestSeconds') or []),
                     t.get('automaticRuntimeSeconds',t.get('elapsedSeconds')),t.get('humanWaitingSeconds'),row['counts'].get('complete') if row['kind']=='full' else 'short'))
    full=[row for row in summaries if row['kind']=='full']
    lines += ['', 'All %d of four scheduled full-board durations appear above, including incomplete failures. Each first/later decision duration includes both roles, revisions and retries; failed requests and environment overhead remain separately saved. The automatic 1,800 s board budget includes processing; the native request cap is 180 s. Human needs-input waiting is reported separately. There is no three-minute quality or speed gate.' % len(full), '',
              '## Role costs and outcomes', '',
              '| Attempt | Role | Native attempts / seconds | Native observed total tokens / unknown attempts | HTTP attempts / observed total tokens / unknown attempts |',
              '|---|---|---|---|---|']
    for row in summaries:
        for role in ('player','reviewer'):
            native=row.get('requests',{}).get('roles',{}).get(role,{})
            upstream=row['wire'].get('roles',{}).get(role,{})
            lines.append('| %s | %s | %s / %s | %s / %s | %s / %s / %s |' % (row['id'],role,native.get('attempts'),native.get('elapsed_seconds'),
                         (native.get('observed_tokens') or {}).get('totalTokens'),native.get('usage_unknown_attempts'),upstream.get('upstream_attempts'),
                         (upstream.get('observed_tokens') or {}).get('total_tokens'),upstream.get('usage_unknown_attempts')))
    lines += ['', 'Native per-turn usage and upstream HTTP usage are separate observations of cost; never add the two totals. Failed attempts count when usage is observable. Input, cached input, output and reasoning tokens remain in each role summary. Grader durations and observed usage remain separately in grade/run.json and each summary. Monetary cost is unavailable without an attested applicable price schedule.', '',
              '| Attempt | Semantic reviews | Feedback / clarification | Technical retries | Approved / contested delivered | Stop outcome |',
              '|---|---|---|---|---|---|']
    for row in summaries:
        req=row.get('requests',{});dispositions=row.get('dispositions',{})
        lines.append('| %s | %s | %s / %s | %s | %s / %s | %s |' % (row['id'],req.get('semantic_reviews'),req.get('feedback_revisions'),req.get('clarification_requests'),
                     req.get('reviewer_retries'),dispositions.get('reviewApproved',0),dispositions.get('contested',0),row.get('stop_outcome')))
    lines += ['', '## Quality and coverage limits', '',
              'The original serious-error standard and 22-attempt schedule are unchanged. Legal completion, contract result and reviewer approval cannot erase a material final error. Every raw grade, evaluator error and dispute is retained. A cited grader pass is provisional until independent review of the facts; unresolved grades remain pending. Coverage predicates are conservative: actual hold-up/communication and entry opportunities require independent explanation, and an avoided or unobserved trigger remains uncovered.', '',
              'The formerly reserved board is already used regression material. These finite samples do not establish broad bridge strength. Original failed candidates, two historical HTTP metadata gaps, and older grader disputes remain history rather than newly accepted results.', '',
              'Exact HTTP request bytes, metadata and sanitized public RPC outputs are preserved without credentials or decrypted reasoning. Both role catalogs are checked against the frozen native catalog. The runtime preserves opaque encrypted conversation history; that does not grant hidden bridge holdings or strategic tools.', '',
              'The independent evidence/adjudication overlay and final per-issue met/unmet ledger are recorded separately. Until those are resolved, this report is captured evidence, not acceptance approval, main delivery, issue-closure authority or permission to merge.', '']
    (output / 'REPORT.md').write_text('\n'.join(lines))


def task_complete(attempt, inspection, trace, playing):
    if playing.get('exit_code') != 0 or trace.get('failure') or inspection['status'] != 'pass':
        return False
    return inspection['complete'] if attempt['kind'] == 'full' else inspection.get('model_actions', 0) >= attempt['decisions'] or inspection['complete']


def decision_directories(play):
    play = Path(play)
    decisions = [play] if (play / 'decision.json').is_file() else sorted(p.parent for p in play.glob('decision-*/decision.json'))
    if (play / 'failure.json').exists() and play not in decisions and not any((d / 'failure.json').exists() for d in decisions):
        decisions.append(play)
    return decisions


def verify_schedule(plan):
    if plan != schedule(load(ROOT / 'corpus/manifest.json')):
        raise ValueError('Predeclared finite schedule changed')


def audit_wire(wire, candidate=None, journal=None):
    requests = sorted(Path(wire).glob('request-*.json'))
    metadata = [load(path) for path in sorted(Path(wire).glob('response-metadata-*.json'))]
    statuses = {}
    for row in metadata:
        key = str(row.get('httpStatus', 'unknown'))
        statuses[key] = statuses.get(key, 0) + 1
    result = {'upstream_request_attempts': len(requests), 'http_statuses': statuses,
            'transport_errors': [load(path) for path in sorted(Path(wire).glob('transport-error-*.json'))],
            'missing_response_metadata': ['response-metadata-' + path.name[len('request-'):] for path in requests
                                          if not (Path(wire) / ('response-metadata-' + path.name[len('request-'):])).exists()],
            'observed_response_models': sorted({row['model'] for row in metadata if row.get('model')})}

    if candidate is not None:
        import reviewed_evidence
        result.update(reviewed_evidence.wire_summary(wire, candidate, journal))
    return result


def bounded_command(command, stdout, stderr, timeout):
    import os
    import signal
    import subprocess
    process = subprocess.Popen(command, stdout=stdout, stderr=stderr, start_new_session=True)
    try:
        process.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=0.2)
        except subprocess.TimeoutExpired:
            pass
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait()
        raise
    return process


def proxy_wrapper(process, timeout=10):
    import os
    import select
    import time
    deadline = time.monotonic() + timeout
    data = b''
    while b'\n' not in data:
        remaining = deadline - time.monotonic()
        if remaining <= 0 or not select.select([process.stdout], [], [], remaining)[0]:
            raise TimeoutError('Wire proxy startup exceeded %.3f seconds' % timeout)
        chunk = os.read(process.stdout.fileno(), 4096)
        if not chunk:
            raise RuntimeError('Wire proxy exited before publishing its executable')
        data += chunk
    return data.split(b'\n', 1)[0].decode().strip()


def main():
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    frozen = commands.add_parser('freeze')
    frozen.add_argument('--binary', required=True, type=Path)
    frozen.add_argument('--codex', required=True)
    frozen.add_argument('--output', required=True, type=Path)
    run = commands.add_parser('run')
    run.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    if args.command == 'freeze':
        freeze(args.output, args.binary, args.codex)
    else:
        execute(args.output)


if __name__ == '__main__':
    main()
