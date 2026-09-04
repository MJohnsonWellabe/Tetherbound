
---

## 6. Round two — the open items, and who owns them

Written 2026-09-04 after a pass over all seven Gate 3 lane reports and Gate 2's
2.8 evidence. Round one's lanes finished their own scope and left named residue;
this is that residue, grouped so the six lanes do not collide.

The pattern in what was left is worth naming, because it will recur: **lanes
stopped honestly at their file-ownership boundary.** G3-FINALE flagged W-4 as
"not done" rather than faking a visual pass it had no pipeline for; G3-BAND5
wrote the row it would have written for P-5.2 and stopped; G3-BAND4 called its
own S08 a FAIL because the harness never gave the player a fair captain fight.
None of that is a lane underperforming. It is the ownership split working, and
the cost of the split is that someone has to pick the residue up. That is this
round.

| Lane | Scope | Source |
|---|---|---|
| `G3-OPENING-FIX` | the second orb throw that never leaves the hand (GAME-11/RIG-26); a revived creature not re-deployed (2.11); post-tournament recovery as a designed beat, and a refusal line that names the real reason (2.10) | chain S02, 2.8 §4/§7 |
| `G3-HARNESS` | the walker cannot leave the Pond basin (2.9); S08 has no post-faint switch or revive; stale trace-length thresholds (2.14) | 2.8 §7, G3-BAND4 |
| `G3-BAND1-FINISH` | the South Bridge is visually unbuilt; the oxblood reservation is broken; fence, mill sails, signposts, dome hill, water (2.13); one roster decision on the route (2.12) | 2.8 §7/§8 |
| `G3-HUD` | food bar outside the 5% safe area; objective/action/interact hierarchy; health-text contrast; the interact pill covering its own object | 2.8 §8 |
| `G3-CREATURE-COLOUR` | Bramblebun candy pink in daylight AND glowing at night; time-of-day scaling for `field_emission`; the rest of the roster unreviewed against the 1.5:1 bar | `CURRENT_STATE` §3 + 2.8's judge |
| `G3-WARDEN-ARENA` | W-4 arena dressing and the Warden's silhouette measured at 16 m; R-2 the waystop duty board | G3-FINALE, G3-BAND5 |

### Two findings that only exist because the instrument changed

Both come from 2.8 judging **sixteen stands taken from the played route's own
2 Hz trace** — gameplay camera, HUD on, where the player actually stood — rather
than posed survey viewpoints. Four previous blind judges could not have found
either:

- **The HUD had never been judged at all.** The earlier survey reports say
  "interface (n/a — no HUD present)". Four defects surfaced the first time a
  judge saw one.
- **The South Bridge had never been framed.** A posed stand named
  `place5-bridge-approach` reported "no clear bridge structure is visible despite
  the filename"; standing on the crossing confirms it is a bare plank frame with
  no gate, banner or guard — the chapter's first physical gate, and the thing
  Team Tether is supposed to be holding.

Worth carrying forward as a method note: **where the camera stands decides what
the judge can find.** Posed stands flatter a build.

### Still open, owned by the coordinator, not a lane

- **The single re-bake.** Every lane was forbidden `vegetation.json` and
  `terrain_playground.json` and told to propose diffs instead. Those proposals
  (Band 2's two Warrens clearings already waiting from `BAND2-63-WARRENS`, Band
  5's P-5.2 scorched-pocket sightline, Band 1's dome hill and tree layout) are
  collected and applied in one pass, then both bakes run once, after the merge —
  never before, which is what made PR #29 red.
- **The chapter chain.** S01 13/13, S02 77/5, S03 475/38 with an exit save —
  past the point where run 3 died. S04 onward is running.
- **`chapter_curve.json`'s stale "no trainers" comment** for band 2, reported by
  G3-BAND2 as outside its ownership.
- **The `material_get_instance_shader_parameters` null-material warning** during
  guardian dressing (`burrow_warrens.gd`), seen by two lanes, chased by neither,
  non-fatal in both.
