local keymap = vim.keymap;

-- ctrl f keybinding in neovim
keymap.set("n", "<C-f>", "<cmd>silent !tmux neww ~/scripts/tmux-sessionizer<CR>")

keymap.set("n", "<leader>nh", "<cmd>nohl<CR>", { desc = "Clear search highlights" })

keymap.set("n", "clog", "iconsole.log()<Esc>i")
keymap.set("i", "clog", "console.log()<Esc>i")

