return {
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        opts = {},
        config = function()
            require('tokyonight').setup({
                transparent = true,
                styles = {
                    sidebars = "transparent",
                    floats = "transparent",
                }
            })
            -- vim.cmd.colorscheme "tokyonight-night"
        end,
    },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require('catppuccin').setup({
                flavour = "mocha",
                transparent_background = true,
            })
            vim.cmd.colorscheme "catppuccin-mocha"
        end,
    },
}
