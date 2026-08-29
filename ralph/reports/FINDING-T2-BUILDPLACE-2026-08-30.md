# FINDING — the S03 build-placement failure is a RIG defect, not a GAME defect

**Verdict: RIG, confirmed live in the engine.** `build_menu.gd` /
`build_placer.gd` / `home_progress.gd` all behave exactly as designed at
every point checked. `S03.json`'s own gathering loop (`S03-65`..`S03-104`)
never equips a tool before pressing `interact` on a wood/stone/fiber node,
so — by a design that is itself pinned by a passing unit test — those
gathers silently yield zero, the satchel never affords camp or a creature
bed, and the build catalogue's own "can't afford, stay open" refusal
(`build_menu.gd:713-719`) is what the run's telemetry actually shows as
`input_context` stuck on `build_catalogue` (`S03-117`, `S03-130`,
`S03-143`, `S03-156`, `S03-169`) and `home_built`/`creature_bed_built_3`
never set (`S03-173`, `S03-205`).

## The chain, each link verified against source, a real save, and a live probe

1. **The run's own kept `S03-exit.json` has zero wood, zero stone, zero
   fiber, `placed_buildings: []`, and five berries.** Not "gathered less
   than the threshold" — genuinely none. `events.jsonl` for the whole
   segment contains zero occurrences of the strings "wood", "stone" or
   "fiber", and zero `gather` events.

2. **Wood, stone and fiber are all tool-gated; berries is not**
   (`data/items/items.json`: `wood.gathered_with = "axe"`,
   `stone.gathered_with = "pickaxe"`, `fiber.gathered_with = "knife"`, no
   `gathered_with` on `berries`). `harvest_logic.gd::gather()` returns
   `{"amount": 0}` whenever `equipped_tool != required` — including empty
   string, i.e. no tool equipped at all. This is not incidental behaviour:
   `tests/test_harvest.gd::test_gather_with_no_equipped_tool_is_refused`
   exists specifically to pin it, with the docstring "carrying an axe is
   not enough when no tool is visibly equipped."

3. **`S03.json` never equips a tool anywhere in its 20-node gathering
   loop.** Grepped directly: every gather step is `move_to` then `press
   interact` (x2), with no `hotbar`/`equip`/`assign_hotbar` step before,
   between, or after any of them. The harness has no such step type at all
   (`operator_harness.gd` has no `assign_hotbar`/`equip` action). Since
   `equipped_tool` starts empty and nothing in this segment's own steps
   ever changes it before the gathering loop, every wood/stone/fiber
   attempt is refused by design, exactly as berries (no gate) succeeds
   (5 in the final inventory) while the other three never appear at all.

