# OWNER DIRECTIVES — 2026-08-22

Binding owner decisions given live during the weekend sprint. These sit at
precedence level 1 (explicit newer owner directives) per `CLAUDE.md`. They
supersede older repo prose where they conflict.

## 1. Controller mapping — no held buttons, ever

> "don't make a user hold a button down for any action. if that's not possible
> ask what to get rid of as an action. you should be using every button before
> going to hold down as a choice though."

Hold-to-modify chords are **banned** as a mapping solution. If a verb will not
fit, the answer is to remove or merge a verb and ask the owner — never a
modifier chord. The hold-LB hotbar chord shipped by DPAD-COLLISION is
therefore **reverted** by this directive.

Two verbs move off the button map and become hotbar tools/items instead:

- **Torch** is a tool that lives in the bar ("torch doesn't need a button").
- **Build hammer** is the same pattern: select it, press interact, you are in
  build mode. `build_open` loses its button.
- **Catching** is an orb selected on the bar and thrown with interact.

### The authored map

| Input | Verb |
|---|---|
| Left stick / L3 | move / sprint |
| Right stick / R3 | camera / recentre |
| A | jump |
| X | interact — talk, gather, chop, mine, mount, throw the selected orb, place while building |
| Y | inventory |
| B | hotbar 1 |
| D-pad ← ↑ → ↓ | hotbar 2–5 |
| LB | cycle party member |
| RB | call out / put away your creature |
| LT / RT | creature charged attack / quick attack |
| View | map |
| Menu | game menu |

Build mode: X place, B exit, LT/RT rotate, D-pad up/down snap and piece cycle,
LB/RB catalogue category, Y dismantle.
Map: LT/RT zoom, stick pans. Menus: A confirm, B back, LB/RB tab.

Consequences that are deliberate, not oversights:

- **Fleeing is RB.** Putting the creature away IS disengaging; flee gets no
  button of its own.
- **"Cycle party" and "switch the creature you are piloting" are one verb on
  LB.** This is what retires the d-pad collision: the d-pad is hotbar 2–5 in
  every context including combat, so food and orbs stay reachable mid-fight.
- **LT/RT idle while no creature is out.** Accepted rather than papered over
  with an invented verb.

## 2. The village tournament

- **Eight-slot bracket, three fought rounds.** The other four slots are named
  opponents whose results are simulated on the board between the player's own
  matches. No new humanoid meshes: the fought rounds use Band 1's existing
  trainers.
- **The tournament happens BEFORE Oskar.** It is not his fight.
- **The South Bridge gatekeeper becomes a Team Tether grunt** (existing rig),
  freeing Oskar to be a tournament round.
- **Winning grants the saddle recipe**, and an NPC line tells the player the
  mount species can be ridden.
- **The final opponent rides a Meadowhart.** Owner's own suggestion was
  Burrowback; Meadowhart was recommended and accepted because it is already
  the authored, tuned first mount whose `rideable` block already reads
  `requires_item: saddle`, so the reward points at the creature just fought
  and costs no new data. Burrowback stays non-rideable.
- **You can lose and retry after healing your creatures.** Not no-fail.

### Sequencing note, accepted by the owner

The saddle recipe is Rootstone-tier and Rootstone only appears in the Burrow
Warrens and the Old Quarry, both past the South Bridge. The reward is
therefore a **promise, not a purchase** — the player holds the recipe for a
region before they can build it. This is intended: it is the reason to want
rootstone.

## 3. Map fog

The map is not broken; it is fog-of-war with zero starting reveal, so a fresh
save opens a black rectangle. Owner accepted the recommendation:

- **The village and the roads out of it start revealed.**
- **Named landmarks show as icons through the fog** once an NPC has told the
  player about them.

Walking still uncovers the world. The player does not start blind in their own
home town. This supersedes the "reveal nothing at the start" reading of OW3.

## 4. Player-built roofs

> "the roof doesn't need a continuous edge. it just needs to look like the
> buildings in the game when you build it as a user."

`ralph/BLOCKED.md`'s modular-roof-ridge entry is **unblocked**. No new art. The
acceptance is that a player-built roof reads like the village houses' roofs;
a continuous ridge line is explicitly not required.

## 5. Verification

- **No ROG Ally is available to this environment.** The owner accepted a
  synthetic joypad harness that drives the whole chapter through real
  `InputEventJoypadButton` events. It is also the proof that the mapping in
  section 1 has no collisions.
- Blind visual review stays Fable-only and must never judge evidence it
  produced.

## 6. Gate order

Finish Gate A, then B, then C, each fully verified and tested, before D
starts. **The five D regions may then run concurrently with each other.**
