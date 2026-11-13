# BELOW6-FLINCH (F36#30 Abyssal Guardian 5.77; F36#86 Voltarach 6.50): NOT SENT on its own

Judges, 3/3 on both: "the hit is almost identical to standing".

Flag `creature_clip_flags.json below6_flinch_abyssal` (OFF): Abyssal Guardian's own hit clip, rotation x1.9, position x0.6.

CPU (`_sheet_cpu.jpg`: base above, arm below; Abyssal standing and hit 050, then Voltarach standing and hit 050; `capture_f36_poses.gd --roles=hit`):
- **Abyssal Guardian:** the base hit is a small hop with the neck still upright. The arm bows the neck forward and drops the body into a crouch with the feet near the ground: a clearly different, grounded flinch.
- **Voltarach: the clip flag does not reach it.** The native spider that ships does not play its own hit clip, so base and arm are the same frame, and both are nearly the standing pose. Its flinch has to come from the recipe hit (`creature_pose_settle`), which is LANE-THINGS' file. Voltarach was removed from the flag.

Why not sent: for the Abyssal Guardian alone I estimate +0.2 to +0.4, under the rule. It is a rider for the row's next real change (LANE-THINGS' faint grounding, expected to stack to about 6.5 on #30): one line in the overlay.

**For LANE-THINGS:** Voltarach's hit needs a recipe flinch (body dip and a leg recoil); the clip-flag route is a no-op for it.