4. **Live-engine confirmation, `tools/gate_f/probe_build_catalogue_arm_cause.gd`**
   (`godot --headless --path . --script
   tools/gate_f/probe_build_catalogue_arm_cause.gd`), against the real
   `build_menu.gd`/`build_placer.gd`/`home_progress.gd` in the production
   `meadows_playground.tscn`, driven through the same synthetic-controller
   path `S03.json` itself uses (`Input.parse_input_event`, not a bypass):
   - **Part 1**, at zero materials: arming camp reproduces the run's own
     observation exactly — the menu stays open, `pending_build` stays
     empty. This is `_pick()`'s own affordability refusal
     (`AUDIO_CUES.play(&"ui_error")`, no `close()`), not a broken
     catalogue-to-placement handoff.
   - **Part 2**, with camp's real cost (12 wood / 8 stone / 10 fiber)
     granted: the identical button sequence arms the piece, closes the
     menu, sets `pending_build == "camp"`, and a real `build_place` press
     produces a genuine `placed_building` node tagged `camp`.
   - **Part 3**, with creature_bed's cost (6 wood / 8 fiber) also granted:
     the same chain places a real `creature_bed`, and `home_progress.gd`
     sets `home_built` the instant both required pieces
     (`data/config/progression.json`: `home.required_pieces` is now just
     `{camp: 1, creature_bed: 1}`) stand in `GameState.placed_buildings`.
   - Full transcript ends `PROBE PASS`.

   **This is the direct answer to the brief's "diff `smoke_gate_a_rest_
   torch.gd` against S03's own steps."** That smoke test's own header says
   why it cannot answer this question on its own: it "directly arms
   free-build pieces" (`_game.set("pending_build", id)`) specifically to
   skip the catalogue, so its PASS never exercised `build_menu.gd::_pick()`
   at all. This probe closes that gap by driving the catalogue for real.

5. **A second, smaller, already-recorded RIG defect in the same
   neighbourhood, NOT the cause of the S03-117/S03-205 failures but worth
   naming**: `S03-181` ("focus Creature Bed") independently FAILs —
   `1 x ui_right did not move focus off` the first grid cell — in the
   furniture category, which holds Storage Chest then Creature Bed
   (`data/items/buildables.json` order). This probe's own Part 3 sidesteps
   it (`menu.call("_pick", 1)` directly) rather than re-diagnosing a
   second, separate focus bug while answering the RIG-or-GAME question.

## Round 2 — a SEVERE, previously-undiscovered GAME defect, found while proving the fix end to end

Chasing "why is the satchel never affordable" one layer further: Tam's own
gift (`data/dialogue/village.json:181`, `tam_tools_given`) is **only**
`give:knife:1, give:torch:1` — no axe, no pickaxe. Those come exclusively
from Mira's unconditional first-visit conversation
(`village_mira_shop_intro`, `data/dialogue/village.json:29-39`,
`give:axe:1, give:pickaxe:1, give:coin:30, flag:mira_shop_open`), gated in
`data/config/village_npcs.json:26-28` purely by `unless_flag:
mira_shop_open` — no combat/ally-state gate at all.

The first pass of this finding left this open, having ruled out the
fainted-party hypothesis by an isolated probe. A live, full-segment replay
of the fix (10 attempts, `ralph/reports/gate-f-buildplace-validation/`)
answered it, and the answer is much bigger than a Mira-specific bug:

**`scripts/combat/encounter_director.gd::interaction_offer()` (line ~1037)
returns a priority-100, distance-0 `"<ally> is out of the fight."`
statement UNCONDITIONALLY whenever the tracked `_ally` has fainted — no
proximity gate, checked before `_engageable()`.** `prompt_arbiter.gd`
ranks priority before distance always ("a status line about the creature
at their heels... still has to beat a creature nine metres away" — the
file's own comment), so this one line outranks **every other interaction
in the world**: not just re-engaging a wild creature, but every village
NPC greeting, every harvest node, every creature bed's own rest prompt —
for as long as `_ally` stays non-null and fainted, which only a fresh
save/load clears (confirmed: `_ally`/`_ally_body` are never cleared by
ordinary play, matching RIG-13's own finding that a load resets them).

**A real player whose only starter faints during the tutorial's own first
catch attempts (a normal, RIG-15-acknowledged possible outcome) becomes
unable to interact with anything in the game world afterward** — cannot
catch a replacement creature (catching is `interaction_offer()`-gated too,
and `_engageable()` is checked *after* the blanket clause), cannot talk to
any NPC, cannot gather, and cannot reach a creature bed's rest prompt —
for the rest of that play session, with no in-game affordance suggesting
a save+reload is the way out. This reads as a genuine soft-lock risk in
the opening tutorial. **Out of this lane's ownership**
(`scripts/combat/**`, actively edited by T3-TYPECHART) and **not fixed
here** — flagged loudly, per this lane's brief, for whoever owns that
file.

The one in-session mitigation available from the rig side:
`encounter_director.gd::_read_creature_control_input()` toggles
`creature_recall` between `summon_active_creature()` and
`dismiss_active_creature()`; pressing it while a fainted ally is still
deployed calls the latter, which sets both `_ally` and `_ally_body` back
to null and clears the blanket override. `S03.json` now presses this
right after the catch loop (`S03-39b`), before Bryn's own challenge
attempt (which reads the now-null ally and falls back to dialogue without
re-summoning anything).

**Still open after this pass**: even with the blocking prompt cleared,
getting the walker reliably next to Mira specifically has not converged.
Across the ten replays: a `move_to_entity` walk against her own live
position once completed cleanly (`0 held`, reached within `2.5m`) but
another time got stuck on her building's wall (`120 held`, stopped `6.9m`
short); the original authored coordinate (`18.99,-1.01`, which is in fact
her exact configured spawn point) lands anywhere from `0` to `120 held`
frames and `2.27m` to `4.9m` short of her depending on the catch loop's
own RNG-varied outcome upstream. The last diagnostic taken
(`interactable.gd::_has_line_of_sight`'s own raycast, read directly) shows
every candidate approach point as "blocked," but that reading is not
trustworthy as recorded — a quick from-scratch raycast probe does not
replicate the two clearance trims the real function applies at each end
specifically to avoid a prompt occluding itself, so it likely just hit
Mira's own collision body, not a real wall. **The honest state: Mira's
own interaction radius (`npc_body.gd::add_prompt`, default `3.8m`) should
comfortably cover every stop point recorded, and it is not doing so for a
reason this pass did not pin down.** Whoever picks this up next should
read `_has_line_of_sight`'s two clearance constants and either replicate
them exactly in a probe, or add temporary debug logging to
`interaction_offer()` itself to print the actual refusal reason
(radius vs. line-of-sight) at the walker's real stop point.

## Round 3 — the real cause of the Mira approach, and a second GAME-shaped hole this lane could actually close

Round 2's own "still open" section named the right next step (read
`_has_line_of_sight`'s clearance constants for real rather than guessing at
more tolerances) and this pass did exactly that, but by calling Mira's REAL
LIVE `Interactable._has_line_of_sight()`/`interaction_offer()` methods
directly (`tools/gate_f/probe_mira_los_check_v2.gd`) instead of
reimplementing the raycast — the mistake round 2 named in its own deleted
probe. The sweep alone was misleading (see below); the actual cause needed
one more probe.

**The actual cause: OF31 put Mira behind a real, physically shut door, and
nothing in this segment (or the prior two rounds' fixes) ever opened it.**
`data/config/village_npcs.json:47` and `scripts/world/village_door.gd` are
explicit that Mira stands inside `cottage_a` behind her counter, and
`village_door.gd::setup()` gives the doorway a real `Gate` `StaticBody3D`
collider (1.6m × 2.3m × 0.45m) that starts **closed** (`_open = false`) and
stays that way until a player presses its own "Open Door" prompt. A live,
from-scratch physics raycast confirms it: `is_open() == false` at boot, and
a ray cast from just outside the doorway to just inside **hits the `Gate`
collider directly**. This single collider blocks BOTH things at once:

- **The walk.** `tests/helpers/stick_navigator.gd` has no notion of "open a
  door" — it only slides along whatever is solid, hunting for a gap that
  genuinely is not there while closed. `tools/gate_f/probe_mira_walk_trace.gd`
  reproduced this directly: a short walk from 2m outside the closed door to
  a point just past the threshold went nowhere for 900 frames, sliding the
  walker up to 9m off course in each direction before giving up — the exact
  shape of every "stuck 2-5m short" symptom rounds 1 and 2 recorded. The
  SAME walk, from the SAME start, to the SAME target, with nothing else
  changed but `door.force_open(true)` first, arrived cleanly in 51 frames.
- **The line of sight.** `interactable.gd::_has_line_of_sight()`'s ray hits
  the same `Gate` collider, so any approach point that still needs to look
  *through* the closed door reads as blocked. This is why round 2's own
  ten replays saw a mix of "stuck short" and "arrived but still refused" —
  both are the same door, read two different ways depending on exactly
  where the walker happened to stop.

Round 2's LOS sweep (kept above) is **not wrong, but it is misleading on
its own**: every "Greet Mira: true" result it found was a line that stayed
entirely on one side of the door plane (either fully inside the shop, near
Mira, or grazing the side wall) and never actually needed to cross the
closed gate — so the sweep could report Mira's own prompt as reachable
from many points while the walker could still never physically get to any
of them from outside. A LOS sweep answers "is the interior visible from
here", not "can a walking body reach here at all" — the second question is
a physics-collision question the sweep never asked.

**The fix** (`tools/gate_f/segments/S03.json`, `S03-52`..`S03-52c`): walk
to a FIXED point 1m outside the door on its own approach lane (independent
of wherever Bryn's fight left the player — the round-1/round-2 theory that
RNG-varied arrival position was the cause is superseded by this: a fixed
staging point removes the variable regardless, because the real cause was
never positional noise), press `interact` on the door's own "Open Door"
prompt (`village_door.gd::_on_activated()` disables the gate collider
**synchronously**, before its leaf even finishes its cosmetic swing), wait
briefly, then walk straight to Mira. Live-confirmed converging in well
under 100 walking frames with `0 held` in both an isolated probe
(`tools/gate_f/probe_mira_walk_trace.gd`) and two full, real S03 segment
replays end to end.

## Round 3, second finding — party_cycle alone cannot recover from a party that never grew past one

Proving the door fix end to end surfaced a second problem, again live and
again not visible from source reading alone: **two independent full S03
replays against the same S02-exit seed and the same scripted input both
left `party_size == 1` at S03-39**, with the sole starter fainted. This is
not the "occasionally the active ally faints" case round 2's own
`creature_recall`/`party_cycle` fix addressed — it is the case where
**every one of the ten catch attempts failed to grow the party**, so there
is no second, healthy party member for `party.gd::cycle_active()` to
switch to. Round 2's own dismiss, and this round's initial `party_cycle`
replacement for it, both go silent in exactly this shape: neither can
un-faint the only creature there is.

Both replays produced this identical outcome against the same seed and the
same button sequence, which says the segment's own catch loop (unowned by
this lane — `S03-32a`..`S03-38j`, pre-existing) is not merely "unlucky
sometimes" against this exact save; it is the deterministic result of
driving these exact ten catch attempts against this exact starting state.
Whether that is itself worth a finding about the catch loop's own pacing
(one attacker, ten fights, no chance to rest between them) is a question
for whoever owns that loop, not answered here — it is out of scope for a
lane whose brief is the Mira approach, and is named rather than touched.

**The fix**: `data/items/items.json`'s `revive` item — "the only thing that
raises a creature back up once it's fainted", granted ×2 in the opening
satchel — used through the real Satchel UI
(`scripts/ui/tab_backpack.gd`), the same way a player would. Verified in
both directions before being added to `S03.json`
(`tools/gate_f/probe_revive_menu_flow.gd`): pressing `interact` on the
Revive slot when nobody is fainted refuses harmlessly ("Nobody needs
reviving.", no state change); a stray `ui_accept` immediately after that
merely picks the stack up (Godot's ordinary grid carry gesture, not
destructive); and the exact unconditional four-press close sequence this
lane needs (`interact`, `ui_accept`, `menu_cancel`, `menu_cancel`) reaches
a closed Satchel with no leftover held/targeting state in BOTH the
"nobody needed it" and the "someone was revived" branches — which is what
makes it safe to run every time with no conditional a step-script cannot
express anyway. `S03-39d`..`S03-39k` run it right before Bryn's challenge;
`S03-51e`..`S03-51k` run the identical sequence again right before Mira's
door, because Bryn's fight is now REAL (see below) and can cost the ally
just as the catch loop can. Reviving mutates the SAME creature instance
`encounter_director.gd`'s `_ally` already points to, so `fainted` clears
immediately with no dismiss/resummon needed at all.

Both full replays independently confirm this fires correctly at exactly
the frames it should (`events.jsonl`: `"craft" | gained [] lost
[revive -1] in menu_backpack"`, once before Bryn and once before Mira in
each run) and that the party is not left permanently stuck: Moss (the
starter) faints during the catch loop, is revived before Bryn, fights Bryn
for real, faints again during that real fight, and is revived a second
time before Mira's door — all inside the same run.

## Round 3, incidental correction — Bryn's fight was never real in round 2's own fix

Chasing the fainted-party question surfaced that round 2's `S03-39b`
(`creature_recall`, dismissing the ally before Bryn) had an unintended
consequence its own note did not call out:
`encounter_director.gd::can_challenge()` refuses a **null** ally exactly
like a fainted one (this is RIG-13's own finding, already on record for
the post-load case — round 2's fix reintroduced the same gate a different
way). With `_ally` dismissed to null before `S03-44`, `trainer_npc.gd`'s
own `_on_challenged()` read `can_challenge() == false` and opened Bryn's
`defeated` conversation instead of his `challenge` one — so `S03-48`'s and
`S03-50`'s `combat_quick` presses landed on no fight at all, `S03-51a`'s
level-up capture had no level-up to catch, and the training rung's own
evidence (Section L.4 T05/T06, GF-14-COMBAT-02) was never real in that
fix, even though the segment's own step verdicts read PASS throughout —
exactly the "evidence-shaped, not evidence" failure mode this whole lane's
brief exists to catch. This round's `party_cycle`+`revive` combination
(above) keeps `_ally` live and non-fainted instead of nulling it, so
Bryn's real `challenge` conversation opens and the fight that follows is a
real one, live-confirmed in both full replays (`combat_quick` presses land
against a live opponent, `party_cycle` mid-fight swaps a real pilot, XP and
level-up fire normally).

## Round 3 — still open: the kept `S03-exit.json` is NOT healthy, and a fourth cause was found (not fixed)

**Stated plainly, per this lane's own brief: the fix above is real, live-
confirmed, and does not converge on a healthy exit save by itself.** The
final full replay this round (`ralph/reports/gate-f-buildplace-round3-
validation/S03/saves/S03-exit.json`) ends with `party_size == 1`
(still never grew past the starter, all segment long) and that one
creature `fainted: true`, `hp: 0.0`. Reading `events.jsonl` end to end
finds the actual chain, and it is downstream of everything fixed above,
not a failure of it:

1. Moss faints in the catch loop (t≈271s) — the S03-39d revive fallback
   catches it (t≈341s, `revive -1`).
2. Moss faints again in Bryn's now-real fight (t≈356s) — the S03-51e
   revive fallback catches it too (t≈377s, `revive -1`). The satchel now
   holds zero Revives (it started with exactly 2).
3. Mira's door opens, the walk in succeeds, her first-visit conversation
   completes, the tool-equip sequence runs — all of this lane's own fixed
   ground, and all of it held.
4. **`S03-60`** (pre-existing, several hundred lines further into the
   segment, never touched by this lane — "walk past Oskar on the way
   back", `move_to` (22,-6) with `answer_prompts: true`) FAILs: `did not
   reach (22, -6) in 3000 walking frames; stopped 4.5m short at
   (19.0, -3.0), 0 held` — i.e. it spent its ENTIRE budget stuck right
   next to Mira's own building without ever leaving. While stuck,
   `answer_prompts`'s own stuck-mashing behaviour (§`_walk_loop`, presses
   `interact`/`menu_confirm` every 20 held frames) pressed `interact`
   against Mira again. Because `mira_shop_open` is already true and
   `defeated_mira` is false, her SECOND-visit branch answers this time —
   her own Band-1 challenge conversation
   (`village_mira_challenge`/`battle:trainer_mira`,
   `data/config/village_npcs.json:31-34`) — which a completely
   undefended, unrevivable (0 Revives left) Moss then takes a real hit in
   and faints for the last time (t≈440s, `combat_hit`/`faint`), with
   nothing left in the segment to heal it. The Satchel's own Revive stack
   was legitimately spent twice already, correctly, on two real prior
   faints; there was nothing wrong with spending it, there was simply
   nothing left when a THIRD, unanticipated fight started.
5. Everything after that (`tournament_build_creature_beds`,
   `creature_bed_built_3` never set, and a much later `move_to
   creature_bed.gd` FAIL — "stopped 7603.7m short", i.e. no reachable bed
   exists) reads as consequences of #4 rather than new causes: no bed ever
   gets built (the gathering/building loop past this point is unowned by
   this lane and not audited here), so the sleep step this whole chapter's
   original finding named as "nothing ever heals it before the tutorial's
   sleep step" never gets a chance to run either.

**This is the SAME class of bug as the Mira door, one level further out**:
`S03-60`'s own walk starts from wherever `S03-56j` left the player, which
after this round's fix is now genuinely INSIDE Mira's shop (past the
counter, near her own tile) for the first time ever — a state no earlier
round's replay ever reached, because no earlier round ever got the player
through the door at all. `S03-60` was written and (apparently) never
live-tested from that starting position, and a straight line from inside
the shop back out to Oskar likely clips the same counter/doorway geometry
the entry leg did, now in reverse. **Not fixed this round** — found while
proving the door+revive fix end to end, past this lane's own scope
(`S03-60` sits well outside the `S03-39`..`S03-56` range this lane was
asked to look at), and out of remaining time to diagnose and prove a fix
for with the same rigour the door and revive fixes got.

A candidate fix (untested, do not trust without a live probe run first)
is sketched at the bottom of `tools/gate_f/probe_mira_walk_trace.gd`: route
`S03-60`'s walk through the same door-approach staging point
(`local(1.0, 5.0)` of cottage_a, world `(14.464, -4.121)`) this round's
`S03-52` already uses on the way in, before continuing to Oskar — on the
theory that the exit leg fails for the same reason the entry leg did
(a straight line from inside the shop to a distant point clips the counter
or door frame) and the same "step outside onto open ground first" fix
should work in reverse. **This has not been run to completion or verified
live** — the probe script parses and the two new test blocks are written,
but this session ran out of time before executing and reading the result.
Whoever picks this up next should:

1. Run `godot --headless --path . --script
   tools/gate_f/probe_mira_walk_trace.gd` and read the two new blocks'
   output (`--- S03-60 reproduction ---` and `--- S03-60 candidate fix
   ---`) to confirm the reproduction actually fails the same way live,
   and whether the staged fix actually converges.
2. If it converges, add the same staging step to `S03.json` immediately
   before `S03-60` (mirroring `S03-52`'s own pattern) and re-run a full
   segment replay to confirm a genuinely healthy `S03-exit.json` — this
   time reading the party's `hp`/`fainted` fields directly from the save,
   not trusting `"complete": true` (this round's own replay showed
   `"complete": true` with a fainted, zero-HP party, which is exactly the
   trap the original task brief warned against).
3. If it does not converge, the underlying counter/doorway geometry
   inside `cottage_a`'s shop interior may need a look from whoever owns
   `scripts/world/shop_interior.gd` — not touched or further diagnosed
   here.

## Why this matters beyond S03

Both defects share the same shape as the South Bridge stranding
(`FINDING-T2-STRANDING-2026-08-30.md`): an early, quiet, unasserted state
gap (no tool equipped; possibly a missed NPC interaction) that only
becomes visible many steps later as a loud, heavily-asserted failure
(`input_context` stuck, a flag never set) whose own immediate neighbourhood
is not where the cause lives. Reading `build_menu.gd`/`build_placer.gd` in
isolation, or the failing assertions' own step text, would not have found
either cause; both needed the actual save contents and a live probe.

## Impact on other lanes

The fix (across all three rounds) touches only
`tools/gate_f/segments/S03.json` and adds probe tooling under
`tools/gate_f/`. No file under `scripts/`, `data/`, or any other
game-code/content path is touched by this finding — `build_menu.gd`,
`build_placer.gd`, `home_progress.gd`, `harvest_logic.gd`,
`data/dialogue/village.json`, `village_door.gd`, `interactable.gd`,
`tab_backpack.gd`, `creature_instance.gd`, and `encounter_director.gd` are
all confirmed correct as shipped (or, for `encounter_director.gd`, already
flagged and out of this lane's ownership) and none are modified here.

Round 3 worth naming as a general observation for this codebase, same
shape as round 2's own "one defect masquerading as several": a diagnostic
that answers a narrower question than it looks like it answers can send an
investigation sideways for a full round. Round 2's LOS sweep looked like
proof that Mira's own prompt was reachable from many points near the
door — it was proof of something true but narrower (interior visibility),
and the actual blocker (a closed physical door) needed a second, different
kind of probe (a real physics raycast, then the real walk) to surface at
all.
