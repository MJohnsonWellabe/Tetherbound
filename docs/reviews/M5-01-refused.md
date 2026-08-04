# M5 — Release ceremony: REFUSED (round 1)

Judged blind by `.claude/skills/systems-judge` against the acceptance bullets in
`docs/MEADOWS_VERTICAL_SLICE.md`. The reviewer saw the transcript
(`shots/session_release.log`) and eleven rendered frames, and nothing else — no
source, no commits, no description of what was built.

Recorded here pass or fail, per D15. This one is a refusal, and it found
something four passing test suites, eight smokes and the author did not.

## Verdict table, in the judge's words

| Bullet | Verdict | Evidence |
|---|---|---|
| Capture while full | MET | L102 `caught=true after 3 shakes` with `party size before the catch: 5`; L103 director reports `token='party_full'` |
| Present six | MET | L161 `distinct known pals named on screen: 6 of 6`; frames 01–07 show six cards, newcomer tagged `just caught — not yours yet` |
| Inspect meaningful info | **NOT SHOWN** | Frame 02 shows Thistle as `Gentle 130/130`; L214 dumps the same panel as `Keen 118/118` — the two evidence sources contradict each other for 3 of 6 pals |
| Keep one / release one | MET | L423 releases the owned `Thistle`, not the newcomer; L602 party becomes `Bracken, Sorrel, Clover, Nettle, Meadow Hopper`; L614 object identity holds |
| Released pal leaves permanently | MET | L713 `occurrences of 'Thistle' in the file on disk: 0`; L723–728 memory cleared to 0, reloaded to 5, `'Thistle' came back from disk: false` |

> **REFUSED** — 1 bullet is not met or not shown, listed above.

## The finding

On "inspect meaningful info" the judge would not choose between two readings,
because choosing would have required opening the source:

> 1. **The nine ceremony PNGs are leftovers from an earlier run**, in which case
>    the transcript's nine `frame '…' -> res://shots/…png` lines are false, and
>    there is *no rendered evidence at all* for this run's inspection panel.
> 2. **The frames are current and the ReleaseScreen renders values that disagree
>    with the party records it is supposedly displaying.** Then the panel shows
>    the player the wrong trait and the wrong HP for three of the six pals they
>    are being asked to choose between.
>
> Reading 1 removes the evidence; reading 2 destroys the bullet. Neither supports
> MET.

**Reading 1 was correct, and the cause was worse than a stale directory.**

Two sessions were running at once, both writing `session_release_*.png`. A run
that appeared to have died when its output stopped was still going when a second
was launched over the top of it. The frames on disk were a **mixture of two
games** — which is why some pals matched the transcript and some did not.

The proof was a timestamp nobody had thought to look at: **frame 10 was written
eight seconds before frame 09.** No single sequential process can do that.
Everything else about the set looked healthy — eleven frames, correctly
numbered, plausible creatures, right-looking screens.

## Why this matters more than the bullet it failed

The gate is built on the premise that evidence emitted by the running game is
testimony rather than the author's account. That premise silently assumed the
evidence all came from *one* run. Nothing checked it, and the failure mode is
invisible by construction: the pictures look fine, they are simply of a
different game.

A blind reviewer holding only artefacts found it. The author, who knew what the
system did and could see nothing wrong with the screens, did not.

## Other findings, all accepted

Independent of the contamination, and all of them the evidence being weaker than
it read:

1. **Only four of six pals were ever inspected.** "Inspect meaningful info" is a
   claim about all six.
2. **No independent read of selection anywhere.** Every statement about what was
   selected came from the hint line the screen itself renders — *"[A] Say goodbye
   to Thistle"*. The screen agreeing with itself.
3. **The throw counters could not be trusted.** `throws made: 11`, `resolved: 9`,
   then 19 misses listed: session-wide totals printed under a per-fight heading.
   As the judge put it — *"Any number in this transcript that is not
   independently cross-checked should be distrusted."* Three numbers that cannot
   describe one fight discredit every number beside them.
4. **The goodbye screen is a dead end.** Two greyed prompts for actions that no
   longer exist, and no indication of how to leave. It does close itself after a
   beat, which a still frame cannot show and a player should not have to
   discover by waiting.
5. The "nowhere to put a sixth" notice opens lowercase mid-sentence and reads as
   a truncation, in the one place the screen answers the player directly.

## What the judge praised, for the record

> This is not a generic delete dialog. It is two screens, it names the specific
> pal in every button label, and it enumerates what is lost.

and on the refusal path:

> The ceremony cannot be escaped … That is the right answer to the project's
> five-pal rule, and it is stated in fiction rather than as an error.

## Work this produced

- The harness now clears prior artefacts for its system, takes a lock and says
  loudly when one was already held, verifies every frame actually landed with its
  size, and ends the transcript with a manifest of the frames the run wrote — so
  a judge can check the frames they were handed against the frames that were
  produced.
- The rubric gained the distinction this exposed a sibling of: a harness calling
  `save()` itself proves the format round-trips and nothing about whether the
  game ever calls it. See the persistence question in the skill.
- Findings 1–5 all fixed.
- `tools/preview_ceremony.gd` gave all five pals the same trait, making the
  layout worst case and the identity best case — a card drawn from the wrong pal
  would have looked perfectly correct. It now uses distinct traits and audits
  each card against the pal the ceremony handed it.
