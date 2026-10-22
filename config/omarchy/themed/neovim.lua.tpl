-- Generado por Omarchy desde ~/.config/omarchy/themed/neovim.lua.tpl para temas que no
-- traen neovim.lua propio (sin él LazyVim falla con "Failed to load plugins.theme").
-- Usa aether.nvim con los colores ANSI de colors.toml, que todos los temas definen.
return {
	{
		"bjarneo/aether.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			colors = {
				bg = "{{ background }}",
				dark_bg = "{{ background }}",
				darker_bg = "{{ background }}",
				lighter_bg = "{{ color0 }}",
				fg = "{{ foreground }}",
				dark_fg = "{{ color7 }}",
				light_fg = "{{ foreground }}",
				bright_fg = "{{ color15 }}",
				muted = "{{ color8 }}",
				red = "{{ color1 }}",
				yellow = "{{ color3 }}",
				orange = "{{ color9 }}",
				green = "{{ color2 }}",
				cyan = "{{ color6 }}",
				blue = "{{ color4 }}",
				purple = "{{ color5 }}",
				brown = "{{ color8 }}",
				bright_red = "{{ color9 }}",
				bright_yellow = "{{ color11 }}",
				bright_green = "{{ color10 }}",
				bright_cyan = "{{ color14 }}",
				bright_blue = "{{ color12 }}",
				bright_purple = "{{ color13 }}",
				accent = "{{ accent }}",
				cursor = "{{ cursor }}",
				foreground = "{{ foreground }}",
				background = "{{ background }}",
				selection = "{{ selection_background }}",
			},
		},
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "aether",
		},
	},
}
