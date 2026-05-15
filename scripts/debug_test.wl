PacletDirectoryLoad["/Users/arnoudb/github/GaussianSplatting"];
Needs["ArnoudBuzing`GaussianSplatting`"];
ArnoudBuzing`GaussianSplatting`Private`loadLibrary[];
fn = ArnoudBuzing`GaussianSplatting`Private`$PLYGaussianCountFn;
Print["fn class: ", Head[fn]];
testFile = "/Users/arnoudb/github/GaussianSplatting/tests/fixtures/small.ply";
result = fn[testFile];
Print["result: ", result];
Print["result head: ", Head[result]];
