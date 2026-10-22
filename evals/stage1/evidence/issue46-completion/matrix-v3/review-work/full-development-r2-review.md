# Independent review — full-development r2

**Verdict: fail.** I reviewed only the saved r2 snapshots, outputs and public event history under `matrix-v3/full-development-r2`, using the basic/non-optimality rubric. The run legally consumed all 52 cards in 20 decisions and made 3NT; neither legality nor the final score settles semantic quality. Original Sol grades are unchanged.

| Decisions | Independent result | Finding |
|---|---|---|
| 1–6 | Pass | D3/DK and CK/CA are sound; C2/C7 preserve CQ while a higher club wins. |
| 7 | Fail | CA and CK are already played; North’s CQ outranks unseen CJ. Calling C4 toward CQ a “finesse against the unseen CJ” and warning it may lose is a false rank assessment. |
| 8–9 | Fail; one active-plan family | The d7 line wins CQ over CJ. All five defender clubs are now accounted for, leaving South C86 as established winners, reachable via HA/DA/SA. The d8 replacement says not to count another club winner; d9 keeps that. H3 is a sound follow, but the retained plan is materially wrong. |
| 10–12 | Fail; propagated plan | At d10, five tricks plus DA, HA, SA and C86 makes ten potential tricks, not “only eight” with a ninth dependent on a concession. D11–12 keep this error; S4/D5 are legal follows. |
| 13–15 | Fail; repeated root | D13 replaces the plan but again overlooks C86 while South is on lead; d14 keeps it. At d15, South is on lead with seven tricks, SA and C86, and needs two; S9’s speculative route and the claim that no ninth is guaranteed ignore an immediately cashable pair. |
| 16–18 | Uncertain; Sol overstates these | After S9 loses, the defenders have the lead. C86 remain top, but access to South is not established from these snapshots. D17’s North D6 action does not choose South’s forced discard. At d18 South discards C6 while retaining SA and higher C8—the two required winners if declarer regains the lead. This is not independently shown harmful; the active plan’s route now requires review. |
| 19–20 | Fail | At d19 North’s D8 is currently winning; after it wins, North can lead S8 to South’s SA. D20 nevertheless says the ace needs the remaining honor to be East. With North leading, East acts before South; SA wins third against either defender. This is a separate order/winner-certainty error. |

Root failures are d7’s CQ/CJ misranking, d8’s new club-inventory error after the Q/J trick, d10’s inventory/counting error, d13’s renewed omission while South is again on lead, d15’s further omission despite seven tricks and direct access, and d19–20’s failure to notice the visible D8-to-SA route. D9, d11–12 and d14 propagate active plans through `keep`. D16–18 are uncertain because the club cards are established but access after losing the lead is unresolved. The original d17–18 claim that the selected discards themselves destroy the contract route is not supported: d18 retains SA and C8, enough for the two needed tricks if reached.

Independent adjudication is **6 pass, 11 fail, 3 uncertain**. The run remains quality-fail; making the contract does not erase the false plans or winner condition.
