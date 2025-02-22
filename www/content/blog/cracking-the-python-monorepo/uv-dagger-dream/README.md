# uv + Dagger monorepo

This is an example a monorepo that combines the best of Dagger and uv.

Any project registered as uv workspace member can be built with Dagger:

```shell
dagger call build-project --source-dir . --project <project>
```
