# N07-VFX-POLISH — telegraph ring colour and catch seal retune — lane report

Branch: `ralph/N07-VFX-POLISH-0905`, from `origin/main` at `f8a47ee4`.
**Last code commit: `7a96a764`** (round 2 closed: the magenta ring, the seal back at 0.45 s,
the round-2 verdict, D87 and the status row). Everything after it is this report. **This report's own commit is necessarily
one past whatever hash is written here**; the true head is
`git log --oneline -1 origin/ralph/N07-VFX-POLISH-0905`, and the closing commit's hash is the
last line of this file.

Source finding: `ralph/reports/W09-VFX-0904/REPORT.md` and its `JUDGE_round1.md` — the two
items W09's blind judge named and that lane correctly routed because they were pre-existing
config outside its ownership.

## What the player sees

- **The wind-up ring is magenta, and it is under the foe.** When a wild creature winds up a
  blow, the pulsing ring at its feet is now `#ff40e6` — a hue the meadow, the creatures and
  the reward layer do not contain — instead of the red that sat inside the band this project
  reserves for Team Tether. And it is a mark on the ground again: it is depth-tested, so its
  far half passes behind the creature it belongs to and it no longer draws through the
  player's own creature standing in front of it. Before this change, from the combat camera's
  usual place behind the ally, the ring was painted straight across the ally's back in dull
  red — which is exactly what W09's judge described as "a dull oxblood torus across the
  creature's chest" on the friendly creature.
- **A catch seals with a gold bloom around the orb, not a sheet over the screen.** The warm
  flash at the instant of the seal was a 2.76 m disc in front of a camera 2.4 m from the orb;
  it covered the resolve close-up edge to edge and, pale over grass, read as khaki. It is now
  a 1.0 m gold bloom around the 0.42 m orb, gone a fifth of a second sooner so W09's gold
  sparkle owns the rest of the second and the orb is not veiled by the flash.

Both are config: `combat.json` `telegraph.colour`, `catching.json` `vfx.caught`. The
depth test and the 0.08 m lift live in `telegraph_glow.gd`. Decision record: **D87**.

## Files changed

| File | Change |
|---|---|
| `data/config/combat.json` | `telegraph.colour` `#ff5a3c` → `#ff40e6`, with a `_why_colour_0905` note carrying both rounds. Nothing else in the file. |
| `data/config/catching.json` | `vfx.caught` `#ffe9a8` / radius 1.2 / 0.55 s / strength 1.15 → `#ffc94a` / 0.5 / 0.45 s / 1.0, with a `_why_0905` note inside the block recording the 0.75 s trial and why it was reverted. `strike` and `breakout` untouched. |
| `scripts/combat/telegraph_glow.gd` | `no_depth_test` true → false, with the render evidence written where the old reasoning was; `GROUND_LIFT` 0.08 m applied in `begin()`; the script's own default colour follows the config; `begin()` tolerates an out-of-tree host (the same guard `vfx_burst.gd::spawn` has) so a unit fixture can spawn the real ring. |
| `tests/test_telegraph_glow.gd` | new — reads the real `combat.json` through `combat_math.gd::config()` and asserts the telegraph hue is ≥ 25° from every reserved oxblood (`#6b2a20`, `#7a2430`, palette `tether_oxblood`); spawns the real ring through `begin()` and asserts it is parented, lifted 0.01–0.2 m, depth-tested, MIX-blended, draws one tick in and frees itself when the beat ends. Not in the brief's file list; it is the guard that keeps D87 from drifting back, and the coordinator can drop it if `tests/` ownership is a problem. |
| `tools/_capture_vfx_polish_0905.gd` | new — a **subclass** of W09's `tools/_capture_vfx_moments.gd` (every helper inherited), adding the wind-up shot from two views, a control frame, and the seal at its own peak; `--out=` so rounds sit side by side. |
| `tools/_measure_vfx_polish_0905.py` | new — whole-frame HSV band counts on the clean frames; bands and pass rules in its docstring, the round-1 set fixed before the first render, the magenta band added before the round-2 render. |
| `docs/decisions/D87-the-wind-up-ring-is-magenta-and-the-seal-flash-is-sized-to-the-orb.md` | new — both rounds' colour reasoning, why not a move-type colour, the seal sizing and duration, what was routed. |
| `docs/CURRENT_STATE.md` | the CL-A2 row rewritten to carry this follow-up. |
| `ralph/reports/N07-VFX-POLISH-0905/` | this report, `JUDGE_PROMPT.md`, `JUDGE_round1.md`, `JUDGE_round2.md`, `_sheet_before.png`, `_sheet_after1.png`, `_sheet_after2.png` (one sheet per round). |

