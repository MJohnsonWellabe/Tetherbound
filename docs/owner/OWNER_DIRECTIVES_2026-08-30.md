# Owner directives — 2026-08-30

Recorded by the coordinator as they were given, so they survive session
turnover. Under CLAUDE.md's precedence these are explicit newer owner
directives and outrank every other document in this repo for what they cover.

---

## D-0830-1 — Roll new worlds must be turned on

> "make sure someone flips roll new world on at some point."

**The flag.** `data/config/spawn_tables.json` → `"roll_new_worlds": false`,
shipped by `ralph/T3-ENCOUNTER`. It decides whether a NEW GAME rolls itself a
world seed instead of taking seed 0. Seed 0 is the authored world: every rolled
cluster resolves to the species it already names, so seed 0 reproduces the
pre-rolled world byte-for-byte.

**Why it shipped off, and why that was right.** T3-ENCOUNTER's own note: a
global determinism switch flipped on the day nine branches land, with a Gate F
run in flight and no time to re-baseline the protocol, is the version that does
not land. Everything behind the flag is built, tested, and playable today via
`TB_WORLD_SEED` in the environment.

**The obligation this file creates.** The flag is not a deferred maybe. It is
owner-directed work with one precondition:

- **Precondition:** Gate F has a re-baselined protocol that accounts for a
  rolled population — the four T2 lanes in flight on 2026-08-30 must land and
  the affected segments must be re-run first. Flipping it underneath a live
  Gate F run invalidates that run's evidence.
- **Owner:** whoever picks up the first content lane after Gate F re-baselines.
  Not T2. Not a lane that is mid-run.
- **Definition of done:** `roll_new_worlds: true`, a new game observably rolls
  a non-zero seed, an existing save still loads at its stored seed, the Gate F
  segments pass against the rolled world, and `_comment_roll_new_worlds` is
  rewritten to describe the shipped state rather than the deferral.

Do not close this item by arguing the flag is fine where it is. The owner asked
for it on.

---

## D-0830-2 — Install everything that has been built

> "also install everything we've done so far. if we built it, turn it on, put
> it on the game, make it playable."

This is a standing instruction, not a one-off task. The repo has repeatedly
accumulated systems that exist in code and data but are unreachable in play —
a mesh generated but not wired to a species, a feature behind a flag that was
never flipped, content authored into a config that nothing reads. That is the
failure mode this directive closes.

**The rule:** built is not done. A thing is done when a player can reach it in
a normal playthrough.

**Applies at minimum to:**

- The five new creature meshes (Sparkit, Shadelet, Frostclaw, Cindercub,
  Bramblebun redesign), now committed under
  `assets/creatures/tetherbound/<name>/models/` — imported, wired to their
  species entries, standing up in the world.
- The four variant creatures (Nightburrow, Stormtrail, Riftfrill, Ashtusk),
  which need no new mesh — material/scale/VFX variants of meshes already
  installed, plus their encounter placement.
- The refined NPC cast from `ralph/T1-NPC-CAST` — committed, imported, and
  actually standing in the world rather than sitting in a lane's container.
- `roll_new_worlds`, per D-0830-1 above.
- Any other flag, config block, or asset a lane built and left dark. Sweep for
  them; do not wait to be told which.

**Evidence standard:** a rendered frame or a play-path observation showing the
thing in the game. A passing test that the data parses is not evidence that a
player can reach it.
