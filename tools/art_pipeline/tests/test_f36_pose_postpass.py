"""F36 post-pass: idempotent, and it never touches anything but pose data."""
import json
import math
from pathlib import Path
import sys
import unittest

PIPELINE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PIPELINE))
import f36_pose_postpass as postpass

ROLES = set(postpass.ROLES)


class PostPass(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.live = postpass.LIVE.read_text()
        cls.once = postpass.rewrite(cls.live)
        cls.twice = postpass.rewrite(cls.once)

    def test_running_twice_changes_nothing(self):
        self.assertEqual(self.once, self.twice)

    def test_committed_file_is_current(self):
        self.assertEqual(self.live, self.once, 'run tools/art_pipeline/f36_pose_postpass.py')

    def test_only_pose_roles_and_grounding_differ(self):
        before = json.loads(self.live)
        after = json.loads(self.once)
        self.assertEqual(list(before), list(after))
        for key in before:
            if key not in ('species', 'profiles'):
                self.assertEqual(before[key], after[key])
        self.assertEqual(list(before['species']), list(after['species']))
        for name, row in before['species'].items():
            strip = lambda r: {k: v for k, v in r.items() if k != 'grounded_roles'}
            self.assertEqual(strip(row), strip(after['species'][name]), name)
        for pid, profile in before['profiles'].items():
            for role, spec in profile.items():
                if role not in ROLES:
                    self.assertEqual(spec, after['profiles'][pid][role], (pid, role))

    def test_every_rewritten_species_grounds_all_five_roles(self):
        after = json.loads(self.once)
        for name, row in after['species'].items():
            if name in postpass.SKIP_SPECIES:
                continue
            self.assertEqual(set(row['grounded_roles']), ROLES, name)

    def test_long_necks_never_invert_on_hurt(self):
        after = json.loads(self.once)
        for name, row in after['species'].items():
            if name in postpass.SKIP_SPECIES:
                continue
            for frame in after['profiles'][row['profile']]['hit']['frames']:
                for bone in ('neck', 'head'):
                    if bone in frame['bones']:
                        w = abs(postpass.AUTHOR.quaternion(frame['bones'][bone])[3])
                        angle = 2 * math.degrees(math.acos(min(1.0, w)))
                        self.assertLessEqual(angle, postpass.NECK_PITCH_LIMIT + 0.01, (name, bone))

    def test_round3_faint_rests_the_torso_on_the_floor(self):
        import statistics
        import f36_pose_solver as solver
        import f36_skin as skin_module
        after = json.loads(self.once)
        gaps = {}
        for name, row in after['species'].items():
            skin = skin_module.Skin(row['model'], row['rig_contract'], row['bones'])
            frame = solver.Frame(skin, after['profiles'][row['profile']]['faint']['frames'][-1])
            gaps[name] = solver.faint_gap(skin, frame.points())
        self.assertLessEqual(statistics.median(gaps.values()), solver.FAINT_GAP, gaps)
        self.assertLessEqual(max(gaps.values()), 0.2, gaps)

    def test_enabled_hurt_and_faint_never_tear_the_mesh(self):
        # A live pose must not stretch any skinned edge far past its rest length
        # (Stormursa's prone faint did: spike 0.258, visible slabs in game).
        import f36_pose_solver as solver
        import f36_skin as skin_module
        after = json.loads(self.once)
        worst = {}
        for name in after['enabled_species']:
            # Water forms (water_riverdrake) share their source species' row.
            row = after['species'].get(name) or after['species'].get(name.removeprefix('water_'))
            if row is None or name in postpass.SKIP_SPECIES:
                continue
            skin = skin_module.Skin(row['model'], row['rig_contract'], row['bones'])
            for role in ('hit', 'faint'):
                for spec in after['profiles'][row['profile']][role]['frames']:
                    s = solver.spike(skin, solver.Frame(skin, spec).points())
                    worst[(name, role)] = max(worst.get((name, role), 0.0), s)
        torn = {k: round(v, 3) for k, v in worst.items() if v > solver.SPIKE_LIMIT + 0.03}
        self.assertEqual(torn, {})

    def test_voltarach_binds_its_native_arachnid_rig(self):
        import f36_arachnid_profile as arachnid
        after = json.loads(self.once)
        row = after['species']['voltarach']
        self.assertEqual(row['model'], arachnid.MODEL)
        self.assertEqual(row['profile'], arachnid.PROFILE)
        self.assertEqual(set(after['profiles'][arachnid.PROFILE]), ROLES)
        self.assertEqual(arachnid.rewrite(self.live), self.live, 'run tools/art_pipeline/f36_arachnid_profile.py')


if __name__ == '__main__':
    unittest.main()
