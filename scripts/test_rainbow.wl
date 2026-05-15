PacletDirectoryLoad["/Users/arnoudb/github/GaussianSplatting"];
Needs["ArnoudBuzing`GaussianSplatting`"];

file = "tests/fixtures/rainbow.ply";
Print["Rendering Rainbow Cube (Splat mode)..."];
img = PLYGaussianRender[file, "DisplayMode" -> "Splat", "Width" -> 512, "Height" -> 512];
Export["rainbow_render.png", img];

colors = Union[Flatten[ImageData[img], 1]];
Print["Number of colors in rainbow render: ", Length[colors]];
If[Length[colors] > 2,
  Print["Success! Colors detected."];
  Print["Sample colors: ", Take[colors, Min[5, Length[colors]]]];
,
  Print["Failed. Still mostly black or monotone."];
];
