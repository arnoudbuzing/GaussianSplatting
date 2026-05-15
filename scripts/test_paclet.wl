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

(* Test 2: nonexistent file should return $Failed *)
badResult = PLYGaussianCount["/nonexistent/file.ply"]
If[badResult === $Failed,
  Print["PASS: Missing file returns $Failed"],
  Print["FAIL: Expected $Failed for missing file, got: ", badResult]
]
