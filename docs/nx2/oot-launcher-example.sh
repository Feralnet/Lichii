#!/usr/bin/env bash
# ============================================================================
# Example launcher for The Legend of Zelda: Ocarina of Time (Switch 2)
# on the feral/oot-nx2-sync snapshot branch of Lichii.
#
# This is the "best configuration we have" as of 2026-11-06, distilled to the
# parts that matter. Edit the four paths below and run it.
# ============================================================================
set -uo pipefail

BIN="/path/to/Lichii/build/release/bin/lichii"
PREFIX="/path/to/your/prefix"          # config/ data/ cache/ live under here
ROM="/path/to/Ocarina of Time [0400486024DEC000][v131072].nup"

[ -x "$BIN" ] || { echo "binary not found: $BIN"; exit 1; }
[ -f "$ROM" ] || { echo "rom not found: $ROM"; exit 1; }

# --- the settings that matter ----------------------------------------------
# EDEN_NX2_REJECT_HASH : Link renders solid instead of semi-transparent (#101)
# The four fast-path switches: measured +8.9% together on our baseline.
export EDEN_NX2_REJECT_HASH="c72b6ea746c00433"
export EDEN_NX2_SEM_FAST=2
export EDEN_NX2_LIST_FAST=1
export EDEN_NX2_LOOP_SKIP=1
export EDEN_NX2_DMA_WAIT_WRITERS=5

# gpu_accuracy must be 0 (Low) in config/eden/qt-config.ini — that is what keeps
# the split GPU thread (the frame rate) enabled. 1 (High) is the obsolete #163
# flicker workaround and costs roughly 9 fps.
acc="$(grep -aE '^gpu_accuracy=' "$PREFIX/config/eden/qt-config.ini" 2>/dev/null | tail -1 | cut -d= -f2)"
[ "${acc:-0}" = "0" ] || echo "warning: gpu_accuracy=$acc — set it to 0 for the fast path"

echo "reminder: if vegetation looks missing, start a NEW FILE. Saves written by"
echo "older builds carry bad rendering state (see docs/nx2/oot-nx2-sync-snapshot.md)."

XDG_CONFIG_HOME="$PREFIX/config" \
XDG_DATA_HOME="$PREFIX/data" \
XDG_CACHE_HOME="$PREFIX/cache" \
  "$BIN" -g "$ROM"