Not touched, on purpose: `combat_manager.gd` (its `#ff5a3c` fallback in `_on_enemy_telegraph()`
is dead while the config names a colour; not this lane's file), `impact_flash.gd` (shared by
every attack), `orb.gd`, `vfx.json`, and the `target_marker` comment in `combat.json` that still
says "the telegraph's warning red" (outside the `telegraph` block; one word for whoever next
owns that file).

## The two root causes, as found

**Telegraph.** `#ff5a3c` is hue 9°, saturation 0.76. The game's two painted oxbloods are
`#6b2a20` (hue 8°, sat 0.70) and `#7a2430` (hue 352°, sat 0.70): the old ring was 1.2° of hue
from one of them. But the colour was only half of "on a friendly creature". The before-render
(`_sheet_before.png`, `05`/`06`) shows why the judge saw it on the *ally*: the ring spawns at
the foe's feet, the foe stands beyond the ally from the combat camera, and `telegraph_glow.gd`
drew with `no_depth_test = true` — a setting its own comment records was tried while chasing
"no ring ever draws" and "left true anyway". With the ring drawing, that setting paints it
through whatever stands in front, which from the default camera is the player's creature.
A ground mark is the case `alpha_aura.gd` and W09's round-3 level-up rings keep the depth test
for; the 0.08 m lift keeps the terrain from winning it along the whole ring.

**Seal.** `catching.json` sizes `vfx.caught` "against the resolve close-up", and the numbers
say the opposite: `resolve_camera` parks 2.4 m from the orb at a 50° vertical field of view,
2.24 m of frame height at the orb's depth. An `impact_flash.gd` ring at radius 1.2 × strength
1.15 expands to 1.38 m — a 2.76 m disc, 123 % of the frame height — with nine streaks reaching
1.86 m. At saturation 0.34 mixed over green it lands as khaki. Radius 0.5 × 1.0 is a 1.0 m
bloom (45 % of frame height) around a 0.42 m orb (19 %), in the same gold family as the
sparkle already layered on top.

## Two rounds, and why there were two

