# Candidate 3 Standards review

**Clear: no documented standards violation or actionable baseline smell.** Pinned review: `71eaf73e7908867179ee9c0a38e639abaab806ea...c6f9086c851e1364fd9d5a50e039e2f05e0647bc`. Current HEAD matched that pin. No Spec opinion was read.

Repository rules take precedence over the Fowler judgment baseline. Sources inspected: `AGENTS.md`, `docs/agents/{domain,issue-tracker}.md`, `CONTEXT.md`, ADR 0003, root README and `evals/stage1/README.md`. No CODING_STANDARDS/CONTRIBUTING source was found. Tool-enforced formatting/compilation checks were not recast as review findings.

Per-file/hunk assessment:

- `Sources/BridgeExpert/Resources/DeclarerInstructions.txt:76–79`, the sole production hunk: “When new public play establishes a fact relevant to the current trick or remaining line, briefly state that fact and its bearing on the play.” No hard violation. This uses decision-time public facts consistently with `CONTEXT.md` vocabulary and `docs/agents/domain.md:21–24`; it changes no ownership, pending execution or review authority governed by ADR 0003. The existing plan-operation rules remain unchanged.
- `candidate3-repair/REPORT.md:3–23`: preserves diagnosis, compatibility evidence and semantic acceptance as distinct states, consistent with the finite-acceptance boundaries in `evals/stage1/README.md`. No unsupported delivery/merge claim found.
- `instructions/{before,after}-{Declarer,Reviewer}Instructions.txt`, `instructions.diff`, `manifest.json`: intentional immutable provenance snapshots, not duplicated executable logic. Independently checked all four snapshot bytes/hashes against the two pinned commits and all 308 listed unchanged files. No discrepancy.
- `validation/environment.json`, `{swift,swift-matched-sdk,python}-result.json`, `{swift,swift-matched-sdk,python}-tests.log`, `scope-and-resource-check.json`: the initial compiler/SDK failure is retained alongside the successful selected-SDK run. Saved logs report 255 Swift tests/10 skips and 74 Python tests; saved timestamps put successful Swift before Python. These remain compatibility evidence.

Baseline judgment, not hard rules: all twelve supplied heuristics were considered. No new function/type/object hierarchy or executable control flow is introduced, so Mysterious Name, Feature Envy, Data Clumps, Primitive Obsession, Repeated Switches, Message Chains, Middle Man and Refused Bequest yield no finding. The single authoritative field edit is localized, with no Duplicated Code, Shotgun Surgery, Divergent Change or Speculative Generality. Historical snapshots intentionally repeat bytes to preserve provenance; extracting them would defeat that purpose.

Semantic green remains pending. This read-only review made no source changes, native/model calls or GitHub writes.
