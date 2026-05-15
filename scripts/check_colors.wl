img = Import["render_output.png"];
colors = Union[Flatten[ImageData[img], 1]];
Print["Distinct colors in image: ", Length[colors]];
Print["First 5 colors: ", Take[colors, Min[5, Length[colors]]]];
