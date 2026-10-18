#!/usr/bin/env python3
"""Read saved playing evidence and grade it independently. Never runs a player."""
import json
from pathlib import Path
import re


def read_json(path):
    return json.loads(Path(path).read_text())


def read_decision(directory):
    directory = Path(directory)
    if not (directory / 'decision.json').exists() and (directory / 'failure.json').exists():
        return {'runtimeFailure': read_json(directory / 'failure.json'), 'source_directory': str(directory.resolve()),
                'rpc': [json.loads(line) for line in (directory / 'rpc.jsonl').read_text().splitlines()] if (directory / 'rpc.jsonl').exists() else [],
                'runtime_config': (directory / 'runtime-config.toml').read_text() if (directory / 'runtime-config.toml').exists() else None}
    record = read_json(directory / 'decision.json')
    rpc_path = directory / 'rpc.jsonl'
    if not rpc_path.exists() and (directory.parent / 'trace.json').exists():
        rpc_path = directory.parent / 'rpc.jsonl'
    return {**record, 'executionEvents': read_json(directory / 'events.json') if (directory / 'events.json').exists() else None,
            'runtimeFailure': read_json(directory / 'failure.json') if (directory / 'failure.json').exists() else None,
            'rpc': [json.loads(line) for line in rpc_path.read_text().splitlines()] if rpc_path.exists() else None}


def deterministic_checks(record):
    checks = {}
    version = record.get('wireContractVersion', 'stage1-currentCard-plan-publicReason-v1')
    card_key = 'selectedCard' if version == 'stage1-plan-publicReason-selectedCard-v2' else 'currentCard'
    def add(name, condition, fact):
        checks[name] = {'status': 'pass' if condition else 'fail', 'fact': fact}
    snapshot = record['snapshot']
    try:
        answer = json.loads(record['rawOutput'])
        plan = answer['plan']
        valid = (version in ('stage1-currentCard-plan-publicReason-v1', 'stage1-plan-publicReason-selectedCard-v2') and set(answer) == {card_key, 'publicReason', 'plan'} and
                 isinstance(answer['publicReason'], str) and bool(answer['publicReason'].strip()) and
                 set(plan) == {'update', 'text'} and plan['update'] in ('replace', 'keep', 'withdraw') and
                 ((plan['update'] == 'replace' and isinstance(plan['text'], str) and bool(plan['text'].strip())) or
                  (plan['update'] != 'replace' and plan['text'] is None)) and
                 isinstance(answer[card_key], str) and bool(re.fullmatch('[SHDC][2-9TJQKA]', answer[card_key])))
        add('structure', valid, 'Raw answer must match the versioned single-card wire contract with publicReason and a valid plan update.')
    except (ValueError, KeyError, TypeError):
        add('structure', False, 'Raw answer cannot be decoded as the public advice contract.')
        return checks
    if not valid:
        return checks
    if record.get('rpc') is not None:
        turns = [e['value']['params'] for e in record['rpc'] if e.get('kind') == 'request' and e['value'].get('method') == 'turn/start']
        completions = [item.get('text') for e in record['rpc'] if e.get('kind') == 'completion' for item in e['value'].get('items', []) if item.get('type') == 'agentMessage']
        add('request_evidence', any(record['input'] == item.get('text') for turn in turns for item in turn.get('input', [])), 'Saved input must occur in an actual turn/start request.')
        add('output_evidence', record['rawOutput'] in completions, 'Saved raw output must occur in actual completion evidence.')
    card = answer.get(card_key, '')
    action = record.get('action', {})
    add('current_seat', action.get('actingSeat') == snapshot['actingSeat'] and action.get('controller') == snapshot['controller'],
        'Current actor is %s; controller is %s.' % (snapshot['actingSeat'], snapshot['controller']))
    hands = {hand['seat']: hand['cards'] for hand in snapshot['hands']}
    holding = hands.get(snapshot['actingSeat'], [])
    add('ownership', card in holding, '%s holds %s; proposed %s.' % (snapshot['actingSeat'], ', '.join(holding), card))
    trick = snapshot['currentTrick']
    led = trick[0]['card'][0] if trick else None
    add('follow_suit', not led or not any(c.startswith(led) for c in holding) or card.startswith(led),
        'Led suit is %s; actor must follow if holding it.' % led)
    add('action_binding', action.get('card') == card and action.get('boardID') == snapshot['boardID'] and
        action.get('revision') == snapshot['revision'] and action.get('snapshotID') == '%s:%s:%s' % (snapshot['boardID'], snapshot['revision'], snapshot['controller']),
        'Program action must match raw current card and immutable decision snapshot.')
    events = record.get('executionEvents')
    if record.get('runtimeFailure'):
        add('execution', False, 'Runtime stopped: %s' % record['runtimeFailure'])
    elif events is None:
        checks['execution'] = {'status': 'uncertain', 'fact': 'No execution evidence supplied (authored calibration is not executed).'}
    else:
        expected = snapshot['events'] + [{'card': card, 'seat': snapshot['actingSeat'], 'sequence': len(snapshot['events'])}]
        add('execution', events == expected, 'Actual events must be prior events plus exactly the proposed card once.')
    return checks


