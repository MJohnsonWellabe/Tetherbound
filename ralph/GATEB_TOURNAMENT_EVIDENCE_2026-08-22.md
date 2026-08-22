# Gate B — village tournament evidence, 2026-08-22

Evidence record for the three pieces of work left over after `TOURNAMENT-1`
built the tournament itself: an end-to-end smoke test that actually fights the
bracket, a blind visual pass on the board, and the fresh-save evidence run.

The tournament was **not** rebuilt. `ralph/TOURNAMENT-1` (c31e54e2) already
carried the eight-slot bracket, `data/config/tournament.json`,
`scripts/world/tournament.gd`, the marshal Halda, the three fought rounds, the
Team Tether grunt holding `south_bridge_key` and the saddle-recipe prize. This
branch verifies it, and changes the board where the owner ruled against it.

---

## 1. The bracket is fought end to end

`tests/smoke_tournament_bracket.gd`. `tests/test_tournament.gd` proves the
tournament as data — eight slots, three fought rounds, the marshal's ladder,
the thresholds, the prize on the final's own reward. Every one of those
assertions reads JSON or calls a static function, so until now **nobody had
ever fought the bracket**.

The new smoke test drives the production route on real ground — the marshal's
`greeting_when` branch, her conversation, the `battle:` effect,
`encounter_director.begin_trainer_battle()` — with real input actions rather
than manager calls. A passing run:

```
branch: a party too small to enter -> tournament_halda_closed
branch: a team that is not trained yet -> tournament_halda_train
branch: a team that qualifies -> tournament_halda_signup
signed up: the board went from 'the draw is open' to 'Quarter-final, you vs Mira'
branch: a round that was lost -> tournament_quarter
loss: the quarter-final is still on offer, and 'tournament_quarter_won' is still unset
Quarter-final: 2 creatures felled, 20 coins paid
Semi-final:    2 creatures felled, 25 coins paid
Final:         3 creatures felled, 40 coins paid -> 'champion of the Lower Meadows'
prize: the saddle pattern is granted and the recipe reads as known
steady state: the champion's line pays nothing and starts nothing
```

The deliberate loss is the owner's own rule from
`ralph/OWNER_DIRECTIVES_2026-08-22.md` §2 — "You can lose and retry after
healing your creatures" — proven the only way it honestly can be: by losing a
round, checking the marshal still offers it and no flag was set, healing, and
winning it on the second attempt.

### The flake this found, and its root cause

The first two runs of the file disagreed: one won the final in 2261 frames,
the next never resolved it inside 9000. That is a coin flip on a test that
was about to go into CI.

Diagnostics were added first, so the failure would say something:

```
Final stalled: 901 frames without the opponent losing HP -- 184.8 HP left,
2.6m away, quick_ready=true charged_ready=true, 0 of 3 felled
```

Both attacks available, neither ever thrown. `data/config/combat.json` sets
`player_quick.range` to **2.6** and `player_charged.range` to **3.0**, and the
enemy AI holds a `preferred_range` of 2.1. The drive loop closed to a
hard-coded **2.0m** before it would attack — tighter than the game's own
reach — so against a creature that keeps its spacing the harness parked at
2.6m and swung at nothing until the ceiling ran out. The quarter and semi
finals passed only because their creatures happened to close the gap
themselves.

The loop now reads both ranges from `combat.json`. **The same private-constant
bug is latent in `tests/smoke_village_trainer.gd`**, whose fight loop this one
was modelled on; its one-creature fight does not currently trip it, but it is
the same defect and worth fixing before it costs a CI run.

---

## 2. Blind visual pass on the board

Run per `.claude/skills/visual-judge/SKILL.md`: a Fable critic, told nothing
about what changed or what anyone hoped it would say, handed
`shots/tournament/tournament-board.png` and `tournament-ground.png` against
the key art and the five Palworld references. Every claim below was then
confirmed independently against the frames and the code rather than taken on
trust.

**Both bar questions came back no.** A: not the key art's world — "the key
art's Meadows is lush; this is a lawn." B: not the same kind of game as the
Palworld shots — no creatures on screen, no dressed world, an empty field and
a text panel.

### On the board itself — in this branch's scope

1. **It read as a UI panel, not carpentry**: an untextured quad on two smooth
   cylinders, no planks, no frame, no joinery, and the posts drawing in front
   of the panel face.
2. **The lettering is an engine sans-serif label**, uniform weight, no paint
   character.
3. **The bracket text was programmer formatting** — confirmed in code:
   `_bout_line()` was literally `"%s vs %s  --  %s"` with `"...."` as the
   undecided placeholder, and the player's slot printing as the string `You`
   on a physical village sign.
4. **No event dressing** — no banners, ring or posts; the venue reads as a
   field with a sign in it.

### Beyond this branch — recorded, not fixed here

5. A large **casterless shadow** across the foreground of
   `tournament-ground.png`, with no visible caster and no clouds to justify
   it. Reads as a lighting bug.
6. A **cloudless gradient sky** in both frames.
7. A **bald midground**: no trees, bushes, fences or structures between the
   player and the mountain; grass tufts at uniform scale and even spacing.
