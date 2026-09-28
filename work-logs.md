Installed dotfiles on Ubuntu 26.04. It was empty.

Now after installation there are few issues, that I'd like to cover with tests in future

nvim installed, but when I open it there are appears a lot of errors. I press Enter many times. Wait when everything that could installed. Exit. Then open again and again and see this

```
Error detected while processing User Autocommands for "VeryLazy":
tree-sitter CLI not found: `tree-sitter` is not executable!
Press ENTER or type command to continue
```
Enter

```
Error detected while processing User Autocommands for "VeryLazy":
tree-sitter CLI not found: `tree-sitter` is not executable!
Error detected while processing User Autocommands for "VeryLazy":
tree-sitter CLI is needed because `latex` is marked that it needs to be generated from the grammar definitions to be compatible with nvim!

```

Enter
```
nvim-treesitter[jsonc]: Error during tarball extraction.

gzip: stdin: not in gzip format
tar: Child returned status 1
tar: Error is not recoverable: exiting now
```

Enter

```

                                                                                                                                     ╭───────   mason-tool-installer ────────╮
                                                                                                                                     │ isort: failed to install               │
                                                                                                                                     ╰────────────────────────────────────────╯
                                                                                                                                     ╭───────   mason-tool-installer ────────╮
                                                                                                                                     │ black: failed to install               │
                                                                                                                                     ╰────────────────────────────────────────╯
                                                                                                                                     ╭───────   mason-tool-installer ────────╮
                                                                                                                                     │ cmakelang: failed to install           │
                                                                                                                                     ╰────────────────────────────────────────╯
                                                                                                                                     ╭───────   mason-tool-installer ────────╮
                                                                                                                                     │ clang-format: failed to install        │
                                                                                                                                     ╰────────────────────────────────────────╯
                                                                                                                                     ╭───────   mason-tool-installer ────────╮
                                                                                                                                     │ codespell: failed to install           │
                                                                                                                                     ╰────────────────────────────────────────╯
                                                                                                                                     ╭───────   mason-tool-installer ────────╮
                     Home (H)   Install (I)   Update (U)   Sync (S)   Clean (X)   Check (C)   Log (L)   Restore (R)   Profile (P)   D│ debugpy: failed to install             │
                                                                                                                                     ╰────────────────────────────────────────╯
                    Total: 129 plugins                                                                                               ╭───────   mason-tool-installer ────────╮
                                                                                                                                     │ xmlformatter: failed to install        │
                    Failed (1)                                                                                                       ╰────────────────────────────────────────╯
                      ● image.nvim 53.61ms  VeryLazy     ● build failed
                          `/home/sap/.local/share/nvim/lazy-rocks/hererocks/bin/lua` version `5.1` not installed

                          This plugin requires `luarocks`. Try one of the following:
                           - fix your `luarocks` installation
                           - disable *hererocks* with `opts.rocks.hererocks = false`
                           - disable `luarocks` support completely with `opts.rocks.enabled = false`

                          Will try building anyway, but will likely fail...

                          --------------------------------------------------------------------------------

                          Failed to spawn process luarocks {
                            args = { "--tree", "/home/sap/.local/share/nvim/lazy-rocks/image.nvim", "--server", "https://lumen-oss.github.io/rocks-binaries/
                            ", "--lua-version", "5.1", "install", "--force-fast", "--deps-mode", "one", "image.nvim" },
                            cwd = "/home/sap/.local/share/nvim/lazy/image.nvim",
                            env = {
                              PATH = "/home/sap/.local/share/nvim/lazy-rocks/hererocks/bin:/home/sap/.cargo/bin:/home/sap/.local/bin:/home/sap/.local/share/
                              mise/installs/github-fish-shell-fish-shell/4.9.3:/home/sap/.local/share/mise/installs/aqua-tmux-tmux-builds/3.7c:/home/sap/.
                              local/share/mise/installs/github-neovim-neovim-releases/0.11.5/bin:/home/sap/.local/share/mise/installs/aqua-junegunn-fzf/0.74.
                              4:/home/sap/.local/share/mise/installs/aqua-burnt-sushi-ripgrep/15.2.0/ripgrep-15.2.0-x86_64-unknown-linux-musl:/home/sap/.
                              local/share/mise/installs/aqua-sharkdp-fd/10.5.0/.mise-bins:/home/sap/.local/share/mise/installs/aqua-sharkdp-bat/0.26.1/.mise-
                              bins:/home/sap/.local/share/mise/installs/aqua-lsd-rs-lsd/1.2.0/.mise-bins:/home/sap/.local/share/mise/installs/aqua-
                              ajeetdsouza-zoxide/0.10.0:/home/sap/.local/share/mise/installs/aqua-jesseduffield-lazygit/0.65.1:/home/sap/.local/share/mise/
                              installs/github-dandavison-delta/0.19.2:/home/sap/.local/share/mise/installs/aqua-aristocratos-btop/1.4.7/btop/bin:/home/sap/.
                              local/share/mise/installs/pipx-ranger-fm/1.9.4/bin:/home/sap/.local/share/mise/installs/github-sxyazi-yazi/26.9.1:/home/sap/.
                              local/share/mise/installs/aqua-jqlang-jq/1.8.2:/home/sap/.local/share/mise/installs/aqua-tealdeer-rs-tealdeer/1.9.0:/home/sap/.
                              local/share/mise/installs/aqua-filo-sottile-age/1.3.2/age:/home/sap/.local/share/mise/installs/aqua-mordechai-hadad-bob/4.1.7/
                              bob-linux-x86_64:/home/sap/.local/share/mise/installs/aqua-astral-sh-uv/0.12.18/.mise-bins:/home/sap/.local/share/mise/installs/
                              aqua-jesseduffield-lazydocker/0.25.2:/home/sap/.local/share/mise/installs/aqua-cli-cli/2.101.0/gh_2.101.0_linux_amd64/bin:/home/
                              sap/.local/share/mise/installs/pipx-aider-chat/0.86.2/bin:/home/sap/.local/share/mise/installs/pipx-dir2md/0.3.1/bin:/home/sap/.
                              local/share/mise/installs/pipx-dvc/3.67.1/bin:/home/sap/.local/share/mise/installs/pipx-jupytext/1.19.5/bin:/home/sap/.local/
                              share/mise/shims:/home/sap/.npm-global/bin:/home/sap/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/
                              games:/usr/local/games:/snap/bin"
                            },
                            on_line = <function 1>,
                            timeout = 120000
                          }
                          Failed installing image.nvim with `luarocks`.

                          --------------------------------------------------------------------------------

                          Trying to build from source.
                          Failed to spawn process luarocks {
                            args = { "--tree", "/home/sap/.local/share/nvim/lazy-rocks/image.nvim", "--dev", "--lua-version", "5.1", "make", "--force-fast",
                            "--deps-mode", "one" },
                            cwd = "/home/sap/.local/share/nvim/lazy/image.nvim",
                            env = {
                              PATH = "/home/sap/.local/share/nvim/lazy-rocks/hererocks/bin:/home/sap/.cargo/bin:/home/sap/.local/bin:/home/sap/.local/share/
                              mise/installs/github-fish-shell-fish-shell/4.9.3:/home/sap/.local/share/mise/installs/aqua-tmux-tmux-builds/3.7c:/home/sap/.
                              local/share/mise/installs/github-neovim-neovim-releases/0.11.5/bin:/home/sap/.local/share/mise/installs/aqua-junegunn-fzf/0.74.
                              4:/home/sap/.local/share/mise/installs/aqua-burnt-sushi-ripgrep/15.2.0/ripgrep-15.2.0-x86_64-unknown-linux-musl:/home/sap/.
                              local/share/mise/installs/aqua-sharkdp-fd/10.5.0/.mise-bins:/home/sap/.local/share/mise/installs/aqua-sharkdp-bat/0.26.1/.mise-
                              bins:/home/sap/.local/share/mise/installs/aqua-lsd-rs-lsd/1.2.0/.mise-bins:/home/sap/.local/share/mise/installs/aqua-
                              ajeetdsouza-zoxide/0.10.0:/home/sap/.local/share/mise/installs/aqua-jesseduffield-lazygit/0.65.1:/home/sap/.local/share/mise/
                              installs/github-dandavison-delta/0.19.2:/home/sap/.local/share/mise/installs/aqua-aristocratos-btop/1.4.7/btop/bin:/home/sap/.
                              local/share/mise/installs/pipx-ranger-fm/1.9.4/bin:/home/sap/.local/share/mise/installs/github-sxyazi-yazi/26.9.1:/home/sap/.
                              local/share/mise/installs/aqua-jqlang-jq/1.8.2:/home/sap/.local/share/mise/installs/aqua-tealdeer-rs-tealdeer/1.9.0:/home/sap/.
                              local/share/mise/installs/aqua-filo-sottile-age/1.3.2/age:/home/sap/.local/share/mise/installs/aqua-mordechai-hadad-bob/4.1.7/
                              bob-linux-x86_64:/home/sap/.local/share/mise/installs/aqua-astral-sh-uv/0.12.18/.mise-bins:/home/sap/.local/share/mise/installs/
                              aqua-jesseduffield-lazydocker/0.25.2:/home/sap/.local/share/mise/installs/aqua-cli-cli/2.101.0/gh_2.101.0_linux_amd64/bin:/home/
                              sap/.local/share/mise/installs/pipx-aider-chat/0.86.2/bin:/home/sap/.local/share/mise/installs/pipx-dir2md/0.3.1/bin:/home/sap/.
                              local/share/mise/installs/pipx-dvc/3.67.1/bin:/home/sap/.local/share/mise/installs/pipx-jupytext/1.19.5/bin:/home/sap/.local/
                              share/mise/shims:/home/sap/.npm-global/bin:/home/sap/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/
                              games:/usr/local/games:/snap/bin"
                            },
                            on_line = <function 1>,
                            timeout = 120000
                          }

                    Updates (77)
                      ● alabaster.nvim 0.15ms  start     ● updates available
                      ○ android-nvim  kotlin  java  xml      ● updates available

```

