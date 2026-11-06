# Ocarina of Time (Switch 2) — community snapshot branch

**Branch:** `feral/oot-nx2-sync` · **Title:** `0400486024DEC000` v131072 (v2.0.0)

This branch is a **community snapshot**, not an official release and not maintained.
It exists because people asked how we got *The Legend of Zelda: Ocarina of Time (Switch 2)*
running this well in the Lichii lineage.

**If you hit a problem, report it upstream — not to the author of this branch.**
Upstream: <https://github.com/zortos293/Lichii> (fork of the Eden/Eglantine lineage).

---

## What this branch carries

It is upstream `nx2` plus ~115 commits, including the merge of upstream
build-88 (`#194` Frizti performance port, `#240` Dynamic FPS by Dark) and a set of
adopted upstream PRs — `#243`, `#241`, `#245`, `#250`, `#251`, `#257` — plus our own
OoT-specific work and a large set of opt-in diagnostics.

Out of the box, on this branch:

- the 3D world renders (not black), with correct shadows;
- the texture flicker of `#163` no longer reproduces on the fast path
  (`gpu_accuracy = Low`); the old workaround is unnecessary and costs ~9 fps;
- Link renders **solid** rather than semi-transparent when `EDEN_NX2_REJECT_HASH`
  is set (below) — Lichii `#101`;
- outdoor lighting is no longer overblown, and the "darker square" artifact is gone;
- the CPU-side fast path (GPU split) is enabled and is where the frame rate comes from.

## Runtime settings that matter

| Setting | Value | Why |
|---|---|---|
| `gpu_accuracy` | `0` (Low) | Keeps the split GPU thread enabled. `High` was only ever a workaround for `#163` and costs ~9 fps. |
| `EDEN_NX2_REJECT_HASH` | `c72b6ea746c00433` | Link renders solid instead of semi-transparent (`#101`). |
| `EDEN_NX2_SEM_FAST` | `2` | Resolve waiting semaphore acquires without draining the split's back. |
| `EDEN_NX2_LIST_FAST` | `1` | Keep list processing on the front. |
| `EDEN_NX2_LOOP_SKIP` | `1` | Track the instance loop without the back-side round trip. |
| `EDEN_NX2_DMA_WAIT_WRITERS` | `5` | Macro DMA reads on the split front without draining the back. |

The four `EDEN_NX2_*` switches above were measured together at **+8.9 %**
(45.43 vs 41.71 fps, t = 8.76) on a standing held-draws baseline, with profilers
armed and the heavy tracers off. Measure them in your own scenes before trusting
the number — scene-to-scene totals are not comparable.

A pile of further `EDEN_NX2_*` diagnostics exists for debugging draws, queries,
DMA reads, table pointers and native pipelines; see `docs/nx2/`.

## Building (Linux)

```sh
git clone https://github.com/Feralnet/Lichii -b feral/oot-nx2-sync
cd Lichii
cmake -S . -B build/release -DCMAKE_BUILD_TYPE=Release -DYUZU_TESTS=OFF
cmake --build build/release --target lichii -j$(nproc)
# binary: build/release/bin/lichii
```

Use `ccache` if you rebuild often. Building the test suite
(`-DYUZU_TESTS=ON`, target `tests`) is optional; three known failures exist in the
`nx2_*` video tests (`UsageTracker` move-assignment) and are unrelated to the
renderer.

Run it with the emulator's own data directories, e.g.:

```sh
XDG_CONFIG_HOME=./prefix/config XDG_DATA_HOME=./prefix/data XDG_CACHE_HOME=./prefix/cache \
  build/release/bin/lichii -g "/path/to/Ocarina of Time [0400486024DEC000][v131072].nup"
```

## Known issues

1. **Saves written by older emulator builds carry bad rendering state.**
   If the vegetation is missing or a scene looks wrong after loading an existing
   save, **start a new file**. This state lives in the save data; no emulator-side
   change removes it from an affected save. (This cost one very long night to
   establish; see `docs/nx2/oot-vegetation-plan-2026-11-06.v2.md`.)
2. **Grass "vanishes when swinging" in Hyrule Field** on some older saves —
   present in upstream build-88 as well, so it is an upstream matter.
3. **Log noise that is harmless:** `Mesh output topology 0 (SET_MESH_SHADER_A
   0x00040200) is not implemented`, occasional `Draw skipped (no pipeline)` and
   `Unmapped Device ReadBlock` messages appear in the same counts on healthy runs.
4. Never force-kill the emulator. Killing it mid-run can leave a truncated
   pipeline cache; if that happens, wipe `cache/eden/shader/<title-id>/`.

## Reporting

Upstream only: <https://github.com/zortos293/Lichii/issues>.
This branch is a snapshot — issues filed against it are not monitored.

## Credits

All renderer work builds on the upstream lineage: Lichii, Eglantine, Eden, yuzu and
Sudachi, and on the upstream contributors whose PRs are adopted here. The OoT-specific
diagnostics and the fast-path switches were developed for this snapshot; use them,
fork them, improve them.
