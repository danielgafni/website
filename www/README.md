# Website

## Development

Nix and [`devenv`](https://devenv.sh) have to be installed. Enter the development shell from the repo root (`direnv` can be used to do it automatically):

```shell
devenv shell
```

Running the website locally:

```shell
cd www
zensical serve
```

The site only needs [`uv`](https://docs.astral.sh/uv/): `uv run zensical serve` works without the dev shell (uv installs Python from `.python-version`).

Social (Open Graph) cards are generated per page from each page's `title` and `description` by `scripts/social_cards.py` (Zensical can't render them yet). Run it before building to get them locally; CI runs it on every build:

```shell
uv run python scripts/social_cards.py
```

# File Structure

```
.
├── zensical.toml  # Zensical config
├── pyproject.toml  # Python dependencies (zensical), part of the root uv workspace
├── docs  # website content as markdown files (the blog lives at the root)
│   ├── posts  # blog posts
│   └── projects  # project pages, rendered as cards
├── overrides  # theme template overrides
├── scripts  # social card generator (+ bundled fonts)
└── snippets  # code embedded into posts via pymdownx.snippets
```
