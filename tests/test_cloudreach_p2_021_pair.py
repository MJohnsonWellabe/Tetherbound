"""CPU-only receipt fixtures; they do not represent rendered game evidence."""
import importlib.util
import json
import struct
import tempfile
import unittest
import zlib
from pathlib import Path
from types import SimpleNamespace

MODULE_PATH = Path(__file__).resolve().parents[1] / 'tools/validate_cloudreach_p2_021_pair.py'
SPEC = importlib.util.spec_from_file_location('cloudreach_p2_021_validator', MODULE_PATH)
validator = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(validator)


def png_1080p():
    def chunk(kind, payload):
        return struct.pack('>I', len(payload)) + kind + payload + struct.pack('>I', zlib.crc32(kind + payload) & 0xffffffff)
    raw = (b'\x00' + bytes(1920 * 4)) * 1080
    return (validator.PNG + chunk(b'IHDR', struct.pack('>IIBBBBB', 1920, 1080, 8, 6, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(raw, 6)) + chunk(b'IEND', b''))


class FourLegReceiptTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.source = 'a' * 40
        self.manifests = {}
        image_bytes = png_1080p()
        self.ids = []
        rows = []
        for destination in range(1, 13):
            for time_name in validator.TIMES:
                for weather_name in validator.WEATHER:
                    for view_name in validator.VIEWS:
                        frame_id = f'cr_{destination:02d}_{time_name}_{weather_name}_{view_name}'
                        self.ids.append(frame_id)
                        rows.append({'frame_id': frame_id, 'destination_index': destination,
                                     'position_xz': [float(destination), 0.0], 'view_heading_deg': 0.0,
                                     'time': time_name, 'weather': weather_name, 'view': view_name,
                                     'player_position': [0.0, 0.0, 0.0], 'camera_position': [0.0, 1.0, 4.0],
                                     'camera_rig_transform': [0.0], 'camera_transform': [0.0],
                                     'camera_player_distance_m': 4.0,
                                     'observed_clock': {'time_of_day': time_name},
                                     'observed_weather': weather_name, 'on_floor': True,
                                     'file': 'frame.png'})
        self.rows = rows
        for variant in ('baseline', 'p2_021_candidate'):
            for preset in ('High', 'Medium'):
                directory = self.root / variant / preset
                directory.mkdir(parents=True)
                (directory / 'frame.png').write_bytes(image_bytes)
                candidate = variant == 'p2_021_candidate'
                manifest = {
                    'complete': True, 'failures': [], 'biome_id': 'cloudreach',
                    'candidate_preview': candidate,
                    'f40_visual_candidate_preview': False,
                    'p2_033_pickup_candidate_preview': False,
                    'p2_030_surface_candidate_preview': False,
                    'p2_021_open_terrain_candidate_preview': candidate,
                    'graphics_capture': {'preset': preset, 'renderer': 'forward_plus',
                        'resolution': [1920, 1080], 'source_commit': self.source,
                        'graphics_config_sha256': 'b' * 64, 'adapter': 'Fixture adapter'},
                    'resolution': [1920, 1080], 'candidate_config_sha256': 'c' * 64,
                    'p2_021_candidate_config_sha256': 'd' * 64,
                    'f40_revision': 'fixture-r1',
                    'f40_isolated_save_fixture': f'user://f40_capture_fixture_{variant}_{preset}/',
                    'capture_plan': {'times': list(validator.TIMES), 'weather': list(validator.WEATHER),
                        'views': list(validator.VIEWS), 'minimum_frames': 384,
                        'weather_settle_frames': 24},
                    'planned_frame_ids': list(self.ids), 'planned_frame_count': 384,
                    'captured_frame_count': 384, 'frames': [dict(row) for row in rows],
                }
                path = directory / 'manifest.json'
                path.write_text(json.dumps(manifest), encoding='utf-8')
                self.manifests[(variant, preset)] = path
        self.args = SimpleNamespace(project_root=self.root, source_commit=self.source,
            baseline_high=self.manifests[('baseline', 'High')],
            baseline_medium=self.manifests[('baseline', 'Medium')],
            candidate_high=self.manifests[('p2_021_candidate', 'High')],
            candidate_medium=self.manifests[('p2_021_candidate', 'Medium')],
            output=self.root / 'audit.json')

    def tearDown(self):
        self.temp.cleanup()

    def mutate(self, variant, preset, change):
        path = self.manifests[(variant, preset)]
        value = json.loads(path.read_text(encoding='utf-8'))
        change(value)
        path.write_text(json.dumps(value), encoding='utf-8')

    def test_complete_four_leg_matrix_produces_hash_bound_audit(self):
        audit = validator.validate(self.args)
        self.assertTrue(audit['complete'])
        self.assertEqual(384, len(audit['legs']['baseline/High']['frames']))
        self.assertEqual(64, len(next(iter(audit['legs']['baseline/High']['frames'].values()))['png_sha256']))

    def test_rejects_missing_frame_even_when_manifest_says_complete(self):
        self.mutate('baseline', 'High', lambda value: value['frames'].pop())
        with self.assertRaisesRegex(validator.ReceiptError, 'exactly 384'):
            validator.validate(self.args)

    def test_rejects_candidate_flag_drift(self):
        self.mutate('p2_021_candidate', 'Medium', lambda value: value.update(candidate_preview=False))
        with self.assertRaisesRegex(validator.ReceiptError, 'candidate_preview'):
            validator.validate(self.args)

    def test_rejects_observed_time_and_weather_mismatch(self):
        def bad_clock(value):
            value['frames'][0]['observed_clock']['time_of_day'] = 'night'
        self.mutate('baseline', 'High', bad_clock)
        with self.assertRaisesRegex(validator.ReceiptError, 'observed time'):
            validator.validate(self.args)

    def test_rejects_changed_source_pin(self):
        self.mutate('baseline', 'Medium', lambda value: value['graphics_capture'].update(source_commit='e' * 40))
        with self.assertRaisesRegex(validator.ReceiptError, 'source pin'):
            validator.validate(self.args)

    def test_rejects_png_with_corrupt_chunk_crc(self):
        path = self.root / 'baseline' / 'High' / 'frame.png'
        data = bytearray(path.read_bytes()); data[-1] ^= 0x01; path.write_bytes(data)
        with self.assertRaisesRegex(validator.ReceiptError, 'CRC'):
            validator.validate(self.args)


if __name__ == '__main__':
    unittest.main()
