# Team care and swimmer preparation content — Wave5

Base main: `2eb8d4b8681ce8224eaa58666b41be5164479c5b`, whose own push
CI34272560821 passed on attempt1. These changes prioritize the owner's request
for actual game content. No workflow, retry policy or test ceiling changes.

The saved paid-camp image told the player to enter the tournament with three
unrested creatures. The new `tournament_prepare_team` objective uses the existing
live `tournament_condition_ready` flag and retires after registration. It explains
assigning tired or unhappy creatures, sleeping, reusing one bed or building more,
and feeding the team. The eligibility rules are unchanged. Existing quest/home
checks passed54 tests/896 assertions; the regression covers readiness changing
in both directions before registration and retirement afterward.

After Iona teaches the saddle, the previous guidance jumped to a vaguely
"prepared swim mount" and told players to equip the saddle. Production instead
checks inventory and fits the saddle on mounting. Iona now names the actual
Tidal Cradle camp workbench and saddle-in-bag/Ride flow. Otto explains catching
Mosshell or Riverdrake, the full-belt farewell choice, and using a pickaxe for
Reef Stone. Salt Crown's existing objective retains preparation instructions
after learning the recipe and preserves the actual chart interaction.

Source checks: `water_camps.gd` creates the camp workbench with a craft prompt;
`riding_controller.gd::_has_tack` checks the bag and `mount()` fits the saddle;
the existing recipe costs8 reed fiber/6 driftwood/4 Reef Stone. The Tidal dry
encounter table includes compatible ordinary swimmers. Existing pending-catch
UI handles the five-creature choice. Effects, costs, flags and roster rules
are unchanged.

Existing Water dialogue/dock/quest checks passed47 tests/937 assertions with
zero failures, errors or warnings. Logs: `.artifacts/water-preparation-text.log`
and `.artifacts/water-preparation-text-engine.log`. The isolated First Shore
through Iona pass is recorded separately in WATER-OPENING-CONTINUOUS.md; it
preceded these text edits and is not fresh campaign evidence. Full continuous
opening-to-ending acceptance remains open.

Brine ordinary site011 is also moved from its rejected slope to a nearby
supported shelf at[473.6123,41.1299,747.8559], preserving its table, count,
roaming radius and all runtime footing/reach rules. All three table species
passed native footing. A diagnostic initial road pose and prepared ally are
disclosed; subsequent ordinary grounded walking and one physical Interact
started a fight with the exact authored Riptusk (85 observed frames, zero
navigator resets). Owner saves were unchanged and no engine/script error
occurred. `.artifacts/wave5-brine011-direct-{console,engine}.log` records exact
candidate/enemy identities. Its inherited terminal prose incorrectly says no
combat attempted; the PRE/POST receipts show the actual fight start.

The earlier011 diagnostic required arbiter registration which Water does not
currently provide; its failure remains recorded. The corrected diagnostic uses
Water's real direct-input path, not a callback or larger reach. Site010's high
shelf failed ordinary approach and was restored. No full combat win, HUD
presentation, fresh campaign or complete ecology repair is claimed.

The placement investigation exposed a separate player-facing omission: Water
created its combat manager and director without mounting the existing CombatHUD
or registering Engage with its interaction arbiter. No alternate Water consumer
provided those displays. The builder now reuses the shipped HUD with the actual
manager/director paths and registers the director, matching the other realms.
Simulation worlds still omit the HUD; repeated build calls reuse the same nodes.
No combat UI redesign or fighting rule changed.

The existing scene smoke retains its original checks and now also checks actual
HUD binding, idempotence, Engage presentation, both combatant panels, names,
health and move controls. Its headless run passed40 checks/zero failures.
Evidence: `.artifacts/wave5-water-combat-hud{,-engine}.log`. This scene fixture
uses synthetic prerequisites, diagnostic poses and its existing direct trainer
challenge; it does not establish ordinary chapter traversal or a full fight win.

Rendered execution passed41 checks/zero failures, owner hashes unchanged,
zero engine/script errors and seven existing terrain/deprecation warnings.
Root inspected `.artifacts/wave5-water-combat-hud-render.png`: Cragclaw/Lysa,
Mosshell, health, energy and move controls are visible. The fixture camera is
still looking across the landscape after its diagnostic pose change; the image
is evidence of the HUD, not combat framing or visual-quality acceptance.
No second art iteration was made. Render logs:
`.artifacts/wave5-water-combat-hud-render{,-engine}.log`.

PR89's first head08b5b3d6 exposed two stale content expectations in CI34277113851:
`test_flag_scopes` still required33 entries after the new authored row made34,
and `test_gateb_objective_chain` omitted the condition-ready step before entry.
The corrected fixtures retain every scope assertion and add the readiness
transition to the ordered chain; no reach, timeout, gameplay eligibility or
failure criterion is relaxed. Existing scope/chain/quest checks pass59 tests/
1223 assertions with clean output in `.artifacts/wave5-objective-chain{,-engine}.log`.
The failed CI head remains recorded; it is not rerun or merged.

On corrected headf4886bcb, the existing saved-camp capture was executed in a
fresh isolated diagnostic copy. Root inspected
`.artifacts/wave5-paid-camp-guidance.png`: the actual HUD now reads "Rest and
feed all five before you sign up" at the paid camp where the previous capture
incorrectly said to enter the tournament. Capture exited0; owner and original
fresh-scratch fingerprints were unchanged. This confirms the rendered guidance,
not a resumed fresh run, successful next rest, or tournament completion.
No engine/script errors occurred. Fourteen warnings remain explicit: twelve
terrain mipmap notices, one interpolation deprecation and the expected staged
camera-follow notice. Logs: `.artifacts/wave5-care-capture{,-stderr,-engine}.log`.
