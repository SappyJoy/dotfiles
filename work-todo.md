

  set ts (date +%Y%m%d-%H%M%S)
  mv ~/.config/nvim ~/.config/nvim.bak-$ts
  mkdir ~/.local/share/nvim.bak-$ts
  for f in ~/.local/share/nvim/*
      test (path basename $f) = venv; or mv $f ~/.local/share/nvim.bak-$ts/
  end
  mv ~/.local/state/nvim ~/.local/state/nvim.bak-$ts
  mkdir -p ~/.local/state/nvim/shada
  cp ~/.local/state/nvim.bak-$ts/shada/main.shada ~/.local/state/nvim/shada/
  chezmoi update     # if it asks about .config/nvim: o
  cp ~/.config/nvim.bak-$ts/db_ui/connections.json ~/.config/nvim/db_ui/ 2>/dev/null

  chezmoi update then installs nvim 0.12.5 through mise and runs the plugin installer, which takes a few minutes.
