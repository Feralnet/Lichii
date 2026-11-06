# Addendum to the vegetation plan — Zephyr's source map and its corrections
Date: 2026-11-06 · Read this WITH `oot-vegetation-plan-2026-11-06.md`, not instead of it.
Source: crew member Zephyr, read-only source map (full text: `~/Pictures/oot-check/veg-2026-11-06/zephyr-draw-map.md`).

This addendum exists so the plan under Cade's audit is not edited mid-review. Where these two
disagree, **this file wins** — and the reasons are given as commands, not assertions.

## 1. HARD BLOCKER — the plan's instrument step could not have produced a single line

The plan says: arm `EDEN_NX2_RENDER_TRACE`, then read `count=` / `instances=` per draw. Zephyr's map
shows that would have printed **nothing**, for three independent reasons:

1. The per-draw trace lines are `LOG_DEBUG(Render_Vulkan, …)` — **Debug** level. Every log on this box
   runs the default `log_filter='*:Info'`. Lines filtered out are never logged at all.
2. They fire only when `render_trace_frame % 600 == 0`.
3. The two draw trace lines are capped per frame.

**Verified independently** (Echo, same session):

```
eden_log-adopted-f77b1c3209.txt   Debug lines: 0   Render-trace lines: 0
tracer-run-2-020128.log           log_filter=*:Info  Debug lines: 0  Render-trace lines: 1
```

The single "Render trace" line in the grass-era log is the startup banner
(`Report: Render trace enabled: interval=600 frames, log_filter=*:Info`), not a draw.

**Fix:** the port exposes `log_filter` as a **live** debug-server method — *"Replaces the live log
filter, e.g. '\*:Info HW.GPU:Debug Shader:Debug'. Returns the previous one. Lines filtered out are
never logged."* So: arm `EDEN_NX2_RENDER_TRACE` at launch, then lift `Render_Vulkan` to Debug **live**,
and wait for a frame divisible by 600 (≈10 s at 60 fps, ≈13 s at 45). No relaunch, and the filter can
be restored afterwards — but note the filter state is not persisted into the log retroactively, so
anything wanted must be captured while it is raised.

## 2. A cheaper H1 detector already exists and the plan misses it

`EDEN_DKB_FRAME_TRACE` feeds a once-per-second summary that already counts **zero-count draws**
(`trace_zero_direct`, incremented when `num_vertices == 0` or a non-mesh draw has `instances == 0`).
That is a direct H1 detector — "is the guest issuing zero-count draws, and how many per second" —
without needing the Debug-level per-draw lines at all. Verify the switch's exact name and the emitted
line from source before arming it; do not trust this sentence alone.

## 3. The quietest drop has a witness with no count

`draw_manager.cpp` prints `Render trace suppressed: docked=… indirect=… vs=… ps=… condition_address=…
mode=… override=…` when `ShouldExecute()` is false — i.e. when the **guest's own conditional-render
gate** says cull. It is capped at 256 unique tuples and carries **no count field**, so it can say
"this program was suppressed" but not "with what count". This matters: it is the only witness for the
H1 mechanism if the zero comes from an unmet condition rather than an empty vertex buffer.

## 4. Factual corrections to the plan

| Plan says | Actually |
|---|---|
| title id `0400486024DEC000` written as 12 hex chars in one place | It is **16** hex chars, `0400486024DEC000`. Never a 12-char form (`custom/0400486024DEC000.ini` in the live log; `patch_manager.cpp:94`) |
| "around 145 switches" | **148** distinct `EDEN_*` names (136 of them `EDEN_NX2_*`) |
| the two `Draw skipped (no pipeline)` pairs are candidates for the vegetation | **Corrected (Cade F9c):** in the grass era those skips are at **2560×1440**; only the live log shows 640×360. So the target size differs between eras, and "probably not the vegetation" does **not** hold — treat as open. (An earlier revision of this row also claimed the shader addresses differ between eras; that was unsupported — addresses shift per launch, and the two logs happen to carry identical values.) |
| the live run's `no pipeline` skip is unexplained | It is explained: `vs=0x1149092100 ps=0x114908b800` is the `EDEN_NX2_REJECT_HASH` (Link's overlay shader, per #101), logged as rejected |

## 5. Instrument set — revised, with the "changes what is drawn" column filled in

Arm for the capture run (observers only):
`EDEN_DKB_FRAME_TRACE`, `EDEN_NX2_RENDER_TRACE` (+ live filter lift), `EDEN_NX2_QUERY_TRACE`,
`EDEN_NX2_QUERY_DMA_TRACE`, `EDEN_NX2_CMDPAGE_DIAG`, `EDEN_NX2_PENDING_WRITE_TRACE`,
`EDEN_NX2_DOWNLOAD_TRACE`, `EDEN_NX2_TABLE_POINTER_TRACE`.

**Reconciled with v2 (re-audit item):** `MME_LOG` is **out** — it logs two Debug lines per macro call on
a hot path and floods the moment the filter is lifted. `EDEN_NX2_DEBUG_SERVER` must be **in**, or there is
no live filter lift at all.

Must stay OFF for this run — each **changes what is drawn**, so they cannot be used to observe:
- `EDEN_NX2_GPU_PROFILE`, `EDEN_NX2_3D_METHODS`, `EDEN_NX2_3D_HISTORY` — all clear `fast_maxwell3d`,
  i.e. they run a different method path than the played renderer.
- `EDEN_NX2_LOOP_SKIP` — changes which instanced draws flush.
- The ordering family (`DMA_WAIT_WRITERS`, `SEM_FAST`, `LIST_FAST`, `FETCH_DRAIN`, `SPLIT_SAFE_READS`)
  — they change *when* the front reads guest memory, which is precisely the class of mechanism H2
  posits. Use as A/B arms in a later step, never in the observation run.
- `EDEN_NX2_FRAME_CAPTURE` combined with the debug server's `screenshot` — shared pending flag
  (`RequestScreenshot`/`screenshot_requested`). Note the other pairing: `capture_frame` shares the
  FrameDump schedule with `FRAME_DUMP`, not with `FRAME_CAPTURE`.

## 6. What the map could NOT determine (carry these as open questions)

- Which draw family the field grass uses (plain / instanced / indirect / task-mesh). No Debug-level
  trace exists in any saved log to answer it; the discriminating run has to supply that.
- Whether the release-silent `Faulty draw!` drop (`macro.cpp:116`) ever fires for this title.
- Whether the record-time `GraphicsPipelineMissing()` drop has ever discarded a game draw: it has no
  counter and no log — so if a pipeline fails *after* a draw is accepted, the draw vanishes silently.
  This is a real gap in the observation plan and should be named as one.

## 7. Consequence for the run plan

Step 3's "collect the render trace for the vegetation programs" becomes: arm the observers → lift the
log filter live → **wait for a frame divisible by 600** → capture the per-draw lines plus the DKB
zero-count summary → then `capture_frame` for the pass dump (never both frame-capture paths at once).
Nothing else in the run plan changes. The H1/H2 decision criterion is unchanged: vegetation programs
present with `count=0` is H1; absent from the trace entirely is H2.
