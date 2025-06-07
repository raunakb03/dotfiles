return {
    {
        "rose-pine/neovim",
        name = "rose-pine",
        config = function()
            require("rose-pine").setup({
                variant = "main",
                dark_variant = "main",
                palette = {
                    main = {
                        -- base = "#000000"
                    }
                }
            })
            vim.cmd("colorscheme rose-pine")
        end,
    },
}
