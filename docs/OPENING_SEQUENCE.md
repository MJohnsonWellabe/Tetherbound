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

Most of it. The slice has been built out of order — systems first, sequence
never — so this is mostly **wiring**, not new systems:

- Movement, camera, sprint, jump, stamina, fall damage — `player_controller.gd`
- Terrain, vegetation, sky, time of day — `playground_world.gd`, `world_look.gd`
- Wild pals that roam, notice you, and can be aggressive — `wild_pal.gd`,
  `encounter_director.gd`
- Piloted combat with quick/charged attacks and energy — `combat_manager.gd`
- Aimed orb throwing and the catch formula — `throw_aim.gd`, `catch_math.gd`
- A party that holds five and forces a release at six — the M4/M5 work
- Three real starters, at peer scale, with six clips each

## What is missing, in build order

1. **A conversation system.** There is no dialogue anywhere in the project. The
   smallest thing that works: a panel, a portrait, a name, a line, advance on
   the interact button. No branching, no choices in text — the only choice in
   this sequence is which pal, and that is made by walking up to one.
2. **Grandpa as an NPC.** A body that stands where it is put, faces the player,
   and offers an interact prompt. He never moves in this sequence.
3. **A starter-choice interaction.** Three pals standing near him; approaching
   one offers "Choose <name>"; choosing gives it to the party and despawns the
   other two.
4. **A naming prompt.** One text field. `GAME_DESIGN.md` §2 lists naming first
   among the things that make the five matter, and it has never been built.
5. **A sequence director.** One node that owns the beat list, gates what is
   possible at each beat, and advances. Everything above is inert without it.
6. **A home scene.** Grandpa's house does not need an interior — beat 1 can
   start outside the door with a fade-in. That saves an entire interior art
   pass for a beat that lasts forty seconds.

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
