"""F29#3 r7 (close-1020): Stormursa v1 flinch hit and grounded topple faint.
Rewrites only the stormursa_native_adult hit/faint frames in data/creatures/f36_pose_candidates.json.
Run from a clean pre-r7 recipe: python3 assets/creatures/tetherbound/stormursa/source/author_f36_hit_faint_r7.py"""
import sys, json, importlib.util, re, math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[5]
spec=importlib.util.spec_from_file_location('pp', ROOT/'tools/art_pipeline/f36_pose_postpass.py')
PP=importlib.util.module_from_spec(spec); spec.loader.exec_module(PP)
mul=PP.mul; E=PP._ease; group=PP.group

def topple_faint(rig, frames, axis, roll=-90.0):
    """Feet stay planted while the front knees buckle and the near shoulder drops
    (0-.45); the body then tips onto its flank (.4-.8) and settles with the head
    lying in line with the body, face visible, legs slack (late, small tuck)."""
    for f in frames:
        p=f['phase']
        buckle=E(p/.45); fall=E((p-.4)/.4); late=E((p-.75)/.25)
        settle=math.sin(math.pi*E((p-.78)/.22))*(1-E((p-.92)/.08))
        turns={}; add=PP._adder(rig,turns)
        add('neck', rig.pitch(-14*buckle*(1-fall) - 4*fall))
        add('head', rig.pitch(-6*buckle*(1-fall)))
        for b in rig.contract:
            g=group(b)
            if g=='front_upper': add(b, rig.swing(-10*buckle*(1-fall) + 10*late))
            elif g=='front_lower': add(b, rig.swing(-38*buckle*(1-fall) - 10*late))
            elif g=='rear_upper': add(b, rig.swing(-8*late))
            elif g=='rear_lower': add(b, rig.swing(12*buckle*(1-fall) + 8*late))
            elif g=='tail': add(b, rig.pitch(-10*fall))
        pivot=mul(PP.axis_angle(axis, roll*fall + roll*.06*settle), rig.pitch(-7*buckle*(1-fall)))
        PP._solve(rig,f,turns,pivot)

def flinch_hit(rig, frames):
    """A jolt at .12: head snaps away and down, shoulders hunch back, front
    knees give, body leans away; held to .35, back to stance by .8."""
    for f in frames:
        p=f['phase']; e=E(p/.12)*(1-E((p-.35)/.45))
        turns={}; add=PP._adder(rig,turns)
        add('spine', rig.pitch(-4*e))
        add('neck', mul(rig.yaw(-26*e), rig.pitch(-14*e)))
        add('head', mul(rig.yaw(-12*e), rig.pitch(-10*e)))
        for b in rig.contract:
            g=group(b)
            if g=='front_upper': add(b, rig.swing(-14*e))
            elif g=='front_lower': add(b, rig.swing(-20*e))
            elif g=='rear_lower': add(b, rig.swing(10*e))
            elif g=='tail': add(b, rig.pitch(-10*e))
        PP._solve(rig,f,turns,mul(rig.roll(9*e), rig.pitch(-3*e)))

text=PP.LIVE.read_text(); live=json.loads(text)
row=live['species']['stormursa']; pid=row['profile']
rig=PP.Rig(row['rig_contract'], row['bones'])
skin=PP.SKIN.Skin(row['model'], row['rig_contract'], row['bones'])
prof=live['profiles'][pid]
axis=PP.mesh_long_axis(skin)
topple_faint(rig, prof['faint']['frames'], axis); PP.SOLVER.guard_stretch(skin, prof['faint']['frames'])
flinch_hit(rig, prof['hit']['frames']); PP.SOLVER.guard_stretch(skin, prof['hit']['frames'])
m=re.compile(r'\n    %s: ' % re.escape(json.dumps(pid))).search(text, text.index('\n  "profiles": {'))
s,e=PP.value_span(text, m.end())
PP.LIVE.write_text(text[:s]+json.dumps(prof, separators=(',',':'))+text[e:]); print('patched')
