# Standards Review — Quality Correction v2

Base: `dbc6596206949d1c2da1ec32d1ce98f75f7477ec`  
Target: `4fd65bfae21263e0ab3d38a5ea1b9a2dd6a5ed4f` (`codex/issue46-quality-v2`)

## Standards and findings

No new hard standards violation or concrete defect found in the three active code changes.

- The instruction edit is limited to DECISION PROCESS step 2 in `Sources/BridgeExpert/Resources/DeclarerInstructions.txt`. It asks the model to check an unfinished line against remaining cards, entries, possible higher cards, won tricks and remaining sources before retaining or replacing a plan. It leaves the approved objective, schema, runtime and other instruction sections intact.
- In `evals/stage1/evaluate.py:19–24`, parent RPC is read only when the decision directory lacks its own `rpc.jsonl`. Existing turn correlation checks both thread and turn IDs, and the new `test_interrupted_board_certifies_only_its_own_turn_from_shared_rpc` exercises matching and wrong-thread cases. This supports interrupted evidence without inventing a final trace.
- The deferred `acceptance.py` module-boundary observation from v1 is unchanged and remains nonblocking; this correction does not call for architectural cleanup.

The parent reports 53 Python and 31 Swift playing tests passing. I performed static review only; no tests, live calls, GitHub actions, or repository edits were made.
