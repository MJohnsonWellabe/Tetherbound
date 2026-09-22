# D83 — Companion reactions are procedural over the model pivot, and yield to everything

**Status:** implemented (lane W12-COMPANION-0904); the tuned numbers in
`data/config/companion_presence.json` are judgment calls open to owner
playtest, the three structural calls below are not.
**Decided:** 2026-09-04, implementing addendum §E and owner directive C §5.

## Context

The owner's directive C §5 asks that the deployed creature "visibly feel
like a companion in ordinary play" — acknowledgment, a post-victory
reaction, a readable hurt state, a camp reaction, a response to care, warmer
reactions at higher bond — while explicitly refusing a pet simulation, and
while `CLAUDE.md` forbids new creature meshes and any new Meshy generation
for the Meadows. Three questions had no answer in the repo, and each admits
materially different implementations. They are recorded here rather than
queued for the owner, per `docs/AGENT_WORKFLOW.md`'s standing rule that the
orchestrator decides and records.

## 1. The reactions are procedural, because the rigs have nothing else

Measured, not assumed (`tools/_capture_companion_rig_inventory.gd`, output in
`ralph/reports/W12-COMPANION-0904/rig_inventory.txt`): **all 21 unique
creature GLBs carry exactly six clips — `attack`, `faint`, `hit`, `idle`,
`run`, `walk` — and a `head` + `neck` bone.** There is no happy loop, no
bounce, no lie-down, no look-around, anywhere in the roster, and every
species shares one animation vocabulary.

So a reaction layer built on authored clips would have had **one** state to
work with, and the directive asks for six. The reactions are therefore
procedural motion on `creature_body.model_pivot()` — a hop as a sine arc, a
nod as a pitch, a head shake as a yaw, a swell as a scale pulse, the camp
pose as a partial roll toward the species' own `rest_roll_deg` — composed
over the clips that DO exist (`hit` reused as a flinch, `attack` as a roar at
high bond) and a `LookAtModifier3D` on the head bone for the gaze.

The pivot, not the body: `creature_body.gd`'s own header already draws that
line ("the body's position is gameplay and belongs to the combat manager"),
and `play_rest()` already moves the pivot for the bed pose, so this is the
existing seam rather than a new one. The consequence is that **every species
gets every state**, which is what the directive's "prefer a reusable behavior
layer over species-specific one-off scripting" asks for, and no reaction can
desync a fight.

The alternative — authoring or generating new clips — is refused by
`CLAUDE.md` for the Meadows and would have cost a Meshy generation with no
owner reference art.

## 2. A reaction always loses to the game

Every reaction is cut, and the pivot restored the same frame, whenever a
fight, an aim, a ride, a panel or dialogue, a live actionable interact
prompt, the sequence director's lockout, or an armed build ghost is present
(`companion_presence.gd::blocked_reason()`). Not deferred, not blended —
cut. A companion moment is worth less than one frame of the player being able
to act, and the owner's own wording is that reactions must not be "noisy,
blocking, or repetitive".

**One carve-out, and it is data** (`guard.victory_during_resolve`): the
post-victory reaction plays during `combat_manager`'s RESOLVING pause after a
**won** fight. That pause is the result beat — the fight is decided, nothing
is piloting the body, and the alternative is celebrating after the arena has
already been torn down and the creature teleported back to the trainer, which
reads as a creature celebrating nothing. If the teardown hides the body
mid-celebration, the layer queues a greeting instead, so the creature turns
to the trainer when it reappears rather than standing in the empty field.

## 3. Bond warms the reactions; it does not add new ones

Higher `bond_nodes()` shortens the acknowledgment delay and its cooldown
(to a floor), adds hops and height to the victory reaction, and unlocks the
walk-up and the roar. It never unlocks a state a bond-0 creature does not
have. A creature the player has just caught still acknowledges them, still
shows it is hurt, still settles at camp; the difference is how quickly and
how warmly. The opposite design — states gated behind bond nodes — would
make the feature invisible for the first hours of a 3–4 hour chapter, which
is the part of the journey the directive is most about.

Bond-node completion is itself the layer's strongest moment. It is currently
**polled** off `bond_nodes()` each tick, keyed to the creature it was read
from so a party swap or a loaded save cannot celebrate bond earned long ago.
`on_event("bond_milestone")` is the hook the progression feed
(`docs/prompts/73-PROGRESSION-VISIBLE-bond-and-level-feedback.md` §2.1, being
built by another lane on `Game`) should call when it lands; the poll becomes
redundant then and can be deleted. This lane deliberately did not build that
feed.

## What this does not decide

The tuned numbers — the 6 s still-delay, the 30 s acknowledgment cooldown,
the 30 % hurt threshold, the 6 m camp radius, the hop heights — are first
estimates chosen to be conservative (reactions rare enough to stay special)
and live in `data/config/companion_presence.json` precisely so a playtest can
move them without touching code. An owner note that the creature reacts too
often, or not often enough, is a config change.
