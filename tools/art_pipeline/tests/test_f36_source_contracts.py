"""Non-engine risk checks: scale monotonicity and charged task cap/receipts."""
import copy
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

PIPELINE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PIPELINE))
import creature_scale_ladder as scale
import f36_meshy_guard as guard


class Contracts(unittest.TestCase):
    def test_enlarged_creatures_and_mount_geometry_never_shrink(self):
        species = scale._load(scale.SPECIES_PATH)
        water = scale._load(scale.WATER_ROSTER_PATH)
        mounts = scale._load(scale.WATER_MOUNTS_PATH)
        look = species['species']['terrapup']['placeholder']
        look['height'] = 9.0
        look['footprint_allowance'] = 99.0
        water['species']['cannonback']['placeholder']['target_height_m'] = 9.0
        before_mount = copy.deepcopy(mounts)
        before_ride = copy.deepcopy(species['species']['terrapup']['rideable'])
        scale.apply_scale(species, water, mounts)
        self.assertEqual(look['height'], 9.0)
        self.assertEqual(look['footprint_allowance'], 99.0)
        self.assertEqual(species['species']['terrapup']['rideable'], before_ride)
        self.assertEqual(water['species']['cannonback']['placeholder']['target_height_m'], 9.0)
        self.assertEqual(mounts, before_mount)
        once = copy.deepcopy((species, water, mounts))
        scale.apply_scale(species, water, mounts)
        self.assertEqual((species, water, mounts), once)

    def test_cap_and_uncertain_submission_are_fail_closed(self):
        with tempfile.TemporaryDirectory() as temporary:
            original = guard.LEDGER
            guard.LEDGER = Path(temporary) / 'ledger.json'
            try:
                calls = []
                def request(method, path, body):
                    calls.append(path)
                    return {'result': f'task-{len(calls)}'}
                for _ in range(30):
                    guard.submit_guarded(request, '2026-10-01', 'terrapup', 'ref.png', 'hash', 'POST', '/image-to-3d')
                with self.assertRaises(RuntimeError):
                    guard.submit_guarded(request, '2026-10-01', 'terrapup', 'ref.png', 'hash', 'POST', '/retexture')
                self.assertEqual(len(calls), 30)
                def uncertain(*args):
                    raise TimeoutError('request sent, response unknown')
                with self.assertRaises(TimeoutError):
                    guard.submit_guarded(uncertain, '2026-10-02', 'terrapup', 'ref.png', 'hash', 'POST', '/refine')
                ledger = json.loads(guard.LEDGER.read_text())
                self.assertEqual(len(ledger['tasks']), 31)
                self.assertEqual(ledger['tasks'][-1]['status'], 'submission_uncertain_counts_against_cap')
                self.assertIsNone(ledger['tasks'][-1]['task_id'])
                self.assertFalse(guard.LEDGER.with_suffix('.lock').exists())
            finally:
                guard.LEDGER = original


if __name__ == '__main__':
    unittest.main()
