# D17 — Items, tools, and buildings that do something

**Status:** accepted
**Decided by:** implementation, during the M8/M9 foundations
**Builds on:** `D12-the-build-grid-is-measured-from-the-kit.md`

Three decisions that will each look arbitrary in six months and are each load-
bearing.

## 1. There is no weight, and it is enforced by a test

`CLAUDE.md` says slot/stack inventory, no carry-weight system. `GAME_DESIGN.md`
§19 repeats it. The inventory has no weight field, no mass, no bulk.

That much is just obedience. The part worth recording is that a **test** asserts
none of the eleven refusal tokens contains `weight`, `heavy`, `mass`, `bulk`,
`encumb` or `overload`.

The reason is that a banned system does not come back under its own name. It
comes back as "too bulky to carry", or as a slot count that shrinks when you
pick up a rock. Prose in a design document cannot notice that; a test can.

## 2. Tools do not stack, and a broken tool is not destroyed

**Not stacking** is enforced in code, not data: `item_defs.stack_limit()` forces
the limit to 1 for anything with durability, whatever the JSON says.

A stack of five axes has one durability between them, and there is no honest
answer to which axe the 40% belongs to. The general alternative — an array of
durabilities per stack — makes every split, merge and repair take a which-one
argument that no UI has anywhere to put. The specific case is not worth the
general machinery.

**At zero durability a tool is broken, not gone.** It keeps its slot, refuses to
be used, and repairs free.

§19 promises free repair. A tool that deletes itself at zero puts that promise
out of reach precisely when it is needed, and with no weight limit there is no
cost to keeping the worn one — so destroying it is pure punishment with no
system behind it. "Your axe is broken, go and repair it" is a errand. "Your axe
is gone, go and make another" is the same errand plus a loss.

## 3. A build piece may carry behaviour, and a pal bed holds one pal

`pieces.json` deliberately excluded bed, pal bed, campfire, workbench, storage
and berry plot, with a comment: *each is a station with behaviour, not a piece of
geometry.* That comment was right, and it was also a hole — six of the twelve
categories M8 asks for were unreachable.

The hook: a piece definition may carry a `station` block; `structures.place()`
attaches a node for it. **Save state is a per-station opt-in** — a wall's record
is byte-for-byte what it was before, and a test asserts that. Twenty-eight
existing pieces did not change.

### The pal bed holds one pal

In data, so reversing it is a JSON edit. Five pals therefore need five beds.

The alternative — one bed with a queue — was rejected for a reason that is not
about beds. A shared facility with throughput is the first step toward pals
having *jobs*, and "pals do not perform base jobs" is a hard rule. A bed that
several pals take turns at is a bed with a work schedule.

An overflow is a **refusal token**, not a wait list, so recovery can tell the
player to build another bed. And a base that visibly grows a bed per pal is the
cheapest legible reward building has: the five-pal party becomes something you
can see from across the camp.

### The rule is a test, not a comment

`test_no_station_can_be_told_to_work` fails if any station ever grows an
`assign`, `work` or `produce` method.

"Pals do not perform base jobs" is easy to keep while buildings are inert and
easy to break the moment they have behaviour — not by deciding to break it, but
by adding one convenient method to a bed. The rule now has something watching it
that does not rely on anyone remembering it.

A bed is somewhere a pal rests: `begin_rest()` is called *into* the station and
the station never reaches out.

## What is deliberately still missing

**Build costs.** There is no inventory hookup and no `cost` key on any piece —
and a test fails if one appears before the system that would spend it exists.
The seam is documented in both files: costs go on the piece beside `model`, the
refusal goes in `build_mode._check()` beside "too far away".

**Workbench, storage, berry plot.** Named as TODOs with what each waits on —
crafting recipes, an inventory container, plant/grow/harvest. Not stubbed in. A
station that places and does nothing is the exact pattern this project keeps
getting caught by: the traits system that loaded and tested while nothing called
it, the save system that worked perfectly and was never invoked, the XP curve
that no fight ever awarded. An empty station would have been the fourth.
