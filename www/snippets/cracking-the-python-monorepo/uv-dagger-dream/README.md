# uv + Dagger monorepo

This is an example a monorepo that combines the best of Dagger and uv.

Any project registered as uv workspace member can be built with Dagger:

```shell
dagger call build-project --root-dir . --project <project>
```

where <project> is defined as `project.name` in `pyproject.toml` of the target project (that's 4 times "project" in one sentence).