**Round 1** moved the ring to `#ffbe47`, the HUD's own `WARNING` amber (the colour of the
"!  incoming — move" line for the same beat), and cut the seal to 0.45 s. The blind judge, not
told which sheet was newer, endorsed the depth test unprompted ("depth-test it and put it on
the grass … a ground decal that the creature's body occludes") and confirmed the ring now sits
under the right creature — but found the amber three degrees of hue from the board's gold
swatch, the orb's band, the catch sparkle and the level-up rings, at a value inside the
sunlit-grass band: "the game uses that exact gold for 'you got the thing'"; the ring read as
"a dropped coin", a buff. On the seal it found the 0.45 s ring buried under the sparkle's
dark-haloed birth motes at three ticks and faded to nothing by sixteen, leaving A/04's orb
"the best orb in either sheet" but "unsupported". `JUDGE_round1.md` has the verdict verbatim
and the lane's response.

**Round 2** answered both: the ring became magenta (`#ff40e6`, hue 308°, the complement of
the grass, 44° from the nearest painted oxblood, 31° from the palette's near-black
`tether_oxblood`, 46° from the psychic lilac — and the genre's colour for an attack you cannot
block and must move off, which with no shields in this game is every wind-up), and the seal
was tried at 0.75 s so the ring would still frame the orb at the sixteen-tick shot. The
round-2 judge kept the ring ("the better read, decisively" for placement; not the reserved
family) and rejected the longer seal — it ranked the orb's legibility above the ring's
persistence and read the lingering ring as veiling the orb — so **the seal ships at round 1's
0.45 s** and the ring ships magenta. Both judges' one remaining colour wish is inadmissible:
round 1 wanted the ring nearer the red family, round 2 wanted the board's oxblood hue itself,
and the brief, `palette.json` and the regression test all exclude that band. Recorded as the
ceiling in D87 §1 and `JUDGE_round2.md`. `combat.json`'s `_why_colour_0905`,
`catching.json`'s `_why_0905` and D87 carry both rounds.

## Tests and smokes

| Command | Result |
|---|---|
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_combat_vfx.gd` (baseline, before any change) | **8 tests, 55 assertions, 0 failed**, rc=0 |
| same, after round 1 | **8 tests, 55 assertions, 0 failed**, rc=0 |
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_telegraph_glow.gd` (round 1) | **2 tests, 20 assertions, 0 failed**, rc=0 |
| same, with `telegraph.colour` set back to `#ff5a3c` and `no_depth_test` set back to `true` | **2 failed**, rc=1: `telegraph.colour ff5a3c is 1.2 degrees of hue from reserved oxblood #6b2a20 (needs 25)`, `… 17.6 degrees … #7a2430 …`, and `expected false, got true (the ring must be depth-tested …)`. Both restored; seen red for the right reasons. |
| same, on round 2's `#ff40e6` | **2 tests, 20 assertions, 0 failed**, rc=0 |
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_telegraph_glow.gd,test_combat_vfx.gd` on the final tree (`7a96a764`) | **10 tests, 75 assertions, 0 failed**, rc=0 |
| `godot --headless --path . --script tests/smoke_combat.gd` (round 1 and again on round 2) | `combat: OK — a fight can be entered, piloted, won and left.`, rc=0 both times |
| `godot --headless --path . --script tests/smoke_catching.gd` (round 1 and round 2) | `catching: OK — a throw can be aimed, missed, and landed.`, rc=0 both times |
| `godot --headless --path . --script tests/smoke_trainer_battle.gd` (round 1 and round 2) | `trainer battle: OK …`, rc=0 both times |
| `godot --headless --path . --script tests/smoke_boss.gd` (round 1) | rc=0 |
| same, round 2, run **concurrently with the round-2 software render** | **rc=1**: `FAIL: exploration never came back after the boss fight` — the fight itself ran and was won (`5 creatures, 961 frames, 6 quick attacks landed, 0 missed`), the tether released, the legendary joined, the full-belt ceremony took the decision, and only the final exploration-return check failed. |
| same, re-run alone, no code changed, render finished | rc=0, `boss smoke test passed` (`5 creatures, 981 frames, 7 quick attacks landed, 0 missed`) |

**On the one red.** It is the symptom `ralph/briefs/0904/LANES.md` records for
`smoke_gate_e_finale` — "exploration never came back after 'warden_aldis''s fight", split
verdicts across paired runs of one commit, traced to a race on whether a dialogue or decision
panel is up when the smoke checks locomotion. Nothing this lane changed executes after a boss
is beaten: the telegraph ring dies with the wind-up, the seal flash only plays on a catch, and
neither touches the finale, the panel or locomotion. The run that failed shared four cores
with a 1280×720 llvmpipe render; the round-1 run of the same smoke, on the same code path,
passed. Recorded as a finding, not chased, per `CLAUDE.md`'s rule that a retry is a finding.

`ERROR:` set across every run above and all three renders, read line by line: only
`ERROR: Parameter "material" is null` (the known-benign alpha-resize line, 1–4 per run, count
unstable as `docs/AGENT_WORKFLOW.md` §6 says) and, under xvfb only, the ALSA `ERR_CANT_OPEN`
with the dummy-audio fallback. The unit runner adds its usual two exit-time leak lines, identical
in the baseline and after runs. No `SCRIPT ERROR`. The distinct set did not grow.

Godot 4.7-stable, installed per `ralph/briefs/0904/COMMON.md`; `--import` once before any run.

## Frames and measurement

Three rounds captured by `tools/_capture_vfx_polish_0905.gd` under
`xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720`,
day/clear pinned and frozen, the tree paused for every shutter, `--only=telegraph,catch`:
before (879 frames, 18 min), round 1 (1,577 frames, 29 min — the catch took three throws),
round 2 (874 frames, 19 min); 10 shots written and 0 failed in each. The tool prints what is
alive at each shutter: `TelegraphGlow` at `05`/`06` in every round (18 ticks after engage;
`05` at 0.067 s into the beat, `06` at 0.333 s, the start of the ring's second pulse);
`HitSpark` at the `07` control in every round (the foe's blow landing on the ally);
`CatchBurst` at `04a`/`04` in every round.

One capture defect found and fixed between the before round and round 1, recorded in the tool:
the rig applies `yaw` in `_process`, which a paused tree never runs, so W09's `_aim_at_fight`
before the shutter never reached the frame — before-round `05` and `06` are the same picture
(the round-1 judge measured it: 198 differing pixels). Round 1 onward pre-aims through the
wait. It does not change what any round shows about the ring; `06` is the framing W09's
judge saw the ring "across the creature's chest" in.

**Rules fixed before the render they judge** (`tools/_measure_vfx_polish_0905.py` docstring):

| Rule | Before | Round 1 | Round 2 | Verdict |
|---|---|---|---|---|
| Telegraph: reserved-band pixels (H 345–25°, S ≥ 0.45, V 0.2–0.9) in `05` minus the `07` control — must fall to ≤ 10 % of before; the new family's delta over control must be positive | **+11,208** | **+717**, amber +663 | **+559**, magenta **+380** | **PASS** both rounds |
| Seal, `04a` (3 ticks in): pale wash (S ≤ 0.30, V ≥ 0.72) share of the whole frame must halve; gold (W09's rule) must stay > 0 | 18.7 % | 10.4 %, gold 33,665 | 12.4 %, gold 52,289 | **FAIL** as written — see below |
| Seal, `04` (16 ticks in): same | 14.0 % | 12.1 %, gold 32,703 | 13.7 %, gold 28,914 | **FAIL** as written — see below |

Whole-frame magenta in the three `07` controls is 19–21 px: the meadow has no magenta, so
every magenta pixel in `05`/`06` is the ring (399 and 972 px).

The two seal rules fail as written and the reason is the rule, not the seal: the whole-frame
wash count has a floor the flash cannot move — the ally's white shell plates filling the left
third of the close-up, the white orb itself, and the pale wild creatures at the top edge — and
that floor is most of the after number. Measured a second way, decided after the render and
labelled as such: the same band on the right 66 % of the frame (`x ≥ 440`, right of the ally):

| Region `x ≥ 440` | Before | Round 1 | Round 2 |
|---|---|---|---|
| `04a-catch-seal` | 14.0 % | 0.9 % | 4.3 % |
| `04-catch-success` | 7.1 % | 4.2 % | 6.8 % |

Round 2 is deliberately above round 1 at `04`: that is the 0.75 s ring still present at
sixteen ticks around the orb, which is the point of the change. The `04a` difference between
rounds is the sparkle's random birth spread on a different throw, not the seal.

## Blind judge

`JUDGE_PROMPT.md` is the prompt verbatim (round 2 added one sentence telling the judge which
small creature is the foe, after round 1 zoomed on a bystander). Each round the code-blind
judge (opus, Agent tool) was given two sheets labelled **A** (that round's after) and **B**
(before) — deliberately not in date order — plus the frames, `docs/reference/` and the
visual-judge skill, and nothing about what changed or which was newer.

- **`JUDGE_round1.md`** — before vs round 1. Wind-up: A under the right creature, but A's
  amber is the reward gold and "a dropped coin"; asks for the depth test A already has. Seal:
  A's `04` orb is "the best orb in either sheet" but unsupported; B's is a half-frame wash.
- **`JUDGE_round2.md`** — before vs round 2, verbatim, with the lane's response. Wind-up:
  round 2's ring is "the better read, decisively" — "the only frame in either sheet where the
  mark is on the ground, occluded correctly at both ends, and centred on the creature that is
  actually winding up"; "not the reserved family"; the one change it still wants is the board's
  oxblood hue raised in value, which the brief excludes (the ceiling). Seal: it ranked the
  clean orb of the before round's sixteen-tick frame above the 0.75 s ring's veiled one, so the
  0.45 s cut ships; both judges want `impact_flash.gd`'s primitive itself replaced.

**Acceptance, honestly.** *Telegraph:* met — the ring is out of the reserved band (measured
+11,208 → +559 reserved-band px over control, 25°+ of hue guarded by a test), it is the only
magenta in the frame, and two blind judges independently place it under the right creature
once depth-tested. *Seal:* half met — it no longer washes the close-up (14.0 % → 0.9 % pale
wash right of the ally at its peak), it is gold rather than khaki and sized to the orb, and the
orb reads at sixteen ticks; but neither judge calls the composite "clear", because the
primitive (`impact_flash.gd`'s camera-facing undepth-tested ring and hard spikes), the
sparkle's birth motes (`vfx.json`) and the orb's own hard-edged ground quad (`orb.gd`) are
what they see, and none is reachable from `vfx.caught`. That is the ceiling for "retuning
existing config values, not authoring a new effect".

## Known limitations and what was deliberately not done

- **The spikes are still spikes.** `impact_flash.gd` draws nine hard-edged radial triangles in
  its core colour and exposes no softness key; the brief's "spike softness" is not reachable
  from `catching.json`, and that script is shared by every attack in the game. At the new
  radius they reach 0.68 m instead of 1.86 m. Routed.
- **The seal's first three ticks are W09's mote cloud.** `vfx.json` `catch_burst` throws 26
  dark-haloed motes from the orb; at three ticks they are still packed on it and the round-1
  judge read them as "dust or mud kicked up" burying the orb. Not this lane's file. Routed.
- **The hard-edged lit quad at the orb's base** in every round's seal frames (a straight-edged
  trapezoid on the ground around the orb) is `orb.gd`'s own readable halo rendering with no
  falloff under software GL, not the flash; unchanged before and after. The round-1 judge
  called it "the clearest rendering bug in the catch sequence". Routed.
- **The resolve camera still parks inside the ally** (W09's judge: "indistinguishable from a
  bug"): `catching.json` `resolve_camera` / the rig, not `vfx.caught`. Routed, unchanged.
- **Not a move-type colour.** The wild creature's pending move type never reaches
  `telegraph_glow.gd` (the manager hands it only the beat length); wiring it is a
  `combat_manager.gd` change. D87 §1 records the reasoning.
- **`06` is the honest picture from behind the ally**: with the ring depth-tested, the half of
  it behind the foe's body is hidden, as it should be; when the foe is entirely hidden behind
  the ally there is no ring to see from that angle, and the "!  incoming" line carries the
  beat. In real play the camera orbits.
- The side view (`05`) shows only a sliver of the ring in rounds 1 and 2 because the foe
  circled to the ally's far shoulder before its first swing; the ring is measured present and
  is plainly visible in `06`. A capture that steers the foe is out of scope.
- The `07` control carries a `HitSpark` in every round, so the amber/magenta deltas over it are
  understated; the reserved-band delta is not affected (the spark is ground-tinted, not red).
- Frames are software GL: composition, presence, colour relationships and scale are what they
  prove; fine lighting is not.
- `combat.json`'s `target_marker` comment still calls the telegraph "warning red" — one word,
  outside the block this lane owns.
- The import left five untracked `.uid` files for Cloudreach scripts that ship without one on
  `main` (`autoload/realm_heart_state.gd.uid` and four under `scripts/world/`, `tests/`); not
  this lane's, not committed.
- Rebased on nothing: `origin/main` moved to `4acd59ff` (PR #52) during this lane; none of
  the files this lane changed moved on `main`, and the `CURRENT_STATE.md` row it rewrote is
  untouched there. Still based on `f8a47ee4` per the brief; no rebase, no force-push.

## Commits

| Hash | What |
|---|---|
| `c2350015` | capture and measurement tools |
| `d6cfc9c1` | round 1: amber colour, depth test and lift, seal retune, D87, the regression test, judge prompt |
| `1da2a97c` | round 2: magenta colour, 0.75 s seal trial, D87 rewritten, magenta band, round-1 verdict and sheets |
| `7a96a764` | round 2 closed: seal back to 0.45 s with the reason, `JUDGE_round2.md`, `_sheet_after2.png`, D87 ceiling, the `CURRENT_STATE.md` row |
| closing commit | this report only — its hash is one past `7a96a764`; see the last line |

Closing commit (this report): the head of `origin/ralph/N07-VFX-POLISH-0905`, one past `7a96a764`.
