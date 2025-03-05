+++
title = "Cracking the Python Monorepo"
date = 2025-02-23

[taxonomies]
tags = ["Python", "Dagger", "uv", "Monorepo"]
[extra]
code_block_name_links = true
stylesheets = ["css/custom.css"]

+++

A monorepo is a single repository that contains multiple projects. It is a popular way to organize codebases with many coupled components, and is also used at very big companies like Google, Facebook, and Twitter.

For a long time, I did not understand the benefits of monorepos. I thought they were used because people could not figure out how to split their codebases into smaller parts.

After working at [Dagster](https://dagster.io) (on a pretty huge monorepo with more than 140k lines of code and 70+ subprojects), I realized that monorepos can provide quite a pleasant development experience when done right --- with the right tooling, practices, and, of course, the right use case. Monorepos solve a very specific problem: local dependencies between projects force them to be updated together, which eliminates certain types of technical debt (e.g. ensures all current projects are always compatible with each other). I also anjoyed **using** all this tooling which somebody else has built for me (but I imagine it's not as fun to **build** it).

It's worth noting that monorepos are not a silver bullet. They have their own set of challenges, mostly the need to build custom tooling and to organize the development workflow. The big tech companies have the resources to build and maintain these tools, but for smaller companies, it can be quite challenging.

Dagster's monorepo wasn't perfect either. Some of the drawbacks were:
- Slow CI/CD pipelines: builds could run for hours!
- Legacy Python packaging made maintaining dependencies and CI pipelines quite complicated. Making a change to dependencies required editing multiple configuration files at a few locations with great care.

These problems were mostly due to technical debt

{{ aside(position="right", text="I started migrating Dagster's monorepo to `uv` but at the time got [blocked](https://github.com/dagster-io/dagster/pull/23814#issuecomment-2364694200) by  conflicting development dependencies for different test suites, which was not supported by `uv` at that time (but is now).") }}

This post focuses on a very specific use case --- `uv` Python monorepos. Until very recently, Python monorepos were quite hard to set up and maintain, with problems like the ones I mentioned above being quite common.

However, nowadays we have a bunch of excellent tooling available with great out-of-the-box monorepo support.

{{ admonition(type="warning", text="`uv` shouldn’t need any introduction. In 2024, `uv` took the Python ecosystem by storm, and it’s now the go-to tool for Python development. Using anything else (except perhaps [Pixi](https://pixi.sh/latest/) which builds on top of `uv` and extends it to handle Conda packages) doesn't make much sense anymore. Learn move about `uv` [here](https://docs.astral.sh/uv/).") }}

## The dream of the monorepo

In this post, I am going to share an approach to building Python monorepos that solves these issues in a very elegant way. The benefits of this approach are:
- **it works with any `uv` project** (even yours!)
- **it needs little to zero maintenance and boilerplate**
- **it provides end-to-end pipeline caching** --- including steps downstream to building the image (like running linters and tests), which is quite rare
- **it's easy to run locally and in CI**

We will walk through a typical monorepo setup and use [uv](https://astral.sh/uv) and [Dagger](https://dagger.io) to build lightning-fast and modular build pipelines. Feel free to check out the docs for these tools ([uv quickstart](https://docs.astral.sh/uv/getting-started/), [Dagger quickstart](https://docs.dagger.io/quickstart/daggerize)). Impatient readers can jump straight to the [Dagger module](#a-thousand-daggers).

# Python packaging: :snake: :package: :scream:

Please look at the emojis above until you get it. Yes, managing packaging in a Python monorepo can be a nightmare. But it doesn’t have to be!

And it's really not with the right tooling.

- `uv` has the concept of [workspaces](https://astral.sh/uv/docs/workspaces) which allows installing individual packages from a monorepo and makes managing dependencies a breeze. It standardizes dependency management and maintenance operations in monorepos, including operations with local dependencies.
- `Dagger` --- a universal build tool which supports multiple languages (including Python) to define containerized build pipelines. Because Dagger pipelines can be written in Python, they can be easily adapted to work with monorepos of arbitrary complexity and structure. Dagger is essentially a glorified Dockerfile generator available in your favorite programming language. Dagger pipelines are huge graphs of `BuildKit` (the engine used by Docker when building images) steps, so the entire pipeline can be optimized, parallelized, and cached by BuildKit.
- modern QA tooling: `ruff` and `pyright` have first-class support for monorepos and are able to automatically discover and merge configuration files from multiple subdirectories.

## A brief history of Python packaging

Contrary to what you might think, Python packaging is not a nightmare anymore. It used to be, but with the introduction of [PEP 517](https://peps.python.org/pep-0517/) and [PEP 518](https://peps.python.org/pep-0518/), and the rise of `uv`, it's actually in pretty good shape --- I rarely have to pull out my hair when working with Python packaging nowadays.

{{ aside(position="right", text="I remember sweating hard before running `poetry lock` which I knew would run for an hour or two with my shitty internet connection because these juicy PyTorch wheels just had to be downloaded and hashed for every combination of Python and OS. Good times!") }}


The PEPs and their adoption were important to standardize the way Python packages are built and distributed. Because the overwhelming majority of Python packages now provide correct distribution metadata (like hashes of the package contents), it's much easier for advanced and optimized package managers like `uv` to do their job really well. Some machine learning dependencies --- and [specifically PyTorch](https://github.com/pytorch/pytorch/issues/76557) --- used to sabotage the Python packaging ecosystem, but even PyTorch now (mostly) provides the hashes with the various wheels they build for all these CUDA versions.

Therefore, I'd like to note that the improvements with packaging are not only due to better tooling like `uv`, but also due to the community's effort to standardize and improve the Python packaging ecosystem in general.

# Setting up the monorepo

Fair enough! Let's start by invoking `uv` (assuming the dear reader has --- and he should --- `uv` installed) and creating a new workspace:

```shell
mkdir uv-dagger-dream
cd uv-dagger-dream
uv init
uv add --group dev ruff pyright
mkdir projects
uv init --package --lib projects/lib-one
uv init --package --lib projects/lib-two
uv lock
```

Phew! That was a lot of commands. Let's break them down:

- `uv init` initializes a project. A workspace is a directory that contains one or more packages. It's a way to group packages together and manage their dependencies, while allowing cross-package dependencies.
- `uv add --group dev` adds dependencies to the root project. Development groups are only used when working on the project and are not registered as dependencies when the project is published. Downstream projects will not inherit these dependencies.
- `uv init --package --lib projects/lib-one` initializes a new package in the `projects` directory. The `--lib` flag tells `uv` that this package is a library. This is important because it will add a `[build-system]` section to the `pyproject.toml` file, which is required for `uv` to know how to build the package.
- `uv lock` creates a `uv.lock` file that contains the resolved dependencies for the workspace. This file is used by `uv` to determine which versions of the dependencies to install.

After this section, you should see something like this (non-essential files are omitted):

```
.
├── README.md
├── projects
│   ├── lib-one
│   │   ├── pyproject.toml
│   │   └── src
│   │       └── lib_one
│   │           └── __init__.py
│   └── lib-two
│       ├── pyproject.toml
│       └── src
│           └── lib_two
│               └── __init__.py
├── pyproject.toml
└── uv.lock
```

Projects recognized by `uv` as workspace members share the same `uv.lock` file, environment, can be added as dependencies to each other, and can be managed with `uv` commands.

{{ admonition(type="tip", text="I like to edit the root `pyproject.toml` and set `workspace.members` to `['projects/*']` so that all the packages in the `projects` directory are recognized as workspace members.") }}

To demonstrate how one project can be added as a dependency to another, let's add `lib-one` as a dependency to `lib-two`:

```shell
uv add --package lib-two lib-one
```

The `--package` flag tells `uv` to execute the command in the context of the `lib-two` package. The `lib-one` package is added as a dependency to `lib-two`'s `pyproject.toml` and the root `uv.lock` file is updated automatically.

You can see it now? There is more than one package in our repository, therefore, it's a monorepo! :tada:

# Cache me if you can

Who knows how to write a `Dockerfile`? I'm sure you do. Do you know how to write it efficiently? Are you sure? In any case, we are about to unleash the combined power of `Dagger` (backed by `BuildKit`), and `uv`, to build our monorepo in a very (**very**) efficient way.

We don't actually need a `Dockerfile`. We could have used `Dagger` to define the entire build process in Python. However, since it might complicate building the project with plain `docker` or other tools, we are still going to define most of the build with a traditional `Dockerfile`. But:

1. We will define an intermediate stage *almost* identical to the final stage.
2. We will then call `Dagger` to build the project in the intermediate stage. We will then complete the final stage programmatically with `Dagger`.

This approach allows building a very similar image locally just with `docker build .` if needed.

For simplicity, all the subprojects will share the same `Dockerfile`. Behold!

<details>
<summary><strong>Click to reveal the Dockerfile</strong></summary>

```dockerfile,name=Dockerfile
{{ remote_text(src="blog/cracking-the-python-monorepo/uv-dagger-dream/Dockerfile") }}
```

</details>

{{ admonition(type="note", text="The resulting image will contain a subset of the monorepo dependencies needed for the specific project due to the `--package` flag.") }}

That's a lot of Docker magic! Let's break it down:
- The `deps-prod` stage installs only runtime dependencies. This is useful for building a more lightweight image for deployment.
- The `deps-dev` stage installs development dependencies. This is useful for building an image for QA checks or running tests.
- The `final` stage installs the package itself. Only at this point the source code is copied into the image. The last `uv sync` invocation doesn't install any third-party dependencies, only the dependencies from our monorepo (`uv` workspace). Noticed the `--no-install-workspace` flag spammed all over the place? It's quite important as it configures `uv sync` to ignore the missing source code and install only the dependencies.

{{ admonition(type="info", text="The `--mount=type=cache,target=/root/.cache/uv` flag tells Docker to mount the cache directory to the build container. This way, the cache is persisted between builds and doesn't inflate the image itself.") }}

What a great Dockerfile! It's so efficient that it's almost a crime. Or is it not? Can you spot the problem?

Let's have a hypothetical conversation between you (the dear reader) and a Docker guru:

-- You: Hey, I know! Just look at that filthy `COPY . .` before the final `uv sync`! It will invalidate the cache every time any file in the monorepo changes!

-- Docker guru: You are right! But how can we fix it?

-- You: Oh, I'm very smart. Let's only copy our package's source code into the image and then `uv sync` it. Check this out!

```dockerfile
# -------------------------------------------------------------
FROM deps-${INCLUDE_DEPENDENCIES} AS final

ARG PACKAGE
ARG PACKAGE_NAME
COPY projects/$PACKAGE ./projects/$PACKAGE/
# at this point all the third-party dependencies are already installed
# so the step below is very fast anyway
RUN uv sync --all-extras --inexact --package $PACKAGE
```

-- Docker guru: Wow! You are a genius! But what if our package depends on some other package in the monorepo?

-- You: Oh, that's easy! We can just add another `COPY` instruction for the dependency before running `uv sync`.

-- Docker guru: Oh and what if we have multiple packages that depend on each other? Are you going to write a new `COPY` instruction for each of them? Are you going to maintain a separate `Dockerfile` for each set of dependencies? What if they are scattered around the repo instead of being carefully placed in `projects/` and hard to track? By the way, `COPY . .` is cursed in another way. It will always invalidate the final image cache and trigger potentially expensive downstream steps in your CI pipeline like running tests. A pipeline like this is doomed to be slow.

With plain Docker, we are left with two options:
1. Carefully (probably manually) track all inter-package dependencies and maintain `COPY` instructions in multiple `Dockerfile`s.
2. Slap a `COPY . .` and accept the fact that the final image will always be rebuilt from scratch.

Pick your poison.

---

Remember our goal: to avoid unnecessary rebuilds of the final image and granularly include only the source code of the packages that are actually needed. What if we could programmatically define the Dockerfile? What if we could define the build process in Python? What if there is already a place in our project where the local dependencies graph is defined precisely?

Think about it for a moment. I will give you a hint: it's {{ spoiler(text="the `uv.lock` file.", fixed_blur=false) }} I'm sorry this wasn't a hint but a direct answer, but let's move on.

# A thousand daggers

Let's look into the `uv.lock` file for a moment. It's a TOML file that describes the entire dependency tree of our monorepo. At the very top, you will find:

```toml
[manifest]
members = [
    "lib-one",
    "lib-two",
    "uv-dagger-dream",
]

[[package]]
name = "lib-one"
version = "0.1.0"
source = { editable = "projects/lib-one" }

[[package]]
name = "lib-two"
version = "0.1.0"
source = { editable = "projects/lib-two" }
dependencies = [
    { name = "lib-one" },
]
```

:tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada: :tada:

At the beginning of the `uv.lock` file is the `members` array. It contains a list of all the workspace members (our local packages), including the root member `uv-dagger-dream`.

Next comes the `package` array. Each element in the `package` array describes a package (local or third-party) in the monorepo. Notice the `source` key in the `package` table. It points to the source code of the package. And we can use it to identify the local dependencies of a given package.

The plan:
1. build the original `Dockerfile` up to the `deps-dev` stage. At this point, we have all the production dependencies installed, but the source code is not copied and installed yet.
2. extract the information about the local dependencies from the `uv.lock` file (with Python)
3. use it to copy the source code of each local dependency into the image
4. then we can run `uv sync` to install the local dependencies (including our project) in editable mode

Docker can't cover steps 2, and 3. But Dagger can! Let's write a `Dagger` function to do this.

{{ admonition(type="note", text="The words `container` and `image` are used interchangeably in this post. Technically, a container is a running instance of an image, but Dagger defines the `Container` type, so I will use the word `container` to refer to images most of the time.") }}

We will start by creating a new `Dagger` module sitting in a separate package in our monorepo. This way we keep it independent and reusable.

```shell
mkdir .dagger
cd .dagger
dagger init --sdk python --name monorepo-dagger .dagger
```

This command will create a new `Dagger` module in the `.dagger` directory.

<details>
<summary><strong>A work-around for Dagger not supporting uv workspaces</strong></summary>

---

The Dagger package we just added is not configured to be a workspace member because of [this](https://github.com/dagger/dagger/issues/8583#issuecomment-2654117616) current limitation of Dagger (this may already be fixed at the time of reading). It also relies on an ephemeral local `sdk` package which is excluded from version control and may not be always available for `uv`.

Here are the steps for a workaround at the time of writing:

1. Remove the following from `.dagger/pyproject.toml`:

```toml
[tool.uv.sources]
dagger-io = { path = "sdk", editable = true }
```
and run `uv add tomli` (we will use it to read `uv.lock`) inside the `.dagger` directory.

This will ensure that the Dagger module is not dependent on the local `sdk` package and will fetch `dagger-io` from PyPI instead.

2. Add the Dagger module as a development dependency to the root project:

```shell
uv add --group dagger .dagger
uv sync --all-groups
```

This will enable type checking and linting for our Dagger module.

3. Move `dagger.json` to the repo root, and add

```json
"source": ".dagger"
```

to it.

4. Finally, add

```toml
[project.entry-points."dagger.mod"]
main_object = "monorepo_dagger:MonorepoDagger"
```

to the root `pyproject.toml`.

---

</details>

Now we can run the `dagger call` command from the repo root.

## Building the build pipeline

We will go backwards because it's somewhat easier to understand in my opinion. Feel free to consult the Dagger Python SDK [documentation](https://dagger-io.readthedocs.io/en/sdk-python-v0.16.1/).

First, we will do a bunch of imports and define some useful types:

<!-- blacken-docs:off -->

```python,name=.dagger/src/monorepo_dagger/main.py,hide_lines=43-1000
{{ remote_text(src="blog/cracking-the-python-monorepo/uv-dagger-dream/.dagger/src/monorepo_dagger/main.py") }}
```

---

And here is the Dagger entry point --- `MonorepoDagger`, also called a Dagger *Module*. The method `build_project` defines a Dagger *Function* which will be available as

```shell
dagger call build-project
```

from the command line. The `build_project` function will build the Docker image for a given project and will **only contain the dependencies and source code required for that project**. This function will call other high-level methods of the class to achieve this.

```python,name=.dagger/src/monorepo_dagger/main.py,hide_lines=1-44 82-1000
{{ remote_text(src="blog/cracking-the-python-monorepo/uv-dagger-dream/.dagger/src/monorepo_dagger/main.py") }}
```

The `debug_sleep` argument will be useful later.

---

Let's implement the `container_with_third_party_dependencies` method first. That's easy, we just need to use the existing `Dockerfile` and specify the `deps-dev` target stage. Note how we don't need **any files** except `pyproject.toml` and `uv.lock` to build the Docker image for a given project. This is possible thanks to `uv` workspaces.

```python,name=.dagger/src/monorepo_dagger/main.py,hide_lines=1-82 114-1000
{{ remote_text(src="blog/cracking-the-python-monorepo/uv-dagger-dream/.dagger/src/monorepo_dagger/main.py") }}
```

{{ admonition(type="note", text="We also create a dummy `README.md` file because `Hatch` --- the default build system in `uv` projects --- requires it to be present.") }}

---

The `project_sources_map` dictionary is the precious information we need to enable granular copying of the source code. Here is the implementation of the `get_project_sources_map` method which retrieves it:

```python,name=.dagger/src/monorepo_dagger/main.py,hide_lines=1-114 144-1000
{{ remote_text(src="blog/cracking-the-python-monorepo/uv-dagger-dream/.dagger/src/monorepo_dagger/main.py") }}
```

This function will parse the `uv.lock` file and return a dictionary where the keys are the project names and the values are the paths to the source code.

{{ admonition(type="info", text="Most of the Dagger operations are lazy. The operations which trigger materializations are `async` and therefore must be explicitly awaited. This is why we use `await` to fetch the `uv.lock` file contents. It's a very elegant way to express blocking operations, because once part of the code becomes `async` (blocking), all the code that calls it must also be `async` (blocking). Smart!") }}

{{ admonition(type="note", text="For extra cache efficiency this can be replaced by creating empty directories and files and delaying the source code copying to after the last `uv sync` command, but we will keep it simple for the sake of this blog post. Also, the current approach is already good enough.") }}

---

Our source code is still not copied into the image. Let's implement the `copy_source_code` method which will granularly copy the source code of a given project and its dependencies into the image. This is why we are here!

```python,name=.dagger/src/monorepo_dagger/main.py,hide_lines=1-144 158-1000
{{ remote_text(src="blog/cracking-the-python-monorepo/uv-dagger-dream/.dagger/src/monorepo_dagger/main.py") }}
```

---

Now the only thing left is to install the local dependencies in editable mode:

```python,name=.dagger/src/monorepo_dagger/main.py,hide_lines=1-158 175-1000
{{ remote_text(src="blog/cracking-the-python-monorepo/uv-dagger-dream/.dagger/src/monorepo_dagger/main.py") }}
```

---

All together:

<details>
<summary><strong>Click to reveal the full Dagger module</strong></summary>

```python,name=.dagger/src/monorepo_dagger/main.py,hide_lines=175-1000,linenos
{{ remote_text(src="blog/cracking-the-python-monorepo/uv-dagger-dream/.dagger/src/monorepo_dagger/main.py") }}
```

</details>

<!-- blacken-docs:on -->

The beauty of this approach is that we can now take full advantage of:
- `uv`'s project discovery
- the fact that `uv` workspace configuration is standardized and well-defined
- and always kept in sync with the actual project structure when running `uv` commands

We can build the Docker image for any project in the monorepo with a single command:

```shell
dagger call build-project --root-dir . --project lib-one
```

We can add a project to an arbitrary location in the monorepo, add other projects as dependencies, and build the new project without changing anything:

```shell
uv init --package --lib weird-location/nested/lib-three
uv add --package lib-three lib-one lib-two
dagger call build-project --root-dir . --project lib-three
```

Running `dagger call build-project --root-dir . --project lib-three` just works despite the *weird* location of the `lib-three` project and zero build pipeline changes!

<details>
<summary><strong>Proof</strong></summary>

```shell
dagger call build-project --root-dir . --project lib-three
✔ connect 0.2s
✔ load module 5.4s
✔ parsing command line arguments 2.0s

✔ monorepoDagger: MonorepoDagger! 2.1s
✔ .buildProject(
│ │ debugSleep: 0.000000
│ │ project: "lib-three"
│ │ rootDir: no(digest: "sha256:7112225e5254a6bc947b4ce9318d5ed7e8e5a713df2bb1acefa52bbd739077ce"): Missing
│ ): Container! 8.2s
✔ .defaultArgs: [String!]! 0.0s

✔ Container.mounts: [String!]! 0.0s

✔ Container.entrypoint: [String!]! 0.0s

✔ Container.platform: Platform! 0.0s

✔ Container.user: String! 0.0s

✔ Container.workdir: String! 0.0s

_type: Container
defaultArgs:
    - python3
entrypoint: []
mounts: []
platform: linux/amd64
user: ""
workdir: /src
```

</details>

Now let's confirm caching works as expected. `lib-one` doesn't depend on `lib-two`, so modifying files in `lib-two` should not invalidate the cache for `lib-one`. Because Dagger doesn't always log the intermediate hash digests, we will use the `--debug-sleep` flag to check whether the build stage is skipped.

The first build:

```shell
dagger call build-project --root-dir . --project lib-one --debug-sleep=5
✔ .buildProject(
│ │ debugSleep: 5.000000
│ │ project: "lib-one"
│ │ rootDir: no(digest: "sha256:e52f8c20e2809532808a5be5d1b0313aa8d18d10766fc902b7a22b0358973109"): Missing
│ ): Container! 9.1s
```

Now let's change something in `lib-two` and rebuild `lib-one`:

```shell
touch projects/lib-two/src/lib_two/new_file.py
dagger call build-project --root-dir . --project lib-one --debug-sleep=5
✔ .buildProject(
│ │ debugSleep: 5.000000
│ │ project: "lib-one"
│ │ rootDir: no(digest: "sha256:d1b1986db760ada8081fc3b9ff584ce0c55c006adda7cb324b5f68774bc976e6"): Missing
│ ): Container! 2.6s
```

Hooray! The build only took `2.6s` now --- the cache has not been invalidated and the build stage has been skipped!

{{ admonition(type="info", text="The build is not fully cached because the `--root-dir` argument points at the entire repo (which did change). But it doesn't matter because the **final** image is cached and the build stage is skipped.") }}

## Growing the pipeline

Now that we have a Dagger Function which builds a container for a given project, we can easily create downstream steps in our CI pipeline. For example, this is how we can run tests for a project after building the container:

```python,name=.dagger/src/monorepo_dagger/main.py,hide_lines=1-175 181-1000
{{ remote_text(src="blog/cracking-the-python-monorepo/uv-dagger-dream/.dagger/src/monorepo_dagger/main.py") }}
```

Running the tests becomes:

```shell
dagger call pytest --root-dir . --project lib-one
```

Note how we can do it in one function call. Any upstream steps (like building the image) are automatically executed before the tests and are very likely to be cached.

Another one with `pyright`:

```python,name=.dagger/src/monorepo_dagger/main.py,hide_lines=1-181
{{ remote_text(src="blog/cracking-the-python-monorepo/uv-dagger-dream/.dagger/src/monorepo_dagger/main.py") }}
```

Now we can just call these Dagger functions locally or in our CI/CD system (typically one CI/CD step corresponds to one `dagger call`) --- they will work exactly the same! [Dagger Cloud](https://dagger.io/cloud) can also be used to execute builds remotely (and the entire team can benefit from the shared cache). It's also worth mentioning their [integration with Depot](https://depot.dev/blog/dagger-functions-for-depot) --- provider for accelerated builds and caching, which requires zero configuration and can speed up builds even more.

# Conclusion

When combined together, `uv` and `Dagger` provide powerful features that dramatically simplify build processes in Python monorepos, while maintaining flexibility and providing enormous performance gains.

The pipeline we built is a good starting point for further customization and optimization. You can add more steps to the pipeline, such as linting, code formatting, and deployment steps, and add configuration options to create a comprehensive build process that meets your specific requirements. It's very easy because it's just Python code. You could even generalize this approach to work with multiple `uv` workspaces (so multiple `uv.lock` files) in a single monorepo.

I encourage you to explore the documentation for these tools to fully understand their capabilities and how they can be tailored to your specific needs.

# References and Acknowledgements

- [source code](https://github.com/danielgafni/website/tree/master/www/content/blog/cracking-the-python-monorepo/uv-dagger-dream) for this blog post
- [uv docs](https://docs.astral.sh/uv/getting-started/)
- [Dagger docs](https://docs.dagger.io/quickstart/cli)

---

Thank you [@nordmtr](https://github.com/nordmtr) for the feedback and suggestions!
