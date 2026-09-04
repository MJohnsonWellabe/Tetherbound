# G3-ENCOUNTERS-0903 — report

**Lane:** Gate 3 encounter design (Fable). **Branch:** `ralph/G3-ENCOUNTERS-0903`.
**Deliverable:** `docs/specs/GATE3_ENCOUNTER_CONTRACTS.md`. Read-only on code, data,
assets, shaders and tests; this branch touches only the contract document and this
report. No pull request (coordinator lands it).

## What the contract document decides

| § | Decides |
|---|---|
| 1 | The general standard every Gate 3 major encounter is held to, derived from the Warren Guardian: the three-sentence blind test (G-1), presentation and context minimums (G-5, G-6), the in-world readiness signal (G-7). |
| 1.2 / G-2 | The one mechanism request: a per-body `combat` override merged over `combat.json`'s `enemy` block in `wild_creature.set_engaged()`, readable from a spawn's `alpha`/`elder` block, the guardian block and a trainer team member. Five reusable behaviour profiles (WALL, CHARGER, DIVER, CURRENT, ACE). |
| 1.4 | Guardian: keep everything shipped; give the fight the heavy directional swing its own file describes (G-9). |
| 2 | Band 2 rhythm and the 200 m / 60 s pull-free ceiling. |
| 3 | Captain Vance: Dell moves to the gate so the yard is the captain's; the Tuskroot becomes the ace and charges; local healing on `relay_disabled`. |
| 4 | Routing verdict: Riverwatch stays on the far bank at z=4350 as the Band 3/4 seam and is designed as the first captain fought (composition → power → endurance in road order). Oreth's ace 16 → 15 so the ladder climbs. Each captain's test, site and profile. |
| 5 | The Warden opens no softer than the elite (18/18/19/19/20), his five are sent in a doctrinal order with one profile each, and only his creatures carry TM-tier quicks. Hald gets the third type his comment already claims. Arena stays empty inside the ring and is re-measured for legibility. |
| 6 | Per-band rhythm for bands 2–5 with beat sequences and the longest allowed pull-free interval; Band 5 is a crescendo, not a count (D70 respected). |
| 7 | The roster-pressure moment: the waystop, a Team Tether duty board naming the garrison's numbers, a once-only alpha on the doorstep visible from the fire, history on every Team-screen row, and a measured evidence question. The legendary's own decision kept as D38 ships it. |

## The finding worth reading first

Every opponent in the game, wild or trainer-owned, fights with the single global
`enemy` block (`wild_creature.gd::set_engaged()`); the AI has one attack intent and
the damage path reads the opponent's **quick** move only. The guardian's
`signature_move: earth_fist` therefore reaches the player only after a catch. Every
"memorable, not fight + HP" claim in the chapter's data rests on presentation and
context today, never on behaviour. G-2 is the smallest change that makes behaviour
authorable; §9 item 5 says what happens to the document if it is ruled out.

## Every place the document contradicts something shipped

Full table in the document's §8. In brief:

- G-2: one global enemy profile → per-body override (code: one merge in one function).
- G-9: guardian `combat` = WALL with Earth Fist's 72° cone.
- V-1: Officer Dell from 4 m off the relay centre to the gate opening (≈343.2, 3771.1); the decorative sentry steps inside.
- V-2: Vance's team reordered galecrest 11 / duskhush 11 / tuskroot 12 (was tuskroot 11 / galecrest 11 / duskhush 12); Tuskroot CHARGER.
- V-5: the relay's own three drain stations heal on `relay_disabled` (reads D41; owner to confirm).
- C-1: Oreth 13/14/16 → 13/14/15.
- C-2: Oreth's stale `facing_deg` re-derived; a three-prop post at his stand.
- C-3..C-5: captains' creatures get profiles (Mosshell WALL, Brooktail CURRENT; Tuskroot CHARGER, Meadowhart CURRENT; Galecrest DIVER).
- C-7: captains' defeated-line pointers flipped to road order Oreth → Halder → Vess.
- W-1: Warden 16/17/17/18/20 → 18/18/19/19/20.
- W-2: Warden send-out order fixed: burrowback WALL → galecrest DIVER → brooktail CURRENT → meadowhart CHARGER → tuskroot ACE.
- W-3: TM-tier quick moves (`rock_throw`, `aqua_shot`, `wind_blade`) on the Warden's five only.
- W-4: arena end wall and door dressed, ring kept empty, Warden silhouette re-measured at 1.5:1.
- W-7: Hald duskhush 19 → mosshell 19 (Air/Ground/Water).
- P-5.2: the scorched pocket (Sunstone, special Mudsnout, `tm_heavenfall`) made visible from the spine.
- R-2: a Team Tether duty board at the waystop (readout mechanism; small placer change).
- R-3: the (−20,7505) burrowback cluster's first member becomes a once-only alpha (+2 levels, scale 1.3, WALL).
- R-4: Team screen rows show the bond task line, `battles_fought`, `caught_on_day` and the Best mark.

Pinned-fixture note for whoever edits V-2, C-1, W-1, W-7:
`tests/fixtures/band_split_baseline/trainers.json` mirrors pre-split entries and
must move in the same commit (`tests/test_band_content.gd`'s stated policy).

## Questions escalated to the owner rather than answered

1. V-5 — local drained-ground healing at the relay on `relay_disabled` (this document's reading of D41).
2. W-1 — raise the Warden's front to 18 (recommended) versus lowering Hald.
3. R-8 — where a refused Veridian goes after `legendary_freed` without `legendary_joined` (recommended: seen again at the Highfield herd, unengageable).
4. R-3 — confirm a wild alpha at 16–19 on the last 60 m before the Hall is intended pressure (optional, catchable, never in the way).
5. G-2 — whether the per-body combat override is in Gate 3's scope; if not, every behaviour contract degrades to default behaviour and G-1's sentence (b) fails for every encounter but the guardian's catch.

## What I did not do

- No code, data, asset, shader or test was edited; every "do" is addressed to the lane that owns the file, with the file named.
- No blind visual judging: this is a reading-and-writing lane and every measured number quoted is from a file's own recorded measurement.
- Did not reopen the guardian's colourway, level or den, the captains' body palettes, the Warden's dialogue, the Hall's fight count or Band 5's length — all correct as shipped and said so.
