-- Personalizacion de la interfaz
return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.theme = "auto"
      opts.options.globalstatus = true
      opts.options.section_separators = ""
      opts.options.component_separators = ""
      return opts
    end,
  },
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      stiffness = 0.8,
      trailing_stiffness = 0.5,
      damping = 0.9,
      distance_stop_animating = 0.5,
    },
  },
  {
    "petertriho/nvim-scrollbar",
    -- v2: fijado a la rama v2 hasta que se fusione en `main`.
    branch = "refactor/v2",
    event = "VeryLazy",
    opts = {
      -- v1 `handlers` -> v2 `providers`. `handle` ya no es provider:
      -- el thumb se controla con `scrollbar.layout.columns` (por defecto está).
      providers = {
        cursor = false,
        search = false,
        diagnostic = false,
        marks = false,
      },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = [[
╭────────────────────────────╮
│                            │
│        /\       ARCH LINUX │
│       /  \      lazyvim    │
│      / /\ \     nvim       │
│     /_/  \_\               │
│                            │
╰────────────────────────────╯
]],
        },
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    opts = {},
  },
  -- mini.animate: anima scroll y ventanas, pero el cursor lo anima smear-cursor
  {
    "nvim-mini/mini.animate",
    opts = {
      cursor = { enable = false },
      scroll = { enable = true, speed = 14 },
      resize = { enable = true },
      open = { enable = true },
      close = { enable = true },
    },
  },
}