def json_text(value):
    return json.dumps(value, indent=2, ensure_ascii=False) + '\n'


def grader_package(decisions):
    seats = ['north', 'east', 'south', 'west']
    for _, record in decisions:
        declarer = record['snapshot']['contract']['declarer']
        allowed = {declarer, seats[(seats.index(declarer) + 2) % 4]}
        if any(h['seat'] not in allowed for h in record['snapshot']['hands']):
            raise ValueError('Decision snapshot contains unauthorized defender holdings')
    return {'rubric_version': 'stage1-basic-v2', 'rubric': Path(__file__).with_name('rubric.txt').read_text(),
            'decisions': [{'id': identifier, 'authorized_input': record['input'], 'playing_identity': record.get('identity'),
                           'playing_instructions': record['instructions'], 'wire_contract': record.get('wireContractVersion', 'stage1-currentCard-plan-publicReason-v1'), 'raw_output': record['rawOutput'],
                           'effective_plan': record.get('effectivePlan'),
                           'decision_time_facts': record['snapshot'],
                           'deterministic_checks': deterministic_checks(record)}
                          for identifier, record in decisions]}


def adjudicate(package, grader_output=None, evaluator_error=None):
    """Validate model citations/shape; preserve evaluator failures as review work."""
    results = []
    try:
        rows = grader_output['results']
        if len(rows) != len(package['decisions']) or len({r['id'] for r in rows}) != len(rows):
            raise ValueError('Missing or duplicate grader results')
        by_id = {r['id']: r for r in rows}
        if set(by_id) != {d['id'] for d in package['decisions']}:
            raise ValueError('Unexpected grader result IDs')
    except (TypeError, KeyError, ValueError) as error:
        by_id = {}
        evaluator_error = evaluator_error or str(error)
    for decision in package['decisions']:
        row = by_id.get(decision['id'])
        error = evaluator_error
        if not error:
            try:
                if row['status'] not in ('pass', 'fail', 'uncertain') or not row['findings']:
                    raise ValueError('Missing status or cited findings')
                for finding in row['findings']:
                    if not all(isinstance(finding[k], str) and finding[k].strip() for k in ('dimension', 'fact', 'explanation')):
                        raise ValueError('Incomplete finding')
                    # V1 saved grades use a single quote; V2 has an explicit list of exact excerpts.
                    quotes = finding.get('quotes', [finding.get('quote')])
                    if not isinstance(quotes, list) or not quotes or not all(isinstance(q, str) and q.strip() for q in quotes):
                        raise ValueError('Missing exact answer excerpts')
                    answer = json.loads(decision['raw_output'])
                    public_text = answer.get('publicReason', '') + '\n' + str(answer.get('plan', {}).get('text', '')) + '\n' + answer.get('selectedCard', answer.get('currentCard', ''))
                    for quote in quotes:
                        if not any(quote in source for source in (decision['raw_output'], json.dumps(answer, ensure_ascii=False), public_text, decision.get('effective_plan') or '')):
                            raise ValueError('Grader quote absent from actual answer')
            except (TypeError, KeyError, ValueError) as issue:
                error = str(issue)
        quality = 'uncertain' if error else row['status']
        mechanical_failure = any(c['status'] == 'fail' for c in decision['deterministic_checks'].values())
        attribution = ('evaluator_issue' if error else 'product_error' if mechanical_failure or quality == 'fail'
                       else 'pending_review' if quality == 'uncertain' else 'no_material_error_found')
        results.append({'id': decision['id'], 'mechanical': 'fail' if mechanical_failure else 'pass',
                        'quality': quality, 'overall': 'fail' if mechanical_failure else quality,
                        'attribution': attribution, 'evaluator_error': error, 'findings': row.get('findings', []) if row else []})
    return {'rubric_version': package['rubric_version'], 'results': results,
            'scope': 'Small-sample basic evaluation; no claim of broad grading reliability.'}


