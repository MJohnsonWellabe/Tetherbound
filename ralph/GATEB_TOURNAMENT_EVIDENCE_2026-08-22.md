# Gate B — status record, 2026-08-22

Everything this session accomplished, everything it found, and everything Gate
B still needs. Written to be read cold by whoever picks this up next.

**Branch:** `ralph/TOURNAMENT-2` (also pushed as
`claude/tournament-gate-b-kn9wpv`), based on `ralph/TOURNAMENT-1` (c31e54e2).
**CI:** run 1977 on that branch. **On `main`: nothing.** See §6.

The tournament itself was **not** rebuilt. `TOURNAMENT-1` already carried the
eight-slot bracket, `data/config/tournament.json`,
`scripts/world/tournament.gd`, the marshal Halda, the three fought rounds, the
Team Tether grunt holding `south_bridge_key` and the saddle-recipe prize. This
branch verifies it, changes the board where the owner ruled against it, and
builds the entry gate that was missing.

---

## 1. What was accomplished

### 1.1 The bracket is fought end to end — `tests/smoke_tournament_bracket.gd`

`tests/test_tournament.gd` proves the tournament as DATA: eight slots, three
fought rounds, the marshal's ladder, the thresholds, the prize. Every one of
those assertions reads JSON or calls a static function, so before this **nobody
had ever fought the bracket**.

The new smoke drives the production route on real ground — the marshal's
`greeting_when` branch → her conversation → the `battle:` effect →
`encounter_director.begin_trainer_battle()` — with real input actions rather
than manager calls. A passing run:

```
branch: a party too small to enter      -> tournament_halda_closed
branch: a team that is not trained yet  -> tournament_halda_train
branch: a levelled team in poor condition -> tournament_halda_condition
condition: refused, and the report says -> Terrapup needs a night in a creature bed, is unhappy.
condition: fed the team and rested them -- 3 creature(s) ready
branch: a team that qualifies           -> tournament_halda_signup
signed up: the board went from 'the draw is open' to 'Quarter-final, you vs Mira'
branch: a round that was lost           -> tournament_quarter
loss: the quarter-final is still on offer, and 'tournament_quarter_won' is still unset
condition: fed the team and rested them -- 3 creature(s) ready
Quarter-final: 2 creatures felled, 20 coins paid
Semi-final:    2 creatures felled, 25 coins paid
Final:         3 creatures felled, 40 coins paid -> 'champion of the Lower Meadows'
prize: the saddle pattern is granted and the recipe reads as known
steady state: the champion's line pays nothing and starts nothing
```

The loss is deliberate — the owner's rule in
`ralph/OWNER_DIRECTIVES_2026-08-22.md` §2, "You can lose and retry after
healing your creatures", proven the only way it honestly can be: by losing a
round, checking the marshal still offers it and no flag was set, healing and
caring for the team, and winning it on the second attempt.

Run it: `godot --headless --path . --script tests/smoke_tournament_bracket.gd`

### 1.2 The board is a bracket that fills in only after events

Owner ruling, given on the first render: *"the tournament bracket should be a
bracket and it should only fill in after events not be filled in from the
start."*

**It is a bracket.** Four columns — 8 draw slots, 4 quarter-final winners, 2
semi-final winners, 1 champion — one `Label3D` per slot plus real connector
geometry, replacing a centred paragraph of "A vs B -- winner" lines. A
paragraph could never have held columns in line: the font is proportional and
this project ships no monospace face.

**It only fills in after events.** `tournament.gd::bracket_state()` refuses to
name anybody in a bout whose two feeding bouts are not both decided. The old
board printed `You vs Tam` in the semi-finals and `You vs Oskar` in the final
**from the moment the draw opened** — pairings that only exist if you already
know who wins the quarter-finals. Undecided slots draw an empty ruled line, so
a board with nothing decided still reads as a bracket with places waiting.

