return {
    "mbbill/undotree",
    config = function()
        vim.keymap.set('n', "<leader>zz", "<cmd>UndotreeToggle<CR>", { desc = "Toggle Undo Tree" })
    end,
}
