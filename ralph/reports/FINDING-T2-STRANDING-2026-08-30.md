# FINDING — the South Bridge stranding is a RIG defect, not a GAME defect

**Verdict: RIG, confirmed live in the engine.** The world is behaving exactly
as designed at every point in this chain. The fix is in
`tools/gate_f/segments/S03.json` (pushed alongside this finding); full
mechanism and evidence below.

## Live-engine confirmation

`tools/gate_f/probe_stranding_cause.gd`, run against this run's own real
`S05-exit.json` (`godot --headless --path . --script
tools/gate_f/probe_stranding_cause.gd`), reproduces the exact block and its
exact cure:

```
load_slot(4) applied: true
party size after load: 1
active creature: Moss  fainted=true  hp=0.0/1.18
--- pressing creature_recall (RIG-13's S05-09a step: summon_active_creature()) ---
summon_active_creature() returned: false
can_challenge(south_bridge_grunt) BEFORE healing: false
--- healing the party's only creature the way a creature bed does (heal_fully()) ---
active creature after heal_fully(): fainted=false hp=1.18/1.18
summon_active_creature() after heal returned: true
can_challenge(south_bridge_grunt) AFTER healing: true
PROBE PASS
```

Nothing else changed between the two `can_challenge()` calls — not position,
not the gate, not any flag. Healing the party's one creature is the entire
difference between permanently blocked and immediately able to fight the
South Bridge grunt.

## The chain, each link verified against source and this run's own telemetry

1. **S03's own catch loop can faint the player's only creature on a real,
   non-buggy roll.** `gate-f-run-20260828T183531Z/S03/telemetry/events.jsonl`
   has a `faint` event at `t=256.0`, `type: combat_hit`: "Moss fainted",
   `hp: 0.0/1.18`. RIG-18 (`RESTARTS.md`) already found the *catching* odds
   were fair; it never checked the player's own creature's HP during the same
   fights. It was fainting.

2. **`encounter_director.gd::summon_active_creature()` (line 864) correctly
   refuses to deploy a fainted creature**: `if creature == null or
   bool(creature.get("fainted")) or bool(creature.get("resting")): return
   false`. This is the same action RIG-13's fix (`S0n-09a`, "press
   creature_recall after every load") presses after every segment boot. With
   the party's only creature fainted, it silently no-ops every time, forever.

3. **`can_challenge()` (line 1568) correctly refuses every trainer/gate fight
   without a deployed ally**: `if _ally == null or _ally.fainted or
   _ally_body == null or not is_instance_valid(_ally_body): return false`.
   Confirmed directly in this run's own S05 telemetry: the "Old Bram" fight
   at S05-34..38 shows only `dialogue` events, never `combat_start` — the
   step-script's button presses succeeded, but no fight ever staged, exactly
   like the South Bridge grunt three minutes later.

4. **`trainer_npc.gd::_on_challenged()` (lines 171-172) cannot distinguish
   "no usable creature" from "already beaten"** — it shows the trainer's
   `defeated` conversation whenever `can_challenge()` is false for ANY
   reason. This is why `RESTARTS.md` saw the South Bridge grunt open with
   his post-victory lines ("Take it, I'll tell them you had a key already")
   on a completely fresh approach: not a flag bug, just the one fallback
   branch a fainted-ally refusal and an already-won fight share. This is a
   minor, real, secondary UX defect worth a Track 3 ticket (a player in this
   state gets no explanation at all — `_creature_control_offer()` also
   returns an empty prompt rather than any text when the only creature is
   fainted) but it is not the stranding's cause.

5. **The South Bridge gate is a real, correctly-locked physical collision
   barrier** (`gated_crossing.gd`, `GateCollision` `StaticBody3D`,
   `_shape.disabled` only flips on `_unlock()`), and `south_bridge_key` is
   exclusively `south_bridge_grunt`'s combat reward
   (`data/config/bands/band1_lower_meadows/trainers.json:188`, confirmed by
   the 2026-08-22 owner directive comment at line 163). Since the fight can
   never start (step 2-3), the key is never obtained, and the gate never
   opens. This is the intended design, working correctly.

6. **Every `move_to` step from S05 onward that targets a point past the
   bridge is asking the harness to walk through a permanently, legitimately
   locked gate.** The straight-line primitive has no "this target is
   unreachable, stop" case; it keeps trying, and in trying appears to drift
   near the gully edges around the gate. `scripts/world/severed_spokes.gd`'s
   `_add_carve_failsafe()`/`_on_carve_failsafe_entered()` — a real,
   correctly-functioning system that returns a player who falls into a carve
   back to the road — fires every time this happens, which is the 600+
   `[severed_spokes] player went over the edge` lines per segment
   `handover-GATE-F-RUN-3-2026-08-29.md` already recorded. The failsafe is
   not malfunctioning; it is being triggered on a genuine loop the walker
   cannot break out of on its own.

## Why this is RIG and not GAME

Every system inspected — the fainted-ally combat gate, the trainer dialogue
fallback (modulo the minor UX gap noted above), the physical bridge lock, and
the carve recovery volume — is doing exactly what its own code and comments
say it should. **A real player is not stuck here**: S03 builds three creature
beds specifically for this ("R4.8... `heal_fully()` — GAME_DESIGN.md's own
phrase: 'revives a fainted creature'"), and `data/config/progression.json`'s
own `creature_bed` comment says sleeping through the night completes any
occupied bed's heal immediately. `tools/gate_f/segments/S03.json` builds
those three beds (`S03-176`..`S03-205`) and even sleeps at home afterward
(`S03-223`..`227`) — but never once assigns the fainted creature to a bed
first, so the sleep step heals nobody. That is the gap: an ordinary,
available recovery action the step-script never takes, not a broken world.

## The fix (pushed with this finding)

`tools/gate_f/segments/S03.json` gains five steps (`S03-205a`..`S03-205e`)
immediately after the three beds are confirmed built and before the existing
sleep sequence: walk to a bed (`move_to_entity` on `creature_bed.gd`),
interact, confirm the only row in the rest panel, close it. The segment's own
already-scripted sleep then completes the heal, so the S03 exit save carries
a healthy party into S04 onward — which should resolve the stranding for
every segment downstream, since nothing else in the chain needed to change.

## What is NOT yet independently re-verified by a full run

The probe confirms the underlying game mechanism, not the new step-script's
own execution. `S03-205a`..`S03-205e` mirror `X02.json`'s own already-working
`interact -> panel -> ui_accept -> menu_cancel` bed sequence
(`X02-091`..`X02-094`, part of a segment that finished 146/170 PASS with
nothing flagged wrong in that sequence), but a full S03 re-run to confirm the
new steps execute correctly end-to-end and produce a healthy exit save was
not completed by the time this finding was written — see the handover for
whether it finished by the end of the session.
