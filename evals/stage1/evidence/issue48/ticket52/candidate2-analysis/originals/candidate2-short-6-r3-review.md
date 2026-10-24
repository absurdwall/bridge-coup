# Candidate 2: short-6-r3 independent public-information adjudication

**PUBLIC REVIEW FINAL: PASS. Delivered decisions: 12 pass, 0 fail, 0 uncertain.**

Frozen source: `0a307cbde5498ed24b73da0d781cb9113ce92180`. Evidence root: `evals/stage1/evidence/issue48/ticket52/candidate2/short-6-r3` in the assigned worktree. This public-information quality judgment is complete and saved before separately authorized hidden-environment coverage inspection. Environment findings must not modify this report or become player knowledge.

## Authority and scope

I inspected only the completed immutable attempt, after `playing-outcome.json` existed with exit code 0. Every delivered answer was assessed against its canonical authorized snapshot/history and effective plan. I then reconciled the saved native grade after grading exit code 0 and evidence available. No hidden fixture, other unfinished attempt, future card as earlier decision-time information, new model/native call, live feedback, source/raw/grade/index write or GitHub action was involved in this review.

The trace contains 12 model decisions, 2 forced controlled cards and 13 opponent actions after the initial opening lead. All 12 deliveries are review-approved; that is provenance, not bridge-quality evidence. There is one initial replacement and eleven keeps. The bounded trace ends after North follows C5 under CA, completing trick 7: declarer 4, defenders 3, `complete: false`. No completed contract is recorded.

## All delivered decisions

Each row judges the current card, publicReason and the full actual active plan, including its feasible unfinished remainder. No serious material failure or unresolved strategic question was found; therefore no failure counterbranch is asserted.

| Decision | Card / operation | Independent quality finding |
|---|---|---|
| 0001 | S7 / replace | **Pass.** “Aim for nine tricks: one spade, three hearts, four diamonds and the club ace.” Authorized SA/CA supply two; South KQJ opposite North A43 gives three hearts; KQJT9 opposite 5432 gives four diamonds after DA. “cash HK and HQ, following with dummy's small hearts; retain HA as the vital diamond entry, with HJ subsequently falling beneath it” makes the critical transfer concrete. The plan allows repeated DA hold-up and CA recovery of a club return. Its hold-up protection is conditional and explicitly cannot guarantee every layout. S7 is a valid low follow to SK. |
| 0002 | S3 / keep | **Pass.** “Duck the opening spade, preserving the ace” implements the first duck against SK–S7–S4 with South A93. SA9 and all heart/diamond/club resources remain, so the active route fits. |
| 0003 | S9 / keep | **Pass.** “exhausts East's spades if they began with three” expressly states the relevant condition. Against SQ–S8–S5, South A9 can legally duck S9 and reserve SA for the third round. The answer does not claim East's unseen original length is known. |
| 0004 | C4 / keep | **Pass.** “Discard a spare club, preserving all diamonds and the heart entry while South wins with SA.” North is void in spades and holds CT54/DKQJT9/HA43; South still has SA. C4 preserves all required source and entry cards and leaves two North clubs. |
| 0005 | HK / keep | **Pass.** “Cash the first of two heart honors, preserving dummy’s ace as the entry to the established diamonds.” South has just won SA and holds KQJ; North has A43. HK starts the specifically planned heart preparation. “established diamonds” describes the intended later source: the same active plan explicitly says DA still must be driven out. This is not a material assertion that DA is already gone. |
| 0006 | H3 / keep | **Pass.** “Follow low, preserving HA as the entry to dummy’s diamonds.” On HK–H5, North A43 can follow H3, allowing HK to win and leaving A4 for the next two heart rounds. South retains HQJ. |
| 0007 | HQ / keep | **Pass.** “Cash HQ while dummy follows low, leaving HA as the entry after the diamond ace is forced out.” HK has already won; South QJ and North A4 permit HQ/H4, leaving the specifically reserved HJ-to-HA transfer intact. |
| 0008 | H4 / keep | **Pass.** “Preserve HA as dummy’s entry after the diamond ace is driven out.” On HQ–H6, North A4 follows H4. This executes the second low-heart follow and leaves HA opposite South HJ; it does not spend or invalidate the named critical transfer. |
| 0009 | D2 / keep | **Pass.** “Lead toward dummy’s diamond honors to force out DA, keeping HA available to reach the established winners.” South is on lead with D5432/HJ/CA; North holds DKQJT9/HA. The diamond concession can now be started without using the heart entry. Three tricks are won; four diamonds, HA and CA can supply six more. |
| 0010 | DK / keep | **Pass.** “Play the king to drive out DA, continuing diamonds if East ducks while preserving HA as the entry.” D2–D6 is the actual trick and East has yet to act. DK is a legal establishment honor. If East does not win it, North can continue diamonds; no actual DA location is claimed. If DA wins, the active CA recovery and HJ-to-HA access remain feasible. |
| 0011 | CA / keep | **Pass.** “Win immediately, then cross with HJ to HA and cash the four diamond winners for nine tricks.” Public history now shows East won DK with DA and led CK. CA wins this lead. With three tricks already won, CA + HA + QJT9 supplies six more; South HJ and North HA are still explicitly available. This follows the initial club-return branch and requires no replacement. |
| 0012 | C5 / keep | **Pass.** “Follow low under the ace; then cross to HA and cash dummy’s four diamonds to secure nine tricks.” North CT5 follows C5 to CK–CA–C2, completing South's fourth trick. South still has HJ opposite HA and North has QJT9. The five-trick remainder is physically feasible; no club return to South is needed because CA is now cashed. |

