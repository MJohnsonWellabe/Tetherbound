"""Pipwing owner-picked remake (1 Nov 2026): owl, white and pale-blue, folded wings.

    blender --background --python this.py -- pipwing_a.glb --out rigged.glb --report report.json

tools/art_pipeline/blender/rig_bird.py unchanged (measured bird rig and its six
gameplay clips: idle, walk, run, attack, hit, faint), with one measurement
replaced, the way galecrest/source/rebuild/prepare_galecrest.py replaces
rig_bird.measure. rig_bird.torso_half_width walks out from the centreline to
the first air gap; Meshy's owl is a surface shell, so the first gap is the
hollow between the centreline and the flank and the torso measured 0.05 m wide
(wingspan 10x torso, rigged as SPREAD wings on a bird whose wings lie folded on
its flanks). Here each thin hip row's outer extent is used instead (median of
rows), which is the torso including the folded wings, as rig_bird intends for
a folded wing.

Used unchanged for every owner-rule bird remake (Pipwing, Galewisp, Aeriex,
Duskhush). Extra roles beyond rig_bird's six, for birds whose installed model
also carried, rode, swam or rested (via the F36 pose recipes, which do not
apply to a new mesh): fly_grip (wings open and beating, legs tucked), charged
(the attack, held longer), rest (rig_bird's faint, settled), swim (the walk
gait) and ride (the idle). A species only maps the roles it uses.
"""
import sys, pathlib
ROOT = next(p for p in pathlib.Path(__file__).resolve().parents if (p / 'project.godot').is_file())
sys.path.insert(0, str(ROOT / 'tools/art_pipeline/blender'))
import rig_bird as r


def shell_torso_half_width(pts, crotch_z, top_z, mid_x, hip_y, size):
    rows = 12
    z0 = crotch_z
    z1 = crotch_z + (top_z - crotch_z) * 0.40
    step = (z1 - z0) / rows
    near = [p for p in pts if abs(p.y - hip_y) < size.y * 0.16] or pts
    edges = []
    for i in range(rows):
        row = [abs(p.x - mid_x) for p in near if z0 + step * i <= p.z < z0 + step * (i + 1)]
        if len(row) >= 8:
            edges.append(sorted(row)[int(len(row) * .95)])
    return sorted(edges)[len(edges) // 2] if edges else size.x * .25


r.torso_half_width = shell_torso_half_width
# A bird whose crotch scan cannot resolve (Aeriex: tail plumes reach the
# ground between its long legs) falls back to rig_bird's FALLBACK_LEG_FRACTION;
# BIRD_FALLBACK_LEG_FRACTION overrides it with the leg length read off the
# reference, recorded in that species' provenance.
import os
if os.environ.get('BIRD_FALLBACK_LEG_FRACTION'):
    r.FALLBACK_LEG_FRACTION = float(os.environ['BIRD_FALLBACK_LEG_FRACTION'])


def author_fly_grip(rig, frames, prop):
    """Carrying flight: wings open wide and beat; legs tucked forward."""
    for frame in range(0, frames + 1, 2):
        t = frame / frames * 2 * r.math.pi
        beat = r.math.sin(t)
        for side in r.SIDES:
            r.wing_key(rig, side, "upper", frame, lift=20 + 28 * beat, swing=70)
            r.wing_key(rig, side, "fore", frame, lift=10 + 18 * beat, swing=45)
            r.wing_key(rig, side, "tip", frame, lift=6 + 12 * r.math.sin(t - .6), swing=25)
        for side in r.SIDES:
            r.leg_key(rig, "leg_upper_" + side, frame, forward=-35)
            r.leg_key(rig, "leg_lower_" + side, frame, forward=40)
        r.key(rig, "spine", frame, nod=4 * r.math.sin(t + .5))
        r.key(rig, "tail_1", frame, nod=6 * r.math.sin(t + 1.0))


def author_gait_swim(rig, frames, prop):
    r.author_gait(rig, frames, prop, swing=r.WALK_SWING, lean=r.WALK_LEAN, bob=r.WALK_BOB,
                  spine_nod=r.WALK_SPINE_NOD, thrust=r.WALK_HEAD_THRUST, tail=r.WALK_TAIL,
                  wing=r.WALK_WING, waddle=r.waddle_amount(prop))


r.CLIPS.update({"charged": (36, False), "fly_grip": (24, True), "rest": (48, False),
                "swim": (32, True), "ride": (72, True)})
r.AUTHORS.update({"charged": r.author_attack, "fly_grip": author_fly_grip, "rest": r.author_faint,
                  "swim": author_gait_swim, "ride": r.author_idle})
r.main()
