require("lazy").setup({
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "kyazdani42/nvim-web-devicons" }
    },

    {
        "stevearc/oil.nvim",
        lazy = true,
    },
    -- "echasnovski/mini.files",
    -- "vimwiki/vimwiki",
    -- "tpope/vim-surround",
    -- "junegunn/fzf",
    {
        "ibhagwan/fzf-lua",
        lazy = true,
    },
    {
        "tpope/vim-commentary",
        lazy = true,
    },
    {
        "junegunn/vim-emoji",
        lazy = true,
    },
    {
        "vim-python/python-syntax",
        lazy = true,
    },
    {
        "norcalli/nvim-colorizer.lua",
        lazy = true,
    },
    {
        "neovim/nvim-lspconfig",
        lazy = true,
    },
    {
        "hrsh7th/cmp-nvim-lsp",
        lazy = true,
    },
    {
        "hrsh7th/cmp-buffer",
        lazy = true,
    },
    {
        "hrsh7th/cmp-path",
        lazy = true,
    },
    {
        "hrsh7th/cmp-cmdline",
        lazy = true,
    },
    {
        "hrsh7th/nvim-cmp",
        lazy = true,
    },
    {
        "gruvbox-community/gruvbox",
        lazy = true,
    },

    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = "VeryLazy",
    },

    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        event = "VeryLazy",
    },

    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        event = "VeryLazy",
    },

    -- Commented out plugin example
    -- {
    --   "letieu/wezterm-move.nvim",
    --   config = function()
    --     local wezterm_move = require("wezterm-move")
    --     vim.api.nvim_set_keymap('n', '<m-h>', '<cmd>lua wezterm_move.move("h")<CR>', { noremap = true, silent = true })
    --     vim.api.nvim_set_keymap('n', '<m-j>', '<cmd>lua wezterm_move.move("j")<CR>', { noremap = true, silent = true })
    --     vim.api.nvim_set_keymap('n', '<m-k>', '<cmd>lua wezterm_move.move("k")<CR>', { noremap = true, silent = true })
    --     vim.api.nvim_set_keymap('n', '<m-l>', '<cmd>lua wezterm_move.move("l")<CR>', { noremap = true, silent = true })
    --   end,
    -- },

    {
        "ornfelt/ChatGPT.nvim",
        dependencies = {
            "MunifTanjim/nui.nvim",
            "folke/trouble.nvim",
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
        },
        event = "VeryLazy",
    },

    {
        "robitx/gp.nvim",
        lazy = true,
    },

    --{
    --    "github/copilot.vim",
    --    lazy = true,
    --},

    --{
    --    "David-Kunz/gen.nvim",
    --    lazy = true,
    --},

    {
        "gsuuon/model.nvim",
        lazy = true,
    },

    -- avante (cursor-like)
    --{
    --  "stevearc/dressing.nvim",
    --  lazy = true,
    --},

    ---- Nui.nvim, for various UI plugins
    --{
    --  "MunifTanjim/nui.nvim",
    --  lazy = true,
    --},
    ---- Optional dependencies
    ---- {
    ----   "nvim-tree/nvim-web-devicons",
    ----   lazy = true,
    ---- },
    ---- {
    ----   "echasnovski/mini.icons", -- Alternative to nvim-web-devicons
    ----   lazy = true,
    ---- },
    ---- {
    ----   "HakonHarnes/img-clip.nvim", -- Clipboard image plugin
    ----   lazy = true,
    ---- },
    ---- {
    ----   "zbirenbaum/copilot.lua",
    ----   lazy = true,
    ----   config = function()
    ----     require("copilot").setup() -- Setup for Copilot
    ----   end,
    ---- },

    --{
    --  "yetone/avante.nvim",
    --  branch = "main",
    --  build = "make",
    --  lazy = false, -- Load eagerly
    --  config = function()
    --  end,
    --},
    -- end avante

    {
        "aznhe21/actions-preview.nvim",
        config = function()
            require("actions-preview").setup()
        end,
        lazy = true,
    },

    {
        "nanotee/sqls.nvim",
        lazy = true,
    },

    {
        "preservim/nerdcommenter",
        lazy = true,
    },

    {
        "tpope/vim-fugitive",
        lazy = true,
    },

    {
        "ornfelt/gitgraph.nvim",
        dependencies = {
            "sindrets/diffview.nvim",
        },
        config = function()
            require("gitgraph").setup({
                symbols = {
                    merge_commit = "M",
                    commit = "*",
                },
                format = {
                    timestamp = "%H:%M:%S %d-%m-%Y",
                    fields = { "hash", "timestamp", "author", "branch_name", "tag" },
                },
                hooks = {
                    on_select_commit = function(commit)
                        vim.notify("DiffviewOpen " .. commit.hash .. "^!")
                        vim.cmd(":DiffviewOpen " .. commit.hash .. "^!")
                    end,
                    on_select_range_commit = function(from, to)
                        vim.notify("DiffviewOpen " .. from.hash .. "~1.." .. to.hash)
                        vim.cmd(":DiffviewOpen " .. from.hash .. "~1.." .. to.hash)
                    end,
                },
            })
        end,
        lazy = true,
    },

    {
        "OXY2DEV/markview.nvim",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
        lazy = false,
    },
    -- "alexghergh/nvim-tmux-navigation"
    -- "mhinz/vim-startify"
    -- "mistweaverco/kulala.nvim"
    -- "3rd/diagram.nvim"
    -- "lewis6991/gitsigns.nvim"
    -- "mechatroner/rainbow_csv"
    -- "simrat39/rust-tools.nvim"
    -- "vim-syntastic/syntastic"
    -- "neoclide/coc.nvim"
    -- https://github.com/fladson/vim-kitty
    -- https://github.com/kkharji/sqlite.lua
    -- https://github.com/folke/persistence.nvim
    -- https://github.com/numToStr/Comment.nvim
}, {
        install = {
            missing = true,
            colorscheme = { "gruvbox", "default" }, -- Fallback to default
        },
        checker = {
            enabled = true,
            notify = false,
        },
        change_detection = {
            enabled = true,
            notify = false,
        },
        ui = {
            -- border = "rounded"
        },
        performance = {
            rtp = {
                disabled_plugins = {
                    "gzip",
                    "tarPlugin",
                    "tohtml",
                    "tutor",
                    "zipPlugin",
                },
            },
        },
    }
)