## Resource and lifecycle check

The plan budgets two spade losses plus DA, leaving nine tricks. Actual losses through trick 7 are precisely SK, SQ and DA. The initial five-card diamond source loses DK to DA, leaving four winners QJT9. Heart accounting is three partnership tricks: HK, HQ, and HJ overtaken by HA. North's H3/H4 are spent under the first two, so neither the named HJ nor HA is prematurely consumed. CA is reserved for the actual CK switch and is used exactly as the plan anticipates.

All keeps retain a workable remainder. Decisions 0002–0004 perform the spade phase; 0005–0008 perform the named HK/HQ preparation; 0009–0010 establish diamonds; 0011–0012 perform the stated CA recovery. These completed phases do not need replacement merely because their cards have been spent. At the final delivery, South still has HJ and North HA/QJT9, so the unfinished critical transfer is concrete and available. The club switch changes the actual defense, but it is already an explicit branch of the original plan.

## Actual coverage, separate from quality

- **Two-round hold-up executed:** model S3 ducked SK, model S9 ducked SQ. North's S8 second-round follow and South's third-round SA were forced sole-legal cards. C4 on the third spade was a model discard choice.
- **Defensive spade continuation executed:** West led SK/SQ/SJ and East followed S4/S5/S6. The actual public history does not prove East exhausted all its spades; three follows and the later switch are not a public void.
- **Heart preparation executed before the concession:** model HK/H3 and HQ/H4 cashed the two South winners while retaining HJ-to-HA. Unlike a prospective instruction, those four preparation choices are actual events.
- **DA concession executed:** model D2/DK lost to East's DA on the first diamond round. Repeated DA hold-up and later diamond-establishment rounds were not exercised.
- **New defense and control recovery executed:** East actually led CK after winning DA; the model chose CA, and North's model C5 completed the club trick. This is an actual switch and successful control recovery under the planned club-return branch.
- **Later entry use and diamond cashing remain prospective:** the bounded trace ends after the club trick with four declarer tricks. HJ-to-HA, HA's win and the four diamond cashes are feasible but have not actually occurred. No completed-contract result is credited.
- **Optional information facets unexercised:** only one club round occurs, so there is no third-club localization window or subsequent correct semantic use of it. No hidden defender lengths are credited as player knowledge.

## Saved native grades

The raw independent native grader returns 12 pass, 0 fail, 0 uncertain; the saved evaluation reports mechanical, quality and overall pass for all 12. My overlay agrees on all 12 quality judgments, with no raw-grade dispute. These labels and runtime approvals were reconciled after the decision-specific public-card reasoning rather than used as proof of quality.

SHA-256 at public review finalization:

- `play/trace.json`: `2649994cb2652dda827246e7b0809427cecb135b3d431c3c434df2c26af79e1c`
- `grade/input.json`: `46a255fde76901434cda4d18e73a624c6c2f2dbf4f1e3600b2ec5fbeace4095c`
- `grade/evaluation.json`: `f48f8c9ffaca82f1fff835d2b6dc3d5a572eedbf62f569b85c7667b712e8c9be`

This attempt quality pass does not establish candidate-wide acceptance. Any subsequent evaluator-only environment proof is a separate artifact and must preserve this report unchanged.
