vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'LSP actions',
    callback = function(event)
        local opts = { buffer = event.buf }

        vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', vim.tbl_extend('force', opts, { desc = "Show hover documentation" }))
        vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', vim.tbl_extend('force', opts, { desc = "Go to definition" }))
        vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', vim.tbl_extend('force', opts, { desc = "Go to declaration" }))
        vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', vim.tbl_extend('force', opts, { desc = "Go to implementation" }))
        vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', vim.tbl_extend('force', opts, { desc = "Go to type definition" }))
        vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', vim.tbl_extend('force', opts, { desc = "Find references" }))
        vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', vim.tbl_extend('force', opts, { desc = "Show signature help" }))
        vim.keymap.set('n', '<leader>cr', '<cmd>lua vim.lsp.buf.rename()<cr>', vim.tbl_extend('force', opts, { desc = "Rename symbol" }))
        vim.keymap.set({ 'n', 'x' }, '<leader>cf', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', vim.tbl_extend('force', opts, { desc = "Format code" }))
        vim.keymap.set('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<cr>', vim.tbl_extend('force', opts, { desc = "Show code actions" }))
    end,
})

vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('HighlightYank', { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})
