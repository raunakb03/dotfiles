return {
    "mbbill/undotree",
    config = function()
        vim.keymap.set('n', "<leader>z", "<cmd>UndotreeToggle<CR>", { desc = "Toggle Undo Tree" })
    end,
}
