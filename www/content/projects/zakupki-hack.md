+++
title = "Zakupki.Hack: winning solution"
description = "Procurement objects recommender system"
weight = 7
[taxonomies]
tags = ["Python", "ML", "NLP", "Competitions"]
+++

Zakupki.Hack was the first ML hackathon I've participated in. It was organized by Roseltorg, an electronic procurements platform. The objective was to develop a solution that could recommend the most suitable procurements for a given company based on its description, attributes, and past engagement with procurements. 

After 3 days of little to zero sleep we came up with the [solution](https://github.com/obj42/Zakupki.Roseltorg) which included training a Vec2Wav model, doing vector similarity search with FAISS, and applying a bunch of heuristics. Procurement descriptions turned out to be the most useful among the provided features. To our surprise, the Vec2Wav model outperformed BERT (ruBERT) on this task, most likely due to limited dataset and non-standard, technical language used. 

I was responsible for implementing the Data Science aspect, while my teammates built the frontend and backend and deployed them on Kubernetes. Our final score was incredibly good, and the presence of a fully functional scalable service guaranteed us the first place at the competition. 

