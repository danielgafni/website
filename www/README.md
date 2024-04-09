# Website

## Development

Nix has to be installed and flakes support enabled.

Entering the development shell (`direnv` and `lorri` can be used to do it automatically):

```shell
nix develop
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
├── flake.lock
├── flake.nix  # nix derivation for website build
├── highlight_themes  # custom syntax highlighting themes
├── sass
├── shell.nix  # nix dev shell for lorri 
├── static  # static files
└── themes  # zola themes
```

