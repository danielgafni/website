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
from dagster_ray import RayResource
from dagster_ray.kuberay import KubeRayCluster
import ray


@asset
def my_asset(
    ray_cluster: RayResource,  # RayResource is only used as a type annotation
):  # this type annotation only defines the interface
    return ray.get(ray.put(42))
```

Behind the scenes, `dagster-ray` will manage the `KubeRay`'s `RayCluster` lifecycle, and provide the `ray_cluster` resource to the `my_asset` function.
The function body can then execute `ray` code in a distributed cluster without any additional setup.
