# T5-STORY-2 — narrative drive: does the player know why, and want to continue?

**Branch:** `ralph/T5-STORY-2` off `origin/main` (`5d171130`).
**Axis:** good story, and a reason to keep going. Not systems, art, perf or
reliability — whether a player moving through the chapter's beats ever knows why
they are doing the next thing, feels the stakes rise, and wants to continue.

**One-line summary:** the chapter's *writing* is in good shape and its opening
does deliver the player to their first fight; what was broken is everything
between the beats — for the last two thirds of the game the HUD's one tracked
objective said *"Feed your team before you sign up."*

---

## 0. The instrument

`tools/_probe_story_drive.gd` (new). Stands the real Meadows up, takes the live
`Game.progression` store, and walks the chapter's own shipping flags in
`objectives.json` order. At each rung it reads, through the game's own readers
and nothing else:

| what | read through |
|---|---|
| the tracked HUD line | `scripts/debug/gate_f_probe.gd::tracked_objective()` |
| the tracked hint | `quest_log.gd::tracked_hint()` |
| the guided quest-log rows | `quest_log.gd::guided_entries()` |
| what every villager would say | `village_npcs.gd::greeting_for()` |

Nothing in it reimplements a reader — a probe that parsed `objectives.json`
itself would be measuring a second copy of the game.

**What it is and is not.** It does not fight the captains or beat the Warden. It
advances the same flags those fights write, in the order they write them, and
asks what the shipping guidance says at each point. That is evidence about the
**guidance**, which is this lane's subject. It is not evidence that the fights
are reachable — Gate F owns that. Every string it prints is one the shipping
build would put on a real player's screen.

---

## 1. The question my brief named as unowned — answered, and the answer is good

> *T5-FEEL proved combat engages through the real input path but its probe
> bypasses the opening, so "the opening never delivers the player to their first
> fight" is untested and unowned.*

**The premise is mistaken, and that is the useful finding: this path is not
untested and not unowned.** `tests/smoke_gate_a_opening_segment.gd` plays exactly
it — title screen through the natural first catch, every action a parsed physical
joypad event through the live InputMap, no teleporting, no seeded inventory, no
granted beats — and `.github/workflows/ci.yml:985` runs it on every CI round, in
its longer `--gate-a-continuous-core` form. What was missing was not coverage but
the connection between that job and the open question.

So do not open a lane for it. I ran it four times on current `main` to say what
it actually reports. Three passed. Timeline of the first:

```
+70.66s  wake / Get Up complete
+74.95s  Grandpa briefing and pack complete
+79.04s  starter selected and named
+79.98s  Grandpa's first-catch supplies received (15 Basic Orbs)
+81.58s  usable house / front doorway exited
+90.49s  tutorial Bramblebun combat entered
+95.58s  Bramblebun naturally weakened to 32/124 HP
+102.80s physical landed throw caught Bramblebun on launch 1
+104.42s catch complete; exploration resumed with two-creature party
```

So: **the opening does deliver the player to their first fight and their first
catch, continuously.** The chapter has a ladder for the story to climb.

**Honest caveat, and it is the one thing here worth acting on.** Run 2 of 4
failed: `right-stick aim could not line up the real throw reticle`. That is the
harness's own aim-convergence loop, a flake class the harness file documents at
length in its own comments, and I did not attribute it to the game. But 3/4 is
the number, not 4/4 — which means this CI job has a roughly 25% false-failure
rate on a container like this one, and a job that cries wolf one round in four is
a job people learn to re-run without reading. That belongs to whoever owns
opening reliability, not to a narrative lane, but it is real and unfiled.

