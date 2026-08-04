# D14 — One save envelope, domains as contributors

**Status:** accepted
**Decided by:** implementation, during M4

## The decision

`autoload/save_manager.gd` is the only thing in the game that writes a save
file. One file per slot (`user://save_%d.json`), one `SAVE_VERSION` for the
whole envelope, and systems **register a domain** into it:

```gdscript
SaveManager.register("party", self)   # needs save_data() and load_data()
```

Adding persistence to a new system is a `register()` call and two methods on
the system itself. Never a new file, never a new version number.

## What it replaced

`structures.gd` got there first and owned `user://structures.json` outright: its
own path, its own version constant, its own parse, its own refusal logic.

That shape works exactly once. The second system that needs persistence copies
it, and then a player's world is several files that can silently disagree about
which build wrote them — a party from this build sitting beside structures from
the last one, with nothing in either file able to notice.
`TECHNICAL_START.md` §Save Requirements lists fourteen things to persist.
Fourteen files with fourteen version numbers is not a save system.

`structures.gd` became the first contributor rather than staying special.

## One version number, deliberately

Per-domain versions were considered and rejected. They would let a save file be
*partly* current — a v2 party beside a v1 inventory — which is the exact state
nobody can reason about and no bug report can describe. One number means an old
file is refused whole rather than half-read.

The cost is real: bumping the version for a change in one domain invalidates
saves for all of them. During a vertical slice that is the right trade.

## JSON, not `Resource`/`ResourceSaver`

A save has to survive a script being renamed or a class disappearing. A binary
resource that names its own script cannot. JSON is greppable, diffable and
hand-editable while the slice is being tuned, which matters more right now than
a few kilobytes.

## `user://`, never `res://`

Runtime state does not go near the project directory. On Windows `res://` is
inside the installed game and is read-only for a normal user; a build that
writes its save beside its executable works perfectly on the developer's
machine and fails on the first real install.

## Contributors re-register at the point of use

`register()` is idempotent, and callers re-register defensively. This is not
belt-and-braces, it is required:

Under `--script` — which is how **every** test, smoke and evidence session in
this project runs — Godot attaches autoloads to the tree only after the entry
script's `_init()` returns. A harness that builds its world inside `_init()`
reaches `_ready()` on its nodes before `/root/SaveManager` exists. A contributor
that registered only in `_ready()` would be quietly absent from its own save
file, and every headless run would test a save that was missing a domain while
the real game saved it fine.

Re-registering when the manager is next needed is cheaper than ordering the
boot. `structures.gd` hit this first; `party_manager.gd` has the comment
explaining it so the third system does not have to rediscover it.
