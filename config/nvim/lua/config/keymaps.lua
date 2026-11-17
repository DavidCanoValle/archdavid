-- Atajos personales
local map = vim.keymap.set

map({ "i", "n", "v" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Guardar" })
map("n", "<C-q>", "<cmd>confirm q<cr>", { desc = "Cerrar ventana" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Salir de Neovim" })

-- Mover lineas en modo visual
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Mover linea abajo" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Mover linea arriba" })

-- Mantener la seleccion al indentar
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Inlay hints
map("n", "<leader>uh", function()
  local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
  vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
end, { desc = "Alternar inlay hints" })

-- Selector de temas del sistema (rofi)
map("n", "<leader>ut", function()
  vim.fn.jobstart({ "bash", vim.fn.expand("~/.config/theme-switcher/theme-menu.sh") }, { detach = true })
end, { desc = "Selector de temas" })
