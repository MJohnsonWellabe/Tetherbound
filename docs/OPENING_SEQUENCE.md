# The first fifteen minutes

The sequence a new player actually plays, start to finish, from `GAME_DESIGN.md`
§3's story frame. This is the second staging of the opening: it now starts
**inside Grandpa's farmhouse**, not on the doorstep. The prose here and
`data/config/opening.json` are the same document in two languages and are meant
to be read together; `data/dialogue/opening.json` is every word spoken in it.

**The promise it has to land:** *this creature is yours, and it matters.* Nothing
else in the first fifteen minutes is more important than that, and every beat
below is either serving it or getting out of its way.

## The beats

| # | Beat | Minutes | What the player does | What it teaches |
|---|---|---|---|---|
| 1 | **Wake** | 0–1 | Fade in on a bed upstairs. Get up | Move, camera, one prompt |
| 2 | **Downstairs** | 1–2 | Walk down through the house to Grandpa | Interact; this is home |
| 3 | **The briefing** | 2–5 | He explains Team Tether, gives you his old pack — orbs, potions, berries — and the creature belt | Why there is a journey; the satchel; **the five-creature rule, said in fiction** |
| 4 | **The choice** | 5–7 | Three orbs on the table, each previewing its creature. Look them over, choose one | **The five-creature rule's first bite:** the other two stay with him |

**Beat 4 is no longer unconditional — `docs/decisions/D23`, spec §1D.** The
owner played the published build and walked straight out of the house, skipping
beat 3 entirely: no belt, no orbs, no potions, no reason for the journey. The
door is now gated on beat 3 being complete. `SA2` in `ralph/BACKLOG.md` is the
work, and §1D is specific about the form it takes: crossing is stopped, Grandpa
calls out — "Hold on. You're not walking out there empty-handed." — and the
briefing starts itself. **Not** a "Talk to Grandpa first" error toast. Once
beat 3 is done the gate lifts for good and never re-arms.
| 5 | **Your creature** | 7–9 | Name it. Walk with it following you | It is yours; it has a name you typed |
| 6 | **The encounter** | 9–11 | A wild Bramblebun is grazing down the path. Engage | Targeting; wild creatures are individuals, not spawns |
| 7 | **The fight** | 11–13 | Pilot your creature. Quick attack, energy, charged attack | Combat is piloted (D07), not commanded |
| 8 | **The catch** | 13–15 | Throw an orb at the weakened Bramblebun. Catch it | The catch is a physical act you aim |
| 9 | **The road** | 15 | Grandpa points down the dirt road: follow it, gather from it, make camp before dark | The world is open, and the first day has a shape |

The state machine underneath has eight states — `wake`, `house`, `choose`,
`name`, `walk_out`, `encounter`, `road`, `free_play` — the key order of
`beats.grandpa_conversations` in `data/config/opening.json`, read by
`scripts/story/opening_beats.gd`. Beats 2–3 share the `house` state (coming
downstairs and talking to him are one room), and 7–8 share `encounter` (the
fight and the catch both live inside CombatManager).

## The staging, beat by beat

**Wake.** Fade in from black (`fade` block; the duration is tunable) on the
player in a bed upstairs. The bed's "Get up" prompt is the only interactable in
the world. Grandpa is downstairs and has nothing to say through a floor — the
`wake` state maps to no conversation, so his prompt stays quiet until the
player is in the room with him.

**Downstairs, and the briefing.** One conversation, `grandpa_house`, carries the
whole of it: the warm greeting, Team Tether — returned, holding the eight
places of power, creatures chained to the stones — why he cannot go himself, and
then the gifts. The gifts are not a cutscene grant: each `give:` effect sits on
the exact line that speaks it (`give:orb_basic:15`, `give:potion_small:3`,
`give:berries:5`), so the satchel fills as he says the words. The creature belt
line is where the five-creature cap is said in fiction — *it holds five, no more; a
rule older than Team Tether* — which is the only kind of place a rule that hard
should be said. His last line sends the player out the door and emits
`beat:starter_choice`.

**The choice.** **Reversed 2026-08-11 (`SA0-orbs`, owner directive)** — the
paragraph this replaces had the three starters waiting outside in a row; see
"Decisions taken here" below for the record of the change. The moment
Grandpa's briefing ends, `starter_picker.gd` opens over the same room: three
orbs, each a live view of the creature inside it, still indoors. Look left and
right between them; choosing one closes the picker and opens the naming
prompt straight away. The other two are simply never previewed again — there
are no bodies left standing anywhere for the cost of the choice to be seen in,
which is the trade this reversal makes (see below). `grandpa_waiting` — his one
line if spoken to again mid-choice — is left in the dialogue table but is not
practically reachable any more: the picker is modal and opens automatically,
with no window a player can act inside before it does.

