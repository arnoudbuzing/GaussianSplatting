PacletDirectoryLoad["/Users/arnoudb/github/GaussianSplatting"];
Needs["ArnoudBuzing`GaussianSplatting`"];

file = "tests/fixtures/seashell.ply";

Print["Rendering Side View..."];
img1 = PLYGaussianRender[file, "Yaw" -> Pi/2, "Width" -> 256, "Height" -> 256];
Export["side_view.png", img1];

Print["Rendering Top View..."];
img2 = PLYGaussianRender[file, "Pitch" -> Pi/2, "Width" -> 256, "Height" -> 256];
Export["top_view.png", img2];

Print["Rendering Default View..."];
img3 = PLYGaussianRender[file, "Width" -> 256, "Height" -> 256];
Export["default_view.png", img3];

Print["Done."];
