+++
title = "RaifHack: most loved solution"
description = "Siamese TabNet for real estate price prediction"
weight = 8
[taxonomies]
tags = ["python", "ml", "dl", "competitions"]

[extra]
social_media_card = "./static/img/social_cards/projects_raifhack.jpg"
+++

[The repository](https://github.com/danielgafni/RAIFHACK) showcases a very interesting solution for the [RaifHack](https://raifhack.ru/) competition. The goal of the competition was to implement a machine learning model for accurate commercial real estate price prediction. The given training dataset included both residential and commercial property, but only commercial property prices had to be predicted. 

The breakdown of the solution is:
 1. For a given commercial property object, find similar residential property based on a hand-crafted set of tabular features including geographical location, area, etc. [FAISS](https://github.com/facebookresearch/faiss) was used for efficient vector search.
 2. Run all samples through [TabNet](https://github.com/topics/pytorch-tabnet) to produce vector representation. TabNet is a transformer-based NN designed for tabular data. 
 3. For all pairs of residential-commercial samples, run the embeddings though a `Bilinear` layer
 4. Concatenate the known residential price and run through a `Linear` head to obtain the commercial price prediction 
 5. Predictions from all found similar residential objects were averaged to obtain the final price (only for evaluation but not during training)

![raifnet](https://github.com/danielgafni/RAIFHACK/blob/master/siamese_tabnet.png?raw=true)

This method was not used in our final submission {{ spoiler(text="took too long to tune hparams 🤪") }} --- which did win the competition --- but received the "most loved solution" award. 

