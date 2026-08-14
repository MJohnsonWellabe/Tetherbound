# HOW TO START TETHERBOUND WITH GODOT AND CLAUDE CODE

## What you need on your Windows computer

1. Install the current stable **Godot 4** release.
2. Install **Git**.
3. Install **Claude Code** or use Codex with GitHub access.
4. Clone/create the Tetherbound repository locally.
5. Put the files in this package into the repository:
   - `docs/GAME_DESIGN.md`
   - `docs/MEADOWS_VERTICAL_SLICE.md`
   - `docs/TECHNICAL_START.md`
   - `CLAUDE.md`

You do not need to manually learn Godot before Claude begins creating the project, but you should know how to open and run it.

## Godot basics you will use

After Claude creates `project.godot`:

1. Open Godot.
2. Click **Import**.
3. Browse to the repository folder.
4. Select `project.godot`.
5. Open the project.
6. Press **F6** to run the current scene or **F5** to run the project.
7. Use the **Debugger** panel at the bottom if something errors.
8. Plug in/use the ROG Ally controls and test them in the real game regularly.

## Windows executable

Godot can export the game as a Windows build.

In Godot:
1. Open **Project → Export**.
2. Add **Windows Desktop** preset if it is not already present.
3. Choose an output such as:
   `build/windows/Tetherbound.exe`
4. Export the project.

Claude should configure the export preset early so you are not discovering export problems at the end.

## How to use Claude Code

From the repository root, give Claude a prompt like:

> Read CLAUDE.md and all files under docs/ before making changes. Start only with M0 and M1 from MEADOWS_VERTICAL_SLICE.md. Set up the Godot project, Windows export preset, controller input map, and a third-person movement playground with walk, sprint, jump, stamina, fall damage, camera orbit, rolling test terrain, and a minimal HUD. Do not implement creatures or combat yet. Keep tunable movement values in configuration/resources. Run the project or available validation and document anything I need to test manually on the ROG Ally.

Then test the result yourself.

Your feedback should be experiential:
- movement too floaty
- camera too close
- sprint too slow
- jump too high
- terrain feels empty
- frame rate bad
- buttons confusing

Have Claude fix that before moving to M2.

## Recommended workflow

Do not say:
> Build the whole game.

Instead say:
> Read the docs. Implement the next milestone only. Test it. Stop when it is ready for me to play.

Then you play it and give feedback.

This protects the project from accumulating 30 mediocre systems before the basic game is fun.

## Suggested milestone prompts

### After movement feels good
> Implement M2 only: one roaming wild creature encounter and Combat Mode. Use placeholders if necessary. Support target/interact, choosing/deploying a creature, Quick Attack, Charged Attack energy, Run, and the switching architecture. Do not implement catching yet. Make it comfortable on controller and stop for playtesting.

### Then catching
> Implement M3 only. Add aimed physical orb throwing during wild combat. Full-health attempts must be allowed; current HP should influence capture success; fainting the wild creature must remove the capture opportunity. Focus on the physical feel of aiming and throwing before adding content.

### Then party/release
Proceed through the vertical-slice milestones one at a time.

## What you should personally do in Godot

You mostly need to:
- open the project
- press Play
- test with controller
- observe errors
- test exported `.exe` builds
- give Claude precise feedback about feel/look

You do **not** need to hand-code Godot scenes unless you want to.

## Git workflow

Keep the repository in Git from day one.

At useful checkpoints:
- inspect changes
- commit working milestones
- use clear messages such as `M1: third-person movement playground`
- avoid allowing a coding agent to rewrite unrelated working systems during a focused milestone

A clean commit after each playable milestone gives you a safe rollback point.

## First human playtest target

Before thinking about the 12 creatures, you should be able to launch the `.exe` on the ROG Ally and enjoy simply:
- moving
- sprinting
- jumping
- looking around
- traversing hills
- seeing the landscape

If movement is bad, stop and fix it. Everything else depends on it.
