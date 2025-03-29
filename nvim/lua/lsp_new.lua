--vim.lsp.enable({'clangd', 'gopls', 'rust-analyzer'})

-- Automatically enable LSP for all lsp files found in my runtimepath
local configs = {}

for _, v in ipairs(vim.api.nvim_get_runtime_file('lsp/*', true)) do  
  local name = vim.fn.fnamemodify(v, ':t:r')  
  configs[name] = true  
end

vim.lsp.enable(vim.tbl_keys(configs))

-- TODO: 
-- try: https://github.com/Saghen/blink.cmp

-- Completion
--vim.api.nvim_create_autocmd('LspAttach', {
--  callback = function(ev)
--    local client = vim.lsp.get_client_by_id(ev.data.client_id)
--    if client:supports_method('textDocument/completion') then
--      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
--    end
--  end,
--})

