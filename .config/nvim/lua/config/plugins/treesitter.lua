return {
    {
        "nvim-treesitter/nvim-treesitter",
        event = { "BufReadPre", "BufNewFile" },
        build = ":TSUpdate",
        config = function()
            require('nvim-treesitter.configs').setup({
                ensure_installed = {},
                sync_install = true,
                ignore_install = {},
                auto_install = true,
                highlight = {
                    enable = true,
                },
            })
        end,
    }
}
