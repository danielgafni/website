+++
title = "Customizing Dagster's asset decorator"
date = 2024-03-15
[taxonomies]
tags = ["dagster", "python"]
+++

This blog post assumes some knowledge of [Dagster](https://dagster.io) - a modern data orchestration framework.

## Introduction

When building data pipelines, it's common to work with multiple similar data assets. 

These assets might differ in small details, like: 
 - how is the input table being filtered
 - which transformation is being applied
 - which entities are included in the data
 - which machine learning model is being applied

But share similarities such as:
 - using standard naming conventions
 - producing text and metadata logs
 - having the same columns

At first it's easy to add them by copy-pasting existing code. But what if there are dozens of such assets? How do we keep our code maintainable and DRY? Asset Factories to the resque! 

## Asset Factories

The Asset Factory is a design pattern which can be used to generate multiple similar assets definitions. The idea is to define a function which produces assets based on some (varying) input parameters. This factory encapsulates the common logic for creating the assets, while allowing the specific details to be customized for each asset.

Let's say, we have a machine learning model which predicts client churn probability for the next month. We would like to maintain tables for groups of users which are likely to churn with different tresholds. 

Here is a simple example of an Asset Factory which achieves this goal:

```python
from dagster import asset, AssetsDefinitions
import polars as pl


def build_churning_users_asset(
    min_churn_proba: float, max_churn_proba: float
) -> AssetsDefinitions:
    @asset(name=f"users_churn_between_{min_churn_proba}_{max_churn_proba}")
    def _asset(users: pl.DataFrame) -> pl.DataFrame:
        return users.filter(
            pl.col("predicted_churn_proba") > min_churn_proba,
            pl.col("predicted_churn_proba") <= max_churn_proba,
        )

    return _asset


# create multiple assets
churning_users_assets = [
    build_churning_users_asset(l, h) for l, h in [(0.7, 0.8), (0.8, 0.9), (0.9, 1.0)]
]
```

We now have 3 different assets which only differ in filtering tresholds. 

The codebase can quickly turn in chains of such generated assets. Multiple factories will pass assets to from one to another. Thus, it becomes convenient to take the upstream `AssetsDefinitions` as a factory argument, because it contains a lot of useful information, such as asset key, group, partitioning, etc.

For example, imagine another `users`-like asset, which may be partitioned and come from a different data source:


```python
from dagster import StatisPartitionsDefinition


@asset(
    key=["users", "special"],
    partitions_def=StatisPartitionsDefinition(["A", "B"]),
    group_name="special",
)
def special_users() -> pl.DataFrame:
    ...
```

A generalized churn-filtering factory may look something like this:

```python
from dagster import AssetIn, SourceAsset


def build_bar_filtered_asset(
    upstream_asset: SourceAsset, min_churn_proba: float, max_churn_proba: float
) -> AssetsDefinitions:
    @asset(
        # prepent the original key with a new prefix
        # to clearly separate our generated assets
        key=[f"users_churn_between_{min_churn_proba}_{max_churn_proba}"]
        + list(upstream_asset.key),
        group_name=upstream_asset.group_name,  # we might want to keep the generated asset in the same group
        partitions_def=upstream_asset.partitions_def,  # and we definitely want the same partitioning
        ins={"upstream": AssetIn(upstream_asset.key)},
    )
    def _asset(upstream: pl.DataFrame) -> pl.DataFrame:
        return upstream.filter(
            pl.col("predicted_churn_proba") > min_churn_proba,
            pl.col("predicted_churn_proba") <= max_churn_proba,
        )

    return _asset


churn_thresholds = [(0.7, 0.8), (0.8, 0.9), (0.9, 1.0)]
assets_for_churn_filtering = [users, special_users]

churning_users_assets = [
    build_churning_users_asset(a, l, h)
    for a in assets_for_churn_filtering
    for l, h in churn_thresholds
]
```

Hurray! We were able to build a quite general asset factory. It can be applied to any upstream asset and will carry on such properties as partitioning and group name.

As always with factories, it works well until it doesn't.

One thing this factory cannot generalize over is input data. Because the upstream assets are hardcoded into the asset body signature, we cannot change them when calling the factory.

For example, imagine we are calculating data science features over some data. Some may be statistical and self-contained, but some may require additional maching learning models to be applied. Features may also depend on each other. This makes feature assets form a complex DAG, which can't be expressed by the above pattern, because we would need to dynamically define dependencies between features at factory call time. 

Here is how we solve it: we write more factories. Joking.

## Extending the @asset decorator

Luckily for us, a better solution exists, and it's called `functools.wraps`.

By using it, we can not only dynamically pass the upstream features dependencies to Dagster, but also use the same neat API by specifying them as function arguments.

`functools.wraps` is a handly utility made especially for writing decorators. It carries function metadata from the decorated function to the decorator body. Let's take a look at how it works: 

```python
import functools


def my_decorator(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)

    print(wrapper.__name__)
    print(wrapper.__doc__)

    return wrapper


@my_decorator
def say_hello(someone: str):
    """My docstring"""
    print(f"Hello, {someone}!")
```

```
>>> say_hello("World")
say_hello
My docstring
Hello, World!
```

The inner `wrapper` function now has the same `.__doc__`, `.__name__`, and in fact, the same signature, as our `say_hello` function! 

Now, let's use it to build a customized `@asset` decorator. 

```python
import functools
from dagster import AssetExecutionContext, AssetIn, Config, SourceAsset


def my_asset_decorator(
    # we can pass any Dagster's `@asset` arguments from here
    # this function can also take more complex objects as arguments, such as SourceAsset
    name: str | None = None,
    key: list[str] | None = None,
    group_name: str | None = None,
    io_manager_key: str | None = None,
    ins: dict[str, AssetIn] | None = None,
):
    def inner(
        compute_fn,
    ) -> AssetsDefinitions:
        @asset(
            name=name,
            key=key,
            io_manager_key=io_manager_key,
            group_name=group_name,
            ins=ins,
        )
        @functools.wraps(compute_fn)
        def _asset(
            context: AssetExecutionContext,
            config: Config,
            *args,
            **kwargs,
        ):
            # you can really do anything you want with *args and **kwargs here
            context.log.debug("Before calling user code...")
            result = compute_fn(context, config, *args, **kwargs)
            context.log.debug("After calling user code...")
            # maybe apply a standardized transformation here?
            # or log some metadata? Your choice!
            return ...

        return _asset

    return inner


class MyConfig(Config):
    foo: str = "bar"


@my_asset_decorator(group_name="my_group", io_manager_key="my_io_manager")
def my_asset(context: AssetExecutionContext, config: MyConfig, usptream_1, upstream_2):
    return ...
```

This pattern is very general and powerful. You get the idea, it's possible to inject any code into the resulting asset both from the factory and from the `compute_fn` decorated by `my_asset_decorator`. It can also take arbitrary Dagster Resources and upstream Assets as input. It's possible to make the custom asset decorator as complex and fine-grained as needed, potentially injecting additional asset dependencies or resources or something even more crazy which I can't think of right now.

## Conclusion

The pattern of extending the `dagster.asset` decorator by using `functools.wraps` is a powerful tool for creating reusable and flexible data pipelines. It allows for dynamic definition of dependencies between assets, which is crucial for complex data processing tasks. It is a testament to the flexibility and power of Dagster's asset-based programming model.

