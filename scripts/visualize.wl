PacletDirectoryLoad["/Users/arnoudb/github/GaussianSplatting"]
Needs["ArnoudBuzing`GaussianSplatting`"]

file = "/Users/arnoudb/github/GaussianSplatting/tests/fixtures/small.ply"

PLYGaussianGraphics[filename_String] := Module[
  {pos, cols, rgb},
  pos = PLYGaussianPositions[filename];
  cols = PLYGaussianColors[filename];
  If[pos === $Failed || cols === $Failed, Return[$Failed]];
  rgb = Normal[cols][[All, 1;;3]];
  Graphics3D[
    {PointSize[Medium], Point[Normal[pos], VertexColors -> rgb]},
    Boxed -> False,
    Lighting -> "Neutral",
    Background -> Black,
    Axes -> True
  ]
]

PLYGaussianImage[filename_String, res_Integer:32] := Module[
  {pos, cols, rgb, min, max, scaledPos, grid},
  pos = Normal[PLYGaussianPositions[filename]];
  cols = Normal[PLYGaussianColors[filename]];
  If[pos === $Failed || cols === $Failed, Return[$Failed]];
  rgb = cols[[All, 1;;3]];
  
  min = Min /@ Transpose[pos];
  max = Max /@ Transpose[pos];
  
  (* Handle case where min==max *)
  scaledPos = If[Max[max - min] == 0,
    Table[{1, 1, 1}, Length[pos]],
    Transpose[Round[1 + (res - 1) * MapThread[If[#3==#2, 0*#1, (#1 - #2)/(#3 - #2)]&, {Transpose[pos], min, max}]]]
  ];
  
  grid = Normal[SparseArray[
    Join @@ Table[Thread[Map[Append[#, i]&, scaledPos] -> rgb[[All, i]]], {i, 3}], 
    {res, res, res, 3}, 
    0.
  ]];
  Image3D[grid, ColorSpace -> "RGB"]
]

g = PLYGaussianGraphics[file]
img = PLYGaussianImage[file]

Print["Graphics3D generated: ", Head[g]]
Print["Image3D generated: ", Head[img]]

Export["scripts/output_g3d.png", g]
Export["scripts/output_i3d.png", img]
Print["Exported!"]
