(* ::Package:: *)

(* GaussianSplatting - Wolfram Language bindings for wgpu-3dgs-core *)

BeginPackage["ArnoudBuzing`GaussianSplatting`"]

(* Public symbol declarations *)

PLYGaussianCount::usage = "PLYGaussianCount[filename] loads a 3D Gaussian Splatting PLY file and returns the number of Gaussians it contains.";
PLYGaussianPositions::usage = "PLYGaussianPositions[filename] returns an N x 3 NumericArray of the positions of all Gaussians.";
PLYGaussianColors::usage = "PLYGaussianColors[filename] returns an N x 4 NumericArray of the colors (RGBA) of all Gaussians.";
PLYGaussianOpacities::usage = "PLYGaussianOpacities[filename] returns a NumericArray of the opacities of all Gaussians.";
PLYGaussianScales::usage = "PLYGaussianScales[filename] returns an N x 3 NumericArray of the scales of all Gaussians.";
PLYGaussianRotations::usage = "PLYGaussianRotations[filename] returns an N x 4 NumericArray of the rotations of all Gaussians.";

PLYGaussianGraphics::usage = "PLYGaussianGraphics[filename] returns a Graphics3D Point primitive representation of the Gaussian splats.";
PLYGaussianImage::usage = "PLYGaussianImage[filename, res:32] returns an Image3D voxel representation of the Gaussian splats using a grid of size res.";
PLYGaussianRender::usage = "PLYGaussianRender[filename, opts] returns an Image representation of the Gaussian splats rendered via WGPU.";
SPZGaussianRender::usage = "SPZGaussianRender[filename, opts] returns an Image representation of the Gaussian splats rendered via WGPU.";
PLYGaussianExplore::usage = "PLYGaussianExplore[filename] opens an interactive interface to explore the Gaussian splat model.";

Options[PLYGaussianRender] = {
  "Position" -> {0, 0, 3},
  "Pitch" -> 0,
  "Yaw" -> Pi,
  "FOV" -> Pi/4,
  "Width" -> 512,
  "Height" -> 512,
  "DisplayMode" -> "Splat"
};

Begin["`Private`"]

(* ---- Library loading ---- *)

$libraryName = "gaussian_splatting";

$libraryDirectory = FileNameJoin[{
  PacletObject["ArnoudBuzing/GaussianSplatting"]["Location"],
  "LibraryResources",
  $SystemID
}];

(* Determine the platform-appropriate library filename *)
$libExt = Switch[$OperatingSystem,
  "MacOSX",   ".dylib",
  "Windows",  ".dll",
  _,          ".so"   (* Linux and others *)
];

$libraryPath = FileNameJoin[{
  $libraryDirectory,
  "lib" <> $libraryName <> $libExt
}];

(* Load the native library and bind LibraryLink functions *)
$libraryLoaded = False;

loadLibrary[] := Module[{},
  If[$libraryLoaded, Return[]];
  Check[
    $PLYGaussianCountFn = LibraryFunctionLoad[
      $libraryPath,
      "wl_ply_gaussian_count",
      {"UTF8String"},  (* input: file path *)
      Integer          (* output: count, or -1 on error *)
    ];
    $PLYGaussianPositionsFn = LibraryFunctionLoad[
      $libraryPath,
      "wl_ply_gaussian_positions",
      {"UTF8String"},
      LibraryDataType[NumericArray, "Real32"]
    ];
    $PLYGaussianColorsFn = LibraryFunctionLoad[
      $libraryPath,
      "wl_ply_gaussian_colors",
      {"UTF8String"},
      LibraryDataType[NumericArray, "Real32"]
    ];
    $PLYGaussianOpacitiesFn = LibraryFunctionLoad[
      $libraryPath,
      "wl_ply_gaussian_opacities",
      {"UTF8String"},
      LibraryDataType[NumericArray, "Real32"]
    ];
    $PLYGaussianScalesFn = LibraryFunctionLoad[
      $libraryPath,
      "wl_ply_gaussian_scales",
      {"UTF8String"},
      LibraryDataType[NumericArray, "Real32"]
    ];
    $PLYGaussianRotationsFn = LibraryFunctionLoad[
      $libraryPath,
      "wl_ply_gaussian_rotations",
      {"UTF8String"},
      LibraryDataType[NumericArray, "Real32"]
    ];
    $PLYGaussianRenderFn = LibraryFunctionLoad[
      $libraryPath,
      "wl_ply_gaussian_render",
      {"UTF8String", Integer, Integer, Real, Real, Real, Real, Real, Real, Integer},
      LibraryDataType[NumericArray, "UnsignedInteger8"]
    ];
    $libraryLoaded = True,
    Message[PLYGaussianCount::load, $libraryPath];
    $libraryLoaded = False
  ]
];

PLYGaussianCount::load = "Failed to load GaussianSplatting library from `1`.";
PLYGaussianCount::badfile = "File not found or not a valid PLY file: `1`.";
PLYGaussianCount::err = "Error reading PLY file: `1`.";

PLYGaussianCount[filename_String] := Module[{path, result},
  loadLibrary[];
  If[!$libraryLoaded,
    Return[$Failed]
  ];
  path = ExpandFileName[filename];
  If[!FileExistsQ[path],
    Message[PLYGaussianCount::badfile, path];
    Return[$Failed]
  ];
  result = Quiet[
    Check[$PLYGaussianCountFn[path], $Failed, LibraryFunction::rterr],
    {LibraryFunction::rterr}
  ];
  If[result === $Failed || (IntegerQ[result] && result < 0),
    Message[PLYGaussianCount::err, path];
    $Failed,
    result
  ]
]

