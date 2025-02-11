local opt = vim.opt

vim.g.lazyvim_picker = "telescope"
vim.g.lazyvim_cmp = "nvim-cmp"

vim.g.autoformat = false

-- do not auto comment the next line after commenting a line
vim.cmd("autocmd BufEnter * set formatoptions-=cro")
vim.cmd("autocmd BufEnter * setlocal formatoptions-=cro")

opt.signcolumn = 'yes' -- side column does not shift rightwards after changing text

opt.tabstop = 4 -- 4 spaces for tabs (prettier default)
opt.shiftwidth = 4 -- 4 spaces for indent width

opt.guicursor = ""
