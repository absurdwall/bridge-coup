# Repeat-save screenshot asset repair

Commit: b81a5021636b6598e84b3e1211f71341c077823f

Native QA6 identified an opened review's screenshot URL becoming invalid after saving. LocalReviewSessionStore previously recopied its own existing asset and removed the previous asset. The workflow retained that previous URL, so its next save failed.

One regression exercises the public store seam: save external screenshot, open the record, save two edited snapshots with the opened screenshot URL, read that same URL and reopen the final record. On unchanged source this failed with writeFailed / no such file. Evidence: review2-save-red.log (1 test, 1 unexpected failure).

The store now reuses the previous safe asset only when the supplied standardized URL equals the previous owned asset and the file exists. External replacement and transactional new-asset cleanup continue through the existing copy path. Recognition callbacks and workflow state are unchanged.

Archive focused tests: 11 passed, zero failures (review2-save-focus-green.log). Full suite with BRIDGE_TEACHER_DDS_HELPER pointing at the aggregate's real .build/dds/bridge-dds: 187 passed, zero failures, zero skips (review2-save-full-green.log). git diff --check passed. Aggregate clean after commit.

Packaged native repeat-save and recognition cancel/confirm verification remains with parent QA7. No packaged acceptance is claimed by these automated tests.
