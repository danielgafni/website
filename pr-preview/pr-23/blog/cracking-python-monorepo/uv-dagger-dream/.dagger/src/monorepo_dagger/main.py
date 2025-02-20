import tomli
from dagger import Container, Directory, File, dag, function, object_type


@object_type
class MonorepoDagger:
    @function
    async def build_project(
        self,
        source_dir: Directory,
        project: str,
    ) -> Container:
        """Granularly builds a project and its dependencies."""
        project_dir = await self.build_source_directory_for_project(source_dir, project)
        container = project_dir.docker_build(
            target="deps-dev",
            dockerfile=source_dir.file("Dockerfile"),
        )

        local_sources = await self.get_local_sources(
            source_dir.file("uv.lock"), project=project
        )

        for package, location in local_sources.items():
            container.with_new_directory(location)
            ...

    async def build_source_directory_for_project(
        self,
        source_dir: Directory,
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
