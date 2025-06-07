return {
    "nvim-lua/plenary.nvim",
    "christoomey/vim-tmux-navigator",
    "tpope/vim-sleuth",
    {
        "echasnovski/mini.surround",
        version = '*',
        config = function()
            require('mini.surround').setup()
        end
    }
}
