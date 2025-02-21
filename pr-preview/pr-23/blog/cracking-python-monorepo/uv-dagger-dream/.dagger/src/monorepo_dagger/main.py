import tomli
from dagger import Container, Directory, File, dag, function, object_type


import json
from pathlib import Path
from time import time
from typing import (
    Annotated,
    TypeAlias,
)

import dagger
import tomli
from dagger import (
    Container,
    DefaultPath,
    Directory,
    File,
    Ignore,
    Secret,
    Service,
    dag,
    function,
    object_type,
)
from dagger.client.gen import BuildArg


IGNORE = Ignore(
    [
        ".env",
        ".git",
        "**/.venv",
        "**__pycache__**",
        ".dagger/sdk",
        "**/.pytest_cache",
        "**/.ruff_cache",
    ]
)
RootDir: TypeAlias = Annotated[
    dagger.Directory,
    DefaultPath("."),
    IGNORE,
]

SourceDir: TypeAlias = Annotated[
    dagger.Directory,
    IGNORE,
]


@object_type
class MonorepoDagger:
    async def get_local_sources(
        self,
        uv_lock: File,
        project: str,
    ) -> dict[str, str]:
        """Returns a dictionary of the local dependencies' (of a given project) source directories."""
        uv_lock_dict = tomli.loads(await uv_lock.contents())

        members = set(uv_lock_dict["manifest"]["members"])

        local_dependencies = {project}

        # first, find the dependencies of our project
        for package in uv_lock["package"]:
            if package["name"] == project:
                dependencies = package.get("dependencies", [])
                for dep in dependencies:
                    if isinstance(dep, dict) and dep.get("name") in members:
                        local_dependencies.add(dep["name"])

        # now, gather all the directories with the dependency sources

        local_dependencies_sources = {}

        for package in uv_lock["package"]:
            if package["name"] in local_dependencies:
                local_dependencies_sources[package["name"]] = package["source"][
                    "editable"
                ]

        return local_dependencies_sources

    async def build_source_directory_for_project(
        self,
        source_dir: SourceDir,
        project: str,
    ) -> Directory:
        """Creates a clean source directory containing only the source code for a given project and it's dependencies."""
        local_sources = await self.get_local_sources(
            source_dir.file("uv.lock"), project=project
        )

        project_source_code = dag.directory()

        for source in local_sources.values():
            project_source_code.add_directory(source)

        return project_source_code

    @function
    async def build_project(
        self,
        source_dir: Directory,
        project: str,
    ) -> Container:
        """Build a container containing only the source code for a given project and it's dependencies."""

        project_dir = (
            await self.build_source_directory_for_project(source_dir, project)
            .with_file(
                "pyproject.toml",
                source_dir.file("pyproject.toml"),
            )
            .with_file(
                "uv.lock",
                source_dir.file("uv.lock"),
            )
        )

        container = project_dir.docker_build(
            target="deps-dev",
            dockerfile=project_dir.file("Dockerfile"),
        )

        local_sources = await self.get_local_sources(
            source_dir.file("uv.lock"), project=project
        )

        # this loop only creates the directory structure
        # and copies pyproject.toml files
        # so that the actual source code can be copied in the next step after uv sync
        # and only pyproject.toml files affect caching
        for package, location in local_sources.items():
            package_name = (
                tomli.loads(
                    await source_dir.directory(location)
                    .file("pyproject.toml")
                    .contents()
                )["project"]["name"]
                .lower()
                .replace("-", "_")
            )

            container = (
                container.with_exec(["mkdir", "-p", location])
                .with_exec(["touch", f"{location}/README.md"])
                .with_exec(["mkdir", "-p", f"{location}/src/{package_name}"])
                .with_exec(["touch", f"{location}/src/{package_name}/__init__.py"])
            )

        for package, location in local_sources.items():
            container = container.with_file(
                f"{location}/pyproject.toml",
                source_dir.directory(location).file("pyproject.toml"),
            )

        container = container.with_exec(
            [
                "uv",
                "sync",
                "--no-install-package",
                "anam-engine",
                "--inexact",
                "--package",
                project,
            ]
        )

        # copy the source code

        for package, location in local_sources.items():
            container = container.with_directory(
                location,
                source_dir.directory(location),
            )

        return container