def run_grader(package, output, codex='codex', timeout=180):
    import os
    import shutil
    import subprocess
    import tempfile
    import time
    output = Path(output).resolve()
    (output / 'input.json').write_text(json_text(package))
    prompt = 'Apply this rubric independently to every supplied decision. Return only the required structured result.\n' + json_text(package)
    (output / 'prompt.txt').write_text(prompt)
    schema = read_json(Path(__file__).with_name('grader-schema.json'))
    (output / 'schema.json').write_text(json_text(schema))
    start = time.monotonic()
    metadata = {'requested_model': 'gpt-6.1-sol', 'requested_effort': 'medium',
                'observed_service_model': None, 'observed_service_effort': None,
                'identity_limit': 'CLI requested configuration is recorded; JSONL does not independently expose resolved service identity.',
                'playing_model_called': False, 'isolation': 'Fresh HOME, CODEX_HOME and cwd; authentication file only copied, then deleted.',
                'wire_contracts': sorted({d.get('wire_contract', 'stage1-currentCard-plan-publicReason-v1') for d in package['decisions']})}
    error = None
    answer = None
    try:
        binary = shutil.which(codex)
        if not binary:
            raise OSError('Requested Codex executable unavailable: ' + codex)
        with tempfile.TemporaryDirectory(prefix='bridge-grader-') as temporary:
            runtime = Path(temporary)
            home = runtime / 'home'
            cwd = runtime / 'cwd'
            home.mkdir()
            cwd.mkdir()
            original_home = Path(os.environ.get('HOME', str(Path.home())))
            auth = Path(os.environ.get('CODEX_HOME', str(original_home / '.codex'))) / 'auth.json'
            if not auth.is_file():
                auth = original_home / '.codex/auth.json'
            if not auth.is_file():
                raise OSError('Codex authentication file unavailable')
            shutil.copyfile(auth, home / 'auth.json')
            (home / 'auth.json').chmod(0o600)
            config = Path(__file__).with_name('grader-config.toml').read_text()
            for skill in ('imagegen', 'openai-docs', 'skill-creator', 'skill-installer'):
                config += '\n[[skills.config]]\npath = ' + json.dumps(str(home / ('skills/.system/' + skill + '/SKILL.md'))) + '\nenabled = false\n'
            (home / 'config.toml').write_text(config)
            (output / 'runtime-config.toml').write_text(config)
            env = {'HOME': str(runtime), 'CODEX_HOME': str(home), 'PATH': str(Path(binary).parent) + ':/usr/bin:/bin:/usr/sbin:/sbin', 'TMPDIR': str(runtime)}
            version = subprocess.run([binary, '--version'], env=env, cwd=cwd, text=True, capture_output=True, timeout=10)
            metadata['runtime_version'] = version.stdout.strip()
            command = [binary, 'exec', '--ignore-rules', '--ephemeral', '--skip-git-repo-check', '--sandbox', 'read-only',
                       '--model', 'gpt-6.1-sol', '-c', 'model_reasoning_effort="medium"',
                       '--output-schema', str(output / 'schema.json'), '--json', '--color', 'never', '--cd', str(cwd),
                       '-o', str(output / 'grader-output.json'), '-']
            metadata['command'] = command
            process = subprocess.run(command, input=prompt, env=env, cwd=cwd, text=True, capture_output=True, timeout=timeout)
            metadata['exit_code'] = process.returncode
            # Persist public protocol and answer events only, never reasoning items.
            public_events = []
            tools = []
            for line in process.stdout.splitlines():
                try:
                    event = json.loads(line)
                except ValueError:
                    continue
                kind = event.get('type', '')
                item = event.get('item', {})
                if kind in ('thread.started', 'turn.started', 'turn.completed', 'turn.failed', 'error'):
                    public_events.append(event)
                elif item.get('type') in ('agent_message', 'error'):
                    public_events.append(event)
                elif kind.startswith('item.') and item.get('type') not in ('reasoning', 'agent_reasoning'):
                    tools.append(item.get('type', 'unknown'))
            metadata['observed_tool_items'] = tools
            (output / 'public-events.jsonl').write_text(''.join(json.dumps(e, ensure_ascii=False) + '\n' for e in public_events))
            (output / 'stderr.txt').write_text(process.stderr)
            if process.returncode:
                raise ValueError('Grader runtime failed with exit code %s' % process.returncode)
            if tools:
                raise ValueError('Independent grader attempted a tool: %s' % tools)
            answer = read_json(output / 'grader-output.json')
    except (OSError, ValueError, subprocess.TimeoutExpired) as issue:
        error = str(issue)
    metadata['elapsed_seconds'] = round(time.monotonic() - start, 3)
    metadata['evaluator_error'] = error
    (output / 'run.json').write_text(json_text(metadata))
    return adjudicate(package, answer, error)


