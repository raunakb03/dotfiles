-- My keymaps
vim.keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" }) -- clear search highlights
vim.keymap.del("n", "<leader>n") -- remove lazyvim show all notification keymap
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww ~/scripts/tmux-sessionizer<CR>", { desc = "Start Tmux Sessionizer" }) -- start tmux sessionizer

-- from ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/ui.lua file
vim.keymap.set("n", "<leader>nn",
  function()
    if Snacks.config.picker and Snacks.config.picker.enabled then
      Snacks.picker.notifications()
    else
      Snacks.notifier.show_history()
    end
  end, { desc = "Notification History" })

-- Copilot keymaps
-- vim.keymap.set("n", "<leader>aa", "<cmd>CopilotChatToggle<cr>", { noremap = true, silent = true, desc = "Toggle Copilot Chat" })
-- vim.keymap.set("n", "<leader>ad", "<cmd>Copilot disable<cr>", { noremap = true, silent = true, desc = "Disable Copilot" })
-- vim.keymap.set("n", "<leader>ae", "<cmd>Copilot enable<cr>", { noremap = true, silent = true, desc = "Enable Copilot" })

-- Undotree keymaps
vim.keymap.set("n", "<leader>zz", "<cmd>UndotreeToggle<CR>", { noremap = true, desc = "Toggle Undo Tree" })

-- Tmux navigator keymaps
vim.keymap.set('n', "<C-h>", "<cmd>TmuxNavigateLeft<CR>")
vim.keymap.set('n', "<C-j>", "<cmd>TmuxNavigateDown<CR>")
vim.keymap.set('n', "<C-l>", "<cmd>TmuxNavigateRight<CR>")
vim.keymap.set('n', "<C-k>", "<cmd>TmuxNavigateUp<CR>")

