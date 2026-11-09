STATUS: no change (both banners are on Team Tether sites)
BRANCH: tb/item-victory-card (note only)

F38#17 red banner behind Warder Solene, and F38#28 red banner on the Warden
arena wall. Rule: recolour only if the site is not Team Tether.
- Warder Solene (bands/band5_stronghold_approach/trainers.json,
  id stronghold_courtyard): rank "officer", base "grunt", placed_by "stronghold".
  She is a Team Tether officer in the Tether stronghold courtyard.
- Warden Aldis (same file, id warden_aldis): rank "warden", placed_by
  "stronghold_climax". Its `_comment_rank` reads "the rig every other Team Tether
  rank in the chapter has been a variant of". The arena is the Tether
  stronghold's climax room.
- building_prefabs.json authors the stronghold banners as the occupation
  ("gatehouse banners -- occupation"; "the keep's own banner, the highest oxblood
  in the complex").
Both reds are the faction's reserved colour on the faction's own ground, so they
are correct, not leaks. If judges keep flagging them, the readable fix is a Tether
sigil on the cloth so it reads as the faction's mark, not a recolour. That would
be a separate art arm.
