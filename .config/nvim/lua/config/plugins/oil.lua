return {
    {
        'stevearc/oil.nvim',
        opts = {},
        dependencies = { { "echasnovski/mini.icons", opts = {} } },
        config = function()
            require('oil').setup({
                use_default_keymaps = false,
                keymaps = {
                    ["<CR>"] = "actions.select",
                    ["<C-p>"] = "actions.preview",
                },
            })
        end,
    }
}
