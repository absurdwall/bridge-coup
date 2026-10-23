# Fixed public review regressions for issue 48

This bundle preserves eleven small source assets byte for byte. `manifest.json`
records their exact original paths, SHA256 and sizes, plus **current** expected
adjudications and their origins. Expected labels are evaluator/test metadata;
never include this README, manifest, proof answers or labels in a live player or
reviewer request. Fixed model-facing inputs remain under `fixed-review/` and
`feedback-seed/`. These are regression/diagnostic materials, not additional
acceptance cases or evidence that the 22-attempt matrix passes.

## Cases and current adjudication

| Asset | Origin and current expected treatment |
|---|---|
| `fixed-review/late-club-input.json` | Actual historical B decision 21 corrected-explanation proposal: CT is legal but loses an avoidable overtrick. Revise must address C5 rather than only improve the explanation. Public inference and both East continuations are checked below. |
| `fixed-review/incomplete-initial-input.json` | Constructed omission case on the original Walker public state. Revise for missing complete route, without fabricated card facts or demanding one unique line. Historical reviewers correctly counted three hearts and identified entry/concession timing. |
| `fixed-review/second-round-spade-input.json` | Original filename `reasonable-alternative-input.json`; bytes unchanged. This constructed second-round-SA proposal is **now expected to receive revise** for its supported conditional communication risk. Layout remains a hypothesis. The later user decision accepted this blocking finding and the complete-plan obligation. |
| `feedback-seed/{initial-snapshot,seed-proposal,seed-review}.json` | Synthetic fixed proposal plus genuine recorded Sol Medium reviewer feedback, historically delivered to a **fresh correction session**. Useful for exact-envelope/proposal association and revision regressions. Not a naturally generated same-session precursor. |

The original calibration manifest/manual assessment still call second-round SA
blocking “overblocking” and suggest a non-blocking verdict. They are copied into
`historical-provenance/` without changes to preserve the old evaluation history.
That label is **explicitly superseded** by the later feedback manifest's
`qualityBoundary` and feedback manual assessment's `policy`, together with #48's
handoff. Do not import the old expected label into a test. No paired calibration
improvement or broad reviewer reliability claim is established by those runs.

## Offline branch proof

`public-proof/late-club-branches.json` is the exact historical public proof.
`check_public_proof.py` checks copied bytes and independently replays its three
branches through the repository's existing `evals/stage1/corpus.py` material
reducer. It reconstructs the starting deal entirely from the public actual
plays, authorized current holdings and a legal public deduction; it does **not**
read the old full hidden deal or introduce a new game implementation.

At trick 12, South CJ is followed by West SJ, showing West void in clubs. North
has CT5 and South S9. The public history leaves CK/C9/SQ unplayed outside those
visible holdings. East has two cards left, so its two cards must be CK/C9 and
West's final card SQ. After C5, both legal East clubs yield eleven declarer tricks;
after CT, East CK then C9 holds declarer to ten. Thus the expected C5 distinction
comes from verified public facts/branch consequences, not a desired label echoed
by a scripted reviewer.

Run without models or network:

```sh
python3 check_public_proof.py --repo /absolute/path/to/bridge-coup
```

`offline-check.json` records the successful source-bundle check at integration
`3d3162d3ffb585e3d576239d432224b06e6fd067`, including the reducer hash. It supports
this fixed position only, not population-level strategy quality or live-review
interception. Keep proof/labels evaluator-only; no strategic tool injection is
authorized.

## Limits and integration guidance

- The historical feedback experiment observed one revision then approval, with
  no actual card execution or active-plan adoption. Its saved `state` files are
  not evidence of a process still being alive; none are bundled.
- That old experimental controller stopped on unresolved review/cap. Current
  #48 authorizes a validated latest proposal after five valid semantic rounds as
  contested play, with its matching plan. Do not reuse the old cap behavior.
- Ticket 50 separately records a **natural** production correction sequence
  under `evals/stage1/evidence/issue48/ticket50/native-correction/`; it was not
  seeded by this bundle. Its pre-repair omitted plan.text-null defect remains
  explicit in its README. This bundle neither rewrites that capture nor removes
  the requirement for final native validation of the repaired encoder.
- Historical fixed reviewer inputs omit newly required program-owned proposal
  IDs/round metadata. Preserve source bytes and use an explicitly labeled
  adapter/test envelope if exercising the current runtime; do not relabel old
  payloads as new production captures. Any derived payload gets its own hash and
  provenance pointing to the source asset.
- Only small useful inputs/provenance/proof are copied: no auth files, runtime
  state, executables, catalogs, raw encrypted history or full hidden deal.
- #52 implementer should independently review the cases, integrate under a
  durable fixture location, add public-boundary regressions as appropriate and
  freeze the new assets with its candidate. Fixture availability, offline proof
  success and reviewer approve are separate from delivered-play acceptance.
