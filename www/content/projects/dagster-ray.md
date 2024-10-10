+++
title = "dagster-ray"
description = "Ray integration library for Dagster"
weight = 0
[taxonomies]
tags = ["Python", "Dagster", "Ray", "OSS"]
+++

[dagster-ray](https://github.com/danielgafni/dagster-ray) allows running jobs orchestrated by [Dagster](https://dagster.io/) on [Ray](https://www.ray.io/).

This combines Dagster's rich orchestration capabilities with Ray's close to instant job startup time, compute autoscaling and distributed workflows, without any overhead for the user.

The same Dagster code can be executed locally or on a remote Ray cluster. Local scripts can be immidiately executed in the cluster without redeploys. 

Some of the implemented resources:
- `RunLauncher`
- `Executor`
- `IOManager`
- `PipesClient` 

Some example code:


{{ add_src_to_code_block(src="dagster.yaml") }}
```yaml
# default settings for launched Runs
run_launcher:
  module: dagster_ray
  class: RayRunLauncher
  config:
    num_cpus: 1
    num_gpus: 0
```


{{ add_src_to_code_block(src="definitions.py") }}
```python
from dagster import asset, AssetExecutionContext, Definitions
from dagster_ray import ray_executor, RayIOManager


@asset(
    io_manager_key="ray_io_manager",
    tags={
        "dagster-ray/config": {
            "num_cpus": 32,
            "num_gpus": 1,
            "runtime_env": {"pip": {"packages": ["torch"]}},
        }
    },
)
def upstream(context: AssetExecutionContext) -> float:
    # a really heavy PyTorch computation
    import torch

    result = ...
    some_metric = ...

    context.add_output_metadata({"some_metric": some_metric})

    return result


@asset
def downstream(upstream: float): ...


definitions = Definitions(
    assets=[upstream, downstream],
    resources={"ray_io_manager": RayIOManager()},
    executor=ray_executor,
)
```
