"""CPU fixtures for binding review citations to validated frame bytes."""
import importlib.util
import hashlib
import tempfile
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).resolve().parents[1] / 'tools/rescore_cloudreach_f40.py'
SPEC = importlib.util.spec_from_file_location('cloudreach_f40_rescorer', MODULE_PATH)
scorer = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(scorer)


class ScorerEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.image = Path(self.temp.name) / 'frame.png'
        self.image.write_bytes(b'fixture frame bytes')
        self.digest = hashlib.sha256(self.image.read_bytes()).hexdigest()
        self.frames = {'baseline/High': {'frame-1': {'png_sha256': self.digest,
            'image': str(self.image)}}}
        self.ref = {'variant': 'baseline', 'preset': 'High', 'frame_id': 'frame-1',
                    'png_sha256': self.digest, 'note': 'Route silhouette remains readable.'}

    def tearDown(self):
        self.temp.cleanup()

    def test_accepts_actual_audited_frame_hash_and_note(self):
        result = scorer.validate_reference(self.ref, self.frames)
        self.assertEqual(str(self.image), result['image'])

    def test_rejects_arbitrary_nonempty_evidence_text(self):
        with self.assertRaisesRegex(ValueError, 'structured reference to an audited frame'):
            scorer.validate_reference('looks good', self.frames)

    def test_rejects_hash_mismatch(self):
        bad = {**self.ref, 'png_sha256': '0' * 64}
        with self.assertRaisesRegex(ValueError, 'matching PNG hash'):
            scorer.validate_reference(bad, self.frames)

    def test_rejects_changed_file_after_audit(self):
        self.image.write_bytes(b'changed frame bytes')
        with self.assertRaisesRegex(ValueError, 'changed on disk'):
            scorer.validate_reference(self.ref, self.frames)

    def test_review_requires_all_four_validated_capture_legs(self):
        frames = {}
        refs = []
        for variant in scorer.VARIANTS:
            for preset in scorer.PRESETS:
                key = f'{variant}/{preset}'
                frames[key] = {'frame-1': {'png_sha256': self.digest, 'image': str(self.image)}}
                refs.append({**self.ref, 'variant': variant, 'preset': preset})
        self.assertEqual(4, len(scorer.validate_review_evidence(refs, frames)))
        with self.assertRaisesRegex(ValueError, 'baseline and candidate High and Medium'):
            scorer.validate_review_evidence(refs[:1], frames)


if __name__ == '__main__':
    unittest.main()
