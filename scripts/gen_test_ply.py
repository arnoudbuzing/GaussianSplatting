#!/usr/bin/env python3
"""Generate a minimal 3DGS PLY fixture with N Gaussians for testing."""
import struct, os

# The exact PLY properties used by wgpu-3dgs-core (Inria format)
PROPERTIES = [
    "x", "y", "z",
    "nx", "ny", "nz",
    "f_dc_0", "f_dc_1", "f_dc_2",
    *[f"f_rest_{i}" for i in range(45)],
    "opacity",
    "scale_0", "scale_1", "scale_2",
    "rot_0", "rot_1", "rot_2", "rot_3",
]

N = 5  # number of Gaussians

# Build header
header_lines = [
    "ply",
    "format binary_little_endian 1.0",
    f"element vertex {N}",
] + [f"property float {p}" for p in PROPERTIES] + ["end_header", ""]

header = "\n".join(header_lines).encode("ascii")

# Each Gaussian: one float per property, all zeros except rotation w=1
n_props = len(PROPERTIES)
rot_0_idx = PROPERTIES.index("rot_0")

rows = []
for _ in range(N):
    vals = [0.0] * n_props
    vals[rot_0_idx] = 1.0  # valid unit quaternion w=1
    rows.append(struct.pack(f"{n_props}f", *vals))

os.makedirs("tests/fixtures", exist_ok=True)
with open("tests/fixtures/small.ply", "wb") as f:
    f.write(header)
    for row in rows:
        f.write(row)

print(f"Written tests/fixtures/small.ply with {N} Gaussians, {n_props} properties each")
print(f"Header bytes: {len(header)}, data bytes: {N * n_props * 4}")
