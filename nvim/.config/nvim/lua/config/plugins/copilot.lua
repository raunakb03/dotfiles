return {
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        branch = "main",
        event = "VeryLazy",
        dependencies = {
            { "github/copilot.vim" },
            { "nvim-lua/plenary.nvim" },
        },
        build = "make tiktoken",
        opts = {
            debug = false,
        },
        config = function()
            require("CopilotChat").setup({
                debug = false,
            })
            vim.keymap.set("n", "<leader>aa", "<cmd>CopilotChatToggle<cr>", { noremap = true, silent = true }, { desc = "Toggle Copilot Chat" })
            vim.keymap.set("n", "<leader>ad", "<cmd>Copilot disable<cr>", { noremap = true, silent = true }, { desc = "Disable Copilot" })
            vim.keymap.set("n", "<leader>ae", "<cmd>Copilot enable<cr>", { noremap = true, silent = true }, { desc = "Enable Copilot" })
        end,
    },
}
