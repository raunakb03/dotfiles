return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "stevearc/conform.nvim",
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "j-hui/fidget.nvim",
        {
            {
                "folke/lazydev.nvim",
                ft = "lua",
                opts = {
                    library = {
                        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
                    },
                },
            },
        },
    },

    config = function()
        require("conform").setup({
            formatters_by_ft = {
            }
        })
        local cmp = require('cmp')
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.tbl_deep_extend(
        "force",
        {},
        vim.lsp.protocol.make_client_capabilities(),
        cmp_lsp.default_capabilities())

        require("fidget").setup({})
        require("mason").setup()
        require("mason-lspconfig").setup({
            automatic_installation = true,
            ensure_installed = {},
            handlers = {
                function(server_name)
                    require("lspconfig")[server_name].setup {
                        capabilities = capabilities
                    }
                end,
            }
        })

        local cmp_select = { behavior = cmp.SelectBehavior.Select }

        cmp.setup({
            window = {
                completion = cmp.config.window.bordered(), -- get border around the completion menu
                documentation = cmp.config.window.bordered(), -- get border around the documentation
            },
            snippet = {
                expand = function(args)
                    require('luasnip').lsp_expand(args.body)
                end,
            },
            preselect = cmp.PreselectMode.Item, -- preselect the first item
            mapping = cmp.mapping.preset.insert({
                ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),-- move up in the list
                ['<C-n>'] = cmp.mapping.select_next_item(cmp_select), -- move down in the list
                ['<CR>'] = cmp.mapping.confirm({ select = true }), -- select a completion item
                ["<C-Space>"] = cmp.mapping.complete(), -- get auto-completion
            }),
            sources = cmp.config.sources({
                { name = 'nvim_lsp' },
                { name = 'luasnip' }, -- For luasnip users.
            }, {
                { name = 'buffer' },
            })
        })

        vim.diagnostic.config({
            -- update_in_insert = true,
            float = {
                focusable = false,
                style = "minimal",
                border = "rounded",
                source = true,
                header = "",
                prefix = "",
            },
        })

        -- border around the documentation when hover
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
            border = "rounded",
        })

        vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
            border = "rounded",
        })

        -- show line diagnostics
        vim.keymap.set('n', '<leader>cd', function()
            vim.diagnostic.open_float({ scope = "line" })
        end, { noremap = true, silent = true, desc = "Show current line diagnostics" })
    end
}



