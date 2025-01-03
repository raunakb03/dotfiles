return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
        "MunifTanjim/nui.nvim",
        -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
    },
    config = function()
        require("neo-tree").setup({
            close_if_last_window = true, -- Close Neo-tree if it is the last window left in the tab
            window = {
                position = "right",
                width = 30
            },
            vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle neo-tree"})
        })

    end,
}
