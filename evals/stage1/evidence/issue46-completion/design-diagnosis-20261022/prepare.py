import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).parent
REPO = Path('/Users/tingranwang/.codex/worktrees/issue46-integration/bridge-coup')
RUN = REPO / 'evals/stage1/evidence/issue46-completion/development-v4/short-6-r1'
ROOT.joinpath('requests').mkdir(exist_ok=True)

def load_state(n):
    record = json.loads((RUN / 'play' / f'decision-{n:04}' / 'decision.json').read_text())
    wire = json.loads((RUN / 'wire' / f'request-{n-1}.json').read_text())
    schema = wire['text']['format']['schema']
    assert list(schema['properties']) == ['plan', 'selectedCard', 'publicReason']
    assert schema['properties']['selectedCard']['enum'] == record['snapshot']['legalCards']
    return record, schema

states = {n: load_state(n) for n in [6, 11, 12]}

def replace_plan(input_text):
    match = re.search(r'(?m)^  "effectivePlan" : ', input_text)
    assert match
    start = match.end()
    _, length = json.JSONDecoder().raw_decode(input_text[start:])
    result = input_text[:start] + 'null' + input_text[start+length:]
    expected = json.loads(input_text); expected['effectivePlan'] = None
    assert json.loads(result) == expected
    return result

def remove_winning(input_text):
    result, count = re.subn(r',\n    "winningPlay" : (?:\{.*?\n    \}|null)', '', input_text, count=1, flags=re.S)
    assert count == 1
    expected = json.loads(input_text); del expected['current']['winningPlay']
    assert json.loads(result) == expected
    return result

def remove_winning_reference(instructions):
    old = ('3. Read current.winningPlay to identify the current winner and partnership,\n'
           '   or that the trick is on lead.')
    new = ('3. Read currentTrick to identify the highest actual play and partnership,\n'
           '   or that the trick is on lead.')
    assert old in instructions
    instructions = instructions.replace(old, new)
    old = ('- "current": "toAct", "tricksWon" ("declarer" and "defenders"), and "winningPlay".\n'
           '  "winningPlay" is the highest actual play in the current trick under bridge\n'
           '  rules, with "seat" and "card", or null before the lead. Later plays may change it.\n')
    new = '- "current": "toAct" and "tricksWon" ("declarer" and "defenders").\n'
    assert old in instructions
    return instructions.replace(old, new)

fact_instructions = '''Read the complete authorized bridge position in the input JSON and answer only the diagnostic question using the response schema.
Seats N/E/S/W mean North/East/South/West. Suit codes S/H/D/C mean spades/hearts/diamonds/clubs. Ranks are A K Q J T 9 8 7 6 5 4 3 2, highest first. A card code combines suit and rank. In hands, each suit string lists its remaining ranks. currentTrick contains the actual plays so far; completedTricks contains completed plays. effectivePlan is earlier advice, not an authoritative fact.
'''

specs = []
def add(name, number, repeat, *, clear=False, winning=True, fact=None):
    record, schema = states[number]
    text = record['input']
    instructions = record['instructions']
    if clear: text = replace_plan(text)
    if not winning:
        text = remove_winning(text)
        instructions = remove_winning_reference(instructions)
    if fact == 'hearts':
        instructions = fact_instructions + '\nQuestion: How many future heart tricks can North and South take at most from their currently held hearts, counting suit rounds with both hands following? Ignore access and the lead for this question.\n'
        schema = {'type':'object','additionalProperties':False,'required':['maximumHeartTricks'],
                  'properties':{'maximumHeartTricks':{'type':'integer','minimum':0,'maximum':13}}}
    elif fact == 'clubs':
        instructions = fact_instructions + '\nQuestion: Can South win the current notrump trick using one of its current legal cards? Return canWin and that card, or null if no legal card can win.\n'
        schema = {'type':'object','additionalProperties':False,'required':['canWin','card'],
                  'properties':{'canWin':{'type':'boolean'},'card':{'type':['string','null'],'enum':['CA','CJ',None]}}}
    request = {'instructions': instructions, 'input': text, 'outputSchema': json.dumps(schema,separators=(',',':'),ensure_ascii=False)}
    identifier = f'{name}-r{repeat}'
    path = ROOT / 'requests' / f'{identifier}.json'
    data = (json.dumps(request,indent=2,ensure_ascii=False)+'\n').encode()
    path.write_bytes(data)
    specs.append({'id':identifier,'source_decision':number,'repeat':repeat,'clear_effective_plan':clear,
                  'include_current_winning_play':winning,'task':'factual-'+fact if fact else 'normal-play-output',
                  'request':str(path.relative_to(ROOT)),'sha256':hashlib.sha256(data).hexdigest()})

