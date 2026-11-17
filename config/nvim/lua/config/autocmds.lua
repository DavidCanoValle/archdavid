-- Automatizaciones personales
local aug = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- Resaltar al copiar
vim.api.nvim_create_autocmd("TextYankPost", {
  group = aug,
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 160 })
  end,
})

-- Ortografia en markdown y git commit
vim.api.nvim_create_autocmd("FileType", {
  group = aug,
  pattern = { "markdown", "gitcommit", "text" },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = { "es", "en" }
  end,
})

-- Volver a la ultima posicion del cursor
vim.api.nvim_create_autocmd("BufReadPost", {
  group = aug,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Recargar el colorscheme al cambiar de tema (SIGUSR1)
vim.api.nvim_create_autocmd("Signal", {
  group = aug,
  callback = function()
    package.loaded["theme_current"] = nil
    local ok, theme = pcall(require, "theme_current")
    if ok and theme.scheme then
      pcall(vim.cmd.colorscheme, theme.scheme)
      vim.notify("Tema recargado: " .. theme.scheme, vim.log.levels.INFO)
    end
  end,
})
