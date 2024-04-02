+++
title = "CardioSpike: winning solution"
description = "Attention-based NN for heart anomalies prediction"
weight = 9
[taxonomies]
tags = ["Python", "ML", "DL", "Competitions", "Time Series"]
+++

RardioSpike was an ML competition in heart anomalies prediction. We were given a limited dataset of time series data (heart contractions over time). Some data points were marked as anomalies, and the goal was to build an anomaly classified with a clean UI.

Our [solution](https://github.com/gleberof/cardiospike) was to train a custom neural network with a mix of convolutions and attention. The convolutional layers were effective in capturing local patterns in the time series data, while the attention mechanisms helped the model focus on relevant features for anomaly detection. Hyperparameters search with cross-validation was able to yield great results, and the attention block was useful for data insights. We've implemented a simle `FastAPI`-based backend & frontend, and deployed the service on AWS. 

Our solution took the first place by being one of the most accurate and usable at the same time. 

