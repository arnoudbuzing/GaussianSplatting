(* ::Package:: *)

(* GaussianSplatting - Wolfram Language bindings for wgpu-3dgs-core *)

BeginPackage["ArnoudBuzing`GaussianSplatting`"]

(* Public symbol declarations *)

PLYGaussianCount::usage = "PLYGaussianCount[filename] loads a 3D Gaussian Splatting PLY file \
and returns the number of Gaussians it contains.";

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

End[] (* `Private` *)

EndPackage[]
