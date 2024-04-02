+++
title = "Repalette"
description = "Image recoloring with neural networks"
weight = 8
[taxonomies]
tags = ["Python", "ML", "DL", "OSS", "CV"]

[extra]
+++

[Repalette](https://github.com/danielgafni/repalette) is a tool for automatic image recoloring to a given color palette of 6 color.

I've worked on this project during the 2019-2020 winter. At that time I was really obscessed with Linux customization (also known as "ricing"). A common problem was finding a wallpaper which aligned with a given color palette. It became a problem as I was frequently changing it.

Frustrated by the lack of a good general image recoloring tool, I did some research and found a [paper](https://www.researchgate.net/publication/319277684_PaletteNet_Image_Recolorization_with_Given_Color_Palette) describing the `PaletteNet` GAN-based NN architecture created to solve this problem.

Following the paper, I've implemented `PaletteNet`, scraped [Design Seeds](https://www.design-seeds.com/) to download images alongside their color palettes, and trained the GAN for the image recoloring task. The project was also published as a simple `FastAPI`-based app in a `Docker` image. 

While I haven't completed the second step of GAN fine-tuning (my new real job kicked in), the pre-trained version kinda worked and has been useful too.

Note that this happened before the diffusion models boom. 

Click to reveak recolored version

{{ image_toggler(default_src="https://github.com/danielgafni/repalette/blob/master/screenshots/flowers.jpg?raw=true", toggled_src="https://github.com/danielgafni/repalette/blob/master/screenshots/flowers_recolored.png?raw=true", default_alt="Original", toggled_alt="Recolored") }}

---

See also: Reddit announcement [post](https://www.reddit.com/r/unixporn/comments/n4o4n5/repalette_an_image_recoloring_tool/)

