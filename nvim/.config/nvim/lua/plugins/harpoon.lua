return {
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        -- dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local harpoon = require("harpoon")
            harpoon:setup()
            vim.keymap.set("n", "<leader>h", function() harpoon:list():add() end, { desc = "Add file to the harpoon list" })
            vim.keymap.set("n", "<leader>H", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Open harpoon list" })
            vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end, { desc = "Open harpoon list 1" })
            vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end, { desc = "Open harpoon list 2" })
            vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end, { desc = "Open harpoon list 3" })
            vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end, { desc = "Open harpoon list 4" })
        end,
    }
}
