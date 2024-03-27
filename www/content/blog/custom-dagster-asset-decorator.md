+++
title = "Customizing Dagster's asset decorator"
date = 2024-03-15
draft = true
[taxonomies]
tags = ["dagster", "python"]

[extra]
+++

Just some code to check syntax highlighting works

```python
from dagster import asset
import polars as pl


@asset
def my_asset() -> pl.DataFrame:
    return pl.DataFrame({"a": [0, 1, 2, 3]})
```

