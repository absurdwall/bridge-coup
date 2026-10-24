# Independent review — full-reserved-r1

**Verdict: quality fail; 9 pass, 14 fail, 0 uncertain.** I used only the authorized decision snapshots, answers, and actual public play history in `matrix-v3/full-reserved-r1`, under `evals/stage1/rubric.txt`. The run completed 23 model actions and all 52 legal card events in about 107 seconds; the recorded 12–1 trick result does not establish quality. Original Sol grades remain untouched.

## Passes

- **d1–2:** North’s H4 ducks West’s HJ to South HK; South retains HA. The plan says, “Develop the long clubs from the combined AKQ holdings,” appropriately conditioning establishment on the split. d2 “Win with HK, leaving HA to protect against a later heart continuation” is sound.
- **d3–6:** C3 toward North CA, CA over C4, C5 toward South KQ after CA is gone, and CK over East CT are all feasible. For example, d3 says, “Lead C3 toward North’s CA to start developing the club suit,” and the snapshot has South C3/KQ8 opposite North CA65. d6’s “Cover East’s CT with CK” wins after CA has been played and preserves CQ.
- **d21–23:** Under North’s certain D9, d21 discards S6 and preserves clubs. East discards CJ on that trick, meeting the retained plan’s condition. d22’s “Lead C6 toward South’s CQ; CJ has been played” and d23’s “Play CQ; East is void in clubs” are supported by the public history and remaining C6 opposite CQ8; all higher club honors have appeared.

## Failures

| Decision | Finding and attribution |
|---|---|
| d7 | **Root plan error.** It says, “Avoid leading clubs into the outstanding CJ unless its location is established or another entry makes the play favorable.” CA and CK have been played; North has C6 and South CQ8. CQ outranks CJ, so this treats a safe winner as a material threat. The wording could mean avoiding a *low* club, but subsequent answers explicitly call CQ unsafe. |
| d8 | **Root rank/order error.** “Play DQ to finesse against East’s possible DK; West’s D5 is below it.” Play order is South–West–North–East: West acts before DQ, East after. DQ can finesse against West’s K, not East’s; East can cover DQ with DK. The card is legal, but the stated target is wrong. |
| d9 | **New false assessment.** The reason says, “ducking could let the defenders establish hearts while retaining their lead.” East has led HT; South holds HA and North HQ, while HK/HJ are gone. If South follows low, North’s Q is still to play and beats HT; the defenders cannot retain this trick. The HA action is safe, but that reason misidentifies the winner. Its replacement plan also reinstates the d7 club restriction. |
| d10 | **Propagation.** H8 under South’s winning HA is sound. `keep` retains d9’s false club restriction. |
| d11 | **New plan root.** “Avoid leading clubs while CJ remains outstanding” again excludes South’s certain CQ. “East’s DK and the defenders’ DQ are gone” also misattributes DQ: North played it; it is gone, so this ownership slip does not independently change the remaining diamond route. |
| d12 | **Propagation.** DJ is actually a sure winner: DK and DQ are gone, and DJ outranks any DT. The `keep` answer retains d11’s false club restriction. “East … may hold DT” does not make DT a threat to DJ; I do not count this as a separate action failure. |
| d13 | **New plan root.** The replacement again says, “avoid leading clubs into the outstanding CJ.” At this point North C6/South CQ8 remain and CA/CK are gone; CQ is still safe. |
| d14 | **Root rank error.** “Preserving North’s SK for a later lead toward it to finesse against East’s possible SQ.” SA is still in South and SK in North; after SA is cashed, SK outranks SQ. The S2-to-SA action itself is sound, but the stated spade threat is false. |
| d15 | **Propagation.** SA safely beats East’s S3. `keep` preserves d13’s club restriction; the “five tricks”/HQ text is completed history, not a replay instruction. |
| d16 | **New, material winner/count assessment error.** After seven tricks and DA, the plan seeks a ninth “accounting for East’s possible SQ” or “with the outstanding CJ in mind.” SA, CA, and CK are gone; North SK beats SQ and South CQ beats CJ. Both are available certain winners, not chances. |
| d17 | **Propagation.** D3 under partner’s DA is sound; `keep` retains d16’s false threats to SK and CQ. |
| d18 | **New, explicit root error.** With eight tricks and South on lead, the plan says, “Lead S4 toward North’s SK, hoping East does not hold SQ; the outstanding CJ makes a club lead unsafe.” After SA is gone, SK beats SQ; after CA/CK, CQ beats CJ. Either is a certain ninth trick. S4 is itself a safe lead to SK, but the plan falsely treats both sure winners as risky. |
| d19 | **Propagation.** Playing SK over West’s S9 is sound. `keep` retains d18’s false spade/club risks. |
| d20 | **New overtrick-plan error.** After nine tricks secure 3NT, it says, “seek any further safe overtricks, avoiding a club lead into the outstanding CJ.” North C6 can be led toward South CQ8; CA/CK are gone and CQ beats CJ. This is an available safe overtrick under the stated IMP objective. |

The main repeated failure family is false club danger from CJ (first d7; reintroduced in replacements d9, d11, d13, d16, d18, d20; propagated by `keep` at d10, d12, d15, d17, d19). Separate roots are d8’s finesse-direction error, d9’s heart-winner rationale, and d14’s SQ/SK rank error. I did not infer hidden defender holdings or use the final contract result to grade these decisions.