---

Also in lazygit selected line highlighting is too dark-blue for light them. I cannot read text inside it

---

I don't like how delta displays diff. This heading in delta view isn't obvious

Here lazygit diff view

```
Δ tests/test_bench_runner.py                                                                                       
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────
                                                                                                                   
─────────────────────────────────────────────────────────────────────────┐                                         
• 108: def test_the_runner_holds_no_scoring_logic_and_knows_no_solver(): │                                         
─────────────────────────────────────────────────────────────────────────┘                                         
 108⋮ 108│    imported = {node.module for node in ast.walk(tree) if isinstance(node, ast.ImportFrom)}              
 109⋮ 109│    imported |= {a.name for node in ast.walk(tree) if isinstance(node, ast.Import) for a in node.names}  
 110⋮ 110│    assert imported <= {"__future__", "json", "time", "pathlib", "typing", "contract", "tasks"}          
 111⋮    │                                                                                                         
 112⋮    │                                                                                                         
 113⋮    │def test_the_benchmark_knows_no_solver():                                                                
 114⋮    │    """odi.bench reaches solvers only through the contract: no solver, model backend or pipeline is      
imported."""
```

claude code internal diff view is simpler and easier to read. Let's use same diffview then.

---

Add just to tool list

---

When I use Ctrl+Alt+F in fish I get `ã` in shell (actually not only in shell, but everywhere in Windows, so it's something with Windows Languages setting)

---

I use Windows Terminal with WSL, do ssh to Ubuntu and tmux here. And I hate coursor flickering on every terminal output change. Also, because it's black, some highlighting like commit message highlighting in lazygit or line highlighting in jless covers text in this line. It's hard to read, what is highligted.

---

dots opens too slow
