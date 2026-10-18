# Independent saved-output adjudication — full-reserved-r1

Frozen source `8266947`, corpus `stage1-finite-v1`, rubric `stage1-basic-v2`. Reviewed all 21 actual answers, current authorized holdings/tricks, English deltas, plan updates and original grade findings. Quality review uses decision-visible facts only; full fixture replay is separately restricted to rule/count auditing. No model/API call, regrade, source or original-evidence edit. No root/runtime failure.

**Proposed: 16 pass / 1 fail / 4 pending. Quality FAIL.** Original evaluation is 0 pass / 5 fail / 16 uncertain. The 16 uncertain rows are raw grader pass labels with empty findings, hence evaluator-output defects. Manual passes below are supported independently by concrete visible facts, not by accepting uncited labels. Four substantive grade-severity disputes remain pending, never silently passed.

| Decision | Proposed | Independent basis |
|---|---|---|
| 1 | pass | North H4 follows low under West HJ, retaining HQ; the plan and reason explicitly locate the intended winning HA in South. South HK remains another control. |
| 2 | pass | South HA beats HJ-H4-H2 while retaining HK. Current card and reason agree. |
| 3 | pass | South C3 toward North CA is a feasible club-winner route preserving CK/CQ. The later actual duck does not retroactively invalidate this sound lead. |
| 4 | fail | Current trick is South C3-West C4; North selects C5. Only East acts afterward. “South’s king and queen can take the club trick if East does not overcall” requires an impossible second South play on this trick. If East follows below C5, North C5 wins instead; the guarded East condition does not make the claimed South action feasible. |
| 5 | pass | East HT is led; South HK wins, retaining North HQ. The replacement diamond/entry plan uses actual North CA, South DA and North QJ, without assuming DK's location. |
| 6 | pass | At East HT-South HK-West H3, North H8 follows low and preserves the separate HQ. Correct rank and hand facts. |
| 7 | pending | South D2 toward North DQJ is a physically feasible finesse and no hidden DK location is asserted. “Extra trick needed for 3NT” understates existing winners: two won plus HQ, SA/SK, DA and CA/CK/CQ supply nine with transport. For example, enter North via SK/HQ, cash CA, then C6 toward South KQ; the other top winners remain accessible. However the diamond attempt itself can still retain nine even if it loses, and the spec permits non-optimal lines. Preserve the count/wording severity dispute rather than equate a plausible overtrick attempt with a material impossible route. |
| 8 | pass | On South D2-West D5, North DQ is a genuine finesse against the unlocated DK. “If it holds” is a real conditional, and DJ remains a potential subsequent attempt. |
| 9 | pass | After the failed finesse and actual HQ winner, North CA cash is sure; its remaining C6 leads toward South CK/CQ. “Use it to reach South's honors” coherently refers to winning CA then leading C6, not playing CA twice. |
| 10 | pass | South C8 follows under North CA, retaining CK/CQ. It is the lowest South club; using “discard” for a follow is harmless terminology here, not a different requested suit/card. |
| 11 | pass | North's last C6 leads toward South CK/CQ as described. Actual entry is available and no club honor has been invented. |
| 12 | pass | At North C6-East CJ, South CK covers J and preserves CQ. All current ranks and actors are correct. |
| 13 | pass | South CQ is now a sure top club; CA/CK/CJ have appeared. Cashing it before side winners is feasible. |
| 14 | pass | North is club-void and D3 is an available low discard. It preserves actual SK and DJ9. Plural “spade honors” is nonmaterial phrasing, not a specific invented second honor. |
| 15 | pass | South SA is sure and North SK remains; leading a low spade afterward is a valid route. DA/DJ are actual remaining sources after DK/DQ have visibly appeared. |
| 16 | pass | North S2 follows under South SA, retaining the separate SK. Correct current action and entry preservation. |
| 17 | pending | Primary plan DA then low diamond toward DJ is sound: after DA, DJ will be top because DK/DQ have appeared. “If that fails” is a known-inapplicable guard. The fallback “spade finesse to ... king” misnames an established SK winner, but that fallback is untriggerable and no false current card/entry is required by the actual DA play. Preserve conditional-language/severity review. |
| 18 | pending | North D9 correctly follows under DA and preserves DJ. Sole grade issue is the retained guarded fallback from 17, not a new current physical contradiction. |
| 19 | pending | South D7 toward now-top DJ guarantees the ninth trick. Sole grade issue is the same retained, never-triggered failure/finesse branch. Do not turn a correct current contract-clinching route into an invented-card error. |
| 20 | pass | Nine tricks have actually been won. North SK is a sure winner after SA appeared; cashing it for an overtrick is valid. The correct statement that the contract is already made renders the old fallback inactive. |
| 21 | pass | At North SK-East SJ, South S4 legally follows and preserves S6. SK wins; no unsupported rank or ownership claim. |

## Full execution and timing

**Full-board coverage covered independently of quality.** Independent replay returns no errors: 52 unique cards, 13 tricks, NS 10 / EW 3. There are 21 request attempts, 21 actual turn/start RPCs, 21 model-executed controlled actions, five sole-legal forced controlled actions, 25 driver opponent actions and one opponent opening-prefix action. All 26 controlled actions have valid source labels; no non-forced substitution or retry appears. One continuing thread contains 21 distinct turns. No original-grade alteration is needed to establish these execution facts.

Initial request 13.364805 s; 20 subsequent requests have median 3.997837 s and range 3.595404–6.224810 s. Request latencies sum to 97.360654 s; environment overhead 0.303472 s gives full-driver duration 97.664126 s. Last controlled action is 97.656635 s, with roughly 0.007491 s of trailing opponent/driver work. Timing arithmetic matches the trace. No failed request is reported. The sub-three-minute duration and made contract do not erase the concrete decision-4 failure or adjudicate pending claims.

Evaluator-output issues: raw pass rows 1,2,3,5,6,8,9,10,11,12,13,14,15,16,20,21 lack required findings. They are not product failures. Raw failures 7,17,18,19 remain substantive review disputes; decision 4 independently establishes quality no-go.
