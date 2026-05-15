(* test_paclet.wl - Basic smoke test for GaussianSplatting paclet *)

PacletDirectoryLoad["/Users/arnoudb/github/GaussianSplatting"]
Needs["ArnoudBuzing`GaussianSplatting`"]

(* Test 1: valid PLY file *)
testFile = "/Users/arnoudb/github/GaussianSplatting/tests/fixtures/small.ply"
result = PLYGaussianCount[testFile]
Print["PLYGaussianCount result: ", result]
If[IntegerQ[result] && result >= 0,
  Print["PASS: Got integer count = ", result],
  Print["FAIL: Expected non-negative integer, got: ", result]
]

(* Test 1b: valid PLY positions *)
Print["\nTesting PLYGaussianPositions..."];
positions = PLYGaussianPositions[testFile]
Print["PLYGaussianPositions returned head: ", Head[positions]]
If[Head[positions] === NumericArray, 
  Print["Dimensions: ", Dimensions[positions]];
  Print["First 2 positions: ", Normal[positions[[1;;2]]]];
  If[Dimensions[positions] === {5, 3}, 
    Print["PASS: Got {5, 3} numeric array"],
    Print["FAIL: Incorrect dimensions"]
  ],
  Print["FAIL: Did not return a NumericArray"]
]


Print["\nTesting PLYGaussianColors..."];
colors = PLYGaussianColors[testFile];
If[Head[colors] === NumericArray && Dimensions[colors] === {5, 4},
  Print["PASS: Got {5, 4} numeric array for colors"],
  Print["FAIL: Incorrect output for colors"]
];

Print["\nTesting PLYGaussianOpacities..."];
opacities = PLYGaussianOpacities[testFile];
If[Head[opacities] === NumericArray && Dimensions[opacities] === {5},
  Print["PASS: Got {5} numeric array for opacities"],
  Print["FAIL: Incorrect output for opacities"]
];

Print["\nTesting PLYGaussianScales..."];
scales = PLYGaussianScales[testFile];
If[Head[scales] === NumericArray && Dimensions[scales] === {5, 3},
  Print["PASS: Got {5, 3} numeric array for scales"],
  Print["FAIL: Incorrect output for scales"]
];

Print["\nTesting PLYGaussianRotations..."];
rotations = PLYGaussianRotations[testFile];
If[Head[rotations] === NumericArray && Dimensions[rotations] === {5, 4},
  Print["PASS: Got {5, 4} numeric array for rotations"],
  Print["FAIL: Incorrect output for rotations"]
];

(* Test 2: nonexistent file should return $Failed *)
badResult = PLYGaussianCount["/nonexistent/file.ply"]
If[badResult === $Failed,
  Print["PASS: Missing file returns $Failed"],
  Print["FAIL: Expected $Failed for missing file, got: ", badResult]
]
