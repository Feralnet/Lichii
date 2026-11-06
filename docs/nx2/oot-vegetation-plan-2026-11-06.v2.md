# OoT (Switch 2) — vegetation missing: investigation plan, v2
Date: 2026-11-06 · Branch `feral/oot-nx2-sync` · Supersedes v1 (`oot-vegetation-plan-2026-11-06.md`)
Record kept beside this file: v1 (`oot-vegetation-plan-2026-11-06.md`),
`…​.zephyr-addendum.md`, `…​.cade-audit.md` (the audit findings, filed), and the evidence archive at
`~/Pictures/oot-check/veg-2026-11-06/` (logs, reference frames, Zephyr's source map, Cade's full
transcripts as `cade-audit-transcript.log` and `cade-reaudit-transcript.log`). The two tracer logs
cited in E1 are **not** in the archive — they remain at `~/Pictures/oot-check/tracer-run-*.log`.

v2 exists because the first version was audited by Cade and mapped by Zephyr, and both found real
defects — including one that would have produced a **false negative read as a conclusion**. Every
change below is traceable to a finding; nothing here is a rewrite for style.

## What v2 changes (and why)

| # | v1 said | v2 does | Source |
|---|---|---|---|
| 1 | "Arm RENDER_TRACE, read `count=` per draw" | The trace lines are `Debug`-level and every log is `*:Info`, so v1's step would print **nothing** and its rule would have read that silence as "draws never submitted" (H2). Fix: lift the filter **live** via the debug server's `log_filter`; require at least one observed trace line before concluding anything | Cade F1, Zephyr §1 |
| 2 | Two-way decision: zero-count (H1) vs never-submitted (H2) | **Three-way**: (a) zero count, (b) never submitted, (c) **issued but dropped/ineffective inside the emulator** — which the logs instantiate every session | Cade F2 |
| 3 | H1 carried with "evidence against: none yet" | H1 now carries #101's own **negative test** (forcing the mesh draw changed nothing) and the author's "not proven"; H1 gets an explicit falsification condition | Cade F3 |
| 4 | "One launch with everything armed" | Observers only, with the flood/cap/mutation problems fixed; the FPS criterion moves to its own clean run | Cade F4, F5 |
| 5 | Acceptance criterion: "shows the tall tufts" | Numeric criterion with a measured floor, plus a log-based criterion, plus a separate clean run for the rate | Cade F5 |
| 6 | E3: "nothing changed on disk 02:15–03:00" | Scoped to config/cache/nand (0/0/0). The unscoped claim was false — the log tree has ~4,500 files in that window | Cade F6 |
| 7 | "Ruled out" with rows carrying no artifact | Split into **set aside with an artifact** vs **open** — the split and the read-ordering family move back to open | Cade F7 |
| 8 | (not in v1) | `oot-state`'s revision extractor expected a lowercase suffix and false-alarmed "BINARY DOES NOT MATCH HEAD" on every run. **Fixed and verified**: it now prints `f77b1c3209-HEAD` / "binary matches HEAD" | Cade F8 |
| 9 | references live in `/tmp` | The grass-era frames are archived out of `/tmp`; the mesh-error counts are recounted per archived log | Cade F9 |

## Objective

Find why the tall grass tufts beside the dirt path in Hyrule Field are not drawn, and produce either a
fix or a mechanism named from evidence.

## Acceptance criteria (numeric, falsifiable)

