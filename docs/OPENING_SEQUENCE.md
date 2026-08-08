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

### Correction: the party does not exist

This section previously listed "a party that holds five and forces a release at
six — the M4/M5 work" as **existing**. It does not, and did not when that line
was written. As of this correction there is no party manager, no five-pal limit
enforced anywhere, and `pal_instance.gd` has no `nickname` field. The nearest
thing is `encounter_director._caught`, a flat array whose own comment says it is
a milestone-local record that M4 replaces.

Recorded rather than quietly deleted, because the line was load-bearing: it is
the reason this document described the opening as "mostly wiring", and anything
planned against it was planned against a system that was not there. The party
and the nickname are being built in parallel (see **Depends on**, below); the
opening sequence codes against them and does not implement them.

## What is missing, in build order

1. **A conversation system.** There is no dialogue anywhere in the project. The
   smallest thing that works: a panel, a portrait, a name, a line, advance on
   the interact button. No branching, no choices in text — the only choice in
   this sequence is which pal, and that is made by walking up to one.
2. **An interactable component, and arbitration between prompts.** There is
   exactly one interact prompt in the whole game today, hardcoded inside
   `encounter_director._update_prompt()`, and it says "Engage X". Grandpa, three
   starters and every later resource node all want that same line, so somebody
   has to decide which one gets it. Nearest wins. Everything below depends on
   this existing first.
3. **Grandpa as an NPC.** A body that stands where it is put, faces the player,
   and offers an interact prompt. He never moves in this sequence.
4. **A starter-choice interaction.** Three pals standing near him; approaching
   one offers "Choose <name>"; choosing gives it to the party and leaves the
   other two standing where they are.
5. **A naming prompt.** One text field. `GAME_DESIGN.md` §2 lists naming first
   among the things that make the five matter, and it has never been built. It
   is also the project's first text input, which makes it the first time mouse
   capture is released and the first time a handheld has to type without a
   keyboard — both of those are part of the work, not details of it.
6. **A follower.** The player's pal is instanced today with `visible = false`
   and only exists during a fight. It has to be visible and walking behind the
   trainer, driven through `pal_body.request_move()`.
7. **A sequence director.** One node that owns the beat list, gates what is
   possible at each beat, and advances. Everything above is inert without it.
8. **A home scene.** Grandpa's house does not need an interior — beat 1 can
   start outside the door with a fade-in. That saves an entire interior art
   pass for a beat that lasts forty seconds.

## Depends on

The opening does **not** own the party. It codes against a `GameState` autoload
holding a party of at most five, and against a `nickname` on `pal_instance.gd`.
Both are being built alongside this. Where the sequence needs them it calls
through a narrow seam (`scripts/story/party_seam.gd`) which uses `GameState`
when it is present and keeps the chosen pal locally when it is not, so the
opening plays either way and the join is one file.

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
