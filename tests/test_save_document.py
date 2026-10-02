import json
from pathlib import Path
import struct
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools/net"))
import save_document as codec


class SaveDocumentTests(unittest.TestCase):
    def test_shared_native_wire_fixture_retains_bits_and_integer_boundaries(self):
        encoded = json.loads((ROOT / "tests/fixtures/save-codec-v1.json").read_bytes())
        value = codec.decode(encoded)
        self.assertEqual(value["care"], 100.0 - (1.0 / 60.0) * 0.2)
        self.assertEqual(struct.pack("<d", value["negative_zero"]).hex(), "0000000000000080")
        self.assertEqual(struct.pack("<d", value["subnormal"]).hex(), "0100000000000000")
        self.assertEqual(value["min_int"], -(2**63))
        self.assertEqual(value["max_int"], 2**63 - 1)
        self.assertEqual(value["collision"], {"$tb_float64": "original text"})
        self.assertEqual(codec.encode(value), encoded)

    def test_plain_json_never_interprets_gameplay_keys_as_codec_tags(self):
        value = {"version": 28, "$tb_float64": "original text"}
        self.assertIs(codec.decode(value), value)

    def test_malformed_envelopes_do_not_fall_back_to_plain_json(self):
        for payload in ({"x": {codec.FLOAT: "000000000000f07f"}},
                        {"x": {codec.INTEGER: "9223372036854775808"}},
                        {"x": {codec.FLOAT: "0" * 16, "extra": 1}},
                        {"x": {codec.DICTIONARY: [[codec.FLOAT, "a"], [codec.FLOAT, "b"]]}},
                        {"x": 0.25}, {"x": 10**400}):
            with self.assertRaises(ValueError):
                codec.decode({"format": codec.FORMAT, "codec_version": 1, "payload": payload})
        for version in (True, 2, "1"):
            with self.assertRaises(ValueError):
                codec.decode({"format": codec.FORMAT, "codec_version": version, "payload": {}})


if __name__ == "__main__":
    unittest.main()