1. **Visual, pose-controlled.** Same save, loaded fresh, **no TAS input, camera untouched**; capture 5
   frames at `height=1440` via the debug server. Criterion: the E3–H5 crop (`1280x864+1280+576`) of the
   best frame differs from the archived grass-era frame `grass-era-b4/h01.png` by **less than the
   within-era floor measured on the same crop**. Measured calibration on 2026-11-06:
   Measured exactly as follows — **the metric is part of the criterion, not an implementation detail**:
   `magick compare -metric MAE <a> <b> null:` on the crop `1280x864+1280+576`, ImageMagick Q16 build.

   ```
   within-era difference level  h01 vs h10 (both grass era, tufts present)   6749
   across states                h01 vs m5-1 (no tufts)                      17862   (2.6x)
   across states                h01 vs now-state (no tufts)                  9520   (1.4x)
   ```
   6749 is the **widest** within-era pair measured (others 4985–6749), so the threshold is
   conservative: **accept below 6749**. The same pairs under AE read 113894 / 301432 / 160667 —
   roughly 17× larger, which would fail a tufts-present capture outright. **Use MAE.** If the metric
   is not recorded with the result, the result is not comparable.

   **The weakness is stated on purpose:** even the 2.6× pairing is not robust separation, because the
   pose differs between archived stills, and the *authoritative* capture still compares against an
   archived reference whose pose is uncontrolled. Hence: the pose-controlled capture is the decision,
   the archived frames are corroboration — and if the pose-controlled number lands between 6749 and
   9520, the honest report is "ambiguous", not "fixed".
2. **Log-based (does not need eyes).** `EDEN_DKB_FRAME_TRACE=1` prints a once-per-second summary
   carrying the zero-count-draw counter (`trace_zero_direct`). Criterion: that counter's per-second
   value at the spot, compared with **a baseline recorded in the same way in a tufts-rendering state**.
   **The baseline does not exist yet and must be produced** — no archived log contains a single DKB
   line, so "absent or unchanged" is currently undecidable. See run-sequence step 0. H1 is
   **falsified** if zero-count draws are absent or unchanged between the two states.
3. **No regression, measured separately.** A clean launch, no instruments, recording the exact
   `EDEN_NX2_DMA_WAIT_WRITERS` value in the run header: ≥ 40 fps measured from log timestamps at the
   spot. This cannot come from the instrumented run — the launcher's own doctrine says hot-path
   instruments distort the rate.

## Evidence (corrected)

| # | Fact | Provenance |
|---|---|---|
| E1 | Tufts rendered at 02:26 on `c8a6ca9dbc` | `veg-2026-11-06/grass-era-b4/h01.png` + the two tracer logs naming that rev |
| E2 | The same commit, rebuilt, shows no tufts | `m5-1.png`; **its run log is archived beside it** (`eden_log-old.txt`, rev banner `c8a6ca9dbc-HEAD`). Caveat carried: that rebuild's log shows a lowering scratch-register rejection and a skip the grass-era runs do not — an **unexplained delta inside E2 itself** and an open question |
| E3 | No config/cache/nand file changed in 02:15–03:00 | scoped `find` = 0/0/0. (Unscoped it is ~4,500 files, all under the log tree.) The only known config delta afterwards is the two `custom_rtc` lines I added at ~03:38; the pre-rtc backup is dated 03:28 |
| E4 | Caches cleared, including the prefix-local driver cache and static pipelines | wipe + relaunch, no change; **no artifact archived** — treat as open until one is |
| E5 | In `f77b1c3209` the only shader rejection is our own `REJECT_HASH` | live log, archived. Scoped to **this** binary: the `c8a6ca9dbc` rebuild log *does* carry the scratch-register rejection |
| E6 | Mesh-topology and unmapped-read counts | **recount per archived log at run start** — the live log grows, and the earlier "8" matches no archived log |
| E7 | #101 documents the symptom, a `count=0` mesh-draw lead, **and a negative test** | `gh issue view 101` |

## Set aside — with an artifact for each

Texture-flicker/quavery work is out of scope. For the vegetation hunt, these are set aside **because a
test exists**: both Eden caches and the prefix-local driver cache (wipe + relaunch); console clock
(`custom_rtc_offset=-7200` armed, log-confirmed, no change); forcing occlusion results (self-declared
**confounded** — therefore it sets aside *nothing* and is listed here only so it is not re-run as if it
were a test).

## Open — previously mis-declared as ruled out

