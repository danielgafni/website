+++
title = "dagster-ray"
description = "Ray integration library for Dagster"
weight = 1
[taxonomies]
tags = ["Python", "Dagster", "Ray", "OSS"]
+++

[dagster-ray](https://github.com/danielgafni/dagster-ray) provides a few options for [Dagster](https://dagster.io/) (such as `RunLauncher`, `Executor`, `PipesClient`, and `Resource`.) to run on [Ray](https://www.ray.io/).

The same Dagster code an be executed locally or on a remote distributed Ray cluster.

Some of the resources, such as `PipesKubeRayJobClient`, manage the Ray cluster for the user.
Other, such as `ray_executor`, connect to an externally managed Ray cluster.

Examples below. Check out the repo for more complete and up to date docs.

## `ray_executor`

The ray_executor can be used to execute Dagster steps on an existing remote Ray cluster. The executor submits steps as Ray jobs. They are started directly in the Ray cluster.

```python
from dagster import job, op
from dagster_ray import ray_executor


@op(
    tags={
        "dagster-ray/config": {
            "num_cpus": 8,
            "num_gpus": 2,
            "runtime_env": {"pip": {"packages": ["torch"]}},
        }
    }
)
def my_op():
    import torch

    # your expensive computation here

    result = ...

    return result


@job(executor_def=ray_executor.configured({"ray": {"num_cpus": 1}}))
def my_job():
    return my_op()
```

## `PipesKubeRayJobClient`

`PipesKubeRayJobClient` is a [Dagster Pipes](https://docs.dagster.io/concepts/dagster-pipes) client for running KubeRay's `RayJob` CR on Kubernetes.

Events emitted by the Ray job will be captured by `PipesKubeRayJobClient` and will become available in the Dagster event log. Standard output and standard error streams will be forwarded to the standard output of the Dagster process.

```python
from dagster import AssetExecutionContext, Definitions, asset

from dagster_ray.kuberay import PipesKubeRayJobClient


@asset
def my_asset(
    context: AssetExecutionContext, pipes_rayjob_client: PipesKubeRayJobClient
):
    pipes_rayjob_client.run(
        context=context,
        ray_job={
            # RayJob manifest goes here
            # full reference: https://ray-project.github.io/kuberay/reference/api/#rayjob
            "metadata": {
                # .metadata.name is not required and will be generated if not provided
                "namespace": "ray"
            },
            "spec": {
                "entrypoint": "python /app/my_script.py",
                # *.container.image is not required and will be set to the current `dagster/image` tag if not provided
                "rayClusterSpec": {
                    "headGroupSpec": {...},
                    "workerGroupSpecs": [...],
                },
            },
        },
        extra={"param": "value"},
    )


definitions = Definitions(
    resources={"pipes_rayjob_client": PipesKubeRayJobClient()}, assets=[my_asset]
)
```

In the Python script executed in the `RayJob` CR:

```python
from dagster_pipes import open_dagster_pipes


with open_dagster_pipes() as context:
    assert context.get_extra("param") == "value"
    context.log.info("Hello from Ray Pipes!")
    context.report_asset_materialization(
        metadata={"some_metric": {"raw_value": 57, "type": "int"}},
        data_version="alpha",
    )
```
