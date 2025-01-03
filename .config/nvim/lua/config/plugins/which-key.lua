return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    -- init = function()
        -- 	vim.o.timeout = true
        -- 	vim.o.timeoutlen = 10000
        -- end,
        opts = {
            delay = 500

        },
        keys = {
            {
                "<leader>?",
                function()
                    require("which-key").show({ global = false })
                end,
                desc = "Buffer Local Keymaps (which-key)",
            },
        },
    }