- **The caches.** Both Eden caches, the prefix-local driver cache and the static-pipelines file were
  wiped and the result was unchanged — but **no artifact was archived**, so this sits here, not in
  "set aside". Archive the relaunch log or re-run it before treating it as closed.
- **The GPU split.** No test artifact exists. `EDEN_NX2_SPLIT=0` would test a different machine
  ("runs both on one thread"), and H2 posits split *timing*. Needs a cited test at the default split.
- **Front-read ordering** (`DMA_WAIT_WRITERS`, `SEM_FAST`, `LIST_FAST`, `FETCH_DRAIN`,
  `SPLIT_SAFE_READS`). No artifact records which values prior runs used. These change *when the front
  reads guest memory* — the exact class H2 posits.
- **The reject hash** as a vegetation factor: its identity comes from #101's hedged description, not
  from E5; no no-reject test is cited (a `noreject.png` exists, uncited).
- Save reload / brand-new file / console settings blob: no artifacts cited.
- The scratch-register rejection: open for `c8a6ca9dbc`, closed for `f77b1c3209`.

## Decision rule (three-way, with the counters named)

Run the observation launch, then read:

| Observation | Reading |
|---|---|
| Vegetation programs present in the per-draw trace with `count=0` | **(a) zero count** — guest culling |
| Vegetation programs absent from the per-draw trace entirely | **(b) never submitted** |
| Present with a non-zero count, but the same window shows `Draw skipped`, the DKB `skipped=` counter, `Render trace suppressed`, or mesh-topology pipeline failures | **(c) issued but dropped/ineffective** |

Counters to read in the **same sampled window**: the per-draw trace lines, the DKB zero-count summary,
the DKB `skipped=` counter, and `grep -c 'Draw skipped'`. **"No skip lines" is not "nothing was
dropped"** — a pipeline that fails after the draw is accepted is dropped with no counter and no log.
That hole is named, not papered over.

**Identifying "the vegetation programs" is a step, not an assumption.** Method: use the pass dump
(`capture_frame`) to get the pass and draw range covering the E3–H5 region, correlate that range with
the trace's `draw=` index, and name the vs/ps hashes there — then look for those hashes. Do this on a
frame where geometry renders (any full-res pass will do) rather than guessing from #101's addresses.

**Indirect draws carry no count** in the trace (the count lives in a GPU buffer). If the vegetation is
drawn indirectly, rule (a) cannot be tested this way and that must be said, not skipped.

## Instruments — observers only, with the traps fixed

