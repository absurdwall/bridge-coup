# 桥牌教学第一版：从截图到 IMP 做庄复盘

Status: ready-for-agent

产品底板、A 版视觉方向、测试边界和本地 tracker 均已由用户确认。本 spec 已发布；实现 tickets 的拆分和依赖关系尚待确认，尚未开始开发。

## Problem Statement

用户在打牌后和复盘时拥有牌局截图，截图可能包含四手牌，也可能只包含自己的手牌或部分过程。现有软件可以给出双明手结果，但没有充分解释玩家在当时可得信息下应该如何思考、制定计划、比较路线并调整打法。

用户是理解基础概念的牌手，主要打 IMP，常见为 8 副或 12 副一组。需要的是围绕具体牌局的高质量教学，讨论读牌、概率、安全打法、复杂组合和弃牌；同时不能忽略决定本局成败的基础技巧。第一版应尽快形成真实可用的 Mac 复盘流程，而非完整桥牌平台。

## Solution

提供个人使用的 Mac 应用，以用户选定的 A「并排工作台」为视觉基准：浅色界面，左侧牌面与核对入口，右侧教学模式、分析内容和追问。

用户导入截图后，对照原图检查并修改识别结果，确认分析视角和时点，再点击“做庄计划”或“分析这一步”。应用只把决策时信息作为教学依据，针对影响当前判断的缺口追问，或明确给出条件分析。完整牌面满足条件时，另用 DDS 做有限的双明手核验，清楚区别事后结果与当时合理决策。

优先通过官方 Codex runtime 的 ChatGPT 登录接入真实教学能力。保存牌局材料、修正后的牌面与教学对话，以便再次打开继续复盘。第一版重点是做庄教学和关键出牌分析，详细叫牌体系支持后置。

## User Stories

1. As a bridge player, I want to open the app on my Mac, so that I can review hands where I normally study.
2. As a bridge player, I want a light side-by-side workspace, so that I can compare the cards and teaching without losing context.
3. As a bridge player, I want to import a screenshot, so that I do not have to transcribe a complete deal before starting.
4. As a bridge player, I want to inspect the original screenshot beside its recognized information, so that I can identify recognition mistakes.
5. As a bridge player, I want to correct a wrong card or restore an omitted ace, so that analysis uses the actual material.
6. As a bridge player, I want missing information to stay unknown, so that the app does not invent cards to complete a deal.
7. As a bridge player, I want obvious card contradictions to be shown, so that invalid positions are not sent to the solver as confirmed facts.
8. As a bridge player, I want to identify my seat and the decision point, so that teaching reflects the situation I faced.
9. As a bridge player, I want to supplement the contract, lead or relevant play history, so that the app can answer my actual question.
10. As an IMP player, I want IMP to be the default context, so that I do not repeatedly choose my usual scoring method.
11. As an IMP player, I want risk and reward explained for the specific deal, so that safety play is not reduced to automatic conservatism.
12. As a bridge player, I want to click a button for a declarer plan, so that I receive a coherent route rather than isolated card advice.
13. As a bridge player, I want the plan to explain winners, losers and entries where relevant, so that I understand the order of play.
14. As a bridge player, I want meaningful alternative lines and their assumptions, so that I can understand why one is preferred.
15. As a bridge player, I want the plan to explain responses to new information, so that I can adjust when the actual distribution emerges.
16. As an experienced player, I want concise explanations without routine definitions, so that the teaching respects my level.
17. As an experienced player, I want a basic technique explained when it is decisive in this hand, so that familiarity does not hide a missed idea.
18. As a bridge player, I want to analyze a key play decision, so that I understand a concrete choice and its consequences.
19. As a bridge player, I want to ask follow-up questions in the same review, so that I can explore the reasoning in depth.
20. As a bridge player, I want only relevant missing information requested, so that partial screenshots remain useful.
21. As a bridge player, I want facts, assumptions and inferences distinguished, so that I can assess the explanation.
22. As a bridge player, I want probability claims to disclose their basis, so that unsupported precision is not presented as calculation.
23. As a bridge player, I want teaching to exclude subsequently revealed hidden cards, so that hindsight is not mistaken for good judgment.
24. As a bridge player, I want double-dummy results for a sufficiently specified position, so that concrete trick claims can be checked.
25. As a bridge player, I want the assumptions and position used by the solver shown, so that I know what a verified result actually proves.
26. As a bridge player, I want incomplete positions to remain available for teaching, so that solver requirements do not block all learning.
27. As a bridge player, I want previous analysis marked outdated after a correction, so that I do not rely on an answer about different cards.
28. As a bridge player, I want to reopen a saved review with its material and conversation, so that I can continue learning later.
29. As a bridge player, I want access through a supported Codex sign-in path, so that I can use my available subscription access where supported.
30. As a bridge player, I want interrupted recognition, teaching or verification to preserve my input and allow retry, so that service failures do not erase my work.
31. As a bridge player, I want to distinguish demonstrations from actual model and solver results, so that a convincing UI is not confused with working analysis.
32. As a bridge player, I want teaching in Chinese using normal bridge terminology, so that explanations fit how I review hands.

