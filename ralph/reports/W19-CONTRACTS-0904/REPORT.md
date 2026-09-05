# W19-CONTRACTS-0904 — report

**Lane:** W19-CONTRACTS · **Branch:** `ralph/W19-CONTRACTS-0904` (from `origin/main` at
`ef16544f`) · **Kind:** documents only; no code, no data, no Godot.
**Content commits:** `1cd73455` (C1), `135c3da1` (C2), `1dcd7dab` (C3), `dedf603f` (C4),
`faa215c5` (D74, D75), `7e543849` (the two plan edits). **Final commit:** the one that adds
this report, on top of `7e543849` — `git log -1 origin/ralph/W19-CONTRACTS-0904`.

## Files changed

| File | Kind | Lines |
|---|---|---|
| `docs/specs/C1_RIDEABLE_ROSTER_FLY_TELEPORT.md` | new | 520 |
| `docs/specs/C2_TASK_FEED.md` | new | 632 |
| `docs/specs/C3_VILLAGE_REPLAN.md` | new | 449 |
| `docs/specs/C4_CAMPING_NECESSARY.md` | new | 431 |
| `docs/decisions/D74-burrowback-keeps-its-rock-armour.md` | new | 105 |
| `docs/decisions/D75-the-level-gate-placement-rule.md` | new | 172 |
| `docs/FINISH_THE_MEADOWS.md` | edited | Phase 2a gains a table pointing at the four contracts and the two decisions; item 1.8 points at D74; the 2b "level gate" row at D75 and the "camping" row at C4; the top table's "content" row says the contracts are written |
| `docs/00_START_HERE.md` | edited | one row in the authoritative table for `docs/specs/C*.md` |
| `ralph/reports/W19-CONTRACTS-0904/REPORT.md` | new | this file |

Nothing outside the brief's ownership list was touched. No `docs/owner/*` edit. No code,
no data, no test file.

## What was written, in player-visible terms

**C1 — the rideable roster, fly and teleport.** Terrapup, Burrowback and Tuskroot ride
behind the one generic saddle (Rootstone tier, so "midway" is the Old Quarry, the start
of the middle band). Galewisp will fly and Ripplet will teleport, *only beyond the
Meadows*, carried as a presentation-only block that nothing outside the UI may read. The
choice is legible on three surfaces: a caption under each orb in the starter picker, one
line of Grandpa's before the pick, and a "will learn" tag on the Team screen for the whole
chapter. Each starter gets one in-chapter thing: Terrapup rides in its own slot without
catching a mount; Galewisp scouts the map from the four authored overlooks (the shipped
`reveal_circle`, no movement); Ripplet gets a +0.15 catch affinity on Water wilds in the
band with the most species. A nine-site gate sweep (South Bridge, Sigil gate, all seven
spokes, on every mount, with sprint and jump) proves nothing rides over a locked gate, and
the fix for a crossing is always the mount, never the gate. Mudsnout and Ashtusk are not
rideable — evolving into Tuskroot *gains* the mount. Two small decisions recorded in the
file rather than asked: which starter gets which (Galewisp flies, on the body's own wings;
Ripplet teleports), and the timing lever if "midway" needs tuning (an optional
`requires_bond_tier`, never moving the saddle).

**C2 — the task feed.** A task is an `objectives.json`-shaped entry plus a pin, a counter
and a reward, still a pure function of the flag store (no quest engine; no save-format
change; no new binding; the MAIN STORY card untouched). "Pops up" is a flag or a 300 m
radius, shown as one banner on prompt 73's progression feed and a pin derived from flags
(so a pin can never outlive the flag that should clear it). Built around the two owner
instances: **the relay shutdown chain** — four stations, one per band 2–5, each a console
behind a grunt who already stands there (Dorn, the Band 3 ladder, the ridge patrol,
Watchman Corr), each shutdown healing that station's own drain group through CL-E12's
filter, voiced by the Quarry Foreman, Sela, Ren and Grandpa — and **every trainer in the
Meadows** (a generated 31-flag tally with recovery-supply milestones and the two elixirs
at 31, voiced by Halda). Plus four "like that": alphas (CL-W1's pin, clears on caught or
beaten, tallied), the three Sigils pinned for the main line, Rootstone and Ironwood
surveys over D72's permanent nodes, and a camping chain over the six authored rest points.
The six shipped Local Requests migrate into the same list.