**Launch path (added after the re-audit):** `~/.local/bin/oot-debug-run --all-instruments`. That mode
arms exactly the observer list below plus `EDEN_NX2_DEBUG_SERVER=127.0.0.1:6545` (without which there is
no live filter lift and the trace stays silent), and its header records the reject hash, the read-ordering
value and the split mode. **Do not use the launcher's default (TRACE) mode for this run**: it arms
`EDEN_NX2_3D_METHODS` (which clears `fast_maxwell3d` — an exclusion below) and `EDEN_NX2_FRAME_CAPTURE`
(whose pending flag is shared with the debug server's screenshot, which this run takes).

Arm: `EDEN_DKB_FRAME_TRACE`, `EDEN_NX2_RENDER_TRACE`, `EDEN_NX2_QUERY_TRACE`, `EDEN_NX2_QUERY_DMA_TRACE`,
`EDEN_NX2_CMDPAGE_DIAG`, `EDEN_NX2_PENDING_WRITE_TRACE`, `EDEN_NX2_DOWNLOAD_TRACE`,
`EDEN_NX2_TABLE_POINTER_TRACE`.

Then, **live, no relaunch**: raise the filter with the debug server's `log_filter`
(`*:Info Render.Vulkan:Debug`), and **drop `MME_LOG` for that window** — it logs two Debug lines per
macro call on a hot path and would flood the moment the filter lifts.

Traps to handle explicitly:
- **`PENDING_WRITE_TRACE` stops after 100 000 lines** — observed reaching its cap in the grass-era
  logs (last lines at 54 s and 67 s). `TABLE_POINTER_TRACE` carries the same cap in source but **did
  not reach it** in those runs (79 313 and 47 615 lines), so treat the two differently: the pending
  trace may go silent on its own, the table-pointer trace is unlikely to. Take what matters early.
- **`REJECT_HASH` is armed by the launcher on every run** — a deliberate, draw-skipping mutation.
  The launcher's header now emits it (and the read-ordering value and split mode), so the run's
  environment is recorded rather than assumed.
- **`DMA_WAIT_WRITERS` must be recorded, not pinned.** v1 pinned `=5`, which contradicts v1's own
  rule about behaviour-changing switches. The observation run records whatever value is used, and the
  A/B arms come later.
- **Capture hygiene, with the pairings stated correctly** (the earlier version paired them wrongly):
  the debug server's **`screenshot` shares a pending flag with `FRAME_CAPTURE`**, while **`capture_frame`
  shares the FrameDump schedule with `FRAME_DUMP`** ("another capture is in progress"). So: never arm
  `FRAME_CAPTURE` when taking a debug-server screenshot, and never arm `FRAME_DUMP` when calling
  `capture_frame`. `FRAME_DUMP` also defaults to firing 60 s after boot.
- `TRACE_VS`/`TRACE_PS`/`TRACE_DST`/`SEM_WATCH_EMITS` need values or a companion switch; as bare
  booleans they are inert, and a `strings` presence check cannot detect that. Either give them real
  values or leave them out and say so.
- **Exclusions (they change what is drawn):** `GPU_PROFILE`, `3D_METHODS`, **`3D_HISTORY`** (all three
  clear `fast_maxwell3d`), `LOOP_SKIP`, and the ordering family above for the observation run.

## Run sequence

0. **Baseline run (required by criterion 2).** `oot-state use known-grass/c8a6ca9dbc`, rebuild, launch
   with `--all-instruments` at the same save and spot, and record the DKB zero-count and skip counters
   per second. Without this there is nothing to compare the no-tufts state against. Then return the
   tree to the adopted state.
1. **Observation run** — observers armed (`--all-instruments`), filter lifted live, at the Hyrule Field save, no TAS input,
   camera untouched. Wait for a frame divisible by 600 (≈13 s at 45 fps); confirm at least one
   `Render trace` line appeared **before** reading anything into their absence. Lift
   `*:Info Render.Vulkan:Debug HW.GPU:Debug` — HW.GPU as well, otherwise the class-(c) witness
   ("Render trace suppressed") stays invisible and the F1 failure mode repeats for it. Collect: per-draw
   trace, DKB zero-count and skip counters, `capture_frame` pass dump, a screenshot, and the full env.
2. **Decide (a)/(b)/(c)** from step 1's counters — before any code is touched.
3. **Verification run** — clean launch, no instruments, for criterion 3.
4. **A/B arms** — only now, one ordering switch at a time.
5. Fix, or write the mechanism up with the log line or memory read that proves it.

## State and rollback

`~/.local/bin/oot-state` — `list`, `current`, `save <name>`, `use <tag>` (checks out and rebuilds).
Its revision guard is **fixed** (see v2 change 8) and verified to report a match. Tags in play:
`known-grass/c8a6ca9dbc`, `state/build88-merged`, `state/adopted-tonight`.

## Out of scope

The swing-time dropout (separate symptom, still open); the water shimmer; intro-movie sync; perf work
beyond "no worse than 40 fps" at the spot.

## Open questions carried forward

1. Which draw family the field grass actually uses (plain/instanced/indirect/task-mesh) — the source
   cannot say, and indirect draws would make the count test inapplicable.
2. Why the `c8a6ca9dbc` rebuild log shows a rejection and a skip that the same commit's earlier runs do
   not (E2's internal delta).
3. Whether the release-silent `Faulty draw!` drop has ever fired for this title.
4. Whether the record-time `GraphicsPipelineMissing()` drop has ever discarded a game draw — no counter,
   no log; a known blind spot.