**Your creature.** Naming is mandatory. The moment the name is confirmed the
director runs `grandpa_named` with `$name` substituted — the first time in this
game a line says a word the player wrote — and he points down the path at the
practice bramblebun (`beat:first_encounter`).

**The encounter, the fight, the catch.** As before: the bramblebun is peaceful,
grazing past the rise, and has the highest catch rate in `species.json` so the
tutorial catch cannot fail twice. Talking to Grandpa in this stretch gets the
one-line reminder (`grandpa_encounter_hint`), never the briefing again.

**The road.** After the catch, `grandpa_road` closes the scripted sequence with
the first-day arc in three sentences: follow the dirt road out, gather what the
verges offer, and **make camp before dark**. That last instruction is the
handoff to the gathering/build/rest loop (`GAME_DESIGN.md` §29, steps 4–9). His
final line emits `beat:free_play` and nothing after it is scripted — his prompt
goes quiet rather than repeating the send-off forever.

## Where things stand

The systems the first staging was waiting on have all landed and are in the
scene: `sequence_director.gd` is instanced in `meadows_playground.tscn` and
owns the beat list; `dialogue_runner.gd`, `dialogue_panel.tscn`,
`name_prompt.tscn`, the interaction arbiter, Grandpa's `npc_body.gd`, the
follower, and the party behind `party_seam.gd` are all reachable in play.

What the restaging adds, and who owns it:

1. **The farmhouse interior** — bed upstairs, stairs, Grandpa's spot
   downstairs, the door. The `bed.position` and `grandpa.indoor_position`
   values in `data/config/opening.json` are **placeholders**; the house builder
   finalizes them against the real floor plan, and nothing should be tuned
   against them until then.
2. **The bed interactable, indoor spawn, and door staging** — sequence-director
   work, owned by the owner alongside `smoke_opening.gd`.
3. **The dialogue and beat data** — done, this round. `grandpa_house` replaced
   `grandpa_intro`; the `approach` beat is gone (there is no walk across the
   meadow to him any more) and `wake`/`house` are new.
4. **The gift items** — `orb_basic` and `potion_small` exist in
   `data/items/items.json` so the `give:` effects name real items.

## Decisions taken here, so they are not re-litigated later

- **The opening has an interior — reversing the earlier "no interior" call.**
  The first staging started outside the door with a fade-in, recorded here as
  saving "an entire interior art pass for a beat that lasts forty seconds."
  Both the facts under that decision changed: the owner asked for the wake-up
  in the house, and the house asset pack landed, so the art pass it was
  avoiding no longer has to be paid. The old decision was right when it was
  made and is wrong now; this is the reversal, recorded rather than silently
  edited.
- **REVERSED 2026-08-11 (`SA0-orbs`, owner directive) — the starter choice
  used to be physical, not a menu.** This bullet used to say: "You walk to the
  one you want. It is the first expression of the game's whole posture toward
  its creatures, and a list box would undo it." The owner asked for the
  opposite outright: *"the starters should be in orbs and you preview them
  while talking to Grandpa."* The old reasoning was right for the staging it
  was written for and is superseded now, not silently dropped — the choice is
  still made by looking each one over rather than reading a list of names,
  which is as much of the original posture as an in-conversation picker can
  keep. `data/config/opening.json`'s own `starters` block carries the same
  note.
- **The gifts are lines, not a cutscene grant.** Each `give:` effect rides the
  line that speaks it. If the pacing of the briefing changes, the gifts move
  with their sentences and never fall out of sync with the prose.
- **The five-creature cap is spoken as fiction, once, by the belt.** CLAUDE.md's
  hard rule enters the player's head as a rule of the world, not a tooltip.
  `grandpa_named` gets one short reprise ("that's the belt") and no other line
  restates it.
- **The first wild creature is Bramblebun and it is peaceful.** `species.json` gives
  it the highest catch rate in the game for exactly this reason: the tutorial
  catch must not fail twice.
- **Naming is mandatory, not skippable.** A creature you did not name is a creature you
  did not adopt.
- **The other two starters stay visible with Grandpa afterwards.** The cost of
  the choice should remain standing in the world where the player can see it.
- **Grandpa ends the sequence pointing at the first night, not just at the
  horizon.** "Make camp before dark" gives free play a first goal without
  scripting it; the ridge line of the old draft opened the world but left the
  first hour shapeless.

## The bar

The same one as everything else in this project: not that the beats execute,
but that the owner reaches minute fifteen and wants minute sixteen.