8. **Two humanoids in frame that read as the same person.** This is evidence
   that spec §21's "differentiate villagers per material, by hair colour"
   does not survive gameplay distance — a real finding about the strategy,
   not about this board.
9. **No creature anywhere in a creature game's tournament venue.**

---

## 3. The board is now a bracket that fills in

Owner ruling, given on this render:

> "the tournament bracket should be a bracket and it should only fill in after
> events not be filled in from the start"

Two changes, and the second is a rule rather than a layout.

**It is a bracket.** Four columns — 8 draw slots, 4 quarter-final winners, 2
semi-final winners, 1 champion — drawn as one `Label3D` per slot plus real
connector geometry, instead of a centred paragraph. A paragraph could not have
held columns in line anyway: the font is proportional and this project ships
no monospace face.

**It only fills in after events.** `tournament.gd::bracket_state()` is the new
pure model, and it refuses to name anybody in a bout whose two feeding bouts
are not both decided. The old board printed `You vs Tam` in the semi-finals and
`You vs Oskar` in the final **from the moment the draw opened** — pairings that
only exist if you already know who wins the quarter-finals. A bracket that
prints the future is a spoiler.

The tree needed no new data: `bracket`'s slot order already is the draw, slots
pair (1,2)(3,4)(5,6)(7,8), and their winners pair up in turn — exactly what
`tournament.json`'s own `_comment_pairings` describes.

Undecided slots draw an empty ruled line rather than nothing, so a board with
nothing decided still reads as a bracket with places waiting in it.

`tests/test_tournament.gd` now pins the ruling directly:
`test_a_later_round_names_nobody_until_its_feeders_are_decided` walks the
whole ladder and fails if any column resolves early.

---

## 4. Integration finding — the Gate B chain needs both branches

The fresh-save evidence run needs `origin/ralph/integration-3` **and**
`origin/ralph/TOURNAMENT-1` together, and neither branch alone can produce it:

- integration-3 carries `data/progression/objectives.json`'s 12-entry Gate B
  chain and the four wired ladder flags;
- three of that chain's entries name `tournament_team_ready`,
  `tournament_entered` and `tournament_won`, which exist only on TOURNAMENT-1.

They merge with exactly one conflict — `ralph/BLOCKED.md`'s map-fog entry,
still "OPEN" on TOURNAMENT-1's side against integration-3's "RESOLVED by owner
ruling". Resolved in favour of the owner ruling.

**Every flag in the merged chain has a real writer except the first.**
`opening:beat:road` ("Catch your first wild creature") is named by
`objectives.json` and set by no `.gd` file in the merged tree, so as written
the chain's opening line may never tick over — the first objective a new
player is ever shown. Worth confirming on the evidence path before it is
called a defect, but it is the one gap in the audit.

---

## 5. The fresh-save evidence run

Run on the merged tree (integration-3 + TOURNAMENT-1 + this branch) with
`tests/smoke_gate_a_opening_segment.gd --gate-a-continuous-core`, which drives
real joypad events through the live InputMap per the owner directive's
verification section.

**It does not currently reach a first catch.**

```
+67.64s  starter selected and named
+72.11s  usable house/front doorway exited
+93.10s  tutorial Bramblebun combat entered
+100.29s Bramblebun naturally weakened to 28/124 HP
         launch 1: eligible, STRIKE -- no catch
         launches 2-8: reticle_outside_body / line_of_sight_blocked
FAIL: eight natural weakened-target launches produced 1 strike, 7 misses, no catch
```

Everything before the catch works: the title, a fresh save, the wake, Grandpa,
the starter and naming, the usable front door, the walk out, a natural wild
encounter, and weakening the target through real combat. The failure is at the
throw: after the first launch the reticle reads 1.24, 1.36, 1.55 and 0.81
against a 0.600 body radius, so the harness is not re-converging on a creature
that has moved.

**This is not yet proof of a defect.** This box is software-rendered with
different frame timing from CI, and integration-3 presumably went green there.
Distinguishing "the catch beat is fragile" from "this environment throws the
aim off" needs a real CI run on a `ralph/**` branch. Until that runs, the
honest statement is: **nobody has yet walked the Gate B path end to end**, and
the last place it stopped is the first catch.

### A test fragility found on the way

The first attempt failed at the title with "Start New Game never reached the
configured Meadows world", which was misleading. `title_screen.gd::
_on_new_pressed()` checks for existing saves and shows a "Start a fresh game?"
confirmation whenever any exist -- and the harness has no answer for it, so it
waits out its 2400-frame budget and reports a load failure.

Earlier runs on this machine had written an autosave into `user://`, which is
what triggered it. CI never sees this because CI starts with an empty save
directory. Two consequences worth acting on:

* the harness should answer that confirmation, since a returning player meets
  it every time -- as written, the fresh-save path is only ever exercised in
  the one case a returning player never hits;
* an evidence run has to start from a known-clean `user://` or it is not a
  fresh save at all.

---

