# General route verification hypothesis

The unchanged 352d61f Luna/xhigh development full board completed legally in
367.638 seconds (22 model decisions, four sole-legal actions, 52 cards, 10/3
tricks). This is failed development evidence, not stage acceptance. In its
actual saved outputs, decision 7 says an East CJ can beat North CQ; decisions
18–19 allow East to overtake HK after HA was consumed; decision 21 describes S9
as playing over ST. Card rank rules were already present and correct in the
actual request. Increasing effort alone did not eliminate physical errors.
The independent replay passes; legal execution does not rescue these claims.

The source change replaces only the general route sentence. It asks the player
to check proposed tricks against ranks, actual holdings, the next lead and
retained entries. It adds no case answer, card-specific advice, tool, hidden
fact, extra model, output repair or alternative execution path. Whether this
improves real play is an unproven hypothesis, not an established diagnosis.

The public Expert/driver real-run boundary is already human-confirmed. The
saved failed complete run is the behavioral red evidence. A test that merely
asserted the new instruction text would not test physical plan quality; no such
test was added. Existing public playing regression checks pass (26 tests,
zero failures; `/tmp/bridge-route-contract-swift-tests.log`). New live controls
will exercise the same public boundary, with independent factual review.

`run_route_contract_controls.py COMMIT OUTPUT` predeclares exactly one High and
one xhigh eight-decision run on the same committed contract, sequentially.
Only effort literals differ between their diagnostic builds; all source hashes
and patches are recorded. Acceptable outputs lead to a predeclared full board,
then a promising adopted production candidate still requires the finite 22
attempts and actual specialty coverage. Failed configurations remain failed;
there are no unchanged candidate answer rerolls. PR45 stays draft/unmerged.

## Second slice: hypothetical card consumption

The first change, 44d946f, did not establish an acceptable candidate. High's
eight-decision run took 69.089 seconds; its raw grade was six pass/two fail.
Independent root and Spec review left D6/D7 pending for severity, so High did
not pass. xhigh took 132.138 seconds and retained its impossible first plan
through all eight decisions (raw zero pass/eight fail). That plan cashes CA/CK,
then CQ, yet subsequently leads North's C2; all three North clubs are already
consumed. The actual first input lists CQ/C7/C2 correctly. There is no prior
plan or accumulated history at that initial decision.

The next single replacement carries hypothetical consumption forward explicitly:
what each trick consumes from both hands, which card wins, the next leader and
the resulting remaining cards/entries. This replaces the prior route sentence;
it does not accumulate case-specific restrictions. The first eight-decision
controls and all original grades remain unchanged under route-contract-controls.
New controls use the same harness at a new output directory and committed source.
This remains a hypothesis, with real public-driver outputs as the behavioral
test. No instruction-text assertion would establish that the model can plan.
