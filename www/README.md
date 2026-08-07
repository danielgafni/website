# Website

## Development

Nix and [`devenv`](https://devenv.sh) have to be installed (flakes support enabled).

Entering the development shell (`direnv` can be used to do it automatically):

```shell
devenv shell
```

Running the website locally:

```shell
zola serve
```

# File Structure

```
.
├── config.toml  # zola config
├── content  # actual website content as markdown files
├── devenv.nix  # dev shell (zola)
├── devenv.yaml  # devenv inputs
├── flake.lock
├── flake.nix  # nix derivation for the website build (nix build ./www)
├── highlight_themes  # custom syntax highlighting themes
├── sass
├── static  # static files
└── themes  # zola themes
```

