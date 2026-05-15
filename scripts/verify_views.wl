img = Import["top_view.png"]; Print["Top View Union: ", Union[Flatten[ImageData[img], 1]]];
img2 = Import["side_view.png"]; Print["Side View Union: ", Union[Flatten[ImageData[img2], 1]]];
img3 = Import["default_view.png"]; Print["Default View Union: ", Union[Flatten[ImageData[img3], 1]]];
