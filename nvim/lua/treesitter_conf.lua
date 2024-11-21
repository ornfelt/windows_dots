local check_file_size = function(_, bufnr)
  return vim.api.nvim_buf_line_count(bufnr) > 100000
end

require("nvim-treesitter.configs").setup({
    -- A list of parser names, or "all"
    ensure_installed = {
        'bash',
        'c',
        'cpp',
        'css',
        'go',
        'graphql',
        'html',
        'java',
        'javascript',
        'jsdoc',
        'json',
        'lua',
        'lua',
        'markdown',
        'markdown_inline',
        'php',
        'python',
        'query',
        'regex',
        'rust',
        'scss',
        'sql',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'vue',
        'yaml',
    },

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- Automatically install missing parsers when entering buffer
    -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
    auto_install = true,

    indent = {
        enable = true
    },

    highlight = {
        -- `false` will disable the whole extension
        enable = true,
        disable = check_file_size,

        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on "syntax" being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = { "markdown" },
    },
    incremental_selection = {
        enable = true, -- Enable incremental selection
    },
})

--local treesitter_parser_config = require("nvim-treesitter.parsers").get_parser_configs()
--treesitter_parser_config.templ = {
--    install_info = {
--        url = "https://github.com/vrischmann/tree-sitter-templ.git",
--        files = {"src/parser.c", "src/scanner.c"},
--        branch = "master",
--    },
--}
--
--vim.treesitter.language.register("templ", "templ")

-- require('mini.ai').setup()

