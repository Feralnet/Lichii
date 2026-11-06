# Cade's audit of the vegetation plan — filed record
Date: 2026-11-06 · Auditor: Cade (code review / hard blockers), read-only · Coordinator: Echo
Full transcripts: `~/Pictures/oot-check/veg-2026-11-06/cade-audit-transcript.log` (first audit),
`…/cade-reaudit-transcript.log` (verification of the rewrite).

## First audit — nine findings, four blockers

1. **BLOCKER — the plan's central discriminator cannot emit anything as configured.** The per-draw
   trace lines are `LOG_DEBUG(Render_Vulkan)`; the filter in effect is `*:Info`, and filtered lines are
   never formatted. The appendices' own cited logs prove it: render trace was *enabled* in both
   grass-era runs and neither contains a single trace line. Worse, the plan's rule — "if they never
   appear, H2 holds" — would have read configuration-induced silence as a result. Two further gates
   compound it: sampling only on frames divisible by 600, and a per-frame draw cap.
   *Fix:* lift the filter **live** via the debug server's `log_filter`; require at least one observed
   trace line before drawing any conclusion; add a filter-independent counter as a witness.
2. **BLOCKER — the two-way decision is too narrow.** It omits "issued with a count but dropped or made
   ineffective inside the emulator", which the logs instantiate every session (no-pipeline skips,
   mesh-topology pipeline failures, silent record-time drops with no counter, indirect skips,
   condition-gate suppression).
3. **H1 is overstated and drawn from one side of its source.** Issue #101's own thread contains a
   **negative test** (forcing the mesh draw changed nothing) and the author's "I have not proven these
   are the leaves". The plan's "evidence against: none yet" was therefore wrong.
4. **The instrument set risks changing what is measured, and parts are inert as armed:** a hot-path
   logger that floods once the filter lifts; traces that stop silently at a line cap; an always-armed
   draw-skipping reject hash; a pinned behaviour-changing ordering switch; a frame-dump default and a
   shared capture schedule; trace switches that need values to do anything.
5. **Acceptance criteria are not falsifiable as written**, and the rate criterion cannot come from the
   instrumented run it was filed with.
6. **One evidence row's stated reproduction is false as written**; its scoped version holds.
7. **Several "ruled out" rows are not excluded by any cited artifact** — including two H2-class
   suspects declared out of the search space without a test.
8. **The state guard the plan tells the operator to trust false-alarms**: its revision extractor
   expected a lowercase suffix and the binary reports an uppercase one, so it printed
   "BINARY DOES NOT MATCH HEAD" on every run while the binary matched.
9. **Provenance defects:** an unlinked screenshot, counts quoted from a growing log, a wrong
   target-size claim in the parallel source map, an unverifiable claim.

## Verification of the rewrite (second pass)

Verdict: **not yet fit to run** — and the four instruction-level defects below are what stood between
"corrected" and "fit". Everything else in the rewrite checked out against the box.

| Finding | Verdict |
|---|---|
| F1 discriminator | addressed |
| F2 three-way decision | **partial** — the class-(c) witness is Debug-level and the prescribed lift raised only one namespace |
| F3 hypothesis overstated | addressed |
| F4 instrument traps | **partial** — capture pairings were stated wrongly; no launch path armed the observer set |
| F5 criteria | **partial** — metric and tool unnamed; the log criterion had no baseline; the rate criterion's header field had no emitter |
| F6 evidence row | addressed |
| F7 ruled-out rows | **partial** — the caches row was classified both ways |
| F8 state guard | addressed (verified: it now reports a match) |
| F9 provenance | **partial** — a cited file did not exist; two logs' location was wrong; one claim unsupported |

**New problems raised, all now fixed in v2 or the launcher:** the log criterion had no baseline (a
baseline run is now run-sequence step 0); the visual criterion named no metric (now MAE on a named
crop, with the AE trap called out at ~17×); no launch path existed and the default mode armed two of
the plan's own exclusions (now `oot-debug-run --all-instruments`, with the default mode explicitly
warned against); the suppressed-draw witness needed its namespace lifted (now included); the debug
server was missing from the arm list (now armed by that mode); the capture pairings were wrong (now
stated correctly); the caches row was classified twice (now under Open, no artifact); "record it in the
run header" had no emitter (the launcher's header now emits the reject hash, the read-ordering value
and the split mode); and the small record-link defects (a filed audit record now exists, log locations
corrected, the unsupported address claim withdrawn, the line-cap note scoped to the trace that
actually hit it).

## What the auditor could not verify read-only

The state tool's rebuild path; the observation run itself; that the live filter accepts the exact
filter string; per-image run linkage in the archive; the exact time a config line was added; and that
#101's quoted negative test reproduces on this box.