## Implementation Decisions

- **Product boundary:** a personal Mac application for post-play study, with the approved A layout. Prototype code is reference material to rewrite, not production code to promote unchanged. The prototype's working name is not a final branding decision.
- **Main application boundary:** expose a cohesive review-session workflow covering import, recognition confirmation, decision context, teaching, follow-up, correction and reopen. Keep tests centered on its externally visible behavior, rather than creating tests for every internal helper.
- **Distinct responsibilities:** the review workflow owns session state; a model integration handles recognition and teaching requests; a solver integration handles full-information calculation; local storage retains review material. Keep integration details replaceable without exposing them in the teaching flow.
- **State and provenance:** retain original material, editable recognized information, user corrections, decision context and teaching outputs as distinct concepts. Each analysis is associated with the information version it used. A correction invalidates dependent teaching and solver results; late responses for old versions must not become current answers.
- **Recognition:** support partial materials. Recognized results are candidates for confirmation, not automatically verified truth. Detect basic contradictions such as duplicate known cards and impossible known card counts. Incomplete positions remain incomplete; validate counts in the context of the selected decision point, not by demanding 13 remaining cards per player in every position.
- **Knowledge boundary:** recognition may inspect the whole screenshot, but teaching must use a separately constructed decision-time view. A fresh teaching context must not inherit the original full-information screenshot, hidden cards, future plays, recognition conversation or solver outputs that reveal hidden information. Returning from an explicitly marked full-information comparison must not contaminate later decision-time teaching.
- **Decision context:** capture only information needed for the question, including seat, visible hands, contract, lead, relevant prior play and vulnerability when material. A local event timeline may be minimal; arbitrary play reconstruction from a single screenshot is not promised.
- **Teaching behavior:** make declarer planning the primary mode and key-play analysis the secondary mode. Provide a recommendation, meaningful alternatives, relevant assumptions and adaptation to new evidence, without forcing every answer into a long template. Advanced topics are discussion capabilities, not a promise of an exact probabilistic engine.
- **Scoring:** default to IMP. Compare safety and overtrick opportunities in context; do not fabricate a running match score or assume a particular competition conversion system from the reported 8/12-board format.
- **Model access:** first validate the documented official Codex app-server route for sign-in, images and continued conversation. Keep credentials managed by the supported runtime; do not treat subscription tokens as generic API keys. Runtime absence, account limits and login interruptions must be visible and recoverable. A separate direct API-key integration is a fallback option, not a second required provider for first-version completion.
- **Finite solver scope:** prefer DDS for confirmed complete positions. Validate four remaining hands, trump, turn/current trick and other necessary context before invoking it. Initially compare legal next-card results rather than building a full interactive play simulator. Translate results to declarer trick totals or contract outcomes only with the additional necessary context, explicitly respecting which side and remaining tricks the raw result describes.
- **Solver honesty:** show unavailable, invalid, failed and successfully verified states distinctly. Never replace a failed calculation with an invented number. Results prove only the specified full-information position; they do not establish the best decision under uncertainty.
- **Saved reviews:** retain original screenshot, corrected card information, decision context, conversation and result provenance locally. Reopen into the same review; keep outdated results marked. Do not add cloud synchronization or account-sharing infrastructure.
- **Failure recovery:** preserve current material on recognition/model/solver failures; support an explicit retry without silently duplicating user actions or overwriting a newer correction.
- **Technology selection:** no production stack or dependency version has yet been selected or tested. The first thin application slice selects and records the minimal Mac stack and a working supported runtime version. The DDS slice records its working version and packaging requirements. These are implementation decisions to resolve within the slices, not claims that the integrations already work.

