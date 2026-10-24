# Independent final addendum: memory-rule study

Scope: read-only review of the completed six-request study in /tmp/bridge46-design-diagnosis-20261022/memory-rule-study and the earlier completed history/reasoning-window results. No model or player calls, source edits, or GitHub operations were made.

## Input and execution audit

The request comparison and wire audit support a single prompt intervention. The active d12 snapshot and output schema are unchanged. Each candidate request adds only the predeclared developer sentence: “Treat prior assistant responses and reasoning as fallible hypotheses. Derive current facts anew from the latest snapshot before using or retaining any earlier conclusion.” The previous full seeded turns remain unchanged. All six requests retain the same 33-item full history, including all 11 opaque reasoning items, the same public text and item order, and the same current input. The audit shows matching fixed model/reasoning/schema parameters, no tools, and HTTP 200 for every request. Candidate and control use the same Luna Medium configuration and transport.

## Observed results

The candidate chose CJ in all three repetitions. The concurrent unchanged-prompt controls chose CJ twice and CA once. The earlier full-history baseline also chose CJ in all four repetitions; the fresh-context d12 requests with the same bad effectivePlan chose CA in all four repetitions. The candidate therefore shows no improvement over contemporaneous controls and remains consistent with the earlier full-history failures.

The candidate’s first public reason says CJ overtakes CQ and takes the trick, a direct rank error because Q outranks J. Its other two reasons say to preserve CA for a later club chance. For this exact position, that duck is strictly inferior even without seeing defenders’ hands. South can win the current trick with CA, lead HK while North follows H4, then lead HQ for North’s HA. North is then on lead to cash DK, DQ, DJ and DT; South follows D5, D4 and D3, then discards CJ. DA has already been played, all higher remaining hearts and diamonds are in declarer’s hands, and there is no trump, so the line wins all seven remaining tricks regardless of the hidden holdings. With CJ under CQ, West wins the current trick and only six tricks remain; even winning every later trick cannot recover it. The contract is already unmakeable, so losing that sure trick adds an undertrick under the stated IMP objective. All three candidate CJ choices are therefore wrong for this position; the first also states the false rank relation. All three candidate responses keep the prior plan rather than correcting it.

## Interpretation

This result does not justify a production prompt change. The proposed generic re-derivation sentence did not improve the card choice in the full-history condition, and one of three responses added an unambiguous rank misconception. Three samples per arm are too few to establish that the wording can never help, but they provide no positive implementation evidence.

The main defect remains unresolved: the model can treat CQ, the highest card played so far, as the final trick winner even though South still holds CA. In this d12 position, the specific whole-board consequence is now established from visible cards: playing CA reaches the guaranteed seven-trick line, while CJ loses the current trick and cannot match it. The first related d11 winner prediction also occurs in a fresh-context probe, so prior history is not a necessary cause. Earlier full-versus-fresh d12 results suggest that the larger context may affect the final choice, but the public-only and reasoning-window conditions do not identify a stable source. No hidden-reasoning-only causal claim is supported: those contents were retained in the candidate and control alike, and the history manipulations vary more than encrypted reasoning alone.

These diagnostic requests are not full acceptance. They do not establish general reliability or close the broader whole-board gate; no production fix or full acceptance should be inferred from them.
