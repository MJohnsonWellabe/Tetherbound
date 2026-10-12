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


if __name__ == '__main__':
    unittest.main()