The tree needed no new data: `bracket`'s slot order already is the draw, slots
pair (1,2)(3,4)(5,6)(7,8), and winners pair in turn — exactly what
`tournament.json`'s own `_comment_pairings` describes.

Pinned by `test_a_later_round_names_nobody_until_its_feeders_are_decided`,
which walks the whole ladder and fails if any column resolves early.

**Carpentry.** Two blind passes called the board "a UI panel in world space".
The posts stood at ±0.9m on a panel spanning ±1.25m, in FRONT of the painted
face, hiding the entire draw column and the champion's slot. They now stand at
the panel's outer edge and BEHIND it, with two rails, five plank seams and
timber trim round all four edges. No new art.

### 1.3 The creature condition gate — RG19-spec/D68

Built after confirming no other branch was building it. The owner's original
rule was "well rested, well fed, and happy"; what shipped checked party size
and level only, and the condition half existed nowhere in the tree.

`scripts/creatures/creature_condition.gd` over
`data/config/creature_condition.json` — pure static functions, no Node, every
threshold in data and interpreted in exactly one file. Three states, three
verbs the opening already teaches:

* **rested** — the creature bed's existing flag, plus an expiry (45 minutes
  awake, tunable) and a faint that clears it;
* **fed** — a `nourishment` meter draining on real time, which does **not**
  drain in a bed, so a night's rest is not a night's hunger;
* **happy** — a `happiness` mood, deliberately SEPARATE from `bond`. Merging
  them would either make bond losable (progression a player can be punished
  out of) or make happiness permanent (a gate that unlocks once and never
  matters again).

D29's light-hunger rule extends to creatures and is pinned by a test: an empty
meter makes a creature ineligible — never damaged, never fainted, never dead.
**There is no starvation death and adding one is an owner decision.**

Ticked for every party member in `Game._process`, benched ones included.
Victories, level-ups, faints and completed nights all move it. Save VERSION 13
carries it; `_migrate_v12` gives older creatures the configured STARTING values
— one caught before the model existed was never starving, it was never
measured.

**Fed by playing:** berries carry a `creature_food` block and reach the team
through the backpack's existing target picker, the same flow tonics use.
Gathering and the berry farm now feed the team.

**Gated in one place:** `condition_ready()` / `readiness_report()`, read by the
marshal, the team screen and the entry check alike. Halda gains one branch on
`tournament_condition_ready` — the only VOLATILE flag in the store, written
AND cleared as the team's state changes — and a line naming rest, food and
time together instead of refusing flatly. The team screen shows
"Rested · Fed · Happy" per creature, red while it would refuse entry, because
26-RG19 forbids the rule living only in dialogue.

One safety rule is asserted, not assumed: **condition gates entry, not the
bracket.** A team that goes hungry between bouts is still offered the round it
is halfway through.

### 1.4 Save/load across the bracket — five tests, 26-RG19's own requirement

Its acceptance list says "save/load does not duplicate rewards or regress to
pre-tournament objective", and nothing in the repo tested it. Now in
`tests/test_save_format.gd`: a half-fought bracket survives; the board reads
the same bracket after reload; a won tournament cannot be reloaded into a
second payout of coins or the saddle pattern; condition survives, so a fed
team does not come back hungry and get refused; and a genuine VERSION 12 save,
rewritten on disk with the condition keys stripped, loads as a creature that
was never measured.

### 1.5 Verification status

**Unit suite, locally: 1234 tests, 728,061 assertions, 0 failed.**
CI run 1977 is the authoritative check; see §6.

---

## 2. Defects found and fixed in this session's own harness

Both root-caused rather than retried, and both would have landed as CI flakes.

