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
        config = function()
            require("CopilotChat").setup({
                debug = false,
                proxy = nil, -- [protocol://]host[:port] Use this proxy
                allow_insecure = true,
            })
            vim.keymap.set("n", "<leader>aa", "<cmd>CopilotChatToggle<cr>", { noremap = true, silent = true, desc = "Toggle Copilot Chat" })
            vim.keymap.set("n", "<leader>ad", "<cmd>Copilot disable<cr>", { noremap = true, silent = true, desc = "Disable Copilot" })
            vim.keymap.set("n", "<leader>ae", "<cmd>Copilot enable<cr>", { noremap = true, silent = true, desc = "Enable Copilot" })
        end,
    },
}

