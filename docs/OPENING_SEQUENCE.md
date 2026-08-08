# The first fifteen minutes

The sequence a new player actually plays, start to finish, from `GAME_DESIGN.md`
§3's story frame. Written before it is built so the beats can be argued with
cheaply.

**The promise it has to land:** *this creature is yours, and it matters.* Nothing
else in the first fifteen minutes is more important than that, and every beat
below is either serving it or getting out of its way.

## The beats

| # | Beat | Minutes | What the player does | What it teaches |
|---|---|---|---|---|
| 1 | **Wake** | 0–1 | Stand up, walk out of Grandpa's house | Move, camera |
| 2 | **The meadow** | 1–3 | Walk to Grandpa across open ground | Sprint, jump, stamina; the world is worth looking at |
| 3 | **Grandpa** | 3–5 | Talk. He explains Team Tether, and that he is too old to go | Interact; why there is a journey |
| 4 | **The choice** | 5–7 | Three pals are present. Approach each, then choose one | **The five-pal rule's first bite:** the other two stay with him |
| 5 | **Your pal** | 7–9 | Name it. Walk with it following you | It is yours; it has a name you typed |
| 6 | **The encounter** | 9–11 | A wild Bramblebun is grazing. Engage | Targeting; wild pals are individuals, not spawns |
| 7 | **The fight** | 11–13 | Pilot your pal. Quick attack, energy, charged attack | Combat is piloted (D07), not commanded |
| 8 | **The catch** | 13–15 | Throw an orb at the weakened Bramblebun. Catch it | The catch is a physical act you aim |
| 9 | **The road** | 15 | Grandpa points at the far ridge. Free play | The world is open now |

## What already exists

A good deal, but less than an earlier draft of this file claimed. The slice has
been built out of order — systems first, sequence never — so some of this is
**wiring**, and some of it is genuinely new:

- Movement, camera, sprint, jump, stamina, fall damage — `player_controller.gd`
- Terrain, vegetation, sky, time of day — `playground_world.gd`, `world_look.gd`
- Wild pals that roam, notice you, and can be aggressive — `wild_pal.gd`,
  `encounter_director.gd`
- Piloted combat with quick/charged attacks and energy — `combat_manager.gd`
- Aimed orb throwing and the catch formula — `throw_aim.gd`, `catch_math.gd`
- Three real starters, at peer scale, with six clips each — `species.json`
- Grandpa's model and its art config — `assets/characters/grandpa/`, the
  `grandpa` block in `data/config/art.json`
- A party that holds five, and a nickname — `autoload/party.gd` with
  `MAX_PALS := 5`, owned by the `Game` autoload as `Game.party`, and
  `nickname` on `pal_instance.gd` with a `display()` that prefers it
- A pal that follows you — `follower_pal.gd`, spawned by `encounter_director.gd`

**None of the rest of it is in a scene.** `interactable.gd`,
`interaction_arbiter.gd`, `npc_body.gd`, `dialogue_runner.gd` with
`dialogue_panel.tscn`, and `name_prompt.tscn` are all written and unit-tested
and all unreachable: `scenes/world/meadows_playground.tscn` is still the combat
sandbox, with no Grandpa, no arbiter node, no panel and no prompt in it. The
nearest-wins rule itself (`prompt_arbiter.gd`) does run, inside
`encounter_director.gd`, but nothing except a wild pal ever offers it a
candidate. The starter choice is not written in any form; `encounter_director`
exposes `suspend_default_starter()` and `adopt_starter()` for it and nobody
calls either. A sequence director is being written now — see item 7 below.

### Correction, twice over: what this file has claimed about the party

An early draft listed "a party that holds five and forces a release at six — the
M4/M5 work" as existing when there was no party manager at all. A later
correction said flatly that **the party does not exist**. That correction is now
itself out of date: `autoload/party.gd` and `nickname` both landed, and they are
listed above.

Both are recorded rather than quietly deleted, because both were load-bearing.
The first is the reason this document once described the opening as "mostly
wiring". The second is the reason the seam below was built to work without a
party at all — a defensive design that is now the thing standing between the
opening and the party it was waiting for.

## What is missing, in build order

Items 1–3 and 5–6 have since been **written**. Only 6 is in a scene. The rest
are files that pass their unit tests and that no player can reach, which is a
different state from missing and should not be mistaken for done. The original
descriptions are kept because they are the specification, with the current
status marked.

