# F04#6 Meadows named-fight aftermaths: one frame per win, for a distinctness judge

Captured Sun 11 Oct 2026, render.yml run 38165088838 (source `7ef5e574`: tb/ev-captures merged with tb/ev-coordinator `a8899257`); assembled about 4:19 PM CT. Low/Compatibility (llvmpipe), 1280x720, real time. This lane captures; it does not judge.

- **Tool:** `tools/capture_f04_6_aftermaths.gd`. It reuses `capture_named_fight.gd`'s production path: the challenge goes through the interact prompt and dialogue, the fight is ended by combat_manager's own `_begin_resolve("won")` (disclosed), and the aftermath is framed facing the trainer. Shutters are framed from a teleport stand spot.
- **Order in the world:** Dell, then Vance, then the three captains, then Hald, then the Warden. The trainer dialogue, struck standard, stand-down and sigil token are the production aftermath.
- **`sheet.jpg`:**
  - 01: Dell at the relay gate;
  - 02: Vance, standard cloth fading;
  - 03–05: Oreth, Halder and Vess, each with a standard strike and a floating sigil (river, field, ridge);
  - 06: Hald's blast shutter, gone after the win;
  - 07: the Warden in his arena after the win;
  - 08: the Warden's chamber shutter, gone (the stand spot is cramped against a wall).
- **Run notes:**
  - The tool's reload pass did not run, because the run hit its 150-minute cap during the Warrens guardian fight. The Warrens is outside the current F04#6 list.
  - Extra live frames for Vance's relay console press (12 s drain fade) and Old Mill Crossing (gear granted directly, then the gate's own `_on_tried()`, disclosed) are in the run artifact if wanted.
