+++
title = "dagster-ray"
description = "Ray integration library for Dagster"
weight = 1
[taxonomies]
tags = ["Python", "Dagster", "Ray", "OSS"]
+++

[dagster-ray](https://github.com/danielgafni/dagster-ray) allows easily running [Ray](https://www.ray.io/) computations in [Dagster](https://dagster.io/) pipelines. 
It provides various Dagster abstractions, the most important being `Resource`, and helper `@op`s and `@schedule`s, for multiple backends.

Essentially, it enables writing very simple Python code, similar to: 

```python
from dagster import asset, Definitions
from dagster_ray.kuberay import KubeRayCluster
import ray


@asset
def my_asset(
    ray_cluster: KubeRayCluster,
):
    return ray.get(ray.put(42))
```

Behind the scenes, `dagster-ray` will manage the `KubeRay`'s `RayCluster` lifecycle, spinning it up when the pipeline starts, and tearing it down after the pipeline finishes.
The function body can then execute `ray` code in a distributed cluster without any additional setup.
