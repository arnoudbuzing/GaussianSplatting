points = Flatten[Table[{x, y, z}, {x, -1, 1, 0.5}, {y, -1, 1, 0.5}, {z, -1, 1, 0.5}], 2];
numPoints = Length[points];

(* SH0 = (Color - 0.5) / 0.2820948 *)
colors = Map[ (# + 1)/2 &, points];
sh0 = Map[ (# - 0.5) / 0.2820948 &, colors];

header = {
  "ply",
  "format ascii 1.0",
  "element vertex " <> ToString[numPoints],
  "property float x", "property float y", "property float z",
  "property float f_dc_0", "property float f_dc_1", "property float f_dc_2",
  "property float opacity",
  "property float scale_0", "property float scale_1", "property float scale_2",
  "property float rot_0", "property float rot_1", "property float rot_2", "property float rot_3",
  "end_header"
};

rows = Table[
  {
    points[[i, 1]], points[[i, 2]], points[[i, 3]],
    sh0[[i, 1]], sh0[[i, 2]], sh0[[i, 3]],
    10.0, (* opacity *)
    -2.0, -2.0, -2.0, (* scale - log(0.13) approx *)
    1.0, 0.0, 0.0, 0.0 (* rotation *)
  },
  {i, numPoints}
];

content = Join[header, Map[StringRiffle[Map[ToString[NumberForm[#, {Infinity, 6}]]&, #], " "]&, rows]];
Export["tests/fixtures/rainbow.ply", StringRiffle[content, "\n"], "String"];
Print["Generated tests/fixtures/rainbow.ply with ", numPoints, " points."];