## 6. The condition gate — RG19-spec/D68

Built this session, after confirming no other branch was building it.

The owner's original entry rule was "well rested, well fed, and happy". What
`TOURNAMENT-1` shipped checked party size and level only; the condition half
existed nowhere in the tree. `scripts/creatures/creature_condition.gd` over
`data/config/creature_condition.json` is the model — pure static functions,
every threshold in data, interpreted in exactly one file:

* **rested** is the creature bed's existing flag, plus an expiry (45 minutes
  awake, tunable) and a faint that clears it;
* **fed** is a `nourishment` meter that drains on real time and does not
  drain in a bed;
* **happy** is a `happiness` mood, deliberately SEPARATE from `bond` so bond
  stays permanent progression nobody can be punished out of.

D29's light-hunger rule extends to creatures and is pinned by a test: an
empty meter makes a creature ineligible, never damaged and never dead.

Fed by playing — berries carry a `creature_food` block and go through the
backpack's existing target picker. Gated in one shared place —
`tournament.gd::condition_ready()` / `readiness_report()`, which the marshal,
the team screen and the entry check all read. Halda gains one branch on
`tournament_condition_ready`, the only VOLATILE flag in the store, and a line
that names rest, food and time together instead of refusing flatly.

Proven in the real player path by `smoke_tournament_bracket.gd`:

```
branch: a levelled team in poor condition -> tournament_halda_condition
condition: refused, and the report says -> Terrapup needs a night in a creature bed, is unhappy.
condition: fed the team and rested them -- 3 creature(s) ready
branch: a team that qualifies -> tournament_halda_signup
```

One safety rule is asserted rather than assumed: condition gates ENTRY, not
the bracket. A team that goes hungry between bouts is still offered the round
it is halfway through, because being sent back out to feed somebody with a
fight half fought is the one way this gate could strand a run.

**Unit suite with all of it: 1234 tests, 728061 assertions, 0 failed.**

---

## 7. Still open before Gate B can be called done

1. **Nothing is on `main`.** TOURNAMENT-1, integration-3 and this branch are
   three unmerged branches, and the Gate B objective chain is split across two
   of them. Gate B cannot be evaluated on `main` today.
2. **No CI run.** `claude/**` does not trigger `ci.yml`; everything here was
   run locally on a software-rendered box. A `ralph/**` push is what settles
   both this and item 3.
3. **The fresh-save path stops at the first catch, deterministically.** Not
   flaky: three separate runs on a clean save directory all ended
   "eight natural weakened-target launches produced 1 strike, 7 misses, and
   no catch". A fourth run captured the game's own commit lines and shows
   the aim is NOT the whole story:

   ```
   catch launch: commit eligible=true  reticle=0.160/0.600 first_hit=Wild_bramblebun_2 los=true
   catch launch: commit eligible=true  reticle=0.256/0.600 first_hit=Wild_bramblebun_2 los=true
   catch launch: commit eligible=true  reticle=0.410/0.600 first_hit=Wild_bramblebun_2 los=true
   catch launch: commit eligible=false reticle=0.884/0.600 ... reason=reticle_outside_body
   ```

   Three launches the GAME judged eligible, well inside the body, line of
   sight true, against a Bramblebun weakened to 31/124 HP -- and no catch.
   `combat_manager.gd:178` calls `_rng.randomize()`, so this is not a fixed
   seed repeating one unlucky sequence.

   On `data/config/catching.json`'s headline numbers a centred throw at that
   HP should sit somewhere around half. Three good throws failing, in every
   run, is not that. Either the effective chance is far below what the config
   reads like, or the weakened-HP factor is not reaching the roll. **This is
   Gate A's catching beat, not the tournament's**, and it is handed over
   rather than fixed here -- but Gate B cannot pass while the first catch in
   the chapter behaves like this, because every later beat is downstream of
   it.

   The secondary half is real too: after the first throws the harness's aim
   drifts (0.884, 1.389) and stops re-converging on a creature that has
   moved, so a player gets fewer good throws than the eight the test spends.
4. **`opening:beat:road` has no writer** -- the chain's first objective, the
   first line a new player is shown.
5. **"Enough nearby creatures to prepare naturally" is unproven.** The bracket
   smoke BUILDS a qualifying team; nobody has shown a player can reach the
   entry threshold through ordinary play in the opening area. That is a named
   Gate B pass criterion.
6. **Both blind visual passes answered no to both bar questions.** The board
   itself was rebuilt in response; what remains is not this object -- no
   creatures in a creature game's own venue, no event dressing, a cloudless
   sky, a sourceless shadow, and two humans who read as one human twice.

### Closed since the first draft

* **The South Bridge grunt is not a tournament event.** Measured: the grunt
  stands 1299m from the tournament board; Oskar's final is 3m from it. The
  tournament's handoff is the objective pointing south; the grunt is who the
  player meets on arrival. Confirmed with the owner.
* **Save/load across the bracket** is covered -- five tests in
  `test_save_format.gd`, including a real VERSION 12 save rewritten on disk.
* **The condition gate** exists (section 6).
