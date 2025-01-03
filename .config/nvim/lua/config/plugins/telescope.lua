return {
    {
        'nvim-telescope/telescope.nvim',
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
            "nvim-tree/nvim-web-devicons",
            {"ThePrimeagen/harpoon", branch = "harpoon2"},
        },
        config = function()
            local builtin = require('telescope.builtin')
            local keymap = vim.keymap
            local telescope = require('telescope')
            local actions = require("telescope.actions")
            local telescope_theme = "dropdown"
            local show_preview = false
            telescope.setup({
                pickers = {
                    find_files = {
                        theme = telescope_theme,
                        previewer = show_preview,
                    },
                    live_grep = {
                        theme = telescope_theme,
                        previewer = show_preview,
                    },
                    buffers = {
                        theme = telescope_theme,
                        previewer = show_preview,
                    },
                    help_tags = {
                        theme = telescope_theme,
                        previewer = show_preview,
                    },
                },
                extensions = {
                    fzf = {},
                },
                defaults = {
                    prompt_prefix = " ",
                    selection_caret = " ",
                    file_ignore_patterns = { ".git/", "node_modules/", "vendor/", ".cache/", ".venv/" },
                    path_display = { "smart" },
                    mappings = {
                        i = {
                            ["<C-k>"] = actions.move_selection_previous, -- move to prev result
                            ["<C-j>"] = actions.move_selection_next, -- move to next result
                            ["<C-q>"] = function(prompt_bufnr)
                                actions.send_selected_to_qflist(prompt_bufnr)
                                require("trouble").toggle("qflist")
                            end,
                        },
                    },

                },
            })
            telescope.load_extension("fzf")
            telescope.load_extension("harpoon")
            keymap.set('n', '<leader>ff', builtin.find_files, { desc = "Find files in current directory" })
            keymap.set('n', '<leader>fs', builtin.live_grep, { desc = "Find string in current directory" })
            keymap.set('n', '<leader>fb', builtin.buffers, { desc = "Telescope buffers" })
            keymap.set('n', '<leader>fh', builtin.help_tags, { desc = "Telescope help tags" })
            keymap.set('n', '<leader>fc', "<cmd>Telescope find_files search_dirs={'~/.config/nvim'}<CR>", { desc = "Telescope find files in config" })
        end,
    }
}

