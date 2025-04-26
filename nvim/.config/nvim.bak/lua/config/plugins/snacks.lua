return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = true,
    preset = {
      pick = function(cmd, opts)
        return LazyVim.pick(cmd, opts)()
      end,
header = [[                                                                       
                                                                            
              ████ ██████           █████      ██                     
             ███████████             █████                             
             █████████ ███████████████████ ███   ███████████   
            █████████  ███    █████████████ █████ ██████████████   
           █████████ ██████████ █████████ █████ █████ ████ █████   
         ███████████ ███    ███ █████████ █████ █████ ████ █████  
        ██████  █████████████████████ ████ █████ █████ ████ ██████ 
        ]],
      -- stylua: ignore
      ---@type snacks.dashboard.Item[]
      keys = {
        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
        { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
        { icon = " ", key = "s", desc = "Restore Session", section = "session" },
        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
  },
  explorer = { enabled = false },
  indent = { enabled = true },
  input = { enabled = false },
  picker = { enabled = false },
  notifier = { enabled = false },
  quickfile = { enabled = false },
  scope = { enabled = false },
  scroll = { enabled = true },
  statuscolumn = { enabled = false },
  words = { enabled = false },
},
}
