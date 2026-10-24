# Candidate 2 short-3-r1: independent third-club-first facet check

**Disposition: demonstrated in decision-0010, revision 18.** This is an independent coverage judgment, not the all-12-decision quality review or matrix acceptance. Source: frozen `0a307cbde5498ed24b73da0d781cb9113ce92180`; evidence root: `/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup/evals/stage1/evidence/issue48/ticket52/candidate2/short-3-r1`.

## Public opportunity, reconstructed independently

`grade/input.json` initial authorized holdings contain South CAK864 and North CQ72: eight partnership clubs, hence five outside. Actual club rounds in the decision-0010 authorized prefix are CA/C3/C2/C5 (sequences 4–7) and C4/C9/CQ/CT (8–11). Each defender followed twice. This establishes 3–2 without identifying the long defender.

At revision 18 the actual unfinished trick is South CK, West CJ (sequences 16–17), with North acting. West's C3/C9/CJ accounts for three of the five outside clubs; East's already public C5/CT accounts for the other two. East has not yet acted in this trick. The snapshot ends at sequence 17, not at the later East show-out. Thus the new localization precedes East's first failure to follow clubs (sequence 19, used only to audit the window boundary, never as decision-time knowledge).

There is no prior equivalent localization in the prefix or earlier delivered reasoning. Diamond and heart follows supply no missing-club ownership proof; no defensive agreement is authorized. Before CJ appears, either defender can still hold it consistently with these public facts. Decision-0007 says “Clubs are 3-2”; decision-0009 forecasts “Draw the last opposing club, establishing the eight and six as winners.” Neither identifies its owner.

## Actual model use, not a forced-event substitute

`play/decision-0010/decision.json` records a real player request/response at revision 18, player turn `01a16a40-f028-7d12-8b38-aded675f9a72`, with matching canonical input and a reviewed pending proposal. C7 is the sole legal card, but the delivered reason goes beyond choosing that card:

> “Follow suit as the king removes the last opposing club; South’s remaining clubs are winners.”

I read “the last opposing club” in this actual CK/CJ trick as recognizing the observed West CJ as the final defensive club, and using its exhaustion to justify the retained cashing route. That is the relevant public consequence of West holding three and East two, expressed implicitly. Requiring those seat/count words verbatim would add a criterion. Earlier advice predicted this outcome; the current reason correctly recognizes its realization before East plays, without inventing East's specific discard. A justified keep is permitted.

The immutable raw grader also passes decision-0010 and explicitly cites the five-club exhaustion before East's play; this agrees with, but does not establish, my judgment. Limits: this tests concise public semantic use in one actual window, not inaccessible internal reasoning, discretionary card choice, a mandatory replacement, every repetition's facet, or overall quality acceptance. No hidden holdings or other attempts were inspected; raw grades remain unchanged.
