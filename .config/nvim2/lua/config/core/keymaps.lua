local keymap = vim.keymap;

-- clear search highlights
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- javascript stuffs
keymap.set("n", "clog", "iconsole.log()<Esc>i")
keymap.set("i", "clog", "console.log()<Esc>i")

-- ctrl f keybinding in neovim
keymap.set("n", "<C-f>", "<cmd>silent !tmux neww ~/scripts/tmux-sessionizer<CR>")

-- get current line diagnostics
keymap.set('n', '<leader>cd', function() vim.diagnostic.open_float({ scope = "line" }) end, { noremap = true, silent = true, desc = "Show current line diagnostics" })

-- git signs keybindings
keymap.set("n", "<leader>ghs", "<cmd>lua require'gitsigns'.stage_hunk()<CR>", { noremap = true, silent = true, desc = "Stage hunk" })
keymap.set("n", "<leader>ghr", "<cmd>lua require'gitsigns'.reset_hunk()<CR>", { noremap = true, silent = true, desc = "Reset hunk" })
keymap.set("n", "<leader>ghp", "<cmd>lua require'gitsigns'.preview_hunk()<CR>", { noremap = true, silent = true, desc = "Preview hunk" })
keymap.set("n", "<leader>ghd", "<cmd>lua require'gitsigns'.diffthis()<CR>", { noremap = true, silent = true, desc = "Diff this" })
