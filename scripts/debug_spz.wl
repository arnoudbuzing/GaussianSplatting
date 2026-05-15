PacletDirectoryLoad["/Users/arnoudb/github/GaussianSplatting"];
Needs["ArnoudBuzing`GaussianSplatting`"];
file = "/Users/arnoudb/Downloads/hornedlizard.spz";
Print["Loading file: ", file];
img = SPZGaussianRender[file, "DisplayMode" -> "Splat"];
Print["Result head: ", Head[img]];