**Not duplicated:** OP-0830-4 (trapped in Grandpa's house) is fixed on
`origin/ralph/T5-OPENING`, which adds three new opening rungs
(`opening_hear_grandpa`, `opening_take_starter`, `opening_show_grandpa`). I read
that branch before touching anything and stayed out of it. My `objectives.json`
changes are all *below* their insertion point and should merge cleanly.

---

## 2. THE defect — the tracked objective spends the last two thirds of the chapter naming a food tutorial

**Severity: chapter-scale.** This is the worst thing I found by a distance.

Walking the chapter's flags in order, the HUD's one tracked line — the game's
single answer to *"what now"* — read:

```
--- 16  after: beat the grunt at South Bridge      -> Feed your team before you sign up.
--- 18  after: beat the Relay Captain              -> Feed your team before you sign up.
--- 24  after: beat the Riverwatch captain         -> Feed your team before you sign up.
--- 28  after: beat the elite                      -> Feed your team before you sign up.
--- 29  after: defeated the Meadows Warden         -> Feed your team before you sign up.
--- 30  after: shut down the machine               -> Feed your team before you sign up.
--- 32  after: walked back through a healed Meadows-> Feed your team before you sign up.
```

**21 of 32 rungs** showed a hungry team a tracked line that was not the rung they
were standing on. The eleven story beats below that rung were unreachable by the
tracked line entirely.

### Root cause

Three correct-in-isolation decisions that compose into this:

1. `tournament_team_fed` is deliberately **volatile** — a state, not an event.
2. `tournament.gd::_process` rewrites it from the live team **once a second, for
   the whole game**, with no gate on whether the tournament is still ahead.
3. `quest_log.gd::tracked_text()` is **"first unset flag in file order"**.

So a volatile flag at file position 10 outranks the Warden forever. On this
chapter's own ~1.1/min satiety drain across three to four hours, a team is
hungry most of the time — this is the common case, not an edge case.

`objectives.json` predicted the behaviour and blessed it: *"a team that goes
hungry again puts the line BACK on the HUD. That is the correct behaviour for a
state rather than an event."* That is right **before sign-up** and catastrophic
after it, and nothing in the file distinguished the two.

### Fix

`retired_by` — one optional flag id on one entry, deliberately the exact shape of
the `revealed_by` that already exists one row down. One says *"not yet"*, this
says *"no longer"*. It cannot express an order the file does not already have,
so it is not the prerequisite graph spec §19 and CLAUDE.md ban.

`tournament_feed_team` gets `"retired_by": "tournament_entered"` — the flag the
rung's own words name: the line says *"before you sign up"*, and once you have
signed up there is no *before* left. The lesson is untouched: the rung still
waits on real feeding and still puts itself back on the HUD every time the team
goes hungry right up to registration, which is all the 2026-08-23 owner
directive asked for. It simply stops outranking the Warden afterwards.

Implementation collapsed three copies of the done-check in `quest_log.gd` into
one `_done()` helper, so the tracked line, the tracked hint and the log can no
longer disagree.

**Measured: 21 → 2.** The two survivors are rungs 12 and 13 — the feed lesson,
correctly, before sign-up.

---

## 3. The back three quarters of the chapter gave a bare verb and no direction

`how` — the "next concrete action" line the owner asked for in OP23-04 — was
authored on 13 of 24 main rungs. All 13 were the opening ladder. The remaining
eleven were the warrens, the relay captain, the captive, the relay, the mill
crossing, the three captains, Meadows Hall, the Warden, the machine, the roster
and the ending, and they read like this:

```
Defeat the Relay Captain.
Shut down the Tether Relay.
Settle who walks with you.
```

**16 of 32 rungs** offered a verb and nothing else. The file's own comment
treated it as scope: *"OP23-04's directive is the opening 'until tournament
entry', and a chapter-wide hint pass is not this lane's to invent."* OP23-04
asked for the opening because the opening is what the owner had played; the
reason the rule exists — *tell the player the next thing to do* — does not stop
at the bridge, and the mechanism it built costs one string per rung.

Written from the world's own data, checked rather than remembered. The three
most useful facts in the set were nowhere in the game before this:

- **the three sigils.** Each Upper Meadows captain carries one and the gate on
  the Hall road wants all three (`playground_world.gd::SIGIL_ITEM_IDS`). A player
  could beat one captain and have no idea why the gate stayed shut.
- **read the board first.** Spec §28 puts `stronghold_reveal` *before* the Warden
  speaks, and the Warden's own first line depends on it (*"You read the board.
  Good."*). It is a threshold prop and easy to walk straight past, which
  collapses the chapter's central reveal.
- **the release ceremony already carries history.** `tab_creatures.gd::_history_line()`
  prints battles fought beside you, the day caught, and levels earned since —
  and nothing told the player to look before choosing.

One correction fell out of writing these: `restore_the_mill_crossing`'s `_why`
said the mill gear is *"the gear the Relay Captain pays"*. It is not — Sela hands
it over on rescue (`relay.json::relay_captive_freed`). The `how` line had to be
true, so it was checked; the `_why` is corrected in place.

Nothing added names what is in chamber five before the stronghold. The file's own
`_comment_no_spoilers` rule holds.

**Measured: 16 → 0.**

---

## 4. Home did not stay relevant — the village said the same thing for the entire back half

`MEADOWS_EXIT_CRITERION` **F3**: *"home stays relevant — Grandpa's dialogue
changes, rescued people return, returning is worth it."*

Walking the chapter against a live village, every villager said the **identical**
thing at every rung from the tournament to the ending:

```
--- 16 beat the grunt at South Bridge  Mira -> shop_intro   Oskar -> trade_intro   Halda -> champion
--- 21 restored the Old Mill Crossing  Mira -> shop_intro   Oskar -> trade_intro   Halda -> champion
--- 25 the Hall approach opens         Mira -> shop_intro   Oskar -> trade_intro   Halda -> champion
--- 29 defeated the Meadows Warden     Mira -> shop_intro   Oskar -> trade_intro   Halda -> champion
```

South Bridge, the quarry, the warrens, the relay, three captains and the Hall
gate all happened and nobody at home reacted to any of it. The only mid-chapter
change in the whole village was the rescued ranger appearing.

### Why it was structurally quiet — worth knowing before anyone extends this

`greeting_when` grants **one** conversation per villager, and the vendors' single
slot carries the **shop-opening effect** (`shop:goods:mira`). So an
acknowledgment line and a service line compete for the same slot: a news-only
branch inserted above the shop branch silently removes the shop. D39 already
names the rule — *a vendor branch is never lost, only carried forward* — and the
existing `legendary_freed` branches obey it. Any new line must carry the service
effect forward or it breaks the stall.

### Fix

Three branches, one per beat home would actually hear about:

| villager | fires on | why that beat |
|---|---|---|
| Mira | `captive_rescued` | Sela's own last line is *"I'll walk to your village"*; a shopkeeper is who notices a stranger arrive |
| Oskar | `south_bridge_open` | the key on that grunt's belt was **his** — his own challenge line already says Team Tether took it off him in the spring, and he never got to learn it came back |
| Tam | `hall_approach_open` | a smith reads three sigils on sight, and this is the last time the player is home before the Hall |

Each sits above the villager's `defeated_*` branch and below both their challenge
branch and their ending branch. That placement costs nothing: an unbeaten
villager still challenges, the ending still wins, and Mira's and Oskar's
conversations carry their own `shop:`/`trade:` effect.

Nothing is said that the player was not already told to their face. Spec §32's
reveal ladder is untouched.

**Verified on a re-walk.** Each branch fires at its own beat and only there,
challenge branches are preserved, and the `legendary_freed` endings still win:

```
--- 23 beat the grunt at South Bridge  Oskar -> village_oskar_bridge
--- 26 found the captive at the relay  Mira  -> village_mira_road
--- 32 the Hall approach opens         Tam   -> village_tam_hall
--- 37 shut down the machine           Mira -> _freed  Oskar -> _freed  Tam -> _freed
```

Across the eighteen rungs from the tournament win to the end, the village now
presents **six** distinct states rather than four, and — the measure that
actually matters — **before this change no villager had a single branch keyed to
any mid-chapter flag**, the rescued ranger excepted. Every branch in every
ladder was either an opening/tournament-era flag or `legendary_freed`. That gap
is the whole finding, and it is visible by reading the ladders.

**One thing this taught the probe.** The first village walk showed Mira and
Oskar apparently unchanged, because the probe had never set `mira_shop_open` /
`oskar_trade_open` — it was walking the chapter as a player who never met Mira,
whose visit is a *required* opening beat. The chapter list now sets the village
service flags at the point a real player sets them. Worth knowing: a probe over
`greeting_when` that skips the service flags reads the wrong branch every time.

---

## 5. What I did NOT fix, and why — Grandpa goes silent for three quarters of his own story

**This is the largest remaining item on this axis and I am handing it over
deliberately rather than half-building it.**

Grandpa Elias sets up the entire chapter — *"Team Tether's back. They've taken
Meadows Hall... If you're going to take this on, you won't do it alone."* — and
then has **nothing to say from tournament sign-up to the credits.**

`opening.json`'s `beats.grandpa_conversations` maps opening **beat** → conversation,
and the last three entries are `"tournament_signup": ""`, `"qualification": ""`,
`"free_play": ""`. `sequence_director.gd::_refresh_prompts()` disables his prompt
whenever the conversation for the current beat is empty, so he stops being
interactable at all. He is not a village NPC and has no `greeting_when` ladder —
he is built by the sequence director — so there is no data-only place to put a
later line.

He has no reaction to the tournament win, the bridge, the relay, the captains,
the Hall, or the Warden. **He has no line after the Warden falls**, while Mira,
Oskar, Tam, the foreman and a traveller all do (`meadows_freed.json`).

Fixing this needs a small new seam — a flag-keyed ladder for Grandpa mirroring
`greeting_when`, read by `sequence_director.gd` after the beat map runs dry.
That is a mechanism choice rather than content, so it is flagged here rather
than invented at 3am. It is maybe thirty lines and five conversations, and it is
the single highest-value narrative item I am aware of that remains open.

### Flagged for the owner — the recurring rival

My brief said three named Band 1 trainers (Kip, Talon, Faye) were removed
tonight, that Talon was *"a friendly rival who challenges you throughout the
story"*, and that re-authoring him deliberately would be exactly this lane's
work. **I could not act on it: none of the three exists anywhere in `main` or in
my tree, and the `_comment_t3_ladder` explaining the removal is not on `main`
either** — that change is still on another lane's branch. I could not read the
stated reasoning, so I will not pretend to have weighed it.

The design opinion, offered as an opinion: a recurring rival is the cheapest
escalation device available to this chapter, because it is the only one that can
*re-appear*. Everything the player currently fights is a rung — met once, beaten,
left behind — which is why the chapter's pressure comes entirely from the enemy
side and never from a peer. But he only works if he is authored as an arc with
three or four appearances that track the player's own growth, and a census at
its ceiling means a rung has to be given up to pay for him. That is an owner
decision about what the ladder is for, not a data edit.

---

## 6. What is genuinely good, and should not be "improved"

Worth recording, because the temptation on a lane like this is to rewrite things
that are working:

- **The Warden.** `stronghold.json`'s brief is executed exactly: he confirms the
  readout rather than denying it, argues that the cost is worth paying, never
  says *"you cannot stop me"*, and does not recant when he loses. The player has
  to choose against a real argument. Leave it alone.
- **The trainer escalation ladder.** Dorn → Pell → Kest → Corr → Ness each hand
  off forward in character (*"not like I'm the last one you'll run into between
  here and the river"*). Every trainer in every band has both a challenge and a
  defeated conversation authored — I audited all 27 and found no gaps.
- **Sela at the relay.** The chapter's key escalation beat, and she is written as
  a professional still working the problem rather than a victim. She delivers the
  conspiracy's shape and explicitly does not know its centre, which is the reveal
  ladder done properly.
- **The release ceremony** already prints real history — battles beside you, day
  caught, levels earned since — and stays silent rather than printing a zero when
  there is nothing honest to say.

---

## 7. Verification

| what | result |
|---|---|
| `smoke_gate_a_opening_segment.gd` × 4 on `main` | 3 pass, 1 harness aim flake |
| `run_tests.gd --only=quest_log,gateb_objective_chain,input_glyph_verbs,dialogue_runner` | 112 tests, 1549 assertions, **0 failed** |
| `run_tests.gd --only=dialogue_runner,village` | 62 tests, 796 assertions, **0 failed** |
| `run_tests.gd` — **the full suite**, because `quest_log.gd` is a core reader | **1603 tests, 3,568,660 assertions, 0 failed** |
| `_probe_story_drive.gd` — rungs with no `how` | **16 → 0** |
| `_probe_story_drive.gd` — rungs misdirecting a hungry team | **21 → 2** (both correct) |
| `_probe_story_drive.gd` — villager ladders | see §4 |

Commits are `[skip ci]` checkpoints, so no CI round has been spent on this
branch — but the full local suite is green above, which is the same 1603 tests
CI would run. It still wants one real CI round before merge for the jobs the
local runner does not cover.

## 8. Files touched

```
scripts/world/quest_log.gd          retired_by; three done-checks folded into _done()
data/progression/objectives.json    retired_by on the feed rung; 11 new `how` lines;
                                    two stale comments corrected
data/dialogue/village.json          3 new mid-chapter villager conversations
data/config/village_npcs.json       3 new greeting_when branches
tools/_probe_story_drive.gd         NEW — the instrument
```

## 9. If you pick this up next

1. **Grandpa** (§5). Highest value remaining on this axis.
2. Run a full CI round on this branch.
3. The opening drive's 1-in-4 aim flake (§1). It is a CI job
   (`ci.yml:985`), so this is a live false-failure rate, not a curiosity.
4. `_probe_story_drive.gd` is cheap to extend. Any lane adding a beat can run it
   and see, in one page, exactly what the game will tell a player at that beat.
