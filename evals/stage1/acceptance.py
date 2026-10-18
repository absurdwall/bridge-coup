#!/usr/bin/env python3
"""Freeze and execute the finite stage-1 matrix, preserving every attempt."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[1]


def load(path):
    return json.loads(Path(path).read_text())


def schedule(manifest):
    return [{'id': '%s-r%d' % (case['id'], number), 'case_id': case['id'],
             'kind': case['kind'], 'board': case['board'], 'decisions': case.get('decisions'),
             'opponent_policy': case['opponent_policy']}
            for case in manifest['cases'] for number in range(1, case['required_runs'] + 1)]


def inspect_play(board, trace, evidence):
    """Replay actual events independently; audit all execution source labels."""
    import sys
    if str(ROOT) not in sys.path:
        sys.path.insert(0, str(ROOT))
    import corpus
    errors = []
    events = list(trace.get('initialEvents', []))
    if events != corpus.initial_events(board):
        errors.append('initial prefix differs from frozen board')
    declarer = board['contract']['declarer']
    dummy = corpus.SEATS[(corpus.SEATS.index(declarer) + 2) % 4]
    controlled = {declarer, dummy}
    counts = {'model': 0, 'forced': 0, 'opponent': 0}
    decisions = []
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
                if decision['action']['card'] != event['card'] or decision['snapshot']['events'] != events:
                    errors.append('model source does not bind to its actual event')
        elif source == 'forced':
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
    rpc = Path(evidence) / 'rpc.jsonl'
    requests = [row for row in (json.loads(line) for line in rpc.read_text().splitlines())
                if row.get('kind') == 'request' and row.get('value', {}).get('method') == 'turn/start'] if rpc.exists() else []
    return {'status': 'fail' if errors else 'pass', 'errors': errors, 'actual_events': len(events),
            'complete': complete, 'tricks': [state['declarerTricks'], state['defenderTricks']],
            'model_request_attempts': trace.get('modelRequests'), 'actual_rpc_requests': len(requests),
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
        rounds = [events[i:i+4] for i in range(0, len(events) - 3, 4)]
        club_rounds = [r for r in rounds if all(e['card'][0] == 'C' for e in r)]
        second = club_rounds[1][-1]['sequence'] if len(club_rounds) >= 2 else None
        break_revisions = [d['snapshot']['revision'] for d in decisions
                           if second is not None and d['snapshot']['revision'] > second]
        seen, localized_revisions = {'east': 0, 'west': 0}, []
        for event in events:
            if event['seat'] not in seen or not event['card'].startswith('C'):
                continue
            seen[event['seat']] += 1
            if seen[event['seat']] != 3:
                continue
            other = 'west' if event['seat'] == 'east' else 'east'
            next_other = next((e['sequence'] for e in events if e['sequence'] > event['sequence'] and e['seat'] == other), len(events))
            localized_revisions += [d['snapshot']['revision'] for d in decisions
                                    if event['sequence'] < d['snapshot']['revision'] <= next_other]
        return {'status': 'pending' if break_revisions else 'uncovered',
                'basis': 'Actual information windows observed; factual use, justified retention/replacement and non-invention require independent review.',
                'facets': {'two_round_break_decision_revisions': break_revisions,
                           'third_club_before_other_defender_revisions': localized_revisions}}
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
    paths = ['Package.swift', 'Scripts/capture-playing-wire.py']
    for directory in ('BridgeDomain', 'BridgeEngine', 'BridgeExpert', 'BridgeCodex', 'BridgeDriver', 'BridgePlayCLI'):
        paths += [str(p.relative_to(REPO)) for p in (REPO / 'Sources' / directory).rglob('*.swift')]
    paths += [str(p.relative_to(REPO)) for p in ROOT.glob('*.py')]
    paths += [str(p.relative_to(REPO)) for p in ROOT.glob('*.toml')]
    paths += [str(p.relative_to(REPO)) for p in ROOT.glob('*schema.json')]
    paths += ['evals/stage1/rubric.txt']
    paths += [str(p.relative_to(REPO)) for p in (ROOT / 'corpus').rglob('*.json')]
    return sorted(set(paths))


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
    version = subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=REPO, text=True, capture_output=True, check=True, timeout=10).stdout.strip()
    dirty = subprocess.run(['git', 'status', '--porcelain', '--'] + source_files(), cwd=REPO, text=True, capture_output=True, check=True).stdout
    if dirty.strip():
        raise ValueError('Commit candidate source before freezing: ' + dirty)
    source = (REPO / 'Sources/BridgeExpert/Expert.swift').read_text()
    instructions = re.search(r'public static let instructions = """\n(.*?)\n    """', source, re.S).group(1).strip()
    schema = re.search(r'public static let outputSchema = #"(.*?)"#', source, re.S).group(1)
    candidate = {'created_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'source_commit': version,
                 'source_hashes': hash_files(REPO, source_files()),
                 'binary': str(binary), 'binary_sha256': hash_files(binary.parent, [binary.name])[binary.name],
                 'codex': str(codex), 'codex_sha256': hash_files(codex.parent, [codex.name])[codex.name],
                 'runtime_version': runtime, 'requested_play_model': 'gpt-6-luna', 'requested_play_effort': 'medium',
                 'requested_grader_model': 'gpt-6.1-sol', 'requested_grader_effort': 'medium',
                 'identity_limit': 'Requested and observable runtime identities only; hidden service resolution is not independently established.',
                 'request_timeout_seconds': 180, 'run_timeout_seconds': 1800, 'grader_timeout_seconds': 600,
                 'mechanical_sole_legal': True, 'retry_policy': 'No playing retries, substitutions or answer repair.',
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
    for key in ('binary', 'codex'):
        path = Path(candidate[key])
        if changed_files(path.parent, {path.name: candidate[key + '_sha256']}):
            errors.append(key)
    if errors:
        raise ValueError('Frozen candidate changed: ' + ', '.join(errors))
    observed = subprocess.run([candidate['codex'], '--version'], text=True, capture_output=True, check=True, timeout=10).stdout.strip()
    if observed != candidate['runtime_version']:
        raise ValueError('Codex runtime version changed')


def run_attempt(candidate, attempt, output):
    import subprocess
    import sys
    import time
    directory = output / attempt['id']
    directory.mkdir(exist_ok=False)
    write(directory / 'attempt.json', {**attempt, 'status': 'started', 'playing_retries': 0})
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
        command = [candidate['binary'], '--fixture', str(ROOT / 'corpus' / attempt['board']), '--output', str(directory / 'play'),
                   '--codex', wrapper, '--timeout', str(candidate['request_timeout_seconds']), '--run-timeout', str(candidate['run_timeout_seconds']),
                   '--opponent', attempt['opponent_policy'], '--sole-legal', 'true']
        command += ['--full-board', 'true'] if attempt['kind'] == 'full' else ['--decisions', str(attempt['decisions'])]
        write(directory / 'play-command.json', command)
        with (directory / 'play-stdout.txt').open('w') as stdout, (directory / 'play-stderr.txt').open('w') as stderr:
            process = bounded_command(command, stdout, stderr, candidate['run_timeout_seconds'] + 30)
        outcome = {'exit_code': process.returncode, 'wall_seconds': round(time.monotonic() - start, 3)}
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
    write(directory / 'attempt.json', {**attempt, 'status': 'finished', 'playing_retries': 0})
    return summarize_attempt(attempt, directory)


def summarize_attempt(attempt, directory):
    trace_path = directory / 'play/trace.json'
    trace = load(trace_path) if trace_path.exists() else {}
    decisions = [s['decision'] for s in trace.get('steps', []) if s.get('decision')]
    board = load(ROOT / 'corpus' / attempt['board'])
    try:
        inspection = inspect_play(board, trace, directory / 'play') if trace else {'status': 'fail', 'errors': ['No trace'], 'events': [], 'complete': False}
    except (ValueError, KeyError, TypeError) as error:
        inspection = {'status': 'fail', 'errors': [str(error)], 'events': [], 'complete': False}
    write(directory / 'independent-replay.json', inspection)
    grade_path = directory / 'grade/evaluation.json'
    evaluation = load(grade_path) if grade_path.exists() else {'results': []}
    rows = evaluation.get('results', [])
    playing = load(directory / 'playing-outcome.json')
    task = task_complete(attempt, inspection, trace, playing)
    timing_keys = ('elapsedSeconds', 'lastControlledActionSeconds', 'environmentOverheadSeconds', 'initialRequestSeconds', 'subsequentRequestSeconds', 'failedRequestSeconds')
    result = {**attempt, 'task_complete': task, 'legal_execution': inspection['status'], 'quality': quality_status(evaluation),
              'playing': playing, 'grading': load(directory / 'grading-outcome.json'),
              'coverage': coverage(attempt['case_id'], inspection['events'], decisions, inspection['complete']),
              'counts': {k: v for k, v in inspection.items() if k not in ('events', 'errors', 'status')},
              'wire': audit_wire(directory / 'wire'),
              'timing': {k: trace.get(k) for k in timing_keys}, 'quality_counts': {status: sum(r['quality'] == status for r in rows) for status in ('pass', 'fail', 'uncertain')},
              'review_required': [r for r in rows if r['overall'] != 'pass'],
              'plan_updates': {update: sum(d['advice']['plan']['update'] == update for d in decisions) for update in ('keep', 'replace', 'withdraw')},
              'failures': inspection['errors'] + ([trace['failure']] if trace.get('failure') else [])}
    result['outcome'] = 'fail' if not task or has_failed_evaluation(evaluation) else 'pending' if result['quality'] != 'pass' or result['coverage']['status'] != 'covered' else 'pass'
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
    status = 'NO-GO' if any(row['outcome'] == 'fail' for row in summaries) else 'PENDING INDEPENDENT REVIEW'
    lines = ['# Stage 1 finite acceptance', '', '**%s.** %d of 22 predeclared attempts recorded.' % (status, len(summaries)), '',
             'Candidate source commit: `%s`. The exact source, executable, instructions, schema template, corpus, rubric, requested configurations and runtime hashes were recorded before play in [candidate.json](candidate.json). Later evidence/document commits do not change that candidate.' % candidate['source_commit'], '',
             'All attempts use the production public Expert/driver through Codex app-server, requested gpt-6-luna / medium. Grading uses independent gpt-6.1-sol / medium with the frozen case/rubric. These names describe requested and observable identities; internal service resolution is not independently proven. Playing calls and graders run strictly sequentially, with no answer repair, manual controlled substitute or playing retry.', '',
             '## Every attempt', '',
             '| Attempt | Task | Legal | Quality | Trigger | Requests attempted / RPC / HTTP | Model / forced / opponents | Tricks | Evidence |',
             '|---|---|---|---|---|---|---|---|---|']
    for row in summaries:
        counts = row['counts']
        lines.append('| %s | %s | %s | %s | %s | %s / %s / %s | %s / %s / %s (+%s controlled, %s opponent prefix) | %s | [saved](%s/summary.json) |' %
                     (row['id'], row['task_complete'], row['legal_execution'], row['quality'], row['coverage']['status'],
                      counts.get('model_request_attempts'), counts.get('actual_rpc_requests'), row['wire']['upstream_request_attempts'], counts.get('model_actions'), counts.get('forced_actions'),
                      counts.get('driver_opponent_actions'), counts.get('initial_controlled_actions'), counts.get('initial_opponent_actions'), counts.get('tricks'), row['id']))
    lines += ['', 'Driver retries are counted separately from actual HTTP attempts. Per-attempt wire summaries preserve HTTP statuses, transport errors and missing responses; an RPC may cause multiple upstream HTTP attempts inside the runtime. The runner does not equate driver retries=0 with no internal runtime transport retry.', '',
              'Quality pass is provisional until independent review of cited facts. Trigger coverage is separate from task bounds and quality. Pending means the mechanical event predicate needs review; an avoided trigger remains uncovered. Contract result cannot erase a factual, entry or consistency failure.', '',
              '## Four full-board timings', '',
              '| Attempt | First request s | Later requests n / median / range s | Last controlled action s | Full driver s | Environment overhead s | Failed request s | Retries |',
              '|---|---|---|---|---|---|---|---|']
    for row in summaries:
        if row['kind'] != 'full':
            continue
        timing = row['timing']
        later = timing.get('subsequentRequestSeconds') or []
        distribution = '%d / %.3f / %.3f–%.3f' % (len(later), statistics.median(later), min(later), max(later)) if later else '0 / unavailable'
        lines.append('| %s | %s | %s | %s | %s | %s | %s | %s |' % (row['id'], timing.get('initialRequestSeconds'), distribution,
                     timing.get('lastControlledActionSeconds'), timing.get('elapsedSeconds'), timing.get('environmentOverheadSeconds'),
                     timing.get('failedRequestSeconds'), row['counts'].get('retries')))
    lines += ['', 'The time origin is dummy exposure/driver start immediately before the first request; last controlled action includes mechanical forced actions. Initial fixture prefix is counted separately. Full driver time includes trailing opponents after the last controlled action. Request limit 180 s, run limit 1800 s, independent grader limit 600 s. Three minutes is an experience goal, not a hard gate. Every individual subsequent latency and failed request is preserved in each trace.', '',
              '## Review and limits', '',
              'Every non-pass grade, original cited text, evaluator error and coverage predicate is preserved in per-attempt summary.json and grade/. An independent review must decide disputed/uncertain findings before any stage-complete claim. The runner never feeds grading results into the player.', '',
              'Corpus v2 keeps the formerly reserved board as used regression material: it has already been played and inspected for correction. It is not fresh held-out evidence. These finite samples do not prove broad bridge strength or general grader reliability.', '',
              'Wire captures preserve exact forwarded payload bytes, no authentication headers and no decrypted reasoning. The inherited runtime catalog may contain built-ins/collaboration and opaque encrypted reasoning history. This is not a claim of an entirely empty runtime tool list or a wholly public-only runtime history. Engine analysis/Knowledge tools are absent from the playing surface; verify actual captures and invocation records in independent review.', '',
              'Rule and dependency review evidence, concrete failure adjudication, achieved/unachieved criteria and the final stage recommendation are recorded separately in REVIEW.md. Until then this report is a captured result, not acceptance approval.', '']
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


def audit_wire(wire):
    requests = sorted(Path(wire).glob('request-*.json'))
    metadata = [load(path) for path in sorted(Path(wire).glob('response-metadata-*.json'))]
    statuses = {}
    for row in metadata:
        key = str(row.get('httpStatus', 'unknown'))
        statuses[key] = statuses.get(key, 0) + 1
    return {'upstream_request_attempts': len(requests), 'http_statuses': statuses,
            'transport_errors': [load(path) for path in sorted(Path(wire).glob('transport-error-*.json'))],
            'missing_response_metadata': ['response-metadata-' + path.name[len('request-'):] for path in requests
                                          if not (Path(wire) / ('response-metadata-' + path.name[len('request-'):])).exists()],
            'observed_response_models': sorted({row['model'] for row in metadata if row.get('model')})}


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