def main():
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    grade = commands.add_parser('grade')
    grade.add_argument('--decision', action='append', default=[], type=Path)
    grade.add_argument('--answers', type=Path, help='Authored calibration records; never passed with expectation file.')
    grade.add_argument('--codex', default='codex')
    grade.add_argument('--timeout', type=float, default=180)
    grade.add_argument('--output', required=True, type=Path)
    regrade = commands.add_parser('regrade')
    regrade.add_argument('--run', required=True, type=Path)
    regrade.add_argument('--output', required=True, type=Path)
    regrade.add_argument('--reviewed-parser-fix', help='Review reason for the known CLI item.type=error false tool classification only.')
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    runtime_reports = []
    if args.command == 'regrade':
        if (args.run / 'runtime-failures.json').exists():
            runtime_reports = read_json(args.run / 'runtime-failures.json')
        package = read_json(args.run / 'input.json')
        try:
            answer = read_json(args.run / 'grader-output.json')
            metadata = read_json(args.run / 'run.json')
            error = metadata.get('evaluator_error')
            tools = metadata.get('observed_tool_items', [])
            if metadata.get('exit_code') != 0:
                error = error or 'Saved grader runtime did not exit successfully'
            elif tools:
                error = error or 'Saved grader attempted tools'
            if args.reviewed_parser_fix and metadata.get('exit_code') == 0 and tools and set(tools) == {'error'} and str(error).startswith('Independent grader attempted a tool:'):
                error = None
            result = adjudicate(package, answer, error)
        except (OSError, ValueError) as error:
            result = adjudicate(package, evaluator_error=str(error))
        (args.output / 'input.json').write_text(json_text(package))
        (args.output / 'regrade-source.json').write_text(json_text({'source_run': str(args.run.resolve()), 'model_called': False, 'reviewed_parser_fix': args.reviewed_parser_fix}))
    else:
        supplied = [(p.name, read_decision(p)) for p in args.decision]
        decisions = [(i, r) for i, r in supplied if 'rawOutput' in r]
        for identifier, record in supplied:
            if 'rawOutput' not in record:
                runtime_reports.append({'id': identifier, 'mechanical': 'uncertain', 'quality': 'uncertain', 'overall': 'fail',
                                        'attribution': 'runtime_failure', 'runtime_failure': record['runtimeFailure'],
                                        'evidence': record, 'findings': []})
        if args.answers:
            decisions += [(r['id'], r) for r in read_json(args.answers)]
        if (not decisions and not runtime_reports) or len({i for i, _ in decisions} | {r['id'] for r in runtime_reports}) != len(decisions) + len(runtime_reports):
            parser.error('Supply at least one decision; identifiers must be unique.')
        package = grader_package(decisions)
        if decisions:
            result = run_grader(package, args.output, args.codex, args.timeout)
        else:
            (args.output / 'input.json').write_text(json_text(package))
            (args.output / 'run.json').write_text(json_text({'grading_model_called': False, 'playing_model_called': False, 'reason': 'No model answer exists to grade.'}))
            result = adjudicate(package, {'results': []})
    if runtime_reports:
        (args.output / 'runtime-failures.json').write_text(json_text(runtime_reports))
        result['results'].extend(runtime_reports)
    (args.output / 'evaluation.json').write_text(json_text(result))
    print(json_text(result), end='')


if __name__ == '__main__':
    main()
