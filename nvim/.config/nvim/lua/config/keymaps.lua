-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>j", ":b#<CR>", { desc = "Toggle between buffers", silent = true })
-- stylua: ignore
vim.keymap.set("v", "y", "myy`y", { desc = "Maintain the cursor position when yanking a visual selection", silent = true })
vim.keymap.set("n", "<leader>bx", ":bufdo bdelete<CR>", { desc = "Delete all buffers", silent = true })
vim.keymap.set("n", "<leader>bsd", "<cmd>%bd|e#|bd#<cr>|'<cr>", { desc = "Delete surrounding buffers" })
vim.keymap.set("n", "<leader>ut", ":set list!<CR>", { desc = "Toggle list", silent = true })
vim.keymap.set("n", "Y", "yg$", { desc = "Copy to the end of the line", silent = true })
-- stylua: ignore
vim.keymap.set("n", "n", "nzzzv", { desc = "Keep the window centered (next search result)", silent = true })
-- stylua: ignore
vim.keymap.set("n", "N", "Nzzzv", { desc = "Keep the window centered (previous search result)", silent = true })

-- Last definition wins on the Mac, so + and - close and open folds.
vim.keymap.set("n", "-", "<CMD>foldclose<CR>", { desc = "Close code fold" })
vim.keymap.set("n", "+", "<CMD>foldopen<CR>", { desc = "Open code fold" })

vim.keymap.set("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
vim.keymap.set("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })

vim.keymap.set("v", "<", "<gv", { desc = "Stay in indent mode (left)", silent = true })
vim.keymap.set("v", ">", ">gv", { desc = "Stay in indent mode (right)", silent = true })
