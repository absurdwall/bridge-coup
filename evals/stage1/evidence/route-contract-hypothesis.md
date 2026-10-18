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
