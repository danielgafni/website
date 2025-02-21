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
    BuildArg,
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
    @function
    async def build_project(
        self,
        source_dir: Directory,
        project: str,
    ) -> Container:
        """Build a container containing only the source code for a given project and it's dependencies."""
        # we start by creating a container including only third-party dependencies
        # with no source code (except pyproject.toml and uv.lock from the repo root)
        container = self.container_with_third_party_dependencies(
            pyproject_toml=source_dir.file("pyproject.toml"),
            uv_lock=source_dir.file("uv.lock"),
            dockerfile=source_dir.file("Dockerfile"),
            project=project,
        )

        # here we parse the uv.lock file to find the source code of the dependencies of a given project
        project_sources_map = await self.get_project_sources_map(source_dir, project)

        # we create empty directories in the container so that the next step passes
        container = self.copy_source_code(container, source_dir, project_sources_map)

        # we run `uv sync` to create editable installs of the local dependencies
        # pointing (for now) to the dummy directories we created in the previous step
        container = self.install_local_dependencies(container, project)

        # finally, we fill the dummy directories with the actual source code
        container = self.copy_project_source_code(container, project_sources_map)

        return container

    def container_with_third_party_dependencies(
        self,
        pyproject_toml: File,
        uv_lock: File,
        dockerfile: File,
        project: str,
    ) -> Container:
        # create an empty directory to make sure only the pyproject.toml
        # and uv.lock files are copied to the build context (to affect caching)
        build_context = (
            dag.directory()
            .with_file(
                "pyproject.toml",
                pyproject_toml,
            )
            .with_file(
                "uv.lock",
                uv_lock,
            )
            .with_new_file("README.md", "Dummy README.md")
        )

        return build_context.docker_build(
            target="deps-dev",
            dockerfile=dockerfile,
            build_args=[BuildArg(f"PACKAGE={project}")],
        )

    async def get_project_sources_map(
        self,
        uv_lock: File,
        project: str,
    ) -> dict[str, str]:
        """Returns a dictionary of the local dependencies' (of a given project) source directories."""
        uv_lock_dict = tomli.loads(await uv_lock.contents())

        members = set(uv_lock_dict["manifest"]["members"])

        local_projects = {project}

        # first, find the dependencies of our project
        for package in uv_lock["package"]:
            if package["name"] == project:
                dependencies = package.get("dependencies", [])
                for dep in dependencies:
                    if isinstance(dep, dict) and dep.get("name") in members:
                        local_projects.add(dep["name"])

        # now, gather all the directories with the dependency sources

        project_sources_map = {}

        for package in uv_lock["package"]:
            if package["name"] in local_projects:
                project_sources_map[package["name"]] = package["source"]["editable"]

        return project_sources_map

    def copy_source_code(
        container: Container,
        source_dir: SourceDir,
        project_source_mapping: dict[str, str],
    ) -> Container:
        # copy the full source code

        for package, location in project_source_mapping.items():
            container = container.with_directory(
                location,
                source_dir.directory(location),
            )

        return container

    def install_local_dependencies(
        self, container: Container, project: str
    ) -> Container:
        container = container.with_exec(
            [
                "uv",
                "sync",
                "--inexact",
                "--package",
                project,
            ]
        )

        return container