PLYGaussianPositions::load = "Failed to load GaussianSplatting library.";
PLYGaussianPositions::badfile = "File not found or not a valid PLY file: `1`.";
PLYGaussianPositions::err = "Error reading PLY file positions: `1`.";

PLYGaussianPositions[filename_String] := Module[{path, result},
  loadLibrary[];
  If[!$libraryLoaded, Return[$Failed]];
  path = ExpandFileName[filename];
  If[!FileExistsQ[path],
    Message[PLYGaussianPositions::badfile, path];
    Return[$Failed]
  ];
  result = Quiet[
    Check[$PLYGaussianPositionsFn[path], $Failed, LibraryFunction::rterr],
    {LibraryFunction::rterr}
  ];
  If[result === $Failed || Length[result] == 0,
    Message[PLYGaussianPositions::err, path];
    $Failed,
    ArrayReshape[result, {Length[result] / 3, 3}]
  ]
]

PLYGaussianColors[filename_String] := Module[{path, result},
  loadLibrary[];
  If[!$libraryLoaded, Return[$Failed]];
  path = ExpandFileName[filename];
  If[!FileExistsQ[path], Return[$Failed]];
  result = Quiet[Check[$PLYGaussianColorsFn[path], $Failed, LibraryFunction::rterr], {LibraryFunction::rterr}];
  If[result === $Failed || Length[result] == 0, $Failed, ArrayReshape[result, {Length[result] / 4, 4}]]
]

PLYGaussianOpacities[filename_String] := Module[{path, result},
  loadLibrary[];
  If[!$libraryLoaded, Return[$Failed]];
  path = ExpandFileName[filename];
  If[!FileExistsQ[path], Return[$Failed]];
  result = Quiet[Check[$PLYGaussianOpacitiesFn[path], $Failed, LibraryFunction::rterr], {LibraryFunction::rterr}];
  If[result === $Failed || Length[result] == 0, $Failed, result]
]

PLYGaussianScales[filename_String] := Module[{path, result},
  loadLibrary[];
  If[!$libraryLoaded, Return[$Failed]];
  path = ExpandFileName[filename];
  If[!FileExistsQ[path], Return[$Failed]];
  result = Quiet[Check[$PLYGaussianScalesFn[path], $Failed, LibraryFunction::rterr], {LibraryFunction::rterr}];
  If[result === $Failed || Length[result] == 0, $Failed, ArrayReshape[result, {Length[result] / 3, 3}]]
]

PLYGaussianRotations[filename_String] := Module[{path, result},
  loadLibrary[];
  If[!$libraryLoaded, Return[$Failed]];
  path = ExpandFileName[filename];
  If[!FileExistsQ[path], Return[$Failed]];
  result = Quiet[Check[$PLYGaussianRotationsFn[path], $Failed, LibraryFunction::rterr], {LibraryFunction::rterr}];
  If[result === $Failed || Length[result] == 0, $Failed, ArrayReshape[result, {Length[result] / 4, 4}]]
]

PLYGaussianGraphics[filename_String, opts:OptionsPattern[Graphics3D]] := Module[
  {pos, cols, rgb},
  pos = PLYGaussianPositions[filename];
  cols = PLYGaussianColors[filename];
  If[pos === $Failed || cols === $Failed, Return[$Failed]];
  rgb = Normal[cols][[All, 1;;3]];
  Graphics3D[
    {PointSize[Medium], Point[Normal[pos], VertexColors -> rgb]},
    opts,
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

PLYGaussianRender[filename_String, opts:OptionsPattern[]] := Module[
  {path, result, data, pos, pitch, yaw, fov, width, height, mode, params},
  loadLibrary[];
  If[!$libraryLoaded, Return[$Failed]];
  path = ExpandFileName[filename];
  If[!FileExistsQ[path], Return[$Failed]];
  
  pos = OptionValue["Position"];
  pitch = OptionValue["Pitch"];
  yaw = OptionValue["Yaw"];
  fov = OptionValue["FOV"];
  width = OptionValue["Width"];
  height = OptionValue["Height"];
  mode = Replace[OptionValue["DisplayMode"], {"Splat" -> 0, "Ellipse" -> 1, "Point" -> 2, _ -> 0}];
  
  result = Quiet[Check[
    $PLYGaussianRenderFn[path, width, height, pos[[1]], pos[[2]], pos[[3]], pitch, yaw, fov, mode], 
    $Failed, 
    LibraryFunction::rterr
  ], {LibraryFunction::rterr}];
  If[result === $Failed || Length[result] == 0, Return[$Failed]];
  (* result is a flattened UnsignedInteger8 NumericArray of size width*height*4 (RGBA) *)
  data = ArrayReshape[Normal[result], {height, width, 4}];
  Image[data, "Byte", ColorSpace -> "RGB"]
]

SPZGaussianRender[args___] := PLYGaussianRender[args]

PLYGaussianExplore[filename_String] := DynamicModule[
  {path = ExpandFileName[filename]},
  Manipulate[
    PLYGaussianRender[path, 
      "Position" -> {r * Cos[phi] * Cos[theta], r * Sin[theta], r * Sin[phi] * Cos[theta]},
      "Yaw" -> phi + Pi/2,
      "Pitch" -> -theta,
      "Width" -> 400, "Height" -> 400,
      "DisplayMode" -> mode
    ],
    {{r, 3, "Distance"}, 0.1, 10},
    {{phi, 0, "Azimuth"}, -Pi, Pi},
    {{theta, 0, "Elevation"}, -Pi/2 + 0.1, Pi/2 - 0.1},
    {{mode, "Splat", "Mode"}, {"Splat", "Ellipse", "Point"}},
    ControlPlacement -> Left
  ]
]


End[] (* `Private` *)

EndPackage[]