**Attacking at an invented range.** The fight loop closed to a hard-coded 2.0m
before it would attack — tighter than `combat.json`'s own
`player_quick.range` (2.6). A first fix read the config value and still
deadlocked at 2.9m, because
`combat_manager.gd::_with_reach_for_the_bodies()` RAISES a move's effective
range to `(mine + theirs) * body_clearance + 0.5` for large bodies: the
final's Meadowhart spaces itself further out AND reaches further, so the flat
config number is a floor, not the answer. The harness now holds no opinion —
close to lunge distance, swing when an attack is off cooldown, let the fight
judge it. **Measured: 2 stalls in 4 runs before, 3/3 clean after.**

The same private-constant bug is **latent in
`tests/smoke_village_trainer.gd`**, whose loop this one was modelled on. Its
one-creature fight does not currently trip it. Worth fixing before it costs a
CI run.

**Faking a bed on a deployed creature.** To simulate a night's sleep the
harness set `resting` on every party member and called
`Game.complete_creature_bed_rests()`. `creature_instance.gd` says plainly that
the bed system owns that flag; setting it on the creature DEPLOYED in the
world left the director holding a body it had been told was asleep elsewhere,
and the next fight jammed with the piloted creature permanently mid-commit. It
now calls `creature_condition.note_rest_completed()` and leaves the flag alone.

**A mistake of mine, corrected:** the first commit swept in every `.uid`
sidecar Godot generated on import. A `.uid` is minted at import, not derived
from the file, so seven of them collided with `integration-3`'s different ids
(`capture_map_handheld.gd` is `uid://ct32xww6lbfrk` there and was
`uid://c7iy3wg866yir` here). Removed and excluded locally.

---

## 3. The blocking defect — handed to Gate A

**The chapter's first catch fails deterministically.** Three clean-save runs of
`tests/smoke_gate_a_opening_segment.gd` on the merged tree all ended:

```
eight natural weakened-target launches produced 1 strike, 7 misses, and no catch
```

A fourth run captured the game's own commit lines and rules out aiming as the
whole story:

```
catch launch: commit eligible=true  reticle=0.160/0.600 first_hit=Wild_bramblebun_2 los=true
catch launch: commit eligible=true  reticle=0.256/0.600 first_hit=Wild_bramblebun_2 los=true
catch launch: commit eligible=true  reticle=0.410/0.600 first_hit=Wild_bramblebun_2 los=true
catch launch: commit eligible=false reticle=0.884/0.600 ... reason=reticle_outside_body
```

Three launches the GAME judged eligible, well inside the body, line of sight
true, against a Bramblebun weakened to 31/124 HP — and no catch.
`combat_manager.gd:178` calls `_rng.randomize()`, so no fixed seed is repeating
one unlucky sequence. On `catching.json`'s headline numbers a centred throw at
a quarter health should sit near half; three good throws failing in every run
is not that. **Either the effective chance is far below what the config reads
like, or the weakened-HP factor is not reaching the roll.**

Secondary: after the first throws the harness's aim drifts (0.884, 1.389) and
stops re-converging on a creature that has moved, so a player gets fewer good
throws than the eight the test spends.

**Owner: Gate A's catching beat.** Left alone here by the owner's own
instruction. **Consequence for Gate B: it cannot pass until this is fixed**,
because the fresh-save evidence path dies at the first catch and every Gate B
beat is downstream of it.

Everything before the catch works, and the timings are useful evidence:
title +0.0s, wake +35s, Grandpa +43s, starter named +47s, out of the house
+52s, wild combat +71s, target weakened +78s.

---

## 4. Findings handed to other lanes

From two blind Fable visual passes (`.claude/skills/visual-judge/SKILL.md`),
each told nothing about what changed. **Both answered NO to both bar
questions.** The board's own defects were fixed here (§1.2); these were not,
and are not this branch's to fix:

1. a large **casterless shadow** across the foreground of the walk-up frame —
   no caster, cloudless sky; reads as a lighting bug;
2. a **cloudless gradient sky** in both frames;
3. a **bald midground** — no trees, bushes, fences or structures between the
   player and the mountain; grass tufts at uniform scale and even spacing;
