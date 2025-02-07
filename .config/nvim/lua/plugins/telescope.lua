return {
    "nvim-telescope/telescope.nvim",
    config = function()
        local telescope_theme = "dropdown"
        local show_preview = false
        require("telescope").setup({
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
        })
    end,
}
