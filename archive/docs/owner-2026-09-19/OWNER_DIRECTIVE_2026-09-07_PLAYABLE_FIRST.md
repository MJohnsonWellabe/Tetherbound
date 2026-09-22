# Owner directive — playable first, polish second, 2026-09-07

Recorded verbatim so it survives session turnover. Under `CLAUDE.md`'s precedence this
is a **newer owner directive and outranks every biome exit-criteria document for what
it covers**. It does not delete those criteria — it defers them.

## Verbatim

> can we make sure that codex doesn't grind on something it doesn't need to just to
> clear a visual bar and get stuck rather than continuing forward. the visuals are
> important but I really want this run to be about the 80% of the with that can be done
> in 20% of the time. we'll find back for the rest in a second pass. we need to get a
> playable four biome game out first

## What this changes

The four biome directives each define "done" with a full acceptance bar — Stormwood's
§32 (16 criteria), Water's §21 (18 criteria), and the Cloudreach and Meadows equivalents.
Those bars include blind visual judgment, ROG Ally performance budgets, full §13 density
counts and complete dialogue trees. **Every one of those documents remains the definition
of done. None of them is the target of this run.**

This run targets an earlier, explicitly lower milestone:

> **THE PLAYABLE FOUR-BIOME BUILD** — a fresh save plays from the opening through the
> end of Water without a console command, a debug teleport, or a reload to advance.

Reaching that milestone ends this run. The remaining criteria are then worked in a
second pass, against the backlog this run is required to keep.

## The blocking bar — the only things that stop the run

A criterion blocks only if failing it means the player **cannot proceed, loses data, or
the game stops working**:

1. **The path completes.** Every region enterable, every gate openable by its intended
   means, every objective advances, every required fight resolvable, every required
   reward obtainable. No dead ends.
2. **Nothing breaks.** No freeze, crash, softlock or save corruption on that path. Saves
   load, migrate and survive realm travel.
3. **Solo is the bar.** Multiplayer must not corrupt shared state or duplicate items, but
   the four-peer finale, reconnect stress and separated-island proofs are deferred.
4. **`CLAUDE.md`'s hard rules hold.** Five creatures total, the human never fights,
   real-time piloted combat, no storage box. These never bend for speed.
5. **Content floor, not content target.** On the critical path, no dead-travel gap over
   120 m, and every region's named encounters are present and fightable — even if they
   are placeholders wearing another creature's body.

## Explicitly deferred — record, never block

These are **not** abandoned. They are logged and left:

- blind visual-judge bars on every biome;
- ROG Ally performance budgets and frame-time targets;
- full §13 density counts, dialogue-node counts, recipe counts;
- Meshy replacements and the creature-coherence art work beyond the authorised pilot;
- four-peer finale, reconnect and separated-island multiplayer proofs;
- audio, VFX polish, animation quality;
- anything whose failure a player would describe as "it looks rough" rather than
  "I can't get past this".

## Anti-grind rules, binding for this run

1. **The blind visual judge runs once per biome, to record a verdict — not to pass one.**
   Log it, file the findings to the backlog, move on. Never iterate a scene to change a
   verdict during this run.
2. **One round, not two, for anything cosmetic.** The standing rule is two no-yield
   attempts; for anything on the deferred list it drops to one. If the first attempt does
   not clear it, log and leave.
3. **Take the free wins and stop.** Where a visual fix costs nothing at runtime and is a
   data or palette change — the ground/creature chroma reallocation, landmark placement
   from installed families, the night relight — do it once, early, and move on. Do not
   chase what needs new art.
4. **A placeholder is a valid answer.** Ship the encounter with the wrong body rather than
   block on the right one. Register it; do not replace it.
5. **Never weaken a test, an assertion or an acceptance criterion to move faster.**
   Deferring a criterion is written down; quietly lowering one is not permitted. The
   difference matters: the first is a decision, the second is a lie in the ledger.

## The backlog is what makes this safe

Every deferred item is written to **`docs/SECOND_PASS_BACKLOG.md`** as it is deferred,
with: what was skipped, which criterion it belongs to, why it was deferred, and what
evidence already exists. A deferral that is not written down is a defect, not a
shortcut. That file is the input to the second pass, and it is the reason this
directive costs nothing permanent.

## What has not changed

`docs/DEVELOPMENT_ROADMAP.md`'s Stage E remains the Beta Ready gate. The biome exit
criteria remain the definition of done. This directive inserts one milestone before
them; it does not lower them, and no document may be edited to make a deferred
criterion look satisfied.

---

## Amendment — creature and character art is worth a few rounds, 2026-09-07

### Verbatim

> fixing the creatures visually is worth the time i think. just as long as it's not
> countless tries but a few are fine.

### What this changes

The one-round cosmetic rule above is **too tight for creature and character art**, and
only for that. Everything else on the deferred list keeps the one-round rule.

**Creature and character meshes get up to THREE blind-judge rounds per subject.** Not
one, not countless. The third rejection ends that subject: register it in
`docs/SECOND_PASS_BACKLOG.md` with the three verdicts and move to the next one.

The reason for the exception is the standing blind verdict that the cast is "three
incompatible languages", and that it **cannot** be fixed by lighting, placement,
retexturing or rescaling because the silhouettes were never designed as a set. That is
the one visual problem where scene work genuinely cannot substitute, and the owner
judges it worth real attempts.

### What is still one round, and unchanged

Scene visuals: grass, ground, lighting, landmarks, skies, night, dressing, composition,
HUD. Run the blind judge **once to record a verdict, not to pass one**, exactly as
above. This carve-out does not reopen scene polish.

### Budget discipline still binds

Every rule in `docs/prompts/77-...md` lane ART-PILOT still applies: check
`meshy.py balance` and record it before spending; art-source order first; a code-blind
judge picks among candidates and never judges its own output; write the
`docs/specs/ASSET_LEDGER.md` row with credits before and after. Three rounds is a
ceiling, not a target — stop earlier if a subject passes.
