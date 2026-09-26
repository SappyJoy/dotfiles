set -U fish_color_autosuggestion brblack                # 'brblack' is fine
set -U fish_color_cancel -r                           # '\x2dr' means '-r' (reset flag)
set -U fish_color_command normal
set -U fish_color_comment red
set -U fish_color_cwd green
set -U fish_color_cwd_root red
set -U fish_color_end green
set -U fish_color_error brred
set -U fish_color_escape brcyan
set -U fish_color_history_current --bold              # '\x2d\x2dbold' means '--bold'
set -U fish_color_host normal
set -U fish_color_host_remote yellow
set -U fish_color_normal normal
set -U fish_color_operator brcyan
set -U fish_color_param cyan
set -U fish_color_quote yellow
set -U fish_color_redirection cyan --bold             # 'cyan\x1e\x2d\x2dbold' -> cyan --bold
set -U fish_color_search_match white --background=brblack # 'white\x1e\x2d\x2dbackground\x3dbrblack' -> white --background=brblack
set -U fish_color_selection white --bold --background=brblack # 'white\x1e\x2d\x2dbold\x1e\x2d\x2dbackground\x3dbrblack' -> white --bold --background=brblack
set -U fish_color_status red
set -U fish_color_user brgreen
set -U fish_color_valid_path --underline              # '\x2d\x2dunderline' -> --underline

# Key Bindings (You had this in the list, might belong elsewhere but can be set here)
set -U fish_key_bindings fish_default_key_bindings

# Pager Colors
set -U fish_pager_color_completion normal
set -U fish_pager_color_description yellow -i # '-i' flag for italics might need 'yellow -i' if your terminal supports it, otherwise just 'yellow'
set -U fish_pager_color_prefix normal --bold --underline # 'normal\x1e\x2d\x2dbold\x1e\x2d\x2dunderline' -> normal --bold --underline
set -U fish_pager_color_progress brwhite --background=cyan # 'brwhite\x1e\x2d\x2dbackground\x3dcyan' -> brwhite --background=cyan
set -U fish_pager_color_selected_background --background=brblack # '\x2dr' likely means reset foreground, and set background. '--background=brblack' is clearer. Check `set -S fish_pager_color_selected_background` output if unsure. Often just `--background=<color>` is sufficient.