1. **A conversation system.** *Written — `scripts/story/dialogue_runner.gd`,
   `scenes/ui/dialogue_panel.tscn`; instanced nowhere.* A panel, a portrait, a
   name, a line, advance on the interact button. No branching, no choices in
   text — the only choice in this sequence is which pal, and that is made by
   walking up to one.
2. **An interactable component, and arbitration between prompts.** *Half wired.*
   The comparison is real and running: `scripts/world/prompt_arbiter.gd` decides
   nearest-wins inside `encounter_director.gd`. What is not in any scene is
   `interaction_arbiter.gd`, the node that collects `Interactable`s and asks
   them what they are offering — so there is still exactly one prompt in the
   game and it still says "Engage X". Grandpa, three starters and every later
   resource node all want that same line.
3. **Grandpa as an NPC.** *Written — `scripts/npc/npc_body.gd`; no instance of
   him exists.* A body that stands where it is put, faces the player, and offers
   an interact prompt. He never moves in this sequence.
4. **A starter-choice interaction.** *Not written.* Three pals standing near
   him; approaching one offers "Choose <name>"; choosing gives it to the party
   and leaves the other two standing where they are. `encounter_director` has
   the seams waiting — `suspend_default_starter()` and `adopt_starter()` — and
   nothing calls them, so the playground still hands you Terrapup by fiat.
5. **A naming prompt.** *Written — `scenes/ui/name_prompt.tscn`; instanced
   nowhere.* One text field. `GAME_DESIGN.md` §2 lists naming first among the
   things that make the five matter. It is also the project's first text input,
   which makes it the first time mouse capture is released and the first time a
   handheld has to type without a keyboard — both of those are part of the work,
   not details of it.
6. **A follower.** *Done, and in the scene.* `follower_pal.gd`, spawned by
   `encounter_director.gd`, visible and walking behind the trainer through
   `pal_body.request_move()`. It used to be instanced with `visible = false` and
   to exist only during a fight.
7. **A sequence director.** *Being written now.* One node that owns the beat
   list, gates what is possible at each beat, and advances. Everything above is
   inert without it, which is the whole of why beats 1–6 are unreachable rather
   than unbuilt.
8. **A home scene.** *Not written.* Grandpa's house does not need an interior —
   beat 1 can start outside the door with a fade-in. That saves an entire
   interior art pass for a beat that lasts forty seconds.

## Depends on

The opening does **not** own the party. Where it needs one it calls through a
narrow seam, `scripts/story/party_seam.gd`, so that the join is one file.

**The seam does not currently reach the party, and this file used to say it
did.** It was written against a party that had not been built yet and it guessed
at both the name and the shape:

- it looks up `/root/GameState`; the autoload is registered as **`Game`**
- it expects `add_pal(instance)`, `party()` and `party_is_full()`; the real API
  is `Game.party.add(pal)`, `Game.party.members()` and `Game.party.is_full()`

Every lookup misses, so the seam silently falls through to `_fallback`, the
local array it keeps for the case where no party exists. The opening would play
end to end and the chosen pal would never enter the party the rest of the game
reads. That is exactly the failure a duck-typed seam is bad at showing you: it
degrades quietly instead of erroring.

The nickname half did land — `pal_instance.gd` has the field, and the seam's
`"nickname" in instance` check finds it.

The seam is being repaired in code in this same round of work. When it is, the
fallbacks should go and `_state()` should stop being optional, per the file's
own TODO. Nothing else in the opening changes: every call site goes through it.

## Decisions taken here, so they are not re-litigated later

- **No interior.** Beat 1 starts outdoors. Revisit only if the fade-in reads
  as cheap in playtest.
- **The starter choice is physical, not a menu.** You walk to the one you want.
  It is the first expression of the game's whole posture toward its creatures,
  and a list box would undo it.
- **The first wild pal is Bramblebun and it is peaceful.** `species.json` gives
  it the highest catch rate in the game for exactly this reason: the tutorial
  catch must not fail twice.
- **Naming is mandatory, not skippable.** A pal you did not name is a pal you
  did not adopt.
- **The other two starters stay visible with Grandpa afterwards.** The cost of
  the choice should remain standing in the world where the player can see it.

## The bar

The same one as everything else in this project: not that the beats execute,
but that the owner reaches minute fifteen and wants minute sixteen.
