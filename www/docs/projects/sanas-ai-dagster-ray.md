---
title: 'Talk: building a Feature Store with Dagster and Ray'
description: My Dagster Community Meetup talk on the feature store I built at Sanas with Dagster and KubeRay.
youtube_url: https://www.youtube.com/watch?v=HPqQSR0BoUQ
weight: 3
tags:
- Talks
- Dagster
- Ray
---

# Talk: building a Feature Store with Dagster and Ray

While working as an MLOps Engineer at [Sanas](https://sanas.ai) I designed and developed the Feature Store used for model training and other workloads. The Feature Store had around 10 deep learning and statistical features (with cross-features dependencies), every feature having 10-40M files. 

[Dagster](https://dagster.io) was used for orchestration, and [Ray](https://ray.io) (`KubeRay`) — for scaling the jobs. I've written a custom `RayClusterResource` which handled automatic `KubeRay` cluster provisioning for Dagster's ops and assets. It was possible to write something like this: 


```python
@asset
def my_feature(ray_cluster_my_feature: MyFeatureRayClusterResource): ...
```

to automatically run the `@asset` body in an auto-scaling `KubeRay` cluster on Kubernetes. 

This talk at the Dagster Community Meetup explains the solution and how I've arrived at it in more details.

<iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/HPqQSR0BoUQ" allowfullscreen></iframe>

