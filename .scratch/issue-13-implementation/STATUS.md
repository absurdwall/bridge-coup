# Issue #13 implementation

Scope: https://github.com/absurdwall/bridge-coup/issues/13 and tickets #14–#21.
Fixed reference: prototype commit `7478abf51aa3346ba3f31b726739c99f8b5667fe`; A corner auction, compact continuous ranks, explicit play start. Prototype solver values are never product data.

Dependency graph: #14 / #15 / #16 ready; #16 → #17 / #20; #17 → #18 / #19; #14 + #15 + #18 + #19 + #20 → #21.

Implementation and acceptance are in progress. Ticket completion requires behavior tests and packaged Mac evidence; mocked requests and missing-DDS skips do not establish acceptance. Original checkout's uncommitted CONTEXT.md and prototype documents remain outside this branch and untouched.
