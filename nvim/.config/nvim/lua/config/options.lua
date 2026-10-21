-- Options are automatically loaded before lazy.nvim startup.
require("config.remote_clipboard").setup()

-- Omarchy turns relative numbers and format-on-save off. Keep both.
vim.opt.relativenumber = false
vim.g.autoformat = false

vim.opt.autowrite = true
vim.opt.backspace = { "indent", "eol", "start" }
vim.opt.copyindent = true
vim.opt.foldlevel = 2
vim.opt.fillchars = "fold: "
vim.opt.cursorline = false
vim.opt.foldlevelstart = 99
vim.opt.foldmethod = "indent"
vim.opt.foldnestmax = 10
vim.opt.grepprg = "rg --vimgrep --no-heading --smart-case"
vim.opt.listchars = { tab = "↦ ", trail = "·", nbsp = ".", extends = "❯", precedes = "❮" }
vim.opt.showbreak = "↪"
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.title = true
vim.opt.swapfile = false
vim.opt.virtualedit = "block,insert"
vim.opt.conceallevel = 2

vim.opt.iskeyword:append("-")
vim.opt.wildignore:append({ "*/node_modules/*" })
vim.opt.complete:append({ "i", "k", "s", "kspell" })

-- Only the project root should be the root.
vim.g.root_spec = { ".git" }

-- Personal word lists live under ~/.config/nvim, which is on the runtimepath,
-- so the de/en spell files there are found without an extra path. A literal
-- "~/" in 'spellfile' is not expanded and zg cannot write it.
vim.opt.spellfile:append(vim.fn.expand("~/.config/nvim/spell/en.utf-8.add"))
vim.opt.dictionary:append({
  vim.fn.expand("~/.config/nvim/dictionary/de_user.txt"),
  vim.fn.expand("~/.config/nvim/dictionary/de_neu.txt"),
  vim.fn.expand("~/.config/nvim/dictionary/en_us.txt"),
})
vim.opt.thesaurus:append({
  vim.fn.expand("~/.config/nvim/thesaurus/de_user.txt"),
  vim.fn.expand("~/.config/nvim/thesaurus/de_openthesaurus.txt"),
})
