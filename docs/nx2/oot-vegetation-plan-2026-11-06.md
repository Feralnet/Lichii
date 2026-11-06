# OoT (Switch 2) — vegetation missing: plan for the next investigation pass
Date: 2026-11-06 · Branch: `feral/oot-nx2-sync` · Binary under test: `f77b1c3209` (adopted tree)
Author: Echo · Status: **awaiting Cade's audit before any of it runs**

## Objective (one sentence)

Find why Hyrule Field's tall grass tufts are not drawn in this port, and produce either a fix or a
precise, evidence-backed statement of the mechanism.

## Acceptance criteria (falsifiable)

1. At the Hyrule Field save on the fog-gui prefix, a frame from the emulator's own screenshot shows
   the tall tufts present beside the dirt path (E3–H5 region: crop `1280x864+1280+576` at 2560×1440),
   judged against the reference frame `~/Pictures/oot-check/ab/post/A-nx2-only-plus-landing.png` era
   and the grass-era frame `/tmp/b4/h01.png`.
2. The same run logs the vegetation draw path's counts, so the claim does not rest on eyes alone.
3. No regression: FPS measured from log timestamps ≥ 40 in the same spot with `EDEN_NX2_DMA_WAIT_WRITERS=5`
   and no profiler armed.
4. If NOT fixed: a written mechanism naming the code path that drops the geometry, with the log line
   or memory read that proves it. "Unknown" is an acceptable outcome; "probably" is not.

## Verified evidence (each with its provenance)

| # | Fact | Provenance |
|---|---|---|
| E1 | Tall tufts render at 02:26 on binary `c8a6ca9dbc` | `/tmp/b4/h01.png` + `tracer-run-015905.log` / `tracer-run-2-020128.log` both name `oot-nx2-sync-c8a6ca9dbc` |
| E2 | The same commit, rebuilt today, shows no tufts | `oot-state use known-grass/c8a6ca9dbc` → rebuild → screenshot `m5-1.png` |
| E3 | Config and disk state did not change across the 02:26→02:44 boundary | settings diff vs the 02:01 log shows only a clock line I added later; `find` over the prefix for 02:15–03:00 returns nothing |
| E4 | Every cache has now been cleared, including the two never cleared before (prefix `cache/nvidia/GLCache` 304 MB, `vulkan_static_pipelines.bin`) | wipe + relaunch, no change |
| E5 | In `f77b1c3209` the ONLY shader rejection is our own `EDEN_NX2_REJECT_HASH` (`c72b6ea746c00433`, bound to stage 5). Zero gather/TLD4/scratch-register rejections | live log, `grep -c` for each family = 0 |
| E6 | Mesh-topology errors (8) and unmapped device reads (16) are present in BOTH the grass-era logs and now | counts compared: 5/16 vs 8/16 vs grass era 4–5/16 |
| E7 | Issue #101 documents this exact symptom ("most ferns, flowers and grass are gone") and a lead: **~30 mesh draws with `count=0`** | `gh issue view 101` |
| E8 | An untested patch exists for the TLD4/SURED rejections (`Kradnah/Lichii fix/oot-texture-gather-forms`, `b47f0c3358`) — cherry-pick conflicts in `lower_to_maxwell.h` | fetch + cherry-pick attempt, aborted cleanly |

## Ruled out (do not re-litigate)

The GPU split; the macro DMA read drain/flush (`DMA_WAIT_WRITERS=1/5` both tried); both Eden caches
and the driver cache; save reload; brand-new file; console system-settings blob; console clock;
forcing occlusion queries to "visible" (confounded — see below); the reject hash as the vegetation
cause (E5 shows it is Link's overlay shader, per #101); the Ampere lowering scratch-register rejection
(E5: absent in this build); build-88's merge and the adopted PRs as a class (E2: the pre-adoption
commit also fails).

**Confounded test, must not be cited:** `EDEN_NX2_FORCE_ZPASS` rewrote the report as a Payload write,
which also changes which streamer writes and how the async-write bookkeeping registers. Its negative
result is not evidence about occlusion values.

## Leading hypothesis (must be confirmed or killed, not assumed)

**H1: the guest issues the vegetation draws with a zero count** — i.e. the game decides nothing is
visible (culling) and the emulator faithfully draws nothing. This is #101's own lead (E7) and matches
the "no draw-skipped, no rejection" profile.

