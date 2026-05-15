PacletDirectoryLoad["/Users/arnoudb/github/GaussianSplatting"];
Needs["ArnoudBuzing`GaussianSplatting`"];

file = "tests/fixtures/rainbow.ply";

Print["--- First Render (Cold) ---"];
AbsoluteTiming[PLYGaussianRender[file];] // Print

Print["--- Second Render (Warm) ---"];
AbsoluteTiming[PLYGaussianRender[file];] // Print

Print["--- Third Render (Warm) ---"];
AbsoluteTiming[PLYGaussianRender[file];] // Print
