"""Offline sensitivity controls; synthetic cues are never actual-game proof."""
import importlib.util
import math
from pathlib import Path
import struct
import tempfile
import unittest
import wave

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("f20_audio", ROOT / "tools/audio/verify_f20_stir.py")
VERIFY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VERIFY)


class CueVerification(unittest.TestCase):
    def check_cue(self, hz=98, seconds=2.5, gain=0.014, envelope=True, tail=False):
        rate = 44100
        data = bytearray()
        for index in range(int(5.3 * rate)):
            elapsed = index / rate
            sample = 0.0
            if elapsed < seconds:
                sample = gain * math.sin(math.tau * hz * elapsed)
                if envelope:
                    sample *= math.sin(math.pi * elapsed / seconds)
            if tail and 3 < elapsed < 3.5:
                sample = 0.01 * math.sin(math.tau * 200 * elapsed)
            value = max(-32768, min(32767, int(sample * 32768)))
            data.extend(struct.pack("<hh", value, value))
        with tempfile.TemporaryDirectory(prefix="f20-audio-controls-") as directory:
            self.assertEqual(Path(directory).resolve().parent, Path(tempfile.gettempdir()).resolve())
            path = Path(directory) / "synthetic-control.wav"
            with wave.open(str(path), "wb") as clip:
                clip.setnchannels(2)
                clip.setsampwidth(2)
                clip.setframerate(rate)
                clip.writeframes(data)
            return VERIFY.verify(path, ROOT / "data/config/portals.json")

    def test_matching_reference(self):
        self.assertEqual(self.check_cue()["verdict"], "PASS")

    def test_silence(self):
        with self.assertRaisesRegex(ValueError, "silent"):
            self.check_cue(gain=0)

    def test_wrong_frequency(self):
        self.assertFalse(self.check_cue(hz=180)["checks"]["configured_frequency"])

    def test_wrong_duration(self):
        self.assertFalse(self.check_cue(seconds=1.5)["checks"]["configured_duration"])

    def test_wrong_envelope(self):
        self.assertFalse(self.check_cue(envelope=False)["checks"]["configured_half_sine_envelope_and_tone"])

    def test_clipping(self):
        self.assertFalse(self.check_cue(gain=1.5)["checks"]["no_clipped_samples"])

    def test_sound_after_cue(self):
        self.assertFalse(self.check_cue(tail=True)["checks"]["silence_after_cue"])


if __name__ == "__main__":
    unittest.main()