4. **two humanoids in frame that read as the same person** — real evidence
   that spec §21's "differentiate villagers per material, by hair colour" does
   not survive gameplay distance;
5. **no creature anywhere in a creature game's tournament venue**, and no
   event dressing — no ring, banners or seating. The second critic put the
   information design of the bracket at "understandable in about two seconds"
   and still said the venue reads as any random hill.

Also: **the opening harness assumes an empty save directory.**
`title_screen.gd::_on_new_pressed()` shows a "Start a fresh game?"
confirmation whenever a save exists, and the harness has no answer for it —
it waits out its frame budget and reports a misleading "never reached the
Meadows world". CI never meets it; a returning player meets it every time. The
fresh-save path is therefore only ever exercised in the one case a returning
player never hits.

---

## 5. Integration state

The Gate B objective chain needs **`integration-3` and `TOURNAMENT-1`
together**, and neither branch alone can produce it: integration-3 carries
`data/progression/objectives.json`'s 12-entry chain and the four wired ladder
flags, and three of those entries name `tournament_team_ready`,
`tournament_entered` and `tournament_won`, which exist only on TOURNAMENT-1.

They merge with exactly one conflict — `ralph/BLOCKED.md`'s map-fog entry,
"OPEN" on one side against "RESOLVED by owner ruling" on the other; resolve in
favour of the owner ruling. A merged worktree was used for the evidence run.

**`opening:beat:road` has no writer.** It is named by `objectives.json` and set
by no `.gd` file in the merged tree — the first objective a new player is ever
shown may never tick over. Every other flag in the chain has a real writer.

---

## 6. What is left before Gate B can be called done

| # | Item | Owner |
|---|---|---|
| 1 | **The first catch fails deterministically** (§3) | Gate A |
| 2 | **Nothing is on `main`** — TOURNAMENT-1, integration-3 and TOURNAMENT-2 are three unmerged branches | coordinator |
| 3 | **CI run 1977 must come back green** on `ralph/TOURNAMENT-2` | this branch |
| 4 | **`opening:beat:road` has no writer** (§5) | Gate B follow-up |
| 5 | **"Enough nearby creatures to prepare naturally" is unproven** — the bracket smoke BUILDS a qualifying team; nobody has shown a player can reach the entry threshold through ordinary play in the opening area. A named Gate B pass criterion that needs a play-through, not a test | Gate B / Gate C ecology |
| 6 | **Both blind visual passes said no to both bar questions** (§4) | world/art lanes |

### Nothing lands by itself

`ralph/conventions.md`: both `ralph-merge.yml` and `ralph-sweep.yml` are
`on: workflow_dispatch` only. *"A green `ralph/**` branch therefore sits there
until somebody dispatches a consolidation run. Nothing lands by itself...
Check `git log origin/main`, not the CI badge."*

`ralph-sweep.yml` sweeps **every** green `ralph/**` branch, which currently
includes other lanes' work, so dispatching it is a coordinator-level decision
rather than this branch's.

### Closed since this session began

* the tournament is fought end to end, and the bracket board obeys the owner's
  ruling;
* the condition gate exists and is earned in the real player path;
* save/load across the bracket is covered;
* **the South Bridge grunt is not a tournament event** — measured at 1299m
  from the tournament board against the final opponent's 3m. The tournament's
  handoff is the objective pointing south; the grunt is who the player meets
  on arrival. Confirmed with the owner.

---

## 7. Commands

```bash
# the bracket, fought end to end
godot --headless --path . --script tests/smoke_tournament_bracket.gd

# the fresh-save path (needs an EMPTY user:// -- see §4)
rm -rf ~/.local/share/godot/app_userdata/Tetherbound
godot --headless --path . --script tests/smoke_gate_a_opening_segment.gd -- --gate-a-continuous-core

# unit suite
godot --headless --path . --script tests/run_tests.gd

# the board's visual evidence (xvfb, never plain --headless)
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_capture_tournament_board.gd
```
