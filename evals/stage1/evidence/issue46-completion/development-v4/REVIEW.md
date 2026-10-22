# v4 bounded development disposition

**Not accepted.** This is a three-scenario development check of source `8a0c5181901ce2bdae51442d3caf05511b86f638`, not a final 22-attempt acceptance matrix. The prior v3 matrix remains unchanged and cannot be combined with these samples.

## Fixed change and procedure

The only runtime/instruction change after v3 aligns existing output properties, output enumeration and example ordering to **plan → selectedCard → publicReason**. The nested plan order remains update → text. Every field meaning, plan operation, objective, decision process, example value, input fact, corpus, rubric, parser, legal-card enum, history setting and model/tool configuration stays unchanged.

[DEVELOPMENT-PLAN.json](DEVELOPMENT-PLAN.json) predeclared one run each of short-3, short-5 and short-6. All three were completed sequentially with no reroll, answer repair or human controlled substitute. Each uses 12 actual Luna Medium requests. Independent grading uses Sol Medium. Final source/runtime preflight still matches the frozen hashes.

## Results and independent disposition

| Scenario | Original Sol quality | Independent disposition |
|---|---|---|
| short-3 | 12 pass | Basic quality and the two-round/justified-retention facet pass. The separate third-club-before-discard model-decision facet is unclaimed; original saved coverage remains pending. |
| short-5 | 7 pass, 2 fail, 3 uncertain | **Pending:** 7 pass, 0 proven fail, 5 uncertain. The DJ phrase can refer to history; diamond-entry and sufficient-route questions remain unresolved. |
| short-6 | 1 pass, 11 fail | **Fail:** independent review finds 1 pass, 8 fail, 3 uncertain, upholding the four-heart count and CA/CQ errors while downgrading ambiguous diamond-entry wording. |

Original grades/summaries are unchanged. The independent short-5 reviewer revised an initial interpretation after considering the full wording; both drafts are retained. Pending is not pass. One successful short run does not establish causal benefit from output ordering or satisfy final acceptance.

## Directly checkable short-6 defects

- Decision 6 input has North HA43 and South HKQJ. The replacement says “Cash the heart honors for four tricks.” With three hearts in each hand, at most three heart tricks can be taken. Decisions 7–10 retain this false count.
- Decision 11 input has West leading CQ and South still holding CAJ. The plan calls it “West’s club winner” and a losing trick; CA can beat CQ.
- Decision 12 input shows CQ–H3–C9 with South CAJ to act. It selects CJ and calls CQ winning. CA can win now; HK then HQ (North H4 then HA), followed by North’s four established diamonds, provides all seven remaining tricks. This does not require guessing hidden defenders. The contract is already down, but unnecessarily conceding another trick conflicts with the scoring objective.

These are basic rank/count/current-position defects, not a demand for expert-optimal strategy. Reordering outputs did not remove them. The remaining issues do not have a confirmed snapshot, schema-parsing or transport cause; adding more fixture-specific prompt prohibitions or repairing answers would not demonstrate the agreed model behavior.

## Wire and engineering evidence

[Wire audit](wire-and-thread-audit.json) confirms all 36 requests: Luna Medium, all_turns, empty tools, new schema root order and matching raw output order, 36 HTTP 200 responses, three distinct continuing board threads, no playing retry. Public input/output has no CJK text; opaque reasoning language and internal service routing are not asserted.

The three short playing durations are 44.168, 41.968 and 40.556 seconds. They are not complete-board timing claims. Offline: 234 Swift tests with 10 preexisting skips, 53 Python tests, zero failures. Both Luna Max source-review axes find no new concrete defect; the native HTTP boundary regression was migrated to the new contract expectation without removing other assertions.

## Disposition

This candidate is not eligible to claim Stage 1 completion. A fresh 22-attempt matrix has not been run for v4: known development failures first require a justified correction or a newly agreed model/design direction. No unchanged-candidate retry was used to search for a passing sample. No higher-effort player, second in-play reasoner, strategy engine or automatic output repair was introduced. PR #47 remains draft and requires explicit human approval to merge.
