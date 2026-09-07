# OP-BUILD — Valheim-style repeat placement, modular snapping, and dismantle

## Goal
Building now places successfully, so do **not** reopen the old RG4 confirm-does-nothing bug without current reproduction. The remaining problem is that the construction experience is clumsy and the modular pieces do not behave like one coherent building kit.

Implement three linked improvements:
1. persistent repeat placement after a successful build;
2. reliable shared modular snapping/dimensions;
3. player-built structure dismantling.

## Owner intent — locked
- Build flow should feel like Valheim: select Floor once, then keep placing floors until cancel or change piece.
- Same principle applies across player-placeable buildables unless a specific piece has a proven gameplay reason to exit placement.
- A basic house must be constructible without fighting half-cell offsets.
- Player-built pieces must be removable.
- Default dismantle refund is full material cost so experimentation is not punished.

## Repeat placement
Current/older RG4 assumptions that successful placement clears/disarms the selected piece are superseded.

After placing a legal ghost:
- consume cost exactly once (unless Free Build);
- spawn/save the piece exactly once;
- immediately keep the same buildable active;
- create/reuse the next placement ghost;
- allow another placement without reopening Build menu;
- continue until cancel/back or deliberate piece change.

Selection press must still never auto-place the first piece.

## Modular snap contract
Investigate current dimensions and snap anchors before patching symptoms.

Fresh owner failures:
- roof cannot reliably build/snap on top of a wall;
- floors visually occupy less than the expected full modular cell;
- walls align about half a cell off rather than sitting on floor edges.

Create one authoritative module dimension/anchor convention for structural pieces. Floors, walls, doors and roofs must agree on cell size, edge anchors, height anchors and rotations.

Do not solve this by adding one hard-coded offset per asset.

### Required regression build
From normal player build mode construct:
- 2x2 connected floor footprint;
- four perimeter walls aligned to floor edges;
- one doorway/door in a wall position;
- roof pieces attached cleanly above walls with no floating/half-cell drift.

If this simple house cannot be created reliably through controller input, snapping is not done.

## Dismantle / remove
Add a controller-first removal action available in build mode.

Requirements:
- target/highlight the exact player-built piece before removal;
- remove only objects recorded as player-built/placeable structures;
- never delete authored village/world geometry;
- refund full recipe/material cost by default;
- handle full inventory through existing world-drop/refusal conventions rather than deleting resources;
- remove piece from save-state registry exactly once;
- placed stateful pieces (storage, beds, etc.) require safe state handling; do not silently destroy stored contents.

If a storage container is non-empty, use a clear refusal or safe contents-drop behavior consistent with current item systems. Do not invent data loss.

## Controller/UI
Show compact dynamic glyph hints for Place, Rotate, Snap/step, Dismantle and Cancel while placement mode owns input. Reuse `input_glyph.gd` and coordinate with RG3/RG14.

## Preserve
- current cost/free-build semantics;
- placement validity/collision rules;
- save/load of placed buildings;
- controller-first Ally behavior;
- no duplicate building system.

## Testing
Add tests for repeated same-piece placement without reopening menu, fresh-button arming protection, 2x2 floor/wall/roof snapping, dismantle registry cleanup, material refund, stateful-piece safety and save/load after build/remove cycles.

## Definition of done
The player can select a structure once, build naturally in a continuous session, snap a basic house together cleanly, correct mistakes by dismantling them, and never fight half-cell geometry or repeated menu reopening.