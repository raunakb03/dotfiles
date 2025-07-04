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
                        base = "#000000"
                    }
                }
            })
            -- vim.cmd("colorscheme rose-pine")
        end,
    },
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        opts = {},
        config = function()
            require("tokyonight").setup({
                on_colors = function(colors)
                    colors.bg = "#000000"
                end
            })
            -- vim.cmd("colorscheme tokyonight-night")
        end,
    },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "mocha",
                color_overrides = {
                    mocha = {
                        base = "#000000",
                    },
                },
            })
            -- vim.cmd("colorscheme catppuccin")
        end,
    },
    {
        "morhetz/gruvbox",
        config = function()
            vim.g.gruvbox_contrast_dark = "hard"
            vim.g.gruvbox_invert_selection = "0"
            vim.cmd("colorscheme gruvbox")
            vim.cmd("hi Normal guibg=#000000 ctermbg=0")
        end
    }
}
