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
        end,
    },
}

