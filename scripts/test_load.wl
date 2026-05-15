lib = "/Users/arnoudb/github/GaussianSplatting/GaussianSplatting/LibraryResources/MacOSX-ARM64/libgaussian_splatting.dylib"
Print["Loading Count..."]
fn = LibraryFunctionLoad[lib, "wl_ply_gaussian_count", {"UTF8String"}, Integer]
Print["Success Count"]
Print["Loading Positions..."]
fn2 = LibraryFunctionLoad[lib, "wl_ply_gaussian_positions", {"UTF8String"}, LibraryDataType[NumericArray]]
Print["Success Positions"]