**C3 — the village replan.** The village becomes a street on the chapter's own road (the
L from Grandpa's door to TrailGate), houses on both sides, the well at the bend. A berry
field beside the farm, a grove between the road and the practice meadow, a stone yard
behind the smithy — each built from the harvest nodes already inside the fence and named
on the map. Five villagers stay by function (Mira, Oskar, Tam, Halda, Bram; the Foreman's
hammer moves onto Tam's tools line); fourteen are resited with a place, a reason and a
role each, eight of them into Bands 1–4 as density. The opening's traps are named
(`smoke_opening`'s substrings, the TrailGate corner rule, the gather route's stock), the
one terrain bake is isolated to a single stage, and a four-stage plan keeps the opening
green between every stage.

**C4 — camping made necessary.** Every satiety number is frozen by test (the contract's
own *fails if*). Necessity comes from **strain**: a fifth of damage taken and a quarter of
a faint become a ceiling potions cannot reach, capped at 40%, cleared only by a bed, a
night or home; **scarcity**: no full heal on the road except rest, capped route stalls
(C3's Wilhelm and Corin); **distance**: a per-leg strain floor (≥ 24% at each rest point)
the density pass must hit, written as an expected-fail that goes green leg by leg;
**night**: top-of-band wilds, wider aggro, heavier strain, the village exempt. Strain is
drawn as a hatched ceiling on every HP bar and named in the Team screen's condition
column. One save field (`strain`, VERSION 17) — the only format change across all four
contracts. The dependency on CL-O2 ("no night time") is named.

**D74** — Burrowback keeps its grey-olive rock-armour. Legibility is met in the dark
direction (field over creature ≥ 1.30:1, measured with the G3-CREATURE-COLOUR tooling) by
value, rim and contact shadow, never by hue; the 1.5:1 bright bar stays for every other
species; the blind judge's question becomes "can I trace the outline".

**D75** — a `min_level` sits only on a band's gatekeeper (the South Bridge grunt, Captain
Vance, the three Sigil captains, the Hall patrol), equal to the next band's measured
`team.enter` minus one (8 / 11 / 14 / 16), checked on the party's highest level, refused
in character with a line that names the remedy and no number; crossings never check a
level. The South Bridge's 8 is one under the tournament exit level (9), so a champion
crosses and a beeliner is turned back. Density lands first, per the plan's own dependency.

## Tests and runs

None — this lane is documents only and the brief says no Godot is needed. No test was
run, no smoke was run, no render was made. The only automated check performed was a
script over the eight changed documents that resolved every cited repository path
(`docs/`, `data/`, `scripts/`, `autoload/`, `tests/`, `tools/`, `assets/`) against the
working tree; every path that is not explicitly proposed as new exists. Command:

```
python3 - <<'EOF'   # cited-path check, run at 7e543849
import re,os
files=[...the eight files...]
new={...the sixteen paths the contracts propose as new...}
for f in files:
    for m in re.findall(r'`((?:docs|data|scripts|autoload|tests|tools|assets)/[A-Za-z0-9_./\-*{},]+)`', open(f).read()):
        ...
EOF
# result: 0 missing paths
```

## Runtime validation

None (documents only). The numbers the contracts cite were read from the tree at
`ef16544f`, not from a run: trainer entries and gatekeeper teams (five band
`trainers.json`), the 16 alpha/elder spawns, the six rest points, the harvest node counts
per band, `chapter_curve.json`'s measured entry levels, `vitals.json` and
`creature_condition.json`'s satiety numbers, the drain station groups, the village
structures, villagers and harvest nodes, the map landmarks, the type chart, the item
table, the save version. Where a contract proposes a coordinate, it says "intent, not
surveyed ground" and names the probe that turns it into a position.

## Decisions made in-lane rather than asked (small, recorded in the files)

- Galewisp flies, Ripplet teleports (C1 §1).
- The five villagers who stay (C3 V-6) and the fourteen placements (C3 V-7).
- The Foreman's camp hammer moves to Tam's tools line (C3 V-6).
- Sela's homecoming is the Pond ranger station, not the square (C3 V-7).
- Four relay stations reuse four existing grunts so the 26-name trainer census holds
  (C2 T-7).
- Strain's starting numbers and cap (C4 §8), all marked tunable with the direction to move.
- D74 and D75, as recorded.

## Known limitations and what was deliberately not done

- **No contract was validated by running anything.** Every test named is a test to write;
  every number is a starting point. The brief's "tests to pin" are named per section and
  per slice, with the red-first rule stated, but none exists yet.
- **C3's coordinates are layout intent.** Stage 0 of its plan is the survey that replaces
  them; the contract says so at the top and at every table.
- **C4 depends on CL-O2** (the shipped build never reaches night) for its night lever to
  be felt; the contract names it and does not own it.
- **C2 depends on prompt 73's progression feed** for its banner and on CL-E12's healing
  filter for the relay chain; both are named as prerequisites with a stub allowed for the
  first.
- **The C4 per-leg strain floor is written as an expected-fail** until the density pass
  lands, by design.
- **`MEADOWS_PROGRESSION_SPEC.md` §3 was not edited** (D75 names the one line to add
  there; the spec is not in this lane's ownership list). Nor was `docs/VISUAL_BIBLE.md`
  (D74 names its one sentence). Nor `docs/CURRENT_STATE.md` (no status changed — nothing
  here is implemented by being written down). The coordinator routes those three
  one-line edits.
- **No Biome 2 content of any kind** was designed, named or implied beyond the words
  "beyond the Meadows".
- **No hard rule was touched:** five creatures, no storage, the human never fights, no
  new meshes, no Meshy, no harsher hunger, no starvation, creatures loom, no Biome 2.

## Final state

Branch `ralph/W19-CONTRACTS-0904`, pushed; content through `7e543849`; this report is the
commit on top of it.
