return {
    {
        "folke/tokyonight.nvim",
        lazy = true,
        opts = {
            transparent = true,
            style = "night",
            -- on_colors = function(colors)
            --     colors.bg = "#000000"
            -- end
        },
    },
    {
	"rose-pine/neovim",
	name = "rose-pine",
	config = function()
            require("rose-pine").setup({
                styles = {
                    transparency = true,
                }
            })
		-- vim.cmd("colorscheme rose-pine")
	end
    }, 
    {
        "shaunsingh/nord.nvim",
        name = "nord",
        config = function()
		-- vim.cmd("colorscheme nord")
        end,
    },
    {
        "scottmckendry/cyberdream.nvim",
        config = function()
            require("cyberdream").setup({
                theme = "auto"
            })
            -- vim.cmd("colorscheme cyberdream")
        end,
    },
    {
        "rebelot/kanagawa.nvim",
        config = function()
            require("kanagawa").setup({
                transparent = true
            })
            vim.cmd("colorscheme kanagawa-dragon")
        end
    }
}