# Balanced predetermined order. All requests are fresh threads; no answer is used by another request.
for rep in [1,2]:
    heart_order = [('heart-full',False,None),('heart-no-plan',True,None),('heart-fact',False,'hearts')]
    if rep == 2: heart_order.reverse()
    for name, clear, fact in heart_order: add(name,6,rep,clear=clear,fact=fact)
    order=[('club-full',False,True),('club-no-plan',True,True),('club-no-plan-no-winner',True,False),('club-no-winner',False,False)]
    if rep == 2: order.reverse()
    for name, clear, winning in order: add(name,12,rep,clear=clear,winning=winning)
    add('club-before-error-full',11,rep)
    add('club-fact',12,rep,fact='clubs')

hypotheses = [
 {'rank':1,'hypothesis':'Incorrect effectivePlan anchors later responses despite correct current facts.',
  'prediction':'At decision12, clearing only effectivePlan improves CA choice relative to carrying the actual false plan, within the same winningPlay condition.'},
 {'rank':2,'hypothesis':'The derived winningPlay field/reference primes final-winner interpretation.',
  'prediction':'At decision12, removing that redundant field and its reference improves CA choice within the same plan condition. The actual currentTrick remains unchanged.'},
 {'rank':3,'hypothesis':'Continuing history contributes to the recorded errors.',
  'prediction':'Fresh one-turn requests with byte-identical current input, instructions and schema semantics make fewer observed mistakes than saved continuous turns.',
  'limit':'History is not replayed exactly; stochastic new sampling and time/routing changes prevent a clean causal attribution from this comparison.'},
 {'rank':4,'hypothesis':'Basic knowledge is available when directly requested but not reliably applied during planning.',
  'prediction':'Factual count/rank questions are correct even if normal-play responses in the same study err.',
  'limit':'Changing the task and schema is a positive-control competence probe, not a production fix or isolated proof about prompt length.'}
]
plan={'purpose':'Bounded causal-design diagnosis, not acceptance or product behavior. No production source/instructions changes.',
      'hypotheses':hypotheses,'schedule':specs,'requests':len(specs),'player':'gpt-6-luna','effort':'medium',
      'transport':'The exact production CodexPlayingTransport, called by a temporary Swift harness. No tools.',
      'policy':'Sequential; exactly one request per named entry, two predetermined replicates per condition, no retry or adaptive stop/reroll. Fresh thread per counterfactual request. A different task/schema is used only for the labeled factual positive controls.',
      'scoring':'CA choice is a narrow audited local winner test; heart-count prose requires direct inspection and is not automatically passed by absence of an exact phrase. Factual expected answers: 3 hearts; canWin=true/card=CA. No generic semantic validator or answer repair enters production.',
      'phase_limits':'Saved-witness replay is deterministic and fast. Live stochastic black-box inference cannot provide a deterministic seconds-long green/red loop or exact replay of encrypted prior reasoning. Original failures and their full context remain preserved; controlled probes test only the named variables and do not prove broad reliability.'}
(ROOT/'PLAN.json').write_text(json.dumps(plan,indent=2,ensure_ascii=False)+'\n')
(ROOT/'hypotheses.json').write_text(json.dumps(hypotheses,indent=2,ensure_ascii=False)+'\n')
print('Prepared',len(specs),'requests, with fixed order and hashes')
