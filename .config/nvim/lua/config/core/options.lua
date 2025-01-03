local opt = vim.opt

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

opt.fillchars = {
    vert = "▕",
    fold = " ",
    eob = " ",
    diff = "╱",
    msgsep = "‾",
    foldopen = "▾",
    foldsep = "│",
    foldclose = "▸",
}

opt.clipboard = "unnamedplus"  -- make system clipboard sync with neovim clipboard

opt.number = true  -- set numbering true
opt.relativenumber = true  -- set relative numbering true

opt.signcolumn = 'yes' -- side column does not shift rightwards after changing text

-- disabling auto commenting of the line on enter
vim.cmd("autocmd BufEnter * set formatoptions-=cro")
vim.cmd("autocmd BufEnter * setlocal formatoptions-=cro")

-- tabs & indentation
opt.tabstop = 4 -- 4 spaces for tabs (prettier default)
opt.shiftwidth = 4 -- 4 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one

opt.wrap = false -- do not wrap line in the next line

opt.cursorline = true -- highlight the current line

-- code folding options
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = ""
opt.foldlevel = 99

vim.cmd("let g:netrw_liststyle = 3") -- changing view of the nvim tree directory

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

-- appearance
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- scroll after the middle
opt.scrolloff = 999
opt.guicursor = ""

-- turn off swap file
opt.swapfile = false
opt.backup = false
opt.writebackup = false

opt.colorcolumn = "90"

opt.wildignore:append({"*/node_modules/*"})

vim.o.undofile = true
