# DECISIONS

Choices made during the build that were not already settled by the spec docs.
Per `CLAUDE.md`: when a design decision is ambiguous and both options are
reasonable, pick one, write it down, keep moving. Conflicts with the spec docs
are flagged rather than resolved silently, because the docs win.

**One decision, one file, in `docs/decisions/`.**

```
docs/decisions/D01-renderer-is-babylon-not-three.md
docs/decisions/D26-input-layers-own-separate-vectors.md
```

There is deliberately no index in this file. Sessions can run concurrently, and
an index is a single line every one of them appends to. That is the merge
conflict the split was meant to remove, relocated. Generate it instead:

```
npm run decisions            # the whole list, oldest first
npm run decisions -- --next  # the next free number
```

That command also fails if two files claim the same number, which is the quiet
way concurrent sessions break the log.

## Writing a new one

Take a number nobody else holds. When two sessions are running, take it from
the range assigned to your stream rather than from `--next`, because `--next`
cannot see a branch it is not on.

```markdown
# D27. Short imperative title

Kind: implementation

What was chosen, and the reason it was not the other thing. Name the file,
measurement or bug that decided it.
```

`Kind` is `spec-conflict` when the decision overrides something a spec document
says, and `implementation` otherwise. A `spec-conflict` entry must name the
document it contradicts.

Entries are written once and left alone. A decision that turns out wrong gets a
new entry that supersedes it and says so; editing history to look correct
destroys the only record of why the wrong turn was taken.