Evidence for: E5 (no emulator-side dropping), E7 (trace shows count=0 mesh draws).
Evidence against: none yet; the occlusion-forcing test that would have tested it is confounded.

**Serious alternative — H2: the draws are never submitted at all**, because the guest's own LOD /
visibility state is wrong for a reason outside the query path (e.g. a state register the port
synthesises differently, or the guest's culling fed by a stale read we have not looked at).

**Discriminating commands (run these, do not reason past them):**
- `EDEN_NX2_RENDER_TRACE=1` → the `Render trace direct:` lines carry `count=` and `instances=` per
  draw. If the vegetation programs appear with `count=0`, H1 holds. If they never appear, H2 holds.
- `EDEN_NX2_QUERY_TRACE=1` + `EDEN_NX2_QUERY_DMA_TRACE=1` → whether reports for the vegetation pages
  are being requested/answered at all, and with what values.
- `EDEN_NX2_CMDPAGE_DIAG=1` → records DMA reads with changed words and GPU-written flags, which is the
  one place a stale read would show up as a *value* rather than a theory.

## Instrument plan — arm ALL of them (this is the standing instruction I keep violating)

Add an `--all-instruments` mode to `~/.local/bin/oot-debug-run` so it is one flag and not a memory
exercise, then run ONE launch with everything that is compiled in:

Arm: `EDEN_NX2_RENDER_TRACE`, `TRACE_VS`, `TRACE_PS`, `TRACE_DST`, `QUERY_TRACE`, `QUERY_DMA_TRACE`,
`CMDPAGE_DIAG`, `PENDING_WRITE_TRACE`, `DOWNLOAD_TRACE`, `TABLE_POINTER_TRACE`, `MME_LOG`,
`RT_TRACE`, `UPSCALER_TRACE`, `SEM_WATCH_EMITS`, `FRAME_DUMP` (one frame), debug server on.

Deliberately excluded, with the reason written into the launcher's help:
- `EDEN_NX2_GPU_PROFILE` and `EDEN_NX2_3D_METHODS` — both clear `fast_maxwell3d`, so they measure a
  different renderer than the one being played (`maxwell_3d.cpp:61`).
- `EDEN_NX2_FRAME_CAPTURE` together with the debug server's `screenshot` — they share a pending flag
  that can wedge frame capture for the rest of the session.
- `EDEN_NX2_NO_MESH` / `NO_DRAIN` / `DMA_NO_DRAIN` — these change behaviour rather than observe it;
  they are for A/B arms, not for the capture run.

## Run plan (one variable per step, no step skipped)

1. Add `--all-instruments`; verify it prints the armed list and that the binary actually contains each
   switch name (`strings`).
2. Launch on fog-gui with `DMA_WAIT_WRITERS=5`, load the Hyrule Field save, stand at the spot.
3. Collect: the render trace for the vegetation programs, the query traces, a `capture_frame` pass dump,
   and a screenshot. Archive all under `~/Pictures/oot-check/veg-2026-11-06/`.
4. Decide H1 vs H2 from the traces **before** touching any code.
5. Only then: pick the fix (or write the mechanism up) and verify against the acceptance criteria.

## State management / rollback

`~/.local/bin/oot-state` — `list`, `current`, `save <name>`, `use <tag>` (checks out and rebuilds).
Tags in play: `known-grass/c8a6ca9dbc`, `state/build88-merged`, `state/adopted-tonight`.
`oot-state current` reports when the built binary does not match HEAD — check it before every run,
because this branch has already produced a stale-binary confusion more than once.

## Out of scope for this pass

The swing-time dropout (the original intermittent bug — separate symptom, still open); the water
shimmer; the intro-movie sync (#251, adopted); perf tuning beyond "no worse than 40 fps at the spot".

## Questions for the auditor

1. Is the H1/H2 split the right cut, or is there a third possibility the evidence already excludes or
   includes that this plan misses?
2. Is the instrument set sufficient to discriminate H1 from H2 — and is anything armed that could
   *change* the thing being measured?
3. Is the acceptance criterion in step 1 falsifiable as written, or does it need a measured threshold
   (e.g. a region-difference number against a reference frame)?
4. Anything in "ruled out" that is actually not ruled out by the cited evidence?
