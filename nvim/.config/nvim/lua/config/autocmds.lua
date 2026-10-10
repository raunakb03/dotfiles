vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
  pattern = { "*" },
  callback = function(args)
    if vim.bo[args.buf].filetype == "harpoon" then
      return
    end
    if vim.bo[args.buf].buftype ~= "" then
      return
    end
    vim.cmd("silent! wall")
  end,
  nested = true,
})
