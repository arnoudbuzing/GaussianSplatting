PacletDirectoryLoad["/Users/arnoudb/github/GaussianSplatting"];
Needs["ArnoudBuzing`GaussianSplatting`"];
img = PLYGaussianImage["/Users/arnoudb/github/GaussianSplatting/tests/fixtures/small.ply"];
Print[MinMax[ImageData[img]]];
