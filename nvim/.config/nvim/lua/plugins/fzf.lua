return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local fzf = require("fzf-lua")
    local actions = fzf.actions
    fzf.setup({
      winopts = {
        fullscreen = false,
        preview = { hidden = false },
      },
      files = {
        fd_opts = [[--type f --strip-cwd-prefix --hidden --exclude .git --exclude node_modules]]
      },
      grep = {
        rg_opts = [[--hidden --column --line-number --no-heading --color=always --smart-case --glob "!.git/*" --glob "!node_modules/*"]]
      },
      keymap = {
        fzf = {
          ["ctrl-a"] = "select-all",
          ["ctrl-q"] = "select-all+accept",
        },
      },
      actions = {
      },
      on_create = function()
        vim.keymap.set("t", "<C-j>", "<Down>", { silent = true, buffer = true })
        vim.keymap.set("t", "<C-k>", "<Up>", { silent = true, buffer = true })
      end,
    })
  end,
  keys = {
    {
      "<leader>ff",
      function() require("fzf-lua").files() end,
      desc = "Find files in CWD"
    },
    {
      "<leader>fn",
      function() require("fzf-lua").files({ cwd = vim.fn.stdpath("config") }) end,
      desc = "Find files in neovim config"
    },
    {
      "<leader>fq",
      function() require("fzf-lua").quickfix() end,
      desc = "Find files in quickfix list"
    },
    {
      "<leader>fs",
      function() require("fzf-lua").live_grep() end,
      desc = "Find word"
    },
    {
      "<leader>uc",
      function() require("fzf-lua").colorschemes() end,
      desc = "Find colorschemes"
    },
    {
      "<leader>fm",
      function() require("fzf-lua").manpages() end,
      desc = "Find manpages"
    },
    {
      "<leader>fh",
      function() require("fzf-lua").helptags() end,
      desc = "Find help tags"
    },
    {
      "<leader>fr",
      function() require("fzf-lua").registers() end,
      desc = "Find registers"
    },
    {
      "<leader>fc",
      function() require("fzf-lua").commands() end,
      desc = "Find commands"
    },
    {
      "<leader>fk",
      function() require("fzf-lua").keymaps() end,
      desc = "Find keymaps"
    },
    {
      "<leader>fb",
      function() require("fzf-lua").builtin() end,
      desc = "Find builtins"
    }
  }
}
