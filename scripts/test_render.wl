PacletDirectoryLoad["/Users/arnoudb/github/GaussianSplatting"];
Needs["ArnoudBuzing`GaussianSplatting`"];

Print["Starting render..."];
img = PLYGaussianRender["tests/fixtures/seashell.ply", 512, 512];

If[Head[img] === Image,
  Print["Render successful! Image dimensions: ", ImageDimensions[img]];
  Export["render_output.png", img];
  Print["Exported to render_output.png"];
,
  Print["Render failed. Result: ", img];
];
