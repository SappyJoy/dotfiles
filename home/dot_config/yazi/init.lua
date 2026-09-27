-- File icons take the color of their file name (theme.toml [filetype]: ANSI colors),
-- not yazi's ~700 fixed hex icon colors, which ignore kitty's theme. This is yazi's
-- own Entity:icon (26.9) without the icon style.
function Entity:icon()
	local icon = th.icon:match(self._file, { hovered = self._file.is_hovered })
	return icon and icon.text .. " " or ""
end
