+++
title = "NixOS Config"
description = "My mutli-host NixOs configuration"
weight = 10
[taxonomies]
tags = ["nix", "nixos"]

[extra]
social_media_card = "./static/img/social_cards/projects_nixos.jpg"
+++

I am using [NixOS](https://nixos.org/) to make my development machines rock solid, stable, reliable and recoverable. 

NixOS offers declarative system configuration, which can be checked into VCS, and the ability to boot into any of the previous builds (in case something went wrong). 

My [NixOS](https://nixos.org/) [repo](https://github.com/danielgafni/nixos) features:
 - [flakes](https://nixos.wiki/wiki/Flakes) - every piece of software in my systems is pinned 
 - nix-pre-commit hooks for dev checks and tests
 - two hosts: PC and laptop, which share most of the configuration
 - GitHub Actions which:
   * run build for all target hosts  
   * cache derivation outputs with [Cachix](https://app.cachix.org/cache/danielgafni#pull)
   * run tests and check `flake.lock`
   * automatically submit a PR with updates for all dependencies once per week
 - Catppuccin Mocha theme

