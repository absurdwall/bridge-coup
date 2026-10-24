# Spec review — output-order correction v4

**Reviewed:** `7129ffd352ee332c50b08db9d71a62d069afaaeb..bbcbd1b1c1b5e8364dcc5bbb98a90b615878c365` in `/tmp/bridge46-output-order`.

No spec-scope defect found in this isolated three-file change. Issue #46 retains the `publicReason`, `plan`, and `selectedCard` schema fields, but does not prescribe JSON key order. The order chosen here matches the existing instruction sequence: replace/keep/withdraw the plan, inspect the current winner and select a legal card, then explain the choice (`DeclarerInstructions.txt:25-38`). The runtime serializer emits that order at `Expert.swift:250-255`; the output field list and two existing example objects match it. The serialized-request regression checks the actual `turn/start.outputSchema` at `PlanContractTests.swift:123-130`.

The patch leaves field names, required fields, value semantics, validation, examples’ values, and the rest of the instruction text unchanged. It adds no strategic advice or out-of-scope runtime capability. The Issue #46 spec’s separation of protocol conformance from bridge-quality acceptance still applies: the change is a schema/prompt ordering consistency correction, not evidence that model reasoning improved or that finite acceptance passed. The handoff reports the contract suite passing; this review ran no tests or live calls.
