"""Evaluator-only public opportunity screens, never delivered-quality judgments.

No complete deal, hidden holding, preferred line or future unobserved card is
needed to establish the club-count basis and first-show-out boundary.
"""
DEFENDERS = {'east', 'west'}
CONTROLLED = {'north', 'south'}


def initial_controlled_hands(snapshot, events):
    revision = snapshot['revision']
    prefix = snapshot['events']
    if revision != len(prefix) or prefix != events[:revision] or snapshot['actingSeat'] not in CONTROLLED:
        return None
    if revision < len(events) and snapshot['actingSeat'] != events[revision]['seat']:
        return None
    if revision == len(events) and revision % 4:
        seats = ['north', 'east', 'south', 'west']
        if snapshot['actingSeat'] != seats[(seats.index(prefix[-1]['seat']) + 1) % 4]:
            return None
    if snapshot.get('controller') != 'south' or snapshot['currentTrick'] != prefix[revision - revision % 4:]:
        return None
    hands = snapshot['hands']
    if len(hands) != 2 or {hand['seat'] for hand in hands} != CONTROLLED:
        return None
    initial = {}
    for hand in hands:
        spent = [event['card'] for event in prefix if event['seat'] == hand['seat']]
        cards = hand['cards'] + spent
        if len(cards) != 13 or len(set(cards)) != 13 or set(hand['cards']) & {event['card'] for event in prefix}:
            return None
        initial[hand['seat']] = set(cards)
    if initial['north'] & initial['south']:
        return None
    return initial


def short3_windows(events, decisions):
    initial_hands = None
    valid_decisions = []
    for decision in decisions:
        try:
            snapshot = decision['snapshot']
            reconstructed = initial_controlled_hands(snapshot, events)
        except (KeyError, TypeError, ValueError):
            continue
        if reconstructed is None:
            continue
        if initial_hands is None:
            initial_hands = reconstructed
        if reconstructed == initial_hands:
            valid_decisions.append(snapshot)
    outside_clubs = 13 - sum(card.startswith('C') for cards in (initial_hands or {}).values() for card in cards) if initial_hands else None
    complete_rounds = [events[index:index + 4] for index in range(0, len(events) - 3, 4)]
    club_rounds = [trick for trick in complete_rounds if {event['seat'] for event in trick} == CONTROLLED | DEFENDERS
                   and all(event['card'].startswith('C') for event in trick)]
    second_round_end = club_rounds[1][-1]['sequence'] if len(club_rounds) >= 2 and outside_clubs == 5 else None
    core_revisions = sorted({snapshot['revision'] for snapshot in valid_decisions
                             if second_round_end is not None and snapshot['revision'] > second_round_end})
    first_showouts = {}
    for index, event in enumerate(events):
        if event['seat'] in DEFENDERS and events[index - index % 4]['card'].startswith('C') and not event['card'].startswith('C'):
            first_showouts.setdefault(event['seat'], event['sequence'])
    seen = {seat: 0 for seat in DEFENDERS}
    event_windows, event_revisions, model_revisions = [], set(), set()
    for event in events:
        defender = event['seat']
        if defender not in seen or not event['card'].startswith('C'):
            continue
        seen[defender] += 1
        third_sequence = event['sequence']
        if seen[defender] != 3 or second_round_end is None or third_sequence <= second_round_end:
            continue
        other = next(seat for seat in DEFENDERS if seat != defender)
        showout = first_showouts.get(other)
        if showout is not None and showout < third_sequence:
            continue
        def eligible(revision):
            return third_sequence < revision and (showout is None or revision <= showout)
        controlled_positions = {play['sequence'] for play in events if play['seat'] in CONTROLLED and eligible(play['sequence'])}
        actual_models = {snapshot['revision'] for snapshot in valid_decisions if eligible(snapshot['revision'])}
        # A bounded prefix may end at a model window before its actual card is recorded.
        controlled_positions |= actual_models
        event_revisions |= controlled_positions
        model_revisions |= actual_models
        event_windows.append({'defender': defender, 'third_club_sequence': third_sequence,
                              'other_first_club_showout': showout,
                              'controlled_action_revisions': sorted(controlled_positions),
                              'actual_model_revisions': sorted(actual_models)})
    return {'status': 'pending' if core_revisions else 'uncovered',
            'basis': 'Public two-round and first-show-out opportunities only; actual semantic use and prior equivalent deductions require independent review.',
            'predicate_version': 'public-first-club-showout-v2',
            'public_count_basis': {'initial_outside_clubs': outside_clubs, 'second_complete_club_round_end': second_round_end},
            'facets': {'two_round_break_decision_revisions': core_revisions,
                       'third_club_before_other_defender_revisions': sorted(model_revisions),
                       'third_club_event_only_revisions': sorted(event_revisions - model_revisions),
                       'third_club_event_windows': event_windows}}