## Testing Decisions

- **Approved main seam:** drive the review-session workflow at the highest practical application boundary: import → confirm/correct → generate teaching → follow up, plus save/reopen. Assert the behavior a user observes and the data permitted to cross external boundaries, not private method calls or exact generated prose.
- **Prior art:** the bridge project currently contains a domain glossary, design records and a disposable visual prototype. It has no production application, existing test suite or proven service boundary to reuse. A is visual reference, not automated correctness evidence.
- **Deterministic workflow checks:** substitute controlled model/recognition responses at the external boundary to reproduce missing information, an omitted ace, wrong cards, failed requests and delayed responses. Verify correction propagation, outdated results and recovery. Such checks do not establish real recognition or teaching quality.
- **Information isolation checks:** use paired reviews with identical decision-time information and different hidden hands. Check that decision-time requests contain the same permitted facts and no hidden material, future play or solver leakage. Follow-up and mode switching must preserve this boundary. Do not demand byte-identical natural-language answers from nondeterministic live models.
- **Real solver checks:** use independently known complete deals and small end positions, including legal-card comparison, side-to-move and partial-trick cases. Assert exact expected results and correct result interpretation. Include incomplete and contradictory positions that must not be reported as verified. Do not derive expected results by calling the same solver under test.
- **Real model acceptance:** exercise the supported live sign-in/image/text path and evaluate Chinese teaching on a small recorded set of complete and incomplete materials. Assess factual card use, route consistency, IMP reasoning, uncertainty, missing-information questions and treatment of a decisive basic technique. Record model/runtime context and concrete deficiencies; fluent writing alone is not a passing criterion.
- **Actual Mac acceptance:** open the actual built application and walk through screenshot import, correction, plan, follow-up, key-play analysis, a genuine DDS calculation and reopen. Verify A's readable side-by-side layout. Browser prototype behavior or mocked integration checks cannot substitute for this evidence.
- **Evidence separation:** report deterministic workflow checks, real solver checks, real model teaching quality and direct Mac acceptance separately. If login, live quality or packaging remains blocked, do not describe the whole app as accepted.

## Out of Scope

- Mobile share extensions, multi-user access, cloud synchronization and public service deployment.
- Detailed 2G1/CCBA/Precision conventions, manual discovery/ingestion and full bidding pedagogy.
- MP-specific teaching, tournament scoring and 8/12-board match management.
- A full bridge playing platform, arbitrary interactive deal replay, comprehensive practice-course generation or a training curriculum.
- Exact single-dummy success probabilities, distribution-sampling infrastructure and guarantees of optimal decisions under incomplete information.
- Bulk hand import, automatic reconstruction of missing history and guessing hidden cards to make an input complete.
- Replacing the official Codex authentication lifecycle with a custom token-extraction or third-party OAuth flow.
- Implementing both subscription and direct API-key providers as a requirement of the initial release.
- Shipping the prototype's alternative B/C layouts, its fixed example teaching or its variant switcher as production behavior.

## Further Notes

- The user selected A explicitly: “A 很好，就A。” The design source is preserved on the standalone repository branch [`archive/bridge-ui-prototype`](https://github.com/absurdwall/bridge-coup/tree/archive/bridge-ui-prototype/prototype); it is a snapshot of source commit `b27def74a42385989fea48f31ad8aa4ed443ac8a`. This records a visual decision, not functional acceptance.
- At the time this specification was drafted, the integration paths had not yet been exercised locally. Current implementation and evidence are recorded in the [ticket index](README.md).
- Ticket publication follows a separate review of vertical-slice granularity and true blocking edges. No application-layer refactor is needed before slicing because no production application exists yet.
- The first slice should expose a useful real teaching path while testing authentication feasibility. DDS can be integrated through manually confirmed complete positions without waiting for screenshot recognition, avoiding an artificial dependency.
