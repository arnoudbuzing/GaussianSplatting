PacletDirectoryLoad["/Users/arnoudb/github/GaussianSplatting"];
Needs["ArnoudBuzing`GaussianSplatting`"];
pos = PLYGaussianPositions["tests/fixtures/seashell.ply"];
Print[MinMax /@ Transpose[Normal[pos]]];
