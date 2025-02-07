return {
    {
        "0x00-ketsu/autosave.nvim",
        event = { "InsertLeave", "TextChanged", "TextChangedI" },
        config = function()
            require("autosave").setup({
                events = { "InsertLeave", "TextChanged", "TextChangedI" },
                debounce_delay = 1000,
            })
        end,
    }
}
