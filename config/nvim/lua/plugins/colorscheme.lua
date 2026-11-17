-- Colorscheme segun el tema activo del sistema (generado por theme-switcher)
local theme = require("theme_current")

return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = theme.scheme,
    },
  },
  { "navarasu/onedark.nvim", lazy = true, priority = 1000, opts = { style = "dark" } },
  { "folke/tokyonight.nvim", lazy = true, priority = 1000, opts = { style = "night" } },
  { "catppuccin/nvim", name = "catppuccin", lazy = true, priority = 1000, opts = { flavour = "mocha" } },
  { "ellisonleao/gruvbox.nvim", lazy = true, priority = 1000, opts = { contrast = "hard" } },
  { "shaunsingh/nord.nvim", lazy = true, priority = 1000 },
  { "Mofiqul/dracula.nvim", lazy = true, priority = 1000 },
}
