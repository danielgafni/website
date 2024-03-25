+++
title = "The Modern CLI Stack"
date = 2022-09-20
[taxonomies]
tags = ["cli", "linux", "development"]
+++

This is a copy of my old Medium [article](https://danielgafni.medium.com/the-modern-linux-cli-stack-46253688b53d). The tools mentioned in the article have stood the test of time as for 2024!


---


This post is about the awesome Rust-based **cross-platform** CLI ecosystem which I’ve discovered recently.

Meet the main characters:

```
shell: **nushell**  
prompt: **starship**  
terminal multiplexer: **zellij**
```

versus my old stack:

```
shell: zsh  
plugin manager: oh-my-zsh / antigen  
prompt: powerlevel10k  
terminal multiplexer: tmux
```

which is a basic and very common CLI stack to be found at `/r/unixporn` subreddit (at this point I’ve been using it for ricing my Linux setup for more than 2 years).

So, the Rust stack doesn’t even have a shell plugin manager? Yes! Seems like no shell plugins are needed. All the mentioned tools already implement everything one can need. Even more, they **rarely need any configuration at all**! Of course, they are very configurable, but unlike many old tools they don’t use obscure config files with a tool-specific syntax. Instead of that, normal `yaml` or `toml` files are used.

After trying them out I immediately decided there was no going back.

In this post I will not describe the installation or configuration of these tools (you can always read the docs), but rather highlight the **key features** and explain the **benefits** over the traditional tools.

Nushell
=======

[Nushell](https://www.nushell.sh/), or `nu`, is a modern data-oriented shell written in Rust. It needs almost zero configuration to start working with it, even tho a lot can be configured, has syntax highlighting, auto-completion and other useful features enabled by default. It implements all shell commands (like `ls`, `cat`, etc) in a way that is aware of the contents of the input/output of these commands. Lets take a look at this example:

As we can see, `nu` stores the data representation (in this case the `ls` command output) as a table, while `bash/zsh` `ls` outputs simple text. In fact, the way these tables are rendered can seem familiar to some of you… yes, `nu` is using `polars.DataFrame` internally!

The same can be applied to any file:

This is extremely useful when working with `yaml` , `toml` , `json` , `csv` and other structured files. No need to use `grep` or enter `vim` !

Another positive side of `nu` is it's **error handling**.

The shell is clearly pointing us at the error source.

**Nu DataFrames: a bonus for a Data Scientist**

Because `nu` is using `polars` internally, it is possible to perform DataFrame operations from the `nu` shell directly! It’s also performing way better than `pandas`, of course. Here is an example from the documentation:

nu scripting for DataFrame manipulations

This is just mind-blowing. A lot of complex operations on data can be performed without opening Jupyter at all.

By the way, `nushell` is officially supported by `Poetry` since `1.2.0`.

Starship
========

[Starship](https://starship.rs/) is a terminal prompt written in .. yes, in Rust. It makes in very fast (actually, this is not an improvement over `powerlevel10k` since it’s written in C++). Starship has very rich configuration options in a simple `yaml` file. But, just like `nushell` , it doesn't _need_ any configuration initially - all the defaults are already set! It also provides nice ready-to-use config [presets](https://starship.rs/presets/#nerd-font-symbols).

Starship automatically integrates with multiple other tools & technologies. It can display package versions (for example, when in a `Poetry` project), show AWS region, kubernetes context & namespace.. in short, it works with everything. Take a look at the full list of integrations [here](https://starship.rs/config/#prompt).

Of course, it also looks good. Here is the default prompt with no configuration:

Starship in action

Zellij
======

[Zellij](https://zellij.dev/) is a terminal multiplexer written in Python. Kidding, it’s actually written in R…. Rust. It’s very similar to `tmux`, and even supports `tmux` commands, but has some user-friendly advantages:

1.  Operation [modes](https://zellij.dev/documentation/keybindings-modes.html): pane, tab, resize, etc…
2.  The panes are mouse-scrollable and mouse-clickable
3.  [Layouts](https://zellij.dev/documentation/layouts-templates.html) can be saved to simple `yaml` files. For example, a layout can be saved for every project you are working on.

Zellij

For every operational mode there are very limited possible actions. Thanks to that, a help bar is displayed showing the current available commands.

normal mode hintspane mode hintstab mode hints

The modes can be easily switched with: `ctrl+p` = pane, `ctrl+t` = tab, etc. It’s really a blessing for a newcomer. You don’t need to read tutorials or search how to do “this thing I really need right now” in `zellij`. The bar in the bottom will make sure you are never lost. After you learn `zellij`, the bar can be hidden.

Thanks to the limited available actions per mode, the navigation through `zellij` is greatly simplified.

Again, you don’t need to configure anything at all to achieve this! In contrary,`tmux` needs a dozen of plugins. Of course, `zellij` supports plugins too.

Bonus: other awesome Rust CLI tools
===================================

**Wezterm**

[Wezterm](https://wezfurlong.org/wezterm/index.html) is a terminal emulator written in Rust. I’m currently exploring it in favor of [Alacritty](https://alacritty.org/) because the latter doesn’t support ligatures. It can also act as terminal multiplexer and supports tabs for ssh-sessions.

**bat**

`bat`  is `cat` with syntax highlighting:

yamlPython

**sheldon**

[sheldon](https://github.com/rossmacarthur/sheldon) is a shell plugin manager that currently works with `bash`and `zsh`. It has a nice CLI interface and stores the config in a readable `.toml` file.

**btop**

`btop`is a resources monitoring tool like `htop` , but with a more intuitive UI and controls. Sadly, it’s not written in rust, but I decided to included it here anyway.

You can find more awesome Rust CLI tools in [this](https://www.reddit.com/r/rust/comments/xgwe4u/your_favourite_rust_cli_utilities_this_year/) Reddit post.

I’m currently working on updating my old dotfiles repos ([1](https://github.com/danielgafni/dotfiles), [2](https://github.com/danielgafni/useful-materials)) to include these tools & their configs.

I would love to hear about other useful CLI tools in the comments! Also, make sure to correct me if I’m wrong anywhere. Finally, subscribe to my Telegram [channel](https://t.me/nadya_nafig) for more dev & ML content.

