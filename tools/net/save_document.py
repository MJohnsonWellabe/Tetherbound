"""Read/write the production lossless save envelope; plain JSON remains valid.

Keep the wire contract in sync with scripts/save/save_document.gd. This is for
tools that explicitly mutate saved fixtures, not byte-copying evidence capture.
"""
import math
import re
import struct

FORMAT = "tetherbound-save"
FLOAT, INTEGER, DICTIONARY = "$tb_float64", "$tb_int64", "$tb_dictionary"
RESERVED = {FLOAT, INTEGER, DICTIONARY}
SAFE = 2**53 - 1


def _require(ok, message="Invalid lossless save document"):
    if not ok:
        raise ValueError(message)


def encode(data):
    _require(isinstance(data, dict))
    return {"format": FORMAT, "codec_version": 1, "payload": _encode(data, 0)}


def _encode(value, depth):
    _require(depth <= 128)
    if value is None or type(value) in (bool, str):
        return value
    if type(value) is int:
        _require(-(2**63) <= value < 2**63)
        return value if -SAFE <= value <= SAFE else {INTEGER: str(value)}
    if type(value) is float:
        _require(math.isfinite(value))
        return {FLOAT: struct.pack("<d", value).hex()}
    if isinstance(value, list):
        return [_encode(item, depth + 1) for item in value]
    _require(isinstance(value, dict) and all(type(key) is str for key in value))
    result = {key: _encode(item, depth + 1) for key, item in value.items()}
    return {DICTIONARY: list(map(list, result.items()))} if RESERVED.intersection(value) else result


def decode(outer):
    _require(isinstance(outer, dict))
    if outer.get("format") != FORMAT:
        return outer
    _require(set(outer) == {"format", "codec_version", "payload"})
    _require(type(outer["codec_version"]) in (int, float) and outer["codec_version"] == 1)
    result = _decode(outer["payload"], 0)
    _require(isinstance(result, dict))
    return result


def _decode(value, depth):
    _require(depth <= 128)
    if value is None or type(value) in (bool, str):
        return value
    if type(value) in (int, float):
        _require(-SAFE <= value <= SAFE and math.isfinite(value) and int(value) == value)
        return int(value)
    if isinstance(value, list):
        return [_decode(item, depth + 1) for item in value]
    _require(isinstance(value, dict))
    if FLOAT in value:
        text = value[FLOAT]
        _require(len(value) == 1 and type(text) is str and re.fullmatch(r"[0-9a-f]{16}", text))
        result = struct.unpack("<d", bytes.fromhex(text))[0]
        _require(math.isfinite(result))
        return result
    if INTEGER in value:
        text = value[INTEGER]
        _require(len(value) == 1 and type(text) is str and re.fullmatch(r"-?[0-9]{1,19}", text))
        result = int(text)
        _require(str(result) == text and -(2**63) <= result < 2**63 and abs(result) > SAFE)
        return result
    if DICTIONARY in value:
        _require(len(value) == 1 and isinstance(value[DICTIONARY], list))
        result = {}
        for pair in value[DICTIONARY]:
            _require(isinstance(pair, list) and len(pair) == 2 and type(pair[0]) is str and pair[0] not in result)
            result[pair[0]] = _decode(pair[1], depth + 1)
        _require(RESERVED.intersection(result))
        return result
    return {key: _decode(item, depth + 1) for key, item in value.items()}
