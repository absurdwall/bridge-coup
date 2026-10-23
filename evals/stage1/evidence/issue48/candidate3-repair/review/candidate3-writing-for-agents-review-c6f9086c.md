# Candidate 3 independent writing-for-agents review

**Clear: no actionable instruction-writing defect.** Pinned baseline `71eaf73e7908867179ee9c0a38e639abaab806ea`, head `c6f9086c851e1364fd9d5a50e039e2f05e0647bc`. Applied `/Users/tingranwang/.agents/skills/writing-for-agents/SKILL.md` independently of the implementer's self-check; no Spec opinion was read.

The only production change is `DeclarerInstructions.txt:76–79`, replacing the one-line `publicReason` definition with:

> a brief explanation of the current choice and its public basis. When new public play establishes a fact relevant to the current trick or remaining line, briefly state that fact and its bearing on the play. Keep unresolved holdings conditional.

**Co-location / hierarchy:** the behavior belongs beside the field the player authors. The existing decision process already connects card, plan and reason; the changed field definition supplies the missing observable explanation duty at its authoritative site. It does not add another planning sequence or scatter a separate “inference” procedure through the prompt. Existing planning/input references continue to define facts versus hypotheses; they are not competing output definitions.

**Positive, observable target:** the trigger is newly established, relevant public play; the requested result is a brief statement of the fact and its consequence for the current play or remaining line. That output can be checked against the authorized snapshot. “Keep unresolved holdings conditional” supplies a positive epistemic target. No internal reasoning transcript is requested. Relevance still requires bridge judgment, appropriately; the text does not demand narration of every routine card.

**Pruning / scope:** this is three net lines addressing the documented C2 observability gap, not another generic thoroughness instruction. It includes no board/rank/distribution, reference answer, localization quiz, route prescription or new field. Reviewer instructions remain byte-identical. Existing `keep`/`replace`/`withdraw` semantics and `:92–97` critical-resource checks remain the sole plan-lifecycle authority: no forced replacement, additional reviewer block, retry or acceptance shortcut is added.

**Limits:** the interpretation is coherent, but wording review and 255-Swift/74-Python compatibility evidence cannot establish changed model behavior. The preserved report correctly leaves semantic green pending the independently adjudicated, newly frozen strict 22-attempt cycle 3. No prompt-phrase test or later successful result is substituted for that evidence.
