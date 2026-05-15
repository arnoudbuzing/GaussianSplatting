PacletDirectoryLoad["/Users/arnoudb/github/GaussianSplatting"];
Needs["ArnoudBuzing`GaussianSplatting`"];
file = "tests/fixtures/seashell.ply";
Print["Starting single render..."];
img = PLYGaussianRender[file, "Width" -> 128, "Height" -> 128];
Print["Head of result: ", Head[img]];
If[Head[img] === Image, Export["single_test.png", img]];
Print["Done."];
