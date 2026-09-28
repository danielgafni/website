
# options: prod,dev
ARG INCLUDE_DEPENDENCIES=dev
ARG PYTHON_VERSION=3.12.8

FROM python:${PYTHON_VERSION}-slim AS base

ENV DEBIAN_FRONTEND=noninteractive
# some apt packages usually needed in Python projects
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && apt-get install -y git curl gcc libpq-dev

# install uv (https://github.com/astral-sh/uv)
# docs for using uv with Docker: https://docs.astral.sh/uv/guides/integration/docker/
COPY --from=ghcr.io/astral-sh/uv:0.5.27 /uv /bin/uv

# UV_PROJECT_ENVIRONMENT configures the environment for the uv project interface
# UV_PYTHON configures the python executable for the uv pip interface
ENV UV_PROJECT_ENVIRONMENT=/usr/local/ \
    UV_PYTHON=/usr/local/bin/python \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_FROZEN=1

FROM base AS deps-prod

WORKDIR /src

COPY pyproject.toml uv.lock  ./

ARG PACKAGE
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --no-install-workspace --all-extras --no-dev --package $PACKAGE

FROM deps-prod AS deps-dev

ARG PACKAGE
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --no-install-workspace --only-group dev --inexact && \
    uv sync --no-install-workspace --all-extras --inexact --package $PACKAGE

# -------------------------------------------------------------
FROM deps-${INCLUDE_DEPENDENCIES} AS final

ARG PACKAGE

# Copy all the rest of the code
COPY . .

# finally install our code
RUN uv sync --all-extras --inexact --package $PACKAGE
