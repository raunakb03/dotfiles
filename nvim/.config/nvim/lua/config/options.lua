vim.opt.guicursor = "" -- set the cursor to be a vertical bar
vim.g.autoformat = false -- disable auto-save
vim.g.lazyvim_picker = "fzf" -- use fzf as file picker
vim.g.ai_cmp = false -- disable AI in completion engine
vim.g.lazyvim_cmp = "blink.cmp" -- use blink as completion engine

-- do not auto comment the next line after commenting a line
vim.cmd("autocmd BufEnter * set formatoptions-=cro")
vim.cmd("autocmd BufEnter * setlocal formatoptions-=cro")

-- set tab size to 4 spaces
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

vim.opt.list = false
