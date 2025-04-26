return {
    {
        "rose-pine/neovim",
        name = "rose-pine",
        config = function()
            require("rose-pine").setup({
                styles = {
                    transparency = true,
                }
            })
            vim.cmd("colorscheme rose-pine")
        end
    },
    {
        "ellisonleao/gruvbox.nvim",
        priority = 1000 ,
        config = function()
            -- vim.cmd("colorscheme gruvbox")
        end,
    }
}
