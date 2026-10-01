"""Reproducible IEEE float32 source-math controls; does not execute Godot."""
import json
import math
import struct


def f32(value):
    return struct.unpack("f", struct.pack("f", value))[0]


def add(a, b):
    return f32(a + b)


def mul(a, b):
    return f32(a * b)


def dot(a, b):
    result = mul(a[0], b[0])
    for index in range(1, len(a)):
        result = add(result, mul(a[index], b[index]))
    return result


def normalized(q):
    reciprocal = f32(1.0 / f32(math.sqrt(dot(q, q))))
    return tuple(mul(component, reciprocal) for component in q)


def axis_angle(axis, angle):
    half = mul(f32(angle), 0.5)
    sine = f32(math.sin(half))
    return normalized(tuple(mul(x, sine) for x in axis) + (f32(math.cos(half)),))


def product(a, b):
    x, y, z, w = a
    bx, by, bz, bw = b
    return (
        add(add(add(mul(w, bx), mul(x, bw)), mul(y, bz)), -mul(z, by)),
        add(add(add(mul(w, by), mul(y, bw)), mul(z, bx)), -mul(x, bz)),
        add(add(add(mul(w, bz), mul(z, bw)), mul(x, by)), -mul(y, bx)),
        add(add(add(mul(w, bw), -mul(x, bx)), -mul(y, by)), -mul(z, bz)),
    )


def distances(actual, expected):
    actual, expected = normalized(actual), normalized(expected)
    inverse = tuple(-x for x in expected[:3]) + (expected[3],)
    relative = normalized(product(inverse, actual))
    vector_length = f32(math.sqrt(dot(relative[:3], relative[:3])))
    robust = 2.0 * math.atan2(vector_length, abs(relative[3]))
    d = dot(actual, expected)
    old_argument = add(mul(mul(d, d), 2.0), -1.0)
    old = f32(math.acos(max(-1.0, min(1.0, old_argument))))
    return robust, old


def controls():
    expected = axis_angle((0.0, 1.0, 0.0), math.pi)
    cases = []
    for sign in (1.0, -1.0):
        for delta in (0.0, -0.00005, 0.00005, -0.0002, 0.0002, -0.0003, 0.0003):
            actual = axis_angle((0.0, 1.0, 0.0), sign * math.pi + delta)
            cases.append((f"yaw {sign:+g}PI {delta:+.5f}", actual, abs(delta) <= 0.0001))
    cases.extend([
        ("identity", axis_angle((0.0, 1.0, 0.0), 0.0), False),
        ("quarter turn", axis_angle((0.0, 1.0, 0.0), math.pi / 2.0), False),
        ("wrong axis X", axis_angle((1.0, 0.0, 0.0), math.pi), False),
        ("wrong axis Z", axis_angle((0.0, 0.0, 1.0), math.pi), False),
        ("opposite quaternion sign", tuple(-x for x in expected), True),
    ])
    for axis, name in [((1.0, 0.0, 0.0), "X"), ((0.0, 0.0, 1.0), "Z")]:
        for delta in (-0.00005, 0.00005, -0.0002, 0.0002, -0.0003, 0.0003):
            actual = product(expected, axis_angle(axis, delta))
            cases.append((f"relative {name} tilt {delta:+.5f}", actual, abs(delta) <= 0.0001))
    results = []
    for name, actual, should_pass in cases:
        robust, old = distances(actual, expected)
        passed = robust <= 0.0001
        assert passed == should_pass, (name, robust, should_pass)
        results.append({"case": name, "robust_radians": robust,
                        "acos_dot_radians": old, "expected_pass": should_pass,
                        "robust_pass": passed, "acos_dot_pass": old <= 0.0001})
    assert any(not row["expected_pass"] and row["acos_dot_pass"] for row in results)
    return {"status": "SOURCE_MATH_ONLY_PASS", "tolerance_radians": 0.0001,
            "arithmetic": "float32 operands, products, sums, normalization and vector length; double atan2 on float32 inputs",
            "scope": "quaternion distance controls, not Godot basis extraction or native test execution",
            "controls": results}


if __name__ == "__main__":
    print(json.dumps(controls(), indent=2))
